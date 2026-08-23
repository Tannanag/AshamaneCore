-- Northshire Valley: make the Blackrock Spies see-through, stand the spyglass
-- watchers still, and give the four sniffed spies their patrol routes.
--
-- Reported symptom: the spies are not stealthed at all -- they should not be
-- truly invisible, but see-through. Some should patrol; some should be
-- stationary, holding a spyglass, looking towards the Abbey.
--
-- The zone already encodes that split, one spawn at a time. Of the 22 spies:
--
--   group                    n   creature_addon                     MovementType
--   -----------------------  --  ---------------------------------  ------------
--   spyglass watchers        13  auras 80676, StandState 8 (KNEEL)   1, dist 5
--   patrolling spies          6  auras 92857, StandState 0           1, dist 5
--   patrolling (no addon)     3  falls back to template addon 92857  1, dist 5
--
-- 80676 is "Spyglass" and its aura description is "Peering through a spyglass";
-- 92857 is "Spying". So the intent is already in the data, and two things break
-- it.
--
-- First, every one of the 22 wanders (MovementType 1, wander_distance 5). A spy
-- kneeling behind a spyglass cannot wander off and still be watching anything,
-- and wandering also throws away the orientation each watcher was given. Those
-- orientations are not arbitrary -- checked against the Abbey at about
-- (-8910, -130), they already point at it: 178249 faces 0.73 where the Abbey
-- bears 0.742, 178205 faces 4.63 where it bears 4.548, 178432 faces 0.82 where
-- it bears 0.916. The watchers only need to be told to hold still.
--
-- Second, nothing on any spy applies stealth. 80676 "Spyglass" is
-- SPELL_AURA_DUMMY (4) and 92857 "Spying" is SPELL_AURA_ANIM_REPLACEMENT_SET
-- (312, misc 65) -- an animation and a script hook, neither of which touches
-- visibility. Read out of the client's own Spell.db2 / SpellEffect.db2, not
-- guessed: field mapping confirmed against the three fields that default to
-- 1.0f (ChainAmplitude, PvpMultiplier, GroupSizeBasePointsCoefficient) and
-- cross-checked spell by spell against Wowhead.
--
-- The missing spell is 80673 "Camouflage": one effect, APPLY_AURA
-- SPELL_AURA_MOD_STEALTH (16), base points 1, no misc value. It sits three ids
-- from 80676 "Spyglass" in the same Cataclysm Northshire content batch. Stealth
-- level 1 is below any player's detection, so a spy is never actually hidden --
-- the client draws a detected stealthed unit at partial alpha, which is exactly
-- "not truly invisible, but see through". A real invisibility aura
-- (SPELL_AURA_MOD_INVISIBILITY, 18) would have hidden them outright and is not
-- what retail uses here.

-- 1. Camouflage for every spy, alongside the aura each group already carries.
UPDATE `creature_addon` SET `auras`='80673 80676'
 WHERE `guid` IN (178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484);
UPDATE `creature_addon` SET `auras`='80673 92857'
 WHERE `guid` IN (178240,178248,178254,178280,178460,178475);
-- 178184, 178204 and 178342 have no creature_addon row and inherit this one.
UPDATE `creature_template_addon` SET `auras`='80673 92857' WHERE `entry`=49874;

-- 2. Stand the 13 spyglass watchers still, so the kneel and the facing hold.
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0
 WHERE `id`=49874 AND `guid` IN (178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484);

-- 3. The respawn casts have to go, or the split above cannot survive.
-- smart_scripts casts BOTH 80676 and 92857 on respawn on entry 49874, so every
-- spy ends up with both regardless of which group its spawn belongs to -- and
-- "Spying" is an animation replacement, which is what overrides the kneeling
-- spyglass pose on the 13 watchers. The auras now come from the addon rows,
-- which is where the per-spawn distinction already lives.
DELETE FROM `smart_scripts` WHERE `entryorguid`=49874 AND `source_type`=0 AND `id` IN (1,2);

