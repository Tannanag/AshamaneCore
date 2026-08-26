-- Northshire Valley: fill in the missing turn-in text across the rest of the
-- zone's quests, the same gap 2026_08_22_15 fixed for "They Sent Assassins".
--
-- Northshire has 73 quests under 26 distinct titles, because the starting-zone
-- quests exist once per class branch -- same title, same QuestDescription, same
-- objectives, differing only in RewardNextQuest. 35 of the 73 had no
-- quest_offer_reward row, so the questgiver said nothing at hand-in for those
-- branches while saying the right thing for others.
--
--   title                  versions  had text  filled here
--   ---------------------  --------  --------  -----------
--   Beating Them Back!            9         3            6
--   Fear No Evil                  8         2            6
--   Join the Battle!              9         3            6
--   Lions for Lambs               9         3            6
--   The Rear is Clear             9         2            7
--
-- Each missing row takes the text from a sibling of the same title, so nothing
-- here is invented -- every string already existed in this database on another
-- branch of the same quest.
--
-- Which sibling matters, because the siblings are not all identical. Compared
-- byte-for-byte rather than under MySQL's case-insensitive collation, "Beating
-- Them Back!" and "Lions for Lambs" each carry two variants: one using $N with no
-- emotes, and one using $n with emote columns set (28763 has Emote1/2 = 1/1,
-- 28771 has 21/1). The rest are uniform.
--
-- The source for every group is therefore the lowest-numbered sibling whose emote
-- columns are all zero, and the new rows are written with emotes 0. Propagating
-- one branch's gestures onto six others would be inventing behaviour, and the
-- reported problem is silence, not a missing animation. The emote-bearing rows
-- are left exactly as they are.
DELETE FROM `quest_offer_reward` WHERE `ID` IN (
 28762,28764,28765,28766,28770,28772,28773,28774,28785,28787,28788,28789,
 28809,28810,28811,28812,28813,28819,28820,28821,28822,28823,29078,29079,
 29080,29082,29083,31139,31140,31143,31145);
