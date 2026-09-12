-- New Tinkertown, "Finishin' the Job" (26318): the Detonator sets off the kegs.
--
-- The Powder Kegs (204041) were never spawned: twenty-five of them go in the
-- pile below the plunger. Pressing the Detonator (204042) lights an Explosive
-- Fuse (42763) beside it that runs into the pile; when it arrives the Frostmane
-- Hold Target (42739) standing there casts 79695 on every keg, which holds
-- each one in use for 3 s and then despawns it (Data3 / Data5), and the plunger
-- goes with them. Kegs are back after 20 s, the plunger after 30.
--
-- Kegs, plunger and trigger exist only while 26318 is in the log: phase 178,
-- granted across the zone by quest state and dropped on the turn-in. 169 goes
-- in alongside so the phased player keeps the rest of the world.

-- The kegs.
SET @OGUID := 210120300;
DELETE FROM `gameobject` WHERE `id`=204041;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnDifficulties`, `phaseUseFlags`, `PhaseId`, `PhaseGroup`, `terrainSwapMap`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `isActive`, `VerifiedBuild`) VALUES
(@OGUID+0, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5529.1753, 696.0, 376.17822, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+1, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5528.5645, 695.3993, 376.06882, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+2, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5528.526, 696.1285, 376.07104, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+3, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5528.04, 694.4618, 375.96, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+4, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5527.807, 695.4722, 376.02115, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+5, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5527.8057, 696.46704, 375.95712, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+6, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5525.835, 696.7969, 375.68375, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+7, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5525.146, 696.96704, 375.6826, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+8, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5524.7485, 697.61285, 375.73007, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+9, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5524.741, 698.5226, 375.78314, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+10, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5524.0312, 698.82294, 375.8195, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+11, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5524.002, 697.3785, 375.6923, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+12, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5523.9844, 698.15625, 375.76004, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+13, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5523.1787, 697.5174, 375.6854, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+14, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5522.0645, 698.816, 375.77338, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+15, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5521.3403, 699.38367, 375.8027, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+16, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5521.2466, 700.0382, 375.8384, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+17, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5521.229, 698.5799, 375.7239, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+18, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5520.741, 699.6059, 375.80316, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+19, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5520.6147, 698.8958, 375.73233, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+20, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5519.4707, 699.7257, 375.7709, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+21, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5518.597, 701.1024, 376.04376, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+22, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5518.4272, 700.4375, 375.91953, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+23, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5518.1787, 701.48615, 376.1995, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0),
(@OGUID+24, 204041, 0, 6457, 135, '0', 0, 178, 0, -1, -5518.012, 700.76044, 376.0291, 2.3910985, 0, 0, 0.93041706, 0.3665025, 20, 255, 1, 0, 0);

-- The plunger stood in the middle of its own kegs; it belongs 9 yd north of
-- them, at the tunnel mouth.
UPDATE `gameobject` SET `position_x`=-5523.212, `position_y`=708.6893, `position_z`=376.92456, `orientation`=6.2308264, `rotation0`=0, `rotation1`=0, `rotation2`=-0.026176453, `rotation3`=0.99965733, `spawntimesecs`=30, `PhaseId`=178 WHERE `guid`=51003223 AND `id`=204042;

-- The trigger stays put in the pile, and in the kegs' phase so its cast can
-- reach them.
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `PhaseId`=178 WHERE `guid`=167795 AND `id`=42739;

-- The fuse cannot be clicked or fought.
UPDATE `creature_template` SET `unit_flags`=33555200, `ScriptName`='npc_explosive_fuse' WHERE `entry`=42763;
UPDATE `gameobject_template` SET `ScriptName`='go_frostmane_hold_detonator' WHERE `entry`=204042;

DELETE FROM `phase_area` WHERE `AreaId`=6457 AND `PhaseId` IN (169, 178);
INSERT INTO `phase_area` (`AreaId`, `PhaseId`, `Comment`) VALUES
(6457, 169, 'New Tinkertown - default phase, so phase 178 adds to the world instead of replacing it'),
(6457, 178, 'New Tinkertown - Frostmane Hold kegs and detonator while 26318 is in the log');

-- 10 = in progress (8) or complete and not yet turned in (2).
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=26 AND `SourceGroup`=178 AND `SourceEntry`=6457;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(26, 178, 6457, 0, 0, 47, 0, 26318, 10, 0, 0, 0, 0, '', 'Phase 178 in New Tinkertown while quest 26318 is in the log - Frostmane Hold kegs and detonator');
