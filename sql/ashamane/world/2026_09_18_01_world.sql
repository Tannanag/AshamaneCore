-- Teldrassil, Dolanaar: the Ancient Protector and the one Teldrassil Sentinel
-- who patrol walk the routes sniffed on 14 Sep (zone 141, area 186).
--
-- Ancient Protector 2041, guid 277016. The sniff has him on a 43-stop closed
-- loop, 2.5 yd/s, no pauses, every stop hit in order on every lap (two full laps
-- and a third one started): up the east side of Dolanaar from (9744,942) to
-- (9854,1061) and back down the west, with a real out-and-back spur to (9876,847)
-- south of the bank -- stops 14-16 double back on the same line and are kept.
-- The server spawn is stop 25 of that loop to the decimetre, so the path starts
-- there and the spawn keeps its position; it only changes MovementType 0 -> 2
-- (the template already says 2) and gets the addon row that carries the path.
-- One lap is 608 yd, about 4.1 min at walk speed.
--
-- While he walks he plays sound kit 6528 (the tree's creak), 19 times in the 21
-- minutes he was in view, 21-45 s apart, as SMSG_PLAY_OBJECT_SOUND placed at
-- his current position. SMART_ACTION_SOUND grew a third parameter for that
-- packet (2 = object sound) in the same commit; 0 would send SMSG_PLAY_SOUND,
-- which the client does not attenuate, so everyone in Dolanaar would hear the
-- creak at full volume every half minute. The entry's two combat rows (Entangling
-- Roots, War Stomp) are what Wowhead lists and stay.
--
-- Teldrassil Sentinel 3571, guid 277070. Eleven sentinels stand in Dolanaar in
-- the sniff; ten never move and each matches a server row (277023's sleep and
-- 276637/277067's emotes included). The eleventh walks from the inn door
-- (9841,966) west along the road to (9767,924) and back, 2.5 yd/s, at least
-- five laps. 277070 at (9808,956) is the only server sentinel nothing in the
-- sniff stands on and it is 6 yd off that road, so it becomes the patroller:
-- moved onto the inn-door end, facing down the road. The route is 9 stops out;
-- on the way back retail walks from the west end straight to stop 7 (stop 8
-- lies on that line) and then the same stops in reverse. Every turnaround at
-- either end that the sniff caught (four at each) is 0.1-0.4 s, i.e. no pause:
-- the tool's 86 / 20 yd "legs" on the end stops are the turnaround, and the
-- 8 s the todo mentions is a missing 0->1 packet at 00:09:27, not a stop. A
-- 35 s halt near stop 5 at 00:11:19 is a one-off (player interaction) and is
-- not scripted.
--
-- Both carry PvpFlags 1 / SheatheState 1 in the sniff, as the addon rows say.
-- Needs a worldserver restart (new binary for the sound parameter; the paths
-- alone would take `.reload waypoint_data` + `.reload smart_scripts` and a
-- respawn of the two).

-- Ancient Protector: guid 277016 <- sniffed spawn 2223922. 43 stops per lap, closed loop, walk (2.50 yd/s), no pauses.
--   point 1 is the spawn point (stop 25 of the sniffed loop, 0.0 yd); was MovementType 0, no addon row, no path.
SET @NPC := 277016;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,1,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,9848.224,980.791,1305.147,0,0,0,0,100,0),
(@PATH,2,9846.400,995.745,1305.428,0,0,0,0,100,0),
(@PATH,3,9845.461,1011.137,1305.539,0,0,0,0,100,0),
(@PATH,4,9845.183,1025.086,1305.097,0,0,0,0,100,0),
(@PATH,5,9846.616,1035.321,1304.834,0,0,0,0,100,0),
(@PATH,6,9849.457,1047.508,1305.153,0,0,0,0,100,0),
(@PATH,7,9854.014,1061.109,1306.483,0,0,0,0,100,0),
(@PATH,8,9849.858,1047.879,1305.162,0,0,0,0,100,0),
(@PATH,9,9847.079,1035.602,1304.833,0,0,0,0,100,0),
(@PATH,10,9830.117,1021.594,1307.905,0,0,0,0,100,0),
(@PATH,11,9819.713,1018.017,1304.309,0,0,0,0,100,0),
(@PATH,12,9807.053,1015.485,1303.729,0,0,0,0,100,0),
(@PATH,13,9798.432,1014.775,1301.566,0,0,0,0,100,0),
(@PATH,14,9792.107,1011.032,1299.368,0,0,0,0,100,0),
(@PATH,15,9783.028,1005.537,1299.117,0,0,0,0,100,0),
(@PATH,16,9770.062,986.486,1296.783,0,0,0,0,100,0),
(@PATH,17,9755.872,967.054,1293.366,0,0,0,0,100,0),
(@PATH,18,9748.623,951.893,1293.509,0,0,0,0,100,0),
(@PATH,19,9743.740,942.144,1293.801,0,0,0,0,100,0),
(@PATH,20,9740.571,930.261,1295.013,0,0,0,0,100,0),
(@PATH,21,9751.314,922.571,1296.215,0,0,0,0,100,0),
(@PATH,22,9762.808,915.243,1296.948,0,0,0,0,100,0),
(@PATH,23,9775.641,909.751,1297.983,0,0,0,0,100,0),
(@PATH,24,9797.529,907.546,1298.294,0,0,0,0,100,0),
(@PATH,25,9815.451,907.819,1301.735,0,0,0,0,100,0),
(@PATH,26,9830.997,910.799,1304.491,0,0,0,0,100,0),
(@PATH,27,9842.348,909.106,1305.476,0,0,0,0,100,0),
(@PATH,28,9851.480,904.051,1306.235,0,0,0,0,100,0),
(@PATH,29,9860.840,900.547,1306.844,0,0,0,0,100,0),
(@PATH,30,9876.581,896.769,1308.888,0,0,0,0,100,0),
(@PATH,31,9879.310,887.942,1308.398,0,0,0,0,100,0),
(@PATH,32,9878.167,869.978,1307.112,0,0,0,0,100,0),
(@PATH,33,9876.162,846.766,1307.222,0,0,0,0,100,0),
(@PATH,34,9878.985,862.769,1307.222,0,0,0,0,100,0),
(@PATH,35,9881.287,874.132,1307.045,0,0,0,0,100,0),
(@PATH,36,9886.876,890.960,1307.353,0,0,0,0,100,0),
(@PATH,37,9886.917,901.640,1307.481,0,0,0,0,100,0),
(@PATH,38,9885.125,910.780,1307.429,0,0,0,0,100,0),
(@PATH,39,9881.225,920.605,1307.523,0,0,0,0,100,0),
(@PATH,40,9877.249,928.814,1307.783,0,0,0,0,100,0),
(@PATH,41,9869.623,940.407,1307.447,0,0,0,0,100,0),
(@PATH,42,9861.668,951.502,1306.656,0,0,0,0,100,0),
(@PATH,43,9853.609,964.509,1305.942,0,0,0,0,100,0);

