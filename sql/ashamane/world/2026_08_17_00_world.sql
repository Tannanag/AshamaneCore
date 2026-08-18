-- Coldridge Valley: give nine spawns their retail patrol routes.
--
-- All nine stand still today (`MovementType` = 0, `wander_distance` = 0) on
-- spots where retail walks them a fixed route. 9 paths, 198 waypoints:
--
--   entry  NPC                     guid    path     rows  nodes  speed  shape
--     658  Sten Stoutarm         167020   1670200     3      3   walk   circuit
--   37087  Jona Ironstock        166999   1669990    12     12   walk   circuit
--     853  Coldridge Mountaineer 166975   1669750    15     15   walk   circuit
--     853  Coldridge Mountaineer 166972   1669720    46     19   walk   back-and-forth
--     853  Coldridge Mountaineer 167026   1670260    11     10   walk   back-and-forth
--   37218  Coldridge Citizen     167017   1670170     9      8   walk   back-and-forth
--   37218  Coldridge Citizen     167012   1670120    25     25   walk   circuit
--   37218  Coldridge Citizen     167038   1670380    49     27   walk   back-and-forth
--   37073  Rockjaw Goon          167220   1672200    28     15   RUN    back-and-forth
--
-- Where the coordinates come from
--
-- Two retail 12.1.0.69299 sniffs of the valley, 62,711 packets carrying 13,863
-- monster-moves over about 31 minutes, with each of these nine followed for at
-- least one full lap. WowPacketParser cannot read this build -- its
-- V12_1_0_69214 opcode tables are empty stubs upstream -- so the 0x5E0002 spline
-- payloads were decoded directly by `wpp_movement.py`, and the node order
-- recovered by `wpp_patrols.py`. Both are in the repo root; `wpp_patrols.py --sql`
-- regenerates every block below, so none of this is hand-transcribed.
--
-- A stored waypoint replays as the same float32 triple every lap while random
-- wander never repeats a coordinate exactly, which is what separates these nine
-- from the 111 wanderers in the same sniff.
--
-- Circuits and back-and-forth routes
--
-- Not every route is a loop. Four of these nine walk out along a line and turn
-- round at each end -- A B C B A rather than A B C A -- and the Rockjaw Goon's
-- line runs 200 yards, from (-6270.8, 450.5) down to (-6384.5, 281.3).
--
-- The order is taken from the sniff rather than inferred, which settles the
-- question outright: find a stretch running from some node back to that same
-- node, and that is one lap in the order the NPC actually walked it. A circuit
-- lists each node once, a back-and-forth lists its middle nodes twice, and
-- nothing has to decide in advance which it is looking at. Six of the nine come
-- straight from a gap-free lap of exactly this kind.
--
-- Two need more care. Where a lap spans a gap event the NPC moved unobserved in
-- the middle, so the nodes either side of the hole end up adjacent and the core
-- straight-lines between them; such a lap is used only when its geometry is
-- still plausible. And where no single lap was captured end to end, the route
-- can still be recovered from the maximum spanning tree over observed
-- transitions, which for a line is the line itself -- every node of degree 2
-- except the two ends. That is how the Goon is done: its ends are 200 yards
-- apart and never adjacent, and are visited 0.62 as often as its middle,
-- because each lap crosses the middle twice and touches each end once.
--
-- Back-and-forth routes are emitted as the full round trip, out and back
-- through the interior, because WaypointMovementGenerator.cpp:134 cycles a path
-- rather than ping-ponging it (`i_currentNode = (i_currentNode+1) % size`). A
-- one-way chain would teleport-walk the NPC home on every lap.
--
-- Candidates are filtered on geometry before anything else: no route here has a
-- leg over 24.9 yards, so one that does is missing a stretch whatever produced
-- it. Two nodes were dropped this way across all nine routes, one each from
-- 167017 and 167026, both reachable only across a 56 yard hole.
--
-- One waypoint, one node
--
-- A stored waypoint does not always replay as the same float32. Approached from
-- opposite directions it comes back a few centimetres off -- 0.09 yd between the
-- two spellings of one node on 167038 -- and taken literally that splits a single
-- waypoint into two nodes, each carrying half the visits. The emitted lap then
-- stops at one of the pair on the way out and the other on the way back, so the
-- route reads as though it is missing a point at exactly the spot where two
-- markers sit on top of each other.
--
-- Destinations within half a yard are therefore treated as one waypoint, keeping
-- the best-attested spelling. Real waypoints are never that close: after merging,
-- the nearest two distinct nodes on any of these routes are 0.52 yd apart. This
-- also readmits the single-visit spellings that the "seen more than once" rule
-- would otherwise discard as wander noise.
--
-- It matters most on 167038, which had four such pairs. Folding them turns its
-- 31 nodes into 27 real waypoints and, with the visits no longer split, a
-- gap-free lap covers the whole route for the first time -- longest leg 19.4 yd
-- against 23.2, closing leg 5.9 against 10.4. 166972 loses four the same way
-- (23 nodes to 19) and 167017 two.
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
-- Matching considers every recovered node, including any later dropped: where
-- the spawn sits is a question about identity, which nodes are safe to emit is
-- a question about ordering, and conflating the two loses the Rockjaw Goon.
--
-- Coldridge geometry is unchanged between 7.3.5 and 12.1.0, so the retail
-- coordinates go in as-is: no translation, no snapping.
--
-- Two spawns worth flagging
--
-- * 167026 is the one non-exact pairing, 6.17 yd from its nearest node with the
--   next candidate at 13.9 yd. It is also the least well observed of the nine --
--   the player was beyond 90 yd for 39% of its moves -- so it is the one route
--   here not backed by a close follow. Its emitted lap is clean and its longest
--   leg is 24.6 yd, but confirm the spawn with `.npc info` on the Mountaineer
--   near (-6183, 376) and revert that block if it is the wrong one.
-- * 167017 carried `creature_addon.StandState` = 3, so it sat. Retail walks it,
--   and the rest of its addon row was defaults, so the row is rewritten with
--   StandState 0. It was the only one of the nine with an addon row at all.
--
-- How each column was derived
--
--   position_x/y/z  float32 node coordinates in observed lap order
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
-- a median is trusted; below that it is written as no delay. On a back-and-forth
-- route a mid-route delay is written at both passes, which is what the NPC does.
--
-- Audit
--
-- * `waypoint_data` has no ids anywhere in the 1.66M-1.68M band, so the
--   guid * 10 path ids collide with nothing.
-- * All nine spawns confirmed still at `MovementType` = 0 and the coordinates
--   above before writing.
-- * Longest leg on any of the nine routes is 24.9 yd; every spawn point but
--   167026's falls on its own path to within 0.005 yd; and no two distinct nodes
--   on any route are closer than 0.52 yd.
-- * One node on 167038 is still visited once where its neighbours are visited
--   twice: (-6067.91, 390.68), which sits 1.43 yd from (-6067.81, 389.48) and so
--   overlaps it on screen. The sniff backs this up rather than contradicting it --
--   that coordinate was a destination 3 times against its neighbour's 5 -- so it
--   is left as observed. If it turns out in game that the NPC does stop there in
--   both directions, the second visit belongs between points 12 and 13.
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
--   matched guid 167017 at 0.001 yd from a route node (next candidate 5.5 yd)
--   9 waypoints, back-and-forth over 8 nodes via gap-free lap, walk (2.40 yd/s), 0 node(s) with a delay, 1 unlinked node(s) dropped
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
(@PATH,8,-6074.948,386.149,393.597,0,0,0,0,100,0),
(@PATH,9,-6081.568,392.512,393.689,0,0,0,0,100,0);

