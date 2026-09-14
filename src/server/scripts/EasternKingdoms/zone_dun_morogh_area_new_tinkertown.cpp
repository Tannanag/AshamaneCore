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
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GameObjectData.h"
#include "Log.h"
#include "Map.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
#include "MoveSplineInit.h"
#include "ObjectAccessor.h"
#include "PassiveAI.h"
#include "Player.h"
#include "QuestDef.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "SpellInfo.h"
#include "TaskScheduler.h"
#include "TemporarySummon.h"
#include "Vehicle.h"
#include <cmath>
#include <type_traits>
#include <vector>

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

enum GnomereganRecruitSparring
{
    NPC_LIVING_CONTAMINATION_SPARRING = 43089
};

// The pairs stand 3.5 yards apart and the next pair along the path is about 13
// away, so anything under that binds a recruit to its own target. FindNearestCreature
// would pick the right one at any range; the tight value is what keeps a recruit from
// adopting its neighbour's if one of the pair is ever missing.
static constexpr float RECRUIT_SPARRING_RANGE = 10.0f;

// Eight Gnomeregan Recruits line the path at the tram entrance, each shooting a
// Living Contamination pinned three and a half yards in front of it. The
// contamination fights back in melee and with Poison Bolt on a twelve second
// cycle, which is SmartAI on 43089; only the recruit's half needs C++.
//
// It needs it for the same single reason as npc_safe_operative_sparring above: the
// recruit must keep shooting and must never melee, and no stock AI can be told
// that. Everything that AI documents applies here unchanged -- why AttackStart
// passes false, and why the shot is 208193 wearing 85756's visual kits rather than
// 85756 itself, which would replace the recruit's rifle with a foreign model for
// the whole fight.
//
// One thing differs, and it is why this AI does not touch the emote state. The
// Operative wears its pose in creature_addon.emote, which Unit::Attack wipes when a
// fight starts, so that AI has to put it back. The recruit's pose is an aura
// instead -- 78174, Emote State Hold Rifle, on creature_template_addon -- and its
// rifle is drawn by SheathState 2 rather than by any emote. A recruit in combat
// carries the aura throughout and has no emote state at all, so there is nothing
// for the script to defend.
//
// Staying alive is not this script's job either. creature_sparring_template caps
// 43089 and 43092 at 85%, and Unit::DealDamage applies the cap only to
// non-player-owned attackers, so players still kill both normally.
struct npc_gnomeregan_recruit_sparring : public ScriptedAI
{
    npc_gnomeregan_recruit_sparring(Creature* creature) : ScriptedAI(creature), _refusalLogged(false)
    {
        // They hold the line. Chasing would walk the firing line off the path.
        SetCombatMovement(false);
    }

    void Reset() override
    {
        _scheduler.CancelAll();
        ScheduleShot();
    }

    // See npc_safe_operative_sparring::AttackStart. Passing false keeps the target,
    // the threat and the combat state and drops only the melee claim, which this AI
    // never makes good on: there is no DoMeleeAttackIfReady below.
    void AttackStart(Unit* who) override
    {
        if (!who)
            return;

        if (me->Attack(who, false))
            DoStartNoMovement(who);
    }

    void UpdateAI(uint32 diff) override
    {
        // Deliberately outside the UpdateVictim guard: the firing line is already
        // running before any player arrives, and the first shot is what starts the
        // fight rather than something that happens once it has.
        _scheduler.Update(diff);

        if (!UpdateVictim())
            return;
    }

private:
    void ScheduleShot()
    {
        // Retail shoots on a 1.22 s median, tightly held -- the spread over eight
        // recruits is 1.03 to 1.22 with nothing between shots but the cast itself.
        _scheduler.Schedule(Milliseconds(1100), Milliseconds(1300), [this](TaskContext task)
        {
            if (Creature* partner = me->FindNearestCreature(NPC_LIVING_CONTAMINATION_SPARRING, RECRUIT_SPARRING_RANGE))
            {
                if (me->CastSpell(partner, SPELL_SHOOT, false))
                {
                    // Only on a cast that went out, so the muzzle never fires on a
                    // shot no client saw.
                    me->SendPlaySpellVisualKit(SPELL_VISUAL_KIT_SHOT_START, 0, 0);
                    me->SendPlaySpellVisualKit(SPELL_VISUAL_KIT_SHOT_FIRE, 0, 0);
                }
                else if (!_refusalLogged)
                {
                    // Once per recruit, not once per shot: at this cadence a
                    // standing refusal would be eight lines a second. A refused cast
                    // is otherwise indistinguishable from an AI that never ran,
                    // which is the confusion that hid a minimum-range problem in the
                    // Operative version for several passes.
                    _refusalLogged = true;
                    TC_LOG_ERROR("scripts.ai", "npc_gnomeregan_recruit_sparring: %s refused %u at %s, dist %.1f",
                        me->GetGUID().ToString().c_str(), uint32(SPELL_SHOOT),
                        partner->GetGUID().ToString().c_str(), me->GetExactDist(partner));
                }
            }

            task.Repeat(Milliseconds(1100), Milliseconds(1300));
        });
    }

    TaskScheduler _scheduler;
    bool _refusalLogged;
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

enum SafeOperativeCarrier
{
    NPC_INJURED_GNOME       = 46447,

    // The gnome casts this on itself the moment it is set down. It is the aura every
    // Injured Gnome in the camp already wears -- creature_addon on 169319, and a
    // SMART_EVENT_RESPAWN row on the entry -- so the effect the player sees at the end
    // of a run is the familiar one, arriving with the gnome instead of having sat in
    // the bed since server start.
    SPELL_IRRADIATION       = 80653,

    // Held for exactly as long as the Operative is carrying and cleared once the gnome
    // is down. This is what puts the Operative into the carry pose. The gnome itself is
    // a vehicle passenger, which the client draws at the seat's attachment point on its
    // own.
    ANIM_KIT_CARRY          = 989,

    // 46449 carries creature_template.VehicleId 1186, which has exactly one seat
    // (VehicleSeat 8744, PassengerAttachmentID 1). Seat 0 is that seat.
    SEAT_INJURED_GNOME      = 0,

    POINT_BED               = 1,
    POINT_HOME              = 2
};

// The beats of one run. These are the intervals the scene is built around rather than
// values chosen to taste, and the whole cycle comes to about 65 seconds.
static constexpr Milliseconds PICKUP_TO_WALK         = Milliseconds(3600);
static constexpr Milliseconds ARRIVE_TO_KNEEL        = Milliseconds(1200);
static constexpr Milliseconds KNEEL_TO_PLACE         = Milliseconds(2000);
static constexpr Milliseconds PLACE_TO_CARRY_OFF     = Milliseconds(1200);
static constexpr Milliseconds CARRY_OFF_TO_WALK_BACK = Milliseconds(1600);
static constexpr Milliseconds RETURN_TO_DESPAWN      = Milliseconds(200);

// The gnome is taken away again well before the Operative is home: 20.6 seconds after
// it was set down, against the 26 the walk back takes. Treated and gone, and the bed
// stands empty until the next one arrives.
static constexpr Milliseconds PLACED_GNOME_LIFETIME  = Milliseconds(20600);

// The gap from one Operative despawning to the next appearing is 2.5 seconds. The
// respawn delay is only expressible in whole seconds, so the scene restarts half a
// second late.
static constexpr Seconds RESPAWN_DELAY = Seconds(3);

// How far the gnome is turned in the seat, in transport-local radians. It lies across
// the Operative's arms rather than along them, and orientation grows counter-clockwise,
// so this is a quarter turn counter-clockwise from the way the seat would otherwise
// leave it. If the model still reads wrong in game, the other two quarter turns are
// -CARRY_YAW and CARRY_YAW + M_PI; nothing else needs to change with it.
static constexpr float CARRY_YAW = float(M_PI) / 2.0f;

// The bed, taken from creature guid 169319 -- the static Injured Gnome this scene
// replaces.
Position const GnomeBedPosition = { -4974.72f, 872.908f, 274.392f, 3.7001f };

// The walk down, one node per turn of the ramp. MoveSplineInit::Launch overwrites
// element 0 with the creature's real position, so the value there is never used as a
// destination -- it only records where the path is meant to start.
Position const CarryPathOut[] =
{
    { -4958.170f, 827.382f, 285.898f },
    { -4960.723f, 828.947f, 285.985f },
    { -4963.893f, 831.063f, 283.043f },
    { -4967.999f, 833.952f, 279.352f },
    { -4973.607f, 836.099f, 276.470f },
    { -4975.589f, 836.647f, 276.388f },
    { -4979.849f, 840.044f, 276.388f },
    { -4980.787f, 848.567f, 276.388f },
    { -4980.973f, 854.650f, 276.388f },
    { -4980.184f, 861.803f, 274.387f },
    { -4978.893f, 865.510f, 274.388f },
    { -4973.954f, 871.994f, 274.447f }
};

// The way back, which is not the outbound nodes reversed but a line of its own, running
// within about a yard of the other one.
Position const CarryPathBack[] =
{
    { -4973.954f, 871.994f, 274.447f },
    { -4976.012f, 870.535f, 274.389f },
    { -4979.562f, 867.307f, 274.388f },
    { -4980.466f, 860.328f, 274.387f },
    { -4981.050f, 855.152f, 276.392f },
    { -4981.284f, 849.132f, 276.388f },
    { -4980.177f, 840.459f, 276.388f },
    { -4976.795f, 836.821f, 276.388f },
    { -4969.670f, 834.688f, 277.993f },
    { -4965.455f, 832.328f, 281.593f }
};

// A vehicle with a free seat advertises itself as clickable. Vehicle::Install sets
// UNIT_NPC_FLAG_SPELLCLICK when any seat is usable and Vehicle::RemovePassenger sets it
// again the moment one empties; VehicleJoinEvent only takes it off when the last usable
// seat fills. So a carrier wears it from the moment it lets go until the next passenger
// boards -- the client draws the cog cursor and offers an interaction that does not
// exist. Neither 46449 nor 46012 has any npc_spellclick_spells row, so a click was never
// going to do anything.
static void ClearVehicleSpellClick(Creature* vehicle)
{
    if (vehicle->HasFlag64(UNIT_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK))
        vehicle->RemoveFlag64(UNIT_NPC_FLAGS, UNIT_NPC_FLAG_SPELLCLICK);
}

// The S.A.F.E. Operative on the ledge above the camp, creature guid 169286. It carries
// an Injured Gnome down to the bed at the bottom, kneels and sets it down, walks back
// up and despawns; the respawn timer brings a new one and the run starts over.
//
// The carrying is a vehicle, not an animation trick. 46449 has
// creature_template.VehicleId 1186, whose single seat is VehicleSeat 8744, and the gnome
// rides that seat -- which is also why the Operative's guid is a Vehicle guid rather
// than a Creature one. The anim kit is all the client needs on top of that.
//
// Not SmartAI, for two reasons that SQL cannot reach: SMART_ACTION has no way to seat
// a creature in a vehicle seat, and the run has to carry two guids across its legs --
// the passenger, which has to be found again at the bed, and the gnome left in the
// bed, which has to be found again when its time is up.
// Shared by every S.A.F.E. Operative that holds an Injured Gnome -- the one that
// carries a casualty down to the bed, and the two that kneel over one. They all seat
// the gnome in the same vehicle seat, they all have to put its facing back afterwards,
// they all have to stop the vehicle code advertising a click, and none of them fight.
struct npc_safe_operative_bearer : public ScriptedAI
{
    npc_safe_operative_bearer(Creature* creature) : ScriptedAI(creature) { }

    // This Operative never fights, and the run breaks if it tries. A victim means
    // ChaseMovementGenerator, which takes MOTION_SLOT_ACTIVE off the carry spline and
    // walks the Operative off the ramp with the gnome still on its back; the end of
    // the fight then leaves it standing wherever it stopped, because the arrival that
    // would have driven the rest of the scene never comes. The evade after it is
    // worse: MoveTargetedHome ends in LoadCreaturesAddon, which clears the anim kit,
    // so it walks home in the carry pose and loses it on arrival.
    //
    // REACT_PASSIVE alone does not cover this. It stops the Operative choosing a
    // target of its own, but AttackStart is reachable without it -- another creature's
    // AI calling it directly, an assist, a spell that forces a target. The two
    // overrides make the AI structurally incapable of taking a victim rather than
    // merely disinclined to look for one.
    //
    // creature_template.unit_flags 768 is IMMUNE_TO_PC | IMMUNE_TO_NPC, so nothing can
    // attack the Operative either. That flag stays in the database rather than being
    // re-asserted here, the same way the sparring Operatives leave their sheath state
    // to creature_addon.
    void AttackStart(Unit* /*who*/) override { }

    // Cuts the out-of-combat LOS scan entirely. REACT_PASSIVE already makes
    // CreatureAI::MoveInLineOfSight return without aggroing, so this changes no
    // behaviour -- it only stops the Operative running that check against every unit
    // it passes on a walk that crosses the length of the camp twice a minute.
    void MoveInLineOfSight(Unit* /*who*/) override { }

    // VehicleJoinEvent::Execute finishes the boarding with init.SetFacing(0.0f), and
    // nothing in this core ever reads VehicleSeatEntry::PassengerYaw, so every passenger
    // ends up facing straight along the vehicle's local X axis whatever the seat asked
    // for. On this seat that leaves the gnome lying at the wrong angle across the
    // Operative, so the transport-enter spline is re-issued with the facing the carry
    // wants. The offset is read back from what the join event just wrote, which keeps
    // the seat's own attachment point rather than hard-coding it here.
    void PassengerBoarded(Unit* passenger, int8 /*seatId*/, bool apply) override
    {
        if (!passenger)
            return;

        if (!apply)
        {
            // Vehicle::RemovePassenger puts UNIT_NPC_FLAG_SPELLCLICK back on as its very
            // first act, and this hook is its last, so here is where it comes off again.
            // Without this the cog sits on the Operative for the whole walk home.
            ClearSpellClick();
            return;
        }

        // By value, not by reference: the orientation is written back to this same
        // member a few lines down.
        Position const seat = passenger->m_movementInfo.transport.pos;

        Movement::MoveSplineInit init(passenger);
        init.DisableTransportPathTransformations();
        init.MoveTo(seat.GetPositionX(), seat.GetPositionY(), seat.GetPositionZ(), false, true);
        init.SetFacing(CARRY_YAW);
        init.SetTransportEnter();
        init.Launch();

        // So that a client which streams the gnome in later, rather than watching it
        // board, is told the same angle.
        passenger->m_movementInfo.transport.pos.SetOrientation(CARRY_YAW);

        // Everything about the gnome is now settled, so let the clients have it.
        if (Creature* gnome = passenger->ToCreature())
            Reveal(gnome);
    }

protected:
    // Map::SummonCreature applies visibleBySummonerOnly before AddToMap, so a summon
    // flagged that way never has a create block built for it at all; and because
    // WorldObject::CanSeeOrDetect only exempts the summoner, a creature summoner means
    // no player sees it. That is what lets every gnome in this scene be assembled
    // off-screen and handed over finished. These two are the on and off.
    static void Reveal(Creature* gnome)
    {
        gnome->SetVisibleBySummonerOnly(false);
        gnome->UpdateObjectVisibility();
    }

    static void Conceal(Creature* gnome)
    {
        gnome->SetVisibleBySummonerOnly(true);
        gnome->UpdateObjectVisibility();
    }

    // Cleared from three places rather than polled: Reset, the walk-out task (which
    // covers Vehicle::Install, since Creature::AddToWorld runs it after AIM_Initialize
    // and therefore after Reset), and PassengerBoarded on the way out.
    void ClearSpellClick()
    {
        ClearVehicleSpellClick(me);
    }

    // TRIGGERED_FULL_MASK, rather than Unit::EnterVehicle. EnterVehicle casts 46598 with
    // only TRIGGERED_IGNORE_CASTER_MOUNTED_OR_ON_VEHICLE set, which leaves the whole of
    // Spell::CheckCast in the way of a cast that has no business failing -- and when it
    // does fail it says nothing, applies no SPELL_AURA_CONTROL_VEHICLE, and so never
    // queues the VehicleJoinEvent. The gnome is left standing at the spawn point and the
    // Operative walks the path with an empty back.
    bool BoardGnome(Creature* gnome)
    {
        return gnome->CastCustomSpell(VEHICLE_SPELL_RIDE_HARDCODED, SPELLVALUE_BASE_POINT0,
            SEAT_INJURED_GNOME + 1, me, TRIGGERED_FULL_MASK);
    }
};

struct npc_safe_operative_carrier : public npc_safe_operative_bearer
{
    npc_safe_operative_carrier(Creature* creature) : npc_safe_operative_bearer(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();

        // First of the three things that keep this Operative out of every fight in
        // the camp. See AttackStart and MoveInLineOfSight below for the other two.
        me->SetReactState(REACT_PASSIVE);

        ClearSpellClick();

        // Reset runs on respawn, and on anything that cuts a run short -- a grid
        // unload, a .reload. Without this the gnomes from the abandoned run stay.
        DespawnGnome(_passenger);
        DespawnGnome(_placed);

        me->SetAIAnimKitId(ANIM_KIT_CARRY);

        // Hidden immediately, not summoned hidden. SummonCreature's own
        // visibleBySummonerOnly argument does nothing to a creature: TempSummon
        // redeclares m_visibleBySummonerOnly and its accessors, shadowing WorldObject's,
        // so Map::SummonCreature writes the TempSummon copy while
        // WorldObject::CanSeeOrDetect reads the WorldObject one. Conceal goes through a
        // Creature*, which resolves to WorldObject's setter, and does hide it.
        //
        // Do not "fix" that by deleting the duplicate. Around fifteen scripts pass true
        // in that argument position with a creature summoner -- the Dun Morogh trolls,
        // Duskwood's Stitches, the Loch Modan ambushers -- and they only still appear
        // because the flag is inert. Making it work turns all of them invisible.
        //
        // Boarding is worth hiding through: the seat is filled by a VehicleJoinEvent a
        // tick after the cast and the client plays the seat's enter animation over the
        // top, so a visible gnome is seen on the ground climbing aboard. Concealed, the
        // next thing any client hears is the create block from PassengerBoarded, with
        // the gnome already carried and already turned.
        if (TempSummon* gnome = me->SummonCreature(NPC_INJURED_GNOME, me->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN))
        {
            Conceal(gnome);
            _passenger = gnome->GetGUID();
            BoardGnome(gnome);
        }

        _scheduler.Schedule(PICKUP_TO_WALK, [this](TaskContext /*task*/)
        {
            // Vehicle::AddPassenger schedules the join through a VehicleJoinEvent
            // rather than seating anyone inline, so the seat is still empty when the
            // cast returns and there is nothing to check at the call site. By now it has
            // run, so this is the first honest answer about whether the gnome is aboard.
            //
            // One retry, because an Operative walking the whole path with an empty back
            // is the failure this scene shows when boarding does not take, and it is
            // silent otherwise. Walking goes ahead either way -- a gnome that boards a
            // tick late snaps onto the back, which is better than a run that never
            // starts.
            if (Creature* gnome = ObjectAccessor::GetCreature(*me, _passenger))
            {
                if (!gnome->GetVehicle())
                {
                    TC_LOG_ERROR("scripts.ai", "npc_safe_operative_carrier: %s did not board %s, retrying",
                        gnome->GetGUID().ToString().c_str(), me->GetGUID().ToString().c_str());
                    BoardGnome(gnome);
                }
            }

            // Vehicle::Install runs after Reset, and a boarding that failed leaves a
            // seat open, so this is the one place that catches both.
            ClearSpellClick();

            // walk true is the whole reason this is MoveSmoothPath and not a chain of
            // MovePoint calls: PointMovementGenerator::DoInitialize never touches
            // MoveSplineInit::SetWalk, so a MovePoint always runs, and me->SetWalk does
            // not change that. The 60-yard path takes 26.8 seconds, which is walk speed
            // and not run.
            me->GetMotionMaster()->MoveSmoothPath(POINT_BED, CarryPathOut, std::extent<decltype(CarryPathOut)>::value, true);
        });
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        // MoveSmoothPath finishes through EffectMovementGenerator, so what comes back
        // is EFFECT_MOTION_TYPE and not the POINT_MOTION_TYPE a MovePoint would give.
        if (type != EFFECT_MOTION_TYPE)
            return;

        if (id == POINT_BED)
            PlaceGnome();
        else if (id == POINT_HOME)
            EndRun();
    }


    void UpdateAI(uint32 diff) override
    {
        // No UpdateVictim, and nothing that could acquire one. The scheduler is the
        // whole AI.
        _scheduler.Update(diff);
    }


private:

    void PlaceGnome()
    {
        // The path ends a yard short of the bed with the Operative still facing down
        // the ramp, so it is turned to face what it is about to put down.
        me->SetFacingTo(me->GetAngle(&GnomeBedPosition));

        _scheduler.Schedule(ARRIVE_TO_KNEEL, [this](TaskContext /*task*/)
        {
            me->HandleEmoteCommand(EMOTE_ONESHOT_KNEEL);
        });

        _scheduler.Schedule(ARRIVE_TO_KNEEL + KNEEL_TO_PLACE, [this](TaskContext /*task*/)
        {
            // The passenger is destroyed and a second gnome created in the bed rather
            // than being unseated: the gnome that ends up in the bed is a different
            // creature from the one that was carried. Going this way also keeps
            // Unit::_ExitVehicle out of it, which would throw the gnome clear along the
            // seat's exit arc instead of leaving it where it was set down.
            DespawnGnome(_passenger);

            // No SetStandState here, and that is the point. Setting it after the summon
            // is a visible transition -- the gnome is created on its feet and then lies
            // down in the bed with the animation played out. creature_template_addon
            // carries StandState 3 for 46447 instead, and LoadCreaturesAddon runs inside
            // Creature::UpdateEntry before the creature reaches the map, so the gnome is
            // lying down in the very first block a client receives about it.
            if (TempSummon* gnome = me->SummonCreature(NPC_INJURED_GNOME, GnomeBedPosition, TEMPSUMMON_MANUAL_DESPAWN))
            {
                _placed = gnome->GetGUID();
                gnome->CastSpell(gnome, SPELL_IRRADIATION, true);
            }
        });

        _scheduler.Schedule(ARRIVE_TO_KNEEL + KNEEL_TO_PLACE + PLACE_TO_CARRY_OFF, [this](TaskContext /*task*/)
        {
            me->SetAIAnimKitId(0);
        });

        _scheduler.Schedule(ARRIVE_TO_KNEEL + KNEEL_TO_PLACE + PLACE_TO_CARRY_OFF + CARRY_OFF_TO_WALK_BACK, [this](TaskContext /*task*/)
        {
            WalkHome();
        });

        _scheduler.Schedule(ARRIVE_TO_KNEEL + KNEEL_TO_PLACE + PLACED_GNOME_LIFETIME, [this](TaskContext /*task*/)
        {
            DespawnGnome(_placed);
        });
    }

    void WalkHome()
    {
        // The return nodes stop a couple of yards short of the spawn point. The home
        // position is appended rather than written out as an eleventh node, so that
        // moving the spawn in the database moves the end of the walk with it.
        std::vector<Position> path(std::begin(CarryPathBack), std::end(CarryPathBack));
        path.push_back(me->GetHomePosition());

        me->GetMotionMaster()->MoveSmoothPath(POINT_HOME, path.data(), path.size(), true);
    }

    void EndRun()
    {
        me->SetFacingTo(me->GetHomePosition().GetOrientation());

        // PLACED_GNOME_LIFETIME has already collected the gnome by now. This is for the
        // run that somehow gets here first: nothing else would come to clear the bed.
        DespawnGnome(_placed);

        // Each run is made by a fresh Operative rather than by one looping in place, so
        // the spawn despawns and comes back. The respawn re-enters Reset and the next
        // run sets off.
        me->DespawnOrUnsummon(RETURN_TO_DESPAWN, RESPAWN_DELAY);
    }

    void DespawnGnome(ObjectGuid& guid)
    {
        if (Creature* gnome = ObjectAccessor::GetCreature(*me, guid))
        {
            // Unsummoning a seated passenger goes through Unit::_ExitVehicle, which
            // unroots it and launches a spline that falls and lands beside the vehicle:
            // the gnome visibly hops out of the Operative's arms and only then vanishes.
            // Hiding it first means that spline is launched for something no client is
            // drawing any more, so what is seen is the gnome going out while still held.
            Conceal(gnome);
            gnome->DespawnOrUnsummon();
        }

        guid.Clear();
    }

    ObjectGuid _passenger;
    ObjectGuid _placed;
    TaskScheduler _scheduler;
};

enum SafeOperativeMedic
{
    // Each kneeling Operative and the casualty it holds. Fixed pairs, so they are named
    // rather than found by proximity: the wrong gnome is only 4.8 yards from the lower
    // Operative, close enough that a radius search would be a coin toss.
    GUID_MEDIC_UPPER    = 168986,
    GUID_CASUALTY_UPPER = 168987,
    GUID_MEDIC_LOWER    = 169017,

    // Not 169004. That one lies in the bed on its own; 169017 was moved onto its real
    // post and given 985000 to hold there.
    GUID_CASUALTY_LOWER = 985000,

    // A group each, not one group of two. Neither Operative rotates its line -- each
    // said the same one every time it spoke, three times apiece, which is not chance.
    SAY_MEDIC_UPPER     = 0,
    SAY_MEDIC_LOWER     = 1
};

// Between one Operative's repeats the gap was 85 seconds and then 161, and for the other
// 75 and then 145. The wide ones are barks that went out while the player was too far
// away to be sent them, so the period is the short one.
static constexpr Seconds MEDIC_BARK_MIN = Seconds(70);
static constexpr Seconds MEDIC_BARK_MAX = Seconds(90);

// Two Operatives down in the camp, each kneeling over an Injured Gnome it is holding and
// talking to. The holding is the same vehicle seat the carrier uses -- the gnome sits in
// the arms because of the seat, not because of the animation -- and the difference from
// the carrier is that these two never set the gnome down and never go anywhere.
struct npc_safe_operative_medic : public npc_safe_operative_bearer
{
    npc_safe_operative_medic(Creature* creature) : npc_safe_operative_bearer(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();

        me->SetReactState(REACT_PASSIVE);
        ClearSpellClick();

        // The kneel and the carry compose: creature_addon puts both spawns in
        // StandState 8, UNIT_STAND_STATE_KNEEL, and the carry kit lays the arms over the
        // top of it. Kit 989 is the same one the carrier holds while it walks.
        //
        // What must not be set alongside it is UNIT_NPC_EMOTESTATE. An earlier attempt
        // added EMOTE_STATE_KNEEL as well, on the assumption that it would reinforce the
        // kneel, and it did the opposite -- the emote state displaced the stand state and
        // left them standing up carrying a gnome. The stand state belongs to
        // creature_addon and nothing here should touch it.
        me->SetAIAnimKitId(ANIM_KIT_CARRY);

        // The casualty is a database spawn rather than a summon, so it is already in the
        // world and only has to be seated.
        if (Creature* gnome = FindCasualty())
            if (!gnome->GetVehicle())
                BoardGnome(gnome);

        _scheduler.Schedule(MEDIC_BARK_MIN, MEDIC_BARK_MAX, [this](TaskContext task)
        {
            Talk(BarkGroup());
            task.Repeat(MEDIC_BARK_MIN, MEDIC_BARK_MAX);
        });

        // Vehicle::Install runs after Reset -- Creature::AddToWorld calls it after
        // AIM_Initialize -- so the cog it puts on has to come off again once it has.
        // This also picks up a casualty that did not board first time; boarding is
        // asynchronous, so it cannot be checked any earlier than this.
        _scheduler.Schedule(Seconds(3), [this](TaskContext task)
        {
            ClearSpellClick();

            if (Creature* gnome = FindCasualty())
            {
                if (!gnome->GetVehicle())
                {
                    TC_LOG_ERROR("scripts.ai", "npc_safe_operative_medic: %s is not holding casualty " UI64FMTD ", retrying",
                        me->GetGUID().ToString().c_str(), uint64(CasualtySpawnId()));
                    BoardGnome(gnome);
                    task.Repeat(Seconds(10));
                }
            }
            else
                TC_LOG_ERROR("scripts.ai", "npc_safe_operative_medic: %s found no casualty " UI64FMTD " to hold",
                    me->GetGUID().ToString().c_str(), uint64(CasualtySpawnId()));
        });
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    bool IsLower() const { return me->GetSpawnId() == GUID_MEDIC_LOWER; }

    ObjectGuid::LowType CasualtySpawnId() const
    {
        return IsLower() ? GUID_CASUALTY_LOWER : GUID_CASUALTY_UPPER;
    }

    uint8 BarkGroup() const { return IsLower() ? SAY_MEDIC_LOWER : SAY_MEDIC_UPPER; }

    Creature* FindCasualty() const
    {
        auto bounds = me->GetMap()->GetCreatureBySpawnIdStore().equal_range(CasualtySpawnId());
        return bounds.first != bounds.second ? bounds.first->second : nullptr;
    }

    TaskScheduler _scheduler;
};

enum PhysiciansAssistantGreeter
{
    NPC_RESCUED_SURVIVOR   = 46267,

    // "Teleport" -- a one second dummy with a server-side script and no effect of its
    // own. The gnome casts it on itself the instant it is summoned, and it is the whole
    // of the arrival effect: the flash rides on SpellXSpellVisualID 312, which the
    // client resolves by itself. Nothing else is sent, so there is no visual kit or
    // gameobject animation to go looking for.
    SPELL_TELEPORT         = 7791,

    // creature_text group 0 on 46267 -- the seven lines an arrival can call out.
    SAY_ARRIVAL            = 0,

    // creature_text group 0 on 42552 -- "Ah, a new arrival. Right this way, sir."
    SAY_GREETING           = 0,

    // The cleared emote state. SharedDefines has EMOTE_STATE_NONE, but that is 30 and
    // is an emote in its own right; an empty field is 0 and has no name there.
    EMOTE_STATE_NO_EMOTE   = 0,

    // The gnome's legs; nothing on this script hears about them, because its
    // MovementInform goes to the entry's default AI.
    POINT_LEG              = 1,

