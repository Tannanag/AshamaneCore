-- New Tinkertown: a pair of Gnomeregan Infantry march the town on patrol.
--
-- 168992 leads and 168993 keeps station two yards off its shoulder, so the two are
-- a `creature_formations` group rather than two copies of one path -- a second path
-- would drift out of step within a lap.
--
-- The route is an out-and-back between the north ridge and the southeast gate, so it
-- is written out in both directions. 168992 stands on the northern leg facing south,
-- so point 1 is the node ahead of it and points 1-11 run south, 12-22 come back.
-- `point_1`/`point_2` name the two turnaround points, which mirrors the follow angle
-- there and keeps 168993 on the same side of the road in both directions.
--
-- The other 42319 spawns and all 19 of 42316 are left alone; they stand still.

DELETE FROM `waypoint_data` WHERE `id`=1689920;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(1689920,1,-5185.13,568.205,398.892,0,0,0,0,100,0),
(1689920,2,-5188.012,553.278,394.732,0,0,0,0,100,0),
(1689920,3,-5188.747,536.052,389.721,0,0,0,0,100,0),
(1689920,4,-5187.957,516.509,387.782,0,0,0,0,100,0),
(1689920,5,-5186.391,502.389,387.824,0,0,0,0,100,0),
(1689920,6,-5175.925,486.882,388.312,0,0,0,0,100,0),
(1689920,7,-5159.512,475.056,390.447,0,0,0,0,100,0),
(1689920,8,-5130.811,449.031,394.959,0,0,0,0,100,0),
(1689920,9,-5119.035,451.991,397.99,0,0,0,0,100,0),
(1689920,10,-5106.811,458.717,402.144,0,0,0,0,100,0),
(1689920,11,-5095.03,463.377,404.294,0,0,0,0,100,0),
(1689920,12,-5106.811,458.717,402.144,0,0,0,0,100,0),
(1689920,13,-5119.035,451.991,397.99,0,0,0,0,100,0),
(1689920,14,-5130.811,449.031,394.959,0,0,0,0,100,0),
(1689920,15,-5159.512,475.056,390.447,0,0,0,0,100,0),
(1689920,16,-5175.925,486.882,388.312,0,0,0,0,100,0),
(1689920,17,-5186.391,502.389,387.824,0,0,0,0,100,0),
(1689920,18,-5187.957,516.509,387.782,0,0,0,0,100,0),
(1689920,19,-5188.747,536.052,389.721,0,0,0,0,100,0),
(1689920,20,-5188.012,553.278,394.732,0,0,0,0,100,0),
(1689920,21,-5185.13,568.205,398.892,0,0,0,0,100,0),
(1689920,22,-5183.821,589.148,405.466,0,0,0,0,100,0);

UPDATE `creature_addon` SET `path_id`=1689920 WHERE `guid`=168992;
UPDATE `creature` SET `MovementType`=2, `wander_distance`=0 WHERE `guid`=168992;
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0 WHERE `guid`=168993;

DELETE FROM `creature_formations` WHERE `leaderGUID`=168992 OR `memberGUID` IN (168992,168993);
INSERT INTO `creature_formations` (`leaderGUID`,`memberGUID`,`dist`,`angle`,`groupAI`,`point_1`,`point_2`) VALUES
(168992,168992,0,0,515,0,0),
(168992,168993,2,270,515,11,22);
