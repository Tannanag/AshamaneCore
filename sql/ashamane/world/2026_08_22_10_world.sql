-- Northshire Valley: give the 13 spyglass watchers the "Spying" aura as well, so
-- they are see-through like the patrolling spies.
--
-- The two groups were split one aura each: 80676 "Spyglass" on the 13 kneeling
-- watchers, 92857 "Spying" on the 7 patrollers. After 2026_08_22_02 attached the
-- see-through visual to both spells, only the patrollers turned translucent.
--
-- The reason is in the client's SpellXSpellVisual data rather than in anything on
-- the creatures. 92857 had no visual of its own, so the added SpellVisualID 18332
-- was uncontested. 80676 already carried 17072, the spyglass, and a spell shows
-- one visual -- so Spyglass kept drawing the spyglass and the watchers stayed
-- solid. The added row on 80676 is removed in 2026_08_22_03_hotfixes.sql.
--
-- One spell cannot supply both looks, but two auras can. The watchers keep 80676
-- for the spyglass and gain 92857 for the translucency, each spell rendering its
-- own visual. The patrollers are already correct and are not touched.
UPDATE `creature_addon` SET `auras`='80676 92857'
 WHERE `guid` IN (178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484);

-- Worth watching in game: 92857 also applies SPELL_AURA_ANIM_REPLACEMENT_SET with
-- misc 65, the sneaking animation. On a spawn kneeling at StandState 8 with a
-- spyglass that may override the pose, which is the exact concern that led to the
-- two respawn casts being removed from smart_scripts in 2026_08_22_01. That was a
-- prediction then and was never tested, because the casts gave every spy both
-- auras indiscriminately rather than by group. This is the controlled version of
-- the same thing: if the watchers stand up or stop peering, the fix is to revert
-- this one statement and accept solid watchers, since no single spell in this
-- client carries the spyglass and the translucency together.
--
-- @touched: creature,creature_addon 178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484
