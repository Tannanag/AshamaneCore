-- New Tinkertown: Razlo Crushcog's image steps out and back, without dying.
--
-- The scene ended by despawning him. That routes through the death handling, so
-- he came back only after his spawn timer plus the corpse decay, and the spawn
-- timer was the only half a DB change could reach. He is hidden instead, put
-- back on his mark while nobody can see him, re-frozen, and shown again.
--
-- His spawn timer goes back to what it was; nothing despawns him now.

UPDATE `creature` SET `spawntimesecs` = 300 WHERE `guid` = 168836;

DELETE FROM `smart_scripts` WHERE `entryorguid` = 4250500 AND `source_type` = 9 AND `id` IN (6,7,8,9);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(4250500,9,6,0,0,0,100,0,7000,7000,0,0,47,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Image of Razlo Crushcog - Script - Hide'),
(4250500,9,7,0,0,0,100,0,0,0,0,0,62,0,0,0,0,0,0,8,0,0,0,-5138.53,499.372,396.624,4.10152,'Image of Razlo Crushcog - Script - Back to his mark'),
(4250500,9,8,0,0,0,100,0,0,0,0,0,11,16245,0,0,0,0,0,1,0,0,0,0,0,0,0,'Image of Razlo Crushcog - Script - Cast Freeze Anim'),
(4250500,9,9,0,0,0,100,0,7500,7500,0,0,47,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Image of Razlo Crushcog - Script - Show');
