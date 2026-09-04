-- New Tinkertown: the channelling Irradiated Technicians hold their gun.
--
-- The sixteen 42223 spawns that channel 78858 now carry a gun in the ranged slot and stand in
-- the ranged pose, so the weapon is drawn while they work. The wrench stays in the main hand,
-- so they are not empty-handed when a fight puts the client back into melee posture.
--
-- Equip template 2 is new; template 1 is left alone. Only the sixteen channelers are moved
-- onto it -- the eleven spawns holding the working pose keep template 1 and their stowed
-- wrench.
--
-- The sheath change goes on `creature_template_addon` deliberately. Those sixteen have no
-- `creature_addon` row of their own, which is exactly how they inherit aura 78858; giving them
-- one here would replace the template addon outright rather than merge with it and would drop
-- that aura on the floor. The eleven posed spawns do have their own rows, pinning SheathState
-- 0, so they are untouched by this.

DELETE FROM `creature_equip_template` WHERE `CreatureID`=42223 AND `ID`=2;
INSERT INTO `creature_equip_template` (`CreatureID`,`ID`,`ItemID1`,`AppearanceModID1`,`ItemVisual1`,`ItemID2`,`AppearanceModID2`,`ItemVisual2`,`ItemID3`,`AppearanceModID3`,`ItemVisual3`,`VerifiedBuild`) VALUES
(42223,2,1911,0,0,0,0,0,30128,0,0,0);

UPDATE `creature` SET `equipment_id`=2 WHERE `guid` IN
 (167571,167573,167574,167768,167771,167914,167915,168052,168372,168401,168402,168403,168408,168524,168573,168589);

UPDATE `creature_template_addon` SET `SheathState`=2 WHERE `entry`=42223;
