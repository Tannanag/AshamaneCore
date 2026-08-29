/*
 * Copyright (C) 2008-2018 TrinityCore <https://www.trinitycore.org/>
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation; either version 2 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "ScriptMgr.h"
#include "Creature.h"
#include "Duration.h"
#include "Log.h"
#include "ScriptedCreature.h"
#include "TaskScheduler.h"

enum SafeOperativeSparring
{
    NPC_CRAZED_LEPER_GNOME = 46391,

    // Retail's own ranged attack for this NPC: creature_template.spell2 for 45847,
    // sniffed at VerifiedBuild 25549. It brings its own missile, its own three
    // SoundKits and its own animations, which is why nothing else was accurate
    // enough. 6660 is no substitute -- RangeIndex 54, 5 to 30 yards, and the leper
    // gnomes walk in to 2.5-4.5, so every cast comes back refused as too close.
    SPELL_SHOOT            = 85756,

    // The one part of 85756 that has to go. SpellVisual 18304 fires three kits;
    // 17335 and 17336 are the shot -- animations and SoundKits 20688 and 20685 --
    // and 17337 is SoundKit 20686 plus the single SpellVisualKitModelAttach row in
    // the whole chain, 288183, which hangs SpellVisualEffectName 3113 (a model no
    // item in the game uses) off the caster. That attachment never clears by itself,
    // so at this firing rate it replaced the equipped 52355 and outlived the fight.
    //
    // SMSG_CANCEL_SPELL_VISUAL_KIT takes a single kit id, so the kit is cancelled
    // per shot and everything else about the spell is left alone. Correcting the
    // client data instead was tried twice and abandoned: deleting the kit crashes
    // the client, and overriding the attach row through hotfix_data is ignored by it.
    SPELL_VISUAL_KIT_GUN_ATTACH = 17337
};

// Long enough that the attachment has been applied and the shot reads as a shot --
// the missile covers the 3-4 yards these pairs stand apart in about a tenth of a
// second -- and short enough that the wrong gun is never left parked in their hands.
static constexpr Milliseconds GUN_ATTACH_CANCEL_DELAY = Milliseconds(700);

// The spell reaches 40 yards. The sparring pairs stand between 3 and 25 apart, so
// 30 covers the scene without an Operative picking a fight across the camp.
static constexpr float SPARRING_RANGE = 30.0f;

// The S.A.F.E. Operatives outside the gnome starting area trade fire with the
// Crazed Leper Gnomes beside them. The gnomes walk into contact and swing, which is
// correct; the Operatives must keep using their guns, which is not something the
// database can express.
//
// This AI exists for one reason: it never calls DoMeleeAttackIfReady. Every stock
// AI does, and a creature with a victim inside melee range will swing. There is no
// way around that from SQL -- this core has no no-melee creature flag, and
// SET_RANGED_MOVEMENT cannot push a creature back out of melee once something has
// closed on it, because TargetedMovementGenerator returns early when the owner is
// already inside the offset.
//
// Staying alive is not this script's job. creature_sparring_template caps 45847 and
// 46391 at 85%, so neither side can kill the other, and Unit::DealDamage applies
// that cap only to non-player-owned attackers, so players still kill both normally.
struct npc_safe_operative_sparring : public ScriptedAI
{
    npc_safe_operative_sparring(Creature* creature) : ScriptedAI(creature)
    {
        // They hold their post. Chasing would drag the fight out of the camp.
        SetCombatMovement(false);
    }

    // No SetSheath here. The sheath state belongs to creature_addon: the script
    // cannot hold it, because HomeMovementGenerator::DoFinalize calls
    // LoadCreaturesAddon() when the creature reaches its spawn point and that
    // rewrites the sheath from the addon row -- after Reset() has already run, and
    // before JustReachedHome(). An Operative set to RANGED here therefore drops
    // back to the addon's value on every evade, so the seven of them end up in
    // different sheath states at any given moment and the gun renders
    // inconsistently across the camp.
    void Reset() override
    {
        _scheduler.CancelAll();

        // An Operative whose partner died mid-visual keeps the attachment, and its
        // scheduled cancel died with CancelAll. Clear it on the way back to idle.
        me->SendCancelSpellVisualKit(SPELL_VISUAL_KIT_GUN_ATTACH);
        ScheduleShot();
    }

    // ScriptedAI::AttackStart lands on AttackStartNoMove for a creature with combat
    // movement off, and that calls me->Attack(who, true) -- meleeAttack true. That
    // sets UNIT_STATE_MELEE_ATTACKING and sends SMSG_ATTACK_START to everyone in
    // range, so the client puts the Operative into melee posture and draws hand
    // slots 0 and 1, which are empty: no gun while the fight is on, and the shoot
    // animation falls back to a default weapon. The gun reappears the moment the
    // fight ends and SMSG_ATTACK_STOP restores the sheath state. Passing false
    // keeps the target, the threat and the combat state and drops only the melee
    // claim, which this AI never makes good on anyway -- it has no
    // DoMeleeAttackIfReady.
    void AttackStart(Unit* who) override
    {
        if (!who)
            return;

        if (me->Attack(who, false))
            DoStartNoMovement(who);
    }

    void UpdateAI(uint32 diff) override
    {
        // Runs in and out of combat, so the scene is already going before a player
        // arrives to pull anything.
        _scheduler.Update(diff);

        // Leashing and evade when the partner dies. Note what is missing after it:
        // no DoMeleeAttackIfReady, and that omission is the whole point.
        if (!UpdateVictim())
            return;
    }

private:
    void ScheduleShot()
    {
        _scheduler.Schedule(Seconds(2), Seconds(3), [this](TaskContext task)
        {
            // FindNearestCreature filters to living targets by default. The cast
            // result is checked rather than discarded: a refused cast is otherwise
            // indistinguishable from an AI that is not running, which is exactly the
            // confusion that hid a minimum-range problem here for several passes.
            if (Creature* partner = me->FindNearestCreature(NPC_CRAZED_LEPER_GNOME, SPARRING_RANGE))
            {
                if (me->CastSpell(partner, SPELL_SHOOT, false))
                    // Only on a cast that went out, so a shot the client never saw
                    // cannot cancel a kit belonging to the previous one.
                    task.Schedule(GUN_ATTACH_CANCEL_DELAY, [this](TaskContext /*cancel*/)
                    {
                        me->SendCancelSpellVisualKit(SPELL_VISUAL_KIT_GUN_ATTACH);
                    });
                else
                    TC_LOG_DEBUG("scripts.ai", "npc_safe_operative_sparring: %s refused %u at %s, dist %.1f",
                        me->GetGUID().ToString().c_str(), uint32(SPELL_SHOOT),
                        partner->GetGUID().ToString().c_str(), me->GetExactDist(partner));
            }

            task.Repeat(Seconds(2), Seconds(3));
        });
    }

    TaskScheduler _scheduler;
};

void AddSC_dun_morogh_area_new_tinkertown()
{
    RegisterCreatureAI(npc_safe_operative_sparring);
}
