-- New Tinkertown: desynchronise the Crazed Leper Gnome (46363) idle rhythm.
--
-- 2026_08_26_02_world.sql gave the gnomes their retail rhythm -- roughly 31 s
-- rooted, then 7 s shuffling -- but seeded it so every gnome entered the cycle on
-- the same tick and stayed nearly in phase with its neighbours forever after. On a
-- worldserver start all 42 respawn together, SMART_EVENT_RESPAWN fires for all of
-- them at once, and each was rooted into phase 1. So the whole zone froze and
-- unfroze in step.
--
-- What this does NOT fix, and was briefly and wrongly claimed to: the gnomes also
-- alternate visibly between a feared and a sapped pose, in unison, and that is not
-- this. That alternation is client-side animation off the visual of aura 86414
-- "Leper Gnome Zombie Anim" -- no spell script, SPELL_AURA_DUMMY with
-- EffectAmplitude 0.0 and EffectAuraPeriod 0, DurationIndex 21 so it never expires,
-- and Creature::LoadCreaturesAddon applies it once and skips auras already present.
-- Retail sends 46363 no emote packets at all: 0 of the 479 SMSG_EMOTE in the sniff.
-- The server never toggles it, so nothing in smart_scripts can stagger it. The only
-- server-side lever on that one is when the aura first lands on each gnome, which
-- would mean moving 86414 off creature_template_addon and casting it on a random
-- delay -- deliberately not done here.
--
-- Two changes, both aimed only at the root cycle.
--
-- The starting phase is now drawn per gnome with SMART_ACTION_RANDOM_PHASE_RANGE
-- over phases 1-2, so half start frozen and half start mid-shuffle. Root on respawn
-- is kept: frozen is the state a gnome is in about 80% of the time, so it is the
-- right default, and one that draws phase 2 while already rooted simply re-roots,
-- which is a no-op. Evade re-draws it too, so a pack pulled and dropped together
-- does not resume on a single tick.
--
-- And the timers move from the interquartile ranges, 25-36 s and 6.5-8 s, to
-- 20-42 s and 5.5-9.5 s. Even desynchronised, an 11 s spread against a ~38 s cycle
-- leaves little room to drift. This doubles it while keeping the mean where the
-- sniff put it: uniform(20000,42000) means 31.0 s against a measured mean of 31.4
-- and median of 31.0, and uniform(5500,9500) means 7.5 s against a measured median
-- of 7.4. The measured frozen intervals run 20.2-55.1 s, so this trades the long
-- tail for a correct mean rather than widening symmetrically.
--
-- Rows are otherwise as 2026_08_26_02_world.sql left them; row 0 is still the
-- pre-existing Irradiation Aura cast. That file is already recorded in `updates`,
-- so this is a new file rather than an edit to it.
--
-- Reload with `.reload smart_scripts`. Existing gnomes keep whatever phase they are
-- in until they respawn, so the zone desynchronises gradually rather than at once;
-- a worldserver restart applies it to all 42 immediately.
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

-- action_type 31 is SMART_ACTION_RANDOM_PHASE_RANGE, param1/param2 PhaseMin and
-- PhaseMax, drawn with an inclusive urand -- so 1,2 is an even split over the two
-- phases. 22 is SMART_ACTION_SET_EVENT_PHASE, 103 SMART_ACTION_SET_ROOT (1 on,
-- 0 off), 11 SMART_ACTION_CAST. event_type 11 RESPAWN, 1 UPDATE_OOC, 4 AGGRO,
-- 7 EVADE, 61 LINK. target_type 1 is SMART_TARGET_SELF.
--
-- No `-- @touched:` line: this file writes smart_scripts, which wpp_apply.py
-- neither snapshots nor reverts. See the revert file named in
-- 2026_08_26_00_world.sql.
