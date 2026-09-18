-- Teldrassil: Tarindrella (49480) walks Shadowthread Cave with each player --
-- summoned for him alone, fighting his fights, barking on his spider kills, naming
-- and felling the Gnarlpine Corruption Totem, and sending him to Dentaria when he
-- takes Signs of Things to Come. From dump_12.1.0.69814_2026-09-14_23-03-16.
--
-- The retail summon chain was already here but dead: spell_area 92237 (area 257,
-- 28725 taken, 28728 not, no 92239) had quest_end_status 2, which this core reads
-- as "only while 28728 is COMPLETE" -- it never fit, and a hand-added permanent
-- Tarindrella (guid 300000001, 2020_03_17_00) stood in for her at the cave lip. The
-- sniff has no such spawn: every Tarindrella in it is CreatedBy the player. The mask
-- becomes 1 (28728 NONE); the static spawn goes; the 92238 condition that refused to
-- summon while any Tarindrella stood within 20 yd -- which blocked every second
-- player -- becomes what retail uses, 92239 "Tarindrella Guardian Aura" on the
-- caster (she puts it on her owner 1.7 s after arriving). The core now also keeps
-- PERSONAL_SPAWN for guardian summons (Spell::SummonGuardian), so a second
-- character does not see her.
--
-- Her SmartAI (follow-less, react passive, a Cleanse Spirit the sniff never shows,
-- three copies of the same 92573 row, a 3 s despawn after the teleport, a data 2
-- nothing ever set) is replaced by npc_tarindrella in zone_teldrassil.cpp, and the
-- text fixes follow the sniff and broadcast_text: 1/1 was cut off, 3/0 read
-- "I'm sorry.." for "I'm so sorry...", the greeting carries emote 1 and reaches the
-- summoner ($c). Githyiss's on-aggro row (data 1/3, "My dear friends...") goes: the
-- sniffer's two Githyiss fights have no such line. His on-death row stays; the AI
-- answers data 1/1. The farewell 49480/4 on 28727's reward is not in the sniff
-- either (nothing is said between the turn-in at 23:33:20 and the teleport at
-- 23:33:24), so nothing triggers it.
--
-- 92420's landing spot had no orientation: the sniffed SMSG_MOVE_TELEPORT faces
-- 3.4732. The totem 1338450 sat 5 yd from its sniffed spot and on the ground; the
-- create block has it at 10935.169 924.026 1340.598 with DisableGravity|Root, which
-- InhabitType 12 (air|root) reproduces.
--
-- Needs the rebuilt worldserver and a restart.

-- Summon chain.
UPDATE `spell_area` SET `quest_end_status`=1 WHERE `spell`=92237 AND `area`=257;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=17 AND `SourceEntry`=92238;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(17,0,92238,0,0,1,0,92239,0,0,1,0,0,'','Summon Tarindrella - only while the caster lacks Tarindrella Guardian Aura');

-- The 2020 stand-in spawn (revert: ~/movement-reverts/2026_09_17_02_world.sql_revert-deleted-300000001.sql).
DELETE FROM `creature_addon` WHERE `guid`=300000001;
DELETE FROM `creature` WHERE `guid`=300000001 AND `id`=49480;

-- Her AI.
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_tarindrella' WHERE `entry`=49480;
DELETE FROM `smart_scripts` WHERE `entryorguid`=49480 AND `source_type`=0;
DELETE FROM `smart_scripts` WHERE `entryorguid`=4948000 AND `source_type`=9;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=22 AND `SourceEntry`=49480;
-- Githyiss keeps only the death row: data 1/1 to every Tarindrella within 20 yd.
DELETE FROM `smart_scripts` WHERE `entryorguid`=1994 AND `source_type`=0 AND `id`=1;

-- Sheathed weapon, as the create block has her.
DELETE FROM `creature_template_addon` WHERE `entry`=49480;
INSERT INTO `creature_template_addon` (`entry`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(49480,0,0,0,0,0,1,0,0,0,0,0,0,'');

-- Texts.
UPDATE `creature_text` SET `Emote`=1 WHERE `CreatureID`=49480 AND `GroupID`=0 AND `ID`=0;
UPDATE `creature_text` SET `Text`='His body screams for death, but his soul screams for mercy.' WHERE `CreatureID`=49480 AND `GroupID`=1 AND `ID`=1;
UPDATE `creature_text` SET `Text`='My dear friends... I''m so sorry...' WHERE `CreatureID`=49480 AND `GroupID`=3 AND `ID`=0;

-- Where Tarindrella's Nature Teleport lands the player.
UPDATE `spell_target_position` SET `Orientation`=3.4732 WHERE `ID`=92420 AND `EffectIndex`=0;

-- The totem.
UPDATE `creature` SET `position_x`=10935.169, `position_y`=924.0261, `position_z`=1340.5984, `orientation`=0.0349 WHERE `guid`=1338450 AND `id`=49598;
UPDATE `creature_template` SET `InhabitType`=12 WHERE `entry`=49598;
