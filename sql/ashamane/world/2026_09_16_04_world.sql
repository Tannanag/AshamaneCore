-- Teldrassil: Ilthalaine (2079) in his three quest states, and the Huntress
-- Sandrya Moonfall (49477) / Dentaria Silverglade (49478) scene at the turn-in of
-- 28713 "The Balance of Nature".
--
-- Retail does not phase Shadowglen. Ilthalaine is three permanent spawns on top of
-- each other, each under a "Generic Quest Invisibility" aura, and the player carries
-- the matching "Quest Invisibility Detection" aura for his own quest step (the
-- spell_area rows below), so each player sees exactly one of them:
--   v1 49415 (type 8)  until 28713's objectives are complete   -- spawn 300000002, as it was
--   v2 49414 (type 7)  from then until 28714's are complete    -- same spot, turned to face the huntresses
--   v3 60921 (type 9)  from then on                            -- 14 yd south-east, "changed position"
-- The switch happens on objective completion, not on turn-in: the 14 Sep sniff has
-- v2 in the same packet burst as QUEST_UPDATE_COMPLETE 28713, v3 after 28714's.
-- The server already had the five player-side rows; three status masks read as
-- "only while COMPLETE" where the sniff says NONE|INCOMPLETE etc. (the core treats
-- both masks as allowed statuses: NONE=1, COMPLETE=2, INCOMPLETE=8, REWARDED=64),
-- and all five were flags 1, which Player::SendQuestUpdate ignores -- the detection
-- aura would only have switched on the next area change. Flags 7 makes it switch
-- the moment the sixth nightsaber dies. 92549/94566 are the Iverron/Dentaria cave
-- pair (item 5) and get the same fix while the rows are being touched.
--
-- The two huntresses are not permanent on retail: they are summoned for the player
-- the instant 28713 goes COMPLETE, under 163465 (invisibility 7, so everyone at that
-- quest step sees them), trade talk emotes with Ilthalaine v2 until the turn-in,
-- play the four lines, run off south and despawn. That is quest_the_balance_of_nature
-- + npc_ilthalaine + npc_ilthalaine_huntress in zone_teldrassil.cpp; the SmartAI
-- action list on Ilthalaine (wrong timings, no emotes or facing or run-off, and
-- "closest Dentaria in 10 yd" so with two players the wrong pair talked) goes, as
-- do the six 2079 rows keyed to the Classic quest ids 3116-3120/26841 -- 28714's
-- accept has no line in the sniff. The permanent pair spawns 302852/302853 go
-- (backup: ~/movement-reverts/2026_09_16_04_world_revert-deleted-302852,302853.sql).
--
-- Needs the rebuilt worldserver and a restart.

-- Ilthalaine v2 and v3 next to v1 (300000002 stays on the sniffed v1 position).
DELETE FROM `creature` WHERE `guid` IN (300000151, 300000152);
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(300000151, 2079, 1, 6450, 188, '0', 0, 0, 0, -1, 0, 1, 10312.728, 830.0555, 1326.5217, 5.4105, 120, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, '', 0),
(300000152, 2079, 1, 6450, 188, '0', 0, 0, 0, -1, 0, 1, 10322.895, 820.3333, 1326.2285, 5.5500, 120, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, '', 0);
UPDATE `creature` SET `position_x`=10312.696, `position_y`=830.1215, `position_z`=1326.533, `orientation`=2.3737, `MovementType`=0, `wander_distance`=0 WHERE `guid`=300000002;

DELETE FROM `creature_addon` WHERE `guid` IN (300000002, 300000151, 300000152);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(300000002, 0, 0, 0, 0, 0, 1, 16, 0, 0, 0, 0, 0, '49415'),
(300000151, 0, 0, 0, 0, 0, 1, 16, 0, 0, 0, 0, 0, '49414'),
(300000152, 0, 0, 0, 0, 0, 1, 16, 0, 0, 0, 0, 0, '60921');

-- Player-side detection, by quest status (see the header).
UPDATE `spell_area` SET `quest_start`=0,     `quest_start_status`=0,  `quest_end`=28713, `quest_end_status`=9,  `flags`=7 WHERE `spell`=49417 AND `area`=188;
UPDATE `spell_area` SET `quest_start`=28713, `quest_start_status`=66, `quest_end`=28714, `quest_end_status`=9,  `flags`=7 WHERE `spell`=49416 AND `area`=188;
UPDATE `spell_area` SET `quest_start`=28714, `quest_start_status`=66, `quest_end`=0,     `quest_end_status`=0,  `flags`=7 WHERE `spell`=60922 AND `area`=188;
UPDATE `spell_area` SET `quest_start`=0,     `quest_start_status`=0,  `quest_end`=28727, `quest_end_status`=11, `flags`=7 WHERE `spell`=92549 AND `area`=188;
UPDATE `spell_area` SET `quest_start`=28727, `quest_start_status`=64, `quest_end`=0,     `quest_end_status`=0,  `flags`=7 WHERE `spell`=94566 AND `area`=188;

-- The huntresses: summoned per player by the quest script, invisible to anyone not
-- at that quest step. The permanent pair goes.
DELETE FROM `creature` WHERE `guid` IN (302852, 302853);
DELETE FROM `creature_addon` WHERE `guid` IN (302852, 302853);
UPDATE `creature_template_addon` SET `auras`='163465' WHERE `entry` IN (49477, 49478);

-- Scripts.
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_ilthalaine' WHERE `entry`=2079;
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_ilthalaine_huntress' WHERE `entry` IN (49477, 49478);
DELETE FROM `smart_scripts` WHERE (`entryorguid` IN (2079, 49478) AND `source_type`=0) OR (`entryorguid` IN (207900, 4947800) AND `source_type`=9);
UPDATE `quest_template_addon` SET `ScriptName`='quest_the_balance_of_nature' WHERE `ID`=28713;

-- Every line in the scene comes with a talk emote on retail.
UPDATE `creature_text` SET `Emote`=1 WHERE (`CreatureID`=2079 AND `GroupID`=0) OR (`CreatureID`=49477 AND `GroupID`=0) OR (`CreatureID`=49478 AND `GroupID` IN (0, 1));

-- @touched: creature,creature_addon,creature_template,creature_template_addon,spell_area,smart_scripts,quest_template_addon,creature_text 300000002
