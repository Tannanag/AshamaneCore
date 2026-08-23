-- Northshire Valley: give the two gate guards their retail patrol routes.
--
-- Reported symptom: the two Northshire Guards at the gate are both wrong. One
-- walks "some kind of patrol, but it is incoherent"; the other does not patrol
-- at all.
--
-- Both halves are visible in the DB before any sniffing:
--
--   guid    x         y        MovementType  path_id   waypoints
--   ------  --------  -------  ------------  --------  ---------
--   177881  -9020.05     3.06             2   1778810         28
--   177882  -9047.58  -101.24             0      NULL          -
--
-- 177881 is the incoherent one and 177882 is the one standing still, which is
-- exactly the pair described. The other four Northshire Guards in the zone
-- (177883-177886) stand still in the sniff as well as in the DB and are left
-- alone.
--
-- Path 1778810 is not a route so much as two overlapping recordings of one. Of
-- its 28 points, eleven are near-duplicates of a point earlier in the list --
-- (-9007.9,-67.4), (-9007.3,-70.3), (-9008.7,-63.4), (-9009.3,-39.2),
-- (-9009.5,-31.4), (-9023.4,3.3), (-9024.7,4.2), (-9043.8,-30.3) and
-- (-9043.5,-30.1) all appear twice -- and point 14 -> point 15 jumps 52 yd
-- across the middle of the loop with nothing in between. A guard walking that
-- list doubles back on itself and then slides sideways, which is the reported
-- "incoherent".
--
-- Source: dump_12.1.0.69404_2026-08-21_15-30-00.pkt, decoded with wpp_patrols.py.
-- The decode was re-validated for build 69404 before use: continuity median
-- 0.923 yd with 90.7% of steps within 3 yd, and 81.2% of 10651 legs at exactly
-- 2.5 yd/s. Retail coordinates go in as-is; no node is snapped or rounded.
--
-- 177881: 19 nodes, closed loop, >=3 full laps observed, completeness 92%,
--   matched to its DB spawn at 0.250 yd (next candidate 4.3 yd) -- certain.
-- 177882: 14 nodes, closed loop, >=4 full laps observed, completeness 95%,
--   matched at 4.554 yd (next candidate 15.3 yd). See the note at the bottom.
--
-- Both routes are out-and-back: the guard walks a line, pauses at the far end,
-- and walks back. waypoint_data is cyclic, so the return leg has to be listed
-- explicitly -- the repeated nodes below are the walk home, not duplicates of
-- the kind that made 1778810 incoherent. The pauses the sniff timed are kept as
-- `delay` on the turnaround nodes.
--
-- Point 1 is the node nearest the spawn point in both paths: the core walks a
-- freshly spawned NPC to point 1 before it starts patrolling, so a path that
-- starts on the far side makes the guard cross its own route on every respawn.

-- Northshire Guard 177881 -- replaces path 1778810 (28 waypoints -> 19).
--   19 waypoints, circuit of 19 nodes, via gap-free lap, walk (2.50 yd/s), 2 nodes with a delay
SET @NPC := 177881;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-9020.281,3.154,88.423,0,0,0,0,100,0),
(@PATH,2,-9012.075,-14.765,88.371,0,0,0,0,100,0),
(@PATH,3,-9010.279,-34.814,88.040,0,0,0,0,100,0),
(@PATH,4,-9009.692,-53.727,87.291,0,0,0,0,100,0),
(@PATH,5,-9007.624,-70.437,86.656,0,0,0,0,100,0),
(@PATH,6,-9006.875,-78.345,86.547,0,1729,0,0,100,0),
(@PATH,7,-9009.569,-58.099,87.150,0,0,0,0,100,0),
(@PATH,8,-9009.410,-31.611,88.201,0,0,0,0,100,0),
(@PATH,9,-9014.083,-3.766,88.764,0,0,0,0,100,0),
(@PATH,10,-9024.770,4.273,88.234,0,0,0,0,100,0),
(@PATH,11,-9035.086,2.458,88.228,0,0,0,0,100,0),
(@PATH,12,-9040.156,-7.507,88.242,0,0,0,0,100,0),
(@PATH,13,-9041.208,-21.521,88.242,0,0,0,0,100,0),
(@PATH,14,-9043.388,-35.013,88.262,0,0,0,0,100,0),
(@PATH,15,-9045.403,-42.908,88.349,0,2090,0,0,100,0),
(@PATH,16,-9043.856,-30.389,88.293,0,0,0,0,100,0),
(@PATH,17,-9040.349,-11.366,88.242,0,0,0,0,100,0),
(@PATH,18,-9037.478,-0.493,88.281,0,0,0,0,100,0),
(@PATH,19,-9031.200,4.595,88.191,0,0,0,0,100,0);

-- Northshire Guard 177882 -- was standing still with no addon row at all.
--   14 waypoints, circuit of 14 nodes, via gap-free lap, walk (2.47 yd/s), 2 nodes with a delay
SET @NPC := 177882;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-9046.873,-96.741,88.063,0,0,0,0,100,0),
(@PATH,2,-9052.141,-86.494,87.922,0,0,0,0,100,0),
(@PATH,3,-9047.826,-67.828,88.149,0,0,0,0,100,0),
(@PATH,4,-9046.549,-51.213,88.200,0,0,0,0,100,0),
(@PATH,5,-9046.152,-44.839,88.331,0,1862,0,0,100,0),
(@PATH,6,-9047.811,-66.246,88.143,0,0,0,0,100,0),
(@PATH,7,-9051.520,-86.363,87.961,0,0,0,0,100,0),
(@PATH,8,-9047.505,-95.976,88.065,0,0,0,0,100,0),
(@PATH,9,-9037.521,-101.629,87.811,0,0,0,0,100,0),
(@PATH,10,-9024.465,-99.404,87.346,0,0,0,0,100,0),
(@PATH,11,-9013.879,-90.977,86.536,0,0,0,0,100,0),
(@PATH,12,-9007.525,-81.200,86.525,0,2243,0,0,100,0),
(@PATH,13,-9021.590,-96.392,87.039,0,0,0,0,100,0),
(@PATH,14,-9035.880,-102.086,87.717,0,0,0,0,100,0);

-- The addon rows above are mandatory, not decoration: ObjectMgr::LoadCreatureAddons
-- silently downgrades MovementType=2 to idle when the spawn has no
-- creature_addon.path_id, which would leave both guards standing still again.
--
-- Worth checking in game: 177882 matched its route at 4.554 yd rather than the
-- ~0 yd that makes a pairing certain. Nothing else is close -- the runner-up is
-- 15.3 yd (177883/177884, the pair standing together further west, both of them
-- outside this route's x range entirely) -- and 177882 is the only other guard
-- the report describes as broken, so the pairing is almost certainly right. But
-- 4.5 yd means the sniffed spawn point is not exactly on a node, so confirm with
-- `.npc info` on that guard before trusting the guid. `.guid` returns a runtime
-- counter, not the spawn id. The consequence if it is wrong is small and
-- reversible: a guard 4.5 yd from point 1 walks 4.5 yd on respawn and then
-- patrols normally.
--
-- Left alone on purpose: Northshire Guards 177883, 177884, 177885 and 177886.
-- All four stand still in the sniff as well as in the DB. 177885 carries a
-- creature_addon row with path_id 0, which is harmless with MovementType 0.
--
-- @touched: creature,creature_addon,waypoint_data 177881,177882
