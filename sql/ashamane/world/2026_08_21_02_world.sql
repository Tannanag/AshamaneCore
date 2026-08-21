-- Coldridge Valley: stop five kill-objective mobs claiming to start the quests
-- they are the objective of.
--
-- `creature_queststarter` lists these five as the giver of quests that Grelin
-- Whitebeard (786) and Joren Ironstock (37081) actually give, and
-- `creature_template.npcflag` was set to 2 (UNIT_NPC_FLAG_QUESTGIVER) on each to
-- match, because ObjectMgr::LoadCreatureQuestStarters (ObjectMgr.cpp:8098) logs
-- an sql.sql error for a starter row on a creature without that flag:
--
--   entry  name                          quest                      real giver and ender
--   -----  ----------------------------  -------------------------  --------------------
--     706  Frostmane Troll Whelp         182   The Troll Menace     786 Grelin Whitebeard
--     808  Grik'nir the Cold             218   Ice and Fire         786 Grelin Whitebeard
--   37112  Wayward Fire Elemental        218   Ice and Fire         786 Grelin Whitebeard
--   37514  Grik'nir's Servant            218   Ice and Fire         786 Grelin Whitebeard
--   37073  Rockjaw Goon                  24470 Give 'em What-For    37081 Joren Ironstock
--
-- Nothing is lost by removing them. 786 and 37081 already hold both the
-- `creature_queststarter` and `creature_questender` rows for all three quests,
-- so every quest keeps a giver and a turn-in. None of the three is mob-started
-- by design either -- all are QuestType 2 with StartItem 0, and 182 and 24470
-- carry only flag 524288, so there is no auto-accept path that would need a
-- starter on the objective itself.
--
-- Both halves go in one file on purpose. Clearing npcflag while the starter rows
-- are still there is exactly the case ObjectMgr.cpp:8098 complains about, and
-- deleting the rows while npcflag stays leaves four kill mobs advertising a
-- questgiver flag they have no quest for.
DELETE FROM `creature_queststarter` WHERE `id` IN (706, 808, 37073, 37112, 37514) AND `quest` IN (182, 218, 24470);
UPDATE `creature_template` SET `npcflag`=0 WHERE `entry` IN (706, 808, 37073, 37112, 37514);

-- This is not a fix for the right-click problem in COLDRIDGE-TODO.md section 1
-- and is not expected to change it: 946 Frostmane Novice and 37507 Frostmane
-- Blade already carry npcflag 0 and are just as unclickable, while 37073 and
-- 37112 carried npcflag 2 and were always attackable. It does remove npcflag as
-- a variable from that investigation, which is worth having before the next
-- round of experiments.

-- @touched: creature_queststarter 706,808,37073,37112,37514
-- @touched: creature_template 706,808,37073,37112,37514
