-- New Tinkertown: the Survivors cower, and break out of it to panic.
--
-- They stood idle and silent. The seven lines they are meant to call out have been
-- sitting in creature_text since the spawns were added with nothing to say them, and
-- they had no pose at all.
--
-- Cowering is their resting state, so it goes on the template addon. A cowering gnome
-- cannot play a one-shot over the top of it, so each outburst has to drop the state,
-- throw the animation, and put the state back once the animation has run -- which is a
-- three-step sequence, hence the action lists.
--
-- The outburst is a 20% roll on a timer that comes round every 15 to 20 seconds, and a
-- fifth of those also call out a line. A failed roll still restarts the timer, which is
-- what gives one gnome long uneven silences between outbursts. The initial timer is
-- spread from 5 seconds so the twenty-five of them do not fall into step.
--
-- 431 is EMOTE_STATE_COWER, 18 is EMOTE_ONESHOT_CRY and 20 is EMOTE_ONESHOT_BEG;
-- listing 18 twice in the random pool is what makes crying twice as likely as begging.

UPDATE `creature_template_addon` SET `emote`=431 WHERE `entry`=46268;

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=46268 AND `id` IN (2,3,4);
DELETE FROM `smart_scripts` WHERE `source_type`=9 AND `entryorguid` IN (4626800,4626801);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(46268,0,2,0,1,0,4,0,5000,20000,15000,20000,0,'',80,4626801,0,0,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Out of Combat - Panic and call out'),
(46268,0,3,0,1,0,16,0,5000,20000,15000,20000,0,'',80,4626800,0,0,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Out of Combat - Panic'),

(4626800,9,0,0,0,0,100,0,0,0,0,0,0,'',17,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Stop cowering'),
(4626800,9,1,0,0,0,100,0,1000,1000,0,0,0,'',10,18,18,20,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Cry or beg'),
(4626800,9,2,0,0,0,100,0,5000,5000,0,0,0,'',17,431,0,0,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Cower again'),

(4626801,9,0,0,0,0,100,0,0,0,0,0,0,'',17,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Stop cowering'),
(4626801,9,1,0,0,0,100,0,1000,1000,0,0,0,'',10,18,18,20,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Cry or beg'),
(4626801,9,2,0,0,0,100,0,0,0,0,0,0,'',1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Call out a line'),
(4626801,9,3,0,0,0,100,0,5000,5000,0,0,0,'',17,431,0,0,0,0,0,1,0,0,0,0,0,0,0,'Survivor - Cower again');
