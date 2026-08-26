-- Northshire Valley: give the seven missing versions of "They Sent Assassins"
-- their turn-in text.
--
-- Reported symptom: the quest has no completion text -- Sergeant Willem says
-- nothing when the assassins are dead and the quest is handed in.
--
-- The text a questgiver speaks at turn-in is quest_offer_reward.RewardText, and
-- the quest exists nine times over. All nine are the same quest: identical
-- LogTitle, identical QuestDescription, identical LogDescription. They differ
-- only in RewardNextQuest, because each is the branch for one class and leads to
-- a different follow-up:
--
--   quest  RewardNextQuest   quest_offer_reward row
--   -----  ---------------   ----------------------
--   28791            28817   present
--   28792            28818   present
--   28793            28819   MISSING
--   28794            28820   MISSING
--   28795            28821   MISSING
--   28796            28822   MISSING
--   28797            28823   MISSING
--   29081            29083   MISSING
--   31144            31145   MISSING
--
-- Only two of the nine have a row at all, so seven classes out of nine get
-- silence at the hand-in and two do not. That also explains why this reads as
-- "the completion text is missing" rather than "wrong": it is entirely absent
-- for whichever branch the character happens to be on.
--
-- The text is copied verbatim from 28791, which is the same string 28792 already
-- carries, so all nine now say the same thing -- which is right, since the quest
-- is the same quest and nothing about it is class-specific except which quest
-- comes next. Emotes and delays stay 0, matching the two existing rows.
DELETE FROM `quest_offer_reward` WHERE `ID` IN (28793,28794,28795,28796,28797,29081,31144);
INSERT INTO `quest_offer_reward` (`ID`,`Emote1`,`Emote2`,`Emote3`,`Emote4`,`EmoteDelay1`,`EmoteDelay2`,`EmoteDelay3`,`EmoteDelay4`,`RewardText`,`VerifiedBuild`) VALUES
(28793,0,0,0,0,0,0,0,0,'That will teach those monsters! They\'ll think twice before taking another mercenary job for orcs.',0),
(28794,0,0,0,0,0,0,0,0,'That will teach those monsters! They\'ll think twice before taking another mercenary job for orcs.',0),
(28795,0,0,0,0,0,0,0,0,'That will teach those monsters! They\'ll think twice before taking another mercenary job for orcs.',0),
(28796,0,0,0,0,0,0,0,0,'That will teach those monsters! They\'ll think twice before taking another mercenary job for orcs.',0),
(28797,0,0,0,0,0,0,0,0,'That will teach those monsters! They\'ll think twice before taking another mercenary job for orcs.',0),
(29081,0,0,0,0,0,0,0,0,'That will teach those monsters! They\'ll think twice before taking another mercenary job for orcs.',0),
(31144,0,0,0,0,0,0,0,0,'That will teach those monsters! They\'ll think twice before taking another mercenary job for orcs.',0);

-- Left alone deliberately, both of which are separate gaps rather than this one:
--
--  * quest_template.QuestCompletionLog is empty on all nine. That is the line the
--    quest log shows once the objectives are done ("Return to Sergeant Willem").
--    Blank is common in this database and the client falls back sensibly, so it is
--    not what was reported.
--  * quest_request_items has no row for any of the nine. That table holds the text
--    a questgiver speaks when talked to with the objectives still unfinished. For
--    a kill quest with no items to hand over it is frequently absent.
--
-- Reload with `.reload quest_template` -- that command reloads the whole quest
-- store including quest_offer_reward, so no restart is needed.
