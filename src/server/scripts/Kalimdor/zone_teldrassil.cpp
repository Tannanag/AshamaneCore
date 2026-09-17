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
#include "MoveSpline.h"
#include "MoveSplineInit.h"
#include "ObjectAccessor.h"
#include "PassiveAI.h"
#include "Player.h"
#include "ScriptedCreature.h"
#include "TaskScheduler.h"
#include "WaypointManager.h"
#include <G3D/Vector3.h>

// The Wisps (48624) of Shadowglen and Dolanaar each fly one fixed CatmullRom path,
// forever, at their run speed of 8 yd/s. Retail sends it in one of two ways and the
// path decides which:
//
// - a closed loop, sent once as a cyclic spline in the create block and never
//   followed by another movement packet -- 15 of the 23 sniffed wisps;
// - a rising helix around a tree trunk, sent as a plain spline from the foot to the
//   top; at the top the wisp is teleported back to the foot and the same spline is
//   sent again -- the other 8.
//
// The core has no cyclic waypoint mode and its waypoint generator stops and re-aims
// at every node, which segments a curve like this badly, so the AI drives the spline
// itself. The nodes come from the waypoint_data path the spawn's creature_addon
// names, which keeps the data in SQL where the rest of the movement work lives, and
// keeps this AI free of coordinates. The spawn keeps MovementType 0: a random or
// waypoint generator would call StopMoving() under the spline.
//
// A path is a loop when getting from its last node back to its first is just another
// leg -- for the sniffed loops the closing leg is never longer than the longest leg
// in the path, and for every helix it is at least three times longer (a 22-45 yd
// climb against legs of 5-9 yd). 1.5x sits in the middle of that gap.
//
// The velocity is deliberately not set: with DisableGravity and no FLYING movement
// flag, MoveSplineInit picks the run speed, and 8.0 is what the sniff shows even
// though the template's flight speed is 7.
struct npc_wisp_flight_path : public NullCreatureAI
{
    npc_wisp_flight_path(Creature* creature) : NullCreatureAI(creature) { }

    void UpdateAI(uint32 /*diff*/) override
    {
        // True at spawn, after anything that stopped the wisp, and -- for a helix --
        // every time it reaches the top. A loop's cyclic spline never finalizes.
        if (!me->movespline->Finalized())
            return;

        WaypointPath const* path = sWaypointMgr->GetPath(me->GetWaypointPath());
        if (!path || path->size() < 3)
            return;

        // Retail snaps a helix wisp back to the foot with a teleport between laps,
        // and a loop that was interrupted mid-lap would otherwise gain the point it
        // stopped at as an extra node. Node 1 is the spawn point, so at spawn this
        // is a no-op.
        WaypointData const* first = path->front();
        if (me->GetExactDist(first->x, first->y, first->z) > 0.5f)
            me->NearTeleportTo(first->x, first->y, first->z, me->GetOrientation());

        Movement::MoveSplineInit init(me);
        // MoveSplineInit::Launch overwrites the first point with the current position.
        init.Path().emplace_back(first->x, first->y, first->z);
        for (size_t i = 1; i < path->size(); ++i)
            init.Path().emplace_back((*path)[i]->x, (*path)[i]->y, (*path)[i]->z);

        init.SetFly();
        init.SetSmooth();
        init.SetUncompressed();
        if (IsClosedLoop(init.Path()))
            init.SetCyclic();
        init.Launch();
    }

private:
    static bool IsClosedLoop(Movement::PointsArray const& points)
    {
        float longestLeg = 0.0f;
        for (size_t i = 1; i < points.size(); ++i)
            longestLeg = std::max(longestLeg, (points[i] - points[i - 1]).length());

        return (points.front() - points.back()).length() <= longestLeg * 1.5f;
    }
};

// Moriana Dawnlight (34756) and Doranel Amberleaf (34757) stand together at the top
// of Aldrassil and, when a player steps between them, Amberleaf voices her doubts
// about Fandral, Dawnlight hushes her, and both turn to look at the player before
// turning back. In the 14 Sep sniff the scene is not an OOC line-of-sight bark: it
// fires on areatrigger 5481 (r 3.95 at 10452.4, 843.4, the spot between them) and
// only on entering it -- the client sends the leave 1.2 s later and nothing answers
// it. SmartTrigger fires SMART_EVENT_AREATRIGGER_ONTRIGGER on leave as well, and
// SMART_ACTION_SET_DATA drops the invoker, so a SmartAI build could neither ignore
// the leave nor have the two face the player; hence the C++.
//
// Dawnlight owns the lockout. At T0 she casts 88811 "CSA Area Trigger Dummy Timer
// Aura" on herself, a 30 s dummy, and while she carries it the trigger does nothing:
// at 23:39:15 another player set the scene off and the sniffed player's own entry
// at 23:39:36 was ignored. Offsets below are from her cast, identical in both runs
// the player caused (23:08:18 and 23:10:18):
//   +0.1 s  Amberleaf: "Don't get me wrong... What happened to Fandral?"
//   +3.2 s  Dawnlight: "Shh! Someone's here."
//   +4.3 s  both face the player (MonsterMove Face: Target)
//  +15.2 s  both face their spawn orientation again (Face: Angle 5.0615 / 2.0246)
enum DawnlightAmberleafData
{
    NPC_MORIANA_DAWNLIGHT                       = 34756,
    NPC_DORANEL_AMBERLEAF                       = 34757,
    SPELL_CSA_AREA_TRIGGER_DUMMY_TIMER_AURA     = 88811,

