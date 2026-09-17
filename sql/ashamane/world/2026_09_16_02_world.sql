-- Teldrassil: the five patrolling Shadowglen Sentinels (12160) walk the routes
-- sniffed on 14 Sep; the three hand-added wandering sentinels go.
--
-- The 14 Sep sniff shows 20 sentinels in Shadowglen. 15 never move, and all 15
-- stand on a server spawn to the centimetre, orientation included. The other 5
-- patrol at walk speed (2.4-2.5 yd/s) with no pauses, each on a line walked out
-- and back; wpp_patrols.py recovered every route with verdict "complete", and the
-- halves it reported as disconnected fragments are the same line's other end,
-- joined here in walking order (no leg on any route is longer than 29 yd).
--
-- The server had four of the five on paths written from an older sniff, and the
-- node count differed on every one. The differences that matter:
--   * 276632 (ramp foot) turned round at 10452,798; retail turns at 10446,799.
--   * 276628 (upper ramp) had MovementType 2 but no creature_addon row, so it
--     never walked its path 2766280 -- which also carried a spur to 10449,841
--     that retail does not walk (the line ends at 10444,829).
--   * 277063 (north arc) started its path at the far end of the line, 72 yd
--     from where it spawns, and had one 92-yd straight leg from 10323,827 to
--     10368,747 where retail walks four stops along the curve.
--   * 276892 (east loop) is the same two-terrace line as before with the
--     retail stops; 277061 (west terrace) likewise.
-- Every path now starts at the node nearest the spawn point (0.0-8.5 yd; the
-- old ones began 18-72 yd away on three of the four), so a respawn joins the
-- route where it stands instead of crossing the glade first.
--
-- The addon rows carry the template addon's PvPFlags 1 and aura 18950, which
-- is what the sniff shows on all 20 (PvpFlags 1, SheatheState 1); the four old
-- rows had PvPFlags 0. 18950 is also cast by the SmartAI respawn row, as on
-- retail, so nothing changes there.
--
-- Spawns 36, 37 and 38 -- three MovementType 1 / wander 10 sentinels at
-- (10313,816), (10413,732), (10349,751) -- are not in the sniff at all; they are
-- the only sentinels with two-digit guids and were added by hand at some point.
-- Nothing references them (no addon, pool, event, linked respawn or formation).
--
-- Needs a worldserver restart (or `.reload waypoint_data` plus a respawn of the
-- five) to take effect.

-- ramp foot: guid 276632 <- sniffed spawn 69332786. 16 stops per lap, out-and-back over 9 nodes, walk (2.37 yd/s), no pauses.
--   point 1 is the node nearest the spawn point (1.1 yd); was MovementType 2, path 2766320 with 11 waypoints.
SET @NPC := 276632;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,1,0,0,0,0,0,'18950');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,10405.816,759.783,1322.878,0,0,0,0,100,0),
(@PATH,2,10417.354,764.714,1329.045,0,0,0,0,100,0),
(@PATH,3,10427.927,771.281,1335.682,0,0,0,0,100,0),
(@PATH,4,10433.189,776.627,1337.424,0,0,0,0,100,0),
(@PATH,5,10429.604,784.630,1337.394,0,0,0,0,100,0),
(@PATH,6,10430.961,789.165,1338.268,0,0,0,0,100,0),
(@PATH,7,10436.986,793.371,1342.777,0,0,0,0,100,0),
(@PATH,8,10442.317,797.216,1345.858,0,0,0,0,100,0),
(@PATH,9,10446.112,798.976,1345.827,0,0,0,0,100,0),
(@PATH,10,10442.317,797.216,1345.858,0,0,0,0,100,0),
(@PATH,11,10436.986,793.371,1342.777,0,0,0,0,100,0),
(@PATH,12,10430.961,789.165,1338.268,0,0,0,0,100,0),
(@PATH,13,10429.604,784.630,1337.394,0,0,0,0,100,0),
(@PATH,14,10433.189,776.627,1337.424,0,0,0,0,100,0),
(@PATH,15,10427.927,771.281,1335.682,0,0,0,0,100,0),
(@PATH,16,10417.354,764.714,1329.045,0,0,0,0,100,0);

