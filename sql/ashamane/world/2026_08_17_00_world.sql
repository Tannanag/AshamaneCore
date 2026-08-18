-- Coldridge Valley: give nine spawns their retail patrol routes.
--
-- All nine stand still today (`MovementType` = 0, `wander_distance` = 0) on
-- spots where retail walks them a fixed route. 9 paths, 137 waypoints:
--
--   entry  NPC                     guid    path      rows  speed  shape
--     658  Sten Stoutarm         167020   1670200      3   walk   circuit
--   37087  Jona Ironstock        166999   1669990     12   walk   circuit
--     853  Coldridge Mountaineer 166975   1669750     15   walk   circuit
--     853  Coldridge Mountaineer 166972   1669720     23   walk   circuit
--     853  Coldridge Mountaineer 167026   1670260      7   walk   circuit  (see below)
--   37218  Coldridge Citizen     167017   1670170     10   walk   circuit
--   37218  Coldridge Citizen     167012   1670120     25   walk   circuit
--   37218  Coldridge Citizen     167038   1670380     14   walk   circuit  (see below)
--   37073  Rockjaw Goon          167220   1672200     28   RUN    out-and-back
--
-- Where the coordinates come from
--
-- Two retail 12.1.0.69299 sniffs of the valley, 62,711 packets carrying 13,863
-- monster-moves over about 31 minutes. WowPacketParser cannot read this build
-- -- its V12_1_0_69214 opcode tables are empty stubs upstream -- so the 0x5E0002
-- spline payloads were decoded directly by `wpp_movement.py`, and the node order
-- recovered by `wpp_patrols.py`. Both are in the repo root; `wpp_patrols.py --sql`
-- regenerates every block below, so none of this is hand-transcribed.
--
-- A stored waypoint replays as the same float32 triple every lap while random
-- wander never repeats a coordinate exactly, which is what separates these nine
-- from the 111 wanderers in the same sniff.
--
-- Only nodes joined by observed legs are emitted
--
-- The reconstruction also turns up nodes it cannot place: stretches whose
-- linking legs were never seen, and one-off points that may be combat detours.
-- Those are dropped rather than appended, because a node in the wrong position
-- is worse than a node left out -- it makes the NPC walk its circuit and then
-- strike out across the map to each stray point in turn. 22 nodes were dropped
-- this way, from three of the nine routes.
--
-- Out-and-back routes
--
-- Not every route is a circuit. The Rockjaw Goon patrols a 200 yard line from
-- (-6270.8, 450.5) down to (-6384.5, 281.3) and turns round at each end, and a
-- greedy successor walk cannot represent that -- it stops the moment an edge
-- leads back to a node it already emitted, which gave 7 nodes of 15 and an 87
-- yard jump to close them.
--
-- Such a route is recovered from its shape instead. The maximum spanning tree
-- over observed transitions *is* the line, every node of degree 2 bar the two
-- ends, and two things then tell a line from a circuit: a circuit is observed
-- closing, where a line's ends are 200 yards apart and never adjacent; and a
-- line's ends are visited about half as often as its middle, because each lap
-- passes through the middle twice and touches each end once. The Goon's ends
-- come in at 0.62 of its middle, with no closing transition.
--
-- It is emitted as the full round trip, out along the line and back through the
-- interior, because WaypointMovementGenerator.cpp:134 cycles a path rather than
-- ping-ponging it (`i_currentNode = (i_currentNode+1) % i_path->size()`). A
-- one-way chain would teleport-walk the Goon from the far end back to the start
-- on every lap. 28 rows over 15 distinct nodes, longest leg 23.8 yards, and the
-- spawn point falls on the path at rows 8 and 22.
--
-- Why these guids and not others
--
-- Retail spawn counters (49318, 159459, ...) are runtime GUIDs with no relation
-- to `creature.guid`, and the three Coldridge Citizen routes have centroids only
-- 4 yards apart, so matching on proximity alone is ambiguous. But a patrolling
-- NPC's spawn point *is* one of its waypoints, so the pairing was made on exact
-- coincidence instead: for eight of the nine the live spawn coordinate is
-- bit-for-bit one of the recovered nodes (0.000 to 0.005 yd, z within 0.03).
-- That is decisive even where a neighbouring spawn also sits near the route --
-- guid 167013 is 0.797 yd off 167038's path, against 167038's own 0.000.
-- Matching considers every recovered node, including the dropped ones: where
-- the spawn sits is a question about identity, which nodes are safe to emit is
-- a question about ordering, and conflating the two loses the Rockjaw Goon.
--
-- Coldridge geometry is unchanged between 7.3.5 and 12.1.0, so the retail
-- coordinates go in as-is: no translation, no snapping.
--
-- Three spawns worth flagging
--
-- * 167026 is still a stub rather than a circuit. Its longest leg is 45 yards
--   and its own spawn point sits 7 yards off the path, both signs the discarded
--   nodes carried the route between two ends. Unlike the Goon it does not
--   reconstruct as a line either -- its spanning tree branches -- so there is
--   nothing better to emit from this sniff. It needs a longer continuous follow
--   before it can be done properly; revert that one block if it reads badly.
-- * 167038 has a 32 yard closing leg, mild by comparison but the same cause. It
--   is an out-and-back in truth, but its ends were seen too few times to pass
--   the reversal test, so it is emitted as the circuit the walk recovered.
-- * 167026 is also the one non-exact pairing, 6.17 yd from its nearest node with
--   the next candidate at 13.9 yd. Confirm with `.npc info` on the Mountaineer
--   near (-6183, 376).
-- * 167017 carried `creature_addon.StandState` = 3, so it sat. Retail walks it,
--   and the rest of its addon row was defaults, so the row is rewritten with
--   StandState 0. It was the only one of the nine with an addon row at all.
--
-- How each column was derived
--
--   position_x/y/z  float32 node coordinates in recovered route order
--   move_type       distance / spline duration; the routes land on either
--                   ~2.5 yd/s (walk) or ~6.0 yd/s, and only the Rockjaw Goon
--                   is in the second group at 5.95 yd/s
--   delay           median dwell across laps, in ms
--   orientation     0 everywhere -- stored facing is not recoverable from the
--                   sniff, and the core faces the NPC along the path anyway
--   action / action_chance / wpguid   0 / 100 / 0
--
-- Only five nodes across all nine routes pause for more than a second: 8.3 s and
-- 7.6 s on two Mountaineer routes, 19.5 s and 13.1 s on Citizen 167012, and 1.2 s
-- on 167026. Dwell samples were thrown out when the NPC turned out to have moved
-- while unobserved, and when the player was more than 90 yd away -- past that the
-- sniff simply stops receiving the NPC's packets while the clock keeps running,
-- which is where every implausible figure came from (one node reads as a 20-minute
-- pause on two disagreeing samples). A node needs three surviving samples before
-- a median is trusted; below that it is written as no delay.
--
-- Audit
--
-- * `waypoint_data` has no ids anywhere in the 1.66M-1.68M band, so the
--   guid * 10 path ids collide with nothing.
-- * All nine spawns confirmed still at `MovementType` = 0 and the coordinates
--   above before writing.
-- * `ObjectMgr::LoadCreatureAddons` silently downgrades `MovementType` = 2 to
--   idle when the spawn has no `creature_addon.path_id`, so the addon row is
--   mandatory rather than optional -- hence the DELETE/INSERT pair per spawn.
-- * Entries 853 and 37073 have `AIName` = 'SmartAI', but neither uses
--   SMART_ACTION_WP_START, so nothing there fights `MovementType` = 2. The
--   `waypoints` + SAI action 53 mechanism is deliberately not used here: that is
--   for escort paths, and three of these five entries have no `AIName` at all.
--
-- Deliberately left alone
--
-- * Citizens 167014, 167015 and 167016, set wandering by e3000aff80. Neither
--   matches a recovered route and their radius is already right.
-- * `creature_template.MovementType`, npcflags, and formations (none exist for
--   these guids).
--
-- The core straight-lines between waypoints while retail splines through them,
-- so watch for anyone clipping terrain on a curved leg. The intermediate spline
-- points are still in the packet data if a leg needs filling in.