    SAY_AMBERLEAF_WHAT_HAPPENED_TO_FANDRAL      = 0,
    SAY_DAWNLIGHT_SOMEONE_IS_HERE               = 0
};

struct npc_moriana_dawnlight : public ScriptedAI
{
    npc_moriana_dawnlight(Creature* creature) : ScriptedAI(creature) { }

    void Reset() override
    {
        _scheduler.CancelAll();
    }

    // Called by the areatrigger script with the player who stepped on 5481.
    void SetGUID(ObjectGuid guid, int32 /*id*/) override
    {
        // The aura is the lockout, as on retail: no restart, no queue.
        if (me->HasAura(SPELL_CSA_AREA_TRIGGER_DUMMY_TIMER_AURA))
            return;

        // Amberleaf spawns 1.4 yd from her; if she is not there (dead, despawned)
        // there is no conversation to have.
        Creature* amberleaf = me->FindNearestCreature(NPC_DORANEL_AMBERLEAF, 10.0f);
        if (!amberleaf)
            return;

        _playerGUID = guid;
        _amberleafGUID = amberleaf->GetGUID();
        _scheduler.CancelAll();

        // A real cast -- the sniff has SMSG_SPELL_START and SMSG_SPELL_GO for it,
        // not just the aura update. Cast time is 0 so nothing waits on it.
        DoCastSelf(SPELL_CSA_AREA_TRIGGER_DUMMY_TIMER_AURA);

        _scheduler.Schedule(Milliseconds(100), [this](TaskContext /*task*/)
        {
            if (Creature* amberleaf = GetAmberleaf())
                amberleaf->AI()->Talk(SAY_AMBERLEAF_WHAT_HAPPENED_TO_FANDRAL);
        });

        _scheduler.Schedule(Milliseconds(3200), [this](TaskContext /*task*/)
        {
            Talk(SAY_DAWNLIGHT_SOMEONE_IS_HERE);
        });

        _scheduler.Schedule(Milliseconds(4300), [this](TaskContext /*task*/)
        {
            // The player may have logged out or moved out of range in the 4 s; the
            // scene still finishes, they just do not turn.
            if (Player* player = ObjectAccessor::GetPlayer(*me, _playerGUID))
            {
                me->SetFacingToObject(player);
                if (Creature* amberleaf = GetAmberleaf())
                    amberleaf->SetFacingToObject(player);
            }
        });

        _scheduler.Schedule(Milliseconds(15200), [this](TaskContext /*task*/)
        {
            // Spawn orientation, not a fixed angle: both spawns sit on the sniffed
            // marks to the bit and MovementType 0 keeps the home position there.
            me->SetFacingTo(me->GetHomePosition().GetOrientation());
            if (Creature* amberleaf = GetAmberleaf())
                amberleaf->SetFacingTo(amberleaf->GetHomePosition().GetOrientation());
        });
    }

    void UpdateAI(uint32 diff) override
    {
        // Out of combat too -- the whole scene is out of combat.
        _scheduler.Update(diff);

        if (!UpdateVictim())
            return;

        DoMeleeAttackIfReady();
    }

private:
    Creature* GetAmberleaf() const
    {
        return ObjectAccessor::GetCreature(*me, _amberleafGUID);
    }

    TaskScheduler _scheduler;
    ObjectGuid _playerGUID;
    ObjectGuid _amberleafGUID;
};

// Areatrigger 5481, the spot between the two.
class at_aldrassil_dawnlight_amberleaf : public AreaTriggerScript
{
public:
    at_aldrassil_dawnlight_amberleaf() : AreaTriggerScript("at_aldrassil_dawnlight_amberleaf") { }

    bool OnTrigger(Player* player, AreaTriggerEntry const* /*trigger*/, bool entered) override
    {
        // The client reports the leave too, about a second later; retail answers
        // only the entry.
        if (!entered || !player->IsAlive())
            return false;

        // 11 yd from the trigger centre to the pair.
        Creature* dawnlight = player->FindNearestCreature(NPC_MORIANA_DAWNLIGHT, 30.0f);
        if (!dawnlight)
            return false;

        dawnlight->AI()->SetGUID(player->GetGUID());
        return true;
    }
};

void AddSC_teldrassil()
{
    RegisterCreatureAI(npc_wisp_flight_path);
    RegisterCreatureAI(npc_moriana_dawnlight);
    new at_aldrassil_dawnlight_amberleaf();
}
