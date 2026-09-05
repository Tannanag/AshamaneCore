-- New Tinkertown: the monk trainer takes his class.
--
-- Xi, Friend to the Small stands facing the middle of three Monk Trainees and shadowboxes at
-- them while they drill back. The three trainees had templates but no spawns at all, so they
-- are added here; Xi was already in the world and only needed his stance and his script.
--
-- All four rest in emote state 510 (STATE_MONKOFFENSE_READYUNARMED), the unarmed monk guard,
-- and none of them carries a weapon -- no `creature_equip_template` row exists for any of the
-- four, so `equipment_id` 0 leaves them empty-handed rather than loading equip template 1.
--
-- The drill itself is in `npc_xi_monk_trainer` and `npc_monk_trainee`. Only 63239 carries a
-- ScriptName: it keeps time for all three trainees so they strike together, and finds the
-- other two by entry, which is why they need no script and no fixed guids.
--
-- Xi's spawn row was filed under zone 1 / area 5495; the position is New Tinkertown, so it is
-- corrected to match the spawns standing beside him.
--
-- Needs a worldserver restart: `creature_template_addon` and the new spawns are not reloadable,
-- and the two scripts have to be compiled and installed to `ashamaneServer/bin/scripts`.

-- -----------------------------------------------------------------------------
-- Xi, Friend to the Small
-- -----------------------------------------------------------------------------

UPDATE `creature_template` SET `ScriptName`='npc_xi_monk_trainer' WHERE `entry`=63238;

UPDATE `creature_template_addon` SET `emote`=510 WHERE `entry`=63238;

UPDATE `creature` SET `zoneId`=6457, `areaId`=133 WHERE `guid`=33;

-- -----------------------------------------------------------------------------
-- the three Monk Trainees
-- -----------------------------------------------------------------------------

-- 2048 is UNIT_FLAG2_REGENERATE_POWER, which every other spawn on this ground carries.
UPDATE `creature_template` SET `unit_flags2`=2048 WHERE `entry` IN (63239,63241,63242);

UPDATE `creature_template` SET `ScriptName`='npc_monk_trainee' WHERE `entry`=63239;

DELETE FROM `creature_template_addon` WHERE `entry` IN (63239,63241,63242);
INSERT INTO `creature_template_addon` (`entry`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(63239,0,0,0,0,0,1,0,510,0,0,0,0,''),
(63241,0,0,0,0,0,1,0,510,0,0,0,0,''),
(63242,0,0,0,0,0,1,0,510,0,0,0,0,'');

-- Each trainee faces Xi; Xi faces the middle of the three.
DELETE FROM `creature` WHERE `guid` BETWEEN 300000145 AND 300000147;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(300000145,63239,0,6457,133,'0',0,0,0,-1,42908,0,-5164.262,460.68924,391.2339,  2.075682163,300,0,0,0,0,0,0,0,0,0,0,'',0),
(300000146,63241,0,6457,133,'0',0,0,0,-1,42909,0,-5167.2676,460.65625,390.8431, 1.262669086,300,0,0,0,0,0,0,0,0,0,0,'',0),
(300000147,63242,0,6457,133,'0',0,0,0,-1,42910,0,-5162.328,462.93228,391.11148, 2.710769891,300,0,0,0,0,0,0,0,0,0,0,'',0);
