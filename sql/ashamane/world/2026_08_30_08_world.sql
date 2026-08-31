-- New Tinkertown: bind the Target Acquisition Device (46012) AI.
--
-- Needs a worldserver restart.
UPDATE `creature_template` SET `ScriptName`='npc_target_acquisition_device' WHERE `entry`=46012;
