-- New Tinkertown: Gnome Travelers ride up the main road in ones, twos and threes.
--
-- A group appears at the south end of the road (-5424, -329), rides 650 yards north
-- in single file at 3.75 yd/s and is gone past Brewnall at (-5382, 319); the next
-- group comes a few seconds later. 168886 is the one spawn and moves to the start;
-- npc_gnome_traveler_column rolls the group size and the mounts and summons the
-- riders behind it, so the script goes on the template. The other five spawns were
-- two groups caught mid-ride, one of them behind 168886 itself, and come out with
-- their addon rows. speed_run is the entry's own 8 yd/s. Needs a worldserver restart.

UPDATE `creature_template` SET `ScriptName`='npc_gnome_traveler_column', `speed_run`=1.142857 WHERE `entry`=43297;

UPDATE `creature` SET `zoneId`=0, `areaId`=0, `position_x`=-5423.67, `position_y`=-329.405, `position_z`=399.66434, `orientation`=1.570796, `MovementType`=0, `wander_distance`=0 WHERE `guid`=168886;

DELETE FROM `creature_addon` WHERE `guid` IN (168887,168888,169297,169298,169299);
DELETE FROM `creature` WHERE `guid` IN (168887,168888,169297,169298,169299);

-- @touched: creature,creature_addon,creature_template 168886,168887,168888,169297,169298,169299
