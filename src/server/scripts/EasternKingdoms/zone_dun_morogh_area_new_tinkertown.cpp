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
#include "Player.h"
#include "ScriptedCreature.h"
#include "TaskScheduler.h"

enum SafeOperativeSparring
{
    NPC_CRAZED_LEPER_GNOME = 46391,

    // Not 85756, which is what retail gives this NPC (creature_template.spell2,
    // VerifiedBuild 25549), because its visual will not leave the gun alone.
    //
    // 85756 is the only spell in the client using SpellVisual 18304, and 18304 is
    // the only one of the candidates whose chain contains a
    // SpellVisualKitModelAttach row: kit 17337 attaches SpellVisualEffectName 3113,
    // model 165559, to the caster. No item in the game uses that model. Cast once it
    // reads as the gun changing for the shot; cast every 2-3 seconds, as the sparring
    // AI does, it replaces the equipped 52355 and is still there when the fight ends.
    // An Operative that has never fought keeps 52355 correctly, which is what makes
    // the scene ones look wrong by comparison. The visual is resolved client-side, so
    // the spell is the only lever.
    //
    // 6660 is not the way out: RangeIndex 54, 5 to 30 yards, and the leper gnomes
    // walk in to 2.5-4.5, so every cast comes back refused as too close.
    //
    // 208193 is RangeIndex 5, the same 0-40 band as 85756; it carries SpellVisual
    // 10208, whose two kits hold no model attachments at all; it has no
    // SPELL_ATTR0_REQ_AMMO; and its school damage is the same order as 6660's. Of the
    // twenty-four spells on visual 10208 only it and 233835 clear all four bars, and
    // 233835 hits about twenty times harder.
    SPELL_SHOOT            = 208193,

    // 85756's visual, 18304, is the look this scene wants, and the client will not
    // give it whole: of its three kits only 17337 carries a
    // SpellVisualKitModelAttach, and that is the one that puts a foreign gun on the
    // caster. 17335 and 17336 are the other two, are used by no other visual in the
    // client, and hold no attachment at all -- so they can be played straight onto
    // the caster on top of 208193's cast. That gets 85756's shot without its gun.
    SPELL_VISUAL_KIT_SHOT_START = 17335,
    SPELL_VISUAL_KIT_SHOT_FIRE  = 17336
};

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
        {
            // Unit::Attack wipes UNIT_NPC_EMOTESTATE on any creature that starts a
            // fight, on the assumption that the creature will evade later and
            // LoadCreaturesAddon will put it back. These never evade -- the sparring
            // cap keeps both sides alive indefinitely -- so the ready-rifle stance
            // from creature_addon would be gone for the rest of the uptime.
            me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_READY_RIFLE);
            DoStartNoMovement(who);
        }
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
                {
                    // Only on a cast that actually went out, so the muzzle never
                    // fires on a shot the client never saw.
                    me->SendPlaySpellVisualKit(SPELL_VISUAL_KIT_SHOT_START, 0, 0);
                    me->SendPlaySpellVisualKit(SPELL_VISUAL_KIT_SHOT_FIRE, 0, 0);
                }
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

enum SafeOperativeBarker
{
    // creature_text group for "Our men have secured the walkway."
    SAY_WALKWAY_SECURED = 0,

    NPC_SAFE_OPERATIVE  = 45847
};

// Retail fires this bark at about 2.5 yards. Across three approaches the player
// crossed 7.5, 5.6 and 3.2 yards in silence and the line went out between 2.3 and
// 1.7.
//
// This is the whole reason the bark is not SmartAI. SMART_EVENT_OOC_LOS compares
// against maxDist plus both combat reaches -- 1.725 for the Operative, 1.5 for the
// player -- so its smallest usable radius is 4.2 yards, and the 8 it was set to was
// really 11.2. The two barkers stand 19 yards apart, so those circles overlapped
// across the middle of the walkway and a player standing there set off both.
static constexpr float BARK_RADIUS = 2.5f;

// Long enough to reach the other barker 19 yards away, short enough to stop before
// the sparring pairs further down the camp.
static constexpr float BARK_PARTNER_RANGE = 25.0f;

// A player running the walkway covers the 19 yards between the two in under three
// seconds. The radii can no longer overlap, but two barks that close still read as
// both of them talking at once, so whichever speaks first holds the other quiet.
static constexpr uint32 BARK_PARTNER_SILENCE = 10 * IN_MILLISECONDS;

// Unchanged from the smart_scripts row this replaces.
static constexpr uint32 BARK_COOLDOWN_MIN = 45 * IN_MILLISECONDS;
static constexpr uint32 BARK_COOLDOWN_MAX = 90 * IN_MILLISECONDS;

// 250ms rather than a full second: at run speed a player covers about 1.75 yards
// between polls, which is already most of the 2.5-yard radius.
static constexpr uint32 BARK_POLL_INTERVAL = 250;

// The two S.A.F.E. Operatives on the walkway above the camp, 984707 and 984708.
// They ignore the fight below and greet players who walk right up to them.
struct npc_safe_operative_barker : public ScriptedAI
{
    npc_safe_operative_barker(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _cooldown = 0;
        _poll = 0;
    }

    // Called by the other barker, not from here. Only ever extends the wait, so the
    // partner's own post-bark cooldown is never cut short.
    void SilenceFor(uint32 ms)
    {
        if (ms > _cooldown)
            _cooldown = ms;
    }

    void UpdateAI(uint32 diff) override
    {
        if (_cooldown)
        {
            _cooldown = _cooldown > diff ? _cooldown - diff : 0;
            return;
        }

        if (_poll > diff)
        {
            _poll -= diff;
            return;
        }

        _poll = BARK_POLL_INTERVAL;

        if (me->IsInCombat())
            return;

        // SelectNearestPlayer pads the range with both combat reaches the same way
        // the smart event does, so it is used only to pick the nearest candidate;
        // the radius itself is enforced on the raw distance.
        Player* player = me->SelectNearestPlayer(BARK_RADIUS);
        if (!player || me->GetExactDist(player) > BARK_RADIUS)
            return;

        if (!me->IsWithinLOSInMap(player))
            return;

        Talk(SAY_WALKWAY_SECURED, player);
        _cooldown = urand(BARK_COOLDOWN_MIN, BARK_COOLDOWN_MAX);

        std::list<Creature*> neighbours;
        me->GetCreatureListWithEntryInGrid(neighbours, NPC_SAFE_OPERATIVE, BARK_PARTNER_RANGE);
        for (Creature* neighbour : neighbours)
        {
            if (neighbour == me)
                continue;

            // dynamic_cast: most of the 45847 spawns in range are sparring or plain
            // SmartAI, and only another barker answers this.
            if (npc_safe_operative_barker* partner = CAST_AI(npc_safe_operative_barker, neighbour->AI()))
                partner->SilenceFor(BARK_PARTNER_SILENCE);
        }
    }

private:
    uint32 _cooldown = 0;
    uint32 _poll = 0;
};

void AddSC_dun_morogh_area_new_tinkertown()
{
    RegisterCreatureAI(npc_safe_operative_sparring);
    RegisterCreatureAI(npc_safe_operative_barker);
}