-- Coldridge Citizen (entry 37218) -- retail spawn 25215147
--   matched guid 167017 at 0.001 yd from a route node (next candidate 5.4 yd)
--   10 waypoints, circuit, walk (2.40 yd/s), 0 node(s) with a delay, 1 unlinked node(s) dropped
SET @NPC := 167017;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6088.332,399.516,395.597,0,0,0,0,100,0),
(@PATH,2,-6081.270,393.029,393.822,0,0,0,0,100,0),
(@PATH,3,-6074.948,386.149,393.597,0,0,0,0,100,0),
(@PATH,4,-6071.469,385.264,393.950,0,0,0,0,100,0),
(@PATH,5,-6067.965,380.767,393.706,0,0,0,0,100,0),
(@PATH,6,-6066.971,370.811,393.597,0,0,0,0,100,0),
(@PATH,7,-6069.182,382.866,393.609,0,0,0,0,100,0),
(@PATH,8,-6074.912,385.899,393.597,0,0,0,0,100,0),
(@PATH,9,-6081.568,392.512,393.689,0,0,0,0,100,0),
(@PATH,10,-6088.628,399.366,395.597,0,0,0,0,100,0);

-- Coldridge Mountaineer (entry 853) -- retail spawn 49319
--   matched guid 166975 at 0.000 yd from a route node (next candidate 3.5 yd)
--   15 waypoints, circuit, walk (2.40 yd/s), 1 node(s) with a delay
SET @NPC := 166975;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6109.585,390.309,395.597,0,0,0,0,100,0),
(@PATH,2,-6108.307,376.966,395.597,0,0,0,0,100,0),
(@PATH,3,-6098.929,372.751,395.597,0,0,0,0,100,0),
(@PATH,4,-6089.930,366.932,395.597,0,0,0,0,100,0),
(@PATH,5,-6081.341,376.956,393.565,0,0,0,0,100,0),
(@PATH,6,-6080.260,383.485,393.597,0,0,0,0,100,0),
(@PATH,7,-6075.878,384.170,393.597,0,0,0,0,100,0),
(@PATH,8,-6065.815,383.761,393.548,0,8347,0,0,100,0),
(@PATH,9,-6077.331,384.505,393.597,0,0,0,0,100,0),
(@PATH,10,-6081.070,393.094,393.818,0,0,0,0,100,0),
(@PATH,11,-6089.586,400.611,395.662,0,0,0,0,100,0),
(@PATH,12,-6094.961,397.080,395.597,0,0,0,0,100,0),
(@PATH,13,-6104.308,396.571,396.021,0,0,0,0,100,0),
(@PATH,14,-6108.483,398.134,395.597,0,0,0,0,100,0),
(@PATH,15,-6111.334,398.886,395.597,0,0,0,0,100,0);

