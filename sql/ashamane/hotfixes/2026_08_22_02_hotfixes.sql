-- Northshire Valley: give "Spyglass" and "Spying" the spell visual that makes
-- Gavin Marlsbury see-through, and take back the stealth effect that came with
-- restrictions nobody wanted.
--
-- 2026_08_22_01 read the shared description and the interrupt flags on these two
-- spells and concluded they were stealth spells missing their stealth effect.
-- The mechanic that produced was correct -- the spies do hide past 30 yards and
-- behind the player -- but it never made them translucent, and the restrictions
-- are not wanted. Both halves of that are now explained.
--
-- Why the stealth effect could never have looked right. AuraEffect::HandleModStealth
-- (SpellAuraEffects.cpp:1592) gives a stealthed unit two things:
--
--     target->SetStandFlags(UNIT_STAND_FLAGS_CREEP);
--     if (target->GetTypeId() == TYPEID_PLAYER)
--         target->SetByteFlag(PLAYER_FIELD_BYTES2, ..._AURA_VISION, PLAYER_FIELD_BYTE2_STEALTH);
--
-- The second line is what draws the rogue translucent, and it is a PLAYER_FIELD
-- guarded to players. UNIT_FIELD_BYTES_2 has only SheathState, PvPFlag, PetFlags
-- and ShapeshiftForm (UnitDefines.h:77-83) -- there is no aura-vision byte on a
-- unit at all, so a creature has nowhere to carry that bit. The CREEP flag it
-- does get renders nothing on its own, which an earlier experiment setting
-- creature_addon.VisFlags directly had already demonstrated.
--
-- Where the look actually comes from. Gavin Marlsbury (61838) carries aura 86603
-- in creature_template_addon, and 86603 is instructive:
--
--   spell   name       effect                                   SpellVisualID
--   ------  ---------  ---------------------------------------  -------------
--   86603   Stealth    APPLY_AURA ANIM_REPLACEMENT_SET misc 61          18332
--   92857   Spying     APPLY_AURA ANIM_REPLACEMENT_SET misc 65      none at all
--   80676   Spyglass   APPLY_AURA DUMMY                             none at all
--
-- 86603 is named "Stealth" and contains no SPELL_AURA_MOD_STEALTH whatsoever. It
-- is an animation replacement plus a spell visual, and the visual is the whole
-- effect. That is exactly why Gavin is see-through with none of the restrictions:
-- visible past 30 yards, visible from behind, because nothing about him is
-- stealthed in the server's sense. Spyglass and Spying are the same shape of
-- spell and were only ever missing the visual row.
--
-- 1. Drop the stealth effects added in 2026_08_22_01. This removes the 30 yard
--    limit and the behind-the-player limit along with them.
DELETE FROM `spell_effect` WHERE `ID` IN (707841,707842);
DELETE FROM `hotfix_data` WHERE `TableHash`=0xF04238A5 AND `RecordId` IN (707841,707842);

-- 2. Attach SpellVisualID 18332 to both spells, mirroring Gavin's row. 251499 and
--    251500 are free: the highest ID in the client's SpellXSpellVisual.db2 is
--    251498. Probability 1 and zeroed condition columns match a row that always
--    applies and is visible to everyone.
DELETE FROM `spell_x_spell_visual` WHERE `ID` IN (251499,251500);
INSERT INTO `spell_x_spell_visual` (`SpellVisualID`,`ID`,`Probability`,`CasterPlayerConditionID`,`CasterUnitConditionID`,`ViewerPlayerConditionID`,`ViewerUnitConditionID`,`SpellIconFileID`,`ActiveIconFileID`,`Flags`,`DifficultyID`,`Priority`,`SpellID`,`VerifiedBuild`) VALUES
(18332,251499,1,0,0,0,0,0,0,0,0,0,80676,0),
(18332,251500,1,0,0,0,0,0,0,0,0,0,92857,0);

DELETE FROM `hotfix_data` WHERE `TableHash`=0x27B7A01A AND `RecordId` IN (251499,251500);
INSERT INTO `hotfix_data` (`TableHash`,`RecordId`,`Deleted`) VALUES
(0x27B7A01A,251499,0),
(0x27B7A01A,251500,0);

-- What this gets, without a single line of script or core code. Out of combat a
-- spy carries its aura and is drawn see-through at any range and from any angle,
-- like Gavin. The moment it swings or is hit the aura is removed by its own
-- AuraInterruptFlags -- 4098 on Spying, 4107 on Spyglass, both containing
-- MELEE_ATTACK 0x1000 and TAKE_DAMAGE 0x2 (SpellInfo.h:232,243) -- so the visual
-- goes with it and the spy turns solid for the fight. That is the combat
-- behaviour asked for earlier, arriving as a property of the spells rather than
-- as machinery bolted on beside them.
--
-- Scope. 80676 is carried by 13 spy spawns and cast on spawn by Blackrock Tracker
-- (615, 9 spawns), the same scout archetype. 92857 is carried by the 7 patrolling
-- spies and the Blackrock Spy template addon. Nothing else in the world uses
-- either spell. 93046 "Sneaking" is left alone deliberately -- it is the Goblin
-- Assassins' animation, they are not meant to look hidden, and it is untouched by
-- every statement here.
--
-- Needs a worldserver restart, not a reload -- hotfix_data is read once at
-- startup by DB2Manager::LoadHotfixData (DB2Stores.cpp:1242). The client may need
-- its Cache folder cleared.
--
-- Undo is the four DELETE statements above, plus re-running 2026_08_22_01 if the
-- stealth mechanic is ever wanted back.
