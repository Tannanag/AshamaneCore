-- New Tinkertown, Frostmane Hold: the Trogg Tunnels (42894) around the powder kegs.
--
-- Three of the seven carried a permanent Churning Dirt (80040) cloud that does not
-- belong on them; what a tunnel does is throw up a Boulder Impact (80054) puff every
-- few seconds. The template also picked between two models per spawn; the trigger
-- is the one it should be.

DELETE FROM `creature_addon` WHERE `guid` IN (167926, 167927, 168065);

UPDATE `creature_template` SET `modelid1`=21072, `modelid2`=0, `AIName`='SmartAI' WHERE `entry`=42894;

DELETE FROM `smart_scripts` WHERE `entryorguid`=42894 AND `source_type`=0;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(42894,0,0,0,1,0,100,0,2500,6000,2500,6000,0,'',11,80054,2,0,0,0,0,1,0,0,0,0,0,0,0,'Trogg Tunnel - Out of Combat - Cast Boulder Impact');