-- Sten Stoutarm (entry 658) -- retail spawn 49318
--   matched guid 167020 at 0.003 yd from a route node (the only spawn of this entry in the box)
--   3 waypoints, circuit, walk (2.41 yd/s), 0 node(s) with a delay
SET @NPC := 167020;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6240.077,347.385,383.848,0,0,0,0,100,0),
(@PATH,2,-6243.069,345.675,383.369,0,0,0,0,100,0),
(@PATH,3,-6229.550,346.663,383.664,0,0,0,0,100,0);

-- Jona Ironstock (entry 37087) -- retail spawn 49323
--   matched guid 166999 at 0.005 yd from a route node (the only spawn of this entry in the box)
--   12 waypoints, circuit, walk (1.87 yd/s), 0 node(s) with a delay
SET @NPC := 166999;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6087.109,384.087,395.597,0,0,0,0,100,0),
(@PATH,2,-6088.327,388.927,395.597,0,0,0,0,100,0),
(@PATH,3,-6091.981,392.017,395.597,0,0,0,0,100,0),
(@PATH,4,-6097.097,394.399,395.597,0,0,0,0,100,0),
(@PATH,5,-6101.175,393.582,395.643,0,0,0,0,100,0),
(@PATH,6,-6105.891,389.401,395.597,0,0,0,0,100,0),
(@PATH,7,-6107.838,384.884,395.597,0,0,0,0,100,0),
(@PATH,8,-6106.488,378.385,395.597,0,0,0,0,100,0),
(@PATH,9,-6103.127,374.660,395.597,0,0,0,0,100,0),
(@PATH,10,-6097.207,372.309,395.647,0,0,0,0,100,0),
(@PATH,11,-6091.910,375.050,395.597,0,0,0,0,100,0),
(@PATH,12,-6087.655,378.986,395.597,0,0,0,0,100,0);