-- Coldridge Mountaineer (entry 853) -- retail spawn 49319
--   matched guid 166975 at 0.000 yd from a route node (next candidate 3.5 yd)
--   15 waypoints, circuit via gap-free lap, walk (2.40 yd/s), 1 node(s) with a delay
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
--   3 waypoints, circuit via gap-free lap, walk (2.41 yd/s), 0 node(s) with a delay
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
--   12 waypoints, circuit via gap-free lap, walk (1.87 yd/s), 0 node(s) with a delay
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
--   46 waypoints, back-and-forth over 19 nodes via gap-free lap, walk (2.25 yd/s), 1 node(s) with a delay
SET @NPC := 166972;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6104.917,375.059,395.597,0,0,0,0,100,0),
(@PATH,2,-6099.723,375.894,395.597,0,0,0,0,100,0),
(@PATH,3,-6099.202,377.140,395.597,0,7636,0,0,100,0),
(@PATH,4,-6093.382,374.979,395.597,0,0,0,0,100,0),
(@PATH,5,-6087.973,379.673,395.597,0,0,0,0,100,0),
(@PATH,6,-6088.800,388.061,395.597,0,0,0,0,100,0),
(@PATH,7,-6094.015,395.521,395.597,0,0,0,0,100,0),
(@PATH,8,-6101.135,395.008,395.597,0,0,0,0,100,0),
(@PATH,9,-6115.752,393.525,395.597,0,0,0,0,100,0),
(@PATH,10,-6127.311,392.842,395.597,0,0,0,0,100,0),
(@PATH,11,-6130.428,383.783,395.597,0,0,0,0,100,0),
(@PATH,12,-6155.236,383.909,395.597,0,0,0,0,100,0),
(@PATH,13,-6167.644,383.766,398.919,0,0,0,0,100,0),
(@PATH,14,-6174.323,376.123,398.238,0,0,0,0,100,0),
(@PATH,15,-6174.323,376.123,398.238,0,0,0,0,100,0),
(@PATH,16,-6178.788,365.716,398.695,0,0,0,0,100,0),
(@PATH,17,-6178.788,365.716,398.695,0,0,0,0,100,0),
(@PATH,18,-6176.249,371.865,398.726,0,0,0,0,100,0),
(@PATH,19,-6167.644,383.766,398.919,0,0,0,0,100,0),
(@PATH,20,-6155.236,383.909,395.597,0,0,0,0,100,0),
(@PATH,21,-6130.428,383.783,395.597,0,0,0,0,100,0),
(@PATH,22,-6129.713,375.099,395.597,0,0,0,0,100,0),
(@PATH,23,-6129.787,376.002,395.597,0,0,0,0,100,0),
(@PATH,24,-6117.872,375.622,395.597,0,0,0,0,100,0),
(@PATH,25,-6099.723,375.894,395.597,0,0,0,0,100,0),
(@PATH,26,-6099.202,377.140,395.597,0,7636,0,0,100,0),
(@PATH,27,-6093.382,374.979,395.597,0,0,0,0,100,0),
(@PATH,28,-6087.973,379.673,395.597,0,0,0,0,100,0),
(@PATH,29,-6088.800,388.061,395.597,0,0,0,0,100,0),
(@PATH,30,-6094.015,395.521,395.597,0,0,0,0,100,0),
(@PATH,31,-6101.135,395.008,395.597,0,0,0,0,100,0),
(@PATH,32,-6115.752,393.525,395.597,0,0,0,0,100,0),
(@PATH,33,-6127.311,392.842,395.597,0,0,0,0,100,0),
(@PATH,34,-6130.428,383.783,395.597,0,0,0,0,100,0),
(@PATH,35,-6155.236,383.909,395.597,0,0,0,0,100,0),
(@PATH,36,-6167.644,383.766,398.919,0,0,0,0,100,0),
(@PATH,37,-6174.323,376.123,398.238,0,0,0,0,100,0),
(@PATH,38,-6174.323,376.123,398.238,0,0,0,0,100,0),
(@PATH,39,-6178.788,365.716,398.695,0,0,0,0,100,0),
(@PATH,40,-6178.788,365.716,398.695,0,0,0,0,100,0),
(@PATH,41,-6176.249,371.865,398.726,0,0,0,0,100,0),
(@PATH,42,-6167.644,383.766,398.919,0,0,0,0,100,0),
(@PATH,43,-6155.236,383.909,395.597,0,0,0,0,100,0),
(@PATH,44,-6130.428,383.783,395.597,0,0,0,0,100,0),
(@PATH,45,-6129.713,375.099,395.597,0,0,0,0,100,0),
(@PATH,46,-6129.787,376.002,395.597,0,0,0,0,100,0);

