-- New Tinkertown: Rockjaw Bonepicker (42221) throws bones for the whole
-- fight, not once on aggro. First cast 1-2.5 s into combat, then every
-- 3.5-5 s while it keeps meleeing; plain cast flags so it still chases.
-- Marauder and Fungus-Flinger cast lists already match; their keg and
-- shield are the addon auras 79253 / 80928, not combat spells.

DELETE FROM `smart_scripts` WHERE `entryorguid`=42221 AND `source_type`=0 AND `id`=1;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(42221,0,1,0,0,0,100,0,1000,2500,3500,5000,0,'',11,82625,0,0,0,0,0,2,0,0,0,0,0,0,0,'Rockjaw Bonepicker - In Combat - Cast ''Bone Toss''');

-- @touched: smart_scripts 42221
