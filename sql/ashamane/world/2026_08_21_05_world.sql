-- Coldridge Valley: give 159 idle or under-radius spawns their retail wander. Radii
-- are the median observed displacement per entry in a sniff of the zone. The twelve
-- spawns that got patrol routes instead are in 2026_08_21_04_world.sql.

-- Ragged Timber Wolf 704 -- 5 spawn(s), 12 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=12 WHERE `id`=704 AND `guid` IN (
    167082, 167103, 167135, 167190, 167257);

-- Ragged Timber Wolf 704 -- 10 spawn(s), 15 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=15 WHERE `id`=704 AND `guid` IN (
    167088, 167148, 167161, 167194, 167195, 167320, 167325, 167332, 167336, 167337);

-- Ragged Young Wolf 705 -- 8 spawn(s), 12 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=12 WHERE `id`=705 AND `guid` IN (
    167042, 167063, 167075, 167122, 167126, 167134, 167228, 167229);

-- Ragged Young Wolf 705 -- 27 spawn(s), 14 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=14 WHERE `id`=705 AND `guid` IN (
    167087, 167104, 167107, 167116, 167118, 167119, 167121, 167125, 167132, 167133,
    167158, 167160, 167163, 167183, 167186, 167191, 167192, 167196, 167197, 167203,
    167221, 167270, 167274, 167287, 167288, 167321, 167330);

-- Frostmane Troll Whelp 706 -- 2 spawn(s), 7 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=7 WHERE `id`=706 AND `guid` IN (
    167301, 167302);

-- Frostmane Troll Whelp 706 -- 20 spawn(s), 8 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=8 WHERE `id`=706 AND `guid` IN (
    167081, 167112, 167168, 167185, 167188, 167202, 167204, 167206, 167238, 167253,
    167254, 167255, 167290, 167298, 167299, 167304, 167329, 167333, 167356, 167357);

-- Small Crag Boar 708 -- 12 spawn(s), 14 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=14 WHERE `id`=708 AND `guid` IN (
    166986, 167061, 167076, 167078, 167108, 167109, 167110, 167143, 167144, 167181,
    167193, 167227);

-- Small Crag Boar 708 -- 27 spawn(s), 15 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=15 WHERE `id`=708 AND `guid` IN (
    167117, 167120, 167127, 167140, 167154, 167182, 167198, 167199, 167225, 167226,
    167242, 167245, 167261, 167267, 167272, 167275, 167277, 167279, 167283, 167285,
    167286, 167305, 167316, 167318, 167327, 167334, 167338);

-- Felix Whindlebolt 8416 -- 1 spawn(s), 5 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=5 WHERE `id`=8416 AND `guid` IN (
    166987);

-- Rockjaw Goon 37073 -- 9 spawn(s), 10 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=10 WHERE `id`=37073 AND `guid` IN (
    167147, 167178, 167224, 167249, 167259, 167260, 167289, 167294, 167295);

-- Rockjaw Scavenger 37105 -- 1 spawn(s), 7 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=7 WHERE `id`=37105 AND `guid` IN (
    167331);

-- Coldridge Citizen 37218 -- 9 spawn(s), 3 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=3 WHERE `id`=37218 AND `guid` IN (
    167010, 167011, 167013, 167014, 167015, 167016, 167018, 167019, 167039);

-- Frostmane Blade 37507 -- 2 spawn(s), 3 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=3 WHERE `id`=37507 AND `guid` IN (
    167313, 167314);

-- Alpine Hare 48935 -- 7 spawn(s), 24 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=24 WHERE `id`=48935 AND `guid` IN (
    167046, 167052, 167053, 167054, 167060, 167084, 167090);

-- Alpine Hare 48935 -- 19 spawn(s), 29 yd
UPDATE `creature` SET `MovementType`=1, `wander_distance`=29 WHERE `id`=48935 AND `guid` IN (
    167049, 167051, 167056, 167062, 167064, 167068, 167072, 167089, 167091, 167093,
    167094, 167095, 167098, 167100, 167123, 167166, 167169, 167179, 167180);

-- Six Frostmane Novices around the Frostmane Hold fire wandered out of formation.
-- They are meant to stand and face it, so the radius goes and each takes the facing
-- its sniffed position implies. This reverts base data, not anything set above.
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=5.124 WHERE `guid`=167085;
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=3.149 WHERE `guid`=167170;
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=4.150 WHERE `guid`=167136;
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=2.070 WHERE `guid`=167159;
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=1.156 WHERE `guid`=167239;
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=5.817 WHERE `guid`=167237;
