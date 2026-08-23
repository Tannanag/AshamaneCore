-- Northshire Valley: make the Blackrock Spies translucent with the CREEP stand
-- flag instead of a stealth aura, so they are see-through at every range rather
-- than hidden until you are on top of them.
--
-- 2026_08_22_06 gave the spies 84442 "Stealth" to get the see-through look. The
-- reasoning was right about where translucency comes from and wrong about the
-- cost of getting there that way.
--
-- What actually draws a unit see-through is not the stealth aura itself. It is
-- UNIT_STAND_FLAGS_CREEP (0x02) in the visFlags byte of UNIT_FIELD_BYTES_1.
-- AuraEffect::HandleModStealth (SpellAuraEffects.cpp:1592) sets exactly that:
--
--     target->SetStandFlags(UNIT_STAND_FLAGS_CREEP);
--
-- so a stealth aura is one way to raise the flag, not the thing the client reads.
--
-- The cost is in WorldObject::CanDetectStealthOf (Object.cpp:2334). Any unit with
-- a stealth flag set becomes invisible past a detection radius:
--
--     detectionValue  = 30 + (seerLevel - 1) * 5 - targetStealthValue
--     visibilityRange = detectionValue * 0.3 + combatReach
--
-- With 84442's stealth value of 1, a level 1 player gets 30 + 0 - 1 = 29, so
-- 29 * 0.3 + reach, call it ten yards. A level 5 gets about fifteen. Outside that
-- the spy is not translucent, it is gone -- and it also has to be inside the
-- player's forward arc to be seen at all (the HasInArc check in the same
-- function). "Invisible until you are ten yards away, then suddenly there" is not
-- what was asked for; see-through at normal viewing distance is.
--
-- creature_addon has a VisFlags column that holds UnitStandFlags directly, which
-- is the flag without the stealth mechanic. It did nothing until now: ObjectMgr
-- read it into CreatureAddon::visFlags at both load sites and nothing in the
-- entire server ever read that member back. Creature::LoadCreaturesAddon applied
-- standState, sheathState, emote, visibilityDistanceType, path_id and auras, and
-- skipped visFlags. That is fixed in the core alongside this file; without that
-- change these three statements have no effect.
--
-- 2 is UNIT_STAND_FLAGS_CREEP (UnitDefines.h:54).
UPDATE `creature_addon` SET `VisFlags`=2, `auras`='80676'
 WHERE `guid` IN (178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484);
UPDATE `creature_addon` SET `VisFlags`=2, `auras`='92857'
 WHERE `guid` IN (178240,178248,178254,178280,178342,178460,178475);
UPDATE `creature_template_addon` SET `VisFlags`=2, `auras`='92857' WHERE `entry`=49874;

-- The auras go back to what each spawn carried before 2026_08_22_06: Spyglass on
-- the 13 watchers, Spying on the patrollers. Both are cosmetic, neither affects
-- visibility, and both are what the sniff supports -- 41 distinct spy spawns in
-- dump_12.1.0.69404 carry 80676 and no stealth aura of any kind.
--
-- That absence now reads as evidence rather than a puzzle. Retail has no stealth
-- aura on these NPCs because retail does not need one: the CREEP flag travels in
-- the creature's own unit data, not as an aura, so it would never appear in an
-- aura-update packet no matter how long the capture ran. This reaches the same
-- state by the same route.
--
-- @touched: creature,creature_addon,creature_template_addon 178205,178233,178238,178242,178249,178250,178271,178340,178341,178345,178347,178432,178484,178240,178248,178254,178280,178342,178460,178475