    // The Assistant's three, each answered to turn it the right way on arrival.
    POINT_MEET             = 2,
    POINT_POST             = 3,
    POINT_ASSISTANT_HOME   = 4
};

// The arrival plays one of these with its line, a tenth of a second ahead of the text.
// Four runs gave three different emotes against four different texts, and the two runs
// that shared an emote did not share a line, so the roll is separate from the line and
// not a property of it -- which is also what the client data says, every one of the
// seven broadcast texts carrying EmoteID 0.
static constexpr Emote ARRIVAL_EMOTES[] =
{
    EMOTE_ONESHOT_TALK,
    EMOTE_ONESHOT_EXCLAMATION,
    EMOTE_ONESHOT_BEG
};

// Every beat of the run, measured from the moment the gnome appears. The cycle comes to
// about 61 seconds and repeats unattended. These are the intervals the scene was built
// on rather than values chosen to taste: it ran five times in a row to the same clock.
static constexpr Milliseconds ARRIVE_TO_EMOTE   = Milliseconds(2067);
static constexpr Milliseconds ARRIVE_TO_SAY     = Milliseconds(2167);
static constexpr Milliseconds ARRIVE_TO_SET_OFF = Milliseconds(6889);
static constexpr Milliseconds ARRIVE_TO_POINT   = Milliseconds(10071);
static constexpr Milliseconds ARRIVE_TO_GREET   = Milliseconds(10229);
static constexpr Milliseconds ARRIVE_TO_LEAD    = Milliseconds(15007);
static constexpr Milliseconds ARRIVE_TO_FOLLOW  = Milliseconds(15400);
static constexpr Milliseconds ARRIVE_TO_POST    = Milliseconds(22683);
static constexpr Milliseconds ARRIVE_TO_SIT     = Milliseconds(27543);
static constexpr Milliseconds ARRIVE_TO_GO_HOME = Milliseconds(38471);
static constexpr Milliseconds ARRIVE_TO_DESPAWN = Milliseconds(48591);
static constexpr Milliseconds CYCLE             = Milliseconds(61073);

// Where the scene turns someone to face when it puts them down somewhere. Every one of
// these is sent as a facing-only spline when the walk ends -- Face 3 (Angle) with no
// path -- rather than being left to the direction of travel, and every one is a whole
// number of degrees, so they are authored values and not something to recompute.
//
// Two of them are corroborated by the spawns this scene replaced: 0.71558 is the
// orientation creature 167917 was standing at, which was the post, and 4.38078 was
// 168909's, which was the mat. Both were stand-ins posed from this scene.
static constexpr float FACING_MEET = 4.2411499f;   // 243 degrees, turned towards the gnome
static constexpr float FACING_POST = 0.7155849f;   //  41 degrees, over the mat
static constexpr float FACING_MAT  = 4.3807764f;   // 251 degrees, the gnome once it sits
// The Assistant's facing at home is 1.39626 -- 80 degrees -- and lives on the spawn in
// creature.orientation rather than here, because that is where a home facing belongs.

// The Gnomeregan Teleporter, gameobject guid 156676, sits at (-5161.78, 754.694). The
// gnome is put down on it facing 1.88496 -- position and facing both taken from
// creature 168936, the static Rescued Survivor that used to stand here and that this
// scene replaces.
Position const TeleporterPad = { -5161.76f, 754.665f, 286.039f, 1.88496f };

// Every route below is written out rather than left to pathfinding.
//
// The room has a table and four chairs standing between the Assistant's spot and the
// teleporter, and the scene walks around them -- the run over covers 12.4 yards in a
// straight line and 21.9 as travelled. None of that furniture is in the navmesh, which
// is built from terrain and statics and knows nothing about gameobject spawns, so
// asking the pathfinder for these legs gets a straight line through the table. The
// nodes here are the route itself, thinned to about a yard apart.
//
// Element 0 of a MoveSmoothPath array is never a destination: MoveSplineInit::Launch
// overwrites it with the mover's real position. Each of these therefore begins at the
// point the mover is standing on when the leg goes out, which is what that element
// records.

// The Assistant's route, out and back. Retail sends the way out as one spline and the
// way back as four, but the four trace this same corridor to within a yard the whole
// way, so it is one route used in both directions and the two cannot drift apart.
Position const AssistantRoute[] =
{
    { -5164.960f,  775.741f,  287.387f },
    { -5161.360f,  774.341f,  287.489f },
    { -5157.610f,  772.341f,  287.489f },
    { -5157.110f,  771.091f,  287.489f },
    { -5155.610f,  769.091f,  287.489f },
    { -5155.860f,  767.841f,  287.489f },
    { -5157.360f,  766.591f,  287.489f },
    { -5158.360f,  766.091f,  286.989f },
    { -5159.110f,  765.591f,  286.489f },
    { -5160.360f,  765.091f,  285.989f },
    { -5161.860f,  764.341f,  285.989f },
    { -5163.260f,  763.441f,  285.591f }
};

// Where the Assistant stands over the gnome once it is on the mat. It sits a yard off
// the second node of the route above, so the walk back stops here instead of carrying
// on to the spot it idles at.
Position const AssistantPost = { -5161.370f, 775.453f, 287.387f };

// The gnome steps off the pad onto the last of these and waits there to be greeted.
Position const ArrivalStepOff[] =
{
    { -5161.760f,  754.665f,  286.039f },
    { -5162.359f,  756.349f,  285.815f },
    { -5163.959f,  759.533f,  285.591f }
};

// The rest of its walk, ending on Gnomeregan Mat 156538 at (-5160.01, 776.535). No
// facing is sent when it stops, so it sits looking the way it was walking, and nothing
// here sets one.
Position const ArrivalWalkToMat[] =
{
    { -5163.959f,  759.533f,  285.591f },
    { -5160.315f,  763.541f,  285.897f },
    { -5159.631f,  764.028f,  286.306f },
    { -5158.881f,  764.528f,  286.556f },
    { -5158.032f,  764.839f,  287.158f },
    { -5157.401f,  765.642f,  287.273f },
    { -5156.151f,  768.142f,  287.523f },
    { -5155.651f,  768.892f,  287.523f },
    { -5156.277f,  769.899f,  287.387f },
    { -5156.798f,  771.162f,  287.637f },
    { -5157.298f,  771.912f,  287.637f },
    { -5158.048f,  773.412f,  287.637f },
    { -5159.298f,  776.412f,  287.637f },
    { -5159.820f,  776.925f,  287.387f }
};

// The last node of that walk is the mat itself, which is what the gnome is sat down on.
static Position const& ArrivalMat()
{
    return ArrivalWalkToMat[std::extent<decltype(ArrivalWalkToMat)>::value - 1];
}

// How close to the mat counts as having got there. The walk ends on it, so this only has
// to be wide enough to cover a spline stopping a little short.
static constexpr float MAT_ARRIVAL_TOLERANCE = 3.0f;

// The way back: the route above walked backwards, stopping at the post.
static std::vector<Position> AssistantRouteBack()
{
    std::vector<Position> route;
    route.reserve(std::extent<decltype(AssistantRoute)>::value);
    for (size_t i = std::extent<decltype(AssistantRoute)>::value; i-- > 0; )
        route.push_back(AssistantRoute[i]);

    route.back() = AssistantPost;
    return route;
}

// Walk a written-out route. MoveSmoothPath sends it as one spline, which is how retail
// sends the way out; the way back arrives there as four splines, but each is issued
// while the one before it is still running, so what is walked is one continuous line
// either way.
static void WalkRoute(Unit* mover, uint32 pointId, Position const* route, size_t count)
{
    // MoveSplineInit reads args.walk off MOVEMENTFLAG_WALKING in its constructor, so
    // this has to be set before the generator builds the spline.
    mover->SetWalk(true);
    mover->GetMotionMaster()->MoveSmoothPath(pointId, route, count, true);
}

// The Physician's Assistant beside the Gnomeregan Teleporter, creature guid 167917.
// Every minute a rescued gnome is teleported in; the Assistant hurries over, points it
// towards a mat, leads it there, stands over it while it rests, and goes back to its own
// spot. The gnome is taken away again before the next one arrives.
//
// The gnome is a summon with no AI of its own and every beat of its run is driven from
// here. Two spawns of 42552 stand in the Loading Room and only this one is the scene:
// the other, 167775, is a plain static NPC, so the script is on the spawn rather than on
// the entry.
//
// Every beat is on the clock rather than chained off arrivals, because that is how the
// scene is actually built -- legs go out while the previous one is still running. The
// one exception is the walk home, which is answered so the Assistant's facing can be put
// back once it is actually standing there.
//
// Not SmartAI. The run drives a second creature's movement, stand state and speech
// across five legs, and SMART_ACTION has no way to walk a creature that is not the one
// the script is attached to.
struct npc_physicians_assistant_greeter : public ScriptedAI
{
    npc_physicians_assistant_greeter(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();

        // Reset runs on respawn and on anything that cuts a run short -- a grid unload,
        // a .reload. Without this the gnome from the abandoned run is left sitting on
        // the mat with nothing coming to collect it.
        DespawnArrival();

        // The emote state is taken partway through every run, so a run cut short leaves
        // it on. It belongs to the scene rather than to the spawn, and creature_addon
        // does not carry it.
        me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NO_EMOTE);

        me->SetReactState(REACT_PASSIVE);

        StartRun();
    }

    // The Assistant never fights. A victim means ChaseMovementGenerator takes
    // MOTION_SLOT_ACTIVE off whichever leg is running, and the run carries on through
    // the timers with the Assistant standing somewhere else entirely. REACT_PASSIVE
    // stops it choosing a target; these two stop anything else handing it one.
    void AttackStart(Unit* /*who*/) override { }
    void MoveInLineOfSight(Unit* /*who*/) override { }

    void MovementInform(uint32 type, uint32 id) override
    {
        // MoveSmoothPath finishes through EffectMovementGenerator, so arrivals come back
        // as EFFECT_MOTION_TYPE and not the POINT_MOTION_TYPE a MovePoint would give.
        //
        // A walk that ends without one of these leaves the Assistant looking whichever
        // way the last node pointed it, which on the way back is straight at the wall.
        if (type != EFFECT_MOTION_TYPE)
            return;

        if (id == POINT_MEET)
            me->SetFacingTo(FACING_MEET);
        else if (id == POINT_POST)
            me->SetFacingTo(FACING_POST);
        else if (id == POINT_ASSISTANT_HOME)
            me->SetFacingTo(me->GetHomePosition().GetOrientation());
    }

    void UpdateAI(uint32 diff) override
    {
        // No UpdateVictim, and nothing that could acquire one. The scheduler is the
        // rest of the AI.
        _scheduler.Update(diff);

        // The gnome sits down when it gets to the mat rather than when the clock says it
        // should. It is a summon carrying the entry's default AI, so its MovementInform
        // goes there and never reaches this script -- watching its spline is the way to
        // hear about the arrival from outside it. The scheduler is updated first, so a
        // leg issued this tick has already been launched and cannot read as finished.
        if (!_seating)
            return;

        Creature* arrival = GetArrival();
        if (!arrival)
        {
            _seating = false;
            return;
        }

        if (!arrival->movespline->Finalized() || arrival->GetExactDist(&ArrivalMat()) > MAT_ARRIVAL_TOLERANCE)
            return;

        SeatArrival();
    }

private:

    void StartRun()
    {
        _scheduler.Schedule(Milliseconds(1), [this](TaskContext run)
        {
            SummonArrival();
            run.Repeat(CYCLE);
        });
    }

    void SummonArrival()
    {
        // Nothing is concealed here, deliberately. Retail creates the gnome and starts
        // the cast in the same instant -- the create block and SMSG_SPELL_START share a
        // timestamp -- and the flash lands with SMSG_SPELL_GO 0.8 seconds later, so the
        // gnome is briefly standing there before the effect goes off. That has been
        // checked in game on retail and it is what it does.
        //
        // Summoning it hidden and revealing it on the flash was tried and reverted. It
        // is a tighter effect and it is not this one. If it comes up again, the reason
        // it is not done is that it looks less like retail, not that it does not work.
        TempSummon* arrival = me->SummonCreature(NPC_RESCUED_SURVIVOR, TeleporterPad, TEMPSUMMON_MANUAL_DESPAWN);
        if (!arrival)
            return;

        _arrival = arrival->GetGUID();

        // Not triggered, so the cast runs its one second and the client is sent
        // SMSG_SPELL_START and then SMSG_SPELL_GO, which is the pair retail sends. A
        // triggered cast collapses that into the second one and the flash arrives with
        // the gnome instead of shortly after it -- which is the wrong timing here, even
        // though it is the neater one.
        arrival->CastSpell(arrival, SPELL_TELEPORT, false);

        // 46267 carries four gnome models in creature_template and the summon picks one
        // at random the same way any spawn of the entry does. Nothing here chooses it.

        _scheduler.Schedule(ARRIVE_TO_EMOTE, [this](TaskContext /*task*/)
        {
            if (Creature* arrival = GetArrival())
                arrival->HandleEmoteCommand(ARRIVAL_EMOTES[urand(0, std::extent<decltype(ARRIVAL_EMOTES)>::value - 1)]);
        });

        _scheduler.Schedule(ARRIVE_TO_SAY, [this](TaskContext /*task*/)
        {
            if (Creature* arrival = GetArrival())
                arrival->AI()->Talk(SAY_ARRIVAL);
        });

        _scheduler.Schedule(ARRIVE_TO_SET_OFF, [this](TaskContext /*task*/)
        {
            // The gnome steps off the pad and the Assistant leaves its spot in the same
            // instant, so that the two meet.
            if (Creature* arrival = GetArrival())
                WalkRoute(arrival, POINT_LEG, ArrivalStepOff, std::extent<decltype(ArrivalStepOff)>::value);

            // The one leg in the scene that is run rather than walked: the Assistant
            // hurries over to a gnome that has just appeared, 21.9 yards in 2.9 seconds.
            // That is 8 yards a second, which is what creature_template.speed_run
            // 1.14286 already gives it, so no speed is set here.
            me->SetWalk(false);
            me->GetMotionMaster()->MoveSmoothPath(POINT_MEET, AssistantRoute,
                std::extent<decltype(AssistantRoute)>::value, false);
        });

        _scheduler.Schedule(ARRIVE_TO_POINT, [this](TaskContext /*task*/)
        {
            // 25 OneShotPoint is the only emote the Assistant ever plays.
            me->HandleEmoteCommand(EMOTE_ONESHOT_POINT);
        });

        _scheduler.Schedule(ARRIVE_TO_GREET, [this](TaskContext /*task*/)
        {
            if (Creature* arrival = GetArrival())
                Talk(SAY_GREETING, arrival);
            else
                Talk(SAY_GREETING);
        });

        _scheduler.Schedule(ARRIVE_TO_LEAD, [this](TaskContext /*task*/)
        {
            // Back down the same corridor, on foot this time, stopping at the post. It
            // leads rather than follows: it sets off first and is standing over the mat
            // before the gnome gets there.
            std::vector<Position> const route = AssistantRouteBack();
            WalkRoute(me, POINT_POST, route.data(), route.size());
        });

        _scheduler.Schedule(ARRIVE_TO_FOLLOW, [this](TaskContext /*task*/)
        {
            if (Creature* arrival = GetArrival())
            {
                WalkRoute(arrival, POINT_LEG, ArrivalWalkToMat, std::extent<decltype(ArrivalWalkToMat)>::value);
                _seating = true;
            }
        });

        _scheduler.Schedule(ARRIVE_TO_POST, [this](TaskContext /*task*/)
        {
            // Beside the mat, at its work, for as long as the gnome is sitting there.
            me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_USE_STANDING);
        });

        _scheduler.Schedule(ARRIVE_TO_SIT, [this](TaskContext /*task*/)
        {
            // A backstop, and normally already spent: the gnome sits the moment it
            // reaches the mat, which on this route is a few seconds before this fires.
            // This is only what catches a walk that never arrives -- something in the
            // way, a spline that failed to launch -- so that it is sitting by the time
            // the Assistant is standing over it either way.
            if (_seating)
                SeatArrival();
        });

        _scheduler.Schedule(ARRIVE_TO_GO_HOME, [this](TaskContext /*task*/)
        {
            me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NO_EMOTE);

            // Straight back to the spot it idles at -- retail sends this last leg with
            // no intermediate nodes at all, so there is no corner to go round. The home
            // position rather than a written-out node, so that moving the spawn in the
            // database moves the end of the walk with it.
            Position const home[] = { me->GetPosition(), me->GetHomePosition() };
            me->SetWalk(true);
            me->GetMotionMaster()->MoveSmoothPath(POINT_ASSISTANT_HOME, home, 2, true);
        });

        _scheduler.Schedule(ARRIVE_TO_DESPAWN, [this](TaskContext /*task*/)
        {
            DespawnArrival();
        });
    }

    void SeatArrival()
    {
        _seating = false;

        Creature* arrival = GetArrival();
        if (!arrival)
            return;

        // Turned before it is sat down, and in that order: the walk ends heading
        // north-west into the wall, so a gnome that sits on the direction it arrived on
        // has its back to the room. Retail sends the turn and the stand state in the
        // same instant, the turn first.
        arrival->SetFacingTo(FACING_MAT);
        arrival->SetStandState(UNIT_STAND_STATE_SIT);
    }

    Creature* GetArrival()
    {
        return ObjectAccessor::GetCreature(*me, _arrival);
    }

    void DespawnArrival()
    {
        if (Creature* arrival = GetArrival())
            arrival->DespawnOrUnsummon();

        _arrival.Clear();
        _seating = false;
    }

    ObjectGuid _arrival;
    bool _seating = false;
    TaskScheduler _scheduler;
};

enum TargetAcquisitionDevice
{
    // The Crazed Leper Gnomes loose in the Train Depot. Not 46391, which is the entry
    // the Operatives outside the camp spar with.
    NPC_ABDUCTION_TARGET     = 46363,

    // 85771 is the beam and the only art in this chain: it is a two second channel
    // reaching 30 yards, and it carries SpellVisual 18310. 85772 seats the gnome through
    // SPELL_AURA_CONTROL_VEHICLE and has no SpellXSpellVisual row at all, so it draws
    // nothing on its own.
    SPELL_TAD_TRACTOR_BEAM   = 85771,
    SPELL_RIDE_TAD           = 85772,

    NPC_SAFE_OPERATIVE_LINE  = 45847,
    NPC_SAFE_OFFICER_LINE    = 46025,

    // The Officer's own shot, and what 46025 carries as creature_template.spell1. It is
    // the shot its equipment is for: creature_equip_template gives 46025 item 61392, an
    // off-hand pistol, and leaves its ranged slot empty, so the rifle shot the Operatives
    // fire was never the Officer's to make.
    //
    // 85687 brings its own SpellVisual, 18125, which is the pistol's, so unlike
    // SPELL_SHOOT it is cast and left alone -- no kit is replayed on top of it. 18125's
    // fire kit, 17077, does carry a SpellVisualKitModelAttach, at AttachmentID 21 rather
    // than the 34 that put a foreign rifle on the Operatives; if the Officer's pistol
    // does turn out to change for the shot, that attach is where to look.
    //
    // RangeIndex 54, five to thirty yards, and the five is a real minimum. The two
    // Officers stand 8.3 and 9.3 yards from their drop points, so there is room, but a
    // drop that ended much closer would start coming back refused.
    SPELL_OFFICER_SHOOT      = 85687,

    SEAT_ABDUCTED_GNOME      = 0,

    POINT_TAD_TARGET         = 10,
    POINT_TAD_DROP           = 11,
    POINT_TAD_ROAM           = 12,
    POINT_TAD_HOME           = 13,

    // The device hands its gnome to the squad through UnitAI::SetGUID, which is a no-op
    // on every AI that does not override it -- so the sparring Operatives standing a few
    // yards away hear this and correctly ignore it.
    DATA_FIRING_SQUAD_TARGET = 1
};

// Three of the thirteen posts take their gnome to a firing squad instead of holding it
// where they caught it; the other ten drift around their post until they let go. Each of
// the three stops eight or nine yards short of the squad -- the gnome is put in range to
// be shot, not delivered to their feet.
struct TadPost
{
    float PostX, PostY;
    float DropX, DropY, DropZ;
};

static constexpr TadPost TadCarryPosts[] =
{
    { -5014.29f, 789.721f, -5022.53f, 793.59f, 285.38f },   // squad on the west platform
    { -4967.99f, 734.731f, -4959.04f, 735.21f, 283.24f },   // squad on the east walk
    { -4989.07f, 767.175f, -4985.25f, 776.79f, 295.26f }    // the pair in the middle
};

// How close a device's home has to sit to a listed post to count as that post.
static constexpr float TAD_POST_MATCH = 2.0f;

// A device with nowhere to be drifts this far from its post, and picks a new spot this
// often, which adds up to roughly the ground a held gnome covers before it is dropped.
static constexpr float TAD_ROAM_RADIUS = 10.0f;
static constexpr Milliseconds TAD_ROAM_INTERVAL = Milliseconds(4000);

// The squad shoots what it is handed, from where it stands, and stops when the gnome is
// dead or out of reach.
static constexpr float SQUAD_FIRE_RANGE = 40.0f;
static constexpr Seconds SQUAD_SHOT_MIN = Seconds(2);
static constexpr Seconds SQUAD_SHOT_MAX = Seconds(3);
static constexpr float SQUAD_ALERT_RANGE = 25.0f;

// Volleys after which a gnome that is still standing means the shot is not landing.
static constexpr uint32 SQUAD_SHOTS_BEFORE_DOUBT = 8;

// The faction the gnome wears while it is being executed.
//
// 46363 is faction 36 and is nobody's enemy, so Spell::CheckCast refuses every shot at
// it on target validity, and a triggered cast does not help: the implicit target
// selection drops a unit that is not a valid attack target, so the cast goes out and the
// effect reaches nothing. The gnome has to actually be shootable.
//
// 14 is not an arbitrary pick -- it is what 46391, the game's own hostile Crazed Leper
// Gnome, already wears. This is set on the single gnome being executed rather than on
// creature_template, so the other forty stay as they are and no player walking through
// the depot is set upon.
static constexpr uint32 FACTION_CONDEMNED_GNOME = 14;

// The beam's own range. The sweep is wider because a device whose post has nothing
// that close closes the distance instead of standing idle.
static constexpr float TAD_BEAM_RANGE   = 30.0f;
static constexpr float TAD_SEARCH_RANGE = 60.0f;

// Wide enough to reach every other device in the depot, so two of them cannot settle on
// the same gnome from opposite ends of the camp.
static constexpr float TAD_PEER_RANGE   = 150.0f;

// A roaming device is out for a little under thirty-four seconds: about two and a half
// spent choosing, two channelling, twenty-nine holding, and it is back five seconds after
// it goes. A device with a firing squad runs longer and to no fixed length -- the hold
// stops governing it once it has arrived, and what is left is the execution and the
// flight home.
static constexpr Milliseconds TAD_ACQUIRE_DELAY = Milliseconds(2400);
static constexpr Milliseconds TAD_BEAM_CHANNEL  = Milliseconds(2000);
static constexpr Milliseconds TAD_RETRY_DELAY   = Milliseconds(1000);
static constexpr Seconds      TAD_HOLD_TIME     = Seconds(29);
static constexpr Seconds      TAD_RESPAWN_DELAY = Seconds(5);

// A device that reaches a firing squad holds the gnome up until the squad has killed it,
// and the hold above stops governing the run. The cap is only here so a shot that never
// lands cannot strand a device over the depot for ever: one volley of 208193 is several
// times a Crazed Leper Gnome's health, so a shot that connects ends the execution
// immediately and the next poll starts the walk back.
static constexpr Milliseconds TAD_EXECUTION_LIMIT = Milliseconds(20000);
static constexpr Milliseconds TAD_EXECUTION_POLL  = Milliseconds(500);

// Unit::setDeathState unseats the gnome itself, so the body is already falling out of the
// beam by the time the device notices the kill. The device holds its position over it for
// this long -- the fall, and a beat after it -- before turning for home. Going the moment
// the body was clear read as the device being switched off rather than as one finishing a
// job.
static constexpr Milliseconds TAD_LINGER_AFTER_KILL = Milliseconds(5000);

// A device that is done with a gnome flies back to its own post before it goes, so the
// despawn happens where the respawn will put it back rather than over the firing squad.
// The backstop covers a return that never arrives -- a blocked path, a post that moved --
// so a device cannot hang over the depot for ever with nothing left to do.
static constexpr Milliseconds TAD_RETURN_BACKSTOP = Milliseconds(15000);

// Acquire runs once a second, so this is half a minute of a device finding nothing.
static constexpr uint32 TAD_EMPTY_TRIES_BEFORE_DOUBT = 30;

// Re-path only once the gnome has walked this far from where the approach was aimed,
// so a wandering target does not restart the spline on every poll.
static constexpr float TAD_REPATH_TOLERANCE = 5.0f;

// A gnome in a device's grip is cargo, not a combatant. Boarding a vehicle seat settles
// where it is drawn and nothing else about it: a gnome that was mid-fight when the beam
// took it goes on swinging from the air, and one the firing squad shoots at answers by
// picking a target of its own. UNIT_FLAG_PACIFIED is refused by Unit::Attack outright,
// UNIT_FLAG_SILENCED by Spell::CheckCast, and REACT_PASSIVE stops it looking for anyone
// to use either on -- so CreatureAI::AttackedBy, the one route into a fight that does
// not go through target selection, finds nothing it is allowed to do.
//
// Movement needs nothing: the seat holds it.
static void RestrainGnome(Creature* gnome)
{
    gnome->SetReactState(REACT_PASSIVE);
    gnome->AttackStop();
    gnome->CombatStop(true);
    gnome->DeleteThreatList();
    gnome->SetTarget(ObjectGuid::Empty);
    gnome->SetFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_PACIFIED | UNIT_FLAG_SILENCED);
}

// Being held is no obstacle to being shot. VehicleSeat 8658, the device's only seat,
// does not carry VEHICLE_SEAT_FLAG_PASSENGER_NOT_SELECTABLE, so nothing puts
// UNIT_FLAG_NOT_SELECTABLE on the passenger and Unit::_IsValidAttackTarget has no
// quarrel with a gnome in the air; and Creature::Relocate drives
// Vehicle::RelocatePassengers, so the gnome's position tracks the device and the squad's
// range check reads the beam rather than the floor the gnome was lifted off.
//
// What is left is the faction, which is the whole of it.
static void CondemnGnome(Creature* gnome)
{
    gnome->setFaction(FACTION_CONDEMNED_GNOME);
}

// Undoes both of the above, and every path that lets go of a gnome comes through it --
// including the one where it is let go because it is dead. The faction has to come off
// the body: Creature::Respawn restores a template faction only through UpdateEntry and
// calls that only when the entry changed, which it never does here.
//
// REACT_AGGRESSIVE rather than a remembered value, because that is what
// Creature::InitializeReactState gives 46363 -- type 7, and no totem, trigger or critter.
static void ReleaseGnome(Creature* gnome)
{
    gnome->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_PACIFIED | UNIT_FLAG_SILENCED);
    gnome->SetReactState(REACT_AGGRESSIVE);
    gnome->RestoreFaction();
}

// The devices hanging over the Train Depot pick a Crazed Leper Gnome off the floor and
// hold it up for half a minute. Ten of them drift around their post and put it back; the
// three that have a firing squad carry it over and hold it there to be shot.
//
// The interesting part is the choosing: a gnome already in a seat, or already spoken for
// by a device still on its way over, has to be invisible to every other device, or
// several of them converge on one gnome and the rest of the floor is never touched.
//
// The claim lives on the AI that made it and is read back out through UnitAI::GetGUID
// rather than kept in a registry beside the class. A device that despawns at the end of
// its run, or leaves with its grid, or is dropped by a .reload, takes its claim with it;
// a registry would need every one of those paths to remember to clean up, and the one
// that forgot would lock a gnome out permanently.
struct npc_target_acquisition_device : public ScriptedAI
{
    npc_target_acquisition_device(Creature* creature) : ScriptedAI(creature) { }

    // What the other devices ask. Empty until this one has settled on a gnome.
    ObjectGuid GetGUID(int32 /*id*/) const override { return _claimed; }

    void Reset() override
    {
        _scheduler.CancelAll();

        // The device flies, and it is the core that decides so: 46012 is InhabitType 4,
        // and Creature::UpdateMovementFlags reads that every tick and hands out
        // MOVEMENTFLAG_DISABLE_GRAVITY while the device is off the ground. It gets that
        // right on the first spawn and never again, because the despawn at the end of a
        // run poisons it.
        //
        // ReleaseAndDespawn goes through Creature::ForcedDespawn, which kills the device
        // first -- and Creature::setDeathState JUST_DIED drops a flying corpse with
        // MotionMaster::MoveFall (Creature.cpp:1840). MoveFall's first act is
        // SetFall(true) (MotionMaster.cpp:653), and RemoveCorpse, which follows
        // immediately, only calls StopMoving: the spline ends, the flag does not.
        //
        // So the device comes back five seconds later still flagged as falling, and the
        // two halves of UpdateMovementFlags are then deadlocked against each other. It
        // will not give an airborne creature disable-gravity while IsFalling() is true,
        // and it only clears the fall for a creature that is *not* airborne -- and the
        // device respawns at its post, well off the depot floor. Neither condition can
        // be met, and the tick that would fix it re-asserts it instead.
        //
        // A device in that state is a ground unit as far as the client is concerned: it
        // drops to the floor on sight and is snapped back up by every spline the script
        // sends, which is the falling-and-teleporting the runs turned into. Clearing the
        // fall here is what breaks the deadlock -- the next tick then sees an airborne
        // creature that is not falling and gives the gravity back on its own. It is set
        // directly as well so the first frame after the respawn is already right.
        me->SetFall(false);
        me->SetDisableGravity(true);

        // A run cut short -- a grid unload, a .reload -- leaves its gnome restrained and
        // possibly condemned, and a condemned gnome that is simply forgotten is a hostile
        // creature standing in the middle of the depot. A despawn unseats it through
        // Vehicle::Uninstall and that comes back as PassengerBoarded, but a Reset that
        // does not go through one does not, so the previous run's claim is let go by hand
        // before it is cleared.
        if (Creature* gnome = ObjectAccessor::GetCreature(*me, _claimed))
            ReleaseGnome(gnome);

        _claimed.Clear();
        _falling.Clear();
        _blind = 0;
        _emptyTries = 0;
        _approaching = false;
        _executing = false;
        _leaving = false;
        _executionLeft = TAD_EXECUTION_LIMIT;
        _carry = nullptr;

        // From the spawn row, not from GetHomePosition. Creature::LoadCreatureFromDB calls
        // Create() -- which reaches AIM_Initialize and therefore this Reset -- a few lines
        // before it calls SetHomePosition (Creature.cpp:1528 and :1532), so the home
        // position is not dependable this early. The spawn data is.
        if (CreatureData const* data = me->GetCreatureData())
        {
            for (TadPost const& post : TadCarryPosts)
                if (std::hypot(data->posX - post.PostX, data->posY - post.PostY) <= TAD_POST_MATCH)
                {
                    _carry = &post;
                    break;
                }
        }
        else
            TC_LOG_ERROR("scripts.ai", "npc_target_acquisition_device: %s has no spawn data, cannot tell whether it carries",
                me->GetGUID().ToString().c_str());

        // The device is scenery with a job; a victim would put a ChaseMovementGenerator
        // on MOTION_SLOT_ACTIVE and take the approach spline off it. AttackStart and
        // MoveInLineOfSight below close the two routes REACT_PASSIVE leaves open.
        me->SetReactState(REACT_PASSIVE);

        ClearVehicleSpellClick(me);

        _scheduler.Schedule(TAD_ACQUIRE_DELAY, [this](TaskContext task) { Acquire(task); });
    }

    void AttackStart(Unit* /*who*/) override { }
    void MoveInLineOfSight(Unit* /*who*/) override { }

    // Every gnome that boards is restrained here and every gnome that leaves the seat is
    // let go here, whichever way it leaves -- the hold running out, the device being
    // reset, or Unit::setDeathState unseating the body of one the squad has shot. That
    // makes this the one place either state is applied or removed.
    void PassengerBoarded(Unit* passenger, int8 /*seatId*/, bool apply) override
    {
        Creature* gnome = passenger ? passenger->ToCreature() : nullptr;
        if (!gnome)
            return;

        if (apply)
        {
            RestrainGnome(gnome);
            return;
        }

        ReleaseGnome(gnome);

        // Vehicle::RemovePassenger puts UNIT_NPC_FLAG_SPELLCLICK back on as its very first
        // act and this hook is its last, so here is where it comes off again. Without it
        // the device wears the cog for everything after the gnome goes -- the pause over
        // the body, the flight home, and every second of the run for a device that let a
        // live one go.
        ClearVehicleSpellClick(me);

        // A gnome that leaves the seat alive falls on its own: Unit::_ExitVehicle reads
        // the ground under the device and launches the drop itself, and nothing disturbs
        // it. A gnome that leaves because it has been shot does not, and it takes two
        // things going wrong to get there.
        //
        // Unit::setDeathState calls ExitVehicle -- which is what runs this hook -- and
        // then, four lines later, GetMotionMaster()->Clear, MoveIdle, StopMoving and
        // DisableSpline. The exit's own fall is launched and wiped inside the one call,
        // so anything issued from here goes with it.
        //
        // Creature::setDeathState has a fall of its own for this, but it is guarded by
        // CanFly() || IsFlying() and the gnome passes neither by the time it is reached:
        // the seat's VEHICLE_SEAT_FLAG_DISABLE_GRAVITY is what made it airborne, and
        // Vehicle::RemovePassenger gives gravity back before this hook is even called.
        //
        // So the body is dropped from UpdateAI instead, one tick later, where the death
        // is finished and there is nothing left to undo it.
        if (!gnome->IsAlive())
            _falling = gnome->GetGUID();
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != POINT_MOTION_TYPE)
            return;

