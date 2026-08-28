-- New Tinkertown: stop SpellVisual 18304 attaching a gun to the caster.
--
-- Spell 85756 is the S.A.F.E. Operatives' own ranged attack. Of its visual's three
-- kits, 17335 and 17336 are the shot; 17337 exists only to carry this
-- SpellVisualKitModelAttach row, which attaches SpellVisualEffectName 3113 -- model
-- 165559, used by no item in the game -- to the caster. At this firing rate that
-- model replaced the equipped 52355 and outlived the fight.
--
-- The row is overridden with SpellVisualEffectNameID 0 rather than deleted. Deleting
-- it, or the kit, crashes the client: the client's own SpellVisualEvent rows still
-- reference them, so a missing record leaves it dereferencing nothing. Every value
-- below is the client's own except that one field.
--
-- The missile and the sound are untouched; both hang off the SpellVisual itself
-- (SpellVisualMissileSetID 2291), not off a kit.
--
-- 0xF07194C3 is SpellVisualKitModelAttach's table hash. Kit 17337 is shared with
-- SpellVisual 19021 (spell 89557) and 33838 (spell 146773), which lose the attached
-- model too.
--
-- Needs a worldserver restart.
CREATE TABLE IF NOT EXISTS `spell_visual_kit_model_attach` (
  `Offset1` float NOT NULL DEFAULT '0',
  `Offset2` float NOT NULL DEFAULT '0',
  `Offset3` float NOT NULL DEFAULT '0',
  `OffsetVariation1` float NOT NULL DEFAULT '0',
  `OffsetVariation2` float NOT NULL DEFAULT '0',
  `OffsetVariation3` float NOT NULL DEFAULT '0',
  `ID` int unsigned NOT NULL DEFAULT '0',
  `SpellVisualEffectNameID` smallint unsigned NOT NULL DEFAULT '0',
  `AttachmentID` tinyint NOT NULL DEFAULT '0',
  `Flags` tinyint unsigned NOT NULL DEFAULT '0',
  `PositionerID` smallint unsigned NOT NULL DEFAULT '0',
  `Yaw` float NOT NULL DEFAULT '0',
  `Pitch` float NOT NULL DEFAULT '0',
  `Roll` float NOT NULL DEFAULT '0',
  `YawVariation` float NOT NULL DEFAULT '0',
  `PitchVariation` float NOT NULL DEFAULT '0',
  `RollVariation` float NOT NULL DEFAULT '0',
  `Scale` float NOT NULL DEFAULT '0',
  `ScaleVariation` float NOT NULL DEFAULT '0',
  `StartAnimID` smallint NOT NULL DEFAULT '0',
  `AnimID` smallint NOT NULL DEFAULT '0',
  `EndAnimID` smallint NOT NULL DEFAULT '0',
  `AnimKitID` smallint unsigned NOT NULL DEFAULT '0',
  `LowDefModelAttachID` int unsigned NOT NULL DEFAULT '0',
  `StartDelay` float NOT NULL DEFAULT '0',
  `ParentSpellVisualKitID` int NOT NULL DEFAULT '0',
  `VerifiedBuild` smallint NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3;

DELETE FROM `spell_visual_kit_model_attach` WHERE `ID`=288183;
INSERT INTO `spell_visual_kit_model_attach`
 (`Offset1`,`Offset2`,`Offset3`,`OffsetVariation1`,`OffsetVariation2`,`OffsetVariation3`,`ID`,
  `SpellVisualEffectNameID`,`AttachmentID`,`Flags`,`PositionerID`,`Yaw`,`Pitch`,`Roll`,
  `YawVariation`,`PitchVariation`,`RollVariation`,`Scale`,`ScaleVariation`,
  `StartAnimID`,`AnimID`,`EndAnimID`,`AnimKitID`,`LowDefModelAttachID`,`StartDelay`,
  `ParentSpellVisualKitID`,`VerifiedBuild`) VALUES
 (0,0,0,0,0,0,288183,0,34,12,0,0,0,0,0,0,0,1,0,-1,-1,-1,0,0,0,17337,26972);

DELETE FROM `hotfix_data` WHERE `TableHash`=0xF07194C3 AND `RecordId`=288183;
INSERT INTO `hotfix_data` (`Id`,`TableHash`,`RecordId`,`Deleted`) VALUES (394,0xF07194C3,288183,0);
