-- Coldridge Valley: throw the Priceless Rockjaw Artifact from throwing range,
-- and let the throw itself deliver the item.
--
-- 2026_08_19_04_world.sql got the artifact into the bag by casting the
-- item-granting half of the chain (104959) as a second, triggered SAI action on
-- aggro. That works in the sense that the quest can be finished, but nothing is
-- thrown: 104959 is instant, invisible and rangeless, so the artifact simply
-- appears. The visible half, 69897, was left to fend for itself and never fires.
--
-- Both halves are fixed here, one in the core scripts and one in this file.
--
--
-- 1. Why 69897 never lands, and why SMART_EVENT_AGGRO is the wrong trigger.
--
-- 69897 uses SpellRange 179, which is MinRange 5 / MaxRange 15 (read out of
-- SpellRange.db2; the row's two 64-bit fields pack RangeMin1/2 and RangeMax1/2).
-- Spell::GetMinMaxRange widens both ends by the combat reach of caster plus
-- target, and SpellRange 179 has no flags, so for a Rockjaw Scavenger
-- (CombatReach 1.05) against a player (~1.5) the spell is castable only when the
-- two are between roughly 7.5 and 17.5 yards apart, centre to centre.
--
-- SMART_EVENT_AGGRO fires at whatever distance the trogg noticed the player, and
-- Creature::GetAttackDistance makes that distance depend on the level gap:
--
--     aggroRadius = 20 - CombatReach + (creatureLevel - playerLevel), clamped [5, 45]
--
-- The scavenger is level 2, so:
--
--     player level   aggro radius   inside the 7.5 - 17.5 window?
--     ------------   ------------   -----------------------------
--       1 -  3        ~19 - 18      no, too far
--       4 - 12        ~17 -  9      yes
--        65             5 (clamp)   no, too close
--
-- which is why the throw looked dead on a high-level test character: at level 65
-- a level 2 trogg cannot notice you until you are already inside its minimum
-- range, so Spell::CheckRange rejects the cast and no animation plays. Nothing
-- was wrong with the SAI row; the event just hands it a distance the spell
-- cannot use.
--
-- SMART_EVENT_RANGE (event_type 9, SmartScriptMgr.h:123) is measured against the same window with the same combat
-- reaches (WorldObject::IsInRange adds the size factor to both ends exactly as
-- Spell::GetMinMaxRange does), so 5 / 15 here means precisely "whenever the
-- spell would succeed". The trogg is pulled, runs in, and the first tick it is
-- within throwing distance it stops -- a creature with a cast time is held still
-- by TargetedMovementGenerator's IsMovementPreventedByCasting check -- throws
-- once, then closes to melee.
--
-- That also keeps the intended rule without a condition row: a scavenger pulled
-- from inside 7.5 yards never enters the window on its way to you, so walking
-- into melee gets you a plain melee fight and no artifact. Backing off mid-fight
-- does earn a throw, which is what retail does too.
--
-- event_flags 1 (SMART_EVENT_FLAG_NOT_REPEATABLE) is kept, so this is one throw
-- per pull rather than one per tick spent at range; SmartScript::OnReset clears
-- runOnce, so a scavenger that evades or respawns can throw again.
SET @ENTRY := 37105;

UPDATE `smart_scripts` SET
    `event_type`=9, `event_param1`=5, `event_param2`=15, `event_param3`=0, `event_param4`=0,
    `comment`='Rockjaw Scavenger - Between 5-15 Range - Cast Throw Priceless Artifact'
WHERE `entryorguid`=@ENTRY AND `source_type`=0 AND `id`=0;

-- 2. Retire the parallel item grant.
--
-- The artifact now rides on the throw (see spell_throw_priceless_artifact in
-- src/server/scripts/EasternKingdoms/zone_dun_morogh_area_coldridge_valley.cpp),
-- which re-aims 69897's TRIGGER_MISSILE effect at the unit its damage effect hit
-- instead of at the caster, and keeps the quest gate that used to live in the
-- conditions row below. Granting the item from a second SAI action would now
-- hand out two artifacts per pull, one of them out of nowhere.
DELETE FROM `smart_scripts` WHERE `entryorguid`=@ENTRY AND `source_type`=0 AND `id`=1;
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=22 AND `SourceEntry`=@ENTRY AND `SourceId`=0 AND `SourceGroup`=2;

DELETE FROM `spell_script_names` WHERE `spell_id`=69897 AND `ScriptName`='spell_throw_priceless_artifact';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(69897, 'spell_throw_priceless_artifact');

-- Still deliberately kept, as in 2026_08_19_04: creature_loot_template
-- (37105, 49751, 100%, QuestRequired=1). A scavenger you pull from range and
-- then kill yields two artifacts, and one is enough if you pull it in melee.

-- @touched: smart_scripts 37105
-- @touched: conditions 37105
-- @touched: spell_script_names 69897