        // The approach and the roam are of no interest; the other two ends of a carrier's
        // run are the whole of its script.
        if (id == POINT_TAD_DROP)
            Condemn();
        else if (id == POINT_TAD_HOME)
            ReleaseAndDespawn();
    }

    void UpdateAI(uint32 diff) override
    {
        // MotionMaster::MoveFall finds the ground under the body and drops it straight
        // down, and it is a no-op when there is none to speak of -- a gnome shot while a
        // device happened to be hovering a foot off the floor simply stays where it fell.
        if (!_falling.IsEmpty())
        {
            if (Creature* gnome = ObjectAccessor::GetCreature(*me, _falling))
                gnome->GetMotionMaster()->MoveFall();

            _falling.Clear();
        }

        _scheduler.Update(diff);
    }


private:
    // The device is over its firing squad with the gnome still in its grip, which is
    // where the execution happens: the gnome is shot down out of the beam rather than
    // set on the floor first. Handing it over on arrival instead of on release is the
    // difference -- the squad used to be told at the end of the hold, so it was still
    // taking aim as the device was already leaving.
    void Condemn()
    {
        // One arrival per run. A second pass through here would restart the clock and
        // hand the squad a mark it is already shooting at.
        if (_executing)
            return;

        Creature* gnome = ObjectAccessor::GetCreature(*me, _claimed);
        if (!gnome || !gnome->IsAlive())
        {
            TC_LOG_ERROR("scripts.ai", "npc_target_acquisition_device: %s reached its drop with no gnome to hand over",
                me->GetGUID().ToString().c_str());
            ReleaseAndDespawn();
            return;
        }

        // Before the squad is told, so the first volley already has something it is
        // allowed to hit.
        CondemnGnome(gnome);
        AlertSquad(gnome);

        _executing = true;
        _executionLeft = TAD_EXECUTION_LIMIT;
        _scheduler.Schedule(TAD_EXECUTION_POLL, [this](TaskContext task) { WatchExecution(task); });
    }

    void WatchExecution(TaskContext task)
    {
        Creature* gnome = ObjectAccessor::GetCreature(*me, _claimed);
        if (!gnome || !gnome->IsAlive())
        {
            _scheduler.Schedule(TAD_LINGER_AFTER_KILL, [this](TaskContext /*task*/) { GoHome(); });
            return;
        }

        if (_executionLeft <= TAD_EXECUTION_POLL)
        {
            // One volley should have been enough, so a gnome still standing here means
            // the shot is not reaching it. Said once, by the one script that knows the
            // execution was ever meant to happen.
            TC_LOG_ERROR("scripts.ai", "npc_target_acquisition_device: %s held %s over its squad for %u ms and it is still up (%.0f%% hp)",
                me->GetGUID().ToString().c_str(), gnome->GetGUID().ToString().c_str(),
                uint32(TAD_EXECUTION_LIMIT.count()), gnome->GetHealthPct());

            GoHome();
            return;
        }

        _executionLeft -= TAD_EXECUTION_POLL;
        task.Repeat(TAD_EXECUTION_POLL);
    }

    // Runs every second until a gnome is both chosen and inside beam range.
    void Acquire(TaskContext task)
    {
        // Vehicle::Install runs after Reset -- Creature::AddToWorld calls it after
        // AIM_Initialize -- so the cog it puts on has to come off again once it has, and
        // this is the first thing to run afterwards.
        ClearVehicleSpellClick(me);

        Creature* gnome = ObjectAccessor::GetCreature(*me, _claimed);

        // Dead, gone, or picked up by something else while this device was walking over.
        if (gnome && (!gnome->IsAlive() || gnome->GetVehicle()))
            gnome = nullptr;

        if (!gnome)
        {
            _claimed.Clear();
            _approaching = false;

            gnome = FindGnome();
            if (!gnome)
            {
                // Said once. A device that has spent this long finding nothing is either
                // over an empty floor, which is ordinary, or is looking at gnomes it
                // cannot see, which means its post has no clear view of them and the
                // sight test is what is keeping it idle.
                if (++_emptyTries == TAD_EMPTY_TRIES_BEFORE_DOUBT && _blind)
                    TC_LOG_ERROR("scripts.ai", "npc_target_acquisition_device: %s has found nothing for %u tries; %u candidate(s) rejected on sight",
                        me->GetGUID().ToString().c_str(), _emptyTries, _blind);

                task.Repeat(TAD_RETRY_DELAY);
                return;
            }

            _emptyTries = 0;

            // Claimed from here on: FindGnome on any other device will now skip it.
            _claimed = gnome->GetGUID();
        }

        if (me->IsWithinDist(gnome, TAD_BEAM_RANGE))
        {
            // In range but no longer in sight -- it wandered behind something between
            // being chosen and being reached. Give the claim up rather than beam through
            // it; FindGnome will not offer it again until it comes back into the open.
            if (!InBeamSight(gnome))
            {
                _claimed.Clear();
                _approaching = false;
                task.Repeat(TAD_RETRY_DELAY);
                return;
            }

            me->GetMotionMaster()->MovementExpired();
            Grab(gnome);
            return;
        }

        if (!_approaching || gnome->GetDistance(_approachTo) > TAD_REPATH_TOLERANCE)
        {
            _approaching = true;
            _approachTo = gnome->GetPosition();
            me->GetMotionMaster()->MovePoint(POINT_TAD_TARGET, _approachTo, false);
        }

        task.Repeat(TAD_RETRY_DELAY);
    }

    void Grab(Creature* gnome)
    {
        me->SetFacingToObject(gnome);

        // Before the cast, not after it. Spell::DoAllEffectOnTarget ends in
        // CombatStart(unit, ...) for any target the caster is not friendly to, and
        // faction 35 is only neutral towards the gnome's 36, not friendly -- so the beam
        // landing is by itself enough to set the gnome on the device, and what the player
        // sees is a leper that was standing still turning and fighting.
        //
        // CombatStart skips AI()->AttackStart for a REACT_PASSIVE target and Unit::Attack
        // refuses a PACIFIED one, so restraining the gnome first is what stops the beam
        // starting a fight. It is also the right moment for it: a gnome in the beam
        // should stop what it was doing, not two seconds later when the seat takes it.
        RestrainGnome(gnome);

        // Cast plainly, not triggered. TRIGGERED_FULL_MASK takes the cast time with it,
        // and a two second channel that is skipped never establishes -- the client is
        // told the cast began and then immediately that it is over, so what it draws is
        // a blip at the device rather than a beam that reaches the gnome and holds
        // there. Letting the channel run is the difference between the two.
        //
        // The cost of casting plainly is that Spell::CheckCast is back in the way, and a
        // creature cast it refuses is refused in silence -- no message reaches any
        // client and none is logged. The device is faction 35 and the gnome 36, so that
        // is a real possibility rather than a theoretical one, and it is worth a line in
        // the log rather than a beam that is simply missing with nothing to explain it.
        if (!me->CastSpell(gnome, SPELL_TAD_TRACTOR_BEAM, false))
        {
            TC_LOG_ERROR("scripts.ai", "npc_target_acquisition_device: %s could not beam %s",
                me->GetGUID().ToString().c_str(), gnome->GetGUID().ToString().c_str());

            // The beam never went out, so nothing was caught. The seating that follows is
            // TRIGGERED_FULL_MASK and would have gone through anyway -- which is how a
            // refused beam still ended in an abduction, with the gnome pulled off the
            // floor by nothing visible at all. Let it go and start again instead.
            ReleaseGnome(gnome);
            _claimed.Clear();
            _approaching = false;
            _scheduler.Schedule(TAD_RETRY_DELAY, [this](TaskContext task) { Acquire(task); });
            return;
        }

        // A channel draws its beam between the caster and whatever is listed in
        // UNIT_DYNAMIC_FIELD_CHANNEL_OBJECTS. Spell::SendChannelStart fills that list from
        // m_UniqueTargetInfo (Spell.cpp:4683) -- from the spell's own effect targeting,
        // not from the unit the cast was aimed at. An effect whose implicit target does
        // not resolve to the gnome leaves the list empty, and a channel with no object has
        // no far end: the visual plays, and it plays entirely on the device.
        //
        // So the far end is named here rather than assumed. Writing the slot directly is
        // how this core already does it for the fishing bobber, SpellEffects.cpp:4944.
        ObjectGuid const gnomeGuid = gnome->GetGUID();
        bool connected = false;
        for (ObjectGuid const& channelled : me->GetChannelObjects())
            if (channelled == gnomeGuid)
                connected = true;

        if (!connected)
        {
            TC_LOG_ERROR("scripts.ai", "npc_target_acquisition_device: %s beamed %s but the channel named nothing; connecting it",
                me->GetGUID().ToString().c_str(), gnomeGuid.ToString().c_str());
            me->SetDynamicStructuredValue(UNIT_DYNAMIC_FIELD_CHANNEL_OBJECTS, 0, &gnomeGuid);
        }

        _scheduler.Schedule(TAD_BEAM_CHANNEL, [this](TaskContext /*task*/)
        {
            Creature* gnome = ObjectAccessor::GetCreature(*me, _claimed);
            if (!gnome || !gnome->IsAlive() || gnome->GetVehicle())
            {
                // Lost between choosing it and lifting it. Start again rather than
                // seat nothing and sit out the carry empty. A gnome that is still here
                // but has been taken by another device keeps that device's restraint, so
                // only one this device is walking away from is let go.
                if (gnome && !gnome->GetVehicle())
                    ReleaseGnome(gnome);

                _claimed.Clear();
                _approaching = false;
                _scheduler.Schedule(TAD_RETRY_DELAY, [this](TaskContext task) { Acquire(task); });
                return;
            }

            Board(gnome);

            if (_carry)
                me->GetMotionMaster()->MovePoint(POINT_TAD_DROP, _carry->DropX, _carry->DropY, _carry->DropZ, false);
            else
                Roam();

            _scheduler.Schedule(TAD_HOLD_TIME, [this](TaskContext /*task*/)
            {
                // The hold is the whole run for the ten devices that have nowhere to take
                // a gnome, and the backstop for a carrier whose approach never arrived. A
                // carrier that did arrive is on the execution clock instead, and running
                // out of hold in the middle of a volley would carry the gnome off alive.
                if (!_executing)
                    ReleaseAndDespawn();
            });
        });
    }

    // TRIGGERED_FULL_MASK, and cast by the gnome rather than through Unit::EnterVehicle.
    // EnterVehicle casts with only TRIGGERED_IGNORE_CASTER_MOUNTED_OR_ON_VEHICLE set,
    // which leaves the whole of Spell::CheckCast in the way; when it refuses it says
    // nothing, applies no SPELL_AURA_CONTROL_VEHICLE and so never queues the
    // VehicleJoinEvent, and the device hangs there with an empty seat.
    //
    // The tractor beam's periodic tick is supposed to force-cast this by itself. It is
    // driven here as well because a force-cast that fails is just as quiet, and the whole
    // run is built on the gnome actually being aboard.
    bool Board(Creature* gnome)
    {
        return gnome->CastCustomSpell(SPELL_RIDE_TAD, SPELLVALUE_BASE_POINT0,
            SEAT_ABDUCTED_GNOME + 1, me, TRIGGERED_FULL_MASK);
    }

    // Nothing to deliver to, so the device drifts around its post while it holds the
    // gnome rather than hanging perfectly still for half a minute.
    void Roam()
    {
        _scheduler.Schedule(TAD_ROAM_INTERVAL, [this](TaskContext task)
        {
            Position const home = me->GetHomePosition();
            float const angle = frand(0.0f, 2.0f * float(M_PI));
            float const dist = frand(3.0f, TAD_ROAM_RADIUS);
            me->GetMotionMaster()->MovePoint(POINT_TAD_ROAM,
                home.GetPositionX() + std::cos(angle) * dist,
                home.GetPositionY() + std::sin(angle) * dist,
                home.GetPositionZ(), false);
            task.Repeat(TAD_ROAM_INTERVAL);
        });
    }

    // The end of a carrier's run, whether the squad killed the gnome or the execution
    // timed out with it still standing. The device lets go here and then flies back to
    // its post under its own power: the despawn belongs at the spawn point, because that
    // is where the respawn five seconds later puts the next one, and a device that
    // vanished over the firing squad and reappeared at its post was the same jump played
    // twice.
    void GoHome()
    {
        if (_leaving)
            return;

        _leaving = true;

        // The seat is empty by now on the path that got here through a kill, and holds a
        // live gnome on the one that timed out. Either way it is emptied before the return
        // starts, so nothing is carried home.
        if (Vehicle* kit = me->GetVehicleKit())
            kit->RemoveAllPassengers();

        me->GetMotionMaster()->MovePoint(POINT_TAD_HOME, me->GetHomePosition(), false);

        _scheduler.Schedule(TAD_RETURN_BACKSTOP, [this](TaskContext /*task*/) { ReleaseAndDespawn(); });
    }

    void ReleaseAndDespawn()
    {
        // Explicitly, before the despawn. Vehicle::Uninstall would clear the seat anyway,
        // but going through RemoveAllPassengers is what runs the gnome's exit and leaves
        // it standing on the floor rather than wherever the seat had it -- and it is what
        // reaches PassengerBoarded, which is where a gnome that survived the run gets its
        // faction and its own will back.
        if (Vehicle* kit = me->GetVehicleKit())
            kit->RemoveAllPassengers();

        // The despawn cannot help dropping the device: DespawnOrUnsummon kills it first,
        // and Creature::setDeathState JUST_DIED sends a flying corpse to the floor with
        // MotionMaster::MoveFall. The guard on that is CanFly() || IsFlying(), and
        // Creature::CanFly reads InhabitType straight off the template (Creature.h:107) --
        // 46012 is InhabitType 4, so it is true for as long as the device flies at all.
        // No movement flag the script can set will turn it off.
        //
        // So the fall is left to happen and taken away from the clients instead. The
        // device is destroyed for everyone in range first, and the monster-move that
        // follows a moment later names a GUID they no longer hold and is discarded. What
        // is left to watch is the device blinking out at its post, which is what the
        // despawn was always meant to look like.
        //
        // Nothing has to put this back: Creature::Respawn opens with its own
        // DestroyForNearbyPlayers and closes with UpdateObjectVisibility, so the device
        // is built again from scratch on every client that can see it -- and by then
        // Reset has already run, so it is created with its gravity in the right state.
        //
        // After the passengers, not before. The gnome is drawn attached to the device
        // while it is seated, so a device taken off the clients with the seat still full
        // takes the gnome's own exit and fall with it.
        me->DestroyForNearbyPlayers();

        me->DespawnOrUnsummon(Milliseconds(0), TAD_RESPAWN_DELAY);
    }

    // SetGUID does nothing on an AI that has not asked for it, so the sparring Operatives
    // nearby are untouched by this.
    void AlertSquad(Creature* gnome)
    {
        std::list<Creature*> line;
        me->GetCreatureListWithEntryInGrid(line, NPC_SAFE_OPERATIVE_LINE, SQUAD_ALERT_RANGE);
        me->GetCreatureListWithEntryInGrid(line, NPC_SAFE_OFFICER_LINE, SQUAD_ALERT_RANGE);

        uint32 told = 0;
        for (Creature* shooter : line)
            if (shooter->IsAIEnabled && shooter->IsAlive())
            {
                shooter->AI()->SetGUID(gnome->GetGUID(), DATA_FIRING_SQUAD_TARGET);
                ++told;
            }

        if (!told)
            TC_LOG_ERROR("scripts.ai", "npc_target_acquisition_device: %s dropped %s with no squad within %.0f yd",
                me->GetGUID().ToString().c_str(), gnome->GetGUID().ToString().c_str(), SQUAD_ALERT_RANGE);
    }

    // The same test Spell::CheckCast will apply to the beam, down to the ignore flags, so
    // a gnome that passes here is one the cast will accept. M2 doodads are ignored on both
    // sides: a crate or a lamppost between the device and the floor is not cover.
    bool InBeamSight(Creature const* gnome) const
    {
        return gnome->IsWithinLOSInMap(me, VMAP::ModelIgnoreFlags::M2);
    }

    // Nearest gnome that is alive, out of a seat, in sight, and not already claimed.
    // _blind counts the ones that failed only on sight, so a device that has stopped
    // finding anything can say whether that is because the floor is empty or because it
    // cannot see any of it.
    Creature* FindGnome() const
    {
        _blind = 0;

        std::list<Creature*> gnomes;
        me->GetCreatureListWithEntryInGrid(gnomes, NPC_ABDUCTION_TARGET, TAD_SEARCH_RANGE);
        if (gnomes.empty())
            return nullptr;

        std::list<Creature*> devices;
        me->GetCreatureListWithEntryInGrid(devices, me->GetEntry(), TAD_PEER_RANGE);

        Creature* best = nullptr;
        float bestDist = 0.0f;

        for (Creature* gnome : gnomes)
        {
            // GetVehicle covers a gnome already carried, whoever is carrying it.
            if (!gnome->IsAlive() || gnome->GetVehicle())
                continue;

            if (IsClaimedElsewhere(devices, gnome->GetGUID()))
                continue;

            // Behind a wall, under a platform, on the far side of a train. The beam is a
            // real cast, so Spell::CheckCast refuses it for line of sight, and a device
            // that settles on one of these spends its whole run closing on something it
            // can never lift -- while the gnome it walked past goes untouched.
            if (!InBeamSight(gnome))
            {
                ++_blind;
                continue;
            }

            float const dist = me->GetDistance(gnome);
            if (!best || dist < bestDist)
            {
                best = gnome;
                bestDist = dist;
            }
        }

        return best;
    }

    bool IsClaimedElsewhere(std::list<Creature*> const& devices, ObjectGuid gnome) const
    {
        for (Creature* device : devices)
        {
            if (device == me || !device->IsAIEnabled)
                continue;

            if (device->AI()->GetGUID() == gnome)
                return true;
        }

        return false;
    }

    TaskScheduler _scheduler;
    ObjectGuid _claimed;
    ObjectGuid _falling;
    mutable uint32 _blind = 0;
    uint32 _emptyTries = 0;
    Position _approachTo;
    bool _approaching = false;
    bool _executing = false;
    bool _leaving = false;
    Milliseconds _executionLeft = TAD_EXECUTION_LIMIT;
    TadPost const* _carry = nullptr;
};

// The Operatives and the Officer standing in a line at each of the three drop points.
// They shoot the gnome a device holds up in front of them, and they shoot it out of the
// air: nothing about a vehicle seat protects the passenger, and 46363 has no
// creature_sparring_template row, so a volley that lands kills it. What they must not do
// is join the rest of the camp's brawling -- they hold their line, and the only gnome
// they ever touch is the one a device hands over.
//
// The target is not routed through the threat system. REACT_PASSIVE stops the Operative
// choosing anything for itself, but it also makes Creature::SelectVictim refuse to keep a
// victim, which walks the squad straight into an evade the moment it is given one. So the
// mark is held as a guid and shot at directly, and combat bookkeeping stays out of it.
struct npc_safe_operative_firing_squad : public ScriptedAI
{
    npc_safe_operative_firing_squad(Creature* creature) : ScriptedAI(creature)
    {
        // The line does not advance. Set before any AttackStart can be reached.
        SetCombatMovement(false);
    }

    void Reset() override
    {
        _scheduler.CancelAll();
        ReleaseMark();
        me->SetReactState(REACT_PASSIVE);
    }

    // The two routes into a fight this squad has no business being in.
    void AttackStart(Unit* /*who*/) override { }
    void MoveInLineOfSight(Unit* /*who*/) override { }

    void SetGUID(ObjectGuid guid, int32 id) override
    {
        if (id != DATA_FIRING_SQUAD_TARGET)
            return;

        _mark = guid;
        _warned = false;
        _shots = 0;
        _scheduler.CancelAll();

        // Staggered, so four rifles on the same line do not fire as one.
        _scheduler.Schedule(Milliseconds(urand(0, 1200)), [this](TaskContext task)
        {
            Creature* gnome = ObjectAccessor::GetCreature(*me, _mark);
            if (!gnome || !gnome->IsAlive())
            {
                ReleaseMark();
                return;
            }

            // A device that has to carry a live gnome off gives it its own faction back,
            // and that is this squad's signal to stand down. Without it the line would go
            // on firing at a gnome it is no longer allowed to hit, every few seconds,
            // until something else happened to it.
            if (!me->IsValidAttackTarget(gnome))
            {
                ReleaseMark();
                return;
            }

            if (me->IsWithinDistInMap(gnome, SQUAD_FIRE_RANGE))
            {
                me->SetFacingToObject(gnome);

                uint32 const shot = ShotSpell();

                // Cast plainly. The device hands the gnome over wearing a faction that
                // makes it a legal target, so there is nothing here for CheckCast to
                // refuse, and a refusal that does happen is worth hearing about rather
                // than papering over -- a triggered cast would report success while the
                // effect quietly reached nothing at all, which is exactly how this went
                // unnoticed the first time.
                if (me->CastSpell(gnome, shot, false))
                {
                    // Only the Operatives' substitute needs its look replayed by hand.
                    // The Officer casts its own spell, so its own visual plays with it.
                    if (shot == SPELL_SHOOT)
                    {
                        me->SendPlaySpellVisualKit(SPELL_VISUAL_KIT_SHOT_START, 0, 0);
                        me->SendPlaySpellVisualKit(SPELL_VISUAL_KIT_SHOT_FIRE, 0, 0);
                    }
                }
                else if (!_warned)
                {
                    _warned = true;
                    TC_LOG_ERROR("scripts.ai", "npc_safe_operative_firing_squad: %s refused %u at %s, dist %.1f, valid=%u hostile=%u",
                        me->GetGUID().ToString().c_str(), shot,
                        gnome->GetGUID().ToString().c_str(), me->GetExactDist(gnome),
                        uint32(me->IsValidAttackTarget(gnome)), uint32(me->IsHostileTo(gnome)));
                }

                // A cast that was accepted is still not proof the gnome is being hit --
                // the effect's own implicit target selection runs after it and can drop
                // the target on its own. If the gnome is still standing well past the
                // volleys that should have finished it, say so once rather than let the
                // squad mime at it forever.
                if (++_shots == SQUAD_SHOTS_BEFORE_DOUBT)
                    TC_LOG_ERROR("scripts.ai", "npc_safe_operative_firing_squad: %s has fired %u times at %s and it is still up (%.0f%% hp), valid=%u hostile=%u",
                        me->GetGUID().ToString().c_str(), uint32(_shots),
                        gnome->GetGUID().ToString().c_str(), gnome->GetHealthPct(),
                        uint32(me->IsValidAttackTarget(gnome)), uint32(me->IsHostileTo(gnome)));
            }

            task.Repeat(SQUAD_SHOT_MIN, SQUAD_SHOT_MAX);
        });
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    // The Officer and the Operatives on a line are not carrying the same weapon, so they
    // do not fire the same shot. Read off the entry rather than stored, because a line is
    // built from whichever spawns stand near the drop and either entry can be on it.
    uint32 ShotSpell() const
    {
        return me->GetEntry() == NPC_SAFE_OFFICER_LINE ? uint32(SPELL_OFFICER_SHOOT) : uint32(SPELL_SHOOT);
    }

    // The device owns the condemned state and undoes it when the gnome leaves the seat,
    // which covers the kill -- Unit::setDeathState unseats the body itself. This is the
    // backstop for the marks that never get that far: a gnome that left with its grid, a
    // reload, a device that despawned without unseating. A gnome left wearing faction 14
    // would come back hostile to the whole camp and to any player walking past.
    //
    // A gnome that is still in a seat is skipped, because that is an execution in
    // progress and the device has not finished with it; letting it go here would hand the
    // gnome back its faction in the middle of the volley.
    void ReleaseMark()
    {
        if (me->IsInWorld() && !_mark.IsEmpty())
        {
            if (Creature* gnome = ObjectAccessor::GetCreature(*me, _mark))
                if (!gnome->GetVehicle())
                    ReleaseGnome(gnome);

            // Every shot turns the Operative to face the gnome, and nothing turns it back
            // -- so a line that has executed once stands angled at the drop point for the
            // rest of the uptime instead of along its own front. The spawn orientation is
            // the line's facing, so it is put back with the mark.
            me->SetFacingTo(me->GetHomePosition().GetOrientation());
        }

        _mark.Clear();
        _warned = false;
        _shots = 0;
    }

    TaskScheduler _scheduler;
    ObjectGuid _mark;
    bool _warned = false;
    uint32 _shots = 0;
};

// The S.A.F.E. Officer posted in the Loading Room's north-west corner. He never
// moves and never speaks -- the whole of him is a gesture every few seconds at the
// two Operatives seated in front of him, which is what makes that corner read as a
// briefing rather than three NPCs who happen to be standing near each other. His
// spawn orientation already points him between the pair, so nothing here turns him.
//
// This hangs off the spawn rather than off 46025, because the Officer who walks the
// room's patrol does not do it: he gestures perhaps twice in the time this one gets
// through fifty, so the two are not the same behaviour and giving the entry a timer
// would put this one's cadence on a walker that does not want it.
static constexpr Milliseconds BRIEFING_EMOTE_MIN = Milliseconds(3600);
static constexpr Milliseconds BRIEFING_EMOTE_MAX = Milliseconds(6100);

// Weighted by repetition rather than by a roll with branches: the talking gesture
// takes half the list and the other three split the rest, so the corner reads as one
// man doing most of the talking and occasionally answering himself.
static constexpr uint32 BRIEFING_EMOTE_COUNT = 6;
static constexpr uint32 BRIEFING_EMOTES[BRIEFING_EMOTE_COUNT] =
{
    EMOTE_ONESHOT_TALK_NO_SHEATHE,
    EMOTE_ONESHOT_TALK_NO_SHEATHE,
    EMOTE_ONESHOT_TALK_NO_SHEATHE,
    EMOTE_ONESHOT_YES,
    EMOTE_ONESHOT_NO,
    EMOTE_ONESHOT_QUESTION
};

struct npc_safe_officer_briefing : public ScriptedAI
{
    npc_safe_officer_briefing(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();

        // The first gesture waits out a full interval too. Starting on zero would put
        // every restart's first emote on the same tick as everything else that reset
        // with it, and the officer is meant to be mid-conversation, not starting one.
        _scheduler.Schedule(BRIEFING_EMOTE_MIN, BRIEFING_EMOTE_MAX, [this](TaskContext task)
        {
            // A gesture belongs to the briefing, not to a fight he has been pulled
            // into. The timer keeps running so he picks the conversation back up
            // once he is out of combat rather than falling silent for good.
            if (!me->IsInCombat())
                me->HandleEmoteCommand(BRIEFING_EMOTES[urand(0, BRIEFING_EMOTE_COUNT - 1)]);

            task.Repeat(BRIEFING_EMOTE_MIN, BRIEFING_EMOTE_MAX);
        });
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    TaskScheduler _scheduler;
};

// The Clean Cannon X-2 crews itself.
//
// Each of the four cannons has a S.A.F.E. Operative entered at its own guid + 1,
// standing about half a yard away at ground level and carrying the cannon's own
// orientation to six decimals. In the dump not one of those four is standing: all four
// ride their cannon in seat 0 at TransportPosition (-1.0872, 0, 0.98481) -- the 0.98
// yard lift that stands the gunner up on the barrel -- and there is no fifth 45847
// anywhere near a cannon. The room holds seven of the entry in total: these four,
// seated, and the three posted Operatives over in the north-west corner. So the ground
// spawns are stand-ins for a gunner that belongs in the seat, the same shape the
// teleporter scene found under 46267 and 42552.
//
// They are seated rather than deleted and replaced with vehicle_template_accessory,
// which is the mechanism the shape of this first suggests. Three things rule it out:
//
//   - Vehicle::InstallAccessory summons a *new* creature of the accessory entry. The
//     four authored spawns would go on standing beside their own doubles, so that route
//     costs four deletes before it does anything.
//   - It seats through Unit::HandleSpellClick, which walks npc_spellclick_spells for the
//     vehicle's entry. 46208 has no row there, so the install would silently do nothing
//     until one was added -- and adding one hands players a click path into a cannon
//     that nothing in the dump suggests retail offers.
//   - A summon has no spawn id, so creature_addon cannot reach it and it would wear
//     45847's template emote 214 READY_RIFLE and SheathState 2. The seated gunners
//     report EmoteState 0 and SheatheState 1, which per-guid addon rows give the real
//     spawns.
//
// The facing needs no help here, unlike the carry scene above. VehicleJoinEvent::Execute
// hardcodes SetFacing(0), and this seat's own TransportPosition orientation is 0 as well,
// so the gunner ends up looking along its cannon exactly as the dump has it.
//
// Seating also takes the cog cursor off the cannon without touching a flag: the join
// event decrements Vehicle::UsableSeatNum and clears UNIT_NPC_FLAG_SPELLCLICK when the
// count reaches zero, and 1173 has only the one seat.
enum CleanCannonX2
{
    NPC_SAFE_OPERATIVE_GUNNER = 45847,

    // Vehicle 1173's only seat, read off the dump as VehicleSeatIndex 0. VehicleSeat.db2
    // cannot settle it from here -- the collapsed SeatID array leaves the reader off by
    // one, so seat 8674 could be read as either index.
    SEAT_CANNON_GUNNER        = 0
};

// A gunner stands 0.50-0.57 yards from its own cannon, the cannons are 9.5 yards apart at
// the closest, and the nearest 45847 that is not a gunner is 22 yards away in the corner.
// So this radius cannot pick up a neighbour's gunner or one of the posted Operatives.
static constexpr float CANNON_GUNNER_RANGE = 3.0f;

// Cannon and gunner are both static spawns on the same grid and nothing orders the two,
// so the first attempt may find no gunner at all. The retry covers that rather than an
// assumption about which of them the map creates first.
static constexpr Milliseconds CANNON_CREW_FIRST = Milliseconds(1000);
static constexpr Milliseconds CANNON_CREW_RETRY = Milliseconds(3000);

struct npc_clean_cannon_x2 : public ScriptedAI
{
    npc_clean_cannon_x2(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();

        _scheduler.Schedule(CANNON_CREW_FIRST, [this](TaskContext task)
        {
            if (IsCrewed())
                return;

            SeatGunner();

            // Boarding is asynchronous: Vehicle::AddPassenger queues a VehicleJoinEvent,
            // so the seat is still empty when the cast returns and there is nothing to
            // read at the call site. The next pass is what confirms it, which is why this
            // repeats until IsCrewed() rather than trusting the cast.
            task.Repeat(CANNON_CREW_RETRY);
        });
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    bool IsCrewed() const
    {
        Vehicle* kit = me->GetVehicleKit();
        return kit && kit->GetPassenger(SEAT_CANNON_GUNNER);
    }

    void SeatGunner()
    {
        if (!me->GetVehicleKit())
            return;

        Creature* gunner = me->FindNearestCreature(NPC_SAFE_OPERATIVE_GUNNER, CANNON_GUNNER_RANGE);
        if (!gunner || gunner->GetVehicle())
            return;

        // TRIGGERED_FULL_MASK rather than Unit::EnterVehicle, for the reason written out
        // on npc_safe_operative_bearer::BoardGnome above: EnterVehicle leaves the whole of
        // Spell::CheckCast in the way of a cast that has no business failing, and when it
        // does refuse it says nothing and queues no join event.
        gunner->CastCustomSpell(VEHICLE_SPELL_RIDE_HARDCODED, SPELLVALUE_BASE_POINT0,
            SEAT_CANNON_GUNNER + 1, me, TRIGGERED_FULL_MASK);
    }

    TaskScheduler _scheduler;
};

enum SafeGuide
{
    NPC_SAFE_GUIDE_MAGE                 = 47351,
    QUEST_THE_FUTURE_OF_GNOMEREGAN_MAGE = 26197,