-- the creak: sound kit 6528 as an object sound at his position, every 21-45 s out of combat
DELETE FROM `smart_scripts` WHERE `entryorguid`=2041 AND `source_type`=0 AND `id`=2;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(2041,0,2,0,1,0,100,0,21000,45000,21000,45000,0,'',4,6528,0,2,0,0,0,1,0,0,0,0,0,0,0,'Ancient Protector - Out of Combat - Play Object Sound 6528');

-- Teldrassil Sentinel, inn door to the west road: guid 277070 <- sniffed spawn 2636288. 15 stops per lap, out-and-back over 9 nodes, walk (2.50 yd/s), no pauses.
--   point 1 is the inn-door end; the spawn moves onto it from (9808.11,955.75), 6 yd off the road; was MovementType 0, no addon row.
SET @NPC := 277070;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `position_x`=9840.995, `position_y`=965.936, `position_z`=1307.814, `orientation`=3.46920, `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,1,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,9840.995,965.936,1307.814,0,0,0,0,100,0),
(@PATH,2,9821.772,959.403,1308.797,0,0,0,0,100,0),
(@PATH,3,9779.382,948.086,1307.892,0,0,0,0,100,0),
(@PATH,4,9775.844,947.595,1306.674,0,0,0,0,100,0),
(@PATH,5,9770.480,943.282,1305.977,0,0,0,0,100,0),
(@PATH,6,9767.908,937.862,1303.999,0,0,0,0,100,0),
(@PATH,7,9767.567,931.506,1301.429,0,0,0,0,100,0),
(@PATH,8,9767.080,926.653,1299.642,0,0,0,0,100,0),
(@PATH,9,9766.854,923.663,1298.710,0,0,0,0,100,0),
(@PATH,10,9767.567,931.506,1301.429,0,0,0,0,100,0),
(@PATH,11,9767.908,937.862,1303.999,0,0,0,0,100,0),
(@PATH,12,9770.480,943.282,1305.977,0,0,0,0,100,0),
(@PATH,13,9775.844,947.595,1306.674,0,0,0,0,100,0),
(@PATH,14,9779.382,948.086,1307.892,0,0,0,0,100,0),
(@PATH,15,9821.772,959.403,1308.797,0,0,0,0,100,0);

-- @touched: creature,creature_addon,waypoint_data 277016,277070
