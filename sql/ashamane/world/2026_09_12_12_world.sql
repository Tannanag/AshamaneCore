-- New Tinkertown: Razlo Crushcog sits in his mech, and Stonegrind rides a ram.
--
-- 42839 is the mech, a vehicle; 42494 is Crushcog and rides seat 0 as its
-- accessory. Spawn 168787 was Crushcog standing in mid-air at the seat's height
-- with no mech under him, so it goes and the accessory replaces it. He is not a
-- minion of the seat: the mech's script throws him clear and kills him itself.
-- Both need a worldserver restart.

DELETE FROM `creature_addon` WHERE `guid`=168787;
DELETE FROM `creature` WHERE `guid` IN (168787,985016);
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(985016,42839,0,6457,211,'0',0,0,0,-1,33087,0,-5247.9375,119.40972,394.43466,3.036873,300,0,0,0,0,0,0,0,0,0,0,'',0);

DELETE FROM `vehicle_template_accessory` WHERE `entry`=42839;
INSERT INTO `vehicle_template_accessory` (`entry`,`accessory_entry`,`seat_id`,`minion`,`description`,`summontype`,`summontimer`) VALUES
(42839,42494,0,0,'Razlo Crushcog - Razlo Crushcog',6,3600);

-- Crushcog cannot be picked out of the seat or fought there.
UPDATE `creature_template` SET `unit_flags`=33555200 WHERE `entry`=42494;

-- Stonegrind's ram. The row replaces the template addon, so its PvP and sheath
-- values are carried over.
DELETE FROM `creature_addon` WHERE `guid`=168782;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(168782,0,2786,0,0,0,1,1,0,0,0,0,0,'');
