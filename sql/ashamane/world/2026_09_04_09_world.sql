-- New Tinkertown: the warrior trainer drills his recruits.
--
-- Four Gnomeregan Trainees work four Practice Dummies, one trainee to each dummy, while Drill
-- Sergeant Steamcrank walks the line and barks at them.
--
-- Each trainee swings at its own dummy every few seconds, picking one of three cosmetic attacks
-- at random. The dummy answers every swing: a plain attack lands as `Wound Impact` (78960) and
-- knocks a wound flinch out of it, the heavier special attack lands as `Wound Impact Critical`
-- (78961) and does not. The trainee turns onto its dummy as it swings, which the cast already
-- does by itself, so nothing here sets a facing for them.
--
-- The sergeant patrols a closed loop past the four pairs. He starts at the west end, marches the
-- full length of the line to the east end, then works his way back down it stopping at each pair
-- in turn; the lap comes to roughly 47 seconds. At each of the four posts he pauses, turns to
-- face the pair he is inspecting, and throws one of four gestures at them -- approval, refusal, a
-- point, or a shout. The other nodes are the bends in his route and he does not stop at them.
--
-- The path is driven from the script rather than from `creature_addon`, because the pause, the
-- facing and the gesture all have to happen at named nodes. The four posts are points 8, 11, 12
-- and 18; the loop deliberately does not begin on a post, so that the first move after a respawn
-- covers real ground.
--
-- His spawn point stood about seven yards north of the loop, on ground he has no reason to be on,
-- so it is moved onto the westernmost post, which is where the lap ends.
--
-- The trainees' three attack scripts already existed but never fired: they looked for a Practice
-- Dummy with a maximum range of 0, which matches nothing, so every swing was cast at no target.
-- They now take the nearest dummy within three yards -- each trainee's own dummy is about a yard
-- away and the next nearest is over five, so the pairs cannot cross.
--
-- `AIName` goes on template 42324, which has exactly one spawn in the world.

-- -----------------------------------------------------------------------------
-- the drill sergeant: spawn, path and AI
-- -----------------------------------------------------------------------------

UPDATE `creature` SET `position_x`=-5173.526, `position_y`=453.4757, `position_z`=390.49203,
       `orientation`=4.834561824798584, `MovementType`=0 WHERE `guid`=167468;

DELETE FROM `creature_addon` WHERE `guid`=167468;
DELETE FROM `waypoint_data` WHERE `id`=1674680;

DELETE FROM `waypoints` WHERE `entry`=4232401;
INSERT INTO `waypoints` (`entry`,`pointid`,`position_x`,`position_y`,`position_z`,`point_comment`) VALUES
(4232401, 1,-5171.2075, 454.05643,391.4192,  'Drill Sergeant Steamcrank'),
(4232401, 2,-5170.4575, 454.30643,391.4192,  'Drill Sergeant Steamcrank'),
(4232401, 3,-5168.4575, 454.80643,391.6692,  'Drill Sergeant Steamcrank'),
(4232401, 4,-5167.4575, 455.05643,391.9192,  'Drill Sergeant Steamcrank'),
(4232401, 5,-5165.7075, 455.05643,391.9192,  'Drill Sergeant Steamcrank'),
(4232401, 6,-5162.7075, 455.80643,392.1692,  'Drill Sergeant Steamcrank'),
(4232401, 7,-5160.7075, 456.05643,392.4192,  'Drill Sergeant Steamcrank'),
(4232401, 8,-5158.389,  456.63715,392.34637, 'Drill Sergeant Steamcrank - east post'),
(4232401, 9,-5160.922,  456.85504,392.27658, 'Drill Sergeant Steamcrank'),
(4232401,10,-5162.1953, 455.52563,392.47327, 'Drill Sergeant Steamcrank'),
(4232401,11,-5163.068,  454.22745,392.35367, 'Drill Sergeant Steamcrank - third post'),
(4232401,12,-5167.78,   453.7014, 391.68835, 'Drill Sergeant Steamcrank - second post'),
(4232401,13,-5168.5,    453.93402,391.57214, 'Drill Sergeant Steamcrank'),
(4232401,14,-5170.25,   454.43402,391.32214, 'Drill Sergeant Steamcrank'),
(4232401,15,-5171.052,  454.15436,390.99713, 'Drill Sergeant Steamcrank'),
(4232401,16,-5171.552,  454.15436,390.99713, 'Drill Sergeant Steamcrank'),
(4232401,17,-5173.052,  454.15436,390.74713, 'Drill Sergeant Steamcrank'),
(4232401,18,-5173.526,  453.4757, 390.49203, 'Drill Sergeant Steamcrank - west post');

