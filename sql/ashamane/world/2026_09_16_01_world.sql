-- Teldrassil: the 23 Wisps (48624) of Shadowglen and Dolanaar fly their retail
-- flight paths -- 15 closed loops and 8 rising helices -- instead of standing still.
--
-- In the 14 Sep sniff every 48624 (display 12769, DisableGravity, hover, AnimTier 3)
-- flies one fixed CatmullRom path at 8 yd/s, Forward, and never leaves it. 15 are
-- sent once, as a Cyclic spline inside the create block, and the server never sends
-- another movement packet for them: loops of 8-14 nodes, 2.3-14.2 s per lap, radius
-- 3-24 yd. The other 8 climb a helix around a tree trunk (10-16 nodes, 22-45 yd of
-- rise, 5.8-13.9 s): at the top the wisp gets SMSG_MOVE_UPDATE_TELEPORT back to the
-- foot and the same spline again, 0.3 s later, no hover. Chord length at 8 yd/s
-- reproduces every sniffed lap time to within 5%; the core measures along the curve,
-- so closer still.
--
-- The core has no cyclic waypoint mode, so npc_wisp_flight_path (zone_teldrassil.cpp)
-- drives the spline itself, reading the nodes from the waypoint_data path named in
-- creature_addon.path_id and launching it cyclic, fly, smooth, uncompressed -- the
-- packet the client got. A path whose closing leg is longer than 1.5x its longest leg
-- is a helix and is flown once, then the wisp is teleported back to node 1; for the
-- sniffed paths the two cases sit at <= 1.0x and >= 3.3x. The spawns keep
-- MovementType 0 so no generator calls StopMoving() under the spline; 4 of them
-- (277107,277130,277137,277261) were random walkers at radius 3 and stop being.
-- move_type 1 on the nodes records the speed (run = 8 yd/s); the script does not read it.
--
-- Each path's node 1 is the spawn point so a respawn starts on the path. 20 of the
-- 23 sniffed paths pass within 3.7 yd of an existing spawn (16 within 1.2 yd; the
-- four helix-top spawns 277107, 277130, 277137, 277261 sit on the last node of their
-- helix to 0.03 yd -- the old sniff caught them at the top). Those 20 spawns are moved
-- onto node 1: for a loop the node nearest the old position (no-op for the 0.01-0.04
-- yd matches), for a helix the foot. Three loops in Shadowglen proper have no spawn at
-- all (nearest 48624 20-64 yd away) and are added as 300000148,300000149,300000150
-- on their first node. 277185 and 277234 each stand between two near-identical loops
-- and take one; 277002 and 277280, unmatched before, take the partner loop.
--
-- Left alone: 277201 (9560, 739), outside the sniff's coverage, and the five 48624
-- spawns elsewhere on the map -- without a path row the script does nothing and they
-- behave as before. The per-spawn creature_addon rows copy the template addon
-- (AnimTier 3, SheathState 1) because a creature_addon row replaces it outright.
--
-- Needs a worldserver rebuild (new script) and restart. To undo the three new spawns:
-- DELETE FROM creature / creature_addon WHERE guid IN (300000148,300000149,300000150) and their
-- waypoint_data paths guid*10; the rest is in the wpp_apply revert.

UPDATE `creature_template` SET `ScriptName`='npc_wisp_flight_path' WHERE `entry`=48624;


-- The three loops with no spawn, on their first node, facing along the path.
DELETE FROM `creature` WHERE `guid` IN (300000148,300000149,300000150);
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(300000148,48624,1,6450,188,'0',0,0,0,-1,12769,0,10339.659,746.504,1334.215,3.0445,300,0,0,42,0,0,0,0,0,0,0,'',0),
(300000149,48624,1,6450,188,'0',0,0,0,-1,12769,0,10343.367,818.826,1333.387,4.5916,300,0,0,42,0,0,0,0,0,0,0,'',0),
(300000150,48624,1,6450,188,'0',0,0,0,-1,12769,0,10428.435,809.911,1331.067,3.0905,300,0,0,42,0,0,0,0,0,0,0,'',0);

