-- New Tinkertown, the ruined ground west: the spawn set for the sludges and slimes
-- The three entries carried 86 spawns between them where there are 53 creatures.
-- Toxic Sludge drops 48 -> 27, Living Contamination 42185 drops 32 -> 18, and
-- 43089 goes 6 -> 8: it was the one entry that was short, not over.
--
-- The surplus is duplication rather than a wider spread: 13 of the 48 sludges stood
-- within 8 yd of another sludge, several within a yard, and 168835/168862 shared a
-- coordinate exactly. Every spawn removed here is one that nothing was ever standing
-- on, on ground that was in view for twenty minutes or more.
--
-- Kept guids are unchanged so the paths in _10 keep their spawns.

DELETE FROM `creature_addon` WHERE `guid` IN (
    167533, 167885, 167887, 168020, 168320, 168349, 168367, 168420, 168438, 168439,
    168440, 168446, 168542, 168546, 168677, 168862, 168865, 168953, 168977, 168994,
    168996, 169010, 169115, 169143, 169144, 169145, 169146, 169147, 169151, 169152,
    169153, 169167, 169168, 169170, 169172, 169174);
DELETE FROM `creature` WHERE `guid` IN (
    167533, 167885, 167887, 168020, 168320, 168349, 168367, 168420, 168438, 168439,
    168440, 168446, 168542, 168546, 168677, 168862, 168865, 168953, 168977, 168994,
    168996, 169010, 169115, 169143, 169144, 169145, 169146, 169147, 169151, 169152,
    169153, 169167, 169168, 169170, 169172, 169174);

-- The three 43089 slimes that were missing. They stand still like the other five,
-- each holding the facing it was seen with.
-- The DELETE lets the updater re-run this file.
DELETE FROM `creature` WHERE `guid` BETWEEN 985013 AND 985015;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(985013,43089,0,6457,133,'0',0,0,0,-1,13749,0,-5236.836,503.607,387.857,6.239818,300,0,0,55,0,0,0,0,0,0,0,'',0),
(985014,43089,0,6457,133,'0',0,0,0,-1,13749,0,-5225.556,466.786,386.020,5.919405,300,0,0,55,0,0,0,0,0,0,0,'',0),
(985015,43089,0,6457,133,'0',0,0,0,-1,13749,0,-5229.389,483.615,386.052,0.210880,300,0,0,55,0,0,0,0,0,0,0,'',0);

-- @touched: creature,creature_addon 167533,167885,167887,168020,168320,168349,168367,168420,168438,168439,168440,168446,168542,168546,168677,168862,168865,168953,168977,168994,168996,169010,169115,169143,169144,169145,169146,169147,169151,169152,169153,169167,169168,169170,169172,169174
