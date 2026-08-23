-- Northshire Valley: give the Blackrock Spies the stealth half of their spell
-- pair, so they render see-through instead of solid.
--
-- 2026_08_22_05 removed 80673 "Camouflage" because it painted the spies in leafy
-- particles (SpellVisualID 17071) instead of stealthing them, and noted that the
-- sniff shows no stealth aura on any spy. That second point was correct but it
-- was the wrong conclusion to stop at, because it treated "no stealth aura in
-- the capture" as "stealth is not how this works". Following the spell family
-- through shows what the data actually says.
--
-- 92857 "Spying" carries the description "Puts the caster in stealth mode. Lasts
-- until cancelled." That string is not boilerplate. Exactly 13 spells in
-- Spell.db2 share it, and every one is a stealth spell:
--
--   5916 Shadowstalker Stealth   6920 Hide            30831 Stealth
--  42932 Prowl                  86237 Stalking        92857 Spying
--  93046 Sneaking             119908 Taoshi Force   152891 Saberon Stealth
-- 158183 Prowl                 163912 Elusion        205985 Camouflage
-- 234160 Normal Phase
--
-- Ten of the thirteen apply SPELL_AURA_MOD_STEALTH. Exactly three do not, and
-- those three -- 86237 "Stalking", 92857 "Spying", 93046 "Sneaking" -- are
-- byte-identical to each other: APPLY_AURA, SPELL_AURA_ANIM_REPLACEMENT_SET
-- (312), base points 1, misc 65. They are the animation half of a two-spell
-- pair. The crouch pose and the transparency are separate spells, and Spying
-- only ever supplied the pose. Nothing on this server supplied the other half,
-- which is exactly why the spies were solid.
--
-- The visual is the other half of the earlier mistake. SpellVisualID 184 is
-- shared by Prowl, Stealth, Hide and Shadowstalker Stealth -- it is the game's
-- standard stealth appearance, which is the translucency itself rather than an
-- effect layered on top. 80673's 17071 was a bespoke visual belonging to one
-- Cataclysm quest spell, which is why it looked like leaves and 184 will not.
--
-- 84442 "Stealth" is the spell used here:
--   - SPELL_AURA_MOD_STEALTH with base points 1. Stealth level 1 is below every
--     player's detection, so a spy is never actually hidden -- it is always seen
--     and always drawn at partial alpha. That is "see-through, not invisible".
--   - SpellVisualID 184, the standard stealth appearance.
--   - No SPELL_AURA_ANIM_REPLACEMENT_SET, so it does not fight the kneeling
--     spyglass pose on the 13 watchers the way Spying would.
--   - Already in use on this server on 31 "7th Legion Scout" spawns, the same
--     scout-and-watch archetype, so it is proven on this core rather than
--     inferred from DB2 alone.
UPDATE `creature_addon` SET `auras`='80676 84442'
 WHERE `guid` IN (178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484);
UPDATE `creature_addon` SET `auras`='92857 84442'
 WHERE `guid` IN (178240,178248,178254,178280,178342,178460,178475);
UPDATE `creature_template_addon` SET `auras`='92857 84442' WHERE `entry`=49874;

-- Stated plainly: this is a deliberate departure from the sniff. 290 aura-update
-- packets in dump_12.1.0.69404 show 41 distinct Blackrock Spy spawns carrying
-- 80676 "Spyglass" and nothing else, so retail today does not put a stealth aura
-- on them and a strictly retail-faithful zone would leave them solid. This adds
-- the stealth half anyway because the spies are meant to read as hidden
-- watchers, which is what the whole Spying/Spyglass/kneel arrangement is for.
-- Reverting is this file alone; 2026_08_22_05 is the retail-exact state.
--
-- @touched: creature,creature_addon,creature_template_addon 178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484,178240,178248,178254,178280,178342,178460,178475
