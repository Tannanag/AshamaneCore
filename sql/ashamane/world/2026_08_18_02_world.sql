-- Coldridge Valley: 11 wander radii that are wrong by more than 3x.
--
-- Same 2026-08-18 sniff and the same per-entry derivation as
-- 2026_08_18_01_world.sql. These spawns already wander; only the radius changes.
--
-- Scope is deliberately narrow. A correction rewrites movement that already
-- works, so it fires only past a factor of 3 -- entries within 3x of retail are
-- left alone -- and only where at least two sniffed spawns of the entry back the
-- number. That second bar is what keeps Coldridge Defender (37177) out of this
-- file: one sniffed spawn showed a 29.6 yd spread, which is a defender chasing
-- an invader, not an 8-spawn entry that should roam at 30 yd.
--
--   Ragged Young Wolf (705)   3 -> 12   from 24 sniffed spawns
--   Small Crag Boar   (708)   3 -> 14   from 26 sniffed spawns
--   Alpine Hare     (48935)   3 -> 24   from 14 sniffed spawns
--
-- Explicit guid lists, never a bare WHERE id: 48935 has 562 spawns server-wide
-- and one of them is in this list.

-- Ragged Young Wolf (705): 4 spawn(s), 3 -> 12
UPDATE `creature` SET `wander_distance`=12 WHERE `id`=705 AND `guid` IN (
    167042, 167126, 167228, 167229);
-- Small Crag Boar (708): 6 spawn(s), 3 -> 14
UPDATE `creature` SET `wander_distance`=14 WHERE `id`=708 AND `guid` IN (
    167061, 167076, 167078, 167143, 167181, 167227);
-- Alpine Hare (48935): 1 spawn(s), 3 -> 24
UPDATE `creature` SET `wander_distance`=24 WHERE `id`=48935 AND `guid` IN (
    167090);
-- 11 radius correction(s)
-- @touched: creature 167042,167061,167076,167078,167090,167126,167143,167181,167227,167228,167229
