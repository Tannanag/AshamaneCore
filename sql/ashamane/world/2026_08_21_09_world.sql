-- Coldridge Valley: collapse the Kharanos tunnel when 24490 is turned in, and clear
-- it again when the player flies out on 24492.

-- The rubble.
SET @OGUID := 210120200;
DELETE FROM `gameobject` WHERE `guid`=@OGUID;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnDifficulties`, `phaseUseFlags`, `PhaseId`, `PhaseGroup`, `terrainSwapMap`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `isActive`, `VerifiedBuild`) VALUES
(@OGUID, 201711, 0, 0, 0, '0', 0, 170, 0, -1, -6218.997, 118.5677, 431.6347, 2.600535, 0, 0, 0.9636297, 0.267241, 120, 255, 1, 0, 23877); -- Coldridge Tunnel Cave In

-- Phase 169 must be granted alongside 170: PhasingHandler only treats a shift as
-- Unphased if it holds DEFAULT_PHASE 169, and without it a player granted 170 stops
-- seeing every unphased spawn and the valley reads as empty.
DELETE FROM `phase_area` WHERE `AreaId` IN (132, 800) AND `PhaseId` IN (169, 170);
INSERT INTO `phase_area` (`AreaId`, `PhaseId`, `Comment`) VALUES
(132, 169, 'Coldridge Valley - default phase, so phase 170 adds to the world instead of replacing it'),
(800, 169, 'Coldridge Pass - default phase, so phase 170 adds to the world instead of replacing it'),
(132, 170, 'Coldridge Valley - Kharanos tunnel collapsed'),
(800, 170, 'Coldridge Pass - Kharanos tunnel collapsed');

-- Phase 170 applies while 24490 is rewarded AND 24492 is not; conditions in one
-- ElseGroup are ANDed. 24492 is the end trigger rather than 24491 because its turn-in
-- is the ride itself -- without it the player rides out, walks back, and finds the
-- valley still sealed with no way through.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=26 AND `SourceGroup`=170 AND `SourceEntry` IN (132, 800);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(26, 170, 132, 0, 0, 8, 0, 24490, 0, 0, 0, 0, 0, '', 'Phase 170 in area 132 once quest 24490 rewarded - tunnel collapses'),
(26, 170, 132, 0, 0, 8, 0, 24492, 0, 0, 1, 0, 0, '', 'Drop phase 170 in area 132 once quest 24492 rewarded - tunnel is clear again'),
(26, 170, 800, 0, 0, 8, 0, 24490, 0, 0, 0, 0, 0, '', 'Phase 170 in area 800 once quest 24490 rewarded - tunnel collapses'),
(26, 170, 800, 0, 0, 8, 0, 24492, 0, 0, 1, 0, 0, '', 'Drop phase 170 in area 800 once quest 24492 rewarded - tunnel is clear again');

-- Milo and his gyro stay unphased, so ending the phase does not remove them along with
-- the rubble. What times Milo's arrival is the invisibility pair below, against the
-- detect aura 24491 hands out on accept.
DELETE FROM `creature_addon` WHERE `guid` IN (210115304, 10612185);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `StandState`, `AnimTier`, `VisFlags`, `SheathState`, `PvPFlags`, `emote`, `aiAnimKit`, `movementAnimKit`, `meleeAnimKit`, `visibilityDistanceType`, `auras`) VALUES
(210115304, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '70045 70042'), -- Milo Geartwinge 37113
(10612185,  0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '70045 70042'); -- Milo's Gyro 37198

-- 24491 hands the player the detect aura on accept.
UPDATE `quest_template_addon` SET `SourceSpellID`=70047 WHERE `ID`=24491; -- Follow that Gyro-Copter!

UPDATE `creature_template` SET `ScriptName`='npc_hands_springsprocket' WHERE `entry`=6782;