-- 4. Patrol routes for the four spies the sniff actually resolved.
--
-- Source: dump_12.1.0.69404_2026-08-21_15-30-00.pkt via wpp_patrols.py, decode
-- re-validated for build 69404 (continuity median 0.923 yd, 81.2% of legs at
-- exactly 2.5 yd/s). Coordinates go in as-is.
--
-- All four matched spawns fall in the "Spying" group and none in the kneeling
-- group, which is an independent confirmation of the split above. These are
-- short beats of 6-30 yd, not long circuits. The repeated nodes in 178342 and
-- 178248 are out-and-back return legs, which waypoint_data has to list.

-- 178342 -- matched at 1.483 yd (next candidate 22.1 yd)
--   6 waypoints, out-and-back over 4 nodes, walk (2.27 yd/s)
SET @NPC := 178342;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'80673 92857');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-8832.973,-120.335,80.642,0,0,0,0,100,0),
(@PATH,2,-8831.473,-124.040,80.739,0,0,0,0,100,0),
(@PATH,3,-8842.240,-117.730,80.413,0,0,0,0,100,0),
(@PATH,4,-8831.473,-124.040,80.739,0,0,0,0,100,0),
(@PATH,5,-8832.973,-120.335,80.642,0,0,0,0,100,0),
(@PATH,6,-8837.326,-118.861,80.526,0,0,0,0,100,0);

-- 178460 -- matched at 1.201 yd (next candidate 26.5 yd)
--   3 waypoints, circuit of 3 nodes, walk (2.29 yd/s)
SET @NPC := 178460;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'80673 92857');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-8870.217,-93.738,82.541,0,0,0,0,100,0),
(@PATH,2,-8878.309,-92.227,83.887,0,0,0,0,100,0),
(@PATH,3,-8873.397,-91.309,83.077,0,0,0,0,100,0);

-- 178280 -- matched at 1.158 yd (next candidate 27.4 yd)
--   3 waypoints, circuit of 3 nodes, walk (2.34 yd/s)
--   INCOMPLETE: one gap in the sniff covers ground no lap repeated, so roughly
--   4 further nodes of this route were never observed and are not listed. The
--   three below are the stretch that was seen, and the spy will walk that much.
SET @NPC := 178280;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'80673 92857');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-8929.808,-68.917,89.928,0,0,0,0,100,0),
(@PATH,2,-8922.819,-71.708,89.076,0,0,0,0,100,0),
(@PATH,3,-8926.372,-68.809,89.695,0,0,0,0,100,0);

-- 178248 -- matched at 0.003 yd (next candidate 10.1 yd), the spawn point is a node
--   4 waypoints, out-and-back over 3 nodes, walk (2.23 yd/s)
SET @NPC := 178248;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'80673 92857');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-8975.587,-210.868,74.278,0,0,0,0,100,0),
(@PATH,2,-8982.348,-208.635,74.086,0,0,0,0,100,0),
(@PATH,3,-8982.990,-201.662,74.653,0,0,0,0,100,0),
(@PATH,4,-8982.348,-208.635,74.086,0,0,0,0,100,0);

-- The four addon rows above are rewritten rather than updated because they need
-- a path_id, and each one carries its auras forward explicitly -- an addon row
-- inserted with auras NULL would silently strip the spy of Camouflage and
-- Spying, which is the whole point of this file.
--
-- Left alone on purpose: the five remaining spies in the Spying group (178240,
-- 178254, 178475, 178184, 178204). The sniff resolved no route for them, so
-- they keep MovementType 1 and wander, which is a reasonable stand-in for a spy
-- on the move. Guessing routes for them from no evidence is not.
--
-- @touched: creature,creature_addon,creature_template_addon,smart_scripts,waypoint_data 178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484,178240,178248,178254,178280,178460,178475,178184,178204,178342
