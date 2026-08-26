-- Northshire Valley: take spell 80673 "Camouflage" back off the Blackrock Spies.
--
-- 2026_08_22_01 added 80673 to all 22 spies to make them see-through. It was the
-- wrong spell, on two counts, and both are now settled from evidence rather than
-- inference.
--
-- Reported symptom: it does not stealth them, it wraps them in a leafy particle
-- effect. Confirmed in the client's SpellXSpellVisual.db2 -- 80673 carries
-- SpellVisualID 17071. The reasoning that picked it looked only at
-- SpellEffect.db2, saw a clean SPELL_AURA_MOD_STEALTH with base points 1, and
-- never checked whether the spell drags a visual along with it. It does. By
-- contrast 92857 "Spying" and 93046 "Sneaking" have no visual row at all, which
-- is why those two have always looked clean.
--
-- The second count is that retail does not stealth these NPCs at all. Read out
-- of the sniff rather than guessed: 290 aura-update packets (opcode 670011) in
-- dump_12.1.0.69404 name exactly two spells, and they split perfectly by
-- creature --
--
--   creature                     aura carried            distinct spawns seen
--   ---------------------------  ----------------------  --------------------
--   49874 Blackrock Spy          80676 Spyglass only                       41
--   50039 Goblin Assassin        93046 Sneaking only                        -
--
-- Not one spy carried a stealth or invisibility aura of any kind. So the
-- see-through look this was chasing does not come from an aura on retail, and no
-- aura substitution reproduces it. 80673 is removed and nothing replaces it.
UPDATE `creature_addon` SET `auras`='80676'
 WHERE `guid` IN (178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484);
UPDATE `creature_addon` SET `auras`='92857'
 WHERE `guid` IN (178240,178248,178254,178280,178342,178460,178475);
UPDATE `creature_template_addon` SET `auras`='92857' WHERE `entry`=49874;

-- This restores exactly the aura each spawn carried before 2026_08_22_01, and
-- leaves the rest of that file standing: the 13 spyglass watchers still hold
-- still and face the Abbey, the four patrol routes are untouched, and the two
-- respawn casts stay removed.
--
-- One thing the sniff turned up that is deliberately NOT acted on here. Of the
-- 41 spy spawns observed carrying Spyglass, none was one of the four the sniff
-- resolved a patrol route for -- those four carried no aura at all through the
-- whole capture. So retail looks like "standing spies hold a spyglass,
-- patrolling spies carry nothing", and the 92857 "Spying" this server puts on
-- its patrollers is not corroborated. It is left in place because it predates
-- this pass, has no visual and does no harm, and stripping it is a separate
-- decision from fixing the bug that was reported.
--
-- @touched: creature,creature_addon,creature_template_addon 178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484,178240,178248,178254,178280,178342,178460,178475
