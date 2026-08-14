-- Coldridge Valley: remove duplicated Rockjaw Invader (37070) spawns.
--
-- sql/ashamane/old/world/2018_05_01_04_start_area_fix.sql deleted all spawns of
-- entry 37070 and re-inserted two merged sets: the 13 stock TDB rows
-- (guid 167268-167372, zoneId/areaId correctly populated) plus 14 hand-placed
-- rows (guid 210115287-210115300) that were left with zoneId=0, areaId=0.
--
-- The result is 27 invaders inside a ~120x100 yard box at the valley entrance,
-- roughly double retail density. This core has no spawn-group or dynamic-respawn
-- support, so every row spawns unconditionally regardless of player population.
--
-- Drop the 14 hand-placed rows; the stock TDB spawns are left untouched.

DELETE FROM `creature` WHERE `id` = 37070 AND `guid` BETWEEN 210115287 AND 210115300;