UPDATE `creature_template` SET `AIName`='SmartAI' WHERE `entry`=42324;

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=42324;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(42324,0, 0, 0,11,0,100,0,0,0,0,0,0,'',53,0,4232401,1,0,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - On Respawn - Start Waypoint Movement'),

(42324,0, 1, 2,40,0,100,0, 8,4232401,0,0,0,'',54,8500,0,0,0,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - On Waypoint 8 Reached - Pause Path'),
(42324,0, 2, 3,61,0,100,0,0,0,0,0,0,'',66,0,0,0,0,0,0,8,0,0,0,-5158.389,456.63715,392.34637,5.273177623748779,'Drill Sergeant Steamcrank - Linked - Face The Recruit'),
(42324,0, 3, 0,61,0,100,0,0,0,0,0,0,'',10,5,25,273,274,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - Linked - Play Random Emote'),

(42324,0, 4, 5,40,0,100,0,11,4232401,0,0,0,'',54,8500,0,0,0,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - On Waypoint 11 Reached - Pause Path'),
(42324,0, 5, 6,61,0,100,0,0,0,0,0,0,'',66,0,0,0,0,0,0,8,0,0,0,-5163.068,454.22745,392.35367,5.131268024444580,'Drill Sergeant Steamcrank - Linked - Face The Recruit'),
(42324,0, 6, 0,61,0,100,0,0,0,0,0,0,'',10,5,25,273,274,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - Linked - Play Random Emote'),

(42324,0, 7, 8,40,0,100,0,12,4232401,0,0,0,'',54,8500,0,0,0,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - On Waypoint 12 Reached - Pause Path'),
(42324,0, 8, 9,61,0,100,0,0,0,0,0,0,'',66,0,0,0,0,0,0,8,0,0,0,-5167.78,453.7014,391.68835,4.886921882629395,'Drill Sergeant Steamcrank - Linked - Face The Recruit'),
(42324,0, 9, 0,61,0,100,0,0,0,0,0,0,'',10,5,25,273,274,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - Linked - Play Random Emote'),

(42324,0,10,11,40,0,100,0,18,4232401,0,0,0,'',54,8500,0,0,0,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - On Waypoint 18 Reached - Pause Path'),
(42324,0,11,12,61,0,100,0,0,0,0,0,0,'',66,0,0,0,0,0,0,8,0,0,0,-5173.526,453.4757,390.49203,4.834561824798584,'Drill Sergeant Steamcrank - Linked - Face The Recruit'),
(42324,0,12, 0,61,0,100,0,0,0,0,0,0,'',10,5,25,273,274,0,0,1,0,0,0,0,0,0,0,'Drill Sergeant Steamcrank - Linked - Play Random Emote');

-- -----------------------------------------------------------------------------
-- the trainees: model variants and swing cadence
-- -----------------------------------------------------------------------------

UPDATE `creature` SET `modelid`=31679 WHERE `guid` IN (167474,167475);
UPDATE `creature` SET `modelid`=31678 WHERE `guid` IN (167693,167998);

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=42329;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(42329,0,0,0,1,0,100,0,1000,5000,3600,6100,0,'',87,4232900,4232901,4232902,0,0,0,1,0,0,0,0,0,0,0,'Gnomeregan Trainee - OOC - Run Random Script');

-- -----------------------------------------------------------------------------
-- the three swings, and the dummy's answer to each
-- -----------------------------------------------------------------------------

DELETE FROM `smart_scripts` WHERE `source_type`=9 AND `entryorguid` IN (4232900,4232901,4232902);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(4232900,9,0,0,0,0,100,0,  0,  0,0,0,0,'',11,42880,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Cast ''Cosmetic - Combat Attack 1H'''),
(4232900,9,1,0,0,0,100,0,  0,  0,0,0,0,'',86,78960,0,19,42328,3,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Practice Dummy Casts ''Wound Impact'''),
(4232900,9,2,0,0,0,100,0,350,350,0,0,0,'', 5,33,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Practice Dummy Plays Wound Emote'),

(4232901,9,0,0,0,0,100,0,  0,  0,0,0,0,'',11,44079,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Cast ''Cosmetic - Combat Special Attack 1H'''),
(4232901,9,1,0,0,0,100,0,  0,  0,0,0,0,'',86,78961,0,19,42328,3,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Practice Dummy Casts ''Wound Impact Critical'''),

(4232902,9,0,0,0,0,100,0,  0,  0,0,0,0,'',11,78959,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Cast ''Cosmetic - Combat Attack 1H (Thrust)'''),
(4232902,9,1,0,0,0,100,0,  0,  0,0,0,0,'',86,78960,0,19,42328,3,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Practice Dummy Casts ''Wound Impact'''),
(4232902,9,2,0,0,0,100,0,350,350,0,0,0,'', 5,33,0,0,0,0,0,19,42328,3,0,0,0,0,0,'Gnomeregan Trainee - Practice Dummy Plays Wound Emote');
