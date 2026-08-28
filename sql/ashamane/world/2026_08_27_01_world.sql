-- New Tinkertown: give the sparring S.A.F.E. Operatives their gun back.
--
-- creature_equip_template returns to the sniffed values. 52355 is a Class 2
-- Weapon, Subclass 3 Gun, InventoryType 26 RANGED_RIGHT in this client, with a
-- complete ItemModifiedAppearance -> ItemAppearance -> ItemDisplayInfo chain; the
-- 53056/11585/30128 sword-shield-gun set that was here belongs to Gnomeregan
-- Infantry (42316), not to these three entries.
--
-- SheathState 2 (ranged) goes on the seven sparring spawns only, so they hold the
-- gun instead of drawing it for each shot. The other 33 spawns of 45847 keep the
-- template's SheathState 1. It has to live in creature_addon and not in the C++
-- AI: LoadCreaturesAddon() runs when a creature reaches its spawn point and
-- overwrites whatever the script set. creature_addon overrides
-- creature_template_addon wholesale rather than merging, so every other column
-- here repeats 45847's template addon row.
--
-- Gnome precedent for a slot-3 gun held at sheath 2: Station Guard (21115),
-- Station Sharpshooter (21441), Gnomeregan Recruit (43092).
--
-- Needs a worldserver restart: there is no .reload for creature_addon.
UPDATE `creature_equip_template` SET `ItemID1`=0, `ItemID2`=0, `ItemID3`=52355
WHERE `CreatureID` IN (45847,46449,47836) AND `ID`=1;

DELETE FROM `creature_addon`
WHERE `guid` IN (984705,984706,984710,984711,167627,167633,167938);

INSERT INTO `creature_addon`
 (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
 (167627,0,0,0,0,0,2,0,0,0,0,0,0,''),
 (167633,0,0,0,0,0,2,0,0,0,0,0,0,''),
 (167938,0,0,0,0,0,2,0,0,0,0,0,0,''),
 (984705,0,0,0,0,0,2,0,0,0,0,0,0,''),
 (984706,0,0,0,0,0,2,0,0,0,0,0,0,''),
 (984710,0,0,0,0,0,2,0,0,0,0,0,0,''),
 (984711,0,0,0,0,0,2,0,0,0,0,0,0,'');
