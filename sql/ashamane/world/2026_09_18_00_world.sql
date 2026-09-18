-- Teldrassil: the boars, the grellkin and the nightsabers of Shadowglen stand
-- where the 14 Sep sniff has them and roam as far. Young Thistle Boar 1984,
-- Thistle Boar 1985, Grellkin 1989, Young Nightsaber 2031, Mangy Nightsaber 2032
-- (zone 6450, areas 188/256); the box 9500-11000 x 400-1100 on map 1.
--
-- Method. Every sniffed guid of the five entries was folded into a spawn point:
-- retail gives a respawn a new guid low but puts it back on the exact same spot
-- (three Young Nightsaber lows all first seen at 10296.98, 902.09), so a point
-- seen twice is exact; otherwise the point is the median of the guid's own
-- walk positions (combat runs over 3.5 yd/s left out). Points and DB rows were
-- paired one-to-one within 20 yd. A paired row moves onto its point when it is
-- more than 8 yd off (2 yd for an exact point) and the point rests on at least
-- ten observed positions. A row nobody paired counts as absent on retail only
-- when the player stood within 60 yd of it for a while (view range in this
-- sniff is ~100 yd: median create distance 99, 90th percentile 104); such rows
-- are moved onto the nearest sniffed point that has no row (never further
-- than 60 yd) or, when none is left, deleted. Sniffed points with no row are
-- inserted. Rows the player never came within view of -- the SE corner around
-- 10590-10670 x 620-690, the south below y 580 and the NE grell camp at
-- 10480-10530 x 1020-1066 -- keep their positions.
--
-- Reach (95th-percentile displacement from the spawn's own centre, median
-- over the sniffed spawns):
--   Young Thistle Boar 16 yd (11 spawns, 12-19)   Thistle Boar 19 yd (24 spawns, 8-27)
--   Mangy Nightsaber   16 yd (24 spawns,  6-27)   Young Nightsaber 14 yd (51 spawns, 0-19)
--   Grellkin: two behaviours. The NW ridge camp (10310-10360 x 1015-1045, nine
--   spawns) mills about at 1-13 yd, median 3 -- the 3 yd it already has; the
--   scattered ones roam 18-36 yd, median 26.
-- The nightsabers keep the 13 / 15 yd from 2026_09_17_06. Every sniffed boar
-- and grellkin roams, none stands still, so the idle rows of those entries in
-- the zone start walking too, including the ones out of view. The one
-- exception is a Grellkin that stood on the rock above the NW camp
-- (10329.86, 1066.75, z 1359.97) for the two minutes it was in view: idle.
--
-- No row here has a creature_addon, and none of the templates has one.
-- Positions, deletes and inserts are outside what wpp_apply.py reverts: the
-- full rows as they were are in ~/movement-reverts/snapshot-20260918-2026_09_18_00-shadowglen-wildlife.sql.

-- 1. Idle rows start roaming at the species reach.
UPDATE `creature` SET `MovementType`=1, `wander_distance`=19 WHERE `id`=1985 AND `guid` IN (
    277384, 277536, 277539, 277541, 277668, 277700, 277798, 277992, 277996, 277997,
    278317, 278379, 278389);
UPDATE `creature` SET `MovementType`=1, `wander_distance`=3 WHERE `id`=1989 AND `guid` IN (
    277903, 277906, 278023);
UPDATE `creature` SET `MovementType`=1, `wander_distance`=25 WHERE `id`=1989 AND `guid` IN (
    277540, 277828, 277994);
UPDATE `creature` SET `MovementType`=1, `wander_distance`=15 WHERE `id`=2032 AND `guid` IN (
    277385, 277537, 277830, 277995, 278388);

-- 2. Roaming rows get the species reach (the nightsabers already have theirs).
UPDATE `creature` SET `wander_distance`=16 WHERE `id`=1984 AND `guid` IN (
    277611, 277832, 277852, 277854, 277864, 277917, 277954, 277967, 278071, 278290,
    278587);