-- upper ramp: guid 276628 <- sniffed spawn 77721394. 14 stops per lap, out-and-back over 8 nodes, walk (2.48 yd/s), no pauses.
--   point 1 is the node nearest the spawn point (0.0 yd); was MovementType 2, path_id NULL (orphan path 2766280 with 11 waypoints).
SET @NPC := 276628;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,1,0,0,0,0,0,'18950');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,10445.455,820.755,1382.649,0,0,0,0,100,0),
(@PATH,2,10451.341,809.910,1385.256,0,0,0,0,100,0),
(@PATH,3,10462.006,798.365,1389.267,0,0,0,0,100,0),
(@PATH,4,10474.851,790.116,1393.196,0,0,0,0,100,0),
(@PATH,5,10487.661,785.865,1395.948,0,0,0,0,100,0),
(@PATH,6,10501.587,787.121,1397.987,0,0,0,0,100,0),
(@PATH,7,10510.066,795.694,1397.297,0,0,0,0,100,0),
(@PATH,8,10501.587,787.121,1397.987,0,0,0,0,100,0),
(@PATH,9,10487.661,785.865,1395.948,0,0,0,0,100,0),
(@PATH,10,10474.851,790.116,1393.196,0,0,0,0,100,0),
(@PATH,11,10462.006,798.365,1389.267,0,0,0,0,100,0),
(@PATH,12,10451.341,809.910,1385.256,0,0,0,0,100,0),
(@PATH,13,10445.455,820.755,1382.649,0,0,0,0,100,0),
(@PATH,14,10443.783,829.425,1381.237,0,0,0,0,100,0);

-- west terrace: guid 277061 <- sniffed spawn 35778354. 22 stops per lap, out-and-back over 12 nodes, walk (2.47 yd/s), no pauses.
--   point 1 is the node nearest the spawn point (4.1 yd); was MovementType 2, path 2770610 with 13 waypoints.
SET @NPC := 277061;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,1,0,0,0,0,0,'18950');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,10485.064,800.681,1326.987,0,0,0,0,100,0),
(@PATH,2,10474.417,799.073,1323.447,0,0,0,0,100,0),
(@PATH,3,10465.082,800.035,1322.796,0,0,0,0,100,0),
(@PATH,4,10455.283,795.333,1322.638,0,0,0,0,100,0),
(@PATH,5,10440.623,788.924,1322.800,0,0,0,0,100,0),
(@PATH,6,10426.856,783.286,1322.800,0,0,0,0,100,0),
(@PATH,7,10416.022,777.809,1322.800,0,0,0,0,100,0),
(@PATH,8,10404.795,770.608,1322.800,0,0,0,0,100,0),
(@PATH,9,10416.022,777.809,1322.800,0,0,0,0,100,0),
(@PATH,10,10426.856,783.286,1322.800,0,0,0,0,100,0),
(@PATH,11,10440.623,788.924,1322.800,0,0,0,0,100,0),
(@PATH,12,10455.283,795.333,1322.638,0,0,0,0,100,0),
(@PATH,13,10465.082,800.035,1322.796,0,0,0,0,100,0),
(@PATH,14,10474.417,799.073,1323.447,0,0,0,0,100,0),
(@PATH,15,10485.064,800.681,1326.987,0,0,0,0,100,0),
(@PATH,16,10496.138,797.726,1328.904,0,0,0,0,100,0),
(@PATH,17,10503.306,796.536,1330.597,0,0,0,0,100,0),
(@PATH,18,10511.463,791.075,1330.335,0,0,0,0,100,0),
(@PATH,19,10523.547,781.276,1329.597,0,0,0,0,100,0),
(@PATH,20,10511.463,791.075,1330.335,0,0,0,0,100,0),
(@PATH,21,10503.306,796.536,1330.597,0,0,0,0,100,0),
(@PATH,22,10496.138,797.726,1328.904,0,0,0,0,100,0);

