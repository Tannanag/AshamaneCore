-- New Tinkertown, "Down with Crushcog!" (26364): the assault on Razlo Crushcog.
--
-- Mekkatorque's spawn runs it from npc_high_tinker_mekkatorque_assault; the entry
-- keeps its default AI for the summon that rides into Jarvi's camp. Stonegrind,
-- the mech and the guardians take their scripts on the entry. The beats live in
-- the scripts; the lines were already in creature_text.
--
-- The kill objective is credited by the script to everyone in range, against the
-- credit entry rather than Crushcog himself, who is never attackable.
-- ScriptName on a spawn needs a worldserver restart.

DELETE FROM `gossip_menu_option` WHERE `MenuId`=11662;
INSERT INTO `gossip_menu_option` (`MenuId`,`OptionIndex`,`OptionIcon`,`OptionText`,`OptionBroadcastTextId`,`OptionType`,`OptionNpcFlag`,`VerifiedBuild`) VALUES
(11662,0,0,'I''m ready to start the assault.',42755,1,1,0);

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=15 AND `SourceGroup`=11662;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`,`SourceGroup`,`SourceEntry`,`SourceId`,`ElseGroup`,`ConditionTypeOrReference`,`ConditionTarget`,`ConditionValue1`,`ConditionValue2`,`ConditionValue3`,`NegativeCondition`,`ErrorType`,`ErrorTextId`,`ScriptName`,`Comment`) VALUES
(15,11662,0,0,0,9,0,26364,0,0,0,0,0,'','Mekkatorque offers the assault while Down with Crushcog! is open');

UPDATE `quest_objectives` SET `ObjectID`=42860 WHERE `ID`=265862 AND `QuestID`=26364;

UPDATE `creature` SET `ScriptName`='npc_high_tinker_mekkatorque_assault' WHERE `guid`=168428 AND `id`=42849;
UPDATE `creature_template` SET `ScriptName`='npc_mountaineer_stonegrind' WHERE `entry`=42852;
UPDATE `creature_template` SET `ScriptName`='npc_razlo_crushcog_mech' WHERE `entry`=42839;
UPDATE `creature_template` SET `ScriptName`='npc_crushcogs_guardian' WHERE `entry`=42294;
