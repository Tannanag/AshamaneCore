-- New Tinkertown: give the Crazed Leper Gnomes (46363) their retail idle rhythm.
--
-- On retail the gnomes do not roam continuously. Each one alternates between two
-- server-pushed states:
--
--   frozen   ~31 s, standing perfectly still
--   moving   ~7 s, shuffling at 1.6 yd/s
--
-- This is NOT the visible pose change -- the gnomes also alternate between a feared
-- and a sapped look, and that is a separate, client-side thing driven by the visual
-- of aura 86414 "Leper Gnome Zombie Anim". The server has no part in that one: no
-- spell script, SPELL_AURA_DUMMY with EffectAmplitude 0.0 and EffectAuraPeriod 0,
-- DurationIndex 21 (permanent), and Creature::LoadCreaturesAddon applies it once and
-- skips auras already present. Retail sends these gnomes no emote packets at all --
-- 0 of the 479 SMSG_EMOTE in the sniff are addressed to 46363. Do not reach for this
-- file to change how the gnomes look; it only decides when they move.
--
-- Measured from dump_12.1.0.69465_2026-08-24_18-06-03-Tinkertown-part1.pkt across
-- 48 gnomes: 122 frozen intervals, median 31.0 s, p25 25.1, p75 36.1; 116 moving
-- intervals, median 7.4 s, p25 6.9, p75 8.1. The two states are unmistakable in
-- the sniff -- 629 move packets land inside moving intervals and 4 inside frozen
-- ones, across roughly an hour of frozen time in total.
--
-- The state flips arrive as two adjacent guid-only opcode pairs sent together,
-- which is the shape of SMSG_MOVE_SPLINE_ROOT / SMSG_MOVE_SPLINE_UNROOT (0x2DE5 /
-- 0x2DE6 in this core) alongside the plain root pair -- so retail is rooting and
-- unrooting the creature, not swapping an emote. WowPacketParser has no opcode
-- names for build 12.1.0.69465, so that identification rests on the adjacency and
-- on the behaviour, not on a decoded name; the behaviour is the part being
-- reproduced here and it is measured directly.
--
-- 1.6 yd/s is already correct without touching anything: creature_template.speed_walk
-- for 46363 is 0.64, and 0.64 x 2.5 = 1.6.
--
-- Implementation is two event phases over the MovementType=1 wander added in
-- 2026_08_26_00_world.sql. SmartScript::UpdateTimer returns early for an event
-- whose phase is not current, so the out-of-phase timer is frozen rather than
-- decremented, and the two phases hand off cleanly. RandomMovementGenerator
-- already treats UNIT_STATE_ROOT as UNIT_STATE_NOT_MOVE: it interrupts and calls
-- StopMoving while rooted, keeps its own timer running, and issues the next leg as
-- soon as the root lifts. So no core change is needed and there is no path spam.
--
-- The timers are ranges, not the medians, for two reasons: they match the spread
-- the sniff actually shows, and fixed values would march every gnome in view into
-- lockstep after the first respawn. 25-36 s and 6.5-8 s are the interquartile
-- ranges above.
--
-- Rows 7-9 are the safety net. A gnome that is rooted when a player pulls it would
-- otherwise stand there unable to close, so aggro drops the root and clears the
-- phase; evade puts it back into the frozen phase. UPDATE_OOC does not tick in
-- combat, so the rhythm suspends itself for the duration of the fight anyway.
--
-- Row 0 is the pre-existing Irradiation Aura cast and is reinserted unchanged.
--
-- Scope: entry 46363 only. Entry 46391 has no SmartAI and is left that way.
--
-- Reload with `.reload smart_scripts`.
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

-- event_type 11 is SMART_EVENT_RESPAWN, 1 is SMART_EVENT_UPDATE_OOC, 4 AGGRO,
-- 7 EVADE, 61 SMART_EVENT_LINK. action_type 11 is SMART_ACTION_CAST, 22 is
-- SMART_ACTION_SET_EVENT_PHASE and 103 is SMART_ACTION_SET_ROOT (param1 1 = on,
-- 0 = off). target_type 1 is SMART_TARGET_SELF. event_phase_mask is a bitmask over
-- phases, so 1 is phase 1 and 2 is phase 2.
--
-- No `-- @touched:` line: this file writes smart_scripts, which wpp_apply.py
-- neither snapshots nor reverts. See the revert file named in
-- 2026_08_26_00_world.sql.
