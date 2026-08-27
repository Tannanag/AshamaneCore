-- New Tinkertown: add the missing S.A.F.E. Operatives at the northern rescue camp.
--
-- Nine Operatives stand in two rows around -4975..-4995, 835..863 that this server
-- had no spawns for. The 25 existing spawns elsewhere are already in the right
-- places and are not touched.
--
-- Clears its own guid block first so the SQL updater can re-run this file.
-- Needs a worldserver restart.
DELETE FROM `creature` WHERE `guid` BETWEEN 984700 AND 984708;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(984700,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4978.3198,862.8870,274.3923,3.0194,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984701,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4985.0298,862.8040,274.3923,3.5081,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984702,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4990.2100,861.7290,274.3923,4.7114,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984703,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4975.5498,854.3910,276.3153,2.5307,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984704,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4990.4399,852.6230,276.3153,5.2360,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984705,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4989.7993,842.0929,276.3875,5.1462,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984706,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4982.4487,841.6322,276.3875,4.6368,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984707,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4994.5400,837.0020,276.3153,5.7421,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984708,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4975.5698,835.5450,276.3153,3.8572,300,0,0,102,0,0,0,0,0,0,0,'',69465);