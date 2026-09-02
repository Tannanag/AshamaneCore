-- New Tinkertown: Progress and Completion text for the gnome starting chain.
--
-- Every quest from 27670 Pinned Down to 26373 On to Kharanos had no
-- `quest_offer_reward` and no `quest_request_items` row at all, so the hand-in and
-- progress boxes came up empty. Missing rows rather than empty strings, which is why
-- nothing logged: ObjectMgr loads both tables optionally.
--
-- The 37 of `QuestSortID` 6457, plus the five class follow-ups under sort id 801 that
-- a gnome hits in the same run: 26198, 26200, 26201, 26204, 26207.
--
-- Completion is written for all 42. Progress only for the 14 that have one -- a quest
-- with no progress text gets no row rather than a row holding an empty string.
--
-- Emotes, delays and VerifiedBuild are 0 throughout, which is what the source rows
-- carry for these quests.

DELETE FROM `quest_offer_reward` WHERE `ID` IN (26197,26198,26199,26200,26201,26202,26203,26204,26205,26206,26207,26208,26222,26264,26265,26284,26285,26316,26318,26329,26331,26333,26339,26342,26364,26373,26421,26422,26423,26424,26425,26566,27635,27670,27671,27674,28167,28169,31135,31137,41217,41218);
INSERT INTO `quest_offer_reward` (`ID`,`Emote1`,`Emote2`,`Emote3`,`Emote4`,`EmoteDelay1`,`EmoteDelay2`,`EmoteDelay3`,`EmoteDelay4`,`RewardText`,`VerifiedBuild`) VALUES
(26197,0,0,0,0,0,0,0,0,'$n, isn\'t it? It\'s a pleasure to finally meet you. While you were getting cleaned up, Nevin\'s team told me about your escape from Gnomeregan.',0),
(26198,0,0,0,0,0,0,0,0,'You picked that one up quickly. I can\'t wait to show you some of my other favorite tricks.',0),
(26199,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. I\'m sure your time in Gnomeregan afforded you ample opportunity to practice your arts. Things are somewhat safer here, but your talents will never go to waste.',0),
(26200,0,0,0,0,0,0,0,0,'Good work, $n. You have a natural talent for our arts.',0),
(26201,0,0,0,0,0,0,0,0,'As you continue to gain power, return to me and I will teach you new spells and techniques.',0),
(26202,0,0,0,0,0,0,0,0,'So, another one of Nevin\'s \"rescued\" survivors, eh? More than likely, you saved his life from the troggs down there. Did he stumble over his words when he mentioned me? The man has a healthy respect for the demonic powers we channel.',0),
(26203,0,0,0,0,0,0,0,0,'For a $r who has spent so much time inside Gnomeregan, you look positively fit and healthy, $n. That\'s good. Before we can complete what Operation: Gnomeregan began, we\'re going to need more warriors like you. ',0),
(26204,0,0,0,0,0,0,0,0,'Good work! Keep practicing your charge and you\'ll have an instant advantage at the start of battle.',0),
(26205,0,0,0,0,0,0,0,0,'Wow, I never expected it to work on the first trial!$B$BUh, I mean, we\'ve succeeded! I wonder what other uses I we can find for this handy little guy.',0),
(26206,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. Nevin tells me that you managed to survive the dangers in Gnomeregan by using your wits. That\'s exactly what we need up here. Clever minds and quick blades.',0),
(26207,0,0,0,0,0,0,0,0,'I\'m not surprised to see you\'re such a quick study. I look forward to showing you more of our tricks of the trade.',0),
(26208,0,0,0,0,0,0,0,0,'Even now, only the S.A.F.E. teams dare to venture far into the city to search for survivors. Meanwhile, Thermaplugg has sent one of his followers, Crushcog, to distract us and buy time for him to dig in.',0),
(26222,0,0,0,0,0,0,0,0,'These are fantastic! Let\'s see what we can put together. Would you be interested in testing out the prototype once I\'m done?',0),
(26264,0,0,0,0,0,0,0,0,'I can\'t wait to give this new technology a try! We\'ve lost more gnomes to radiation than we can count. It\'s time to turn that around!',0),
(26265,0,0,0,0,0,0,0,0,'What a relief! Thank you for your help. I hope that gadget Engineer Grindspark was working on helps get the airfield cleaned up permanently.',0),
(26284,0,0,0,0,0,0,0,0,'You have me own thanks and th\' thanks of th\' men you rescued. I\'ve already had th\' boys start setting up the gear down inside the cave. It should be ready to go soon.',0),
(26285,0,0,0,0,0,0,0,0,'Well, now, that\'s more like it. We may get around to blowin\' up somethin\' after all.',0),
(26316,0,0,0,0,0,0,0,0,'It won\'t be tough to collapse th\' tunnel, but I\'m goin\' to need my team an\' my equipment \'afore I can get to th\' task.',0),
(26318,0,0,0,0,0,0,0,0,'I could feel th\' explosion way up here! My boys did a fine job riggin\' up that blast, but it wouldn\'t have happened without your help. It\'s only fair that I split my contract payment with you for helpin\' me finish th\' job.',0),
(26329,0,0,0,0,0,0,0,0,'<The high tinker reads Jessup\'s report.>$B$BSplendid news! With the troggs taken care of, we should be able to turn our attention to Crushcog\'s troublemaking.',0),
(26331,0,0,0,0,0,0,0,0,'That should set back Crushcog\'s plans a bit, but we can\'t rest until he is defeated and Chill Breeze Valley is secure.',0),
(26333,0,0,0,0,0,0,0,0,'Mekkatorque will be pleased to hear that you\'ve ruined Crushcog\'s plans to use our old weapons for his followers. Without the mechano-tanks under his command, he\'ll be weak and vulnerable.',0),
(26339,0,0,0,0,0,0,0,0,'Ah, yes, Kelsey told me to expect you. There\'s still much to do before we can take on Crushcog.',0),
(26342,0,0,0,0,0,0,0,0,'You\'ve given us just the opening we\'ll need to get the drop on Crushcog. Excellent work, $n.',0),
(26364,0,0,0,0,0,0,0,0,'We\'re finally free of Razlo Crushcog and his interference! With the defeat of Crushcog and his forces, Thermaplugg can\'t afford to send any more of his followers to the surface. I can\'t wait for the day when we defeat him for good!',0),
(26373,0,0,0,0,0,0,0,0,'If Gnomeregan Covert Operations is recommending you, then you must have made quite an impression. Your help will be most welcome here, as we\'ve a wealth of enemies and few enough mountaineers to face them.',0),
(26421,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. You\'ve probably heard others speaking of Operation: Gnomeregan. Let me tell you a bit about what happened and why we left the dwarven city of Ironforge.',0),
(26422,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. You\'ve probably heard others speaking of Operation: Gnomeregan. Let me tell you a bit about what happened and why we left the dwarven city of Ironforge.',0),
(26423,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. You\'ve probably heard others speaking of Operation: Gnomeregan. Let me tell you a bit about what happened and why we left the dwarven city of Ironforge.',0),
(26424,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. You\'ve probably heard others speaking of Operation: Gnomeregan. Let me tell you a bit about what happened and why we left the dwarven city of Ironforge.',0),
(26425,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. You\'ve probably heard others speaking of Operation: Gnomeregan. Let me tell you a bit about what happened and why we left the dwarven city of Ironforge.',0),
(26566,0,0,0,0,0,0,0,0,'So the high tinker himself has heard of my little project? Splendid! I\'ve almost finished my latest prototype, but maybe you can help me chase down those last few parts.',0),
(27635,0,0,0,0,0,0,0,0,'There, now you\'re fit to head off to the surface and start your new life. The High Tinker will be delighted to hear of your arrival. ',0),
(27670,0,0,0,0,0,0,0,0,'Well done, $n. My men can take it from here. Let\'s focus on getting the other survivors out now. ',0),
(27671,0,0,0,0,0,0,0,0,'I know Nevin will be pleased with all the survivors you managed to help. I still can\'t believe you managed to stay so strong down here in the radiation. You\'ve seen the shape the other survivors are in. Let\'s get you to the loading room for decontamination. ',0),
(27674,0,0,0,0,0,0,0,0,'It\'s good to see you again, $n. Without your help, we wouldn\'t have been able to get so many survivors out of Gnomeregan this time. Everyone is going to be thrilled to meet you and hear your story. ',0),
(28167,0,0,0,0,0,0,0,0,'Did Nevin send you ahead? That means he\'s getting ready to end the mission, but there are still survivors to be rescued. We have to help them! ',0),
(28169,0,0,0,0,0,0,0,0,'It\'s good to meet you, $c. We rarely come across survivors as strong and capable as you are. I can help get you decontaminated and on your way out of here. ',0),
(31135,0,0,0,0,0,0,0,0,'Why, you look great! I\'ve heard bad things about what happens down there.$B$BWell, are you ready to start your training in the ways of the $C?',0),
(31137,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. You\'ve probably heard others speaking of Operation: Gnomeregan. Let me tell you a bit about what happened and why we left the dwarven city of Ironforge.',0),
(41217,0,0,0,0,0,0,0,0,'For a $R who has spent so much time inside Gnomeregan, you look positively fit and healthy, $n. That\'s good. Before we can complete what Operation: Gnomeregan began, we\'re going to need more hunters like you.',0),
(41218,0,0,0,0,0,0,0,0,'It\'s good to meet you, $n. You\'ve probably heard others speaking of Operation: Gnomeregan. Let me tell you a bit about what happened and why we left the dwarven city of Ironforge.',0);

