-- New Tinkertown: a Mounted Ironforge Mountaineer rides from Brewnall Village to Kharanos.
--
-- One rider appears in the village at (-5394, 308), rides 850 yards south down the main
-- road at 9.7 yd/s and is gone at the Kharanos end (-5523, -460); the next one comes a
-- few seconds later. 168873 is the one spawn and moves to the start under
-- npc_mounted_ironforge_mountaineer. The other three were the same rider caught
-- mid-ride and come out. Needs a worldserver restart.

UPDATE `creature` SET `zoneId`=0, `areaId`=0, `position_x`=-5393.55, `position_y`=307.573, `position_z`=394.66235, `orientation`=4.562209, `MovementType`=0, `wander_distance`=0, `ScriptName`='npc_mounted_ironforge_mountaineer' WHERE `guid`=168873;

DELETE FROM `creature` WHERE `guid` IN (168733,168795,169292);

-- @touched: creature 168733,168795,168873,169292
