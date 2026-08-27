-- New Tinkertown: three more S.A.F.E. Operatives (45847) at the northern camp.
--
-- These stand 2.8-3.2 yd from spawns added in 2026_08_26_05_world.sql, close
-- enough that the earlier pass folded them in as the same post. They are separate
-- Operatives.
--
-- Clears its own guid block first so the SQL updater can re-run this file.
-- Needs a worldserver restart.
DELETE FROM `creature` WHERE `guid` BETWEEN 984709 AND 984711;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(984709,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4976.1104,861.2100,274.9105,3.6300,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984710,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4979.3901,841.3300,276.5700,4.3810,300,0,0,102,0,0,0,0,0,0,0,'',69465),
(984711,45847,0,1,5495,'0',0,0,0,-1,34708,0,-4986.6802,841.2400,276.3900,4.7540,300,0,0,102,0,0,0,0,0,0,0,'',69465);
