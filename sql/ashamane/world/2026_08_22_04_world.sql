-- Northshire Valley: the southern gate patrol belongs to guard 177885, not
-- 177882, and 177885 has to spawn on the route it walks.
--
-- 2026_08_22_00 paired the 14-node southern route with guid 177882 on a 4.554 yd
-- match and flagged it as the one thing in that file worth checking in game,
-- since anything past ~1 yd is a guess rather than an identification. Checked,
-- and it was wrong: the guard actually walking that loop is 177885. This file
-- moves the route across and puts 177882 back exactly as it was.
--
-- Why the match missed is worth recording. The pairing rule is that a patrolling
-- NPC's spawn point is one of its own waypoints, which identifies it outright.
-- That rule assumes the spawn point is on the route, and 177885's is not -- it
-- sits 37.11 yd from the nearest node. So the real owner could not be found by
-- proximity at all, and 177882, standing 4.554 yd off the route by coincidence,
-- looked like the best available answer. A 4.5 yd "best match" with no exact
-- match anywhere in the zone was the tell.

-- 1. Put 177882 back: stationary, no addon row, no path. These are the values
--    from the pre-change snapshot, not reconstructed.
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=1.98968 WHERE `guid`=177882;
DELETE FROM `creature_addon` WHERE `guid`=177882;
DELETE FROM `waypoint_data` WHERE `id`=1778820;

-- 2. Move 177885 onto the route and give it the path.
--
-- The spawn point moves because the alternative is worse. The core walks a
-- freshly spawned NPC to point 1 before it patrols, so leaving 177885 where it
-- was would make it cross 37 yd of open ground on every respawn -- the same
-- defect 2026_08_22_00 removed from 177881's old path. Of the 14 nodes, point 5
-- of the old numbering is both the nearest to where 177885 stood (37.11 yd, next
-- nearest 38.95) and one of the two nodes the sniff timed a pause at (1862 ms),
-- so it is a place the guard already stops rather than an arbitrary point on a
-- leg. The spawn lands exactly on it.
--
-- Orientation 4.6350 is the bearing from that node to the next one, so the guard
-- spends its 1862 ms pause facing the way it is about to walk.
UPDATE `creature` SET `position_x`=-9046.152, `position_y`=-44.839, `position_z`=88.331,
    `orientation`=4.6350, `MovementType`=2, `wander_distance`=0
 WHERE `guid`=177885 AND `id`=1642;

-- 177885 already had a creature_addon row carrying aura 18950 "Invisibility and
-- Stealth Detection" (MOD_INVIS_DETECT + MOD_STEALTH_DETECT at 100000). That is
-- updated in place rather than replaced -- a DELETE and re-INSERT would have
-- dropped the aura, and it matters more than usual now that 2026_08_22_01 put
-- real stealth on the Blackrock Spies this guard walks past.
UPDATE `creature_addon` SET `path_id`=1778850 WHERE `guid`=177885;

-- 3. The same 14 retail nodes, rotated so the guard's new spawn node is point 1.
--    waypoint_data is cyclic, so rotating changes only where the route is
--    entered; the loop, its direction and both timed pauses are unchanged. Old
--    point 1 is now point 11.
SET @PATH := 1778850;
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-9046.152,-44.839,88.331,0,1862,0,0,100,0),
(@PATH,2,-9047.811,-66.246,88.143,0,0,0,0,100,0),
(@PATH,3,-9051.520,-86.363,87.961,0,0,0,0,100,0),
(@PATH,4,-9047.505,-95.976,88.065,0,0,0,0,100,0),
(@PATH,5,-9037.521,-101.629,87.811,0,0,0,0,100,0),
(@PATH,6,-9024.465,-99.404,87.346,0,0,0,0,100,0),
(@PATH,7,-9013.879,-90.977,86.536,0,0,0,0,100,0),
(@PATH,8,-9007.525,-81.200,86.525,0,2243,0,0,100,0),
(@PATH,9,-9021.590,-96.392,87.039,0,0,0,0,100,0),
(@PATH,10,-9035.880,-102.086,87.717,0,0,0,0,100,0),
(@PATH,11,-9046.873,-96.741,88.063,0,0,0,0,100,0),
(@PATH,12,-9052.141,-86.494,87.922,0,0,0,0,100,0),
(@PATH,13,-9047.826,-67.828,88.149,0,0,0,0,100,0),
(@PATH,14,-9046.549,-51.213,88.200,0,0,0,0,100,0);

-- Left alone: 177881 and its path 1778810, which matched at 0.250 yd and was
-- never in doubt. 177883, 177884 and 177886 still stand still.
--
-- @touched: creature,creature_addon,waypoint_data 177882,177885
