-- Coldridge Valley: Frostmane and beast fixes. Every entry here spawns only in
-- areas 132 and 6137, so these template changes cannot reach another zone.

-- Neutral, but attackable. The trolls could be hit with an ability but not
-- right-clicked, because two separate bits in FactionTemplate.db2 govern it:
-- FactionGroup decides hostile-vs-neutral (FactionTemplateEntry::IsHostileTo), and
-- Flags 0x400 is what makes a neutral unit answer a right-click at all -- read purely
-- client-side, which is why no server flag explained the symptom. They sat on 190/2136,
-- which point at Faction 148, the generic wildlife faction shared with Toad and Roach.
-- The Frostmane faction is not the fix either: all three templates on Faction 33 carry
-- FactionGroup 8 and are hostile on sight. 189 is FactionGroup 0 plus 0x400, and is what
-- Small Crag Boar already uses in this zone. The two wolves join them -- they were on 32,
-- which fails IsNeutralToAll and drew a red name frame.
-- Accepted: 189 has an empty Friend[], so these do not assist each other.
UPDATE `creature_template` SET `faction`=189 WHERE `entry` IN (704, 705, 706, 808, 946, 37507);
-- 704 Ragged Timber Wolf, 705 Ragged Young Wolf, 706 Frostmane Troll Whelp,
-- 808 Grik'nir the Cold, 946 Frostmane Novice, 37507 Frostmane Blade

-- Five kill-objective mobs were listed as the giver of the quest they are the objective
-- of, with npcflag 2 set to match. Both halves must go together, or the remaining one
-- trips the sql.sql error in ObjectMgr::LoadCreatureQuestStarters. Nothing is lost:
-- 786 Grelin Whitebeard and 37081 Joren Ironstock already hold the starter and ender
-- rows for quests 182, 218 and 24470.
DELETE FROM `creature_queststarter` WHERE `id` IN (706, 808, 37073, 37112, 37514) AND `quest` IN (182, 218, 24470);
UPDATE `creature_template` SET `npcflag`=0 WHERE `entry` IN (706, 808, 37073, 37112, 37514);

-- Whelps fled at 15% health. SMART_ACTION_FLEE_FOR_ASSIST is the only caller of
-- Creature::DoFleeToGetAssistance and no flags_extra bit suppresses it, so the row goes
-- rather than a flag. Row 1, the bark at the same threshold, stays.
DELETE FROM `smart_scripts` WHERE `entryorguid`=706 AND `source_type`=0 AND `id`=0; -- Frostmane Troll Whelp - Flee at 15% HP

-- Grik'nir wears a permanent self-applied aura on retail; it is what gives him his
-- spell visual. One spawn, so entry scope is spawn scope.
UPDATE `creature_template_addon` SET `auras`='80631' WHERE `entry`=808; -- Grik'nir the Cold - Cold Heart

-- Quest 24475 wants 3x Boar Haunch to 4x Ragged Wolf Hide, but the boar dropped at
-- 39.36% against the wolves' ~65%, costing nearly as many kills for 3 as they cost for 4.
UPDATE `creature_loot_template` SET `Chance`=70 WHERE `Entry`=708 AND `Item`=49747; -- Small Crag Boar -> Boar Haunch
