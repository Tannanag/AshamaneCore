-- Teldrassil: the wildlife and critters of Dolanaar stand where the 14 Sep
-- sniff has them and roam as far, and the four villagers that differed are
-- put right. Strigid Owl 1995, Webwood Lurker 1998, Nightsaber 2042, Fawn 890
-- and 61165, Elfin Rabbit 49728 and 62178, Red-Tailed Chipmunk 49778, Forest
-- Moth 49842, Valeena 63070, Melarith 6781, Sentinel Shaya 12429, Moonwell
-- Bunny 34575; the box 9600-10000 x 740-1160 on map 1 (zone 141, area 186
-- and the zone-level rows around it; the south road is included down to y 740).
--
-- The player walked Dolanaar from 23:51 to 00:14 (2042 position samples,
-- 9726-9920 x 780-1034). Every one of the 41 named villagers, the Teldrassil
-- Sentinels and the Moonwell Bunny was seen, and all but Valeena stand on
-- their server row to the centimetre, facing the same way (Kyra Starsong's
-- two "moves" are her turning to face the player on gossip). The Ancient
-- Protector and the patrolling Sentinel 277070 are 2026_09_18_01 and are left
-- alone here; the wisps and Crested Owls are items 1 and 10.
--
-- Method, as in 2026_09_18_00. Every sniffed guid was folded into a spawn
-- point: a respawn keeps the exact spot under a new guid low (the Lurker
-- pair 2670845 / 2671211 at 9816.30, 784.38), so a point seen twice is exact;
-- otherwise the point is the median of the guid's own walk positions (combat
-- runs over 3.5 yd/s left out). Corpses (Health 0 at create -- two dead
-- Lurkers stacked at 9861, 800) and guids created already in combat with
-- fewer than ten walk points (Nightsaber 2671290, sprinting after another
-- player) give no point. Points and rows were paired one-to-one
-- within 30 yd, least total distance.
-- A paired row moves onto its point when it is more than 8 yd off (2 yd for
-- an exact point) and the point rests on at least ten positions. A row nobody
-- paired counts as absent on retail only when the player stood within 60 yd
-- of it for a while (view range ~100 yd); such rows are moved onto the
-- nearest sniffed point that has no row (never further than 60 yd) or, when
-- none is left, deleted. A row out of view whose species has an unpaired
-- point within 40 yd is that spawn seen from the far side (Owl 278177) and
-- moves onto it. Sniffed points with no row are inserted. Rows the player
-- never came within view of -- the west strip x < 9690 and the north strip
-- y > 1120 -- keep their positions. Rows south of y 740 were used for pairing
-- only and are not edited (their sniffed neighbours lie outside the box).
--
-- Reach (95th-percentile displacement from the spawn's own centre): the owls,
-- lurkers and nightsabers keep the 11 / 19 / 27 yd from 2026_09_17_06, which
-- now also reaches the wander_distance-3 rows in the north strip. Critters,
-- all of which roam in the sniff (the two static chipmunk / moth rows start
-- walking): Red-Tailed Chipmunk 11-20 yd, Forest Moth 14-20, Elfin Rabbit
-- 8-18, Fawn 25-38 -> 15 for the small ones, 30 for the fawns. Critter rows
-- follow their neighbours: spawntimesecs 120, modelid 0 (the entries have two
-- models), curhealth 1. 61165 and 62178 are the pet-battle Fawn and Elfin
-- Rabbit, both entries the DB already spawns elsewhere.
--
-- No row here has a creature_addon apart from the Lurkers 278520 and 278607
-- (11959 aura, untouched). Positions, deletes and inserts are outside what wpp_apply.py
-- reverts: the full rows as they were are in
-- ~/movement-reverts/snapshot-20260918-2026_09_18_02-dolanaar-spawns.sql.

-- 1. Villagers. Valeena stands 1.9 yd from where retail has her and faces
--    the other way; Melarith, Sentinel Shaya (kneeling) and the Moonwell Bunny
--    never moved in the 3.5-5 minutes each was in view, but wander 3 yd here.
UPDATE `creature` SET `position_x`=9837.08, `position_y`=991.16, `position_z`=1306.63, `orientation`=5.695 WHERE `guid`=10655777;  -- Valeena 63070, low 2249979
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0 WHERE `guid` IN (276676, 276680, 276889);  -- Melarith 6781, Sentinel Shaya 12429, Moonwell Bunny 34575

-- 2. Idle rows start roaming at the species reach.
UPDATE `creature` SET `MovementType`=1, `wander_distance`=19 WHERE `id`=1998 AND `guid` IN (
    278607);  -- Webwood Lurker
UPDATE `creature` SET `MovementType`=1, `wander_distance`=15 WHERE `id`=49778 AND `guid` IN (
    10649632);  -- Red-Tailed Chipmunk
UPDATE `creature` SET `MovementType`=1, `wander_distance`=15 WHERE `id`=49842 AND `guid` IN (
    10649641);  -- Forest Moth

-- 3. Roaming rows get the species reach.
UPDATE `creature` SET `wander_distance`=11 WHERE `id`=1995 AND `guid` IN (
    278027, 278040, 278331, 278651);  -- Strigid Owl
UPDATE `creature` SET `wander_distance`=19 WHERE `id`=1998 AND `guid` IN (
    278157);  -- Webwood Lurker
UPDATE `creature` SET `wander_distance`=27 WHERE `id`=2042 AND `guid` IN (
    278332, 278541);  -- Nightsaber

-- 4. Rows onto their sniffed spawn point.
-- Strigid Owl 1995
UPDATE `creature` SET `position_x`=9667.935, `position_y`=1027.768, `position_z`=1284.402 WHERE `guid`=278177;  -- 25.9 yd, centre of 25 positions, low 2671256
UPDATE `creature` SET `position_x`=9782.87, `position_y`=1083.994, `position_z`=1292.403 WHERE `guid`=278766;  -- 23.4 yd, centre of 59 positions, low 11059533
UPDATE `creature` SET `position_x`=9829.326, `position_y`=1154.786, `position_z`=1289.177 WHERE `guid`=278331;  -- 13.9 yd, centre of 12 positions, low 2670857
UPDATE `creature` SET `position_x`=9913.327, `position_y`=825.402, `position_z`=1317.345 WHERE `guid`=278153;  -- 13.4 yd, centre of 139 positions, respawns 2670497, 2671288
UPDATE `creature` SET `position_x`=9964.416, `position_y`=1099.662, `position_z`=1321.844 WHERE `guid`=278651;  -- 11.2 yd, centre of 13 positions, low 2671354
-- Webwood Lurker 1998
UPDATE `creature` SET `position_x`=9783.81, `position_y`=747.092, `position_z`=1298.617 WHERE `guid`=278520;  -- 28.4 yd, centre of 14 positions, respawns 2670541, 2671428
UPDATE `creature` SET `position_x`=9816.299, `position_y`=784.382, `position_z`=1301.251 WHERE `guid`=278521;  -- 29.0 yd, exact point, respawns 2670845, 2671211
UPDATE `creature` SET `position_x`=9850.493, `position_y`=750.499, `position_z`=1304.309 WHERE `guid`=278607;  -- 8.8 yd, exact point, respawns 2670936, 2671681
UPDATE `creature` SET `position_x`=9910.039, `position_y`=848.277, `position_z`=1315.144 WHERE `guid`=278428;  -- 31.1 yd, centre of 68 positions, respawns 11058927, 11059819  (nothing of its kind at the old spot while the player looked)
-- Nightsaber 2042
UPDATE `creature` SET `position_x`=9706.47, `position_y`=764.959, `position_z`=1292.493 WHERE `guid`=278536;  -- 21.4 yd, centre of 37 positions, low 2665741
UPDATE `creature` SET `position_x`=9747.351, `position_y`=786.152, `position_z`=1296.771 WHERE `guid`=278531;  -- 14.1 yd, centre of 28 positions, low 2669614
UPDATE `creature` SET `position_x`=9848.82, `position_y`=820.737, `position_z`=1307.711 WHERE `guid`=278606;  -- 35.7 yd, centre of 134 positions, respawns 2670497, 2671206  (nothing of its kind at the old spot while the player looked)
UPDATE `creature` SET `position_x`=9937.144, `position_y`=1082.69, `position_z`=1318.068 WHERE `guid`=278533;  -- 17.1 yd, centre of 16 positions, low 2669809
UPDATE `creature` SET `position_x`=9958.749, `position_y`=861.358, `position_z`=1321.513 WHERE `guid`=278346;  -- 14.3 yd, centre of 16 positions, low 2671461
-- Red-Tailed Chipmunk 49778
UPDATE `creature` SET `position_x`=9802.47, `position_y`=1002.609, `position_z`=1303.695 WHERE `guid`=10649632;  -- 8.9 yd, centre of 89 positions, low 2262943
-- Forest Moth 49842
UPDATE `creature` SET `position_x`=9707.927, `position_y`=969.073, `position_z`=1293.404 WHERE `guid`=10649641;  -- 11.7 yd, centre of 38 positions, low 2495648

-- 5. Rows the player looked at for minutes with nothing there, and no sniffed
--    point within 60 yd to give them.
DELETE FROM `creature` WHERE `guid`=10649651;  -- Elfin Rabbit at 9732.92, 886.667: player within 37 yd, 161 position samples inside 60 yd

-- 6. Sniffed spawn points with no row.
DELETE FROM `creature` WHERE `guid` BETWEEN 300000178 AND 300000195;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(300000178,890,1,141,141,'0',0,0,0,-1,0,0,9784.035,792.886,1298.891,0.1128,120,30,0,1,0,1,0,0,0,0,0,'',0),  -- Fawn, centre of 18 positions, low 2670332
(300000179,890,1,141,141,'0',0,0,0,-1,0,0,9799.704,783.364,1300.779,6.2373,120,30,0,1,0,1,0,0,0,0,0,'',0),  -- Fawn, centre of 42 positions, low 2656019
(300000180,890,1,141,141,'0',0,0,0,-1,0,0,9807.847,766.913,1303.271,0.5790,120,30,0,1,0,1,0,0,0,0,0,'',0),  -- Fawn, centre of 45 positions, low 2655881
(300000181,890,1,141,141,'0',0,0,0,-1,0,0,9815.295,1075,1301.26,4.9240,120,30,0,1,0,1,0,0,0,0,0,'',0),  -- Fawn, centre of 19 positions, low 2571734
(300000182,1995,1,141,141,'0',0,0,0,-1,10832,0,9811.878,1087.515,1298.791,1.8366,300,11,0,102,0,1,0,0,0,0,0,'',0),  -- Strigid Owl, centre of 49 positions, low 2670925
(300000183,1998,1,141,141,'0',0,0,0,-1,760,0,9731.43,1092.419,1285.159,6.1824,300,19,0,102,0,1,0,0,0,0,0,'',0),  -- Webwood Lurker, centre of 24 positions, low 2667263
(300000184,49728,1,141,141,'0',0,0,0,-1,0,0,9841.552,887.976,1311.405,3.5773,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Elfin Rabbit, centre of 76 positions, low 2640355
(300000185,49728,1,141,141,'0',0,0,0,-1,0,0,9920.085,1086.721,1315.709,3.9325,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Elfin Rabbit, centre of 2 positions, low 2671503
(300000186,49778,1,141,186,'0',0,0,0,-1,0,0,9725,974.479,1294.849,5.1098,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Red-Tailed Chipmunk, centre of 41 positions, low 245493559
(300000187,49778,1,141,186,'0',0,0,0,-1,0,0,9739.827,872.415,1297.301,4.7124,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Red-Tailed Chipmunk, centre of 34 positions, low 2660451
(300000188,49778,1,141,186,'0',0,0,0,-1,0,0,9791.279,846.078,1300.972,5.6907,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Red-Tailed Chipmunk, centre of 67 positions, low 2579727
(300000189,49778,1,141,141,'0',0,0,0,-1,0,0,9911.343,848.489,1316.326,1.2407,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Red-Tailed Chipmunk, centre of 36 positions, low 2507969
(300000190,49842,1,141,186,'0',0,0,0,-1,0,0,9726.322,944.173,1298.252,4.3859,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Forest Moth, centre of 49 positions, low 2391192
(300000191,49842,1,141,186,'0',0,0,0,-1,0,0,9739.226,956.693,1296.066,1.8038,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Forest Moth, centre of 69 positions, low 2659923
(300000192,61165,1,141,141,'0',0,0,0,-1,0,0,9763.957,783.401,1297.186,6.1935,120,30,0,1,0,1,0,0,0,0,0,'',0),  -- Fawn, exact (created in view), low 2660481
(300000193,62178,1,141,186,'0',0,0,0,-1,0,0,9651.461,987.564,1292.148,5.7398,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Elfin Rabbit, centre of 7 positions, low 2618221
(300000194,62178,1,141,259,'0',0,0,0,-1,0,0,9673.374,840.317,1281.989,5.8082,120,15,0,1,0,1,0,0,0,0,0,'',0),  -- Elfin Rabbit, centre of 2 positions, low 2416435
(300000195,62178,1,141,141,'0',0,0,0,-1,0,0,9935.867,877.531,1320.35,0.8448,120,15,0,1,0,1,0,0,0,0,0,'',0);  -- Elfin Rabbit, centre of 62 positions, low 2655431

-- @touched: creature 276676,276680,276889,278027,278040,278153,278157,278177,278331,278332,278346,278428,278520,278521,278531,278533,278536,278541,278606,278607,278651,278766,10649632,10649641,10649651,10655777
