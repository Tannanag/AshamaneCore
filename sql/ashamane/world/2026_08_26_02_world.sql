-- New Tinkertown: idle rhythm for the Crazed Leper Gnome (46363).
--
-- Roots them ~31 s, then lets them shuffle ~7 s, as two SmartAI phases over the
-- MovementType=1 wander. Needs no core change: an out-of-phase timer freezes
-- rather than drains, and RandomMovementGenerator treats UNIT_STATE_ROOT as
-- UNIT_STATE_NOT_MOVE. Aggro unroots so a rooted gnome is never stuck unable to
-- close.
--
-- Does not control the feared/sapped pose alternation -- that is client-side
-- animation off aura 86414, which the server applies once and never toggles.
DELETE FROM `smart_scripts` WHERE `entryorguid`=46363 AND `source_type`=0;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(46363,0,0,0,11,0,100,0,0,0,0,0,0,11,80653,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - On Respawn - Irradiation Aura'),
(46363,0,1,2,11,0,100,0,0,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - On Respawn - Set Phase 1 (frozen)'),
(46363,0,2,0,61,0,100,0,0,0,0,0,0,103,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - Linked - Root'),
(46363,0,3,4,1,1,100,0,25000,36000,25000,36000,0,103,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - OOC 25-36s in Phase 1 - Unroot'),
(46363,0,4,0,61,0,100,0,0,0,0,0,0,22,2,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - Linked - Set Phase 2 (moving)'),
(46363,0,5,6,1,2,100,0,6500,8000,6500,8000,0,103,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - OOC 6.5-8s in Phase 2 - Root'),
(46363,0,6,0,61,0,100,0,0,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - Linked - Set Phase 1 (frozen)'),
(46363,0,7,0,4,0,100,0,0,0,0,0,0,103,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - On Aggro - Unroot'),
(46363,0,8,9,7,0,100,0,0,0,0,0,0,22,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - On Evade - Set Phase 1 (frozen)'),
(46363,0,9,0,61,0,100,0,0,0,0,0,0,103,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Crazed Leper Gnome - Linked - Root');

-- event 11 RESPAWN, 1 UPDATE_OOC, 4 AGGRO, 7 EVADE, 61 LINK; action 11 CAST,
-- 22 SET_EVENT_PHASE, 31 RANDOM_PHASE_RANGE, 103 SET_ROOT; target 1 SELF.
