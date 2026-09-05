-- New Tinkertown: quieten the practice dummies.
--
-- The dummies answered each swing with `Wound Impact` / `Wound Impact Critical`, and this
-- client draws those with a loud impact noise that carries across the whole camp. The two casts
-- are dropped and the wound flinch stays, so the dummies still visibly take the hit.
--
-- The flinch keeps its 350 ms delay, which now runs from the swing itself.

DELETE FROM `smart_scripts` WHERE `source_type`=9 AND `entryorguid` IN (4232900,4232901,4232902);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(4232900,9,0,0,0,0,100,0,  0,  0,0,0,0,'',11,42880,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Cast ''Cosmetic - Combat Attack 1H'''),
(4232900,9,1,0,0,0,100,0,350,350,0,0,0,'', 5,33,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Practice Dummy Plays Wound Emote'),

(4232901,9,0,0,0,0,100,0,  0,  0,0,0,0,'',11,44079,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Cast ''Cosmetic - Combat Special Attack 1H'''),

(4232902,9,0,0,0,0,100,0,  0,  0,0,0,0,'',11,78959,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Cast ''Cosmetic - Combat Attack 1H (Thrust)'''),
(4232902,9,1,0,0,0,100,0,350,350,0,0,0,'', 5,33,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Practice Dummy Plays Wound Emote');