    SAY_GUIDE_FOLLOW                    = 0,
    SAY_GUIDE_INTRODUCE                 = 1
};

// 47351 has no spawn anywhere. It is created when the quest is accepted, walks the
// player to their class trainer and unsummons on arrival, so the route below lives in
// the script rather than in `waypoints`: there is no guid for a path_id to hang off.
//
// The guide appears here, a few yards east of Nevin Twistwrench. The hunter has its
// own guide entry walking to its own trainer and it starts from this same spot, so
// the position belongs to the summon rather than to either class.
static Position const SafeGuideSummonPos = { -5196.80f, 475.03f, 388.55f, 0.0f };

// The walk to Bipsi Frostflinger: nine legs, 129 yards, about 52 seconds.
//
// Nothing here sets a speed. 47351 carries speed_walk 1, which is the 2.5 yd/s these
// legs are timed at, and SetSpeed would not help in any case -- it takes an absolute
// yd/s on this core, so SetSpeed(MOVE_WALK, 1.0f) would crawl at 1 yard a second
// rather than leave the walk alone.
static Position const SafeGuideMagePath[] =
{
    { -5177.57f, 476.61f, 388.38f, 0.0f },
    { -5164.87f, 478.95f, 389.93f, 0.0f },
    { -5155.42f, 470.17f, 390.68f, 0.0f },
    { -5146.19f, 459.63f, 392.42f, 0.0f },
    { -5130.46f, 450.37f, 394.94f, 0.0f },
    { -5116.67f, 453.45f, 398.91f, 0.0f },
    { -5105.66f, 458.72f, 402.41f, 0.0f },
    { -5093.27f, 457.52f, 405.38f, 0.0f },
    { -5087.58f, 448.46f, 409.12f, 0.0f }
};

// The last point stops 2.8 yards short of Bipsi's spawn, which leaves the guide
// looking down the path it just walked. This turns it to face her for the
// introduction.
static constexpr float SAFE_GUIDE_MAGE_FACING = 5.533f;

// The pauses either side of the walk. The guide stands still for a moment after it
// appears, speaks, and only then sets off.
static constexpr Milliseconds SUMMON_TO_FOLLOW_LINE = Milliseconds(3000);
static constexpr Milliseconds SUMMON_TO_FIRST_STEP  = Milliseconds(6900);
static constexpr Milliseconds ARRIVE_TO_UNSUMMON    = Milliseconds(1300);

// Safety net, well clear of the 52-second walk. It only matters if a leg never
// reports back, which would otherwise leave the guide standing in the camp for good.
static constexpr uint32 SAFE_GUIDE_LIFETIME = 3 * MINUTE * IN_MILLISECONDS;

// The guide that walks a new mage from Nevin Twistwrench to Bipsi Frostflinger after
// The Future of Gnomeregan is accepted.
struct npc_safe_guide : public ScriptedAI
{
    npc_safe_guide(Creature* creature) : ScriptedAI(creature), _leg(0) { }

    void IsSummonedBy(Unit* summoner) override
    {
        Player* player = summoner ? summoner->ToPlayer() : nullptr;
        if (!player)
        {
            // Nothing else summons this entry. Without the player there is nobody to
            // address or to face, and walking the route anyway would read as a stray
            // NPC wandering out of the camp on its own.
            TC_LOG_ERROR("scripts.ai", "npc_safe_guide: summoned without a player summoner, despawning");
            me->DespawnOrUnsummon();
            return;
        }

        _playerGuid = player->GetGUID();
        me->SetWalk(true);
        me->SetFacingToObject(player);

        _scheduler.Schedule(SUMMON_TO_FOLLOW_LINE, [this](TaskContext /*task*/)
        {
            Talk(SAY_GUIDE_FOLLOW, ObjectAccessor::GetPlayer(*me, _playerGuid));
        });

        _scheduler.Schedule(SUMMON_TO_FIRST_STEP, [this](TaskContext /*task*/)
        {
            WalkTo(0);
        });
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != POINT_MOTION_TYPE || id != _leg)
            return;

        if (++_leg < uint32(std::extent<decltype(SafeGuideMagePath)>::value))
        {
            WalkTo(_leg);
            return;
        }

        me->SetFacingTo(SAFE_GUIDE_MAGE_FACING);
        Talk(SAY_GUIDE_INTRODUCE, ObjectAccessor::GetPlayer(*me, _playerGuid));
        me->DespawnOrUnsummon(ARRIVE_TO_UNSUMMON);
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

    // The guide walks through a camp that is permanently trading fire with the
    // sludges to its west. It takes no part in that.
    void AttackStart(Unit* /*who*/) override { }
    void EnterCombat(Unit* /*who*/) override { }

private:
    void WalkTo(uint32 leg)
    {
        me->GetMotionMaster()->MovePoint(leg, SafeGuideMagePath[leg]);
    }

    TaskScheduler _scheduler;
    ObjectGuid _playerGuid;
    uint32 _leg;
};

// The quest is accepted at Nevin Twistwrench, but the hook hangs off the player
// rather than off him: the player is the summoner, and Nevin himself does nothing
// here, so this leaves his creature_template.ScriptName free for later work.
class player_safe_guide_summoner : public PlayerScript
{
public:
    player_safe_guide_summoner() : PlayerScript("player_safe_guide_summoner") { }

    void OnQuestAccept(Player* player, Quest const* quest) override
    {
        if (!quest || quest->GetQuestId() != QUEST_THE_FUTURE_OF_GNOMEREGAN_MAGE)
            return;

        // Deliberately visible to everyone. Making it visible to the summoner alone
        // works -- the flag has to be set through a Creature* afterwards, because
        // TempSummon shadows it and the argument to SummonCreature is inert -- but
        // nothing observed says the guide is private, and an invisible guide is a
        // much worse failure than an extra one walking past.
        player->SummonCreature(NPC_SAFE_GUIDE_MAGE, SafeGuideSummonPos,
            TEMPSUMMON_TIMED_DESPAWN, SAFE_GUIDE_LIFETIME);
    }
};

enum GnomereganRecruitColumn
{
    NPC_AMMO_CART           = 43273,
    NPC_AMMO_CART_BUNNY     = 43279,

    // 43276 carries creature_template.VehicleId 947, whose single seat is VehicleSeat
    // 8172, and 43273 carries VehicleId 946, whose single seat is VehicleSeat 8171. Seat
    // 0 is that seat in both cases, and the load is a stack of two: the cart rides the
    // recruit and the bunny rides the cart. Both are seated rather than followed, which
    // is why 43276 and 43273 are Vehicle guids and only the bunny on top is a Creature
    // one.
    SEAT_AMMO_CART          = 0,
    SEAT_CART_BUNNY         = 0,

    // What puts the recruit's arms out in front of it, on the handles of the cart it is
    // pushing. Held for the whole run: the recruit wears it from the moment it takes its
    // load to the moment it despawns, and nothing clears it in between. The cart and the
    // bunny carry no kit of their own.
    ANIM_KIT_PUSH_CART      = 645,

    POINT_COLUMN_END        = 1
};

// A run is one column's walk from its post to the end of its route, where it is gone.
// The next leaves a few seconds later. The four routes are 188, 191, 257 and 590 yards,
// so at walk speed the columns come round every 81, 83, 109 and 242 seconds.
static constexpr Milliseconds COLUMN_BOARD_TO_WALK = Milliseconds(1000);

// How long a post stands empty between one column reaching the end of its route and the
// next setting off. Six seconds is what the cadence works out to, and the spread either side
// of it is rolled per run: on a fixed gap the columns keep whatever order they started in
// for as long as the server is up, and a player standing at the fork sees the same recruits
// pass in the same sequence every time. Rolling it lets them drift apart. Widen the pair to
// make the wobble more obvious -- nothing else depends on these two numbers.
static constexpr uint32 COLUMN_RESPAWN_MIN_SECONDS = 3;
static constexpr uint32 COLUMN_RESPAWN_MAX_SECONDS = 9;

// A follower that reaches the end of its route is ended by the leader, which arrives
// within a second of it. If the word never comes -- the leader died on the road, or was
// despawned under it -- the follower waits this long and goes on its own.
static constexpr Milliseconds COLUMN_FOLLOWER_END_GRACE = Milliseconds(5000);

// The four routes out of town. Element 0 of each is that route's own start, because
// MoveSplineInit::Launch overwrites element 0 with the creature's real position -- the
// value there is never used as a destination, it only records where the path begins, and
// it is also what ColumnFor matches a recruit against.
//
// Two columns take the road south and split near the bottom of it; the third takes the
// road southwest, out of the zone; the fourth starts at Brewnall and takes the main road
// the whole length of the town, to where it leaves the zone in the south. None of them
// comes back.
Position const RecruitColumnSouthA[] =
{
    { -5128.630f, 441.328f, 396.082f },
    { -5124.340f, 416.957f, 396.615f },
    { -5128.760f, 401.816f, 396.609f },
    { -5127.800f, 377.835f, 396.609f },
    { -5127.210f, 349.245f, 395.728f },
    { -5120.200f, 322.993f, 394.139f },
    { -5102.690f, 308.052f, 394.139f },
    { -5091.250f, 295.217f, 394.224f },
    { -5079.630f, 296.405f, 395.319f },
    { -5064.680f, 291.533f, 393.850f }
};

Position const RecruitColumnSouthB[] =
{
    { -5140.950f, 454.278f, 393.619f },
    { -5122.810f, 416.710f, 396.640f },
    { -5126.820f, 401.288f, 396.609f },
    { -5125.980f, 377.427f, 396.609f },
    { -5124.610f, 348.917f, 395.822f },
    { -5117.300f, 323.821f, 394.141f },
    { -5099.250f, 310.688f, 394.140f },
    { -5088.410f, 299.245f, 394.264f },
    { -5079.270f, 284.849f, 395.066f }
};

Position const RecruitColumnSouthwest[] =
{
    { -5184.940f, 467.078f, 388.518f },
    { -5197.280f, 447.616f, 388.895f },
    { -5219.020f, 426.450f, 390.290f },
    { -5233.010f, 416.986f, 391.018f },
    { -5249.200f, 407.344f, 391.821f },
    { -5264.790f, 397.693f, 392.374f },
    { -5285.840f, 387.894f, 392.603f },
    { -5311.000f, 381.054f, 393.019f },
    { -5339.550f, 373.922f, 393.717f },
    { -5351.480f, 362.726f, 394.688f },
    { -5362.610f, 342.663f, 394.811f },
    { -5364.850f, 310.828f, 394.135f }
};

Position const RecruitColumnMainRoad[] =
{
    { -5410.630f, 299.778f, 394.707f },
    { -5415.990f, 278.858f, 394.742f },
    { -5418.090f, 252.740f, 394.702f },
    { -5433.620f, 231.488f, 395.027f },
    { -5437.520f, 205.658f, 394.350f },
    { -5436.800f, 170.816f, 394.300f },
    { -5432.430f, 148.936f, 394.128f },
    { -5420.340f, 131.248f, 393.420f },
    { -5416.510f, 111.759f, 393.355f },
    { -5410.320f,  86.068f, 393.400f },
    { -5405.260f,  65.701f, 393.398f },
    { -5396.660f,  54.063f, 392.535f },
    { -5387.120f,  38.346f, 391.260f },
    { -5383.360f,  21.264f, 391.270f },
    { -5381.950f,   1.465f, 391.030f },
    { -5383.140f, -23.686f, 391.057f },
    { -5383.250f, -52.927f, 391.202f },
    { -5388.390f, -75.290f, 391.574f },
    { -5401.610f, -91.264f, 393.263f },
    { -5411.300f, -110.835f, 394.432f },
    { -5415.790f, -127.125f, 395.712f },
    { -5417.690f, -155.972f, 397.688f },
    { -5417.770f, -179.623f, 399.359f },
    { -5420.230f, -211.684f, 401.337f },
    { -5421.990f, -239.512f, 401.123f },
    { -5422.820f, -259.606f, 401.284f },
    { -5421.050f, -288.405f, 400.560f }
};

// A follower walks the leader's nodes from a post of its own to an end of its own. The
// main-road column is three recruits in single file: the two behind start three and a half
// and seven yards back from the leader's post and stop four and eight yards short of its
// end, so the file they set off in is the file they arrive in.
struct RecruitColumnFollower
{
    Position start;
    Position end;
};

static RecruitColumnFollower const RecruitColumnMainRoadFollowers[] =
{
    { { -5408.950f, 302.847f, 394.707f, 4.3982f }, { -5421.301f, -284.413f, 400.644f } },
    { { -5407.260f, 305.764f, 394.707f, 4.3982f }, { -5421.551f, -280.421f, 400.689f } }
};

struct RecruitColumn
{
    Position const* nodes;
    size_t          size;
    RecruitColumnFollower const* followers;
    size_t          followerCount;
};

static RecruitColumn const RecruitColumns[] =
{
    { RecruitColumnSouthA,    std::extent<decltype(RecruitColumnSouthA)>::value,    nullptr, 0 },
    { RecruitColumnSouthB,    std::extent<decltype(RecruitColumnSouthB)>::value,    nullptr, 0 },
    { RecruitColumnSouthwest, std::extent<decltype(RecruitColumnSouthwest)>::value, nullptr, 0 },
    { RecruitColumnMainRoad,  std::extent<decltype(RecruitColumnMainRoad)>::value,
      RecruitColumnMainRoadFollowers, std::extent<decltype(RecruitColumnMainRoadFollowers)>::value }
};

// A recruit's place in a column: which route, and whether it leads it (slot 0) or walks
// behind the leader (slot 1 and up, indexing followers from 1).
struct RecruitColumnSlot
{
    RecruitColumn const* column = nullptr;
    size_t slot = 0;
};

// Which route a recruit walks, and where in the file, comes from where it stands rather
// than from its guid, so moving a spawn in the database moves it onto the matching post
// and adding a post is a database change with no script change behind it. The nearest
// post wins, and has to be within five yards: wide enough to survive a spawn nudged off
// its mark, and the nearest-wins rule is what keeps the three main-road posts apart,
// which are three and a half yards from one another.
static RecruitColumnSlot ColumnFor(Position const& home)
{
    RecruitColumnSlot best;
    float bestDist = 5.0f;

    for (RecruitColumn const& column : RecruitColumns)
    {
        float dist = home.GetExactDist2d(&column.nodes[0]);
        if (dist < bestDist)
        {
            bestDist = dist;
            best = { &column, 0 };
        }

        for (size_t i = 0; i < column.followerCount; ++i)
        {
            dist = home.GetExactDist2d(&column.followers[i].start);
            if (dist < bestDist)
            {
                bestDist = dist;
                best = { &column, i + 1 };
            }
        }
    }

    return best;
}

// Map::SummonCreature applies visibleBySummonerOnly before AddToMap, and
// WorldObject::CanSeeOrDetect only exempts the summoner, so a creature's summon flagged
// this way is drawn by nobody at all. These two are the on and off. They go through a
// Creature* deliberately: TempSummon redeclares m_visibleBySummonerOnly and its accessors,
// shadowing WorldObject's, so the argument to SummonCreature writes a copy that
// CanSeeOrDetect never reads.
static void ConcealSummon(Creature* summon)
{
    summon->SetVisibleBySummonerOnly(true);
    summon->UpdateObjectVisibility();
}

static void RevealSummon(Creature* summon)
{
    summon->SetVisibleBySummonerOnly(false);
    summon->UpdateObjectVisibility();
}

// A Gnomeregan Recruit hauling an ammo cart out of New Tinkertown. It takes on its load at
// its post, walks one of the four routes above, and despawns where the route ends; the
// respawn brings the next one and the run starts over.
//
// The main-road column is three of them in single file. Only the leader is a spawn: it
// summons the two behind it at their posts, starts all three off together, and ends the
// run for all three when it reaches the bottom of the road. The followers run this same AI
// from creature_template.ScriptName, resolve their place from where they were put, and
// wait for the leader's word before they move.
//
// Not SmartAI, and not a waypoint path either. SMART_ACTION has no way to seat a creature
// in a vehicle seat, and a creature_addon path would loop -- WaypointMovementGenerator
// advances (i_currentNode + 1) % size and has no end -- so the recruit would turn round at
// the bottom of the road and walk its load back into town. Nor creature_formations for the
// file: CreatureGroup::LeaderMoveTo is only reached from the point, waypoint and random
// generators, and MoveSmoothPath goes through none of them.
struct npc_gnomeregan_recruit_column : public ScriptedAI
{
    npc_gnomeregan_recruit_column(Creature* creature) : ScriptedAI(creature),
        _place(ColumnFor(creature->GetHomePosition())) { }

    // The road passes the Crushcog line, and a recruit that stops to fight never finishes
    // its run: a victim means ChaseMovementGenerator, which takes MOTION_SLOT_ACTIVE off
    // the walk, so the arrival that ends the run never comes and the recruit is left
    // standing wherever the fight stopped it, still loaded. REACT_PASSIVE alone does not
    // cover it -- AttackStart is reachable without it, from another AI, an assist or a
    // forced target -- so the override makes the AI structurally unable to take one.
    void AttackStart(Unit* /*who*/) override { }

    // REACT_PASSIVE already makes CreatureAI::MoveInLineOfSight return without aggroing,
    // so this changes no behaviour. It only stops the scan running against every unit on a
    // route that crosses the whole zone.
    void MoveInLineOfSight(Unit* /*who*/) override { }

    void Reset() override
    {
        _scheduler.CancelAll();

        me->SetReactState(REACT_PASSIVE);

        // A vehicle with a free seat advertises itself as clickable: Vehicle::Install sets
        // UNIT_NPC_FLAG_SPELLCLICK when any seat is usable and only VehicleJoinEvent takes
        // it off again. Neither 43276 nor 43273 has an npc_spellclick_spells row, so the
        // cog cursor the client draws in the meantime offers an interaction that does not
        // exist.
        ClearVehicleSpellClick(me);

        // Reset runs on respawn, and on anything that cuts a run short -- a grid unload, a
        // .reload. Without this the load from the abandoned run is left behind, and so are
        // the followers a leader had out on the road.
        DespawnLoad();
        DespawnFollowers();

        if (!_place.column)
        {
            TC_LOG_ERROR("scripts.ai", "npc_gnomeregan_recruit_column: %s is not within five yards of any column post and will not move",
                me->GetGUID().ToString().c_str());
            return;
        }

        // Set here rather than in creature_template_addon, which carries aiAnimKit 0 for
        // 43276 and would put every static spawn of the entry into the pose as well. Reset
        // is safe to set it from: Creature::setDeathState(JUST_RESPAWNED) runs
        // LoadCreaturesAddon before AI()->Reset(), so the addon's 0 is written first and
        // this overwrites it on every respawn.
        me->SetAIAnimKitId(ANIM_KIT_PUSH_CART);

        // Hidden while it is assembled, then handed over finished. Both seats are filled by
        // a VehicleJoinEvent a tick after the cast and the client plays the seat's enter
        // animation over the top, so a visible cart is seen standing on the ground and
        // climbing onto the recruit's back.
        if (TempSummon* cart = me->SummonCreature(NPC_AMMO_CART, me->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN))
        {
            ConcealSummon(cart);
            _cart = cart->GetGUID();
            BoardVehicle(cart, me, SEAT_AMMO_CART);

            // Vehicle::Install runs inside Creature::AddToWorld, so the cart has a kit of
            // its own by the time SummonCreature returns and can take the bunny straight
            // away. The bunny is summoned by the recruit rather than by the cart so that
            // one owner despawns the whole load.
            if (TempSummon* bunny = me->SummonCreature(NPC_AMMO_CART_BUNNY, me->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN))
            {
                ConcealSummon(bunny);
                _bunny = bunny->GetGUID();
                BoardVehicle(bunny, cart, SEAT_CART_BUNNY);
            }
        }

        // The followers are put at their posts now, so their own Reset loads them in the
        // same tick as the leader and the three are ready together. Their home position is
        // where they were summoned, which is what ColumnFor reads, so they know their place
        // without being told.
        if (IsLeader())
            for (size_t i = 0; i < _place.column->followerCount; ++i)
                if (TempSummon* follower = me->SummonCreature(me->GetEntry(), _place.column->followers[i].start, TEMPSUMMON_MANUAL_DESPAWN))
                    _followers.push_back(follower->GetGUID());

        _scheduler.Schedule(COLUMN_BOARD_TO_WALK, [this](TaskContext /*task*/)
        {
            // Vehicle::AddPassenger schedules the join through a VehicleJoinEvent rather
            // than seating anyone inline, so both seats are still empty when the casts
            // return and there is nothing to check at the call site. By now they have run,
            // and this is the first honest answer about whether the load is aboard.
            Creature* cart = ObjectAccessor::GetCreature(*me, _cart);
            Creature* bunny = ObjectAccessor::GetCreature(*me, _bunny);

            // One retry each. A recruit walking the route with an empty back is the failure
            // this scene shows when a boarding does not take, and it is silent otherwise.
            // The walk goes ahead either way: a cart that boards a tick late snaps into
            // place, which is better than a run that never starts.
            if (cart && !cart->GetVehicle())
            {
                TC_LOG_ERROR("scripts.ai", "npc_gnomeregan_recruit_column: cart %s did not board %s, retrying",
                    cart->GetGUID().ToString().c_str(), me->GetGUID().ToString().c_str());
                BoardVehicle(cart, me, SEAT_AMMO_CART);
            }

            if (cart && bunny && !bunny->GetVehicle())
            {
                TC_LOG_ERROR("scripts.ai", "npc_gnomeregan_recruit_column: bunny %s did not board cart %s, retrying",
                    bunny->GetGUID().ToString().c_str(), cart->GetGUID().ToString().c_str());
                BoardVehicle(bunny, cart, SEAT_CART_BUNNY);
            }

            // Vehicle::Install runs after Reset, and a boarding that failed leaves a seat
            // open, so this is the one place that catches both the recruit and the cart.
            ClearVehicleSpellClick(me);

            if (cart)
            {
                ClearVehicleSpellClick(cart);
                RevealSummon(cart);
            }

            if (bunny)
                RevealSummon(bunny);

            // A follower is loaded and waits. The leader sets off and takes the file with
            // it, in this one tick, so nobody is a step ahead of anyone.
            if (!IsLeader())
                return;

            StartRun();

            for (ObjectGuid const& guid : _followers)
                if (npc_gnomeregan_recruit_column* follower = FollowerAI(guid))
                    follower->StartRun();
        });
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        // MoveSmoothPath finishes through EffectMovementGenerator, so what comes back is
        // EFFECT_MOTION_TYPE and not the POINT_MOTION_TYPE a MovePoint would give.
        if (type != EFFECT_MOTION_TYPE || id != POINT_COLUMN_END)
            return;

        if (!IsLeader())
        {
            _scheduler.Schedule(COLUMN_FOLLOWER_END_GRACE, [this](TaskContext /*task*/)
            {
                EndRun();
            });
            return;
        }

        // The followers go first: they are the leader's summons, and the leader's own
        // despawn is what the next run hangs off.
        for (ObjectGuid const& guid : _followers)
            if (npc_gnomeregan_recruit_column* follower = FollowerAI(guid))
                follower->EndRun();
        _followers.clear();

        // The load goes next and in this order. Despawning the recruit takes its vehicle
        // kit down with it, and Vehicle::Uninstall throws each passenger clear along its
        // seat's exit arc on the way.
        DespawnLoad();

        // Each run is made by a fresh recruit rather than by one looping in place, so the
        // spawn despawns and comes back. The respawn re-enters Reset and the next run sets
        // off.
        me->DespawnOrUnsummon(0, Seconds(urand(COLUMN_RESPAWN_MIN_SECONDS, COLUMN_RESPAWN_MAX_SECONDS)));
    }

    void UpdateAI(uint32 diff) override
    {
        // No UpdateVictim, and nothing that could acquire one. The scheduler is the whole
        // AI.
        _scheduler.Update(diff);
    }

    // The walk. A follower's path is the leader's with the end swapped for its own, so the
    // two behind pull up four and eight yards short rather than onto the leader's heels.
    // Element 0 is overwritten by Launch either way.
    //
    // walk true is the whole reason this is MoveSmoothPath and not a chain of MovePoint
    // calls: PointMovementGenerator::DoInitialize never touches MoveSplineInit::SetWalk,
    // so a MovePoint always runs, and me->SetWalk does not change that.
    void StartRun()
    {
        if (!_place.column)
            return;

        if (IsLeader())
        {
            me->GetMotionMaster()->MoveSmoothPath(POINT_COLUMN_END, _place.column->nodes, _place.column->size, true);
            return;
        }

        std::vector<Position> path(_place.column->nodes, _place.column->nodes + _place.column->size);
        path.back() = _place.column->followers[_place.slot - 1].end;
        me->GetMotionMaster()->MoveSmoothPath(POINT_COLUMN_END, path.data(), path.size(), true);
    }

    // A follower's run is over: load off, then gone. Followers are summons, so there is
    // no respawn to time -- the next leader brings its own.
    void EndRun()
    {
        _scheduler.CancelAll();
        DespawnLoad();
        me->DespawnOrUnsummon();
    }

private:
    bool IsLeader() const { return _place.slot == 0; }

    npc_gnomeregan_recruit_column* FollowerAI(ObjectGuid const& guid) const
    {
        Creature* follower = ObjectAccessor::GetCreature(*me, guid);
        if (!follower)
            return nullptr;

        // The summon takes this AI from creature_template.ScriptName. Anything else here
        // means the template row lost it, which is worth a line in the log rather than an
        // assert that takes the server down over a recruit.
        npc_gnomeregan_recruit_column* ai = dynamic_cast<npc_gnomeregan_recruit_column*>(follower->AI());
        if (!ai)
            TC_LOG_ERROR("scripts.ai", "npc_gnomeregan_recruit_column: follower %s is not running this AI; creature_template.ScriptName for %u is missing",
                follower->GetGUID().ToString().c_str(), follower->GetEntry());
        return ai;
    }

    // TRIGGERED_FULL_MASK, rather than Unit::EnterVehicle. EnterVehicle casts 46598 with
    // only TRIGGERED_IGNORE_CASTER_MOUNTED_OR_ON_VEHICLE set, which leaves the whole of
    // Spell::CheckCast in the way of a cast that has no business failing -- and when it
    // does fail it says nothing, applies no SPELL_AURA_CONTROL_VEHICLE, and so never queues
    // the VehicleJoinEvent.
    static void BoardVehicle(Unit* passenger, Unit* vehicle, int8 seat)
    {
        passenger->CastCustomSpell(VEHICLE_SPELL_RIDE_HARDCODED, SPELLVALUE_BASE_POINT0,
            seat + 1, vehicle, TRIGGERED_FULL_MASK);
    }

    void DespawnLoad()
    {
        // Top of the stack down, so the cart is still there to be stepped off.
        DespawnSummon(_bunny);
        DespawnSummon(_cart);
    }

    void DespawnFollowers()
    {
        for (ObjectGuid const& guid : _followers)
            if (npc_gnomeregan_recruit_column* follower = FollowerAI(guid))
                follower->EndRun();
        _followers.clear();
    }

    void DespawnSummon(ObjectGuid& guid)
    {
        if (Creature* summon = ObjectAccessor::GetCreature(*me, guid))
        {
            // Unsummoning a seated passenger goes through Unit::_ExitVehicle, which unroots
            // it and launches a spline that falls and lands beside the vehicle: the cart
            // visibly hops off the recruit's back and only then vanishes. Hiding it first
            // means that spline is launched for something no client is drawing any more.
            ConcealSummon(summon);
            summon->DespawnOrUnsummon();
        }

        guid.Clear();
    }

    RecruitColumnSlot _place;
    ObjectGuid _cart;
    ObjectGuid _bunny;
    std::vector<ObjectGuid> _followers;
    TaskScheduler _scheduler;
};

enum GnomeTravelerColumn
{
    POINT_TRAVELER_END      = 1
};

// Travelers ride the road at this pace, whatever they sit on and whether they sit on
// anything at all: not the template's walk and not its run, so it is set on the unit
// directly and the spline takes it from there.
static constexpr float TRAVELER_WALK_SPEED = 3.75f;

// A group stands at its start for a moment before it sets off, and the next one appears a
// few seconds after the last has gone: 650 yards at this pace is about three minutes, and
// the gap on top of it is rolled per run for the same reason the recruits' is.
static constexpr Milliseconds TRAVELER_SPAWN_TO_WALK = Milliseconds(2500);
static constexpr uint32 TRAVELER_RESPAWN_MIN_SECONDS = 5;
static constexpr uint32 TRAVELER_RESPAWN_MAX_SECONDS = 12;
static constexpr Milliseconds TRAVELER_FOLLOWER_END_GRACE = Milliseconds(5000);

// How many ride together. Singles and pairs are about as common as each other, and a
// three is the rarer sight.
static constexpr uint32 TRAVELER_PAIR_CHANCE = 40;
static constexpr uint32 TRAVELER_TRIO_CHANCE = 20;

// What a traveler rides, rolled per rider and per run. 0 is on foot, and comes up about
// as often as any one mount.
static uint32 const TravelerMounts[] = { 0, 6569, 9473, 9476, 10661 };

// The one route, south to north the whole length of the town: from the road into the zone
// below the Mountaineer post to the bend past Brewnall, where the group is gone. Element 0
// is the leader's start, overwritten by Launch like the recruits' is.
Position const GnomeTravelerRoad[] =
{
    { -5423.670f, -329.405f, 399.664f },
    { -5426.040f, -307.293f, 400.132f },
    { -5429.140f, -276.083f, 401.011f },
    { -5429.640f, -240.182f, 401.088f },
    { -5426.900f, -200.998f, 400.971f },
    { -5424.780f, -156.597f, 397.878f },
    { -5423.330f, -121.398f, 396.117f },
    { -5410.590f,  -87.943f, 393.051f },
    { -5394.090f,  -72.300f, 391.275f },
    { -5392.600f,  -37.582f, 391.104f },
    { -5388.440f,   -8.854f, 391.029f },
    { -5394.390f,   32.490f, 391.071f },
    { -5408.300f,   54.634f, 393.804f },
    { -5421.690f,   95.649f, 393.429f },
    { -5428.660f,  128.141f, 393.574f },
    { -5442.210f,  150.464f, 394.589f },
    { -5446.250f,  179.250f, 394.272f },
    { -5445.430f,  227.908f, 394.761f },
    { -5427.860f,  252.457f, 394.702f },
    { -5425.010f,  276.201f, 394.700f },
    { -5418.220f,  303.318f, 394.622f },
    { -5397.710f,  313.358f, 394.584f },
    { -5382.190f,  319.306f, 394.223f }
};

// The file behind the leader, same shape as the recruits': posts three and six yards
// back along the road, ends four and eight yards short of the leader's.
static RecruitColumnFollower const GnomeTravelerFollowers[] =
{
    { { -5423.570f, -332.259f, 399.613f, 1.5359f }, { -5385.923f, 317.869f, 394.416f } },
    { { -5423.470f, -335.113f, 399.562f, 1.5359f }, { -5389.660f, 316.443f, 394.420f } }
};

// A traveler's place in the file: slot 0 is the leader's post, slot n the n-th
// follower's. Same nearest-post rule as the recruits, for the same reason.
struct TravelerSlot
{
    bool   placed = false;
    size_t slot = 0;
};

static TravelerSlot TravelerSlotFor(Position const& home)
{
    TravelerSlot best;
    float bestDist = 5.0f;

    float dist = home.GetExactDist2d(&GnomeTravelerRoad[0]);
    if (dist < bestDist)
    {
        bestDist = dist;
        best = { true, 0 };
    }

    for (size_t i = 0; i < std::extent<decltype(GnomeTravelerFollowers)>::value; ++i)
    {
        dist = home.GetExactDist2d(&GnomeTravelerFollowers[i].start);
        if (dist < bestDist)
        {
            bestDist = dist;
            best = { true, i + 1 };
        }
    }

    return best;
}

// Gnome Travelers riding up through New Tinkertown. A group of one, two or three appears
// at the south end of the road, rides the length of the town in single file and is gone at
// the north end; the leader's respawn brings the next group a few seconds later.
//
// The leader is the one spawn. It rolls how many ride with it and summons them at their
// posts behind it; they run this same AI from creature_template.ScriptName and wait for
// its word. Every rider rolls its own mount from the pool, and the costume aura on the
// template addon gives each a face of its own, so no two groups look alike. One-way and
// summon-led for the reasons the recruits are: a waypoint path loops, and formations do
// not follow a MoveSmoothPath.
struct npc_gnome_traveler_column : public ScriptedAI
{
    npc_gnome_traveler_column(Creature* creature) : ScriptedAI(creature),
        _place(TravelerSlotFor(creature->GetHomePosition())) { }

    // Unattackable by flag, but the override keeps a forced target from ever putting a
    // chase under the ride, for the same reason as the recruits.
    void AttackStart(Unit* /*who*/) override { }
    void MoveInLineOfSight(Unit* /*who*/) override { }

