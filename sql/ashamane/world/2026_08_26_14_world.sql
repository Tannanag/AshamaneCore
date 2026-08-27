-- New Tinkertown: give the S.A.F.E. Operatives the gun the zone already uses.
--
-- 30128 "Monster - Gun, Techno" goes in ItemID3, the ranged slot. That is what the
-- client draws for the shoot animation, which is why an empty ItemID3 fell back to
-- a default gun model.
--
-- 32 rows in this table already carry 30128, every one of them in ItemID3, and
-- they are the gnome riflemen of this content: Gnomeregan Infantry 42316/42319/
-- 40122, Irradiated Infantry, Gnomeregan Medic, Hinkles Fastblast, Station
-- Sharpshooter, Irradiated Gnome.
--
-- 52355 "Monster - Gun, Techno 02" is dropped. It is HELD_IN_OFFHAND, so it drew as
-- a melee-held item in the off-hand and as a fallback in the ranged slot. Station
-- Sharpshooter and Irradiated Gnome carry 30128 alone, which is the shape copied
-- here.
--
-- Needs a worldserver restart.
UPDATE `creature_equip_template` SET `ItemID1`=0, `ItemID2`=0, `ItemID3`=30128
WHERE `CreatureID` IN (45847,46449,47836) AND `ID`=1;