DELETE FROM `quest_request_items` WHERE `ID` IN (26197,26198,26199,26200,26201,26202,26203,26204,26205,26206,26207,26208,26222,26264,26265,26284,26285,26316,26318,26329,26331,26333,26339,26342,26364,26373,26421,26422,26423,26424,26425,26566,27635,27670,27671,27674,28167,28169,31135,31137,41217,41218);
INSERT INTO `quest_request_items` (`ID`,`EmoteOnComplete`,`EmoteOnIncomplete`,`EmoteOnCompleteDelay`,`EmoteOnIncompleteDelay`,`CompletionText`,`VerifiedBuild`) VALUES
(26208,0,0,0,0,'Thermaplugg\'s defeat is a certainty, but that irradiator has bought him time to regroup.',0),
(26222,0,0,0,0,'Did you get those parts?',0),
(26264,0,0,0,0,'Were you able to recover the belongings of any of the irradiated gnomes?',0),
(26265,0,0,0,0,'Were you able to clear away any of the contamination?',0),
(26284,0,0,0,0,'Were you able to free any o\' me men?',0),
(26285,0,0,0,0,'Well, did you recover me missing supplies?',0),
(26318,0,0,0,0,'Well, is th\' job done?',0),
(26329,0,0,0,0,'Welcome back, $n.',0),
(26333,0,0,0,0,'Have you managed to take out any of those mechano-tanks Crushcog\'s men are working on?',0),
(26342,0,0,0,0,'Were you able to blind Crushcog\'s sentries?',0),
(26364,0,0,0,0,'Did you face Crushcog? What happened?',0),
(27670,0,0,0,0,'Help my men get the way cleared out so we can help the other survivors get out of here!',0),
(27671,0,0,0,0,'Nevin\'s team found a lot of survivors this time, but he\'s cutting it awful close.',0),
(27674,0,0,0,0,'It\'s good to see you again, $n.',0);
