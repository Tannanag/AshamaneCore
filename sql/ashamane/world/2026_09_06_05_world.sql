-- New Tinkertown: the Crushcog hologram scene shows its images on cue.
--
-- The eight images were also standing as permanent spawns at the exact
-- coordinates the scene summons them at, so they were visible between runs and
-- doubled during one. The summons are the scene; the standing copies go.
--
-- Crushcog's path also began with a point that took him away from his mark
-- before he walked to it, and its second point sat below the floor.

DELETE FROM `creature` WHERE `guid` IN (168849,168850,168913,168914,168915,168916,168917,168918);

UPDATE `waypoints` SET `position_x` = -5138.53, `position_y` = 499.372, `position_z` = 396.624 WHERE `entry` = 42505 AND `pointid` = 1;
UPDATE `waypoints` SET `position_z` = 396.588 WHERE `entry` = 42505 AND `pointid` = 2;

-- Captain Tread Sparknozzle's action list: the dialogue beats, then the images.
UPDATE `smart_scripts` SET `event_param1` = 2000, `event_param2` = 2000 WHERE `entryorguid` = 4248900 AND `source_type` = 9 AND `id` = 3;
UPDATE `smart_scripts` SET `event_param1` = 7000, `event_param2` = 7000 WHERE `entryorguid` = 4248900 AND `source_type` = 9 AND `id` = 4;
UPDATE `smart_scripts` SET `event_param1` = 10000, `event_param2` = 10000 WHERE `entryorguid` = 4248900 AND `source_type` = 9 AND `id` = 5;
UPDATE `smart_scripts` SET `action_param3` = 13500 WHERE `entryorguid` = 4248900 AND `source_type` = 9 AND `id` IN (7,8,9);
UPDATE `smart_scripts` SET `event_param1` = 6000, `event_param2` = 6000, `action_param3` = 14500 WHERE `entryorguid` = 4248900 AND `source_type` = 9 AND `id` = 10;
UPDATE `smart_scripts` SET `action_param3` = 14500 WHERE `entryorguid` = 4248900 AND `source_type` = 9 AND `id` IN (11,12);
UPDATE `smart_scripts` SET `event_param1` = 2000, `event_param2` = 2000 WHERE `entryorguid` = 4248900 AND `source_type` = 9 AND `id` = 13;
UPDATE `smart_scripts` SET `event_param1` = 7500, `event_param2` = 7500 WHERE `entryorguid` = 4248900 AND `source_type` = 9 AND `id` = 15;

-- Image of Razlo Crushcog's action list: he holds his mark a little less long.
UPDATE `smart_scripts` SET `event_param1` = 7000, `event_param2` = 7000 WHERE `entryorguid` = 4250500 AND `source_type` = 9 AND `id` = 6;