    void Reset() override
    {
        _scheduler.CancelAll();

        me->SetReactState(REACT_PASSIVE);

        // Reset runs on anything that cuts a run short as well as on respawn; a leader's
        // followers from the abandoned run go with it.
        DespawnFollowers();

        if (!_place.placed)
        {
            TC_LOG_ERROR("scripts.ai", "npc_gnome_traveler_column: %s is not within five yards of any traveler post and will not move",
                me->GetGUID().ToString().c_str());
            return;
        }

        // Creature::setDeathState(JUST_RESPAWNED) runs LoadCreaturesAddon before
        // AI()->Reset(), and the template addon carries mount 0, which Unit::Mount leaves
        // alone -- so what is set here is what the rider wears for the run.
        if (uint32 mount = TravelerMounts[urand(0, std::extent<decltype(TravelerMounts)>::value - 1)])
            me->Mount(mount);
        else
            me->Dismount();

        me->SetSpeed(MOVE_WALK, TRAVELER_WALK_SPEED);

        if (IsLeader())
        {
            uint32 roll = urand(0, 99);
            size_t riding = roll < TRAVELER_TRIO_CHANCE ? 2 : roll < TRAVELER_TRIO_CHANCE + TRAVELER_PAIR_CHANCE ? 1 : 0;

            for (size_t i = 0; i < riding; ++i)
                if (TempSummon* follower = me->SummonCreature(me->GetEntry(), GnomeTravelerFollowers[i].start, TEMPSUMMON_MANUAL_DESPAWN))
                    _followers.push_back(follower->GetGUID());

            _scheduler.Schedule(TRAVELER_SPAWN_TO_WALK, [this](TaskContext /*task*/)
            {
                StartRun();

                for (ObjectGuid const& guid : _followers)
                    if (npc_gnome_traveler_column* follower = FollowerAI(guid))
                        follower->StartRun();
            });
        }
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != EFFECT_MOTION_TYPE || id != POINT_TRAVELER_END)
            return;

        if (!IsLeader())
        {
            _scheduler.Schedule(TRAVELER_FOLLOWER_END_GRACE, [this](TaskContext /*task*/)
            {
                EndRun();
            });
            return;
        }

        DespawnFollowers();
        me->DespawnOrUnsummon(0, Seconds(urand(TRAVELER_RESPAWN_MIN_SECONDS, TRAVELER_RESPAWN_MAX_SECONDS)));
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

    void StartRun()
    {
        if (!_place.placed)
            return;

        size_t size = std::extent<decltype(GnomeTravelerRoad)>::value;
        if (IsLeader())
        {
            me->GetMotionMaster()->MoveSmoothPath(POINT_TRAVELER_END, GnomeTravelerRoad, size, true);
            return;
        }

        std::vector<Position> path(GnomeTravelerRoad, GnomeTravelerRoad + size);
        path.back() = GnomeTravelerFollowers[_place.slot - 1].end;
        me->GetMotionMaster()->MoveSmoothPath(POINT_TRAVELER_END, path.data(), path.size(), true);
    }

    void EndRun()
    {
        _scheduler.CancelAll();
        me->DespawnOrUnsummon();
    }

private:
    bool IsLeader() const { return _place.slot == 0; }

    npc_gnome_traveler_column* FollowerAI(ObjectGuid const& guid) const
    {
        Creature* follower = ObjectAccessor::GetCreature(*me, guid);
        if (!follower)
            return nullptr;

        npc_gnome_traveler_column* ai = dynamic_cast<npc_gnome_traveler_column*>(follower->AI());
        if (!ai)
            TC_LOG_ERROR("scripts.ai", "npc_gnome_traveler_column: follower %s is not running this AI; creature_template.ScriptName for %u is missing",
                follower->GetGUID().ToString().c_str(), follower->GetEntry());
        return ai;
    }

    void DespawnFollowers()
    {
        for (ObjectGuid const& guid : _followers)
            if (npc_gnome_traveler_column* follower = FollowerAI(guid))
                follower->EndRun();
        _followers.clear();
    }

    TravelerSlot _place;
    std::vector<ObjectGuid> _followers;
    TaskScheduler _scheduler;
};

enum MountedMountaineerRide
{
    POINT_MOUNTAINEER_END   = 1,
    SPELL_MOUNTAINEER_SHOOT = 6660,

    GROUP_MOUNTAINEER_SHOOT = 1
};

// The pace of the ride, on the unit rather than the template: the entry's own run is
// slower than this and the other spawns of it keep that.
static constexpr float MOUNTAINEER_RUN_SPEED = 9.7f;

// The rider sets off almost as soon as it appears, and the next one appears a few seconds
// after it is gone: 850 yards at this pace is a minute and a half, and the gap on top of
// it is rolled per run so the cycle drifts against everything else on the road.
static constexpr Milliseconds MOUNTAINEER_SPAWN_TO_RIDE = Milliseconds(1000);
static constexpr uint32 MOUNTAINEER_RESPAWN_MIN_SECONDS = 5;
static constexpr uint32 MOUNTAINEER_RESPAWN_MAX_SECONDS = 11;

// Brewnall to Kharanos, north to south: out of the village, down the whole length of the
// main road past the Mountaineer post and into Kharanos, where the rider is gone. Element 0
// is the spawn, overwritten by Launch like the recruits' and travelers' are.
Position const MountedMountaineerRoad[] =
{
    { -5393.550f,   307.573f, 394.662f },
    { -5398.530f,   289.731f, 395.614f },
    { -5397.200f,   275.851f, 395.979f },
    { -5402.250f,   262.693f, 396.366f },
    { -5426.380f,   229.472f, 395.921f },
    { -5432.300f,   212.200f, 395.309f },
    { -5433.160f,   166.880f, 394.543f },
    { -5422.180f,   143.677f, 393.636f },
    { -5414.520f,   113.146f, 393.385f },
    { -5405.240f,    78.604f, 393.724f },
    { -5389.790f,    49.865f, 392.328f },
    { -5378.640f,    15.778f, 392.254f },
    { -5377.310f,   -22.033f, 392.626f },
    { -5377.400f,   -57.134f, 392.187f },
    { -5385.880f,   -81.458f, 393.009f },
    { -5397.920f,   -95.115f, 394.360f },
    { -5408.740f,  -115.679f, 395.199f },
    { -5413.710f,  -144.663f, 397.582f },
    { -5415.070f,  -173.470f, 399.502f },
    { -5416.690f,  -206.747f, 401.255f },
    { -5418.010f,  -224.663f, 401.516f },
    { -5419.220f,  -238.191f, 401.744f },
    { -5424.200f,  -254.884f, 401.171f },
    { -5423.600f,  -287.741f, 400.644f },
    { -5421.630f,  -317.769f, 399.920f },
    { -5420.150f,  -345.177f, 398.828f },
    { -5427.140f,  -373.990f, 398.633f },
    { -5437.970f,  -389.465f, 398.630f },
    { -5454.800f,  -405.455f, 398.810f },
    { -5471.060f,  -414.226f, 400.799f },
    { -5486.110f,  -416.292f, 401.562f },
    { -5507.610f,  -423.498f, 402.735f },
    { -5516.780f,  -444.911f, 402.694f },
    { -5522.748f,  -459.754f, 401.672f }
};

// A Mounted Ironforge Mountaineer riding from Brewnall Village down to Kharanos. It appears
// in the village, rides the road to the far end and is gone; its respawn brings the next
// one a few seconds later, so there is one on the road nearly all the time. One-way for
// the reason the recruits and travelers are: a waypoint path loops.
//
// It only ever fights from the saddle. Something that attacks it is shot at while the ride
// goes on, and once nothing has hurt it for a while the ride is all that is left; nothing
// ever turns it round or sends it home.
struct npc_mounted_ironforge_mountaineer : public ScriptedAI
{
    npc_mounted_ironforge_mountaineer(Creature* creature) : ScriptedAI(creature),
        _onPost(creature->GetHomePosition().GetExactDist2d(&MountedMountaineerRoad[0]) < 5.0f) { }

    // No chase, ever: the target is taken without melee so the client is not told a rifleman
    // has closed to melee, and the spline underneath is left alone.
    void AttackStart(Unit* who) override
    {
        if (who)
            me->Attack(who, false);
    }

    void Reset() override
    {
        _scheduler.CancelAll();

        me->SetReactState(REACT_DEFENSIVE);

        if (!_onPost)
        {
            TC_LOG_ERROR("scripts.ai", "npc_mounted_ironforge_mountaineer: %s is not within five yards of the Brewnall post and will not move",
                me->GetGUID().ToString().c_str());
            return;
        }

        me->SetSpeed(MOVE_RUN, MOUNTAINEER_RUN_SPEED);

        _scheduler.Schedule(MOUNTAINEER_SPAWN_TO_RIDE, [this](TaskContext /*task*/)
        {
            me->GetMotionMaster()->MoveSmoothPath(POINT_MOUNTAINEER_END, MountedMountaineerRoad,
                std::extent<decltype(MountedMountaineerRoad)>::value, false);
        });
    }

    void EnterCombat(Unit* /*who*/) override
    {
        _scheduler.Schedule(Milliseconds(urand(2300, 3900)), GROUP_MOUNTAINEER_SHOOT, [this](TaskContext task)
        {
            if (Unit* victim = me->GetVictim())
                DoCast(victim, SPELL_MOUNTAINEER_SHOOT);
            task.Repeat(Milliseconds(2300), Milliseconds(3900));
        });
    }

    // Evading is only ever the end of the fight, never a trip home: the ride is where it is.
    void EnterEvadeMode(EvadeReason why) override
    {
        if (!_EnterEvadeMode(why))
            return;

        _scheduler.CancelGroup(GROUP_MOUNTAINEER_SHOOT);
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != EFFECT_MOTION_TYPE || id != POINT_MOUNTAINEER_END)
            return;

        _scheduler.CancelAll();
        me->DespawnOrUnsummon(0, Seconds(urand(MOUNTAINEER_RESPAWN_MIN_SECONDS, MOUNTAINEER_RESPAWN_MAX_SECONDS)));
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);

        if (me->IsInCombat())
            UpdateVictim();
    }

private:
    bool _onPost;
    TaskScheduler _scheduler;
};

enum MonkTraining
{
    NPC_MONK_TRAINEE_TIMEKEEPER     = 63239,
    NPC_MONK_TRAINEE_SECOND         = 63241,
    NPC_MONK_TRAINEE_THIRD          = 63242,

    // Both are instant, cost nothing, have no cooldown and no target restriction of
    // any kind, and both apply SPELL_AURA_MOD_STUN to the caster for two seconds --
    // which is the student losing his footing. Nothing can refuse them, so they are
    // cast untriggered.
    SPELL_KNOCKDOWN                 = 13360,
    SPELL_DIZZY                     = 123540,

    EMOTE_MONK_ATTACK_UNARMED       = 507,
    EMOTE_MONK_SPECIAL_UNARMED      = 508,
    EMOTE_MONK_PARRY_UNARMED        = 509
};

// The drill runs on a two-beat rhythm: every strike is followed by either a short
// pause or a half-again longer one, rolled fresh each time and independent of the
// last, with the short beat coming up slightly more often than the long. It is the
// unevenness that makes the class look like it is working rather than ticking, so
// the two beats are kept apart rather than averaged into one interval.
static constexpr uint32 MONK_BEAT_SHORT = 4940;
static constexpr uint32 MONK_BEAT_LONG = 7420;
static constexpr int32 MONK_BEAT_SHORT_CHANCE = 55;

static uint32 MonkBeat()
{
    return roll_chance_i(MONK_BEAT_SHORT_CHANCE) ? MONK_BEAT_SHORT : MONK_BEAT_LONG;
}

// The three students stand within three yards of the one that keeps time. Ten is far
// enough to survive a spawn nudged off its mark and stops well short of the warrior
// drill ground, which begins about nine yards away and holds no monks.
static constexpr float MONK_CLASS_RANGE = 10.0f;

// Xi, Friend to the Small. He stands facing the middle of his three students and
// shadowboxes at them, and that is the whole of it -- he never moves, never speaks,
// and casts nothing. He keeps his own time rather than the class's: master and
// students are deliberately not in step with each other.
struct npc_xi_monk_trainer : public ScriptedAI
{
    npc_xi_monk_trainer(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _beat = MonkBeat();
    }

    void UpdateAI(uint32 diff) override
    {
        if (_beat > diff)
        {
            _beat -= diff;
            return;
        }

        _beat = MonkBeat();

        switch (urand(0, 2))
        {
            case 0: me->HandleEmoteCommand(EMOTE_MONK_ATTACK_UNARMED); break;
            case 1: me->HandleEmoteCommand(EMOTE_MONK_SPECIAL_UNARMED); break;
            case 2: me->HandleEmoteCommand(EMOTE_MONK_PARRY_UNARMED); break;
        }
    }

private:
    uint32 _beat = 0;
};

// The three Monk Trainees drawn up in front of Xi. They work as one class: all three
// strike together on the same beat, but each rolls its own move, so the unison is in
// the timing and not in what they throw.
//
// That shared beat is why only 63239 carries this script. Three creatures each
// keeping their own time drift apart within a few strikes and never come back
// together, because the beat is rolled rather than fixed; one timekeeper driving all
// three cannot. The other two need no script of their own and have none -- they are
// found by entry each beat rather than held as guids, so moving or respawning a
// student needs no change here.
struct npc_monk_trainee : public ScriptedAI
{
    npc_monk_trainee(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _beat = MonkBeat();
    }

    void UpdateAI(uint32 diff) override
    {
        if (_beat > diff)
        {
            _beat -= diff;
            return;
        }

        _beat = MonkBeat();

        Strike(me);

        if (Creature* second = me->FindNearestCreature(NPC_MONK_TRAINEE_SECOND, MONK_CLASS_RANGE))
            Strike(second);

        if (Creature* third = me->FindNearestCreature(NPC_MONK_TRAINEE_THIRD, MONK_CLASS_RANGE))
            Strike(third);
    }

private:
    // One student's move for one beat. Three parts strike to one part fall: each of
    // the three unarmed moves comes up twice as often as either of the two ways of
    // going down, so a quarter of all beats put somebody on the floor.
    static void Strike(Creature* trainee)
    {
        switch (urand(0, 7))
        {
            case 0:
            case 1:
                trainee->HandleEmoteCommand(EMOTE_MONK_ATTACK_UNARMED);
                break;
            case 2:
            case 3:
                trainee->HandleEmoteCommand(EMOTE_MONK_SPECIAL_UNARMED);
                break;
            case 4:
            case 5:
                trainee->HandleEmoteCommand(EMOTE_MONK_PARRY_UNARMED);
                break;
            case 6:
                trainee->CastSpell(trainee, SPELL_KNOCKDOWN, false);
                break;
            case 7:
                trainee->CastSpell(trainee, SPELL_DIZZY, false);
                break;
        }
    }

    uint32 _beat = 0;
};

enum NevinArrivals
{
    NPC_ARRIVAL_OPERATIVE  = 45847,
    NPC_ARRIVAL_TECHNICIAN = 46230,
    NPC_ARRIVAL_OFFICER    = 46025,

    // The step up to Nevin and the walk out of the camp. Neither id is ever heard: the
    // arrival is a summon carrying its entry's own AI, so its MovementInform goes there.
    // They are here because MoveSmoothPath demands one.
    POINT_ARRIVAL_STEP     = 10,
    POINT_ARRIVAL_WALK_OUT = 11
};

// The one spot every arrival appears on, orientation included -- it is already turned
// the way it is about to walk, so nothing has to face it when it lands.
Position const NevinArrivalPad = { -5201.760f, 478.174f, 388.543f, 5.0963612f };

// Two yards, from the pad up to Nevin's shoulder. Element 0 is never a destination --
// MoveSplineInit::Launch overwrites it with the mover's real position -- so it only
// records that the leg begins on the pad.
Position const NevinArrivalStep[] =
{
    { -5201.760f, 478.174f, 388.543f },
    { -5201.011f, 476.320f, 388.363f }
};

// The walk out: east past the front of the camp, north up its flank, then back
// south-west to the point it goes off at. Eleven nodes, and element 0 is the spot it
// saluted from rather than a destination of its own.
//
// The route is one-way and complete as it stands. It does not close -- the last node is
// twenty-four yards from the pad -- so the arrival is taken off there rather than
// turning round and walking back through the camp.
Position const NevinArrivalWalkOut[] =
{
    { -5201.011f, 476.320f, 388.363f },
    { -5196.053f, 474.901f, 388.679f },
    { -5186.080f, 473.747f, 388.322f },
    { -5181.280f, 479.153f, 388.285f },
    { -5180.780f, 488.089f, 388.068f },
    { -5185.950f, 495.590f, 387.977f },
    { -5190.030f, 506.799f, 387.764f },
    { -5192.920f, 514.186f, 387.683f },
    { -5198.780f, 511.991f, 388.400f },
    { -5205.100f, 505.281f, 388.400f },
    { -5205.901f, 502.219f, 388.400f }
};

static Position const& NevinArrivalEnd()
{
    return NevinArrivalWalkOut[std::extent<decltype(NevinArrivalWalkOut)>::value - 1];
}

// How close to the last node counts as having got there. The walk ends on it, so this
// only has to cover a spline stopping a little short.
static constexpr float ARRIVAL_END_TOLERANCE = 3.0f;

// Which of the three walks in is rolled fresh every run rather than rotating, so the
// same one can come twice in a row. The Operative comes up about half the time and the
// other two share the rest. The split is not firmly settled; levelling it is this array
// and nothing else.
struct NevinArrivalKind
{
    uint32 entry;
    uint32 weight;
};

static constexpr NevinArrivalKind ARRIVAL_KINDS[] =
{
    { NPC_ARRIVAL_OPERATIVE,  16 },
    { NPC_ARRIVAL_TECHNICIAN,  8 },
    { NPC_ARRIVAL_OFFICER,     6 }
};

static uint32 RollArrivalEntry()
{
    uint32 total = 0;
    for (NevinArrivalKind const& kind : ARRIVAL_KINDS)
        total += kind.weight;

    uint32 roll = urand(1, total);
    for (NevinArrivalKind const& kind : ARRIVAL_KINDS)
    {
        if (roll <= kind.weight)
            return kind.entry;

        roll -= kind.weight;
    }

    return ARRIVAL_KINDS[0].entry;
}

// Every beat of one run, measured from the moment the arrival appears.
//
// The step off is where the one second cast lands rather than where the creature is
// created, which is why it is not simply zero. The salute comes 0.4 seconds after the
// two-yard step ends, and the arrival holds that spot for 2.86 seconds in all before
// setting off -- the only pause anywhere in the run. It walks the rest without
// stopping.
static constexpr Milliseconds ARRIVE_TO_STEP     = Milliseconds(836);
static constexpr Milliseconds ARRIVE_TO_SALUTE   = Milliseconds(2049);
static constexpr Milliseconds ARRIVE_TO_WALK_OUT = Milliseconds(4497);

// A backstop, and normally already spent: the walk out takes about 32 seconds and the
// arrival is taken off the moment its spline finishes. This is only what catches a walk
// that never arrives -- something in the way, a spline that failed to launch -- so that
// the cycle cannot stall with an arrival left standing in the camp.
static constexpr Milliseconds ARRIVE_TO_GIVE_UP  = Milliseconds(50000);

// The camp stands empty between one arrival going off and the next appearing. The gap
// runs anywhere from 31 to 44 seconds, so it is rolled rather than fixed; a fixed gap
// would also lock this scene into step with the other timed ones around it for as long
// as the server is up.
static constexpr uint32 ARRIVAL_GAP_MIN_SECONDS = 31;
static constexpr uint32 ARRIVAL_GAP_MAX_SECONDS = 44;

// Nevin Twistwrench, creature guid 167450. He does nothing himself -- he stands where he
// stands and hands out his quests -- but the camp keeps reporting to him: about every 77
// seconds a S.A.F.E. Operative, Technician or Officer appears beside him, steps up,
// salutes, and walks out of the camp to the north before going off at the far end.
//
// The one that arrives is a summon and not one of the spawns standing here. All three
// entries use the one pad, one at a time and never two at once, and each is taken off at
// the end of its own walk. The three S.A.F.E. spawns standing around Nevin belong where
// they are and none of them is a stand-in for this: two of them sit, and none stands on
// the pad.
//
// Not SmartAI. The run drives a second creature's movement, pose and emote across two
// legs, and SMART_ACTION has no way to walk a creature that is not the one the script is
// attached to. On the spawn rather than on the entry: 42396 is Nevin everywhere, and
// this is the only place he is met.
//
// The name carries the suffix because `npc_nevin_twistwrench` is taken, by a different
// Nevin: entry 45966 in `zone_gnomeregan.cpp`, who irradiates players for the
// Decontamination quest. Two entries share the name in the client and only one of them
// can have the bare script name.
struct npc_nevin_twistwrench_arrivals : public ScriptedAI
{
    npc_nevin_twistwrench_arrivals(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();

        // Reset runs on respawn and on anything that cuts a run short -- a grid unload,
        // a .reload. Without this the arrival from the abandoned run is left standing
        // wherever the walk stopped it.
        DespawnArrival();

        _scheduler.Schedule(Milliseconds(1), [this](TaskContext /*task*/)
        {
            SummonArrival();
        });
    }

    void UpdateAI(uint32 diff) override
    {
        // No UpdateVictim, and nothing here that would give him one. Nevin's own
        // behaviour is untouched -- the scheduler is the whole of what this adds.
        _scheduler.Update(diff);

        // The arrival goes off when it gets to the end of its walk rather than when the
        // clock says it should. It is a summon carrying its entry's default AI, so its
        // MovementInform goes there and never reaches this script -- watching its spline
        // is the way to hear about the arrival from outside it. The scheduler is updated
        // first, so a leg issued this tick has already been launched and cannot read as
        // finished.
        if (!_walking)
            return;

        Creature* arrival = GetArrival();
        if (!arrival)
        {
            EndRun();
            return;
        }

        if (!arrival->movespline->Finalized() || arrival->GetExactDist(&NevinArrivalEnd()) > ARRIVAL_END_TOLERANCE)
            return;

        EndRun();
    }

private:

    void SummonArrival()
    {
        // Nothing is concealed here, and the cast is not triggered, for the same reason
        // the Loading Room arrival is written this way: the creature is created and the
        // cast begun in the same instant, and the flash lands 0.84 seconds later, so it
        // is briefly standing on the pad before the effect goes off. A triggered cast
        // collapses that into one instant, which is the tighter effect and the wrong
        // one.
        TempSummon* arrival = me->SummonCreature(RollArrivalEntry(), NevinArrivalPad, TEMPSUMMON_MANUAL_DESPAWN);
        if (!arrival)
        {
            // Nothing else would ever run again: every later summon is scheduled off the
            // end of the run this one was going to be.
            EndRun();
            return;
        }

        _arrival = arrival->GetGUID();

        // creature_addon cannot reach a summon, so what a summon wears is whatever
        // creature_template_addon says -- and 45847's row carries emote 214
        // EMOTE_STATE_READY_RIFLE and SheathState 2. An arrival has neither: it comes in
        // with an empty emote state and its gun stowed. Set here rather than left alone
        // because a state emote holds the model in its own pose and the arrival has a
        // walk to do; set immediately, before the creature has been through a grid
        // update, so no client is shown the template's values first.
        //
        // Nothing puts them back: LoadCreaturesAddon is what would, and it runs when a
        // creature reaches its home position, which this one never does -- it is passive,
        // it never evades, and it is taken off at the end of its walk.
        arrival->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NO_EMOTE);
        arrival->SetSheath(SHEATH_STATE_MELEE);

        // The route crosses the middle of the camp, and an arrival that stops to fight
        // never finishes it: a victim means ChaseMovementGenerator, which takes
        // MOTION_SLOT_ACTIVE off the walk, so the spline this script is watching for
        // never finalizes anywhere near the last node and the run is left to the backstop.
        arrival->SetReactState(REACT_PASSIVE);

        arrival->CastSpell(arrival, SPELL_TELEPORT, false);

        _scheduler.Schedule(ARRIVE_TO_STEP, [this](TaskContext /*task*/)
        {
            if (Creature* arrival = GetArrival())
                WalkRoute(arrival, POINT_ARRIVAL_STEP, NevinArrivalStep,
                    std::extent<decltype(NevinArrivalStep)>::value);
        });

        _scheduler.Schedule(ARRIVE_TO_SALUTE, [this](TaskContext /*task*/)
        {
            // The whole point of the walk in. Nothing turns it first: the two-yard step
            // leaves the arrival pointed within six degrees of Nevin already, so it
            // salutes on the direction it walked in on.
            if (Creature* arrival = GetArrival())
                arrival->HandleEmoteCommand(EMOTE_ONESHOT_SALUTE);
        });

        _scheduler.Schedule(ARRIVE_TO_WALK_OUT, [this](TaskContext /*task*/)
        {
            if (Creature* arrival = GetArrival())
            {
                WalkRoute(arrival, POINT_ARRIVAL_WALK_OUT, NevinArrivalWalkOut,
                    std::extent<decltype(NevinArrivalWalkOut)>::value);
                _walking = true;
            }
        });

        _scheduler.Schedule(ARRIVE_TO_GIVE_UP, [this](TaskContext /*task*/)
        {
            EndRun();
        });
    }

    // The end of one run and the start of the wait for the next. Both halves are here so
    // that the walk finishing early and the backstop firing late come to the same thing.
    void EndRun()
    {
        // The cancel goes first: it would otherwise take the next summon back off the
        // scheduler along with the beats of the run that has just ended.
        _scheduler.CancelAll();

        DespawnArrival();

        _scheduler.Schedule(Seconds(urand(ARRIVAL_GAP_MIN_SECONDS, ARRIVAL_GAP_MAX_SECONDS)),
            [this](TaskContext /*task*/)
        {
            SummonArrival();
        });
    }

    Creature* GetArrival()
    {
        return ObjectAccessor::GetCreature(*me, _arrival);
    }

    void DespawnArrival()
    {
        if (Creature* arrival = GetArrival())
            arrival->DespawnOrUnsummon();

        _arrival.Clear();
        _walking = false;
    }

    ObjectGuid _arrival;
    bool _walking = false;
    TaskScheduler _scheduler;
};

enum CrushcogHologram
{
    NPC_HINKLES_FASTBLAST            = 42491,
    NPC_KELSEY_STEELSPARK            = 42366,
    NPC_ELGIN_CLICKSPRING            = 42490,
    NPC_IMAGE_OF_RAZLO_CRUSHCOG      = 42505,
    NPC_IMAGE_OF_GNOMEREGAN_INFANTRY = 43131,
    NPC_IMAGE_OF_DWARF_MOUNTAINEER   = 43132,
    NPC_IMAGE_OF_MECHANO_TANK        = 43133,

    // Holds a model in a single frame. It is what makes the tanks and Crushcog himself
    // read as projected images rather than as NPCs standing about: they do not breathe,
    // shift weight or blink. The Infantry and the Mountaineers deliberately do not get
    // it, because they cheer.
    SPELL_FREEZE_ANIM                = 16245,

    // 43133 carries two models and rolls between them. Only this one is ever the tank
    // in this scene; 38985, the other, is a different machine entirely.
    MODEL_MECHANO_TANK_IMAGE         = 35960,

    SAY_SPARKNOZZLE_THERMAPLUGG      = 0,
    SAY_SPARKNOZZLE_INTELLIGENCE     = 1,
    SAY_SPARKNOZZLE_IN_POSITION      = 2,
    SAY_SPARKNOZZLE_YOURE_NEXT       = 3,

    SAY_HINKLES_SCOUTS               = 0,
    SAY_HINKLES_PROTOTYPE            = 1,

    SAY_KELSEY_IRONFORGE             = 0,

    SAY_ELGIN_BREWNALL               = 0,

    POINT_CRUSHCOG_STEP_OUT          = 1
};

// The four who speak all stand within eight yards of the Captain. Twenty is wide enough
// to find them from anywhere he could be nudged to and still far too narrow to reach
// another camp; each of these entries has exactly one spawn in the world anyway.
static constexpr float HOLOGRAM_CAST_RANGE = 20.0f;

// Crushcog's image is projected a pace in front of the plinth he stands on, walks a
// single yard and a quarter clear of it, and turns to face the gathering.
static Position const CrushcogMark      = { -5138.53f, 499.372f, 396.624f,  4.10152f };
static Position const CrushcogStepOut   = { -5137.77f, 500.366f, 396.58752f, 0.0f };
static constexpr float CRUSHCOG_FACING  = 3.996804f;

// Two mechano-tanks flank him, three dwarf mountaineers form up on one side and three
// Gnomeregan infantry on the other. Every one of these is a projection with no business
// of its own: they appear on their mark, hold it, and are gone again inside the minute.
static Position const MechanoTankMarks[] =
{
    { -5137.05f, 499.769f, 396.45734f, 3.106686f },
    { -5138.56f, 500.873f, 396.46933f, 4.345870f }
};

static Position const DwarfMountaineerMarks[] =
{
    { -5138.01f, 498.262f, 396.42035f, 1.500983f },
    { -5138.44f, 498.372f, 396.42136f, 1.413717f },
    { -5138.90f, 498.429f, 396.43634f, 1.413717f }
};

static Position const GnomereganInfantryMarks[] =
{
    { -5139.73f, 499.203f, 396.42035f, 6.195919f },
    { -5139.75f, 499.571f, 396.45633f, 6.195919f },
    { -5139.76f, 499.977f, 396.44333f, 6.195919f }
};

// Every beat, in milliseconds from the Captain's first line. The whole briefing is one
// fixed clock -- nothing in it waits on an arrival, a cast or a player.
static constexpr uint32 BRIEFING_FIRST_RUN_MS     = 30000;
static constexpr uint32 BRIEFING_CYCLE_MS         = 300000;

static constexpr uint32 BEAT_SPARKNOZZLE_SAY_0    = 0;
static constexpr uint32 BEAT_SPARKNOZZLE_ANSWER_0 = 3660;
static constexpr uint32 BEAT_SPARKNOZZLE_SAY_1    = 7330;
static constexpr uint32 BEAT_SPARKNOZZLE_ANSWER_1 = 11140;
static constexpr uint32 BEAT_HINKLES_SAY_0        = 17390;
static constexpr uint32 BEAT_CRUSHCOG_STEP_OUT    = 19060;
static constexpr uint32 BEAT_CRUSHCOG_TURN        = 19850;
static constexpr uint32 BEAT_TANKS_APPEAR         = 21060;
static constexpr uint32 BEAT_HINKLES_ANSWER_0     = 21060;
static constexpr uint32 BEAT_HINKLES_SAY_1        = 25870;
static constexpr uint32 BEAT_HINKLES_ANSWER_1     = 29500;
static constexpr uint32 BEAT_KELSEY_SAY_0         = 35640;
static constexpr uint32 BEAT_KELSEY_ANSWER_0      = 39280;
static constexpr uint32 BEAT_MOUNTAINEERS_APPEAR  = 45370;
static constexpr uint32 BEAT_ELGIN_SAY_0          = 45390;
static constexpr uint32 BEAT_ELGIN_ANSWER_0       = 48990;
static constexpr uint32 BEAT_CRUSHCOG_EXCLAIM     = 50650;
static constexpr uint32 BEAT_INFANTRY_APPEAR      = 51480;
static constexpr uint32 BEAT_SPARKNOZZLE_SAY_2    = 52660;
static constexpr uint32 BEAT_MOUNTAINEERS_CHEER   = 53860;
static constexpr uint32 BEAT_SPARKNOZZLE_ANSWER_2 = 56340;
static constexpr uint32 BEAT_CRUSHCOG_LEAVES      = 56900;
static constexpr uint32 BEAT_SPARKNOZZLE_SAY_3    = 59970;
static constexpr uint32 BEAT_INFANTRY_CHEER       = 62030;
static constexpr uint32 BEAT_SPARKNOZZLE_ANSWER_3 = 63630;

// How long each set of images is held. They are timed despawns rather than a scheduled
// cleanup so that a run cut short -- a grid unload, a .reload -- still takes them away.
static constexpr uint32 TANK_DURATION_MS         = 41530;
static constexpr uint32 MOUNTAINEER_DURATION_MS  = 13290;
static constexpr uint32 INFANTRY_DURATION_MS     = 14520;