UPDATE `creature` SET `wander_distance`=19 WHERE `id`=1985 AND `guid` IN (
    277365, 277533, 277535, 277544, 277560, 277566, 277595, 277621, 277626, 277699,
    277826, 277871, 277978, 278072, 278380, 278385, 278387);
UPDATE `creature` SET `wander_distance`=25 WHERE `id`=1989 AND `guid` IN (
    277617, 277644, 277669, 278588, 278625);

-- The Grellkin on the rock above the NW camp (moved there in 3.) never moved.
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0 WHERE `id`=1989 AND `guid` IN (277861);

-- 3. Rows onto their sniffed spawn point.
-- Young Thistle Boar 1984
UPDATE `creature` SET `position_x`=10281.326, `position_y`=730.672, `position_z`=1339.415 WHERE `guid`=277917;  -- 9.8 yd, centre of 91 positions, low 2665597
UPDATE `creature` SET `position_x`=10318.254, `position_y`=949.307, `position_z`=1331.171 WHERE `guid`=277954;  -- 11.6 yd, centre of 113 positions, low 2667431
UPDATE `creature` SET `position_x`=10368.015, `position_y`=710.731, `position_z`=1326.603 WHERE `guid`=277967;  -- 18.5 yd, centre of 146 positions, low 2665953
UPDATE `creature` SET `position_x`=10385.698, `position_y`=624.879, `position_z`=1327.68 WHERE `guid`=277832;  -- 15.5 yd, centre of 11 positions, low 2564349
UPDATE `creature` SET `position_x`=10433.377, `position_y`=920.114, `position_z`=1316.831 WHERE `guid`=278071;  -- 17.1 yd, centre of 70 positions, low 2660671
-- Thistle Boar 1985
UPDATE `creature` SET `position_x`=10488.449, `position_y`=984.943, `position_z`=1320.534 WHERE `guid`=277560;  -- 13.5 yd, centre of 12 positions, low 2558178
UPDATE `creature` SET `position_x`=10503.651, `position_y`=745.947, `position_z`=1313.805 WHERE `guid`=278317;  -- 9.8 yd, centre of 93 positions, low 2661869
UPDATE `creature` SET `position_x`=10514.423, `position_y`=675.73, `position_z`=1320.934 WHERE `guid`=277699;  -- 6.8 yd, exact point, low 2643731
UPDATE `creature` SET `position_x`=10525, `position_y`=940.006, `position_z`=1314.681 WHERE `guid`=277626;  -- 8.2 yd, centre of 148 positions, low 2631387
UPDATE `creature` SET `position_x`=10537.543, `position_y`=952.161, `position_z`=1317.074 WHERE `guid`=277595;  -- 9.2 yd, centre of 123 positions, low 2631394
UPDATE `creature` SET `position_x`=10617.298, `position_y`=777.846, `position_z`=1314.012 WHERE `guid`=277992;  -- 9.1 yd, centre of 44 positions, low 2660437
UPDATE `creature` SET `position_x`=10636.618, `position_y`=842.883, `position_z`=1311.834 WHERE `guid`=278389;  -- 10.6 yd, centre of 119 positions, low 2581069
UPDATE `creature` SET `position_x`=10644.819, `position_y`=749.911, `position_z`=1321.671 WHERE `guid`=277997;  -- 9.3 yd, centre of 27 positions, low 2660920
UPDATE `creature` SET `position_x`=10660.048, `position_y`=897.298, `position_z`=1319.904 WHERE `guid`=278380;  -- 45.0 yd, centre of 128 positions, low 2632335  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=10683.51, `position_y`=734.081, `position_z`=1324.068 WHERE `guid`=277535;  -- 12.9 yd, centre of 34 positions, low 2595607
UPDATE `creature` SET `position_x`=10686.944, `position_y`=939.999, `position_z`=1325.682 WHERE `guid`=277978;  -- 35.6 yd, centre of 96 positions, low 2668128  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=10717.977, `position_y`=849.405, `position_z`=1327.16 WHERE `guid`=277871;  -- 29.0 yd, centre of 74 positions, low 2581077  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=10766.828, `position_y`=763.316, `position_z`=1331.754 WHERE `guid`=277798;  -- 11.1 yd, centre of 35 positions, low 2544182
-- Grellkin 1989
UPDATE `creature` SET `position_x`=10329.857, `position_y`=1066.754, `position_z`=1359.965 WHERE `guid`=277861;  -- 28.4 yd, create position of low 2590408, which never moved (nothing stood at the old spot while the player was in the camp)
UPDATE `creature` SET `position_x`=10516.692, `position_y`=665.241, `position_z`=1321.903 WHERE `guid`=278588;  -- 12.2 yd, exact point, low 2652901
UPDATE `creature` SET `position_x`=10609.454, `position_y`=767.753, `position_z`=1313.537 WHERE `guid`=277994;  -- 20.7 yd, centre of 25 positions, low 2661735  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=10650.015, `position_y`=953.481, `position_z`=1326.775 WHERE `guid`=278625;  -- 12.3 yd, centre of 37 positions, low 2651720
UPDATE `creature` SET `position_x`=10700.859, `position_y`=860.442, `position_z`=1323.5 WHERE `guid`=277644;  -- 29.0 yd, centre of 50 positions, low 2661583  (nothing of its kind at the old spot while the player looked)
-- Young Nightsaber 2031
UPDATE `creature` SET `position_x`=10237.67, `position_y`=848.47, `position_z`=1345.52 WHERE `guid`=278159;  -- 4.5 yd, exact point: two were killed here and both respawns (2668975, 19446150) landed on this one spot, so two rows share it
UPDATE `creature` SET `position_x`=10237.67, `position_y`=848.47, `position_z`=1345.52 WHERE `guid`=277792;  -- 4.9 yd, exact point, the second row on that spot
UPDATE `creature` SET `position_x`=10265.887, `position_y`=721.43, `position_z`=1343.22 WHERE `guid`=278167;  -- 10.3 yd, centre of 92 positions, respawns 2665529, 2670081
UPDATE `creature` SET `position_x`=10280.36, `position_y`=910.55, `position_z`=1335.68 WHERE `guid`=278301;  -- 2.9 yd, exact point, respawns 2667923, 2668554, 2668884
UPDATE `creature` SET `position_x`=10291.513, `position_y`=856.759, `position_z`=1333.773 WHERE `guid`=278366;  -- 8.6 yd, exact point, respawns 2668154, 2668934
UPDATE `creature` SET `position_x`=10295.316, `position_y`=662.552, `position_z`=1338.853 WHERE `guid`=277887;  -- 11.4 yd, centre of 64 positions, low 2666107
UPDATE `creature` SET `position_x`=10302.618, `position_y`=874.571, `position_z`=1327.744 WHERE `guid`=278369;  -- 8.3 yd, exact point, low 27834758
UPDATE `creature` SET `position_x`=10310.02, `position_y`=925.131, `position_z`=1332.843 WHERE `guid`=278374;  -- 10.0 yd, centre of 37 positions, respawns 2668237, 27834799
UPDATE `creature` SET `position_x`=10354.047, `position_y`=658.356, `position_z`=1330.487 WHERE `guid`=277885;  -- 13.8 yd, centre of 58 positions, low 2651162
UPDATE `creature` SET `position_x`=10377.249, `position_y`=659.72, `position_z`=1327.05 WHERE `guid`=277966;  -- 9.7 yd, centre of 40 positions, low 2650966
UPDATE `creature` SET `position_x`=10378.394, `position_y`=617.426, `position_z`=1327.796 WHERE `guid`=277833;  -- 9.0 yd, centre of 17 positions, low 2628746
UPDATE `creature` SET `position_x`=10382.061, `position_y`=675.375, `position_z`=1325.836 WHERE `guid`=277965;  -- 11.3 yd, centre of 55 positions, low 27816615
UPDATE `creature` SET `position_x`=10417.49, `position_y`=666.16, `position_z`=1323.231 WHERE `guid`=277853;  -- 17.0 yd, centre of 29 positions, low 2641369
UPDATE `creature` SET `position_x`=10425.243, `position_y`=947.109, `position_z`=1320.079 WHERE `guid`=277795;  -- 17.3 yd, centre of 38 positions, low 2660749
-- Mangy Nightsaber 2032
UPDATE `creature` SET `position_x`=10503.103, `position_y`=647.081, `position_z`=1325.551 WHERE `guid`=277825;  -- 9.7 yd, exact point, low 2652890
UPDATE `creature` SET `position_x`=10508.389, `position_y`=700.802, `position_z`=1319.264 WHERE `guid`=277701;  -- 14.0 yd, centre of 49 positions, low 2485040
UPDATE `creature` SET `position_x`=10601.666, `position_y`=757.868, `position_z`=1316.58 WHERE `guid`=277995;  -- 38.0 yd, centre of 33 positions, low 2668634  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=10616.604, `position_y`=819.995, `position_z`=1309.163 WHERE `guid`=278386;  -- 12.7 yd, centre of 97 positions, low 2668298
UPDATE `creature` SET `position_x`=10624.621, `position_y`=726.222, `position_z`=1321.059 WHERE `guid`=277618;  -- 15.3 yd, centre of 24 positions, low 2657817
UPDATE `creature` SET `position_x`=10652.868, `position_y`=932.324, `position_z`=1318.993 WHERE `guid`=278383;  -- 24.3 yd, centre of 82 positions, low 2663426  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=10658.572, `position_y`=723.816, `position_z`=1326.502 WHERE `guid`=278388;  -- 56.4 yd, centre of 26 positions, low 2588534  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=10677.368, `position_y`=746.728, `position_z`=1322.456 WHERE `guid`=277999;  -- 8.0 yd, centre of 38 positions, low 2657884
UPDATE `creature` SET `position_x`=10695.993, `position_y`=949.902, `position_z`=1329.968 WHERE `guid`=277973;  -- 12.0 yd, centre of 81 positions, low 2554663
UPDATE `creature` SET `position_x`=10717.713, `position_y`=889.666, `position_z`=1328.101 WHERE `guid`=278073;  -- 54.1 yd, centre of 93 positions, low 2640343  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=10720.479, `position_y`=812.609, `position_z`=1326.056 WHERE `guid`=277646;  -- 9.8 yd, centre of 29 positions, low 2661674
UPDATE `creature` SET `position_x`=10760.436, `position_y`=792.157, `position_z`=1331.669 WHERE `guid`=277343;  -- 9.3 yd, centre of 49 positions, low 2544178

