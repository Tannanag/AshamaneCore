-- Shadowglen: "A Favor for Melithar" (28734) is offered alongside Fel Moss
-- Corruption, the way retail treats it -- a breadcrumb to Demonic Thieves, not a
-- link in the chain.
--
-- Here 28734 was gated on Fel Moss Corruption (PrevQuestID 28714) and Demonic
-- Thieves (28715) was gated on 28734, so Ilthalaine only handed the errand out
-- after the fel moss was in, and Melithar would not give Demonic Thieves until
-- the errand was delivered. Retail does neither: in the 12.1.0 run
-- (dump_12.1.0.69814_2026-09-14_23-03-16) Melithar offered Demonic Thieves at
-- 23:16:14 while Fel Moss Corruption was still in the log and 28734 had never been
-- taken, and Ilthalaine's questgiver status was None straight after the Balance of
-- Nature hand-in launched Fel Moss Corruption -- the breadcrumb had already been
-- withdrawn because the player was past it.
--
-- So: both Ilthalaine quests unlock off The Balance of Nature (28734 now shares
-- 28714's PrevQuestID 28713), Demonic Thieves stands on its own, and the errand is
-- only available while Demonic Thieves is untaken (CONDITION_QUESTSTATE 47, mask
-- 1 = NONE, on CONDITION_SOURCE_TYPE_QUEST_AVAILABLE 19). NextQuestID links and
-- 28714's RewardNextQuest 28734 (retail value) are left as they are: an errand
-- already held or handed in is simply skipped at the Fel Moss turn-in.
UPDATE `quest_template_addon` SET `PrevQuestID`=28713 WHERE `ID`=28734;
UPDATE `quest_template_addon` SET `PrevQuestID`=0 WHERE `ID`=28715;

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=19 AND `SourceEntry`=28734;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(19,0,28734,0,0,47,0,28715,1,0,0,0,0,'','A Favor for Melithar - only while Demonic Thieves is untaken (breadcrumb)');