-- Coldridge Mountaineer (entry 853) -- retail spawn 50380967
--   matched guid 166972 at 0.005 yd from a route node (next candidate 3.7 yd)
--   23 waypoints, circuit, walk (2.25 yd/s), 1 node(s) with a delay
SET @NPC := 166972;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6117.872,375.622,395.597,0,0,0,0,100,0),
(@PATH,2,-6099.723,375.894,395.597,0,0,0,0,100,0),
(@PATH,3,-6099.202,377.140,395.597,0,7636,0,0,100,0),
(@PATH,4,-6093.382,374.979,395.597,0,0,0,0,100,0),
(@PATH,5,-6087.973,379.673,395.597,0,0,0,0,100,0),
(@PATH,6,-6088.800,388.061,395.597,0,0,0,0,100,0),
(@PATH,7,-6094.015,395.521,395.597,0,0,0,0,100,0),
(@PATH,8,-6101.135,395.008,395.597,0,0,0,0,100,0),
(@PATH,9,-6115.752,393.525,395.597,0,0,0,0,100,0),
(@PATH,10,-6127.311,392.842,395.597,0,0,0,0,100,0),
(@PATH,11,-6130.358,383.459,395.597,0,0,0,0,100,0),
(@PATH,12,-6155.236,383.909,395.597,0,0,0,0,100,0),
(@PATH,13,-6167.644,383.766,398.919,0,0,0,0,100,0),
(@PATH,14,-6174.323,376.123,398.238,0,0,0,0,100,0),
(@PATH,15,-6174.227,376.227,398.149,0,0,0,0,100,0),
(@PATH,16,-6178.788,365.716,398.695,0,0,0,0,100,0),
(@PATH,17,-6176.249,371.865,398.726,0,0,0,0,100,0),
(@PATH,18,-6168.106,383.946,398.869,0,0,0,0,100,0),
(@PATH,19,-6155.151,384.320,395.597,0,0,0,0,100,0),
(@PATH,20,-6130.428,383.783,395.597,0,0,0,0,100,0),
(@PATH,21,-6129.713,375.099,395.597,0,0,0,0,100,0),
(@PATH,22,-6129.787,376.002,395.597,0,0,0,0,100,0),
(@PATH,23,-6104.917,375.059,395.597,0,0,0,0,100,0);

