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
#include "MotionMaster.h"
#include "MoveSplineInit.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptedCreature.h"
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
struct npc_safe_operative_carrier : public ScriptedAI
{
    npc_safe_operative_carrier(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();

        // First of the three things that keep this Operative out of every fight in
        // the camp. See AttackStart and MoveInLineOfSight below for the other two.
        me->SetReactState(REACT_PASSIVE);

        // Reset runs on respawn, and on anything that cuts a run short -- a grid
        // unload, a .reload. Without this the gnomes from the abandoned run stay.
        DespawnGnome(_passenger);
        DespawnGnome(_placed);

        me->SetAIAnimKitId(ANIM_KIT_CARRY);

        // Summoned hidden. Boarding is not instant -- the seat is filled by a
        // VehicleJoinEvent a tick later, and the client plays the seat's enter
        // animation over the top of it -- so a gnome that were visible from the start
        // would be seen lying on the ground and climbing aboard. Hidden, the first
        // thing any client is told about it is the create block sent from
        // PassengerBoarded, by which point it is already in the Operative's arms and
        // turned the right way.
        if (TempSummon* gnome = me->SummonCreature(NPC_INJURED_GNOME, me->GetPosition(), TEMPSUMMON_MANUAL_DESPAWN, 0, 0, true))
        {
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

    void UpdateAI(uint32 diff) override
    {
        // No UpdateVictim, and nothing that could acquire one. The scheduler is the
        // whole AI.
        _scheduler.Update(diff);
    }

    // VehicleJoinEvent::Execute finishes the boarding with init.SetFacing(0.0f), and
    // nothing in this core ever reads VehicleSeatEntry::PassengerYaw, so every passenger
    // ends up facing straight along the vehicle's local X axis whatever the seat asked
    // for. On this seat that leaves the gnome lying at the wrong angle across the
    // Operative, so the transport-enter spline is re-issued with the facing the carry
    // wants. The offset is read back from what the join event just wrote, which keeps
    // the seat's own attachment point rather than hard-coding it here.
    void PassengerBoarded(Unit* passenger, int8 /*seatId*/, bool apply) override
    {
        if (!apply || !passenger)
            return;

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

private:
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

            // Hidden again, for a different reason: Creature::UpdateEntry runs
            // LoadCreaturesAddon before AddToMap, and creature_template_addon has 46447
            // standing, so a visible summon is created on its feet and only lies down
            // when the stand state that follows reaches the client -- with the whole
            // transition animation played out in the bed. Setting it before the reveal
            // puts UNIT_STAND_STATE_SLEEP in the create block instead, so the gnome has
            // never been anything but lying there.
            if (TempSummon* gnome = me->SummonCreature(NPC_INJURED_GNOME, GnomeBedPosition, TEMPSUMMON_MANUAL_DESPAWN, 0, 0, true))
            {
                _placed = gnome->GetGUID();
                gnome->SetStandState(UNIT_STAND_STATE_SLEEP);
                Reveal(gnome);

                // After the reveal, so the cast itself is something the clients see
                // rather than an aura that was always there.
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

void AddSC_dun_morogh_area_new_tinkertown()
{
    RegisterCreatureAI(npc_safe_operative_sparring);
    RegisterCreatureAI(npc_safe_operative_barker);
    RegisterCreatureAI(npc_safe_operative_carrier);
}