// Crushcog's image is taken off and put back rather than hidden, which is what puts him
// on his mark again with no teleport and no leftover state. From C++ the respawn timer
// on a forced despawn is honoured: ForcedDespawn swaps m_respawnDelay for this value and
// zeroes the corpse delay for the duration of the kill, so he is back in eight seconds
// and not in his spawn timer plus a minute of corpse decay.
static constexpr Seconds CRUSHCOG_RETURN = Seconds(8);

// The Captain's briefing and the enemy it conjures. Every five minutes Captain Tread
// Sparknozzle runs through the state of the war with his three officers, and a projected
// Razlo Crushcog steps off his plinth with a mechano-tank escort while they do. The
// mountaineers and the infantry appear as each is spoken of, cheer, and wink out.
//
// The clock is free-running and has nothing to do with the player: it is a plain timer
// with no proximity condition anywhere in it, which is why the briefing keeps its place
// in the cycle whether or not anyone is standing there to watch it.
//
// Not SmartAI. The run drives four other creatures' speech, emotes, movement and
// lifetime, and holds eight summons across several beats to cheer them on cue; a
// SMART_ACTION reaches none of that, nor the one thing the database has no column for:
// forcing a summon's model off the entry's own roll.
struct npc_captain_tread_sparknozzle_scene : public ScriptedAI
{
    npc_captain_tread_sparknozzle_scene(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();
        _mountaineers.clear();
        _infantry.clear();

        _scheduler.Schedule(Milliseconds(BRIEFING_FIRST_RUN_MS), [this](TaskContext task)
        {
            StartBriefing();
            task.Repeat(Milliseconds(BRIEFING_CYCLE_MS));
        });
    }

    void UpdateAI(uint32 diff) override
    {
        // No UpdateVictim and no melee. The Captain is immune to everything and never
        // acquires a victim; the scheduler is the whole of what this adds to him.
        _scheduler.Update(diff);
    }

private:

    void StartBriefing()
    {
        _mountaineers.clear();
        _infantry.clear();

        Beat(BEAT_SPARKNOZZLE_SAY_0,    [this] { SayWithEmote(me, SAY_SPARKNOZZLE_THERMAPLUGG, EMOTE_ONESHOT_TALK); });
        Beat(BEAT_SPARKNOZZLE_ANSWER_0, [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_EXCLAMATION); });
        Beat(BEAT_SPARKNOZZLE_SAY_1,    [this] { SayWithEmote(me, SAY_SPARKNOZZLE_INTELLIGENCE, EMOTE_ONESHOT_TALK); });
        Beat(BEAT_SPARKNOZZLE_ANSWER_1, [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_QUESTION); });

        Beat(BEAT_HINKLES_SAY_0,    [this] { SayWithEmote(FindActor(NPC_HINKLES_FASTBLAST), SAY_HINKLES_SCOUTS, EMOTE_ONESHOT_TALK); });
        Beat(BEAT_HINKLES_ANSWER_0, [this] { Emote(FindActor(NPC_HINKLES_FASTBLAST), EMOTE_ONESHOT_TALK); });
        Beat(BEAT_HINKLES_SAY_1,    [this] { SayWithEmote(FindActor(NPC_HINKLES_FASTBLAST), SAY_HINKLES_PROTOTYPE, EMOTE_ONESHOT_TALK); });
        Beat(BEAT_HINKLES_ANSWER_1, [this] { Emote(FindActor(NPC_HINKLES_FASTBLAST), EMOTE_ONESHOT_TALK); });

        Beat(BEAT_KELSEY_SAY_0,    [this] { SayWithEmote(FindActor(NPC_KELSEY_STEELSPARK), SAY_KELSEY_IRONFORGE, EMOTE_ONESHOT_TALK); });
        Beat(BEAT_KELSEY_ANSWER_0, [this] { Emote(FindActor(NPC_KELSEY_STEELSPARK), EMOTE_ONESHOT_TALK); });

        Beat(BEAT_ELGIN_SAY_0,    [this] { SayWithEmote(FindActor(NPC_ELGIN_CLICKSPRING), SAY_ELGIN_BREWNALL, EMOTE_ONESHOT_TALK); });
        Beat(BEAT_ELGIN_ANSWER_0, [this] { Emote(FindActor(NPC_ELGIN_CLICKSPRING), EMOTE_ONESHOT_POINT); });

        Beat(BEAT_SPARKNOZZLE_SAY_2,    [this] { SayWithEmote(me, SAY_SPARKNOZZLE_IN_POSITION, EMOTE_ONESHOT_TALK); });
        Beat(BEAT_SPARKNOZZLE_ANSWER_2, [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_TALK); });
        Beat(BEAT_SPARKNOZZLE_SAY_3,    [this] { SayWithEmote(me, SAY_SPARKNOZZLE_YOURE_NEXT, EMOTE_ONESHOT_TALK); });
        Beat(BEAT_SPARKNOZZLE_ANSWER_3, [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_POINT); });

        ScheduleCrushcog();
        ScheduleImages();
    }

    void ScheduleCrushcog()
    {
        Beat(BEAT_CRUSHCOG_STEP_OUT, [this]
        {
            Creature* crushcog = FindActor(NPC_IMAGE_OF_RAZLO_CRUSHCOG);
            if (!crushcog)
                return;

            // Frozen is the pose he holds on the plinth. It has to come off before he is
            // asked to walk or the model stays in that single frame while he slides.
            crushcog->RemoveAurasDueToSpell(SPELL_FREEZE_ANIM);

            // A yard and a quarter, walked, off his own mark. MoveSplineInit reads
            // args.walk off MOVEMENTFLAG_WALKING in its constructor, so the walk flag
            // has to be set before the generator builds the spline; PointMovementGenerator
            // never sets it itself and an unprepared MovePoint runs.
            //
            // No generated path: it is a straight step across open flagstone, and the
            // navmesh has no idea the plinth is there.
            crushcog->SetWalk(true);
            crushcog->GetMotionMaster()->MovePoint(POINT_CRUSHCOG_STEP_OUT, CrushcogStepOut, false);
        });

        Beat(BEAT_CRUSHCOG_TURN, [this]
        {
            // The step ends without a facing of its own, and he turns to the gathering
            // about eight tenths of a second after it -- by which time the half-second
            // spline is long finished, so nothing overwrites this.
            if (Creature* crushcog = FindActor(NPC_IMAGE_OF_RAZLO_CRUSHCOG))
                crushcog->SetFacingTo(CRUSHCOG_FACING);
        });

        Beat(BEAT_CRUSHCOG_EXCLAIM, [this]
        {
            if (Creature* crushcog = FindActor(NPC_IMAGE_OF_RAZLO_CRUSHCOG))
                crushcog->HandleEmoteCommand(EMOTE_ONESHOT_EXCLAMATION);
        });

        Beat(BEAT_CRUSHCOG_LEAVES, [this]
        {
            // Taken off the field entirely, and back on his mark eight seconds later
            // with his facing and his frozen pose restored by his own Reset. Nothing here
            // has to put him back: he is a database spawn, so the map respawns him where
            // he belongs.
            if (Creature* crushcog = FindActor(NPC_IMAGE_OF_RAZLO_CRUSHCOG))
                crushcog->DespawnOrUnsummon(0, CRUSHCOG_RETURN);
        });
    }

    void ScheduleImages()
    {
        Beat(BEAT_TANKS_APPEAR, [this]
        {
            for (Position const& mark : MechanoTankMarks)
                if (Creature* tank = SummonImage(NPC_IMAGE_OF_MECHANO_TANK, mark, TANK_DURATION_MS))
                    // The entry rolls between two models and only one of them is this
                    // machine. Set before the creature has been through a grid update so
                    // no client is shown the other one first.
                    tank->SetDisplayId(MODEL_MECHANO_TANK_IMAGE);
        });

        Beat(BEAT_MOUNTAINEERS_APPEAR, [this]
        {
            // No model forced on these or on the infantry: both entries carry exactly the
            // set of models the images are drawn from, and the roll is part of the scene.
            for (Position const& mark : DwarfMountaineerMarks)
                if (Creature* mountaineer = SummonImage(NPC_IMAGE_OF_DWARF_MOUNTAINEER, mark, MOUNTAINEER_DURATION_MS))
                    _mountaineers.push_back(mountaineer->GetGUID());
        });

        Beat(BEAT_INFANTRY_APPEAR, [this]
        {
            for (Position const& mark : GnomereganInfantryMarks)
                if (Creature* infantry = SummonImage(NPC_IMAGE_OF_GNOMEREGAN_INFANTRY, mark, INFANTRY_DURATION_MS))
                    _infantry.push_back(infantry->GetGUID());
        });

        Beat(BEAT_MOUNTAINEERS_CHEER, [this] { CheerAll(_mountaineers); });
        Beat(BEAT_INFANTRY_CHEER,     [this] { CheerAll(_infantry); });
    }

    Creature* SummonImage(uint32 entry, Position const& mark, uint32 durationMs)
    {
        // Nothing is concealed and nothing is revealed. The images are meant to be seen
        // arriving -- they blink into place on their marks, which is the whole effect.
        return me->SummonCreature(entry, mark, TEMPSUMMON_TIMED_DESPAWN, durationMs);
    }

    void CheerAll(std::vector<ObjectGuid> const& images)
    {
        for (ObjectGuid const& guid : images)
            if (Creature* image = ObjectAccessor::GetCreature(*me, guid))
                image->HandleEmoteCommand(EMOTE_ONESHOT_CHEER);
    }

    // Each officer plays a gesture a fraction before the line rather than with it, which
    // is what makes the mouth movement land on the text instead of after it.
    static void SayWithEmote(Creature* speaker, uint8 group, uint32 emote)
    {
        if (!speaker)
            return;

        speaker->HandleEmoteCommand(emote);
        speaker->AI()->Talk(group);
    }

    static void Emote(Creature* actor, uint32 emote)
    {
        if (actor)
            actor->HandleEmoteCommand(emote);
    }

    Creature* FindActor(uint32 entry)
    {
        // Looked up per beat rather than held. Crushcog's image is off the field for the
        // last eight seconds of every run and comes back as a fresh object, so a cached
        // pointer would be stale exactly when the next run needs it.
        return me->FindNearestCreature(entry, HOLOGRAM_CAST_RANGE);
    }

    template<typename Action>
    void Beat(uint32 offsetMs, Action&& action)
    {
        _scheduler.Schedule(Milliseconds(offsetMs), [action](TaskContext /*task*/) { action(); });
    }

    std::vector<ObjectGuid> _mountaineers;
    std::vector<ObjectGuid> _infantry;
    TaskScheduler _scheduler;
};

// The projection of Razlo Crushcog that stands on the plinth between briefings. The
// frozen pose is the one thing that has to survive every respawn, and the briefing takes
// it off him at the moment he steps out.
//
// Reset is the right place for it because the briefing puts him back by despawning him:
// Creature::Respawn calls it, so this runs once per cycle with no help from the Captain.
//
// He does not hover, and cannot be made to from here. The bit that would do it is carried
// on the create block rather than by any movement flag or addon column, and this core
// hardcodes it off when it builds an object's movement update; the one packet that could
// raise it afterwards has no effect on this client.
struct npc_image_of_razlo_crushcog : public ScriptedAI
{
    npc_image_of_razlo_crushcog(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->CastSpell(me, SPELL_FREEZE_ANIM, true);
    }
};

enum TockRestoration
{
    NPC_GNOME_RESTORATION_APPARATUS = 43035,
    NPC_RECOVERED_GNOME             = 43033,

    GO_RECOVERED_HELM               = 204255,
    GO_APPARATUS_CONTROL_CONSOLE    = 204266,

    QUEST_WHATS_LEFT_BEHIND         = 26264,

    // 43035 carries two models and rolls between them. Only 28016 is the machine that
    // stands in the yard; 20570 is a different device entirely.
    MODEL_RESTORATION_APPARATUS     = 28016,

    // Tock's goggles are a model swap rather than an equipped item, so they go on and
    // come off as an aura.
    SPELL_GOGGLE_TRANSFORM          = 80414,

    SPELL_LIGHTNING_BEAM            = 80409,
    SPELL_PERSONNEL_LAUNCHER_STATE  = 80381,
    SPELL_LIGHTNING_NOVA            = 57322,
    SPELL_EXPLOSION                 = 62987,
    SPELL_EXPLOSION_COUNTDOWN       = 80531,

    SAY_TOCK_PROCESS                = 0,
    SAY_TOCK_GOGGLES                = 1,
    SAY_TOCK_AMAZING                = 2,
    SAY_TOCK_ALL_THERE              = 3,
    SAY_TOCK_COME_BACK              = 4,
    SAY_TOCK_MEDIC                  = 5,
    SAY_TOCK_ROCKET_SCIENTIST       = 6,

    SAY_GNOME_WHAT_HAPPENED         = 0,
    SAY_GNOME_NOT_HERE              = 1,

    POINT_TOCK_MACHINE              = 1,
    POINT_TOCK_DIAL                 = 2,
    POINT_TOCK_HOME                 = 3,
    POINT_GNOME_STEP_OFF            = 4,
    POINT_GNOME_AWAY                = 5
};

// Tock crosses to the machine and then round to the side of it. Element 0 of each of
// these is the point he is standing on when the leg goes out, never a destination:
// MoveSplineInit::Launch overwrites it with the mover's real position.
//
// The second leg swings wide of the apparatus rather than cutting the corner, and the
// navmesh has no idea the apparatus is there, so both are written out instead of asked
// of the pathfinder.
Position const TockToMachine[] =
{
    { -5054.6494f, 480.51040f, 402.97450f },
    { -5054.0010f, 483.07986f, 402.93810f },
    { -5054.3525f, 483.64932f, 402.90173f }
};

Position const TockToDial[] =
{
    { -5054.3525f, 483.64932f, 402.90173f },
    { -5052.0195f, 481.42450f, 403.51550f },
    { -5052.0195f, 482.42450f, 403.26550f },
    { -5052.1860f, 483.19965f, 403.12924f }
};

// He turns to the machine once he is beside it. The second leg ends heading away from
// it, so without this he works the dials with his back to them.
static constexpr float TOCK_FACING_MACHINE = 2.478368f;

// The apparatus is two pieces standing one above the other, not two machines: a base
// with a hood over it, both on the same bearing.
Position const ApparatusBase = { -5054.8804f, 484.59897f, 402.78992f, 4.188790f };
Position const ApparatusHood = { -5054.6700f, 485.01900f, 404.74835f, 4.188790f };

// The helm is what is left of the gnome before the machine runs, and it lies where he
// will be standing when it is done.
Position const RecoveredHelmMark = { -5054.9653f, 484.48438f, 403.19894f, 4.4854965f };
QuaternionData const RecoveredHelmRotation = QuaternionData(0.0f, 0.0f, -0.78260803f, 0.6225148f);

Position const RecoveredGnomeMark = { -5054.9930f, 484.44790f, 403.16900f, 4.276057f };

// He comes to on the spot the helm was lying on, gets up, and takes a single quick step
// clear of the machine before he is turned to face Tock.
Position const RecoveredGnomeStepOff = { -5055.3400f, 482.72000f, 402.63400f };
static constexpr float RECOVERED_GNOME_FACING = 3.787364f;

// And then walks off towards the camp, ignoring every word said to him.
Position const RecoveredGnomeAway[] =
{
    { -5055.3400f, 482.72000f, 402.63400f },
    { -5063.0796f, 476.95640f, 402.88318f },
    { -5065.5796f, 475.20640f, 403.13318f },
    { -5067.3193f, 473.69278f, 403.13235f }
};

// Every beat, in milliseconds from the moment the quest is handed in.
static constexpr uint32 BEAT_TOCK_SAY_PROCESS      = 195;
static constexpr uint32 BEAT_TOCK_EXCLAIM          = 3469;
static constexpr uint32 BEAT_TOCK_TO_MACHINE       = 8304;
static constexpr uint32 BEAT_TOCK_WORKING          = 9896;
static constexpr uint32 BEAT_HELM_APPEARS          = 13156;
static constexpr uint32 BEAT_TOCK_STOPS_WORKING    = 13577;
static constexpr uint32 BEAT_TOCK_TO_DIAL          = 14392;
static constexpr uint32 BEAT_TOCK_FACES_MACHINE    = 16817;
static constexpr uint32 BEAT_TOCK_GOGGLES_ON       = 17996;
static constexpr uint32 BEAT_CONSOLE_OPENS         = 17996;
static constexpr uint32 BEAT_TOCK_SAY_GOGGLES      = 18165;
static constexpr uint32 BEAT_APPARATUS_APPEARS     = 22901;
static constexpr uint32 BEAT_GNOME_APPEARS         = 29317;
static constexpr uint32 BEAT_CONSOLE_CLOSES        = 29430;
static constexpr uint32 BEAT_HELM_GONE             = 29430;
static constexpr uint32 BEAT_TOCK_STOPS_WORKING_2  = 29761;
static constexpr uint32 BEAT_CONSOLE_RELEASED      = 30687;
static constexpr uint32 BEAT_GNOME_SAY_WHAT        = 31941;
static constexpr uint32 BEAT_TOCK_SAY_AMAZING      = 35575;
static constexpr uint32 BEAT_GNOME_STEPS_OFF       = 36654;
static constexpr uint32 BEAT_GNOME_STANDS          = 37096;
static constexpr uint32 BEAT_TOCK_SAY_ALL_THERE    = 40456;
static constexpr uint32 BEAT_GNOME_SAY_NOT_HERE    = 42885;
static constexpr uint32 BEAT_TOCK_QUESTION         = 45173;
static constexpr uint32 BEAT_GNOME_QUESTION        = 46412;
static constexpr uint32 BEAT_GNOME_LEAVES          = 51252;
static constexpr uint32 BEAT_TOCK_GOES_HOME        = 53697;
static constexpr uint32 BEAT_TOCK_GOGGLES_OFF      = 54966;
static constexpr uint32 BEAT_TOCK_SAY_COME_BACK    = 55042;
static constexpr uint32 BEAT_GNOME_EXPLODES        = 57343;
static constexpr uint32 BEAT_TOCK_SAY_MEDIC        = 58689;
static constexpr uint32 BEAT_TOCK_SAY_ROCKET       = 61108;
static constexpr uint32 BEAT_DEMONSTRATION_ENDS    = 61500;

// How long each creature summon is held. These are timed despawns rather than scheduled
// cleanup so that a run cut short -- a grid unload, a .reload -- still takes them away.
// The helm is not: a creature-owned gameobject never goes on its timer on this core (the
// expiry takes the respawn branch and leaves it standing), so it is held by guid and
// deleted at its beat. A grid unload takes it with Tock, and Reset() covers a .reload.
static constexpr uint32 APPARATUS_DURATION_MS      = 8926;
static constexpr uint32 RECOVERED_GNOME_LIFETIME   = 30623;

// How close Tock stands to the console when he works it.
static constexpr float CONSOLE_SEARCH_RANGE        = 5.0f;

// Tock Sprysprocket, who ends "What's Left Behind". Hand the quest in and he walks over
// to his apparatus, works it up, pulls a whole gnome out of the sludge the player
// brought him, and watches his subject walk off and detonate.
//
// Not SmartAI. The run summons a gameobject and three creatures, holds the gnome across
// eight later beats to move, turn, stand, speak and blow him up, and forces a model off
// an entry that rolls between two; a SMART_ACTION reaches none of that.
//
// The clock is fixed and nothing in it waits on an arrival or a cast, so the whole run
// is scheduled up front from the hand-in.
struct npc_tock_sprysprocket : public ScriptedAI
{
    npc_tock_sprysprocket(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();
        _gnome.Clear();
        _running = false;

        me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NO_EMOTE);
        me->RemoveAurasDueToSpell(SPELL_GOGGLE_TRANSFORM);

        ClearHelm();
        ReleaseConsole();
    }

    void sQuestReward(Player* /*player*/, Quest const* quest, uint32 /*opt*/) override
    {
        if (quest->GetQuestId() != QUEST_WHATS_LEFT_BEHIND)
            return;

        // A second hand-in while the first is still running is ignored rather than
        // queued. There is one apparatus and one mark to stand a gnome on, so a second
        // run would put two of everything in the same square yard.
        if (_running)
            return;

        StartDemonstration();
    }

    void UpdateAI(uint32 diff) override
    {
        // No UpdateVictim and no melee. Tock is immune to players and creatures alike
        // and never acquires a victim; the scheduler is the whole of what this adds.
        _scheduler.Update(diff);
    }

private:

    void StartDemonstration()
    {
        _running = true;
        _gnome.Clear();
        _helm.Clear();
        _console.Clear();

        ScheduleTock();
        ScheduleMachine();
        ScheduleGnome();

        Beat(BEAT_DEMONSTRATION_ENDS, [this] { _running = false; });
    }

    void ScheduleTock()
    {
        Beat(BEAT_TOCK_SAY_PROCESS, [this] { Talk(SAY_TOCK_PROCESS); });
        Beat(BEAT_TOCK_EXCLAIM,     [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_EXCLAMATION); });

        Beat(BEAT_TOCK_TO_MACHINE, [this]
        {
            WalkRoute(me, POINT_TOCK_MACHINE, TockToMachine,
                std::extent<decltype(TockToMachine)>::value);
        });

        // Standing at the machine with his hands on it. This is a state rather than a
        // gesture: it holds until it is cleared.
        Beat(BEAT_TOCK_WORKING,       [this] { me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_USE_STANDING); });
        Beat(BEAT_TOCK_STOPS_WORKING, [this] { me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NO_EMOTE); });

        Beat(BEAT_TOCK_TO_DIAL, [this]
        {
            WalkRoute(me, POINT_TOCK_DIAL, TockToDial,
                std::extent<decltype(TockToDial)>::value);
        });

        // The leg above ends without a facing of its own, and this lands two and a half
        // seconds after it -- well clear of the two-second spline, so nothing overwrites
        // it.
        Beat(BEAT_TOCK_FACES_MACHINE, [this] { me->SetFacingTo(TOCK_FACING_MACHINE); });

        Beat(BEAT_TOCK_GOGGLES_ON, [this]
        {
            me->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
            me->CastSpell(me, SPELL_GOGGLE_TRANSFORM, true);
            me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_USE_STANDING);
        });

        // The console opens the instant his hands go on it and stays open for the whole
        // eleven and a half seconds he works it -- longer than its own ten-second
        // auto-close -- so the state is written directly rather than going through
        // UseDoorOrButton and its timer. The flag comes off a second and a quarter after
        // it shuts.
        Beat(BEAT_CONSOLE_OPENS, [this]
        {
            GameObject* console = me->FindNearestGameObject(GO_APPARATUS_CONTROL_CONSOLE, CONSOLE_SEARCH_RANGE);
            if (!console)
                return;

            _console = console->GetGUID();
            console->SetFlag(GAMEOBJECT_FLAGS, GO_FLAG_IN_USE);
            console->SetGoState(GO_STATE_ACTIVE);
        });

        Beat(BEAT_CONSOLE_CLOSES, [this]
        {
            if (GameObject* console = Console())
                console->SetGoState(GO_STATE_READY);
        });

        Beat(BEAT_CONSOLE_RELEASED, [this] { ReleaseConsole(); });

        Beat(BEAT_TOCK_SAY_GOGGLES,     [this] { Talk(SAY_TOCK_GOGGLES); });
        Beat(BEAT_TOCK_STOPS_WORKING_2, [this] { me->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NO_EMOTE); });
        Beat(BEAT_TOCK_SAY_AMAZING,     [this] { Talk(SAY_TOCK_AMAZING); });
        Beat(BEAT_TOCK_SAY_ALL_THERE,   [this] { Talk(SAY_TOCK_ALL_THERE); });
        Beat(BEAT_TOCK_QUESTION,        [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_QUESTION); });

        Beat(BEAT_TOCK_GOES_HOME, [this]
        {
            // Run, and straight: he hurries back to his post as the gnome walks off.
            // The walk out left him facing the way he was travelling, and the line back
            // to the spawn point happens to leave him on his spawn facing, so nothing
            // has to turn him at the end of it.
            me->SetWalk(false);
            me->GetMotionMaster()->MovePoint(POINT_TOCK_HOME, me->GetHomePosition(), false);
        });

        Beat(BEAT_TOCK_GOGGLES_OFF,   [this] { me->RemoveAurasDueToSpell(SPELL_GOGGLE_TRANSFORM); });
        Beat(BEAT_TOCK_SAY_COME_BACK, [this] { Talk(SAY_TOCK_COME_BACK); });
        Beat(BEAT_TOCK_SAY_MEDIC,     [this] { Talk(SAY_TOCK_MEDIC); });
        Beat(BEAT_TOCK_SAY_ROCKET,    [this] { Talk(SAY_TOCK_ROCKET_SCIENTIST); });
    }

    void ScheduleMachine()
    {
        Beat(BEAT_HELM_APPEARS, [this]
        {
            if (GameObject* helm = me->SummonGameObject(GO_RECOVERED_HELM, RecoveredHelmMark, RecoveredHelmRotation, 0))
                _helm = helm->GetGUID();
        });

        // Gone in the same instant the console shuts.
        Beat(BEAT_HELM_GONE, [this] { ClearHelm(); });

        Beat(BEAT_APPARATUS_APPEARS, [this]
        {
            SummonApparatus(ApparatusBase, SPELL_LIGHTNING_BEAM);
            SummonApparatus(ApparatusHood, SPELL_PERSONNEL_LAUNCHER_STATE);
        });
    }

    void SummonApparatus(Position const& mark, uint32 spell)
    {
        Creature* piece = me->SummonCreature(NPC_GNOME_RESTORATION_APPARATUS, mark,
            TEMPSUMMON_TIMED_DESPAWN, APPARATUS_DURATION_MS);
        if (!piece)
            return;

        // The entry rolls between two models and only one of them is this machine. Set
        // before the creature has been through a grid update so that no client is shown
        // the other one first.
        piece->SetDisplayId(MODEL_RESTORATION_APPARATUS);
        piece->CastSpell(piece, spell, true);
    }

    void ScheduleGnome()
    {
        Beat(BEAT_GNOME_APPEARS, [this]
        {
            // He arrives already sitting, from creature_template_addon: LoadCreaturesAddon
            // runs inside Creature::UpdateEntry before the creature reaches the map, so
            // setting the stand state here instead would show him upright for a frame and
            // then sit him down.
            Creature* gnome = me->SummonCreature(NPC_RECOVERED_GNOME, RecoveredGnomeMark,
                TEMPSUMMON_TIMED_DESPAWN, RECOVERED_GNOME_LIFETIME);
            if (!gnome)
                return;

            _gnome = gnome->GetGUID();
            gnome->CastSpell(gnome, SPELL_LIGHTNING_NOVA, true);
        });

        Beat(BEAT_GNOME_SAY_WHAT, [this] { GnomeTalk(SAY_GNOME_WHAT_HAPPENED); });

        Beat(BEAT_GNOME_STEPS_OFF, [this]
        {
            if (Creature* gnome = Gnome())
            {
                gnome->SetWalk(false);
                gnome->GetMotionMaster()->MovePoint(POINT_GNOME_STEP_OFF, RecoveredGnomeStepOff, false);
            }
        });

        Beat(BEAT_GNOME_STANDS, [this]
        {
            // Turned and then stood, in that order and in the same instant. The step off
            // the mark ends looking at the machine, so a gnome that stands up on the
            // bearing he arrived on has his back to the conversation.
            if (Creature* gnome = Gnome())
            {
                gnome->SetFacingTo(RECOVERED_GNOME_FACING);
                gnome->SetStandState(UNIT_STAND_STATE_STAND);
            }
        });

        Beat(BEAT_GNOME_SAY_NOT_HERE, [this] { GnomeTalk(SAY_GNOME_NOT_HERE); });

        Beat(BEAT_GNOME_QUESTION, [this]
        {
            if (Creature* gnome = Gnome())
                gnome->HandleEmoteCommand(EMOTE_ONESHOT_QUESTION);
        });

        Beat(BEAT_GNOME_LEAVES, [this]
        {
            if (Creature* gnome = Gnome())
                WalkRoute(gnome, POINT_GNOME_AWAY, RecoveredGnomeAway,
                    std::extent<decltype(RecoveredGnomeAway)>::value);
        });

        Beat(BEAT_GNOME_EXPLODES, [this]
        {
            // The countdown carries the knockback that lifts him off his feet; the
            // explosion is the blast itself. Both go off together and he is gone two and
            // a half seconds later, on his own despawn timer.
            if (Creature* gnome = Gnome())
            {
                gnome->CastSpell(gnome, SPELL_EXPLOSION, true);
                gnome->CastSpell(gnome, SPELL_EXPLOSION_COUNTDOWN, true);
            }
        });
    }

    void GnomeTalk(uint8 group)
    {
        if (Creature* gnome = Gnome())
            gnome->AI()->Talk(group);
    }

    Creature* Gnome()
    {
        return ObjectAccessor::GetCreature(*me, _gnome);
    }

    GameObject* Console()
    {
        if (_console.IsEmpty())
            return nullptr;
        return ObjectAccessor::GetGameObject(*me, _console);
    }

    // Shut and released. Safe to call on a console that was never opened.
    void ReleaseConsole()
    {
        if (GameObject* console = Console())
        {
            console->RemoveFlag(GAMEOBJECT_FLAGS, GO_FLAG_IN_USE);
            console->SetGoState(GO_STATE_READY);
        }
        _console.Clear();
    }

    void ClearHelm()
    {
        if (!_helm.IsEmpty())
            if (GameObject* helm = ObjectAccessor::GetGameObject(*me, _helm))
                helm->Delete();
        _helm.Clear();
    }

    template<typename Action>
    void Beat(uint32 offsetMs, Action&& action)
    {
        _scheduler.Schedule(Milliseconds(offsetMs), [action](TaskContext /*task*/) { action(); });
    }

    ObjectGuid _gnome;
    ObjectGuid _helm;
    ObjectGuid _console;
    bool _running = false;
    TaskScheduler _scheduler;
};

enum FinishinTheJob
{
    NPC_FROSTMANE_HOLD_TARGET           = 42739,
    NPC_EXPLOSIVE_FUSE                  = 42763,
    GO_POWDER_KEG                       = 204041,
    GO_COLLAPSING_BOULDERS              = 204047,

    // A permanent dummy aura whose visual is the burning look on the fuse.
    SPELL_RED_BANISH_STATE              = 33343,
    // SPELL_EFFECT_ACTIVATE_OBJECT on every gameobject within 15 yards of the caster.
    // This core's EffectActivateObject ignores the action id and calls
    // GameObject::Use, which for a keg is the right thing: Data3 holds it in use for
    // three seconds and Data5 makes it consumable, so it despawns on its own and
    // comes back on the spawn's timer.
    SPELL_TRIGGER_POWDER_KEG_EXPLOSIONS = 79695
};

// The fuse lights beside the plunger and runs to the middle of the pile.
static Position const FuseLitMark  = { -5522.96f, 707.93054f, 376.69687f, 4.607669f };
static Position const FusePileMark = { -5523.598f, 699.30615f, 375.99692f };

// 8.65 yards in 1457 ms.
static constexpr float FUSE_BURN_SPEED = 5.94f;

// The rockfall at the tunnel mouth, 7 yards from the plunger.
static Position const BouldersMark = { -5520.566f, 693.2934f, 378.2548f, 1.9896724f };
static QuaternionData const BouldersRotation = QuaternionData(0.0f, 0.0f, 0.8386698f, 0.54464024f);

// From the press to the fuse setting off:
static constexpr uint32 BEAT_PLUNGER_ANIM  = 1100;
static constexpr uint32 BEAT_FUSE_LIT      = 2000;
static constexpr uint32 BEAT_KEGS_BLOW     = 4850;
static constexpr uint32 BEAT_BOULDERS_FALL = 7600;
// and from the fuse lighting to its running and going out.
static constexpr uint32 FUSE_LIT_TO_RUN    = 1200;
static constexpr uint32 FUSE_LIFETIME_MS   = 4850;
// From the rockfall to the rocks settling (the IN_USE flag comes off) and clearing.
static constexpr uint32 BOULDERS_SETTLE_MS   = 6700;
static constexpr uint32 BOULDERS_LIFETIME_MS = 14900;