-- Coldridge Citizen (entry 37218) -- retail spawn 92324011
--   matched guid 167012 at 0.002 yd from a route node (next candidate 1.9 yd)
--   25 waypoints, circuit, walk (2.34 yd/s), 2 node(s) with a delay
SET @NPC := 167012;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6067.972,393.330,392.800,0,0,0,0,100,0),
(@PATH,2,-6067.628,390.549,392.876,0,0,0,0,100,0),
(@PATH,3,-6070.247,385.453,393.718,0,0,0,0,100,0),
(@PATH,4,-6072.054,382.976,393.742,0,0,0,0,100,0),
(@PATH,5,-6074.472,382.807,393.597,0,0,0,0,100,0),
(@PATH,6,-6076.022,385.981,393.597,0,0,0,0,100,0),
(@PATH,7,-6078.624,381.453,393.597,0,0,0,0,100,0),
(@PATH,8,-6077.719,378.448,393.630,0,0,0,0,100,0),
(@PATH,9,-6080.438,375.686,393.597,0,0,0,0,100,0),
(@PATH,10,-6088.111,368.946,395.609,0,0,0,0,100,0),
(@PATH,11,-6095.624,368.960,395.620,0,0,0,0,100,0),
(@PATH,12,-6098.979,365.108,395.597,0,0,0,0,100,0),
(@PATH,13,-6102.101,363.615,395.597,0,19476,0,0,100,0),
(@PATH,14,-6097.103,366.309,395.597,0,0,0,0,100,0),
(@PATH,15,-6098.622,365.490,395.597,0,0,0,0,100,0),
(@PATH,16,-6081.212,374.755,394.027,0,0,0,0,100,0),
(@PATH,17,-6075.092,382.682,393.597,0,0,0,0,100,0),
(@PATH,18,-6070.757,382.821,393.650,0,0,0,0,100,0),
(@PATH,19,-6066.912,389.326,393.537,0,0,0,0,100,0),
(@PATH,20,-6067.550,394.507,392.800,0,0,0,0,100,0),
(@PATH,21,-6067.019,399.549,392.792,0,0,0,0,100,0),
(@PATH,22,-6064.043,399.736,392.850,0,0,0,0,100,0),
(@PATH,23,-6057.679,398.434,392.801,0,13120,0,0,100,0),
(@PATH,24,-6064.630,399.957,392.869,0,0,0,0,100,0),
(@PATH,25,-6067.635,399.628,392.795,0,0,0,0,100,0);

-- Coldridge Mountaineer (entry 853) -- retail spawn 33603751
--   matched guid 167026 at 6.166 yd from a route node (next candidate 13.9 yd)
--   7 waypoints, circuit, walk (2.49 yd/s), 1 node(s) with a delay, 4 unlinked node(s) dropped
--   WARNING: longest leg is 45 yd -- the dropped nodes probably carried the route between two ends, leaving a stub rather than a circuit
--   WARNING: spawn point sits 7 yd off the path -- the dropped nodes probably carried the route between two ends, leaving a stub rather than a circuit
SET @NPC := 167026;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6232.762,338.974,383.238,0,0,0,0,100,0),
(@PATH,2,-6225.120,345.355,383.451,0,1175,0,0,100,0),
(@PATH,3,-6218.737,364.024,385.571,0,0,0,0,100,0),
(@PATH,4,-6213.269,373.000,387.177,0,0,0,0,100,0),
(@PATH,5,-6199.655,378.702,390.182,0,0,0,0,100,0),
(@PATH,6,-6184.346,382.753,394.600,0,0,0,0,100,0),
(@PATH,7,-6221.236,358.794,384.928,0,0,0,0,100,0);