-- Coldridge Citizen (entry 37218) -- retail spawn 92324011
--   matched guid 167012 at 0.002 yd from a route node (next candidate 1.9 yd)
--   25 waypoints, circuit via gap-free lap, walk (2.34 yd/s), 2 node(s) with a delay
SET @NPC := 167012;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6076.022,385.981,393.597,0,0,0,0,100,0),
(@PATH,2,-6078.624,381.453,393.597,0,0,0,0,100,0),
(@PATH,3,-6077.719,378.448,393.630,0,0,0,0,100,0),
(@PATH,4,-6080.438,375.686,393.597,0,0,0,0,100,0),
(@PATH,5,-6088.111,368.946,395.609,0,0,0,0,100,0),
(@PATH,6,-6095.624,368.960,395.620,0,0,0,0,100,0),
(@PATH,7,-6098.979,365.108,395.597,0,0,0,0,100,0),
(@PATH,8,-6102.101,363.615,395.597,0,19476,0,0,100,0),
(@PATH,9,-6097.103,366.309,395.597,0,0,0,0,100,0),
(@PATH,10,-6098.622,365.490,395.597,0,0,0,0,100,0),
(@PATH,11,-6081.212,374.755,394.027,0,0,0,0,100,0),
(@PATH,12,-6075.092,382.682,393.597,0,0,0,0,100,0),
(@PATH,13,-6070.757,382.821,393.650,0,0,0,0,100,0),
(@PATH,14,-6066.912,389.326,393.537,0,0,0,0,100,0),
(@PATH,15,-6067.550,394.507,392.800,0,0,0,0,100,0),
(@PATH,16,-6067.019,399.549,392.792,0,0,0,0,100,0),
(@PATH,17,-6064.043,399.736,392.850,0,0,0,0,100,0),
(@PATH,18,-6057.679,398.434,392.801,0,13120,0,0,100,0),
(@PATH,19,-6064.630,399.957,392.869,0,0,0,0,100,0),
(@PATH,20,-6067.635,399.628,392.795,0,0,0,0,100,0),
(@PATH,21,-6067.972,393.330,392.800,0,0,0,0,100,0),
(@PATH,22,-6067.628,390.549,392.876,0,0,0,0,100,0),
(@PATH,23,-6070.247,385.453,393.718,0,0,0,0,100,0),
(@PATH,24,-6072.054,382.976,393.742,0,0,0,0,100,0),
(@PATH,25,-6074.472,382.807,393.597,0,0,0,0,100,0);

