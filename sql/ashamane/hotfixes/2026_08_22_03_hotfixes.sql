-- Northshire Valley: drop the second spell visual added to "Spyglass". It never
-- took effect and it makes the spell ambiguous.
--
-- 2026_08_22_02 attached SpellVisualID 18332 -- Gavin Marlsbury's see-through
-- visual -- to both 80676 "Spyglass" and 92857 "Spying". It worked on Spying and
-- did nothing on Spyglass, and the client's own data says why:
--
--   spell   native SpellXSpellVisual row
--   ------  ---------------------------------
--   92857   none at all
--   80676   SpellVisualID 17072 (the spyglass itself)
--
-- Spying had no visual, so the added row was the only one and the client used it.
-- Spyglass already had 17072, so the added row was a second candidate at the same
-- Probability 1 and Priority 0, and the client went on drawing the spyglass. The
-- watchers stayed solid.
--
-- A spell cannot show two of these at once, and raising the priority of 18332
-- would win the translucency by throwing away the spyglass, which is the one
-- thing those 13 spawns exist to be doing. So the visual is removed from Spyglass
-- here and the translucency is carried by a second aura instead -- see
-- 2026_08_22_10_world.sql, which gives the watchers 92857 alongside 80676 so each
-- spell contributes its own visual.
DELETE FROM `spell_x_spell_visual` WHERE `ID`=251499;
DELETE FROM `hotfix_data` WHERE `TableHash`=0x27B7A01A AND `RecordId`=251499;

-- 251500 stays: that is the row on 92857 "Spying", which is doing exactly what it
-- was meant to and is now what makes both groups of spies see-through.
--
-- Needs a worldserver restart, not a reload.