INSERT INTO `quest_offer_reward` (`ID`,`Emote1`,`Emote2`,`Emote3`,`Emote4`,`EmoteDelay1`,`EmoteDelay2`,`EmoteDelay3`,`EmoteDelay4`,`RewardText`,`VerifiedBuild`) VALUES
(28762,0,0,0,0,0,0,0,0,'You''ve bought us a little time, $N, but we''ve got even bigger problems to deal with now.',0),
(28764,0,0,0,0,0,0,0,0,'You''ve bought us a little time, $N, but we''ve got even bigger problems to deal with now.',0),
(28765,0,0,0,0,0,0,0,0,'You''ve bought us a little time, $N, but we''ve got even bigger problems to deal with now.',0),
(28766,0,0,0,0,0,0,0,0,'You''ve bought us a little time, $N, but we''ve got even bigger problems to deal with now.',0),
(29078,0,0,0,0,0,0,0,0,'You''ve bought us a little time, $N, but we''ve got even bigger problems to deal with now.',0),
(31139,0,0,0,0,0,0,0,0,'You''ve bought us a little time, $N, but we''ve got even bigger problems to deal with now.',0),
(28809,0,0,0,0,0,0,0,0,'I think you now understand the power of the Light. The Light giveth hope, $g brother:sister; and the Light taketh from the darkness! BLESSED BE THE LIGHT!',0),
(28810,0,0,0,0,0,0,0,0,'I think you now understand the power of the Light. The Light giveth hope, $g brother:sister; and the Light taketh from the darkness! BLESSED BE THE LIGHT!',0),
(28811,0,0,0,0,0,0,0,0,'I think you now understand the power of the Light. The Light giveth hope, $g brother:sister; and the Light taketh from the darkness! BLESSED BE THE LIGHT!',0),
(28812,0,0,0,0,0,0,0,0,'I think you now understand the power of the Light. The Light giveth hope, $g brother:sister; and the Light taketh from the darkness! BLESSED BE THE LIGHT!',0),
(28813,0,0,0,0,0,0,0,0,'I think you now understand the power of the Light. The Light giveth hope, $g brother:sister; and the Light taketh from the darkness! BLESSED BE THE LIGHT!',0),
(29082,0,0,0,0,0,0,0,0,'I think you now understand the power of the Light. The Light giveth hope, $g brother:sister; and the Light taketh from the darkness! BLESSED BE THE LIGHT!',0),
(28785,0,0,0,0,0,0,0,0,'It''s true, we were ambushed. I don''t dare send any more soldiers out there and risk losing them too. I need a volunteer. Someone willing to risk their life!',0),
(28787,0,0,0,0,0,0,0,0,'It''s true, we were ambushed. I don''t dare send any more soldiers out there and risk losing them too. I need a volunteer. Someone willing to risk their life!',0),
(28788,0,0,0,0,0,0,0,0,'It''s true, we were ambushed. I don''t dare send any more soldiers out there and risk losing them too. I need a volunteer. Someone willing to risk their life!',0),
(28789,0,0,0,0,0,0,0,0,'It''s true, we were ambushed. I don''t dare send any more soldiers out there and risk losing them too. I need a volunteer. Someone willing to risk their life!',0),
(29080,0,0,0,0,0,0,0,0,'It''s true, we were ambushed. I don''t dare send any more soldiers out there and risk losing them too. I need a volunteer. Someone willing to risk their life!',0),
(31143,0,0,0,0,0,0,0,0,'It''s true, we were ambushed. I don''t dare send any more soldiers out there and risk losing them too. I need a volunteer. Someone willing to risk their life!',0),
(28770,0,0,0,0,0,0,0,0,'Excellent work, $N. You''ve turned out to be quite an asset to this garrison. It''s time for you to train!',0),
(28772,0,0,0,0,0,0,0,0,'Excellent work, $N. You''ve turned out to be quite an asset to this garrison. It''s time for you to train!',0),
(28773,0,0,0,0,0,0,0,0,'Excellent work, $N. You''ve turned out to be quite an asset to this garrison. It''s time for you to train!',0),
(28774,0,0,0,0,0,0,0,0,'Excellent work, $N. You''ve turned out to be quite an asset to this garrison. It''s time for you to train!',0),
(29079,0,0,0,0,0,0,0,0,'Excellent work, $N. You''ve turned out to be quite an asset to this garrison. It''s time for you to train!',0),
(31140,0,0,0,0,0,0,0,0,'Excellent work, $N. You''ve turned out to be quite an asset to this garrison. It''s time for you to train!',0),
(28819,0,0,0,0,0,0,0,0,'With your help we have managed to secure the northern and western sectors of Northshire. We still have a rather large contingency of Blackrock orcs to the east and they''ve begun burning down the forest!',0),
(28820,0,0,0,0,0,0,0,0,'With your help we have managed to secure the northern and western sectors of Northshire. We still have a rather large contingency of Blackrock orcs to the east and they''ve begun burning down the forest!',0),
(28821,0,0,0,0,0,0,0,0,'With your help we have managed to secure the northern and western sectors of Northshire. We still have a rather large contingency of Blackrock orcs to the east and they''ve begun burning down the forest!',0),
(28822,0,0,0,0,0,0,0,0,'With your help we have managed to secure the northern and western sectors of Northshire. We still have a rather large contingency of Blackrock orcs to the east and they''ve begun burning down the forest!',0),
(28823,0,0,0,0,0,0,0,0,'With your help we have managed to secure the northern and western sectors of Northshire. We still have a rather large contingency of Blackrock orcs to the east and they''ve begun burning down the forest!',0),
(29083,0,0,0,0,0,0,0,0,'With your help we have managed to secure the northern and western sectors of Northshire. We still have a rather large contingency of Blackrock orcs to the east and they''ve begun burning down the forest!',0),
(31145,0,0,0,0,0,0,0,0,'With your help we have managed to secure the northern and western sectors of Northshire. We still have a rather large contingency of Blackrock orcs to the east and they''ve begun burning down the forest!',0);

-- Four quests in the zone are left without turn-in text, because no version of
-- them has any and there is nothing in this database to copy:
--
--   27723  Kyle's Test Quest     QuestType 0, empty QuestDescription -- a
--                                developer test quest, not player facing
--   31141  Calligraphed Letter   item-started (StartItem 85160)
--   31142  Palm of the Tiger     class-gated (AllowableClasses 10 = Paladin, Rogue)
--   37112  Rest and Relaxation   single version in this zone, no sibling
--
-- Writing text for those means sourcing it from retail, not from here, so they
-- are reported rather than guessed at.
--
-- Reload with `.reload quest_template`, which reloads the whole quest store
-- including quest_offer_reward. No restart needed.
--
-- Undo is the DELETE above on its own.
