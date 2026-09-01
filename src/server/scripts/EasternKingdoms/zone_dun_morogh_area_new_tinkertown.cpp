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
#include "Map.h"
#include "MotionMaster.h"
#include "MoveSpline.h"
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

    // Nothing hangs off arriving at most legs, so they all share one id. Only the walk
    // home is answered, and only to put the Assistant's facing back.
    POINT_LEG              = 1,
    POINT_ASSISTANT_HOME   = 2
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
static void WalkRoute(Unit* mover, Position const* route, size_t count)
{
    // MoveSplineInit reads args.walk off MOVEMENTFLAG_WALKING in its constructor, so
    // this has to be set before the generator builds the spline.
    mover->SetWalk(true);
    mover->GetMotionMaster()->MoveSmoothPath(POINT_LEG, route, count, true);
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
        if (type == EFFECT_MOTION_TYPE && id == POINT_ASSISTANT_HOME)
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
        // Nothing is concealed here. Retail creates the gnome and starts the cast in the
        // same instant -- the create block and SMSG_SPELL_START share a timestamp -- so
        // the first thing any client draws is the gnome already flashing into place,
        // which is the effect this scene wants. There is nothing to assemble off-screen.
        TempSummon* arrival = me->SummonCreature(NPC_RESCUED_SURVIVOR, TeleporterPad, TEMPSUMMON_MANUAL_DESPAWN);
        if (!arrival)
            return;

        _arrival = arrival->GetGUID();

        // Not triggered: the cast has to run its one second so the client is sent
        // SMSG_SPELL_START and then SMSG_SPELL_GO, which is the pair the flash plays
        // across. A triggered cast sends only the second of them.
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
                WalkRoute(arrival, ArrivalStepOff, std::extent<decltype(ArrivalStepOff)>::value);

            // The one leg in the scene that is run rather than walked: the Assistant
            // hurries over to a gnome that has just appeared, 21.9 yards in 2.9 seconds.
            // That is 8 yards a second, which is what creature_template.speed_run
            // 1.14286 already gives it, so no speed is set here.
            me->SetWalk(false);
            me->GetMotionMaster()->MoveSmoothPath(POINT_LEG, AssistantRoute,
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
            WalkRoute(me, route.data(), route.size());
        });

        _scheduler.Schedule(ARRIVE_TO_FOLLOW, [this](TaskContext /*task*/)
        {
            if (Creature* arrival = GetArrival())
            {
                WalkRoute(arrival, ArrivalWalkToMat, std::extent<decltype(ArrivalWalkToMat)>::value);
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

        if (Creature* arrival = GetArrival())
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

void AddSC_dun_morogh_area_new_tinkertown()
{
    RegisterCreatureAI(npc_safe_operative_sparring);
    RegisterCreatureAI(npc_safe_operative_barker);
    RegisterCreatureAI(npc_safe_operative_carrier);
    RegisterCreatureAI(npc_safe_operative_medic);
    RegisterCreatureAI(npc_physicians_assistant_greeter);
    RegisterCreatureAI(npc_target_acquisition_device);
    RegisterCreatureAI(npc_safe_operative_firing_squad);
}
