-- Teldrassil: Iverron (8584) and Dentaria Silverglade (49479) at the mouth of
-- Shadowthread Cave in their sick and cured states, and the cure scene at the
-- turn-in of 28724 "Iverron's Antidote".
--
-- Same mechanism as Ilthalaine (2026_09_16_04): nothing is phased, each pair is a
-- permanent spawn under a "Generic Quest Invisibility" aura and the player carries
-- the matching detection for his quest step (spell_area 92549 / 94566, already
-- fixed there):
--   sick   82343 (type 12)  until 28727 "Vile Touch" is rewarded  -- 276862 / 276856, as they were
--   cured  80797 (type 13)  from then on                          -- 300000153 / 300000154, new
-- The 14 Sep sniff has the sick Iverron lying down (StandState 3) under 92564
-- "Poisoned" -- the green sick effect is that spell's visual -- and Dentaria
-- kneeling (8) beside him; both spawns were on the right spot but turned the wrong
-- way (Iverron 4.95 for 0.6677, Dentaria 0.087 for 5.9921). The cured pair stands
-- on the same spots: Iverron turned round to face the path with NpcFlags 3 (gossip
-- + quest giver; he has no quest of his own in the sniff, 28725 comes from
-- Dentaria), Dentaria facing 5.9709. 80797 was on Iverron's creature_template_addon,
-- which would have hidden the sick one from everyone but a player already past
-- 28727 -- it moves to the cured spawn's own row. The three 49479 rows at 0,0,0
-- (1338451/1338452 on map 0, 1338453 on map 1) go; nothing references them
-- (backup: ~/movement-reverts/2026_09_17_00_world_revert-deleted-1338451,1338452,1338453.sql).
--
-- The cure scene is Dentaria's action list 4947900, retimed to the sniff
-- (T0 = the reward of 28724):
--   +0.0  stands up
--   +1.9  casts 87071 Alchemy (a 10 s cast, self)
--   +5.5  turns to Iverron (5.3926), casts 92570 on the player (removes 92551, which
--         this server never applies -- kept for shape) and 92388 "Curing Ivveron",
--         a 1 s cast that cuts the Alchemy cast short and lands on Iverron at +6.5
--   +6.8  turns back, talk emote, "Iverron's poison is cured, but it will take some
--         time for him to recover."
-- Iverron stays asleep: the swap to the cured pair is on 28727's reward, not here.
-- Retail never knelt her again in the nine minutes the sniffer stayed; she kneels
-- again 60 s after the scene so the next player finds the spawn as sniffed. The
-- remove/add-npcflag rows go (she keeps NpcFlags 2 throughout), so does the close
-- gossip. 92388 targets "nearby entry" and had no conditions row, so it fell back
-- to whatever the script handed it; the two rows below make it pick the 8584 that
-- carries 82343 -- the sick one, 0.1 yd from the cured one -- so the cure visual
-- lands on the Iverron the player can see.
--
-- Needs a restart (or .reload creature_addon / smart_scripts / conditions and a
-- respawn of the two guids).

-- Sick pair: the spawns that were there, on the sniffed facings.
UPDATE `creature` SET `position_x`=10547.46,  `position_y`=874.1146, `position_z`=1309.5208, `orientation`=0.6677, `npcflag`=2, `MovementType`=0, `wander_distance`=0 WHERE `guid`=276862;
UPDATE `creature` SET `position_x`=10545.201, `position_y`=875.4375, `position_z`=1309.3625, `orientation`=5.9921, `npcflag`=2, `MovementType`=0, `wander_distance`=0 WHERE `guid`=276856;

-- Cured pair on the same spots.
DELETE FROM `creature` WHERE `guid` IN (300000153, 300000154);
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(300000153, 8584,  1, 6450, 188, '0', 0, 0, 0, -1, 0, 0, 10547.372, 874.191,  1309.529,  2.5019, 300, 0, 0, 1, 0, 0, 3, 0, 0, 0, 0, '', 0),
(300000154, 49479, 1, 6450, 188, '0', 0, 0, 0, -1, 0, 0, 10545.201, 875.4375, 1309.3628, 5.9709, 300, 0, 0, 1, 0, 0, 2, 0, 0, 0, 0, '', 0);

-- The 0,0,0 rows.
DELETE FROM `creature` WHERE `guid` IN (1338451, 1338452, 1338453);
DELETE FROM `creature_addon` WHERE `guid` IN (1338451, 1338452, 1338453);

-- Standstates and the invisibility per spawn; the Poisoned visual on the sick Iverron.
DELETE FROM `creature_addon` WHERE `guid` IN (276862, 276856, 300000153, 300000154);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(276862,    0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, '82343 92564'),
(276856,    0, 0, 8, 0, 0, 1, 0, 0, 0, 0, 0, 0, '82343'),
(300000153, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '80797'),
(300000154, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '80797');
UPDATE `creature_template_addon` SET `auras`=NULL WHERE `entry`=8584;

-- 92388 picks the sick Iverron.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=13 AND `SourceEntry`=92388;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(13, 1, 92388, 0, 0, 51, 0, 3, 8584,  0, 0, 0, 0, '', 'Curing Ivveron targets Iverron'),
(13, 1, 92388, 0, 0, 1,  0, 82343, 0, 0, 0, 0, 0, '', 'Curing Ivveron targets the sick Iverron (under Generic Quest Invisibility 4)');

-- The cure scene.
DELETE FROM `smart_scripts` WHERE `entryorguid`=4947900 AND `source_type`=9;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(4947900, 9, 0, 0, 0, 0, 100, 0, 0,     0,     0, 0, 0, '', 91, 8,     0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Iverron''s Antidote rewarded - stand up'),
(4947900, 9, 1, 0, 0, 0, 100, 0, 1900,  1900,  0, 0, 0, '', 11, 87071, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Iverron''s Antidote rewarded - cast Alchemy'),
(4947900, 9, 2, 0, 0, 0, 100, 0, 3600,  3600,  0, 0, 0, '', 66, 0,     0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 5.3926, 'Dentaria Silverglade - on Iverron''s Antidote rewarded - face Iverron'),
(4947900, 9, 3, 0, 0, 0, 100, 0, 0,     0,     0, 0, 0, '', 11, 92570, 2, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Iverron''s Antidote rewarded - cast Cancel Iverron Mod Aura Vision on the player'),
(4947900, 9, 4, 0, 0, 0, 100, 0, 0,     0,     0, 0, 0, '', 11, 92388, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Iverron''s Antidote rewarded - cast Curing Ivveron'),
(4947900, 9, 5, 0, 0, 0, 100, 0, 1300,  1300,  0, 0, 0, '', 66, 0,     0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Iverron''s Antidote rewarded - face back'),
(4947900, 9, 6, 0, 0, 0, 100, 0, 0,     0,     0, 0, 0, '', 1,  0,     0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Iverron''s Antidote rewarded - say text 0'),
(4947900, 9, 7, 0, 0, 0, 100, 0, 60000, 60000, 0, 0, 0, '', 90, 8,     0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Iverron''s Antidote rewarded - kneel again');

-- The line comes with a talk emote.
UPDATE `creature_text` SET `Emote`=1 WHERE `CreatureID`=49479 AND `GroupID`=0;

-- @touched: creature,creature_addon,creature_template_addon,smart_scripts,creature_text,conditions 276862,276856
