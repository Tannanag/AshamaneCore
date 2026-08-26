-- Northshire Valley: give Kurtok the Slayer his two barks.
--
-- Kurtok (42938) is the named Blackrock at the end of quest 26390 and says
-- nothing at all. He has no AI whatsoever -- creature_template.AIName and
-- ScriptName are both empty, there are no creature_text rows and no smart_scripts
-- rows -- so all three pieces are added here.
--
-- The two lines are from Wowhead's page for the NPC, which lists them without
-- saying when either is used; the aggro/death assignment is from the report, not
-- from Wowhead:
--
--   on aggro  "Alliance weakling, your lands will burn!"
--   on death  "The Blackrock Clan will end you..."
--
-- BroadcastTextId stays 0 rather than pointing at the real broadcast text. This
-- server's BroadcastText.db2 is a 362 KB stub rather than the full store -- it
-- contains no "Kurtok", no "weakling" and no "your lands" anywhere, so there is
-- no id here to reference. Every other creature_text row in this zone (Blackrock
-- Spy 49874, Goblin Assassin 50039) is written the same way.
--
-- Type 12 is CHAT_MSG_MONSTER_SAY rather than 14 MONSTER_YELL. That is a
-- judgement call: Kurtok is a named mob but `rank` 0, an ordinary level 5, and
-- every neighbouring Blackrock in the zone uses 12. Change both rows to 14 if he
-- should carry across the vineyard.
--
-- Probability 100 rather than the 50 used by his neighbours: they have three
-- alternative lines in one group and split the roll between them, while each of
-- these groups holds a single line and must always fire.
DELETE FROM `creature_text` WHERE `CreatureID`=42938;
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(42938,0,0,'Alliance weakling, your lands will burn!',12,0,100,0,0,0,0,0,'Kurtok the Slayer - on Aggro'),
(42938,1,0,'The Blackrock Clan will end you...',12,0,100,0,0,0,0,0,'Kurtok the Slayer - on Death');

-- SmartAI has to be switched on for him, or the smart_scripts rows below are
-- inert. He has no ScriptName, so nothing is being displaced by this --
-- FactorySelector::selectAI would otherwise fall through to a default AI with no
-- text handling at all.
UPDATE `creature_template` SET `AIName`='SmartAI' WHERE `entry`=42938;

DELETE FROM `smart_scripts` WHERE `entryorguid`=42938 AND `source_type`=0;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(42938,0,0,0,4,0,100,0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Kurtok the Slayer - On Aggro - Say Line 0'),
(42938,0,1,0,6,0,100,0,0,0,0,0,1,1,0,0,0,0,0,1,0,0,0,0,0,0,0,'Kurtok the Slayer - On Death - Say Line 1');

-- event_type 4 is SMART_EVENT_AGGRO and 6 is SMART_EVENT_DEATH; action_type 1 is
-- SMART_ACTION_TALK with action_param1 as the creature_text GroupID. Neither
-- event carries SMART_EVENT_FLAG_NOT_REPEATABLE: aggro should fire on every pull
-- and death is once per life anyway.
--
-- Scope: entry 42938 has exactly one spawn in the world (guid 178468, Northshire),
-- and it is the objective of quest 26390, so nothing outside this zone is reached.
--
-- Reload with `.reload creature_text` and `.reload smart_scripts`. The AIName
-- change needs `.reload creature_template 42938` and a respawn, since the AI is
-- picked when the creature is created.
