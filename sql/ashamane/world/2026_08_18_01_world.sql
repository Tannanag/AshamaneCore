-- Coldridge Valley / Frostmane Hold: 47 idle spawns start wandering.
--
-- Same 2026-08-18 sniff as 2026_08_18_00_world.sql (build 12.1.0.69382). These
-- spawns stand still on the server and roam in retail, so they get
-- MovementType 1 and a radius.
--
-- The radius is derived per entry, not per spawn: it is the median across the
-- sniffed spawns of that entry of each spawn's 95th-percentile displacement
-- from its own centre. Per entry because a roam radius is a property of the
-- creature, and because matching an individual sniffed critter to an individual
-- DB spawn is not reliable -- these entries pack densely enough that
-- nearest-centroid pairing is worthless. The median absorbs the one spawn that
-- was chased across the zone mid-sniff; the 95th percentile drops that spawn's
-- own tail. Rockjaw Goon shows why both are needed: its four sniffed spawns
-- range 5.7 to 64.3 yd and median to 10.
--
-- Evidence per entry, radius from N sniffed spawns:
--   Ragged Timber Wolf (704): 12 yd from 13 sniffed spawn(s), range 8.3-18.9 yd  [15 spawns server-wide]
--   Ragged Young Wolf (705): 12 yd from 24 sniffed spawn(s), range 6.7-15.6 yd  [39 spawns server-wide]
--   Frostmane Troll Whelp (706): 8 yd from 25 sniffed spawn(s), range 6.2-18.1 yd  [35 spawns server-wide]
--   Small Crag Boar (708): 14 yd from 26 sniffed spawn(s), range 7.4-18.2 yd  [48 spawns server-wide]
--   Rabbit (721): 18 yd from 10 sniffed spawn(s), range 15.4-27.0 yd  [949 spawns server-wide]
--   Coldridge Mountaineer (853): 11 yd from 4 sniffed spawn(s), range 9.6-24.5 yd  [12 spawns server-wide]
--   Frostmane Novice (946): 3 yd from 6 sniffed spawn(s), range 2.6-4.2 yd  [14 spawns server-wide]
--   Rockjaw Raider (1718): 3 yd from 2 sniffed spawn(s), range 2.8-2.9 yd  [9 spawns server-wide]
--   Felix Whindlebolt (8416): 5 yd from 1 sniffed spawn(s), range 4.6-4.6 yd  [1 spawns server-wide]  -- single spawn, no median behind it
--   Rockjaw Goon (37073): 10 yd from 4 sniffed spawn(s), range 5.7-64.3 yd  [10 spawns server-wide]
--   Rockjaw Scavenger (37105): 7 yd from 3 sniffed spawn(s), range 6.0-6.8 yd  [12 spawns server-wide]
--   Wayward Fire Elemental (37112): 23 yd from 1 sniffed spawn(s), range 23.0-23.0 yd  [1 spawns server-wide]  -- single spawn, no median behind it
--   Coldridge Defender (37177): 30 yd from 1 sniffed spawn(s), range 29.6-29.6 yd  [8 spawns server-wide]  -- single spawn, no median behind it
--   Coldridge Citizen (37218): 3 yd from 11 sniffed spawn(s), range 1.4-32.9 yd  [12 spawns server-wide]
--   Frostmane Blade (37507): 3 yd from 28 sniffed spawn(s), range 2.7-20.6 yd  [31 spawns server-wide]
--   Alpine Hare (48935): 24 yd from 14 sniffed spawn(s), range 12.3-29.4 yd  [562 spawns server-wide]
--   Rabbit (61080): 22 yd from 3 sniffed spawn(s), range 17.8-22.9 yd  [41 spawns server-wide]
--   Snow Cub (61689): 18 yd from 12 sniffed spawn(s), range 12.4-24.3 yd  [29 spawns server-wide]
--   Alpine Hare (61690): 25 yd from 5 sniffed spawn(s), range 20.8-35.8 yd  [0 spawns server-wide]--
-- A DB spawn only qualifies if it sits under one of the sniffed roams of its own
-- entry, so this cannot reach spawns of the same creature elsewhere in the zone.
-- Guids are listed explicitly for the same reason -- Alpine Hare has 562 spawns
-- server-wide and an entry-wide UPDATE would retune hares in every zone.
--
-- Left alone:
--   * Wayward Fire Elemental 167308. Its entry roams in the sniff, but the same
--     sniff has it patrolling a fixed loop, and a spawn with a route is not a
--     wanderer. Held back with the route in 2026_08_18_00_world.sql.
--   * Spawns already wandering; their radii are 2026_08_18_02_world.sql.
--   * Coldridge Mountaineer 166968 is the one Mountaineer of the twelve that
--     roams rather than patrols in this sniff, at 11 yd.

-- Ragged Timber Wolf (704): 5 spawn(s) -> wander_distance 12
UPDATE `creature` SET `MovementType`=1, `wander_distance`=12 WHERE `id`=704 AND `guid` IN (
    167082, 167103, 167135, 167190, 167257);
-- Ragged Young Wolf (705): 4 spawn(s) -> wander_distance 12
UPDATE `creature` SET `MovementType`=1, `wander_distance`=12 WHERE `id`=705 AND `guid` IN (
    167063, 167075, 167122, 167134);
-- Frostmane Troll Whelp (706): 20 spawn(s) -> wander_distance 8
UPDATE `creature` SET `MovementType`=1, `wander_distance`=8 WHERE `id`=706 AND `guid` IN (
    167081, 167112, 167168, 167185, 167188, 167202, 167204, 167206, 167238, 167253,
    167254, 167255, 167290, 167298, 167299, 167304, 167329, 167333, 167356, 167357);
-- Small Crag Boar (708): 6 spawn(s) -> wander_distance 14
UPDATE `creature` SET `MovementType`=1, `wander_distance`=14 WHERE `id`=708 AND `guid` IN (
    166986, 167108, 167109, 167110, 167144, 167193);
-- Coldridge Mountaineer (853): 1 spawn(s) -> wander_distance 11
UPDATE `creature` SET `MovementType`=1, `wander_distance`=11 WHERE `id`=853 AND `guid` IN (
    166968);
-- Rockjaw Goon (37073): 2 spawn(s) -> wander_distance 10
UPDATE `creature` SET `MovementType`=1, `wander_distance`=10 WHERE `id`=37073 AND `guid` IN (
    167147, 167294);
-- Rockjaw Scavenger (37105): 1 spawn(s) -> wander_distance 7
UPDATE `creature` SET `MovementType`=1, `wander_distance`=7 WHERE `id`=37105 AND `guid` IN (
    167331);
-- Frostmane Blade (37507): 2 spawn(s) -> wander_distance 3
UPDATE `creature` SET `MovementType`=1, `wander_distance`=3 WHERE `id`=37507 AND `guid` IN (
    167313, 167314);
-- Alpine Hare (48935): 6 spawn(s) -> wander_distance 24
UPDATE `creature` SET `MovementType`=1, `wander_distance`=24 WHERE `id`=48935 AND `guid` IN (
    167046, 167052, 167053, 167054, 167060, 167084);
-- 47 spawn(s) gain wander
-- @touched: creature 166968,166986,167046,167052,167053,167054,167060,167063,167075,167081,167082,167084,167103,167108,167109,167110,167112,167122,167134,167135,167144,167147,167168,167185,167188,167190,167193,167202,167204,167206,167238,167253,167254,167255,167257,167290,167294,167298,167299,167304,167313,167314,167329,167331,167333,167356,167357
