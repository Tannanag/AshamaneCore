-- Teldrassil: the Crested Owls (62242) of Shadowglen and the Dolanaar side perch
-- in the air and circle above their perch, the way retail's do. On the server the
-- template was a random walker (MovementType 1, InhabitType 4, no script, no
-- addon): 20 spawns stood still in mid-air and the 5 in Shadowglen wandered at
-- radius 15, so an owl spawned at circle height would drift about up there.
--
-- In the 14 Sep sniff 13 owls do the same three things (619 movement packets):
--   perched  16-31 s of 0.4-9 yd hops at 2.5 yd/s on one altitude, within ~6 yd of
--            the perch; half the hops are cut off by the next after ~1.2 s, the rest
--            end and pause, mostly under 0.5 s, up to 10 s;
--   take-off one Flying|CatmullRom|Cyclic|EnterCycle spline: a circle of radius 8
--            centred on the owl's current spot, 5 yd higher, 16 points, 12,507 ms a
--            lap (4.5 yd/s), first point straight ahead, direction a coin toss (the
--            same owl goes both ways); 32-60 s up, one 116 s outlier;
--   descent  one 9.43 yd leg at 4.5 yd/s back to the take-off point, 2.1 s.
-- npc_crested_owl (zone_teldrassil.cpp) does all three with the spawn point as the
-- perch; the spawns go MovementType 0 so no generator moves them under it. The
-- create blocks carry AnimTier 3 (Fly) and DisableGravity with hover, as the Wisps
-- do; the template addon row supplies the AnimTier the owl had none of.
--
-- The 7 sniffed owls that sit on a server spawn were matched on their circle, so
-- five of those spawns (39-43, the Shadowglen ones) sit at circle height, 5.00 yd
-- above the perch and 7-9 yd to one side of it; all seven move onto the sniffed
-- perch centre (the mean of every hop, 22-69 hops each) at the perch altitude:
--   39 -> 10633.62, 933.54, 1322.54   (was 9.06 yd off, 5.00 yd up)
--   40 -> 10619.28, 818.35, 1311.75   (7.02 yd, 5.00 up)
--   41 -> 10566.11, 961.08, 1320.54   (9.43 yd, 5.00 up)
--   42 -> 10429.99, 923.26, 1319.55   (7.65 yd, 5.00 up)
--   43 -> 10289.94, 851.49, 1336.77   (7.27 yd, 5.00 up)
--   10649672 -> 9803.22, 772.44, 1303.86  (8.48 yd, 1.72 yd low)
--   10649673 -> 10120.91, 704.71, 1360.79 (6.80 yd, 0.30 yd high)
-- Six sniffed owls have no spawn at all (nearest 62242 more than 40 yd off) and are
-- added as 300000155-300000160 on their perch centre, facing as first seen; the
-- Lake Al'Ameth one (300000160) was only ever seen perched, 2 hops, and gets the
-- same AI. The 18 other 62242 spawns on the map were outside the sniff's route and
-- keep their positions; they only pick up the script.
--
-- Needs a worldserver rebuild (new script) and restart. To undo the six new spawns:
-- DELETE FROM creature WHERE guid BETWEEN 300000155 AND 300000160; the rest is in
-- the snapshot in ~/movement-reverts.

-- @touched: creature_template,creature 39,40,41,42,43,10649672,10649673

-- 1. The template: script owns movement; AnimTier 3 as sniffed.
UPDATE `creature_template` SET `ScriptName`='npc_crested_owl', `MovementType`=0 WHERE `entry`=62242;

DELETE FROM `creature_template_addon` WHERE `entry`=62242;
INSERT INTO `creature_template_addon` (`entry`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(62242,0,0,0,3,0,1,0,0,0,0,0,0,'');

-- 2. Every spawn idle for the script (the five Shadowglen wanderers stop wandering).
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0 WHERE `id`=62242;

-- 3. The seven matched spawns onto their sniffed perch.
UPDATE `creature` SET `position_x`=10633.62, `position_y`=933.542, `position_z`=1322.54 WHERE `guid`=39;
UPDATE `creature` SET `position_x`=10619.28, `position_y`=818.345, `position_z`=1311.75 WHERE `guid`=40;
UPDATE `creature` SET `position_x`=10566.109, `position_y`=961.08, `position_z`=1320.54 WHERE `guid`=41;
UPDATE `creature` SET `position_x`=10429.988, `position_y`=923.256, `position_z`=1319.55 WHERE `guid`=42;
UPDATE `creature` SET `position_x`=10289.935, `position_y`=851.489, `position_z`=1336.77 WHERE `guid`=43;
UPDATE `creature` SET `position_x`=9803.223, `position_y`=772.442, `position_z`=1303.86 WHERE `guid`=10649672;
UPDATE `creature` SET `position_x`=10120.91, `position_y`=704.706, `position_z`=1360.79 WHERE `guid`=10649673;

-- 4. The six perches with no spawn.
DELETE FROM `creature` WHERE `guid` BETWEEN 300000155 AND 300000160;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(300000155,62242,1,6450,188,'0',0,0,0,-1,0,0,10627.354,764.247,1320.09,5.815,120,0,0,1,0,0,0,0,0,0,0,'',0),  -- sniff low 2642879, Shadowglen, above the moonwell path
(300000156,62242,1,141,186,'0',0,0,0,-1,0,0,9789.259,1037.717,1302.37,4.9933,120,0,0,1,0,0,0,0,0,0,0,'',0),   -- 2665533, Dolanaar
(300000157,62242,1,6450,188,'0',0,0,0,-1,0,0,10303.161,653.808,1337.26,2.4836,120,0,0,1,0,0,0,0,0,0,0,'',0),  -- 2667004, south Shadowglen
(300000158,62242,1,141,141,'0',0,0,0,-1,0,0,9975.551,698.766,1320.54,3.3314,120,0,0,1,0,0,0,0,0,0,0,'',0),    -- 2670488, the road south of Shadowglen
(300000159,62242,1,6450,256,'0',0,0,0,-1,0,0,10509.111,742.648,1316.11,2.942,120,0,0,1,0,0,0,0,0,0,0,'',0),   -- 10612535, foot of Aldrassil
(300000160,62242,1,141,141,'0',0,0,0,-1,0,0,9557.517,533.952,1324.31,2.0228,120,0,0,1,0,0,0,0,0,0,0,'',0);    -- 2320156, Lake Al'Ameth, perched only in the sniff