-- The 20 existing spawns: onto node 1 of their path, idle for the script.
UPDATE `creature` SET `position_x`=9833.372, `position_y`=1004.26, `position_z`=1318.033, `wander_distance`=0, `MovementType`=0 WHERE `guid`=276864;  -- loop, moved 0.95 yd
UPDATE `creature` SET `position_x`=9763.646, `position_y`=947.602, `position_z`=1323.033, `wander_distance`=0, `MovementType`=0 WHERE `guid`=276869;  -- loop, moved 0.87 yd
UPDATE `creature` SET `position_x`=9826.116, `position_y`=829.814, `position_z`=1313.903, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277002;  -- loop, moved 0.28 yd
UPDATE `creature` SET `position_x`=9912.575, `position_y`=957.24, `position_z`=1313.866, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277050;  -- helix foot, moved 13.65 yd
UPDATE `creature` SET `position_x`=9794.689, `position_y`=856.381, `position_z`=1309.373, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277053;  -- loop, moved 0.01 yd
UPDATE `creature` SET `position_x`=9831.439, `position_y`=826.644, `position_z`=1323.083, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277054;  -- loop, moved 0.37 yd
UPDATE `creature` SET `position_x`=9846.251, `position_y`=874.769, `position_z`=1318.553, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277088;  -- loop, moved 0.04 yd
UPDATE `creature` SET `position_x`=10413.14, `position_y`=827.163, `position_z`=1317.569, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277107;  -- helix foot, moved 34.60 yd
UPDATE `creature` SET `position_x`=9868.917, `position_y`=988.043, `position_z`=1307.397, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277109;  -- helix foot, moved 14.38 yd
UPDATE `creature` SET `position_x`=9938.177, `position_y`=898.274, `position_z`=1317.104, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277130;  -- helix foot, moved 28.17 yd
UPDATE `creature` SET `position_x`=10364.229, `position_y`=878.986, `position_z`=1322.421, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277137;  -- helix foot, moved 45.96 yd
UPDATE `creature` SET `position_x`=10203.481, `position_y`=705.01, `position_z`=1378.347, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277162;  -- loop, moved 3.70 yd
UPDATE `creature` SET `position_x`=9856.502, `position_y`=1026.151, `position_z`=1307.331, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277183;  -- helix foot, moved 33.15 yd
UPDATE `creature` SET `position_x`=9829.285, `position_y`=827.275, `position_z`=1319.433, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277185;  -- loop, moved 1.20 yd
UPDATE `creature` SET `position_x`=10344.742, `position_y`=705.885, `position_z`=1341.449, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277205;  -- loop, moved 2.39 yd
UPDATE `creature` SET `position_x`=9827.833, `position_y`=930.208, `position_z`=1305.576, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277222;  -- helix foot, moved 17.71 yd
UPDATE `creature` SET `position_x`=9673.887, `position_y`=971.674, `position_z`=1307.384, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277234;  -- loop, moved 0.68 yd
UPDATE `creature` SET `position_x`=10446.362, `position_y`=888.109, `position_z`=1314.966, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277261;  -- helix foot, moved 44.72 yd
UPDATE `creature` SET `position_x`=9662.24, `position_y`=930.839, `position_z`=1301.96, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277277;  -- loop, moved 0.85 yd
UPDATE `creature` SET `position_x`=9679.1, `position_y`=974.072, `position_z`=1312.769, `wander_distance`=0, `MovementType`=0 WHERE `guid`=277280;  -- loop, moved 0.99 yd

DELETE FROM `creature_addon` WHERE `guid` IN (276864,276869,277002,277050,277053,277054,277088,277107,277109,277130,277137,277162,277183,277185,277205,277222,277234,277261,277277,277280,300000148,300000149,300000150);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(276864,2768640,0,0,3,0,1,0,0,0,0,0,0,NULL),
(276869,2768690,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277002,2770020,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277050,2770500,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277053,2770530,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277054,2770540,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277088,2770880,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277107,2771070,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277109,2771090,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277130,2771300,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277137,2771370,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277162,2771620,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277183,2771830,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277185,2771850,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277205,2772050,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277222,2772220,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277234,2772340,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277261,2772610,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277277,2772770,0,0,3,0,1,0,0,0,0,0,0,NULL),
(277280,2772800,0,0,3,0,1,0,0,0,0,0,0,NULL),
(300000148,3000001480,0,0,3,0,1,0,0,0,0,0,0,NULL),
(300000149,3000001490,0,0,3,0,1,0,0,0,0,0,0,NULL),
(300000150,3000001500,0,0,3,0,1,0,0,0,0,0,0,NULL);

