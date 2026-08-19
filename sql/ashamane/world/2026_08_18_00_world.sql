-- Coldridge Valley / Frostmane Hold: two spawns get their retail patrol routes.
--
-- Recovered from the 2026-08-18 retail sniff (build 12.1.0.69382, 48,978 packets,
-- 10,604 monster-moves over 386 spawns, ~35 min around Coldridge and the road
-- south to Frostmane Hold). WowPacketParser has no opcode tables for this build,
-- so the routes come from decoding the raw 0x5E0002 spline payloads directly --
-- wpp_movement.py / wpp_patrols.py, method and validation in
-- PACKET-DUMP-HANDOFF.md. The layout check on this build gives a continuity
-- median of 0.429 yd and 90.9% of legs at exactly 2.50 yd/s, so the field
-- offsets recovered on 69299 still hold on 69382.
--
-- Both spawns are matched to a route node rather than by proximity: a patrolling
-- NPC's spawn point is one of its waypoints, so coincidence identifies the spawn
-- where nearest-neighbour cannot.
--
--   167209  Frostmane Blade       0.003 yd from a node (next candidate 2.8 yd)
--   167027  Coldridge Mountaineer 7.332 yd from a node (next candidate 30.1 yd)
--
-- 167027's 7.3 yd offset means its stored spawn point is not itself a waypoint;
-- the pairing is still unambiguous at 30 yd to the next candidate, but it is the
-- one to confirm with .npc info if the wrong Mountaineer starts walking.
--
-- Both routes are out-and-back lines rather than circuits. WaypointMovement
-- cycles a path rather than ping-ponging it, so the return leg is listed
-- explicitly -- 7 nodes walked as 12 stops, 11 nodes walked as 20.
--
-- Audited and deliberately left alone:
--   * Sten Stoutarm 167020 and Coldridge Mountaineer 167026 already patrol the
--     routes applied in 39c816e922; this sniff agrees with both and re-emitting
--     would replace working paths with one sniff's reconstruction.
--   * Frostmane Blade 167243. The sniff caught only 4 of its 11 nodes joined up,
--     and the 6-stop lap that survives sits 45 yd from where the spawn stands --
--     a fragment of a route, not the route.
--   * Wayward Fire Elemental, held back here because two sniffed spawns both
--     claimed guid 167308. They turned out to be one elemental either side of a
--     death -- a respawn carries a fresh guid counter -- and its route is applied
--     in 2026_08_18_03_world.sql. There is one spawn of 37112 and retail has one
--     elemental; an earlier draft of this header said otherwise and was wrong.
--   * Coldridge Mountaineer sniffed spawn 25455800: nearest DB spawn is 8.39 yd
--     from any node, past the 8 yd bar, so it is not identified.
--
-- Path ids follow the TDB guid*10 convention; both are free of collisions.
-- The creature_addon row is mandatory, not optional: ObjectMgr::LoadCreatureAddons
-- silently downgrades MovementType 2 to idle when a spawn has no path_id.

-- Frostmane Blade (entry 37507) -- sniffed spawn 42233016
--   matched guid 167209 at 0.003 yd from a route node (next candidate 2.8 yd)
--   12 waypoints, out-and-back over 7 nodes (12 stops per lap), via spanning-tree line, walk (2.46 yd/s), 0 node(s) with a delay
--   was MovementType 1, wander_distance 3, no creature_addon path
--   WARNING: 1 gap(s) in the sniff span ground no lap covered -- roughly 1 waypoint(s) of this route were never seen and are not in the list below
SET @NPC := 167209;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6524.860,419.767,386.261,0,0,0,0,100,0),
(@PATH,2,-6528.167,402.971,382.694,0,0,0,0,100,0),
(@PATH,3,-6539.793,386.633,381.870,0,0,0,0,100,0),
(@PATH,4,-6541.569,377.342,381.706,0,0,0,0,100,0),
(@PATH,5,-6526.955,380.441,382.888,0,0,0,0,100,0),
(@PATH,6,-6512.760,382.574,385.090,0,0,0,0,100,0),
(@PATH,7,-6499.151,391.222,385.234,0,0,0,0,100,0),
(@PATH,8,-6512.760,382.574,385.090,0,0,0,0,100,0),
(@PATH,9,-6526.955,380.441,382.888,0,0,0,0,100,0),
(@PATH,10,-6541.569,377.342,381.706,0,0,0,0,100,0),
(@PATH,11,-6539.793,386.633,381.870,0,0,0,0,100,0),
(@PATH,12,-6528.167,402.971,382.694,0,0,0,0,100,0);

-- Coldridge Mountaineer (entry 853) -- sniffed spawn 42233016
--   matched guid 167027 at 7.332 yd from a route node (next candidate 30.1 yd)
--   20 waypoints, out-and-back over 11 nodes (20 stops per lap), via gap-free lap, walk (2.47 yd/s), 0 node(s) with a delay
--   was MovementType 0, wander_distance 0, no creature_addon path
SET @NPC := 167027;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6237.221,160.976,426.151,0,0,0,0,100,0),
(@PATH,2,-6253.904,175.225,419.043,0,0,0,0,100,0),
(@PATH,3,-6264.217,191.137,412.652,0,0,0,0,100,0),
(@PATH,4,-6264.504,208.361,406.227,0,0,0,0,100,0),
(@PATH,5,-6266.325,224.865,399.189,0,0,0,0,100,0),
(@PATH,6,-6258.820,243.262,391.910,0,0,0,0,100,0),
(@PATH,7,-6253.693,267.724,385.809,0,0,0,0,100,0),
(@PATH,8,-6254.481,290.208,383.707,0,0,0,0,100,0),
(@PATH,9,-6255.720,310.069,383.152,0,0,0,0,100,0),
(@PATH,10,-6248.776,318.549,382.724,0,0,0,0,100,0),
(@PATH,11,-6236.734,321.102,382.642,0,0,0,0,100,0),
(@PATH,12,-6248.776,318.549,382.724,0,0,0,0,100,0),
(@PATH,13,-6255.720,310.069,383.152,0,0,0,0,100,0),
(@PATH,14,-6254.481,290.208,383.707,0,0,0,0,100,0),
(@PATH,15,-6253.693,267.724,385.809,0,0,0,0,100,0),
(@PATH,16,-6258.820,243.262,391.910,0,0,0,0,100,0),
(@PATH,17,-6266.325,224.865,399.189,0,0,0,0,100,0),
(@PATH,18,-6264.504,208.361,406.227,0,0,0,0,100,0),
(@PATH,19,-6264.217,191.137,412.652,0,0,0,0,100,0),
(@PATH,20,-6253.904,175.225,419.043,0,0,0,0,100,0);

-- 2 paths, 32 waypoint rows total
-- @touched: creature,creature_addon,waypoint_data 167209,167027
