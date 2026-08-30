-- New Tinkertown: arm the Crazed Leper Gnomes (46363, 46391).
--
-- Both entries were unarmed, so the melee swing played bare-handed. Retail gives them
-- item 1911 "Monster - Tool, Wrench Small" in the main hand -- a one-hand mace with a
-- valid appearance (ItemModifiedAppearance 489, ItemDisplayInfo 7494) in 7.3.5.
--
-- ID 1 is deliberate: every spawn of both entries has `creature`.`equipment_id` 0, and
-- Creature::LoadEquipment defaults to template 1 for those.
--
-- The DELETE exists so the updater can re-run the file. Needs a worldserver restart --
-- creature_equip_template has no reload command.
DELETE FROM `creature_equip_template` WHERE `CreatureID` IN (46363,46391);
INSERT INTO `creature_equip_template` (`CreatureID`,`ID`,`ItemID1`,`AppearanceModID1`,`ItemVisual1`,`ItemID2`,`AppearanceModID2`,`ItemVisual2`,`ItemID3`,`AppearanceModID3`,`ItemVisual3`,`VerifiedBuild`) VALUES
(46363,1,1911,0,0,0,0,0,0,0,0,0),
(46391,1,1911,0,0,0,0,0,0,0,0,0);