-- east loop, both terraces: guid 276892 <- sniffed spawn 2562365. 28 stops per lap, out-and-back over 15 nodes, walk (2.46 yd/s), no pauses.
--   point 1 is the node nearest the spawn point (4.7 yd); was MovementType 2, path 2768920 with 17 waypoints.
SET @NPC := 276892;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,1,0,0,0,0,0,'18950');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,10519.009,833.621,1353.631,0,0,0,0,100,0),
(@PATH,2,10511.828,845.436,1349.909,0,0,0,0,100,0),
(@PATH,3,10500.054,854.248,1345.933,0,0,0,0,100,0),
(@PATH,4,10485.087,857.690,1342.440,0,0,0,0,100,0),
(@PATH,5,10469.702,858.026,1340.588,0,0,0,0,100,0),
(@PATH,6,10456.098,862.431,1335.977,0,0,0,0,100,0),
(@PATH,7,10442.261,870.849,1329.453,0,0,0,0,100,0),
(@PATH,8,10423.300,882.081,1321.478,0,0,0,0,100,0),
(@PATH,9,10442.261,870.849,1329.453,0,0,0,0,100,0),
(@PATH,10,10456.098,862.431,1335.977,0,0,0,0,100,0),
(@PATH,11,10469.702,858.026,1340.588,0,0,0,0,100,0),
(@PATH,12,10485.087,857.690,1342.440,0,0,0,0,100,0),
(@PATH,13,10500.054,854.248,1345.933,0,0,0,0,100,0),
(@PATH,14,10511.828,845.436,1349.909,0,0,0,0,100,0),
(@PATH,15,10519.009,833.621,1353.631,0,0,0,0,100,0),
(@PATH,16,10520.216,821.663,1354.800,0,0,0,0,100,0),
(@PATH,17,10513.525,820.217,1354.800,0,0,0,0,100,0),
(@PATH,18,10507.745,829.045,1357.555,0,0,0,0,100,0),
(@PATH,19,10499.130,840.330,1363.547,0,0,0,0,100,0),
(@PATH,20,10485.363,846.760,1369.424,0,0,0,0,100,0),
(@PATH,21,10468.203,848.365,1376.254,0,0,0,0,100,0),
(@PATH,22,10452.147,844.767,1380.405,0,0,0,0,100,0),
(@PATH,23,10468.203,848.365,1376.254,0,0,0,0,100,0),
(@PATH,24,10485.363,846.760,1369.424,0,0,0,0,100,0),
(@PATH,25,10499.130,840.330,1363.547,0,0,0,0,100,0),
(@PATH,26,10507.745,829.045,1357.555,0,0,0,0,100,0),
(@PATH,27,10513.525,820.217,1354.800,0,0,0,0,100,0),
(@PATH,28,10520.216,821.663,1354.800,0,0,0,0,100,0);

-- north arc: guid 277063 <- sniffed spawn 19001138. 22 stops per lap, out-and-back over 12 nodes, walk (2.48 yd/s), no pauses.
--   point 1 is the node nearest the spawn point (8.5 yd); was MovementType 2, path 2770630 with 11 waypoints.
SET @NPC := 277063;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,1,0,0,0,0,0,'18950');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,10347.450,844.352,1325.405,0,0,0,0,100,0),
(@PATH,2,10328.667,831.215,1326.337,0,0,0,0,100,0),
(@PATH,3,10325.589,821.991,1326.135,0,0,0,0,100,0),
(@PATH,4,10340.778,798.240,1324.811,0,0,0,0,100,0),
(@PATH,5,10351.899,782.269,1324.110,0,0,0,0,100,0),
(@PATH,6,10360.014,758.783,1322.372,0,0,0,0,100,0),
(@PATH,7,10367.790,749.043,1321.507,0,0,0,0,100,0),
(@PATH,8,10360.014,758.783,1322.372,0,0,0,0,100,0),
(@PATH,9,10351.899,782.269,1324.110,0,0,0,0,100,0),
(@PATH,10,10340.778,798.240,1324.811,0,0,0,0,100,0),
(@PATH,11,10325.589,821.991,1326.135,0,0,0,0,100,0),
(@PATH,12,10328.667,831.215,1326.337,0,0,0,0,100,0),
(@PATH,13,10347.450,844.352,1325.405,0,0,0,0,100,0),
(@PATH,14,10359.669,855.394,1325.076,0,0,0,0,100,0),
(@PATH,15,10365.249,864.411,1324.968,0,0,0,0,100,0),
(@PATH,16,10380.802,872.760,1324.280,0,0,0,0,100,0),
(@PATH,17,10397.032,883.698,1321.329,0,0,0,0,100,0),
(@PATH,18,10414.783,885.688,1319.284,0,0,0,0,100,0),
(@PATH,19,10397.032,883.698,1321.329,0,0,0,0,100,0),
(@PATH,20,10380.802,872.760,1324.280,0,0,0,0,100,0),
(@PATH,21,10365.249,864.411,1324.968,0,0,0,0,100,0),
(@PATH,22,10359.669,855.394,1325.076,0,0,0,0,100,0);

-- The three wandering sentinels that exist on no retail sniff.
DELETE FROM `creature_addon` WHERE `guid` IN (36,37,38);
DELETE FROM `creature` WHERE `guid` IN (36,37,38) AND `id`=12160;

-- 5 paths, 102 waypoint rows total; 3 spawns removed
-- @touched: creature,creature_addon,waypoint_data 276632,276628,277061,276892,277063
