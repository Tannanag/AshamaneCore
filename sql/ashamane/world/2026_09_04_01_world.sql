-- New Tinkertown: a mounted pair of Gnomeregan Infantry patrol the road southwest of town.
--
-- 167987 leads and 167988 keeps station two yards off its shoulder, as a
-- `creature_formations` group rather than two copies of one path.
--
-- Both ride the same mechanostrider as the rest of the patrolling infantry, and neither
-- had a `creature_addon` row, so the rows are created rather than updated.
--
-- Both spawns move onto the start of the path: 167987 sits on point 1 exactly and 167988
-- keeps its two-yard station beside it, so neither walks to the route on respawn. They
-- are turned to face point 2, which is the way they set off.
--
-- The route is an out-and-back, so it is written out in both directions: points 1-8 run
-- southwest, 9-14 come back. `point_1` 8 and `point_2` 1 are the two turnaround points,
-- which mirrors the follow angle there and keeps 167988 on the same side of the road in
-- both directions. The angle is 270 because point 1 starts on the outbound leg.

DELETE FROM `waypoint_data` WHERE `id`=1679870;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(1679870,1,-5183.054,460.938,388.512,0,0,0,0,100,0),
(1679870,2,-5189.894,449.413,388.713,0,0,0,0,100,0),
(1679870,3,-5220.471,420.922,390.566,0,0,0,0,100,0),
(1679870,4,-5251.049,400.807,392.149,0,0,0,0,100,0),
(1679870,5,-5283.846,384.036,392.725,0,0,0,0,100,0),
(1679870,6,-5317.19,376.028,393.289,0,0,0,0,100,0),
(1679870,7,-5342.002,369.031,394.0,0,0,0,0,100,0),
(1679870,8,-5361.646,339.328,394.667,0,0,0,0,100,0),
(1679870,9,-5342.002,369.031,394.0,0,0,0,0,100,0),
(1679870,10,-5317.19,376.028,393.289,0,0,0,0,100,0),
(1679870,11,-5283.846,384.036,392.725,0,0,0,0,100,0),
(1679870,12,-5251.049,400.807,392.149,0,0,0,0,100,0),
(1679870,13,-5220.471,420.922,390.566,0,0,0,0,100,0),
(1679870,14,-5189.894,449.413,388.713,0,0,0,0,100,0);

UPDATE `creature` SET `position_x`=-5183.054, `position_y`=460.938, `position_z`=388.512, `orientation`=4.1768, `MovementType`=2, `wander_distance`=0 WHERE `guid`=167987;
UPDATE `creature` SET `position_x`=-5181.334, `position_y`=459.908, `position_z`=388.512, `orientation`=4.1768, `MovementType`=0, `wander_distance`=0 WHERE `guid`=167988;

DELETE FROM `creature_addon` WHERE `guid` IN (167987,167988);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(167987,1679870,6569,0,0,0,1,0,0,0,0,0,0,NULL),
(167988,0,6569,0,0,0,1,0,0,0,0,0,0,NULL);

DELETE FROM `creature_formations` WHERE `leaderGUID`=167987 OR `memberGUID` IN (167987,167988);
INSERT INTO `creature_formations` (`leaderGUID`,`memberGUID`,`dist`,`angle`,`groupAI`,`point_1`,`point_2`) VALUES
(167987,167987,0,0,515,0,0),
(167987,167988,2,270,515,8,1);