-- Coldridge Mountaineer (entry 853) -- retail spawn 33603751
--   matched guid 167026 at 6.166 yd from a route node (next candidate 13.9 yd)
--   11 waypoints, back-and-forth over 10 nodes via gap-free lap, walk (2.49 yd/s), 1 node(s) with a delay, 1 unlinked node(s) dropped
SET @NPC := 167026;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6218.737,364.024,385.571,0,0,0,0,100,0),
(@PATH,2,-6213.269,373.000,387.177,0,0,0,0,100,0),
(@PATH,3,-6199.655,378.702,390.182,0,0,0,0,100,0),
(@PATH,4,-6184.346,382.753,394.600,0,0,0,0,100,0),
(@PATH,5,-6181.535,384.817,395.536,0,0,0,0,100,0),
(@PATH,6,-6187.376,381.038,393.550,0,0,0,0,100,0),
(@PATH,7,-6210.335,374.399,387.752,0,0,0,0,100,0),
(@PATH,8,-6221.236,358.794,384.928,0,0,0,0,100,0),
(@PATH,9,-6225.120,345.355,383.451,0,1175,0,0,100,0),
(@PATH,10,-6232.762,338.974,383.238,0,0,0,0,100,0),
(@PATH,11,-6225.120,345.355,383.451,0,1175,0,0,100,0);

