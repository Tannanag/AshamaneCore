-- Shadowglen: quest text for The Balance of Nature (28713) and the chain it opens,
-- checked field by field against the retail run in
-- dump_12.1.0.69814_2026-09-14_23-03-16 (SMSG_QUERY_QUEST_INFO_RESPONSE,
-- SMSG_QUEST_GIVER_QUEST_DETAILS, _REQUEST_ITEMS, _OFFER_REWARD_MESSAGE).
--
-- Description, progress and completion text of every quest the run touched --
-- 28713, 28714, 28715, 28723..28731 and Dolanaar's 488 Zenn's Bidding -- already
-- matches retail word for word.
-- What does not:
--
--   * "A Favor for Melithar" (28734), the Ilthalaine -> Melithar hand-off between
--     Fel Moss Corruption and Demonic Thieves, has no quest_offer_reward row at
--     all, so Melithar says nothing when it is handed in. The retail player never
--     took it (Demonic Thieves is offered directly), so the text comes from
--     Wowhead (quest=28734, identical on the Cataclysm page). Emotes 0, as every
--     row this DB is missing has been filled so far.
--
--   * Four strings write the player's name as $N where retail sends $n (488 and
--     28714 progress, 28713 and 28714 completion), and the description of
--     Webwood Corruption (28726) carries a trailing space retail does not. The
--     client renders both the same; aligned so the rows are byte-for-byte retail.
--
--   * The progress box's questgiver emote. quest_request_items.EmoteOnComplete is
--     what the core sends as CompEmoteType when the quest can be handed in, and the
--     retail box carries EmoteType 1 (TALK) for 488, 28714, 28715, 28729 and 28730
--     -- all five are 0 here. 28724's retail box carries 0 and stays 0.
--     EmoteOnIncomplete is untouched: the run never opened an unfinished quest.

DELETE FROM `quest_offer_reward` WHERE `ID`=28734;
INSERT INTO `quest_offer_reward` (`ID`,`Emote1`,`Emote2`,`Emote3`,`Emote4`,`EmoteDelay1`,`EmoteDelay2`,`EmoteDelay3`,`EmoteDelay4`,`RewardText`,`VerifiedBuild`) VALUES
(28734,0,0,0,0,0,0,0,0,'Ilthalaine sent you? He was wise to do so. I am indeed in need of help.',0);

UPDATE `quest_request_items` SET `CompletionText`='Have you been a busy little bee, $n?  I\'ve been waiting for you to bring me what I need.' WHERE `ID`=488;
UPDATE `quest_request_items` SET `CompletionText`='Satisfy my suspicions, $n. Bring to me fel moss from the grellkin.' WHERE `ID`=28714;
UPDATE `quest_offer_reward` SET `RewardText`='You performed your duties well, $n.' WHERE `ID`=28713;
UPDATE `quest_offer_reward` SET `RewardText`='Your service to the creatures of Shadowglen is worthy of reward, $n.$b$bYou confirmed my fears, however. The grellkin are still tainted by fel moss, despite Teldrassil\'s blessing. Something sinister remains within the tree. I can only hope that the Gnarlpine tribe of furbolgs are free of the corruption, or we are still in grave danger.$b$bI will look into this further and contact those who might be of aid. Thank you, $c.' WHERE `ID`=28714;
UPDATE `quest_template` SET `QuestDescription`='I\'d hoped to never return to Teldrassil for such grim business. I\'d hoped that its corruption had been wiped away completely.  Something foul lingers.$B$BThese spiders suffer much more deeply from the corruption than the other nearby wildlife. They are becoming a danger to your people and a danger to the forest. We must thin their numbers, but more importantly, we need to find the source of the corruption that plagues them.$B$BI will come with you and aid you in this.' WHERE `ID`=28726;

UPDATE `quest_request_items` SET `EmoteOnComplete`=1 WHERE `ID` IN (488,28714,28715,28729,28730);
