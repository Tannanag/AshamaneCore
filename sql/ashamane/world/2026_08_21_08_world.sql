
-- Rockjaw Scavenger: make the thrown artifact for quest 24486 actually reach the player.
--
-- Two faults. The SAI fired on SMART_EVENT_AGGRO, but 69897 has a 5-15 yd range and
-- aggro distance scales with the level gap, so a high-level player is already inside
-- the minimum range when the trogg notices them and the cast is rejected.
-- SMART_EVENT_RANGE measures the same window, so 5/15 means "whenever the spell would
-- succeed" -- and a scavenger pulled from melee never enters it, which is the intended rule.
--
-- Second, 69897's TRIGGER_MISSILE effect names no implicit target, so
-- Spell::EffectTriggerMissileSpell aims the item grant at the caster. That half is fixed
-- in spell_throw_priceless_artifact, registered below.
UPDATE `smart_scripts` SET
    `event_type`=9, `event_param1`=5, `event_param2`=15, `event_param3`=0, `event_param4`=0,
    `comment`='Rockjaw Scavenger - Between 5-15 Range - Cast Throw Priceless Artifact'
WHERE `entryorguid`=37105 AND `source_type`=0 AND `id`=0;

-- 2. The item never arrived even when the spell landed, because 69897 effect 1
--    (TRIGGER_MISSILE -> 104959 CREATE_ITEM) names no implicit target and so is
--    dispatched as SPELL_EFFECT_HANDLE_HIT. Spell::EffectTriggerMissileSpell then
--    takes its no-target branch and does targets.SetUnitTarget(m_caster), aiming
--    the item grant at the trogg. That half is fixed in
--    spell_throw_priceless_artifact (zone_dun_morogh_area_coldridge_valley.cpp),
--    which re-aims the trigger at the unit effect 0 hit and carries the quest gate.
DELETE FROM `spell_script_names` WHERE `spell_id`=69897 AND `ScriptName`='spell_throw_priceless_artifact';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(69897, 'spell_throw_priceless_artifact');

-- Deliberately kept: creature_loot_template (37105, 49751, 100%, QuestRequired=1).
-- A scavenger pulled from range and then killed yields two artifacts, and one is
-- enough if you pull it in melee.