// How far the detonator reaches for the trigger creature and the kegs. The trigger
// stands 10 yards from the plunger and the far edge of the pile 15.
static constexpr float DETONATOR_REACH = 20.0f;

// The plunger is gone this long once the kegs have blown.
static constexpr int32 DETONATOR_RESPAWN_SECS = 30;

// The Detonator (204042) that ends "Finishin' the Job". Pressing it lights an
// Explosive Fuse beside the plunger, which runs to the powder kegs; when it gets there
// the Frostmane Hold Target standing in the pile sets every keg off, and the plunger
// disappears with them. As the kegs go the tunnel mouth caves in: the Collapsing
// Boulders appear for fifteen seconds and are cleared away again.
//
// The boulders have no spawn; the plunger summons them. Summoned from a gameobject
// they have no owner, so nothing but this script takes them away: the timed path in
// GameObject::Update only ever hides an ownerless summon, and a creature-owned one
// walks the respawn branch and stays. Their lifetime is a beat here with Delete at
// the end of it. Summoning from the plunger also puts them in its phase, and the
// template addon gives them their flags (IN_USE | NODESPAWN) and faction on Create.
//
// The goober does the quest credit, the IN_USE flag and the pressed state on its own
// -- GossipHello returns false so that Use carries on into all of that. What it cannot
// do is hold a clock, and the kegs are not this object: a goober with no script only
// ever acts on itself.
//
// The plunger is a goober with neither Data5 nor Data11, so GameObject::LoadFromDB
// marks it NODESPAWN and zeroes its respawn delay -- the loot state alone will never
// take it away. SetRespawnTime with UpdateObjectVisibility does, and the GO_READY
// branch of GameObject::Update brings it back. The loot state has to be put back to
// GO_READY at the same moment: left at GO_ACTIVATED, the twenty-second auto-close
// would fire while it is hidden, walk the GO_JUST_DEACTIVATED branch, and re-arm the
// same respawn on top of the one already running.
struct go_frostmane_hold_detonator : public GameObjectAI
{
    go_frostmane_hold_detonator(GameObject* go) : GameObjectAI(go) { }

    void Reset() override
    {
        _scheduler.CancelAll();
        ClearBoulders();
        _running = false;
    }

    bool GossipHello(Player* /*player*/, bool reportUse) override
    {
        if (reportUse)
            return false;

        // The client will not press a plunger flagged IN_USE, and after the kegs go
        // it is not there to press; this covers the gap between the two.
        if (_running)
            return true;

        _running = true;

        _scheduler.Schedule(Milliseconds(BEAT_PLUNGER_ANIM), [this](TaskContext /*task*/)
        {
            go->SendCustomAnim(0);
        });

        _scheduler.Schedule(Milliseconds(BEAT_FUSE_LIT), [this](TaskContext /*task*/)
        {
            // The trigger lights it, not the plunger. WorldObject::SummonCreature
            // hands Map::SummonCreature ToUnit() as the summoner, so from a
            // gameobject that is null: the summon inherits no phase and its
            // IsSummonedBy never runs. From the trigger, which shares the plunger's
            // phase, it gets both.
            if (Creature* trigger = FindTrigger())
                trigger->SummonCreature(NPC_EXPLOSIVE_FUSE, FuseLitMark, TEMPSUMMON_TIMED_DESPAWN, FUSE_LIFETIME_MS);
        });

        _scheduler.Schedule(Milliseconds(BEAT_KEGS_BLOW), [this](TaskContext /*task*/)
        {
            BlowKegs();
            HidePlunger();
        });

        _scheduler.Schedule(Milliseconds(BEAT_BOULDERS_FALL), [this](TaskContext /*task*/)
        {
            if (GameObject* boulders = go->SummonGameObject(GO_COLLAPSING_BOULDERS, BouldersMark, BouldersRotation, 0))
                _boulders = boulders->GetGUID();
        });

        _scheduler.Schedule(Milliseconds(BEAT_BOULDERS_FALL + BOULDERS_SETTLE_MS), [this](TaskContext /*task*/)
        {
            if (GameObject* boulders = FindBoulders())
                boulders->RemoveFlag(GAMEOBJECT_FLAGS, GO_FLAG_IN_USE);
        });

        _scheduler.Schedule(Milliseconds(BEAT_BOULDERS_FALL + BOULDERS_LIFETIME_MS), [this](TaskContext /*task*/)
        {
            ClearBoulders();
        });

        return false;
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    Creature* FindTrigger() const
    {
        return go->FindNearestCreature(NPC_FROSTMANE_HOLD_TARGET, DETONATOR_REACH);
    }

    void BlowKegs()
    {
        Creature* trigger = FindTrigger();
        if (!trigger)
            return;

        // TRIGGERED_FULL_MASK carries TRIGGERED_CAST_DIRECTLY, so the spell lands
        // inside this call: Spell::prepare casts at once, the gameobject hits are
        // handled in the same pass, and Map::ScriptCommandStart runs a zero-delay
        // ACTIVATE_OBJECT on the spot. By the next line every keg has been Used.
        trigger->CastSpell(trigger, SPELL_TRIGGER_POWDER_KEG_EXPLOSIONS, true);

        // Use put the kegs in GO_STATE_ACTIVE; blown kegs show the other state. The
        // deactivation three seconds on sets GO_STATE_READY itself, right before the
        // despawn, so this holds exactly as long as it should.
        std::list<GameObject*> kegs;
        go->GetGameObjectListWithEntryInGrid(kegs, GO_POWDER_KEG, DETONATOR_REACH);
        for (GameObject* keg : kegs)
            if (keg->getLootState() == GO_ACTIVATED)
                keg->SetGoState(GO_STATE_ACTIVE_ALTERNATIVE);
    }

    void HidePlunger()
    {
        go->RemoveFlag(GAMEOBJECT_FLAGS, GO_FLAG_IN_USE);
        go->SetGoState(GO_STATE_READY);
        go->SetLootState(GO_READY);
        go->SetRespawnTime(DETONATOR_RESPAWN_SECS);
        go->UpdateObjectVisibility();
    }

    GameObject* FindBoulders() const
    {
        if (_boulders.IsEmpty())
            return nullptr;
        return ObjectAccessor::GetGameObject(*go, _boulders);
    }

    void ClearBoulders()
    {
        if (GameObject* boulders = FindBoulders())
            boulders->Delete();
        _boulders.Clear();
    }

    bool _running = false;
    ObjectGuid _boulders;
    TaskScheduler _scheduler;
};

// The Explosive Fuse (42763) the detonator lights. It has no spawn of its own; it
// appears beside the plunger already burning, waits a moment, and runs into the
// middle of the kegs, where the timed despawn takes it two seconds after they blow.
struct npc_explosive_fuse : public PassiveAI
{
    npc_explosive_fuse(Creature* creature) : PassiveAI(creature) { }

    void IsSummonedBy(Unit* /*summoner*/) override
    {
        me->CastSpell(me, SPELL_RED_BANISH_STATE, true);

        _scheduler.Schedule(Milliseconds(FUSE_LIT_TO_RUN), [this](TaskContext /*task*/)
        {
            // Not MovePoint: that runs at the template's speed, and the fuse crawls
            // along the ground rather than runs.
            Movement::MoveSplineInit init(me);
            init.MoveTo(FusePileMark.GetPositionX(), FusePileMark.GetPositionY(), FusePileMark.GetPositionZ());
            init.SetVelocity(FUSE_BURN_SPEED);
            init.Launch();
        });
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    TaskScheduler _scheduler;
};

enum DownWithCrushcog
{
    QUEST_DOWN_WITH_CRUSHCOG            = 26364,

    NPC_HIGH_TINKER_MEKKATORQUE         = 42849,
    NPC_GNOMEREGAN_INFANTRY_CAMP        = 42316,
    NPC_DUN_MOROGH_MOUNTAINEER          = 13076,
    NPC_BURDRAK_HARGLHELM               = 3162,

    SPELL_PURPLE_FIREWORK               = 80070,
    SPELL_COSMETIC_DRINK                = 70620,

    SOUND_JARVI_SIGNAL                  = 23810,

    SAY_JARVI_DEFEATED                  = 0,
    SAY_JARVI_HEROES                    = 1,
    SAY_MEKKATORQUE_NO_MORE             = 9,
    SAY_INFANTRY_THREE_CHEERS           = 0,
    SAY_INFANTRY_VICTORY                = 1,
    SAY_MOUNTAINEER_DRINK               = 0,

    POINT_MEKKATORQUE_CAMP              = 1
};

// Mekkatorque appears already on the move and walks in to stand in front of Jarvi.
// Element 0 is the point he is standing on when the leg goes out, never a destination:
// MoveSplineInit::Launch overwrites it with the mover's real position. The last segment
// leaves him on the bearing he was summoned on, so nothing has to turn him.
Position const MekkatorqueArrival = { -5359.35f, 306.451f, 394.57135f, 3.328238f };
Position const MekkatorqueToCamp[] =
{
    { -5359.3500f, 306.45100f, 394.57135f },
    { -5363.2793f, 305.70898f, 394.32860f },
    { -5364.2617f, 305.52344f, 394.13776f },
    { -5367.2090f, 304.96680f, 393.96814f },
    { -5372.6900f, 303.94400f, 393.85977f }
};

// Jarvi turns this way while Mekkatorque walks in, and back to his spawn facing once
// the speeches are over.
static constexpr float JARVI_FACING_ARRIVAL = 1.815f;

// Everyone standing within this of Jarvi joins in: the seven infantry and six
// mountaineers clustered round the fire, and Burdrak at his stall. The mountaineer
// sitting by the tent and the far infantry along the ridge stay out of it.
static constexpr float CAMP_AUDIENCE_RANGE = 23.0f;

// The crowd does not gesture in one instant. Each member fires somewhere in a
// two-and-a-half-second window, so a wave reads as a ripple rather than a drill.
static constexpr uint32 WAVE_SPREAD_MS = 2400;

static constexpr uint32 MOUNTAINEER_DANCE_MS = 6000;

// Every beat, in milliseconds from the moment the quest is handed in.
static constexpr uint32 BEAT_JARVI_SAY_DEFEATED     = 200;
static constexpr uint32 BEAT_MEKKATORQUE_ARRIVES    = 1400;
static constexpr uint32 BEAT_JARVI_FACES_ARRIVAL    = 3000;
static constexpr uint32 BEAT_JARVI_SIGNAL           = 6700;
static constexpr uint32 BEAT_MEKKATORQUE_SPEAKS     = 9900;
static constexpr uint32 BEAT_FIRST_CHEER            = 12000;
static constexpr uint32 BEAT_MOUNTAINEER_DANCES     = 12400;
static constexpr uint32 BEAT_MEKKATORQUE_TALKS      = 14000;
static constexpr uint32 BEAT_JARVI_SAY_HEROES       = 14400;
static constexpr uint32 BEAT_MOUNTAINEER_DRINKS     = 16800;
static constexpr uint32 BEAT_SECOND_CHEER           = 19200;
static constexpr uint32 BEAT_JARVI_FACES_HOME       = 19200;
static constexpr uint32 BEAT_CELEBRATION_ENDS       = 22500;

// Mekkatorque is gone with the last of the cheering. A timed despawn rather than a
// scheduled one so that a run cut short still takes him away.
static constexpr uint32 MEKKATORQUE_LIFETIME_MS     = BEAT_CELEBRATION_ENDS - BEAT_MEKKATORQUE_ARRIVES;

// What the infantry throw when they cheer. Applause and cheers lead, with the odd shout
// and roar; the weighting is by repetition.
static constexpr Emote INFANTRY_CHEER_EMOTES[] =
{
    EMOTE_ONESHOT_APPLAUD, EMOTE_ONESHOT_APPLAUD,
    EMOTE_ONESHOT_CHEER,   EMOTE_ONESHOT_CHEER,
    EMOTE_ONESHOT_EXCLAMATION,
    EMOTE_ONESHOT_ROAR
};

static constexpr Emote DWARF_CHEER_EMOTES[] =
{
    EMOTE_ONESHOT_APPLAUD,
    EMOTE_ONESHOT_CHEER
};

template<size_t N>
static Emote RollEmote(Emote const (&pool)[N])
{
    return pool[urand(0, N - 1)];
}

// Jarvi Shadowstep, who ends "Down with Crushcog!". Hand the quest in and High Tinker
// Mekkatorque rides into the camp to declare the valley won, and the infantry and
// mountaineers gathered round Jarvi's fire cheer the player by name -- twice, with a
// firework, a dance and a toast between.
//
// Not SmartAI. The cast is a summon walked in by route plus whoever happens to be
// standing near Jarvi, picked at hand-in and gestured at random; a SMART_ACTION can
// address none of that per creature.
//
// The clock is fixed and nothing in it waits on an arrival, so the whole run is
// scheduled up front from the hand-in.
struct npc_jarvi_shadowstep : public ScriptedAI
{
    npc_jarvi_shadowstep(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();
        _mekkatorque.Clear();
        _player.Clear();
        _audience.clear();
        _running = false;
    }

    void sQuestReward(Player* player, Quest const* quest, uint32 /*opt*/) override
    {
        if (quest->GetQuestId() != QUEST_DOWN_WITH_CRUSHCOG)
            return;

        // A second hand-in while the first is still running is ignored rather than
        // queued: one Mekkatorque on the mark at a time, and the crowd is still busy
        // cheering the first player.
        if (_running)
            return;

        StartCelebration(player);
    }

    void UpdateAI(uint32 diff) override
    {
        // No UpdateVictim and no melee. Jarvi is immune to players and creatures alike
        // and never acquires a victim; the scheduler is the whole of what this adds.
        _scheduler.Update(diff);
    }

private:

    void StartCelebration(Player* player)
    {
        _running = true;
        _player = player->GetGUID();
        _mekkatorque.Clear();

        GatherAudience();

        ScheduleJarvi();
        ScheduleMekkatorque();
        ScheduleCrowd();

        Beat(BEAT_CELEBRATION_ENDS, [this] { _running = false; });
    }

    // Who is going to cheer, decided once so that both waves come from the same
    // people. Anyone sitting or mid-stride is left alone -- a gesture from a seated
    // dwarf stands him up, and one from a walking one snaps between animations.
    void GatherAudience()
    {
        _audience.clear();

        std::list<Creature*> crowd;
        me->GetCreatureListWithEntryInGrid(crowd, NPC_GNOMEREGAN_INFANTRY_CAMP, CAMP_AUDIENCE_RANGE);
        me->GetCreatureListWithEntryInGrid(crowd, NPC_DUN_MOROGH_MOUNTAINEER, CAMP_AUDIENCE_RANGE);
        me->GetCreatureListWithEntryInGrid(crowd, NPC_BURDRAK_HARGLHELM, CAMP_AUDIENCE_RANGE);

        for (Creature* member : crowd)
            if (member->IsAlive() && !member->isMoving() && member->GetStandState() == UNIT_STAND_STATE_STAND)
                _audience.push_back(member->GetGUID());
    }

    void ScheduleJarvi()
    {
        Beat(BEAT_JARVI_SAY_DEFEATED,  [this] { Talk(SAY_JARVI_DEFEATED, Celebrant()); });
        Beat(BEAT_JARVI_FACES_ARRIVAL, [this] { me->SetFacingTo(JARVI_FACING_ARRIVAL); });
        Beat(BEAT_JARVI_SIGNAL,        [this] { me->PlayDistanceSound(SOUND_JARVI_SIGNAL); });

        Beat(BEAT_JARVI_SAY_HEROES, [this]
        {
            Talk(SAY_JARVI_HEROES);
            me->CastSpell(me, SPELL_PURPLE_FIREWORK, true);
        });

        Beat(BEAT_JARVI_FACES_HOME, [this] { me->SetFacingTo(me->GetHomePosition().GetOrientation()); });
    }

    void ScheduleMekkatorque()
    {
        Beat(BEAT_MEKKATORQUE_ARRIVES, [this]
        {
            Creature* mekkatorque = me->SummonCreature(NPC_HIGH_TINKER_MEKKATORQUE, MekkatorqueArrival,
                TEMPSUMMON_TIMED_DESPAWN, MEKKATORQUE_LIFETIME_MS);
            if (!mekkatorque)
                return;

            _mekkatorque = mekkatorque->GetGUID();

            // He is here to make a speech, not to be talked to: the gossip the entry
            // carries belongs to the Mekkatorque standing at the front.
            mekkatorque->RemoveFlag64(UNIT_NPC_FLAGS, UNIT_NPC_FLAG_GOSSIP);

            WalkRoute(mekkatorque, POINT_MEKKATORQUE_CAMP, MekkatorqueToCamp,
                std::extent<decltype(MekkatorqueToCamp)>::value);
        });

        Beat(BEAT_MEKKATORQUE_SPEAKS, [this]
        {
            if (Creature* mekkatorque = Mekkatorque())
                mekkatorque->AI()->Talk(SAY_MEKKATORQUE_NO_MORE, Celebrant());
        });

        Beat(BEAT_MEKKATORQUE_TALKS, [this]
        {
            if (Creature* mekkatorque = Mekkatorque())
                mekkatorque->HandleEmoteCommand(EMOTE_ONESHOT_TALK);
        });
    }

    void ScheduleCrowd()
    {
        // Two of the infantry carry the lines, a mountaineer dances and another
        // raises a drink; all of it is drawn at hand-in from whoever is there.
        ObjectGuid threeCheers = PickFromAudience(NPC_GNOMEREGAN_INFANTRY_CAMP, ObjectGuid::Empty);
        ObjectGuid victory     = PickFromAudience(NPC_GNOMEREGAN_INFANTRY_CAMP, threeCheers);
        ObjectGuid dancer      = PickFromAudience(NPC_DUN_MOROGH_MOUNTAINEER, ObjectGuid::Empty);
        ObjectGuid drinker     = PickFromAudience(NPC_DUN_MOROGH_MOUNTAINEER, dancer);

        // The first wave is everyone; the dancer holds his state instead of throwing a
        // gesture over it.
        for (ObjectGuid const& guid : _audience)
        {
            if (guid == dancer)
                continue;

            uint8 line = guid == threeCheers ? SAY_INFANTRY_THREE_CHEERS
                       : guid == victory     ? SAY_INFANTRY_VICTORY
                       : NO_LINE;
            Beat(BEAT_FIRST_CHEER + urand(0, WAVE_SPREAD_MS), [this, guid, line] { Cheer(guid, line); });
        }

        Beat(BEAT_MOUNTAINEER_DANCES, [this, dancer]
        {
            if (Creature* mountaineer = Member(dancer))
                mountaineer->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_DANCE);
        });

        Beat(BEAT_MOUNTAINEER_DANCES + MOUNTAINEER_DANCE_MS, [this, dancer]
        {
            if (Creature* mountaineer = Member(dancer))
                mountaineer->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_NO_EMOTE);
        });

        Beat(BEAT_MOUNTAINEER_DRINKS, [this, drinker]
        {
            if (Creature* mountaineer = Member(drinker))
            {
                mountaineer->CastSpell(mountaineer, SPELL_COSMETIC_DRINK, true);
                mountaineer->AI()->Talk(SAY_MOUNTAINEER_DRINK);
            }
        });

        // The second wave is the infantry alone; the dwarves have gone back to their
        // drinks by then.
        for (ObjectGuid const& guid : _audience)
            if (guid.GetEntry() == NPC_GNOMEREGAN_INFANTRY_CAMP)
                Beat(BEAT_SECOND_CHEER + urand(0, WAVE_SPREAD_MS), [this, guid] { Cheer(guid, NO_LINE); });
    }

    static constexpr uint8 NO_LINE = 0xFF;

    void Cheer(ObjectGuid const& guid, uint8 line)
    {
        Creature* member = Member(guid);
        if (!member)
            return;

        bool infantry = member->GetEntry() == NPC_GNOMEREGAN_INFANTRY_CAMP;
        member->HandleEmoteCommand(infantry ? RollEmote(INFANTRY_CHEER_EMOTES) : RollEmote(DWARF_CHEER_EMOTES));

        if (line != NO_LINE)
            member->AI()->Talk(line, Celebrant());
    }

    // A random member of the audience with this entry, other than the one already
    // spoken for. Empty when there is nobody left to pick.
    ObjectGuid PickFromAudience(uint32 entry, ObjectGuid const& taken) const
    {
        std::vector<ObjectGuid> candidates;
        for (ObjectGuid const& guid : _audience)
            if (guid.GetEntry() == entry && guid != taken)
                candidates.push_back(guid);

        if (candidates.empty())
            return ObjectGuid::Empty;

        return candidates[urand(0, candidates.size() - 1)];
    }

    Creature* Member(ObjectGuid const& guid)
    {
        return guid.IsEmpty() ? nullptr : ObjectAccessor::GetCreature(*me, guid);
    }

    Creature* Mekkatorque()
    {
        return ObjectAccessor::GetCreature(*me, _mekkatorque);
    }

    Player* Celebrant()
    {
        return ObjectAccessor::GetPlayer(*me, _player);
    }

    template<typename Action>
    void Beat(uint32 offsetMs, Action&& action)
    {
        _scheduler.Schedule(Milliseconds(offsetMs), [action](TaskContext /*task*/) { action(); });
    }

    ObjectGuid _mekkatorque;
    ObjectGuid _player;
    std::vector<ObjectGuid> _audience;
    bool _running = false;
    TaskScheduler _scheduler;
};

enum CrushcogAssault
{
    NPC_MOUNTAINEER_STONEGRIND          = 42852,
    NPC_RAZLO_CRUSHCOG_MECH             = 42839,
    NPC_RAZLO_CRUSHCOG_RIDER            = 42494,
    NPC_CRUSHCOGS_GUARDIAN              = 42294,
    NPC_CRUSHCOG_DEFEATED_CREDIT        = 42860,
    NPC_CRUSHCOG_TECHNICIAN             = 43230,

    MENU_MEKKATORQUE_ASSAULT            = 11662,

    MUSIC_ASSAULT_BRIEFING              = 23952,
    MUSIC_ASSAULT_BATTLE                = 23798,

    // What the two of them fight with. The Bomb is the one cast with a bar on it.
    SPELL_SUPER_SHRINK_RAY              = 22742,
    SPELL_BOMB                          = 9143,
    SPELL_GOBLIN_DRAGON_GUN             = 22739,
    SPELL_STONEGRIND_SHOOT              = 80173,
    SPELL_MACHINE_GUN                   = 74438,

    // The idle pose the guardians hold until they are called up.
    SPELL_GUARDIAN_FREEZE_ANIM          = 16245,

    // The technicians' idle "at work" pose. A self-buff dummy aura with no set
    // duration, but the client channel bar it rides on runs out in a hair over
    // ten seconds, so it is recast on a loop rather than applied once.
    SPELL_TECHNICIAN_AT_WORK            = 78858,

    SAY_MEKKATORQUE_THERMAPLUGG         = 0,
    SAY_MEKKATORQUE_THWARTED            = 1,
    SAY_MEKKATORQUE_SEND_HIM            = 2,
    SAY_MEKKATORQUE_VICTORIOUS          = 3,
    SAY_MEKKATORQUE_YOURE_NEXT          = 4,
    SAY_STONEGRIND_AYE                  = 0,
    SAY_STONEGRIND_TEACH                = 1,
    SAY_CRUSHCOG_ESCAPE                 = 0,
    SAY_CRUSHCOG_GUARDIANS              = 1,
    SAY_CRUSHCOG_TRUE_SONS              = 2,

    POINT_MEKKATORQUE_MARK              = 2,
    POINT_MEKKATORQUE_RETURN            = 3,
    POINT_STONEGRIND_MARK               = 4,
    POINT_STONEGRIND_RETURN             = 5,
    POINT_GUARDIAN_GATHER               = 6,
    POINT_MEKKATORQUE_GUN_MARK          = 7,

    ACTION_WAKE                         = 1,
    ACTION_JOIN_FIGHT                   = 2,
    ACTION_STAND_DOWN                   = 3,
    ACTION_TECHNICIAN_JUMP_IN           = 4
};

// The two of them ride out of Mekkatorque's camp, through the stream and up the far
// bank to the edge of Crushcog's ground. Element 0 of each route is the point the
// rider is standing on when the leg goes out, never a destination: MoveSplineInit::Launch
// overwrites it with the mover's real position. Both cross at 3.74 yd/s -- neither the
// entry's walk nor its run -- so the walk rate is raised for the crossing and put back
// on arrival.
static constexpr float ASSAULT_CROSSING_SPEED   = 3.74f;
static constexpr float ASSAULT_BASE_WALK_SPEED  = 2.5f;

// ...and run back to the marks at the evade rate once the fight is over.
static constexpr float ASSAULT_RETURN_RATE      = 1.25f;

Position const MekkatorqueCrossing[] =
{
    { -5313.4930f, 148.3941f, 389.5100f },
    { -5303.0312f, 140.4922f, 389.3614f },
    { -5300.7812f, 138.7422f, 388.6114f },
    { -5299.2812f, 137.4922f, 387.8614f },
    { -5297.7812f, 136.2422f, 386.6114f },
    { -5295.1190f, 134.0730f, 386.1639f },
    { -5292.5693f, 132.0903f, 386.2130f },
    { -5290.8613f, 131.0508f, 387.1309f },
    { -5287.4473f, 128.9727f, 388.7411f },
    { -5285.7400f, 127.9336f, 389.1132f },
    { -5284.3760f, 127.1032f, 389.5718f },
    { -5283.0490f, 126.3016f, 390.4158f },
    { -5281.2990f, 125.3016f, 390.9158f },
    { -5279.2990f, 124.5516f, 391.4158f },
    { -5277.2990f, 123.8016f, 391.6658f },
    { -5275.2990f, 123.3016f, 392.1658f },
    { -5273.5490f, 123.0516f, 392.6658f },
    { -5271.7990f, 122.5516f, 393.1658f },
    { -5269.7990f, 122.0516f, 393.1658f },
    { -5268.0490f, 121.5516f, 393.6658f },
    { -5266.0490f, 121.0516f, 393.9158f },
    { -5261.7220f, 119.5000f, 393.7598f }
};

Position const StonegrindCrossing[] =
{
    { -5311.1216f, 150.9410f, 390.0118f },
    { -5303.5435f, 145.8733f, 389.8128f },
    { -5301.0435f, 144.1233f, 389.5628f },
    { -5299.5435f, 143.1233f, 389.0628f },
    { -5297.2935f, 141.3733f, 387.5628f },
    { -5295.5435f, 140.3733f, 386.5628f },
    { -5291.9740f, 137.5675f, 386.1139f },
    { -5289.1865f, 135.7056f, 386.6199f },
    { -5287.4365f, 134.7056f, 387.3699f },
    { -5284.9365f, 133.4556f, 388.6199f },
    { -5282.4365f, 132.2056f, 389.3699f },
    { -5281.0024f, 131.0717f, 389.9424f },
    { -5279.6780f, 130.3735f, 390.9056f },
    { -5277.9280f, 129.3735f, 391.6556f },
    { -5276.6780f, 129.1235f, 391.9056f },
    { -5273.9280f, 128.1235f, 392.1556f },
    { -5271.9280f, 127.6235f, 392.6556f },
    { -5270.1780f, 127.3735f, 393.1556f },
    { -5267.4280f, 126.3735f, 393.6556f },
    { -5265.4280f, 125.8735f, 393.9056f },
    { -5261.6780f, 124.8735f, 394.1556f },
    { -5260.3540f, 124.1753f, 393.8688f }
};

// Where they stand to be challenged, and come back to when it is done. Mekkatorque
// squares up to Crushcog on arrival; Stonegrind turns when the fight begins and again
// when he is back.
Position const MekkatorqueAssaultMark = { -5261.7220f, 119.5000f, 393.7598f, 6.161012f };
Position const StonegrindAssaultMark  = { -5260.3540f, 124.1753f, 393.8688f, 6.005911f };
static constexpr float STONEGRIND_FIGHT_FACING = 6.256126f;

// Mekkatorque fires the Dragon Gun from beside the mech, facing straight into it, and
// drops the Bomb on the ground east of it first. The bomb has a minimum range, so its
// mark sits past the last guardian's spot rather than on it.
Position const MekkatorqueGunMark = { -5243.2540f, 121.1524f, 394.2717f, 3.497797f };
Position const MekkatorqueBombMark = { -5236.891f, 122.482f, 394.0f };
static constexpr float MEKKATORQUE_BOMB_FACING = 0.206092f;

Position const MekkatorqueReturn[] =
{
    { -5243.2540f, 121.1524f, 394.2717f },
    { -5252.2383f, 120.3262f, 394.2658f },
    { -5253.9883f, 120.3262f, 394.0158f },
    { -5258.9883f, 120.0762f, 394.0158f },
    { -5261.7220f, 119.5000f, 393.7598f }
};

Position const StonegrindReturn[] =
{
    { -5243.5396f, 121.0580f, 394.2835f },
    { -5250.4470f, 122.6167f, 394.3262f },
    { -5251.4470f, 122.6167f, 394.0762f },
    { -5260.3540f, 124.1753f, 393.8688f }
};

// The four guardians close in round the mech before the fight. Each is matched to the
// point nearest its own spawn.
Position const GuardianGatherPoints[] =
{
    { -5255.2700f, 111.5330f, 393.1738f },
    { -5252.9746f, 128.3291f, 394.1011f },
    { -5253.5527f, 115.9414f, 393.8345f },
    { -5252.0610f, 123.9509f, 393.7387f }
};
static constexpr size_t GUARDIAN_COUNT = std::extent<decltype(GuardianGatherPoints)>::value;
static constexpr float GUARDIAN_SEARCH_RANGE = 40.0f;
static constexpr float CREDIT_RANGE = 40.0f;

// Each technician stands 9-13 yd from its own guardian and better than 13 yd from
// any other, so nearest-creature-in-range never picks the wrong one.
static constexpr float TECHNICIAN_JUMP_RANGE = 20.0f;

// Every beat, in milliseconds from the moment the player tells Mekkatorque to start.
static constexpr uint32 BEAT_ASSAULT_MUSIC              = 177;
static constexpr uint32 BEAT_MEKKATORQUE_SAY_THERMAPLUGG = 1295;
static constexpr uint32 BEAT_MEKKATORQUE_TALKS_1        = 7364;
static constexpr uint32 BEAT_MEKKATORQUE_SAY_THWARTED   = 13388;
static constexpr uint32 BEAT_MEKKATORQUE_TALKS_2        = 19142;
static constexpr uint32 BEAT_MEKKATORQUE_SAY_SEND_HIM   = 24388;
static constexpr uint32 BEAT_STONEGRIND_SAY_AYE         = 29246;
static constexpr uint32 BEAT_MEKKATORQUE_SETS_OFF       = 30456;
static constexpr uint32 BEAT_BATTLE_MUSIC               = 47462;
static constexpr uint32 BEAT_CRUSHCOG_SAY_ESCAPE        = 49086;
static constexpr uint32 BEAT_CRUSHCOG_SAY_GUARDIANS     = 55096;
// The technician beside each guardian jumps up onto it a couple of seconds before
// the guardian itself drops its freeze pose -- the jump is what wakes it.
static constexpr uint32 BEAT_TECHNICIANS_JUMP_IN        = 59845;
static constexpr uint32 BEAT_GUARDIANS_WAKE             = 62045;
static constexpr uint32 BEAT_GUARDIANS_GATHER           = 63269;
static constexpr uint32 BEAT_GUARDIANS_SELECTABLE       = 66931;
static constexpr uint32 BEAT_FIGHT_STARTS               = 70958;
static constexpr uint32 BEAT_MECH_ENGAGES               = 77036;
static constexpr uint32 BEAT_MEKKATORQUE_BOMB           = 79459;
static constexpr uint32 BEAT_MEKKATORQUE_DRAGON_GUN     = 81871;
static constexpr uint32 BEAT_MECH_DIES                  = 82898;
static constexpr uint32 BEAT_STONEGRIND_RETURNS         = 83495;
static constexpr uint32 BEAT_STONEGRIND_SAY_TEACH       = 86726;
static constexpr uint32 BEAT_MEKKATORQUE_RETURNS        = 90308;
static constexpr uint32 BEAT_MEKKATORQUE_SAY_VICTORIOUS = 92808;
static constexpr uint32 BEAT_STONEGRIND_LEAVES          = 97601;
static constexpr uint32 BEAT_CRUSHCOG_CREDIT            = 98870;
static constexpr uint32 BEAT_MEKKATORQUE_TALKS_3        = 103728;
static constexpr uint32 BEAT_MEKKATORQUE_LEAVES         = 109819;

