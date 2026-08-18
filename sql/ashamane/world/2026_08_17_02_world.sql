-- Coldridge Valley: retune 78 wander radii that are badly wrong against retail.
--
-- These spawns already wander -- every one is `MovementType` = 1,
-- `wander_distance` = 3 -- but 3 yards is a default, not a measurement, and for
-- four entries retail roams several times wider. Same 12.1.0.69299 sniff and the
-- same per-entry derivation as 2026_08_17_01_world.sql: 95th-percentile
-- displacement from the wander centre, median across every observed spawn of the
-- entry.
--
--   entry  NPC                  spawns   3 yd ->
--     704  Ragged Timber Wolf        7      15
--     705  Ragged Young Wolf        26      14
--     708  Small Crag Boar          26      15
--   48935  Alpine Hare              19      29
--
-- Scope is deliberately narrow: only entries whose DB radius is off by more than
-- 3x. Rabbit (15 against retail's 19) and Rockjaw Scavenger (3 against 9) both
-- fall under that bar and are left exactly as they are. This is the broadest and
-- least certain of the three files, which is why it is separate -- revert it on
-- its own if the valley reads as too busy.
--
-- Why every guid is written out
--
-- This is the file where a `WHERE id` shortcut would do real damage. Alpine Hare
-- has 562 spawns server-wide and only 19 of them are in Coldridge; an entry-wide
-- UPDATE would quietly retune hares in every zone in the game. Ragged Young Wolf
-- (39 server-wide) and Small Crag Boar (48) are the same story on a smaller
-- scale. The guid lists below are the spawns inside the sniffed box (map 0,
-- x -6600..-6000, y 200..700) and nothing else.
--
-- Audit
--
-- * All 78 confirmed at `MovementType` = 1, `wander_distance` = 3 before writing,
--   in exactly the counts above: 7 / 26 / 26 / 19.
-- * `MovementType` is already 1 on all of them, so it is not touched -- this
--   changes the radius only.
-- * Alpine Hare at 29 yards is the widest change here and the single one most
--   likely to look wrong if the estimate is off. Worth watching the hares near
--   (-6300, 430) before trusting it.

-- Ragged Timber Wolf (704): 3 -> 15, 7 spawns
UPDATE `creature` SET `wander_distance` = 15 WHERE `id` = 704 AND `guid` IN (
    167088, 167148, 167161, 167194, 167195, 167325, 167337);

-- Ragged Young Wolf (705): 3 -> 14, 26 spawns
UPDATE `creature` SET `wander_distance` = 14 WHERE `id` = 705 AND `guid` IN (
    167087, 167104, 167107, 167116, 167118, 167119, 167121, 167125, 167132, 167133,
    167158, 167160, 167163, 167183, 167186, 167191, 167192, 167196, 167197, 167203,
    167221, 167270, 167274, 167287, 167288, 167330);

-- Small Crag Boar (708): 3 -> 15, 26 spawns
UPDATE `creature` SET `wander_distance` = 15 WHERE `id` = 708 AND `guid` IN (
    167117, 167120, 167127, 167140, 167154, 167182, 167198, 167199, 167225, 167226,
    167242, 167245, 167261, 167267, 167272, 167275, 167277, 167279, 167283, 167285,
    167286, 167305, 167316, 167327, 167334, 167338);

-- Alpine Hare (48935): 3 -> 29, 19 spawns
UPDATE `creature` SET `wander_distance` = 29 WHERE `id` = 48935 AND `guid` IN (
    167049, 167051, 167056, 167062, 167064, 167068, 167072, 167089, 167091, 167093,
    167094, 167095, 167098, 167100, 167123, 167166, 167169, 167179, 167180);
