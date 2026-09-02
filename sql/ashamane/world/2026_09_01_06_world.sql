-- New Tinkertown: the Sanitron 500 only takes a player who is on Decontamination.
--
-- The gossip path already checks the quest, but the spell click that boards the
-- vehicle bypasses gossip entirely and was ungated.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=18 AND `SourceGroup`=46185 AND `SourceEntry`=125095;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(18, 46185, 125095, 0, 0, 9, 0, 27635, 0, 0, 0, 0, 0, '', 'Required quest active for spellclick');
