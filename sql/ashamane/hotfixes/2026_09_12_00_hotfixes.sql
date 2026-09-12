-- New Tinkertown: the Makeshift Cages (204019) are only usable while "Missing
-- in Action" (26284) is in the quest log.
-- The cage template already points at PlayerCondition 10023 in its Data9
-- (conditionID1), but the 7.3.5 client has no such row, so it gates nothing
-- and anyone can open a cage. This adds the row: quest 26284 in the log,
-- everything else the defaults a native single-quest condition carries.
-- Needs a worldserver restart and 2026_09_12_01_world.sql's cache bump.

DELETE FROM `player_condition` WHERE `ID`=10023;
INSERT INTO `player_condition` (`RaceMask`,`FailureDescription`,`ID`,`Flags`,`MinLevel`,`MaxLevel`,`ClassMask`,`Gender`,`NativeGender`,`SkillLogic`,`LanguageID`,`MinLanguage`,`MaxLanguage`,`MaxFactionID`,`MaxReputation`,`ReputationLogic`,`CurrentPvpFaction`,`MinPVPRank`,`MaxPVPRank`,`PvpMedal`,`PrevQuestLogic`,`CurrQuestLogic`,`CurrentCompletedQuestLogic`,`SpellLogic`,`ItemLogic`,`ItemFlags`,`AuraSpellLogic`,`WorldStateExpressionID`,`WeatherID`,`PartyStatus`,`LifetimeMaxPVPRank`,`AchievementLogic`,`LfgLogic`,`AreaLogic`,`CurrencyLogic`,`QuestKillID`,`QuestKillLogic`,`MinExpansionLevel`,`MaxExpansionLevel`,`MinExpansionTier`,`MaxExpansionTier`,`MinGuildLevel`,`MaxGuildLevel`,`PhaseUseFlags`,`PhaseID`,`PhaseGroupID`,`MinAvgItemLevel`,`MaxAvgItemLevel`,`MinAvgEquippedItemLevel`,`MaxAvgEquippedItemLevel`,`ChrSpecializationIndex`,`ChrSpecializationRole`,`PowerType`,`PowerTypeComp`,`PowerTypeValue`,`ModifierTreeID`,`WeaponSubclassMask`,`CurrQuestID1`,`VerifiedBuild`) VALUES
(0,'',10023,1,0,0,0,-1,-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,-1,-1,-1,-1,0,0,0,0,0,0,0,0,0,-1,-1,-1,0,0,0,0,26284,0);

DELETE FROM `hotfix_data` WHERE `TableHash`=0x5B3DA113 AND `RecordId`=10023;
INSERT INTO `hotfix_data` (`TableHash`,`RecordId`,`Deleted`) VALUES
(0x5B3DA113,10023,0);
