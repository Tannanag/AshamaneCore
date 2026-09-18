-- Teldrassil: the wildlife of Shadowglen and the Dolanaar side roams as far as
-- retail's does. Young Nightsaber 2031, Mangy Nightsaber 2032, Nightsaber 2042,
-- Strigid Owl 1995 and Webwood Lurker 1998 were all random walkers at
-- wander_distance 3, and a few stood still.
--
-- In the 14 Sep sniff none of them walks a route: every one is a random walker
-- in 9-15 yd legs, and its reach from its own centre (95th percentile, median
-- over the sniffed spawns, combat runs over 3.5 yd/s left out) is
--   Young Nightsaber  13 yd  (53 spawns, 6-23)     Nightsaber  27 yd  (11 spawns, 12-40)
--   Mangy Nightsaber  15 yd  (19 spawns, 9-30)     Strigid Owl 11 yd  (26 spawns, 7-35)
--   Webwood Lurker    19 yd  (12 spawns, 9-39)
--
-- Every guid is listed: the entries have spawns in the rest of Teldrassil that
-- were not sniffed and are not touched. Nothing here has a path or a per-guid
-- addon to lose; the one Lurker addon row (278520) keeps its 11959.

-- 1. Spawns the sniff saw roaming: eight that stood still start walking, 77 get
--    the wider radius.
UPDATE `creature` SET `MovementType`=1, `wander_distance`=11 WHERE `id`=1995 AND `guid` IN (
    278154, 278527);
UPDATE `creature` SET `MovementType`=1, `wander_distance`=19 WHERE `id`=1998 AND `guid` IN (
    278520);
UPDATE `creature` SET `MovementType`=1, `wander_distance`=15 WHERE `id`=2032 AND `guid` IN (
    277502, 277542, 277827, 277993, 278386);

UPDATE `creature` SET `wander_distance`=11 WHERE `id`=1995 AND `guid` IN (
    277841, 278026, 278153, 278171, 278413, 278524, 278525, 278596, 278603, 278609);
UPDATE `creature` SET `wander_distance`=19 WHERE `id`=1998 AND `guid` IN (
    278106, 278340, 278399, 278400, 278401, 278415, 278428, 278600);
UPDATE `creature` SET `wander_distance`=13 WHERE `id`=2031 AND `guid` IN (
    277509, 277525, 277531, 277532, 277792, 277793, 277794, 277795, 277829, 277833,
    277853, 277866, 277885, 277887, 277952, 277962, 277965, 277966, 277969, 278007,
    278015, 278022, 278069, 278078, 278159, 278160, 278166, 278167, 278168, 278285,
    278300, 278301, 278365, 278366, 278367, 278369, 278372, 278374, 278392, 278398);
UPDATE `creature` SET `wander_distance`=15 WHERE `id`=2032 AND `guid` IN (
    277343, 277618, 277646, 277701, 277825, 277973, 277977, 277999, 278018, 278383);
UPDATE `creature` SET `wander_distance`=27 WHERE `id`=2042 AND `guid` IN (
    278346, 278531, 278533, 278536, 278593, 278595, 278598, 278606, 278610);

-- 2. The same animals in the same two zones (6450 Shadowglen, 141 Dolanaar side)
--    that the player never came within sight of -- 20 to 350 yd from any sniffed
--    roam. They already wander, at 3 yd; the radius is a number about the
--    species, so they get it too. The seven idle spawns out there (Lurker 278607,
--    Mangy Nightsabers 277385, 277537, 277830, 277995, 278388, Nightsaber 278652)
--    were never seen moving and stay as they are.
UPDATE `creature` SET `wander_distance`=11 WHERE `id`=1995 AND `MovementType`=1 AND `guid` IN (
    278177, 278178, 278766);
UPDATE `creature` SET `wander_distance`=19 WHERE `id`=1998 AND `MovementType`=1 AND `guid` IN (
    278107, 278521, 278528, 278592, 278594, 278597, 278599);
UPDATE `creature` SET `wander_distance`=13 WHERE `id`=2031 AND `MovementType`=1 AND `guid` IN (
    277043, 277348, 277479, 277642, 277831);
UPDATE `creature` SET `wander_distance`=15 WHERE `id`=2032 AND `MovementType`=1 AND `guid` IN (
    276673, 277386, 277538, 277546, 277872, 278073);
UPDATE `creature` SET `wander_distance`=27 WHERE `id`=2042 AND `MovementType`=1 AND `guid` IN (
    278128, 278129, 278130, 278349, 278350);

-- @touched: creature 276673,277043,277343,277348,277386,277479,277502,277509,277525,277531,277532,277538,277542,277546,277618,277642,277646,277701,277792,277793,277794,277795,277825,277827,277829,277831,277833,277841,277853,277866,277872,277885,277887,277952,277962,277965,277966,277969,277973,277977,277993,277999,278007,278015,278018,278022,278026,278069,278073,278078,278106,278107,278128,278129,278130,278153,278154,278159,278160,278166,278167,278168,278171,278177,278178,278285,278300,278301,278340,278346,278349,278350,278365,278366,278367,278369,278372,278374,278383,278386,278392,278398,278399,278400,278401,278413,278415,278428,278520,278521,278524,278525,278527,278528,278531,278533,278536,278592,278593,278594,278595,278596,278597,278598,278599,278600,278603,278606,278609,278610,278766