-- 4. Rows the player looked at for minutes with nothing there, and no sniffed
--    point left to give them.
DELETE FROM `creature` WHERE `guid`=278590;  -- Thistle Boar at 10545.4, 771.324: player within 42 yd, 207 position samples inside 60 yd
DELETE FROM `creature` WHERE `guid`=278024;  -- Grellkin at 10345.5, 1015.38: player within 19 yd, 186 position samples inside 60 yd

-- 5. Sniffed spawn points with no row.
DELETE FROM `creature` WHERE `guid` BETWEEN 300000161 AND 300000177;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(300000161,1985,1,6450,188,'0',0,0,0,-1,6807,0,10667.03,776.576,1320.778,6.0351,300,19,0,71,0,1,0,0,0,0,0,'',0),  -- Thistle Boar, centre, low 2658289
(300000162,1985,1,6450,188,'0',0,0,0,-1,6807,0,10698.909,867.109,1323.069,2.4746,300,19,0,71,0,1,0,0,0,0,0,'',0),  -- Thistle Boar, centre, low 2621139
(300000163,1989,1,6450,188,'0',0,0,0,-1,3023,0,10665.565,696.223,1329.196,0.1401,300,25,0,71,0,1,0,0,0,0,0,'',0),  -- Grellkin, centre, low 2544373
(300000164,2031,1,6450,188,'0',0,0,0,-1,11454,0,10288.794,793.483,1335.948,1.4921,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, centre, low 2667731, 2670261
(300000165,2031,1,6450,188,'0',0,0,0,-1,11454,0,10289.601,828.078,1334.979,3.3691,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, exact, respawns 2668035, 2668847
(300000166,2031,1,6450,188,'0',0,0,0,-1,11454,0,10296.98,902.09,1331.38,1.8996,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, exact, respawns 2668097, 2668538, 11057542
(300000167,2031,1,6450,188,'0',0,0,0,-1,11454,0,10303.153,792.382,1332.607,6.0543,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, centre, low 2667699, 2669933
(300000168,2031,1,6450,188,'0',0,0,0,-1,11454,0,10315.891,800.526,1329.471,5.1708,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, exact, respawns 2667776, 2670095
(300000169,2031,1,6450,188,'0',0,0,0,-1,11454,0,10316.223,877.915,1329.47,5.1438,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, centre, low 2668193
(300000170,2031,1,6450,188,'0',0,0,0,-1,11454,0,10318.254,881.432,1330.102,4.0909,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, exact, respawns 2668189, 11057583
(300000171,2031,1,6450,188,'0',0,0,0,-1,11454,0,10331.339,974.54,1332.783,5.1118,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, centre, low 2668649
(300000172,2031,1,6450,188,'0',0,0,0,-1,11454,0,10340.303,974.076,1331.649,3.7455,300,13,0,42,0,1,0,0,0,0,0,'',0),  -- Young Nightsaber, centre, low 2668610
(300000173,2032,1,6450,188,'0',0,0,0,-1,11448,0,10516.926,612.434,1332.449,5.6356,300,15,0,55,0,1,0,0,0,0,0,'',0),  -- Mangy Nightsaber, centre, low 2241418
(300000174,2032,1,6450,188,'0',0,0,0,-1,11448,0,10532.216,639.807,1326.065,1.2189,300,15,0,55,0,1,0,0,0,0,0,'',0),  -- Mangy Nightsaber, centre, low 2241440
(300000175,2032,1,6450,188,'0',0,0,0,-1,11448,0,10558.326,770.829,1312.762,4.5585,300,15,0,55,0,1,0,0,0,0,0,'',0),  -- Mangy Nightsaber, centre, low 2661861, 2668434
(300000176,2032,1,6450,188,'0',0,0,0,-1,11448,0,10576.494,776.556,1311.99,5.2315,300,15,0,55,0,1,0,0,0,0,0,'',0),  -- Mangy Nightsaber, centre, low 2667217, 2668471
(300000177,2032,1,6450,188,'0',0,0,0,-1,11448,0,10720.833,961.025,1331.193,2.8124,300,15,0,55,0,1,0,0,0,0,0,'',0);  -- Mangy Nightsaber, centre, low 2588262

-- @touched: creature 277343,277365,277384,277385,277533,277535,277536,277537,277539,277540,277541,277544,277560,277566,277595,277611,277617,277618,277621,277626,277644,277646,277668,277669,277699,277700,277701,277792,277795,277798,277825,277826,277828,277830,277832,277833,277852,277853,277854,277861,277864,277871,277885,277887,277903,277906,277917,277954,277965,277966,277967,277973,277978,277992,277994,277995,277996,277997,277999,278023,278024,278071,278072,278073,278159,278167,278290,278301,278317,278366,278369,278374,278379,278380,278383,278385,278386,278387,278388,278389,278587,278588,278590,278625