-- Coldridge Citizen (entry 37218) -- retail spawn 16826539
--   matched guid 167038 at 0.000 yd from a route node (next candidate 0.8 yd)
--   49 waypoints, back-and-forth over 27 nodes via gap-free lap, walk (2.24 yd/s), 0 node(s) with a delay
SET @NPC := 167038;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6052.272,378.208,398.800,0,0,0,0,100,0),
(@PATH,2,-6052.104,380.988,398.988,0,0,0,0,100,0),
(@PATH,3,-6052.057,373.281,395.644,0,0,0,0,100,0),
(@PATH,4,-6052.295,370.102,395.458,0,0,0,0,100,0),
(@PATH,5,-6055.415,370.240,395.200,0,0,0,0,100,0),
(@PATH,6,-6057.432,370.148,394.049,0,0,0,0,100,0),
(@PATH,7,-6061.054,370.405,393.597,0,0,0,0,100,0),
(@PATH,8,-6058.500,370.233,393.707,0,0,0,0,100,0),
(@PATH,9,-6061.182,373.740,393.013,0,0,0,0,100,0),
(@PATH,10,-6061.660,393.167,392.800,0,0,0,0,100,0),
(@PATH,11,-6068.019,393.368,392.800,0,0,0,0,100,0),
(@PATH,12,-6067.913,390.681,392.800,0,0,0,0,100,0),
(@PATH,13,-6067.812,389.477,393.559,0,0,0,0,100,0),
(@PATH,14,-6068.399,383.965,393.623,0,0,0,0,100,0),
(@PATH,15,-6079.957,383.828,393.597,0,0,0,0,100,0),
(@PATH,16,-6081.066,392.474,393.588,0,0,0,0,100,0),
(@PATH,17,-6088.337,399.752,395.597,0,0,0,0,100,0),
(@PATH,18,-6096.200,397.608,395.597,0,0,0,0,100,0),
(@PATH,19,-6091.116,392.281,395.597,0,0,0,0,100,0),
(@PATH,20,-6087.005,383.484,395.597,0,0,0,0,100,0),
(@PATH,21,-6090.012,377.354,395.597,0,0,0,0,100,0),
(@PATH,22,-6097.653,368.788,395.597,0,0,0,0,100,0),
(@PATH,23,-6109.990,372.745,395.716,0,0,0,0,100,0),
(@PATH,24,-6120.653,375.186,395.597,0,0,0,0,100,0),
(@PATH,25,-6120.653,375.186,395.597,0,0,0,0,100,0),
(@PATH,26,-6130.132,383.755,395.597,0,0,0,0,100,0),
(@PATH,27,-6140.628,384.170,395.597,0,0,0,0,100,0),
(@PATH,28,-6130.132,383.755,395.597,0,0,0,0,100,0),
(@PATH,29,-6129.929,375.748,395.597,0,0,0,0,100,0),
(@PATH,30,-6120.653,375.186,395.597,0,0,0,0,100,0),
(@PATH,31,-6109.990,372.745,395.716,0,0,0,0,100,0),
(@PATH,32,-6097.653,368.788,395.597,0,0,0,0,100,0),
(@PATH,33,-6090.012,377.354,395.597,0,0,0,0,100,0),
(@PATH,34,-6087.005,383.484,395.597,0,0,0,0,100,0),
(@PATH,35,-6091.116,392.281,395.597,0,0,0,0,100,0),
(@PATH,36,-6096.200,397.608,395.597,0,0,0,0,100,0),
(@PATH,37,-6088.337,399.752,395.597,0,0,0,0,100,0),
(@PATH,38,-6081.066,392.474,393.588,0,0,0,0,100,0),
(@PATH,39,-6079.957,383.828,393.597,0,0,0,0,100,0),
(@PATH,40,-6068.399,383.965,393.623,0,0,0,0,100,0),
(@PATH,41,-6067.812,389.477,393.559,0,0,0,0,100,0),
(@PATH,42,-6068.019,393.368,392.800,0,0,0,0,100,0),
(@PATH,43,-6061.660,393.167,392.800,0,0,0,0,100,0),
(@PATH,44,-6061.182,373.740,393.013,0,0,0,0,100,0),
(@PATH,45,-6061.182,373.740,393.013,0,0,0,0,100,0),
(@PATH,46,-6057.432,370.148,394.049,0,0,0,0,100,0),
(@PATH,47,-6055.415,370.240,395.200,0,0,0,0,100,0),
(@PATH,48,-6052.295,370.102,395.458,0,0,0,0,100,0),
(@PATH,49,-6052.057,373.281,395.644,0,0,0,0,100,0);

-- Rockjaw Goon (entry 37073) -- retail spawn 159459
--   matched guid 167220 at 0.003 yd from a route node (next candidate 4.4 yd)
--   28 waypoints, back-and-forth over 15 nodes via spanning-tree line, run (5.95 yd/s), 0 node(s) with a delay
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

-- 9 paths, 198 waypoint rows total