DELETE FROM `waypoint_data` WHERE `id` IN (2768640,2768690,2770020,2770500,2770530,2770540,2770880,2771070,2771090,2771300,2771370,2771620,2771830,2771850,2772050,2772220,2772340,2772610,2772770,2772800,3000001480,3000001490,3000001500);
-- 276864: closed loop, 8 nodes, 7.7 s per lap in the sniff, centre (9828, 996)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2768640,1,9833.372,1004.26,1318.033,0,0,1,0,100,0),
(2768640,2,9837.597,997.878,1318.033,0,0,1,0,100,0),
(2768640,3,9836.07,990.378,1318.033,0,0,1,0,100,0),
(2768640,4,9829.688,986.154,1318.033,0,0,1,0,100,0),
(2768640,5,9822.188,987.68,1318.033,0,0,1,0,100,0),
(2768640,6,9817.964,994.062,1318.033,0,0,1,0,100,0),
(2768640,7,9819.489,1001.562,1318.033,0,0,1,0,100,0),
(2768640,8,9825.872,1005.786,1318.033,0,0,1,0,100,0);
-- 276869: closed loop, 8 nodes, 2.3 s per lap in the sniff, centre (9765, 950)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2768690,1,9763.646,947.602,1323.033,0,0,1,0,100,0),
(2768690,2,9765.935,947.422,1323.033,0,0,1,0,100,0),
(2768690,3,9767.68,948.913,1323.033,0,0,1,0,100,0),
(2768690,4,9767.86,951.202,1323.033,0,0,1,0,100,0),
(2768690,5,9766.369,952.948,1323.033,0,0,1,0,100,0),
(2768690,6,9764.08,953.128,1323.033,0,0,1,0,100,0),
(2768690,7,9762.334,951.637,1323.033,0,0,1,0,100,0),
(2768690,8,9762.154,949.348,1323.033,0,0,1,0,100,0);
-- 277002: closed loop, 8 nodes, 3.1 s per lap in the sniff, centre (9830, 831)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2770020,1,9826.116,829.814,1313.903,0,0,1,0,100,0),
(2770020,2,9826.09,832.875,1313.903,0,0,1,0,100,0),
(2770020,3,9828.235,835.059,1313.903,0,0,1,0,100,0),
(2770020,4,9831.297,835.085,1313.903,0,0,1,0,100,0),
(2770020,5,9833.48,832.939,1313.903,0,0,1,0,100,0),
(2770020,6,9833.507,829.878,1313.903,0,0,1,0,100,0),
(2770020,7,9831.361,827.695,1313.903,0,0,1,0,100,0),
(2770020,8,9828.3,827.668,1313.903,0,0,1,0,100,0);
-- 277050: helix, 22 yd rise, 10 nodes, 5.8 s per lap in the sniff, centre (9908, 956)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2770500,1,9912.575,957.24,1313.866,0,0,1,0,100,0),
(2770500,2,9911.826,958.097,1315.766,0,0,1,0,100,0),
(2770500,3,9908.778,960.311,1317.8,0,0,1,0,100,0),
(2770500,4,9904.91,959.939,1319.517,0,0,1,0,100,0),
(2770500,5,9901.988,956.269,1321.146,0,0,1,0,100,0),
(2770500,6,9904.101,950.974,1323.159,0,0,1,0,100,0),
(2770500,7,9909.511,950.826,1325.811,0,0,1,0,100,0),
(2770500,8,9911.582,955.035,1327.688,0,0,1,0,100,0),
(2770500,9,9907.11,957.995,1331.674,0,0,1,0,100,0),
(2770500,10,9903.02,954.778,1336.193,0,0,1,0,100,0);
-- 277053: closed loop, 8 nodes, 2.3 s per lap in the sniff, centre (9793, 859)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2770530,1,9794.689,856.381,1309.373,0,0,1,0,100,0),
(2770530,2,9792.5,855.691,1309.373,0,0,1,0,100,0),
(2770530,3,9790.463,856.751,1309.373,0,0,1,0,100,0),
(2770530,4,9789.772,858.941,1309.373,0,0,1,0,100,0),
(2770530,5,9790.833,860.978,1309.373,0,0,1,0,100,0),
(2770530,6,9793.022,861.668,1309.373,0,0,1,0,100,0),
(2770530,7,9795.06,860.608,1309.373,0,0,1,0,100,0),
(2770530,8,9795.75,858.418,1309.373,0,0,1,0,100,0);
-- 277054: closed loop, 8 nodes, 3.1 s per lap in the sniff, centre (9830, 830)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2770540,1,9831.439,826.644,1323.083,0,0,1,0,100,0),
(2770540,2,9828.381,826.51,1323.083,0,0,1,0,100,0),
(2770540,3,9826.124,828.578,1323.083,0,0,1,0,100,0),
(2770540,4,9825.99,831.637,1323.083,0,0,1,0,100,0),
(2770540,5,9828.059,833.894,1323.083,0,0,1,0,100,0),
(2770540,6,9831.117,834.028,1323.083,0,0,1,0,100,0),
(2770540,7,9833.374,831.959,1323.083,0,0,1,0,100,0),
(2770540,8,9833.508,828.901,1323.083,0,0,1,0,100,0);
-- 277088: closed loop, 8 nodes, 7.7 s per lap in the sniff, centre (9856, 877)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2770880,1,9846.251,874.769,1318.553,0,0,1,0,100,0),
(2770880,2,9850.91,868.697,1318.553,0,0,1,0,100,0),
(2770880,3,9858.498,867.697,1318.553,0,0,1,0,100,0),
(2770880,4,9864.57,872.357,1318.553,0,0,1,0,100,0),
(2770880,5,9865.569,879.945,1318.553,0,0,1,0,100,0),
(2770880,6,9860.91,886.017,1318.553,0,0,1,0,100,0),
(2770880,7,9853.322,887.016,1318.553,0,0,1,0,100,0),
(2770880,8,9847.25,882.357,1318.553,0,0,1,0,100,0);
-- 277107: helix, 35 yd rise, 14 nodes, 9.0 s per lap in the sniff, centre (10418, 826)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2771070,1,10413.14,827.163,1317.569,0,0,1,0,100,0),
(2771070,2,10414.105,828.391,1319.802,0,0,1,0,100,0),
(2771070,3,10417.162,830.882,1323.291,0,0,1,0,100,0),
(2771070,4,10422.998,829.684,1325.545,0,0,1,0,100,0),
(2771070,5,10424.07,824.222,1327.869,0,0,1,0,100,0),
(2771070,6,10420.705,820.918,1330.191,0,0,1,0,100,0),
(2771070,7,10415.636,821.585,1332.291,0,0,1,0,100,0),
(2771070,8,10413.991,826.438,1334.611,0,0,1,0,100,0),
(2771070,9,10418.097,829.986,1337.367,0,0,1,0,100,0),
(2771070,10,10422.735,828.391,1339.819,0,0,1,0,100,0),
(2771070,11,10422.816,823.79,1341.883,0,0,1,0,100,0),
(2771070,12,10420.131,820.76,1344.472,0,0,1,0,100,0),
(2771070,13,10415.037,821.314,1347.73,0,0,1,0,100,0),
(2771070,14,10415.275,827.601,1352.099,0,0,1,0,100,0);
-- 277109: helix, 26 yd rise, 11 nodes, 7.3 s per lap in the sniff, centre (9864, 992)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2771090,1,9868.917,988.043,1307.397,0,0,1,0,100,0),
(2771090,2,9869.58,990.368,1312.243,0,0,1,0,100,0),
(2771090,3,9868.353,994.142,1314.224,0,0,1,0,100,0),
(2771090,4,9863.091,997.019,1316.012,0,0,1,0,100,0),
(2771090,5,9859.313,992.698,1317.408,0,0,1,0,100,0),
(2771090,6,9860.803,986.516,1319.042,0,0,1,0,100,0),
(2771090,7,9866.129,987.371,1320.837,0,0,1,0,100,0),
(2771090,8,9867.957,992.019,1323.053,0,0,1,0,100,0),
(2771090,9,9864.594,995.99,1325.887,0,0,1,0,100,0),
(2771090,10,9860.837,995.127,1329.342,0,0,1,0,100,0),
(2771090,11,9856.931,990.627,1333.586,0,0,1,0,100,0);
-- 277130: helix, 28 yd rise, 11 nodes, 6.4 s per lap in the sniff, centre (9936, 895)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2771300,1,9938.177,898.274,1317.104,0,0,1,0,100,0),
(2771300,2,9937.024,898.809,1319.106,0,0,1,0,100,0),
(2771300,3,9935.028,898.741,1322.874,0,0,1,0,100,0),
(2771300,4,9931.689,894.988,1324.319,0,0,1,0,100,0),
(2771300,5,9933.521,891.198,1326.794,0,0,1,0,100,0),
(2771300,6,9938.138,892.012,1328.584,0,0,1,0,100,0),
(2771300,7,9939.212,895.979,1330.397,0,0,1,0,100,0),
(2771300,8,9935.202,898.575,1332.979,0,0,1,0,100,0),
(2771300,9,9931.509,895.391,1336.054,0,0,1,0,100,0),
(2771300,10,9934.985,891.068,1339.594,0,0,1,0,100,0),
(2771300,11,9939.022,893.056,1344.774,0,0,1,0,100,0);
-- 277137: helix, 45 yd rise, 16 nodes, 12.6 s per lap in the sniff, centre (10357, 880)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2771370,1,10364.229,878.986,1322.421,0,0,1,0,100,0),
(2771370,2,10363.273,882.457,1325.96,0,0,1,0,100,0),
(2771370,3,10360.935,885.578,1330.338,0,0,1,0,100,0),
(2771370,4,10352.851,884.352,1334.744,0,0,1,0,100,0),
(2771370,5,10348.829,880.28,1337.176,0,0,1,0,100,0),
(2771370,6,10350.844,874.052,1340.295,0,0,1,0,100,0),
(2771370,7,10357.816,871.983,1343.222,0,0,1,0,100,0),
(2771370,8,10360.815,878.109,1344.741,0,0,1,0,100,0),
(2771370,9,10358.698,883.514,1346.718,0,0,1,0,100,0),
(2771370,10,10352.971,885.045,1349.065,0,0,1,0,100,0),
(2771370,11,10349.4,879.448,1352.474,0,0,1,0,100,0),
(2771370,12,10351.507,874.401,1355.62,0,0,1,0,100,0),
(2771370,13,10357.556,874.045,1358.47,0,0,1,0,100,0),
(2771370,14,10361.302,877.873,1361.509,0,0,1,0,100,0),
(2771370,15,10362.516,882.328,1364.706,0,0,1,0,100,0),
(2771370,16,10356.476,885.913,1367.185,0,0,1,0,100,0);
-- 277162: closed loop, 9 nodes, 7.7 s per lap in the sniff, centre (10202, 695)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2771620,1,10203.481,705.01,1378.347,0,0,1,0,100,0),
(2771620,2,10203.747,697.802,1375.403,0,0,1,0,100,0),
(2771620,3,10199.27,692.057,1374.013,0,0,1,0,100,0),
(2771620,4,10198.944,686.221,1374.013,0,0,1,0,100,0),
(2771620,5,10203.842,685.575,1372.066,0,0,1,0,100,0),
(2771620,6,10208.347,689.319,1372.066,0,0,1,0,100,0),
(2771620,7,10207.995,693.981,1372.91,0,0,1,0,100,0),
(2771620,8,10197.723,698.774,1374.961,0,0,1,0,100,0),
(2771620,9,10198.319,705.344,1378.347,0,0,1,0,100,0);
-- 277183: helix, 38 yd rise, 11 nodes, 7.0 s per lap in the sniff, centre (9861, 1026)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2771830,1,9856.502,1026.151,1307.331,0,0,1,0,100,0),
(2771830,2,9856.666,1025.009,1309.879,0,0,1,0,100,0),
(2771830,3,9858.475,1023.094,1313.194,0,0,1,0,100,0),
(2771830,4,9862.396,1021.712,1316.978,0,0,1,0,100,0),
(2771830,5,9866.069,1025.406,1322.283,0,0,1,0,100,0),
(2771830,6,9865.936,1029.264,1325.043,0,0,1,0,100,0),
(2771830,7,9862.233,1032.266,1328.962,0,0,1,0,100,0),
(2771830,8,9858.242,1029.18,1332.876,0,0,1,0,100,0),
(2771830,9,9858.997,1024.123,1336.77,0,0,1,0,100,0),
(2771830,10,9863.633,1022.818,1341.783,0,0,1,0,100,0),
(2771830,11,9865.759,1026.05,1345.665,0,0,1,0,100,0);
-- 277185: closed loop, 8 nodes, 3.1 s per lap in the sniff, centre (9830, 831)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2771850,1,9829.285,827.275,1319.433,0,0,1,0,100,0),
(2771850,2,9832.262,827.99,1319.433,0,0,1,0,100,0),
(2771850,3,9833.861,830.6,1319.433,0,0,1,0,100,0),
(2771850,4,9833.146,833.577,1319.433,0,0,1,0,100,0),
(2771850,5,9830.536,835.177,1319.433,0,0,1,0,100,0),
(2771850,6,9827.56,834.462,1319.433,0,0,1,0,100,0),
(2771850,7,9825.96,831.852,1319.433,0,0,1,0,100,0),
(2771850,8,9826.675,828.875,1319.433,0,0,1,0,100,0);
-- 277205: closed loop, 13 nodes, 10.8 s per lap in the sniff, centre (10350, 704)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2772050,1,10344.742,705.885,1341.449,0,0,1,0,100,0),
(2772050,2,10340.81,700.616,1339.114,0,0,1,0,100,0),
(2772050,3,10342.533,696.457,1337.169,0,0,1,0,100,0),
(2772050,4,10347.712,696.648,1334.065,0,0,1,0,100,0),
(2772050,5,10356.123,701.783,1333.291,0,0,1,0,100,0),
(2772050,6,10357.533,711.51,1332.68,0,0,1,0,100,0),
(2772050,7,10353.271,713.196,1332.451,0,0,1,0,100,0),
(2772050,8,10348.353,708.941,1333.149,0,0,1,0,100,0),
(2772050,9,10347.653,704.111,1335.015,0,0,1,0,100,0),
(2772050,10,10351.339,701.047,1336.161,0,0,1,0,100,0),
(2772050,11,10353.536,700.438,1337.409,0,0,1,0,100,0),
(2772050,12,10354.955,707.302,1340.268,0,0,1,0,100,0),
(2772050,13,10351.08,710.236,1341.536,0,0,1,0,100,0);
-- 277222: helix, 30 yd rise, 11 nodes, 6.5 s per lap in the sniff, centre (9824, 927)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2772220,1,9827.833,930.208,1305.576,0,0,1,0,100,0),
(2772220,2,9825.441,930.984,1308.086,0,0,1,0,100,0),
(2772220,3,9823.399,930.667,1311.616,0,0,1,0,100,0),
(2772220,4,9819.862,927.575,1314.934,0,0,1,0,100,0),
(2772220,5,9821.206,922.851,1318.4,0,0,1,0,100,0),
(2772220,6,9826.19,922.083,1321.065,0,0,1,0,100,0),
(2772220,7,9829.198,925.132,1323.546,0,0,1,0,100,0),
(2772220,8,9826.269,929.469,1326.963,0,0,1,0,100,0),
(2772220,9,9822.224,929.882,1328.689,0,0,1,0,100,0),
(2772220,10,9820.125,927.205,1331.744,0,0,1,0,100,0),
(2772220,11,9820.519,921.661,1335.672,0,0,1,0,100,0);
-- 277234: closed loop, 8 nodes, 2.3 s per lap in the sniff, centre (9676, 974)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2772340,1,9673.887,971.674,1307.384,0,0,1,0,100,0),
(2772340,2,9673.046,973.81,1307.384,0,0,1,0,100,0),
(2772340,3,9673.961,975.916,1307.384,0,0,1,0,100,0),
(2772340,4,9676.098,976.758,1307.384,0,0,1,0,100,0),
(2772340,5,9678.203,975.842,1307.384,0,0,1,0,100,0),
(2772340,6,9679.045,973.706,1307.384,0,0,1,0,100,0),
(2772340,7,9678.129,971.6,1307.384,0,0,1,0,100,0),
(2772340,8,9675.993,970.759,1307.384,0,0,1,0,100,0);
-- 277261: helix, 43 yd rise, 18 nodes, 13.9 s per lap in the sniff, centre (10447, 895)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2772610,1,10446.362,888.109,1314.966,0,0,1,0,100,0),
(2772610,2,10448.091,887.53,1317.049,0,0,1,0,100,0),
(2772610,3,10451.285,888.776,1319.633,0,0,1,0,100,0),
(2772610,4,10452.353,896.788,1321.812,0,0,1,0,100,0),
(2772610,5,10449.308,901.521,1323.633,0,0,1,0,100,0),
(2772610,6,10442.724,901.559,1326.112,0,0,1,0,100,0),
(2772610,7,10439.342,896.262,1328.151,0,0,1,0,100,0),
(2772610,8,10442.474,890.972,1329.584,0,0,1,0,100,0),
(2772610,9,10450.107,890.621,1331.388,0,0,1,0,100,0),
(2772610,10,10452.301,896.028,1332.939,0,0,1,0,100,0),
(2772610,11,10448.079,901.83,1335.19,0,0,1,0,100,0),
(2772610,12,10442.731,901.257,1337.833,0,0,1,0,100,0),
(2772610,13,10440.476,895.403,1341.134,0,0,1,0,100,0),
(2772610,14,10444.042,891.292,1342.959,0,0,1,0,100,0),
(2772610,15,10450.263,890.417,1345.513,0,0,1,0,100,0),
(2772610,16,10452.625,897.062,1348.888,0,0,1,0,100,0),
(2772610,17,10448.518,901.387,1353.312,0,0,1,0,100,0),
(2772610,18,10442.018,900.858,1357.612,0,0,1,0,100,0);
-- 277277: closed loop, 14 nodes, 13.7 s per lap in the sniff, centre (9654, 928)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2772770,1,9662.24,930.839,1301.96,0,0,1,0,100,0),
(2772770,2,9659.31,933.941,1299.47,0,0,1,0,100,0),
(2772770,3,9656.33,935.035,1299.37,0,0,1,0,100,0),
(2772770,4,9648.28,933.104,1301.9,0,0,1,0,100,0),
(2772770,5,9646.39,927.262,1307.64,0,0,1,0,100,0),
(2772770,6,9648.88,921.696,1309.55,0,0,1,0,100,0),
(2772770,7,9654.07,918.689,1310.48,0,0,1,0,100,0),
(2772770,8,9660.33,920.774,1310.48,0,0,1,0,100,0),
(2772770,9,9662.52,929.736,1310.48,0,0,1,0,100,0),
(2772770,10,9654.28,936.446,1310.48,0,0,1,0,100,0),
(2772770,11,9647.23,932.66,1310.48,0,0,1,0,100,0),
(2772770,12,9645.86,926.271,1308.94,0,0,1,0,100,0),
(2772770,13,9651.54,919.078,1306.24,0,0,1,0,100,0),
(2772770,14,9659.92,921.219,1304.77,0,0,1,0,100,0);
-- 277280: closed loop, 8 nodes, 2.3 s per lap in the sniff, centre (9676, 973)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(2772800,1,9679.1,974.072,1312.769,0,0,1,0,100,0),
(2772800,2,9677.354,975.563,1312.769,0,0,1,0,100,0),
(2772800,3,9675.064,975.383,1312.769,0,0,1,0,100,0),
(2772800,4,9673.573,973.637,1312.769,0,0,1,0,100,0),
(2772800,5,9673.753,971.348,1312.769,0,0,1,0,100,0),
(2772800,6,9675.499,969.857,1312.769,0,0,1,0,100,0),
(2772800,7,9677.788,970.037,1312.769,0,0,1,0,100,0),
(2772800,8,9679.279,971.783,1312.769,0,0,1,0,100,0);
-- 300000148: closed loop, 14 nodes, 10.3 s per lap in the sniff, centre (10335, 744)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(3000001480,1,10339.659,746.504,1334.215,0,0,1,0,100,0),
(3000001480,2,10336.292,746.832,1334.549,0,0,1,0,100,0),
(3000001480,3,10329.271,744.684,1334.549,0,0,1,0,100,0),
(3000001480,4,10329.003,741.535,1333.253,0,0,1,0,100,0),
(3000001480,5,10332.361,740.234,1333.347,0,0,1,0,100,0),
(3000001480,6,10335.872,746.899,1336.523,0,0,1,0,100,0),
(3000001480,7,10341.161,747.094,1339.16,0,0,1,0,100,0),
(3000001480,8,10342.8,742.071,1340.947,0,0,1,0,100,0),
(3000001480,9,10337.369,738.123,1340.969,0,0,1,0,100,0),
(3000001480,10,10328.47,740.826,1339.324,0,0,1,0,100,0),
(3000001480,11,10327.908,745.557,1337.878,0,0,1,0,100,0),
(3000001480,12,10332.898,746.521,1335.662,0,0,1,0,100,0),
(3000001480,13,10338.035,740.726,1334.09,0,0,1,0,100,0),
(3000001480,14,10340.536,742.929,1332.333,0,0,1,0,100,0);
-- 300000149: closed loop, 10 nodes, 8.5 s per lap in the sniff, centre (10347, 815)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(3000001490,1,10343.367,818.826,1333.387,0,0,1,0,100,0),
(3000001490,2,10342.868,814.715,1332.43,0,0,1,0,100,0),
(3000001490,3,10344.305,808.264,1331.617,0,0,1,0,100,0),
(3000001490,4,10352.113,809.589,1331.98,0,0,1,0,100,0),
(3000001490,5,10351.073,818.634,1327.35,0,0,1,0,100,0),
(3000001490,6,10345.139,820.078,1327.35,0,0,1,0,100,0),
(3000001490,7,10342.41,814.589,1327.35,0,0,1,0,100,0),
(3000001490,8,10347.016,810.865,1330.664,0,0,1,0,100,0),
(3000001490,9,10352.333,813.911,1331.321,0,0,1,0,100,0),
(3000001490,10,10349.232,819.776,1332.305,0,0,1,0,100,0);
-- 300000150: closed loop, 12 nodes, 14.2 s per lap in the sniff, centre (10414, 796)
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(3000001500,1,10428.435,809.911,1331.067,0,0,1,0,100,0),
(3000001500,2,10424.993,810.087,1330.872,0,0,1,0,100,0),
(3000001500,3,10419.873,803.292,1330.416,0,0,1,0,100,0),
(3000001500,4,10417.881,793.295,1330.416,0,0,1,0,100,0),
(3000001500,5,10408.223,788.95,1329.266,0,0,1,0,100,0),
(3000001500,6,10396.814,788.458,1327.848,0,0,1,0,100,0),
(3000001500,7,10394.913,782.283,1326.833,0,0,1,0,100,0),
(3000001500,8,10402.804,781.123,1328.052,0,0,1,0,100,0),
(3000001500,9,10407.384,792.828,1329.453,0,0,1,0,100,0),
(3000001500,10,10409.64,800.46,1329.453,0,0,1,0,100,0),
(3000001500,11,10429.028,798.549,1330.804,0,0,1,0,100,0),
(3000001500,12,10432.188,803.286,1331.067,0,0,1,0,100,0);

-- @touched: creature_template,creature,creature_addon,waypoint_data 276864,276869,277002,277050,277053,277054,277088,277107,277109,277130,277137,277162,277183,277185,277205,277222,277234,277261,277277,277280
