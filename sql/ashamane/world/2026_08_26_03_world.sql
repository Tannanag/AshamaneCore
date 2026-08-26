-- New Tinkertown: desynchronise the Crazed Leper Gnome (46363) idle rhythm.
--
-- All 42 respawn in one tick on a server start and were all rooted into phase 1,
-- so the zone froze and unfroze in step. The starting phase is now drawn per
-- gnome, and the timers widen from 25-36 s / 6.5-8 s to 20-42 s / 5.5-9.5 s;
-- uniform(20000,42000) keeps the measured 31.0 s mean while doubling the spread.
--
-- Does not affect the pose alternation; see 2026_08_26_02_world.sql.
DELETE FROM `smart_scripts` WHERE `entryorguid`=46363 AND `source_type`=0;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(46363,0,0,0,11,0,100,0,0,0,0,0,0,11,80653,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - On Respawn - Irradiation Aura'),
(46363,0,1,2,11,0,100,0,0,0,0,0,0,31,1,2,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - On Respawn - Random Phase 1-2'),
(46363,0,2,0,61,0,100,0,0,0,0,0,0,103,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - Linked - Root'),
(46363,0,3,4,1,1,100,0,20000,42000,20000,42000,0,103,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - OOC 20-42s in Phase 1 - Unroot'),
(46363,0,4,0,61,0,100,0,0,0,0,0,0,22,2,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - Linked - Set Phase 2 (moving)'),
(46363,0,5,6,1,2,100,0,5500,9500,5500,9500,0,103,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - OOC 5.5-9.5s in Phase 2 - Root'),
(46363,0,6,0,61,0,100,0,0,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - Linked - Set Phase 1 (frozen)'),
(46363,0,7,0,4,0,100,0,0,0,0,0,0,103,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - On Aggro - Unroot'),
(46363,0,8,9,7,0,100,0,0,0,0,0,0,31,1,2,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - On Evade - Random Phase 1-2'),
(46363,0,9,0,61,0,100,0,0,0,0,0,0,103,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - Linked - Root');

-- event 11 RESPAWN, 1 UPDATE_OOC, 4 AGGRO, 7 EVADE, 61 LINK; action 11 CAST,
-- 22 SET_EVENT_PHASE, 31 RANDOM_PHASE_RANGE, 103 SET_ROOT; target 1 SELF.
