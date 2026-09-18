-- Teldrassil: the green Poisoned effect on the sick Iverron (8584) is drawn by the
-- client only for a viewer with the matching aura vision.
--
-- 92564 "Poisoned" was already on Iverron's creature_addon (2026_09_17_00), but its
-- visual (SpellXSpellVisual 40648) is gated client-side on the player's aura-vision
-- byte. Retail gives the player 92551 "Mod Aura Vision, Quest Zone-Specific 01"
-- (SPELL_AURA_DETECT_AMORE type 3): the 14 Sep sniff has it cast on the player at
-- login, refreshed on every quest update in Shadowglen, and removed by Dentaria's
-- 92570 at +5.5 s of the cure scene -- which is how the green goes away for that
-- player while the shared Iverron keeps the aura. The core stubbed DETECT_AMORE
-- (HandleNULL); it now sets the vision bit (SpellAuraEffects.cpp HandleDetectAmore).
--
-- Autocast only (flags 1): no autoremove, so the reward of 28724 does not strip the
-- aura before the cure lands; 92570 removes it, and once 28724 is REWARDED the row
-- no longer fits so it is not cast again on the next area change.
--
-- Needs the rebuilt worldserver and a restart.
DELETE FROM `spell_area` WHERE `spell`=92551 AND `area`=188;
INSERT INTO `spell_area` (`spell`,`area`,`quest_start`,`quest_end`,`aura_spell`,`teamId`,`racemask`,`gender`,`flags`,`quest_start_status`,`quest_end_status`) VALUES
(92551, 188, 0, 28724, 0, -1, 0, 2, 1, 0, 11);
