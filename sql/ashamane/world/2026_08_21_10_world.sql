
-- Milo's Gyro: the parked copy at Anvilmar could be clicked and ridden by anyone.
-- The 24492 turn-in is meant to be the only way on, and it already works -- it
-- summons a private copy and casts 70036 on it, never touching npc_spellclick_spells.
--
-- It has to be a condition rather than an npcflag change or a row delete: Vehicle::Vehicle
-- rewrites npcflag on every spawn, and Player::CanSeeSpellClickOn returns true
-- unconditionally for a flagged creature with no rows at all. An always-false condition
-- is how "no spellclick here" is expressed. SourceGroup is the creature, SourceEntry the spell.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=18 AND `SourceGroup`=37198 AND `SourceEntry`=46598;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(18, 37198, 46598, 0, 0, 36, 0, 0, 0, 0, 1, 0, 0, '', 'Milo''s Gyro - never boardable by clicking; the 24492 turn-in summons a copy and casts 70036');

-- Left alone on purpose: npc_spellclick_spells (37198, 46598).
