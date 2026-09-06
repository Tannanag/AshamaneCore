-- New Tinkertown: the Crushcog hologram briefing moves into script.
--
-- The briefing drives four other NPCs' speech, emotes, movement and lifetime and
-- holds eight images across several beats to cheer on cue, none of which the
-- database can express. Both entries hand their behaviour to the script; the
-- image's two-point path and every smart_scripts row for the scene are gone.

DELETE FROM `smart_scripts` WHERE `entryorguid` IN (42489,42505) AND `source_type` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (4248900,4250500) AND `source_type` = 9;

DELETE FROM `waypoints` WHERE `entry` = 42505;

UPDATE `creature_template` SET `AIName` = '', `ScriptName` = 'npc_captain_tread_sparknozzle_scene' WHERE `entry` = 42489;
UPDATE `creature_template` SET `AIName` = '', `ScriptName` = 'npc_image_of_razlo_crushcog' WHERE `entry` = 42505;
