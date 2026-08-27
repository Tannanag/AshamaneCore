-- New Tinkertown: put the S.A.F.E. Operative gun in a slot the client will draw.
--
-- 52355 is "Monster - Gun, Techno 02", InventoryType 23 HELD_IN_OFFHAND. It sat in
-- ItemID3, the ranged slot. ItemID2 is the off-hand slot and is where this DB puts
-- held-offhand items 394 times against 106 in ItemID3 -- and where the S.A.F.E.
-- Officer already carries 61392 "Monster - Arcanite Steam Pistol (Offhand)".
--
-- 46025 Officer and 46230 Technician are already correct and are not touched.
--
-- Needs a worldserver restart: equipment templates load at startup and .npc reload
-- does not refresh them.
UPDATE `creature_equip_template` SET `ItemID2`=52355, `ItemID3`=0
WHERE `CreatureID` IN (45847,46449,47836) AND `ID`=1;
