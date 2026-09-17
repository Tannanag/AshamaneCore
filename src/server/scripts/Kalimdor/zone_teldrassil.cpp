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
#include "PassiveAI.h"
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

void AddSC_teldrassil()
{
    RegisterCreatureAI(npc_wisp_flight_path);
}