// The guardians wake and set off one after another, not as one.
static constexpr uint32 GUARDIAN_STAGGER_MS             = 410;

// The jump onto the guardian takes a little over a second; the technician is
// destroyed (it has become the guardian's pilot) shortly after it lands.
static constexpr float TECHNICIAN_JUMP_SPEED_XY         = 8.0f;
static constexpr float TECHNICIAN_JUMP_SPEED_Z          = 8.0f;
static constexpr uint32 TECHNICIAN_JUMP_LANDING_MS      = 1600;

// How often the technician recasts its "at work" channel while it waits.
static constexpr uint32 TECHNICIAN_WORK_INTERVAL_MS     = 10900;

// Everyone is back about thirty seconds after Mekkatorque goes; the others left
// earlier, so they wait longer. The guardians come back on their own clock, thirty
// seconds after their bodies are cleared.
static constexpr Seconds MEKKATORQUE_RESPAWN            = Seconds(30);
static constexpr Seconds STONEGRIND_RESPAWN             = Seconds(42);
static constexpr Seconds MECH_RESPAWN                   = Seconds(53);
static constexpr Seconds GUARDIAN_RESPAWN               = Seconds(30);
static constexpr uint32 MECH_CORPSE_MS                  = 3800;
static constexpr uint32 GUARDIAN_CORPSE_MS              = 2500;

// Crushcog is thrown clear when the mech dies, lands, and is dead a moment later.
static constexpr uint32 RIDER_DEATH_MS                  = 1400;

// Neither of the two can be killed, and nor can the mech before its scripted death --
// real damage from a guardian's swing, a bystander, or the player themselves during
// the ~6 s it is unfrozen must not finish it before the Dragon Gun does.
static void ClampToSurvive(Creature* creature, uint32& damage)
{
    if (damage >= creature->GetHealth())
        damage = creature->GetHealth() - 1;
}

// A guardian that is still in the fight, nearest to the caller. Ones that have
// already respawned stand immune and are not it.
static Creature* NearestFightingGuardian(Creature* from)
{
    std::list<Creature*> guardians;
    from->GetCreatureListWithEntryInGrid(guardians, NPC_CRUSHCOGS_GUARDIAN, GUARDIAN_SEARCH_RANGE);

    Creature* nearest = nullptr;
    for (Creature* guardian : guardians)
    {
        if (!guardian->IsAlive() || guardian->HasFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_NPC))
            continue;
        if (!nearest || from->GetDistance(guardian) < from->GetDistance(nearest))
            nearest = guardian;
    }
    return nearest;
}

// Melee for a creature that is in a scripted fight: hit whoever it has, pick the next
// guardian when that one drops, and never evade -- leaving is the owner's decision.
static void FightGuardians(Creature* fighter)
{
    if (!fighter->GetVictim())
    {
        Creature* next = NearestFightingGuardian(fighter);
        if (!next)
            return;
        fighter->AI()->AttackStart(next);
    }
    fighter->AI()->DoMeleeAttackIfReady();
}

// High Tinker Mekkatorque, standing at the front of his camp on the near side of the
// stream. Tell him you are ready and he explains the assault, rides across with
// Mountaineer Stonegrind to the edge of Crushcog's ground, is challenged, and fights:
// the four guardians are called up, the mech opens fire, Mekkatorque shrinks it, bombs
// the ground and burns it down with the Dragon Gun. Crushcog is thrown from the wreck,
// both ride back, the player is credited, and everyone leaves to reset half a minute
// later.
//
// Not SmartAI. Six creatures act, four of them routed by written-out node lists, a
// vehicle dies on cue with its rider handled separately, and the credit goes to every
// player in range rather than the one who spoke; a SMART_ACTION reaches none of that.
//
// The clock is fixed from the gossip choice. The one thing in it that is not is the
// fight itself, which is real: the guardians and the mech lose their immunities and
// are killed by whoever kills them. The beats that end the fight are backstopped, so a
// guardian nobody reached or a mech nobody finished still dies on time.
struct npc_high_tinker_mekkatorque_assault : public ScriptedAI
{
    npc_high_tinker_mekkatorque_assault(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();
        _running = false;
        _fighting = false;
        _player.Clear();
        _stonegrind.Clear();
        _mech.Clear();
        _guardians.clear();

        // He does not pick fights with the sentry-bots that wander past his camp.
        me->SetReactState(REACT_PASSIVE);
        me->SetWalk(false);
        RestoreSpeeds(me);
    }

    void sGossipSelect(Player* player, uint32 menuId, uint32 /*gossipListId*/) override
    {
        if (menuId != MENU_MEKKATORQUE_ASSAULT)
            return;

        CloseGossipMenuFor(player);

        // A second player asking while the first run is under way is ignored rather than
        // queued. They keep the talk-to credit they were just given and, if they follow
        // along, the kill credit too.
        if (_running)
            return;

        StartAssault(player);
    }

    void DamageTaken(Unit* /*attacker*/, uint32& damage) override
    {
        ClampToSurvive(me, damage);
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != EFFECT_MOTION_TYPE)
            return;

        if (id == POINT_MEKKATORQUE_MARK || id == POINT_MEKKATORQUE_RETURN)
        {
            RestoreSpeeds(me);
            me->SetFacingTo(MekkatorqueAssaultMark.GetOrientation());
        }
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);

        if (_fighting)
            FightGuardians(me);
    }

private:

    void StartAssault(Player* player)
    {
        Creature* stonegrind = me->FindNearestCreature(NPC_MOUNTAINEER_STONEGRIND, GUARDIAN_SEARCH_RANGE);
        Creature* mech = me->FindNearestCreature(NPC_RAZLO_CRUSHCOG_MECH, 100.0f);
        if (!stonegrind || !mech)
        {
            // Nothing logs a missing spawn, so this does. Without either of them the
            // run has nobody to fight or nobody to fight with.
            TC_LOG_ERROR("scripts.ai", "npc_high_tinker_mekkatorque_assault: %s%s missing, the assault cannot start",
                stonegrind ? "" : "Mountaineer Stonegrind ", mech ? "" : "Razlo Crushcog's mech ");
            return;
        }

        _running = true;
        _player = player->GetGUID();
        _stonegrind = stonegrind->GetGUID();
        _mech = mech->GetGUID();
        GatherGuardians(mech);

        ScheduleBriefing();
        ScheduleCrossing();
        ScheduleChallenge();
        ScheduleFight();
        ScheduleVictory();
    }

    // The four guardians, each paired with the gathering point nearest its spawn.
    void GatherGuardians(Creature* mech)
    {
        _guardians.clear();

        std::list<Creature*> guardians;
        mech->GetCreatureListWithEntryInGrid(guardians, NPC_CRUSHCOGS_GUARDIAN, GUARDIAN_SEARCH_RANGE);

        for (Creature* guardian : guardians)
        {
            if (!guardian->IsAlive())
                continue;

            Position home = guardian->GetHomePosition();
            size_t best = 0;
            for (size_t i = 1; i < GUARDIAN_COUNT; ++i)
                if (home.GetExactDist2d(&GuardianGatherPoints[i]) < home.GetExactDist2d(&GuardianGatherPoints[best]))
                    best = i;

            _guardians.push_back({ guardian->GetGUID(), best });
        }

        if (_guardians.size() != GUARDIAN_COUNT)
            TC_LOG_ERROR("scripts.ai", "npc_high_tinker_mekkatorque_assault: %u of %u guardians found round the mech",
                uint32(_guardians.size()), uint32(GUARDIAN_COUNT));
    }

    void ScheduleBriefing()
    {
        Beat(BEAT_ASSAULT_MUSIC,               [this] { me->PlayDirectMusic(MUSIC_ASSAULT_BRIEFING); });
        Beat(BEAT_MEKKATORQUE_SAY_THERMAPLUGG, [this] { Talk(SAY_MEKKATORQUE_THERMAPLUGG, Leader()); });
        Beat(BEAT_MEKKATORQUE_TALKS_1,         [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_TALK); });
        Beat(BEAT_MEKKATORQUE_SAY_THWARTED,    [this] { Talk(SAY_MEKKATORQUE_THWARTED, Leader()); });
        Beat(BEAT_MEKKATORQUE_TALKS_2,         [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_TALK); });
        Beat(BEAT_MEKKATORQUE_SAY_SEND_HIM,    [this] { Talk(SAY_MEKKATORQUE_SEND_HIM, Leader()); });
    }

    void ScheduleCrossing()
    {
        Beat(BEAT_STONEGRIND_SAY_AYE, [this]
        {
            Creature* stonegrind = Stonegrind();
            if (!stonegrind)
                return;

            stonegrind->AI()->Talk(SAY_STONEGRIND_AYE);
            Cross(stonegrind, POINT_STONEGRIND_MARK, StonegrindCrossing, std::extent<decltype(StonegrindCrossing)>::value);
        });

        Beat(BEAT_MEKKATORQUE_SETS_OFF, [this]
        {
            Cross(me, POINT_MEKKATORQUE_MARK, MekkatorqueCrossing, std::extent<decltype(MekkatorqueCrossing)>::value);
        });

        Beat(BEAT_BATTLE_MUSIC, [this] { me->PlayDirectMusic(MUSIC_ASSAULT_BATTLE); });
    }

    void ScheduleChallenge()
    {
        Beat(BEAT_CRUSHCOG_SAY_ESCAPE, [this]
        {
            if (Creature* mech = Mech())
                mech->AI()->Talk(SAY_CRUSHCOG_ESCAPE, Leader());
        });

        Beat(BEAT_CRUSHCOG_SAY_GUARDIANS, [this]
        {
            if (Creature* mech = Mech())
                mech->AI()->Talk(SAY_CRUSHCOG_GUARDIANS);
        });

        for (size_t i = 0; i < _guardians.size(); ++i)
        {
            uint32 stagger = uint32(i) * GUARDIAN_STAGGER_MS;

            Beat(BEAT_TECHNICIANS_JUMP_IN + stagger, [this, i]
            {
                // The technician finds its own guardian rather than the other way
                // round: each one stands close enough to its own that nothing else
                // in range is nearer.
                if (Creature* guardian = Guardian(i))
                    if (Creature* technician = guardian->FindNearestCreature(NPC_CRUSHCOG_TECHNICIAN, TECHNICIAN_JUMP_RANGE))
                        technician->AI()->DoAction(ACTION_TECHNICIAN_JUMP_IN);
            });

            Beat(BEAT_GUARDIANS_WAKE + stagger, [this, i]
            {
                if (Creature* guardian = Guardian(i))
                    guardian->AI()->DoAction(ACTION_WAKE);
            });

            Beat(BEAT_GUARDIANS_GATHER + stagger, [this, i]
            {
                if (Creature* guardian = Guardian(i))
                    guardian->GetMotionMaster()->MovePoint(POINT_GUARDIAN_GATHER, GuardianGatherPoints[_guardians[i].point]);
            });

            Beat(BEAT_GUARDIANS_SELECTABLE + stagger, [this, i]
            {
                if (Creature* guardian = Guardian(i))
                    guardian->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE);
            });
        }
    }

    void ScheduleFight()
    {
        Beat(BEAT_FIGHT_STARTS, [this]
        {
            Creature* mech = Mech();
            Creature* stonegrind = Stonegrind();
            if (mech)
                mech->AI()->Talk(SAY_CRUSHCOG_TRUE_SONS);

            _fighting = true;
            me->SetWalk(false);

            if (stonegrind)
            {
                stonegrind->SetWalk(false);
                stonegrind->SetFacingTo(STONEGRIND_FIGHT_FACING);
                stonegrind->AI()->DoAction(ACTION_JOIN_FIGHT);
            }

            // The guardians nearer Mekkatorque go for him, the rest for Stonegrind.
            // Stonegrind opens on the farther of his: the shot has a minimum range
            // that the near one can sit inside.
            Creature* shot = nullptr;
            for (GuardianSlot const& slot : _guardians)
            {
                Creature* guardian = ObjectAccessor::GetCreature(*me, slot.guid);
                if (!guardian || !guardian->IsAlive())
                    continue;

                guardian->AI()->DoAction(ACTION_JOIN_FIGHT);

                Creature* target = me;
                if (stonegrind && guardian->GetDistance(stonegrind) < guardian->GetDistance(me))
                    target = stonegrind;
                guardian->AI()->AttackStart(target);

                if (target == stonegrind)
                {
                    if (!shot || stonegrind->GetDistance(guardian) > stonegrind->GetDistance(shot))
                        shot = guardian;
                }
                else if (!me->GetVictim())
                    AttackStart(guardian);
            }

            if (stonegrind && shot)
            {
                stonegrind->CastSpell(shot, SPELL_STONEGRIND_SHOOT);
                stonegrind->AI()->AttackStart(shot);
            }
        });

        Beat(BEAT_MECH_ENGAGES, [this]
        {
            // Mekkatorque breaks off from the guardians and takes up his firing position;
            // the mech drops its guard and turns its gun on him.
            _fighting = false;
            me->AttackStop();
            me->GetMotionMaster()->Clear(false);
            me->GetMotionMaster()->MovePoint(POINT_MEKKATORQUE_GUN_MARK, MekkatorqueGunMark);

            if (Creature* mech = Mech())
            {
                mech->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC);
                mech->SetFacingToObject(me);
                mech->CastSpell(me, SPELL_MACHINE_GUN);
                me->CastSpell(mech, SPELL_SUPER_SHRINK_RAY);
            }
        });

        Beat(BEAT_MEKKATORQUE_BOMB, [this]
        {
            me->StopMoving();
            me->SetFacingTo(MEKKATORQUE_BOMB_FACING);
            me->CastSpell(MekkatorqueBombMark, SPELL_BOMB, false);
        });

        Beat(BEAT_MEKKATORQUE_DRAGON_GUN, [this]
        {
            me->SetFacingTo(MekkatorqueGunMark.GetOrientation());
            me->CastSpell(me, SPELL_GOBLIN_DRAGON_GUN);
        });

        Beat(BEAT_MECH_DIES, [this]
        {
            // The first burst of the Dragon Gun is what finishes the mech. Any guardian
            // still on its feet goes with it, so nothing is left swinging at the marks.
            if (Creature* mech = Mech())
                if (mech->IsAlive())
                    me->Kill(mech);

            for (GuardianSlot const& slot : _guardians)
                if (Creature* guardian = ObjectAccessor::GetCreature(*me, slot.guid))
                    if (guardian->IsAlive() && !guardian->HasFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_IMMUNE_TO_NPC))
                        me->Kill(guardian);
        });
    }

    void ScheduleVictory()
    {
        Beat(BEAT_STONEGRIND_RETURNS, [this]
        {
            if (Creature* stonegrind = Stonegrind())
            {
                stonegrind->AI()->DoAction(ACTION_STAND_DOWN);
                Return(stonegrind, POINT_STONEGRIND_RETURN, StonegrindReturn, std::extent<decltype(StonegrindReturn)>::value);
            }
        });

        Beat(BEAT_STONEGRIND_SAY_TEACH, [this]
        {
            if (Creature* stonegrind = Stonegrind())
                stonegrind->AI()->Talk(SAY_STONEGRIND_TEACH);
        });

        Beat(BEAT_MEKKATORQUE_RETURNS, [this]
        {
            me->InterruptNonMeleeSpells(false);
            me->CombatStop(true);
            Return(me, POINT_MEKKATORQUE_RETURN, MekkatorqueReturn, std::extent<decltype(MekkatorqueReturn)>::value);
        });

        Beat(BEAT_MEKKATORQUE_SAY_VICTORIOUS, [this] { Talk(SAY_MEKKATORQUE_VICTORIOUS); });

        Beat(BEAT_STONEGRIND_LEAVES, [this]
        {
            if (Creature* stonegrind = Stonegrind())
                stonegrind->DespawnOrUnsummon(Milliseconds(1), STONEGRIND_RESPAWN);
        });

        Beat(BEAT_CRUSHCOG_CREDIT, [this]
        {
            CreditPlayers();
            Talk(SAY_MEKKATORQUE_YOURE_NEXT, Leader());
        });

        Beat(BEAT_MEKKATORQUE_TALKS_3, [this] { me->HandleEmoteCommand(EMOTE_ONESHOT_TALK); });

        Beat(BEAT_MEKKATORQUE_LEAVES, [this]
        {
            _running = false;
            me->DespawnOrUnsummon(Milliseconds(1), MEKKATORQUE_RESPAWN);
        });
    }

    // Everyone in range with the quest open is credited, not only the one who asked.
    void CreditPlayers()
    {
        std::list<Player*> players;
        me->GetPlayerListInGrid(players, CREDIT_RANGE);
        for (Player* player : players)
            if (player->GetQuestStatus(QUEST_DOWN_WITH_CRUSHCOG) == QUEST_STATUS_INCOMPLETE)
                player->KilledMonsterCredit(NPC_CRUSHCOG_DEFEATED_CREDIT);
    }

    static void Cross(Creature* rider, uint32 pointId, Position const* route, size_t count)
    {
        rider->SetSpeedRate(MOVE_WALK, ASSAULT_CROSSING_SPEED / ASSAULT_BASE_WALK_SPEED);
        WalkRoute(rider, pointId, route, count);
    }

    static void Return(Creature* rider, uint32 pointId, Position const* route, size_t count)
    {
        rider->GetMotionMaster()->Clear(false);
        rider->SetWalk(false);
        rider->SetSpeedRate(MOVE_RUN, rider->GetCreatureTemplate()->speed_run * ASSAULT_RETURN_RATE);
        rider->GetMotionMaster()->MoveSmoothPath(pointId, route, count, false);
    }

    static void RestoreSpeeds(Creature* rider)
    {
        rider->SetSpeedRate(MOVE_WALK, rider->GetCreatureTemplate()->speed_walk);
        rider->SetSpeedRate(MOVE_RUN, rider->GetCreatureTemplate()->speed_run);
    }

    struct GuardianSlot
    {
        ObjectGuid guid;
        size_t point;
    };

    Creature* Guardian(size_t i)
    {
        if (i >= _guardians.size())
            return nullptr;
        Creature* guardian = ObjectAccessor::GetCreature(*me, _guardians[i].guid);
        return guardian && guardian->IsAlive() ? guardian : nullptr;
    }

    Creature* Stonegrind() { return ObjectAccessor::GetCreature(*me, _stonegrind); }
    Creature* Mech() { return ObjectAccessor::GetCreature(*me, _mech); }
    Player* Leader() { return ObjectAccessor::GetPlayer(*me, _player); }

    template<typename Action>
    void Beat(uint32 offsetMs, Action&& action)
    {
        _scheduler.Schedule(Milliseconds(offsetMs), [action](TaskContext /*task*/) { action(); });
    }

    ObjectGuid _player;
    ObjectGuid _stonegrind;
    ObjectGuid _mech;
    std::vector<GuardianSlot> _guardians;
    bool _running = false;
    bool _fighting = false;
    TaskScheduler _scheduler;
};

// Mountaineer Stonegrind, who rides beside Mekkatorque. Everything he does is called
// from the High Tinker's clock; this is what has to live on his own hooks -- the melee,
// the speed put back when a leg ends, and the two facings.
struct npc_mountaineer_stonegrind : public ScriptedAI
{
    npc_mountaineer_stonegrind(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _fighting = false;
        me->SetReactState(REACT_PASSIVE);
        me->SetWalk(false);
        me->SetSpeedRate(MOVE_WALK, me->GetCreatureTemplate()->speed_walk);
        me->SetSpeedRate(MOVE_RUN, me->GetCreatureTemplate()->speed_run);
    }

    void DoAction(int32 action) override
    {
        if (action == ACTION_JOIN_FIGHT)
            _fighting = true;
        else if (action == ACTION_STAND_DOWN)
        {
            _fighting = false;
            me->CombatStop(true);
        }
    }

    void DamageTaken(Unit* /*attacker*/, uint32& damage) override
    {
        ClampToSurvive(me, damage);
    }

    void MovementInform(uint32 type, uint32 id) override
    {
        if (type != EFFECT_MOTION_TYPE)
            return;

        if (id == POINT_STONEGRIND_MARK)
            me->SetSpeedRate(MOVE_WALK, me->GetCreatureTemplate()->speed_walk);
        else if (id == POINT_STONEGRIND_RETURN)
        {
            me->SetSpeedRate(MOVE_RUN, me->GetCreatureTemplate()->speed_run);
            me->SetFacingTo(StonegrindAssaultMark.GetOrientation());
        }
    }

    void UpdateAI(uint32 /*diff*/) override
    {
        if (_fighting)
            FightGuardians(me);
    }

private:
    bool _fighting = false;
};

// The mech Crushcog rides. It never moves and never chases: it is spoken through,
// fires its gun on Mekkatorque's cue, and dies when the Dragon Gun reaches it, which
// is why the rider is handled here and not on the High Tinker's clock. Real damage is
// clamped the same as Mekkatorque and Stonegrind's -- once it loses its immunity for
// the ~6 s before that, a guardian's stray swing or the player's own hits must not
// finish it ahead of the scripted kill. Crushcog is thrown clear as it dies, lands,
// and is dead a second and a half later; the wreck is cleared shortly after.
struct npc_razlo_crushcog_mech : public ScriptedAI
{
    npc_razlo_crushcog_mech(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();
        me->SetReactState(REACT_PASSIVE);
    }

    void PassengerBoarded(Unit* passenger, int8 /*seatId*/, bool apply) override
    {
        if (apply && passenger->GetEntry() == NPC_RAZLO_CRUSHCOG_RIDER)
            _rider = passenger->GetGUID();
    }

    void DamageTaken(Unit* /*attacker*/, uint32& damage) override
    {
        ClampToSurvive(me, damage);
    }

    void JustDied(Unit* /*killer*/) override
    {
        // The rider is already off: the control aura goes with the mech's death and
        // Unit::_ExitVehicle throws him. He is not a minion of the seat, so he lands
        // alive and is killed from here.
        _scheduler.Schedule(Milliseconds(RIDER_DEATH_MS), [this](TaskContext /*task*/)
        {
            if (Creature* rider = ObjectAccessor::GetCreature(*me, _rider))
                if (rider->IsAlive())
                    rider->KillSelf();
        });

        me->DespawnOrUnsummon(Milliseconds(MECH_CORPSE_MS), MECH_RESPAWN);
    }

    void EnterEvadeMode(EvadeReason /*why*/) override { }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    ObjectGuid _rider;
    TaskScheduler _scheduler;
};

// Crushcog's Guardians, the four that stand frozen round the mech. They are woken,
// walked in and sent at the riders from Mekkatorque's clock; what is theirs is the
// fight itself and what happens to the body. A dead guardian is cleared quickly and
// is back, frozen and immune again, half a minute later, whether or not the rest of
// the scene is still going.
struct npc_crushcogs_guardian : public ScriptedAI
{
    npc_crushcogs_guardian(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        me->SetReactState(REACT_PASSIVE);
    }

    void DoAction(int32 action) override
    {
        switch (action)
        {
            case ACTION_WAKE:
                me->RemoveAurasDueToSpell(SPELL_GUARDIAN_FREEZE_ANIM);
                break;
            case ACTION_JOIN_FIGHT:
                me->RemoveFlag(UNIT_FIELD_FLAGS, UNIT_FLAG_NOT_SELECTABLE | UNIT_FLAG_IMMUNE_TO_PC | UNIT_FLAG_IMMUNE_TO_NPC);
                me->SetReactState(REACT_AGGRESSIVE);
                break;
            default:
                break;
        }
    }

    void JustDied(Unit* /*killer*/) override
    {
        me->DespawnOrUnsummon(Milliseconds(GUARDIAN_CORPSE_MS), GUARDIAN_RESPAWN);
    }

    void UpdateAI(uint32 /*diff*/) override
    {
        if (!UpdateVictim())
            return;

        DoMeleeAttackIfReady();
    }
};

// Crushcog's Technicians, spawned in pairs beside two of the guardians. They stand
// there recasting the "at work" channel on a loop -- it is not a lasting buff, it
// just runs out in a hair over ten seconds -- until the assault calls them up. Each
// then jumps onto its own guardian and is destroyed: on retail it visibly becomes the
// pilot that turns the frozen suit into a fighter, which is why the guardian's own
// wake beat follows a couple of seconds behind rather than firing on its own.
struct npc_crushcog_technician : public ScriptedAI
{
    npc_crushcog_technician(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();
        me->SetReactState(REACT_PASSIVE);
        ScheduleWork();
    }

    void DoAction(int32 action) override
    {
        if (action != ACTION_TECHNICIAN_JUMP_IN)
            return;

        _scheduler.CancelAll();
        me->InterruptNonMeleeSpells(false);

        if (Creature* guardian = me->FindNearestCreature(NPC_CRUSHCOGS_GUARDIAN, TECHNICIAN_JUMP_RANGE))
            me->GetMotionMaster()->MoveJump(guardian->GetHomePosition(), TECHNICIAN_JUMP_SPEED_XY, TECHNICIAN_JUMP_SPEED_Z);

        // The DB respawn timer brings it back once the encounter itself resets.
        me->DespawnOrUnsummon(Milliseconds(TECHNICIAN_JUMP_LANDING_MS));
    }

    void UpdateAI(uint32 diff) override
    {
        _scheduler.Update(diff);
    }

private:
    void ScheduleWork()
    {
        _scheduler.Schedule(Milliseconds(1), [this](TaskContext task)
        {
            me->CastSpell(me, SPELL_TECHNICIAN_AT_WORK, true);
            task.Repeat(Milliseconds(TECHNICIAN_WORK_INTERVAL_MS));
        });
    }

    TaskScheduler _scheduler;
};

enum PaintItBlack
{
    SPELL_BLIND_SENTRY                  = 79781,
    SPELL_WAILING_SIREN                 = 84152,

    NPC_SENTRY_BOT_BLINDED_CREDIT       = 42796,

    SAY_SENTRY_SHUTDOWN                 = 0
};

// The bot stumbles off blind for this long, then stands where it stopped.
static constexpr uint32 SENTRY_BLIND_DASH_MS        = 1500;
// ...keels over...
static constexpr uint32 BEAT_SENTRY_SHUTDOWN_POSE   = 1800;
// ...and is gone.
static constexpr uint32 SENTRY_SHUTDOWN_MS          = 5000;

// The siren goes off when the target is inside this, on the same clock as the
// smart_scripts row it replaces.
static constexpr float SENTRY_SIREN_RANGE           = 8.0f;

// Crushcog's Sentry-Bot, the target of the Paintinator in "Paint it Black". A hit
// from Blind Sentry credits the quest and shuts the bot down over five seconds: it
// stops fighting, turns on the player, sounds its alarm, careers off blind for a
// second and a half, keels over and despawns.
//
// Not SmartAI. The bot is in combat with the player when the paint lands, and
// SmartAI's UpdateAI keeps calling UpdateVictim, which would either swing at the
// player through the whole shutdown or, with the threat list cleared, evade and run
// the bot home. SMART_ACTION_FLEE cannot stand in for the dash either -- it makes
// the target flee from the bot, not the bot from the player.
struct npc_crushcog_sentry_bot : public ScriptedAI
{
    npc_crushcog_sentry_bot(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _blinded = false;
        _scheduler.CancelAll();
        me->SetReactState(REACT_AGGRESSIVE);
    }

    void EnterCombat(Unit* /*who*/) override
    {
        if (_blinded)
            return;

        _scheduler.Schedule(Milliseconds(1), [this](TaskContext siren)
        {
            Unit* victim = me->GetVictim();
            if (!victim || !me->IsWithinDistInMap(victim, SENTRY_SIREN_RANGE))
            {
                siren.Repeat(Milliseconds(500));
                return;
            }

            DoCast(victim, SPELL_WAILING_SIREN);
            siren.Repeat(Seconds(15), Seconds(25));
        });
    }

    void SpellHit(Unit* caster, SpellInfo const* spell) override
    {
        if (spell->Id != SPELL_BLIND_SENTRY || _blinded)
            return;

        Player* player = caster->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!player)
            return;

        player->KilledMonsterCredit(NPC_SENTRY_BOT_BLINDED_CREDIT);

        _blinded = true;
        _scheduler.CancelAll();
        me->SetReactState(REACT_PASSIVE);
        me->AttackStop();
        me->InterruptNonMeleeSpells(false);

        // Whatever the bot was doing -- chasing, roaming, walking its route -- ends
        // here, or it comes back the moment the dash does.
        me->GetMotionMaster()->Clear(false);
        me->GetMotionMaster()->MoveIdle();

        me->SetFacingToObject(player);
        Talk(SAY_SENTRY_SHUTDOWN, player);
        me->GetMotionMaster()->MoveFleeing(player, SENTRY_BLIND_DASH_MS);

        _scheduler.Schedule(Milliseconds(BEAT_SENTRY_SHUTDOWN_POSE), [this](TaskContext /*task*/)
        {
            me->StopMoving();
            me->SetStandState(UNIT_STAND_STATE_DEAD);
        });

        // Timed from here rather than scheduled, so the bot leaves even if the
        // player finishes it off first.
        me->DespawnOrUnsummon(SENTRY_SHUTDOWN_MS);
    }

    void AttackStart(Unit* who) override
    {
        if (!_blinded)
            ScriptedAI::AttackStart(who);
    }

    void MoveInLineOfSight(Unit* who) override
    {
        if (!_blinded)
            ScriptedAI::MoveInLineOfSight(who);
    }

    void EnterEvadeMode(EvadeReason why) override
    {
        if (!_blinded)
            ScriptedAI::EnterEvadeMode(why);
    }

    void UpdateAI(uint32 diff) override
    {
        if (_blinded)
        {
            _scheduler.Update(diff);
            return;
        }

        if (!UpdateVictim())
            return;

        _scheduler.Update(diff);
        DoMeleeAttackIfReady();
    }

    bool _blinded = false;
    TaskScheduler _scheduler;
};

void AddSC_dun_morogh_area_new_tinkertown()
{
    RegisterCreatureAI(npc_safe_operative_sparring);
    RegisterCreatureAI(npc_gnomeregan_recruit_sparring);
    RegisterCreatureAI(npc_safe_operative_barker);
    RegisterCreatureAI(npc_safe_operative_carrier);
    RegisterCreatureAI(npc_safe_operative_medic);
    RegisterCreatureAI(npc_physicians_assistant_greeter);
    RegisterCreatureAI(npc_target_acquisition_device);
    RegisterCreatureAI(npc_safe_operative_firing_squad);
    RegisterCreatureAI(npc_safe_officer_briefing);
    RegisterCreatureAI(npc_clean_cannon_x2);
    RegisterCreatureAI(npc_safe_guide);
    RegisterCreatureAI(npc_gnomeregan_recruit_column);
    RegisterCreatureAI(npc_gnome_traveler_column);
    RegisterCreatureAI(npc_mounted_ironforge_mountaineer);
    RegisterCreatureAI(npc_xi_monk_trainer);
    RegisterCreatureAI(npc_monk_trainee);
    RegisterCreatureAI(npc_nevin_twistwrench_arrivals);
    RegisterCreatureAI(npc_captain_tread_sparknozzle_scene);
    RegisterCreatureAI(npc_image_of_razlo_crushcog);
    RegisterCreatureAI(npc_tock_sprysprocket);
    RegisterCreatureAI(npc_explosive_fuse);
    RegisterGameObjectAI(go_frostmane_hold_detonator);
    RegisterCreatureAI(npc_jarvi_shadowstep);
    RegisterCreatureAI(npc_high_tinker_mekkatorque_assault);
    RegisterCreatureAI(npc_mountaineer_stonegrind);
    RegisterCreatureAI(npc_razlo_crushcog_mech);
    RegisterCreatureAI(npc_crushcogs_guardian);
    RegisterCreatureAI(npc_crushcog_technician);
    RegisterCreatureAI(npc_crushcog_sentry_bot);
    new player_safe_guide_summoner();
}
