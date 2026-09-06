-- New Tinkertown: High Tinker Mekkatorque's holotable scene (quest 26208)
-- The images ride in mounted, the trogg corpses lie dead, the irradiator glows,
-- none of the projections can be clicked, and Mekkatorque ends back on his mark.

-- The projections are scenery: not selectable, and no combat with anyone.
UPDATE `creature_template` SET `unit_flags` = 33555200
    WHERE `entry` IN (42419, 42420, 42422, 42423, 42441, 42452);

-- The trogg corpses are laid out dead rather than standing.
UPDATE `creature_template` SET `unit_flags2` = 1 WHERE `entry` = 42441;

-- Thermaplugg's Brag-bot turns on its mark a second after it appears.
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 42423;

-- Mounts for the three images, and the auras the corpses and the irradiator carry.
DELETE FROM `creature_template_addon` WHERE `entry` IN (42419, 42420, 42422, 42441, 42452);
INSERT INTO `creature_template_addon`
    (`entry`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(42419, 0, 31692, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, ''),
(42420, 0, 10664, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, ''),
(42422, 0,  6569, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, ''),
(42441, 0,     0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '35356'),
(42452, 0,     0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '79212');

-- This line is spoken without a gesture.
UPDATE `creature_text` SET `Emote` = 0 WHERE `CreatureID` = 42419 AND `GroupID` = 3;

-- The Brag-bot's own turn.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 42423 AND `source_type` = 0;
INSERT INTO `smart_scripts`
    (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(42423, 0, 0, 0, 1, 0, 100, 1, 1000, 1000, 0, 0, 0, 66, 0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 2.2515, 'Thermaplugg\'s Brag-bot - Out of Combat - Turn to face the holotable');

-- The scene itself, retimed end to end.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 4231700 AND `source_type` = 9;
INSERT INTO `smart_scripts`
    (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(4231700, 9,  0, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 22,     0,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Set Phase 0'),
(4231700, 9,  1, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 59,     0,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Turn run off'),
(4231700, 9,  2, 0, 0, 0, 100, 0,  5700,  5700, 0, 0, 0, 11, 79227,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Cast \'Op: Gnomeregan Recap Credit\''),
(4231700, 9,  3, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0,  1,     0,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Say 0'),
(4231700, 9,  4, 0, 0, 0, 100, 0,  2400,  2400, 0, 0, 0, 69,     0,  0,  0,     0,  0, 0,  8,     0,  0, 0, -5132.874, 491.64185, 395.915,       0, 'High Tinker Mekkatorque - Script - Step up to the holotable'),
(4231700, 9,  5, 0, 0, 0, 100, 0,  2000,  2000, 0, 0, 0,  4,  8684,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Play Sound'),
(4231700, 9,  6, 0, 0, 0, 100, 0,  8900,  8900, 0, 0, 0,  1,     1,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Say 1'),
(4231700, 9,  7, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 12, 42419,  1, 83000,  0,  0, 0,  8,     0,  0, 0,  -5134.9,  495.592, 396.418, 5.61996, 'High Tinker Mekkatorque - Script - Spawn Image of High Tinker Mekkatorque'),
(4231700, 9,  8, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 12, 42420,  1, 83000,  0,  0, 0,  8,     0,  0, 0, -5134.27,  496.132, 396.419, 5.53269, 'High Tinker Mekkatorque - Script - Spawn Image of Doc Cogspin'),
(4231700, 9,  9, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 12, 42422,  1, 83000,  0,  0, 0,  8,     0,  0, 0, -5135.19,   494.83, 396.419,  5.5676, 'High Tinker Mekkatorque - Script - Spawn Image of Hinkles Fastblast'),
(4231700, 9, 10, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 12, 42441,  1, 83000,  0,  0, 0,  8,     0,  0, 0, -5133.28,  496.009, 396.419, 4.43314, 'High Tinker Mekkatorque - Script - Spawn Irradiated Trogg Corpse'),
(4231700, 9, 11, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 12, 42441,  1, 83000,  0,  0, 0,  8,     0,  0, 0, -5134.98,  494.033, 396.418, 0.750492, 'High Tinker Mekkatorque - Script - Spawn Irradiated Trogg Corpse'),
(4231700, 9, 12, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 12, 42452,  1, 83000,  0,  0, 0,  8,     0,  0, 0, -5132.73,  493.806, 396.559, 2.11185, 'High Tinker Mekkatorque - Script - Spawn Irradiator 3000 Image'),
(4231700, 9, 13, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 50, 203862, 62, 0,     0,  0, 0,  8,     0,  0, 0, -5133.67,  494.837, 395.426,       0, 'High Tinker Mekkatorque - Script - Spawn 203862'),
(4231700, 9, 14, 0, 0, 0, 100, 0,  6100,  6100, 0, 0, 0,  1,     0,  1,  0,     0,  0, 0, 19, 42419, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of High Tinker Mekkatorque Say 0'),
(4231700, 9, 15, 0, 0, 0, 100, 0,  6300,  6300, 0, 0, 0, 12, 42423,  1, 69000,  0,  0, 0,  8,     0,  0, 0, -5133.47,  494.375, 396.443,  1.6406, 'High Tinker Mekkatorque - Script - Spawn 42423'),
(4231700, 9, 16, 0, 0, 0, 100, 0,  2100,  2100, 0, 0, 0,  1,     0,  1,  0,     0,  0, 0, 19, 42423, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Thermaplugg\'s Brag-bot Say 0'),
(4231700, 9, 17, 0, 0, 0, 100, 0,  6600,  6600, 0, 0, 0,  1,     1,  1,  0,     0,  0, 0, 19, 42423, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Thermaplugg\'s Brag-bot Say 1'),
(4231700, 9, 18, 0, 0, 0, 100, 0,  4900,  4900, 0, 0, 0,  1,     2,  1,  0,     0,  0, 0, 19, 42423, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Thermaplugg\'s Brag-bot Say 2'),
(4231700, 9, 19, 0, 0, 0, 100, 0,  3500,  3500, 0, 0, 0,  1,     1,  1,  0,     0,  0, 0, 19, 42419, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of High Tinker Mekkatorque Say 1'),
(4231700, 9, 20, 0, 0, 0, 100, 0,  5300,  5300, 0, 0, 0,  1,     0,  1,  0,     0,  0, 0, 19, 42452, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Irradiator 3000 Image Say 0'),
(4231700, 9, 21, 0, 0, 0, 100, 0, 10900, 10900, 0, 0, 0,  1,     2,  1,  0,     0,  0, 0, 19, 42419, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of High Tinker Mekkatorque Say 2'),
(4231700, 9, 22, 0, 0, 0, 100, 0,  6600,  6600, 0, 0, 0,  1,     3,  1,  0,     0,  0, 0, 19, 42419, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of High Tinker Mekkatorque Say 3'),
(4231700, 9, 23, 0, 0, 0, 100, 0,  9600,  9600, 0, 0, 0,  1,     3,  1,  0,     0,  0, 0, 19, 42423, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Thermaplugg\'s Brag-bot Say 3'),
(4231700, 9, 24, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 43,     0,  0,  0,     0,  0, 0, 19, 42420, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of Doc Cogspin Remove mount'),
(4231700, 9, 25, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 43,     0,  0,  0,     0,  0, 0, 19, 42422, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of Hinkles Fastblast Remove mount'),
(4231700, 9, 26, 0, 0, 0, 100, 0,  1600,  1600, 0, 0, 0, 17,    69,  0,  0,     0,  0, 0, 19, 42420, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of Doc Cogspin set emotestate 69'),
(4231700, 9, 27, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 17,   428,  0,  0,     0,  0, 0, 19, 42422, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of Hinkles Fastblast set emotestate 428'),
(4231700, 9, 28, 0, 0, 0, 100, 0,  4800,  4800, 0, 0, 0,  1,     1,  1,  0,     0,  0, 0, 19, 42452, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Irradiator 3000 Image Say 1'),
(4231700, 9, 29, 0, 0, 0, 100, 0,  3700,  3700, 0, 0, 0,  1,     5,  1,  0,     0,  0, 0, 19, 42419, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of High Tinker Mekkatorque Say 5'),
(4231700, 9, 30, 0, 0, 0, 100, 0,  6100,  6100, 0, 0, 0, 86, 51347,  0, 19, 42422, 10, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of Hinkles Fastblast Cast \'Teleport Visual Only\''),
(4231700, 9, 31, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 86, 51347,  0, 19, 42420, 10, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of Doc Cogspin Cast \'Teleport Visual Only\''),
(4231700, 9, 32, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 86, 51347,  0, 19, 42419, 10, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of High Tinker Mekkatorque Cast \'Teleport Visual Only\''),
(4231700, 9, 33, 0, 0, 0, 100, 0,  1200,  1200, 0, 0, 0, 41,     0,  0,  0,     0,  0, 0, 19, 42419, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of High Tinker Mekkatorque Despawn'),
(4231700, 9, 34, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 41,     0,  0,  0,     0,  0, 0, 19, 42420, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of Doc Cogspin Despawn'),
(4231700, 9, 35, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 41,     0,  0,  0,     0,  0, 0, 19, 42422, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Image of Hinkles Fastblast Despawn'),
(4231700, 9, 36, 0, 0, 0, 100, 0,  1200,  1200, 0, 0, 0, 86, 51929,  0, 19, 42452, 10, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Irradiator 3000 Image Cast \'Bloody Explosion (Green)\''),
(4231700, 9, 37, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0, 86, 46419,  0, 19, 42452, 10, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Irradiator 3000 Image Cast \'Cosmetic - Explosion\''),
(4231700, 9, 38, 0, 0, 0, 100, 0,   400,   400, 0, 0, 0, 41,     0,  0,  0,     0,  0, 0,  9, 42441,  0, 10,       0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Irradiated Trogg Corpse Despawn'),
(4231700, 9, 39, 0, 0, 0, 100, 0,   800,   800, 0, 0, 0, 41,     0,  0,  0,     0,  0, 0, 19, 42452, 10, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Irradiator 3000 Image Despawn'),
(4231700, 9, 40, 0, 0, 0, 100, 0,  1200,  1200, 0, 0, 0, 11, 79227,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Cast \'Op: Gnomeregan Recap Credit\''),
(4231700, 9, 41, 0, 0, 0, 100, 0,     0,     0, 0, 0, 0,  1,     2,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Say 2'),
(4231700, 9, 42, 0, 0, 0, 100, 0,  1200,  1200, 0, 0, 0, 69,     0,  0,  0,     0,  0, 0,  8,     0,  0, 0, -5130.65,  488.842, 395.586,       0, 'High Tinker Mekkatorque - Script - Walk back to his mark'),
(4231700, 9, 43, 0, 0, 0, 100, 0,  2000,  2000, 0, 0, 0, 66,     0,  0,  0,     0,  0, 0,  8,     0,  0, 0,        0,       0,       0, 2.30383, 'High Tinker Mekkatorque - Script - turn to'),
(4231700, 9, 44, 0, 0, 0, 100, 0,  1000,  1000, 0, 0, 0, 22,     1,  0,  0,     0,  0, 0,  1,     0,  0, 0,        0,       0,       0,       0, 'High Tinker Mekkatorque - Script - Set Phase 1');
