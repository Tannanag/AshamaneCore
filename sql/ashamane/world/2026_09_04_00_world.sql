-- New Tinkertown: a mounted Gnomeregan Infantry patrols the road south of the town.
--
-- 167689 rides the same mechanostrider as the rest of the patrolling infantry, so it
-- gains the mount alongside the path; the infantry that walk routes are the mounted
-- ones, and the ones on foot stand still.
--
-- The route is an out-and-back along the road at x ~ -5122, from the spawn point north
-- to (-5125.31, 440.30) and back, so it is written out in both directions: points 1-7
-- run north, 8-12 come back. Point 1 is the spawn point itself.
--
-- 167689 has no `creature_addon` row today, so one is created rather than updated.
-- It patrols alone -- no `creature_formations` group.

DELETE FROM `waypoint_data` WHERE `id`=1676890;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(1676890,1,-5114.43,323.962,394.14,0,0,0,0,100,0),
(1676890,2,-5122.13,347.938,395.787,0,0,0,0,100,0),
(1676890,3,-5124.19,377.036,396.609,0,0,0,0,100,0),
(1676890,4,-5125.21,401.132,396.609,0,0,0,0,100,0),
(1676890,5,-5121.23,416.439,396.659,0,0,0,0,100,0),
(1676890,6,-5122.31,430.474,396.648,0,0,0,0,100,0),
(1676890,7,-5125.31,440.295,396.281,0,0,0,0,100,0),
(1676890,8,-5122.31,430.474,396.648,0,0,0,0,100,0),
(1676890,9,-5121.23,416.439,396.659,0,0,0,0,100,0),
(1676890,10,-5125.21,401.132,396.609,0,0,0,0,100,0),
(1676890,11,-5124.19,377.036,396.609,0,0,0,0,100,0),
(1676890,12,-5122.13,347.938,395.787,0,0,0,0,100,0);

DELETE FROM `creature_addon` WHERE `guid`=167689;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(167689,1676890,6569,0,0,0,1,0,0,0,0,0,0,NULL);

UPDATE `creature` SET `MovementType`=2, `wander_distance`=0 WHERE `guid`=167689;
