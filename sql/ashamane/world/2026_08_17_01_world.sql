-- Coldridge Valley: let 21 spawns wander that retail wanders and the server
-- leaves standing at attention.
--
-- Every guid below is `MovementType` = 0, `wander_distance` = 0 today, and has a
-- retail counterpart in the 12.1.0.69299 sniff that visibly roams. Same data as
-- the patrol paths in 2026_08_17_00_world.sql -- 13,863 monster-moves decoded by
-- `wpp_movement.py`, which classified 9 patrol routes and 111 wanderers -- but
-- wandering needs far less of it. A patrol needs a per-spawn identity; wander is
-- two numbers, and the radius is a constant of the entry, not of the spawn.
--
-- That distinction matters, because matching individual wanderers to individual
-- DB spawns is not reliable here. Critters in the valley are packed densely
-- enough that greedy nearest-centroid pairing produced matches as far as 125
-- yards off. So the radius is derived per entry -- 95th-percentile displacement
-- from the wander centre, taken as the median across every observed spawn of
-- that entry -- and applied only where a DB spawn (a) is idle now, (b) sits
-- inside the sniffed box, and (c) has a retail wanderer of the same entry
-- centred within a few yards of it.
--
-- The method checks out against a value already chosen by hand: it derives
-- `wander_distance` = 3 for Coldridge Citizen, which is exactly what e3000aff80
-- picked for the three Citizens on the upper shelf.
--
-- Notes on the awkward ones
--
-- * 167224 and 167260 are the DB spawns behind retail wanderers 158094 and
--   158788, the two Rockjaw Goons that were reclassified out of the patrol set
--   once on-node share was measured: only 15% and 23% of their destinations land
--   on repeated coordinates, against 91-100% for a genuine patrol. They belong
--   here as wanderers, not in the patrol file.
-- * Felix Whindlebolt (8416) is a gossip/vendor/repair NPC and both starts and
--   ends quest 8416, and this is his only spawn in the game. Retail does pace
--   him, so he is included at 5 yards, but he is the one spawn here to
--   re-evaluate first if players report trouble clicking him.
--
-- Audit
--
-- * None of the 21 has a `creature_addon` row, so these are plain UPDATEs with
--   nothing to keep in sync.
-- * Every guid is written out explicitly. `WHERE id` alone would escape the
--   zone -- entry 705 has 39 spawns server-wide and 708 has 48, against the one
--   of each touched here.
-- * All 21 confirmed at `MovementType` = 0 and `wander_distance` = 0 before
--   writing.
-- * Coldridge Citizen completeness: 12 spawns exist, and all 12 are now
--   accounted for -- 3 patrolling (2026_08_17_00_world.sql), 6 gaining wander
--   here, and 3 already wandering from e3000aff80.
--
-- Deliberately left alone: anything outside the sniffed box (map 0,
-- x -6600..-6000, y 200..700), which no evidence covers.

-- Coldridge Citizen (37218): 6 spawns, 3 yd
UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 3
    WHERE `id` = 37218 AND `guid` IN (167010, 167011, 167013, 167018, 167019, 167039);

-- Rockjaw Goon (37073): 7 spawns, 10 yd
UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 10
    WHERE `id` = 37073 AND `guid` IN (167178, 167224, 167249, 167259, 167260, 167289, 167295);

-- Ragged Timber Wolf (704): 3 spawns, 15 yd
UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 15
    WHERE `id` = 704 AND `guid` IN (167320, 167332, 167336);

-- Frostmane Troll Whelp (706): 2 spawns, 7 yd
UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 7
    WHERE `id` = 706 AND `guid` IN (167301, 167302);

-- Ragged Young Wolf (705): 1 spawn, 14 yd
UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 14
    WHERE `id` = 705 AND `guid` IN (167321);

-- Small Crag Boar (708): 1 spawn, 15 yd
UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 15
    WHERE `id` = 708 AND `guid` IN (167318);

-- Felix Whindlebolt (8416): 1 spawn, 5 yd
UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 5
    WHERE `id` = 8416 AND `guid` IN (166987);