-- Coldridge Citizen (entry 37218) -- retail spawn 16826539
--   matched guid 167038 at 0.000 yd from a route node (next candidate 0.8 yd)
--   14 waypoints, circuit, walk (2.24 yd/s), 0 node(s) with a delay, 17 unlinked node(s) dropped
--   WARNING: longest leg is 32 yd -- the dropped nodes probably carried the route between two ends, leaving a stub rather than a circuit
SET @NPC := 167038;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6081.077,392.554,393.625,0,0,0,0,100,0),
(@PATH,2,-6079.957,383.828,393.597,0,0,0,0,100,0),
(@PATH,3,-6068.399,383.965,393.623,0,0,0,0,100,0),
(@PATH,4,-6067.812,389.477,393.559,0,0,0,0,100,0),
(@PATH,5,-6068.019,393.368,392.800,0,0,0,0,100,0),
(@PATH,6,-6061.660,393.167,392.800,0,0,0,0,100,0),
(@PATH,7,-6061.182,373.740,393.013,0,0,0,0,100,0),
(@PATH,8,-6061.187,373.922,392.800,0,0,0,0,100,0),
(@PATH,9,-6057.432,370.148,394.049,0,0,0,0,100,0),
(@PATH,10,-6055.415,370.240,395.200,0,0,0,0,100,0),
(@PATH,11,-6052.295,370.102,395.458,0,0,0,0,100,0),
(@PATH,12,-6052.057,373.281,395.644,0,0,0,0,100,0),
(@PATH,13,-6052.272,378.208,398.800,0,0,0,0,100,0),
(@PATH,14,-6052.104,380.988,398.988,0,0,0,0,100,0);

-- Rockjaw Goon (entry 37073) -- retail spawn 159459
--   matched guid 167220 at 0.003 yd from a route node (next candidate 4.4 yd)
--   28 waypoints, out-and-back round trip over 15 nodes, run (5.95 yd/s), 0 node(s) with a delay
SET @NPC := 167220;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6270.788,450.490,386.067,0,0,1,0,100,0),
(@PATH,2,-6287.556,449.660,385.665,0,0,1,0,100,0),
(@PATH,3,-6303.198,447.109,385.710,0,0,1,0,100,0),
(@PATH,4,-6318.872,438.510,381.301,0,0,1,0,100,0),
(@PATH,5,-6329.821,426.830,379.581,0,0,1,0,100,0),
(@PATH,6,-6342.580,416.611,377.730,0,0,1,0,100,0),
(@PATH,7,-6361.229,401.899,375.875,0,0,1,0,100,0),
(@PATH,8,-6364.457,384.545,379.323,0,0,1,0,100,0),
(@PATH,9,-6363.353,364.764,378.457,0,0,1,0,100,0),
(@PATH,10,-6359.606,346.500,379.521,0,0,1,0,100,0),
(@PATH,11,-6366.278,339.219,384.798,0,0,1,0,100,0),
(@PATH,12,-6372.587,335.236,386.049,0,0,1,0,100,0),
(@PATH,13,-6379.397,320.790,386.097,0,0,1,0,100,0),
(@PATH,14,-6384.077,300.424,386.770,0,0,1,0,100,0),
(@PATH,15,-6384.462,281.269,389.702,0,0,1,0,100,0),
(@PATH,16,-6384.077,300.424,386.770,0,0,1,0,100,0),
(@PATH,17,-6379.397,320.790,386.097,0,0,1,0,100,0),
(@PATH,18,-6372.587,335.236,386.049,0,0,1,0,100,0),
(@PATH,19,-6366.278,339.219,384.798,0,0,1,0,100,0),
(@PATH,20,-6359.606,346.500,379.521,0,0,1,0,100,0),
(@PATH,21,-6363.353,364.764,378.457,0,0,1,0,100,0),
(@PATH,22,-6364.457,384.545,379.323,0,0,1,0,100,0),
(@PATH,23,-6361.229,401.899,375.875,0,0,1,0,100,0),
(@PATH,24,-6342.580,416.611,377.730,0,0,1,0,100,0),
(@PATH,25,-6329.821,426.830,379.581,0,0,1,0,100,0),
(@PATH,26,-6318.872,438.510,381.301,0,0,1,0,100,0),
(@PATH,27,-6303.198,447.109,385.710,0,0,1,0,100,0),
(@PATH,28,-6287.556,449.660,385.665,0,0,1,0,100,0);

-- 9 paths, 137 waypoint rows total
