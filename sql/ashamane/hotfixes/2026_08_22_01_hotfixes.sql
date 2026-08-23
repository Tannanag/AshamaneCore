-- Northshire Valley: give "Spyglass" and "Spying" the stealth effect they are
-- already built to have, so the Blackrock Spies are see-through out of combat
-- and solid once pulled.
--
-- Everything about these two spells says stealth except the one row that would
-- make them stealth.
--
-- Their description, shared with exactly 13 spells in Spell.db2 and with nothing
-- else, is "Puts the caster in stealth mode. Lasts until cancelled." Ten of
-- those thirteen apply SPELL_AURA_MOD_STEALTH. The three that do not are
-- 86237 Stalking, 92857 Spying and 93046 Sneaking, which are byte-identical to
-- each other and carry only SPELL_AURA_ANIM_REPLACEMENT_SET -- the crouch pose.
--
-- SpellInterrupts.db2 is the clincher, because interrupt flags only matter to a
-- spell that is meant to be broken:
--
--   spell                          AuraInterruptFlags
--   -----------------------------  ------------------
--   84442 Stealth (NPC stealth)                 4098
--   30831 Stealth                               4098
--   92857 Spying                                4098
--   93046 Sneaking                              4098
--   80676 Spyglass                              4107
--
-- 4098 is AURA_INTERRUPT_FLAG_MELEE_ATTACK (0x1000) | TAKE_DAMAGE (0x2)
-- (SpellInfo.h:232,243). Spying is bit-for-bit identical to the two spells
-- actually named "Stealth", and Spyglass adds two more bits on top. Both are
-- already wired to fall off the moment the caster swings or is hit -- which is
-- exactly the "solid once combat starts" behaviour wanted here, and it needs no
-- script, no morph and no core change. They were only ever missing the effect.
--
-- So: one APPLY_AURA / SPELL_AURA_MOD_STEALTH effect at EffectIndex 1 on each,
-- alongside the animation effect each already has at index 0. Every other column
-- mirrors the SpellEffect row of 84442 "Stealth", including ImplicitTarget 1
-- (caster) and the three coefficients that default to 1.0.
--
-- Base points -70 needs explaining, since the real stealth spells use 1.
-- WorldObject::CanDetectStealthOf (Object.cpp:2334) computes
--
--     visibilityRange = (30 + (seerLevel-1)*5 - targetStealth) * 0.3 + reach
--
-- and then clamps it for players to MAX_PLAYER_STEALTH_DETECT_RANGE, which is
-- 30.0f (Unit.h:923). At the usual stealth value of 1 a level 1 player sees a spy
-- only from about ten yards, which is hiding them, not showing them see-through.
-- A negative value pushes the sum past the clamp so every player, at any level,
-- gets the full 30 yards: 30 - (-70) = 100, and 100 * 0.3 = 30. Negative stealth
-- is an existing Blizzard pattern, not an invention -- 152891 "Saberon Stealth"
-- uses -60.
--
-- What this means in game, stated plainly, because it is a real behaviour change:
-- a spy is invisible beyond 30 yards and invisible if it is behind the player
-- (CanDetectStealthOf also requires HasInArc). Inside 30 yards and in front, it
-- is drawn see-through. That is ordinary WoW stealth, and it is what these spells
-- were built to do.
DELETE FROM `spell_effect` WHERE `ID` IN (707841,707842);
INSERT INTO `spell_effect` (`ID`,`Effect`,`EffectBasePoints`,`EffectIndex`,`EffectAura`,`DifficultyID`,`EffectAmplitude`,`EffectAuraPeriod`,`EffectBonusCoefficient`,`EffectChainAmplitude`,`EffectChainTargets`,`EffectDieSides`,`EffectItemType`,`EffectMechanic`,`EffectPointsPerResource`,`EffectRealPointsPerLevel`,`EffectTriggerSpell`,`EffectPosFacing`,`EffectAttributes`,`BonusCoefficientFromAP`,`PvpMultiplier`,`Coefficient`,`Variance`,`ResourceCoefficient`,`GroupSizeBasePointsCoefficient`,`EffectSpellClassMask1`,`EffectSpellClassMask2`,`EffectSpellClassMask3`,`EffectSpellClassMask4`,`EffectMiscValue1`,`EffectMiscValue2`,`EffectRadiusIndex1`,`EffectRadiusIndex2`,`ImplicitTarget1`,`ImplicitTarget2`,`SpellID`,`VerifiedBuild`) VALUES
(707841,6,-70,1,16,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,80676,0),
(707842,6,-70,1,16,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,1,0,92857,0);

-- 707841 and 707842 are free ids: the highest ID in the client's SpellEffect.db2
-- is 707840.
--
-- hotfix_data is what pushes these to the client rather than leaving them
-- server-side only. 0xF04238A5 is the SpellEffect table hash, read from the
-- table_hash field of the client's SpellEffect.db2 header.
DELETE FROM `hotfix_data` WHERE `TableHash`=0xF04238A5 AND `RecordId` IN (707841,707842);
INSERT INTO `hotfix_data` (`TableHash`,`RecordId`,`Deleted`) VALUES
(0xF04238A5,707841,0),
(0xF04238A5,707842,0);

-- Scope. 80676 is carried by 13 Blackrock Spy spawns and cast on spawn by
-- Blackrock Tracker (615, 9 spawns) -- the same scout archetype, so stealthing it
-- too is right rather than collateral. 92857 is carried by the 7 patrolling
-- spies and the Blackrock Spy template addon. Nothing else in the world uses
-- either spell. 93046 "Sneaking" is deliberately left alone: it is the Goblin
-- Assassins' animation and they are not meant to be hidden.
--
-- Needs a worldserver restart, not a reload -- hotfix_data is read once at
-- startup by DB2Manager::LoadHotfixData (DB2Stores.cpp:1242). The client may also
-- need its Cache folder cleared.
--
-- Undo is the two DELETE statements above on their own.
