-- New Tinkertown: a second mounted pair of Gnomeregan Infantry patrol the main road.
--
-- 168951 leads a 15-node out-and-back along the road between (-5420, -126) south
-- of town and (-5415, 302) at Brewnall, walked continuously with no pauses;
-- 168952 keeps station two yards off its left shoulder as a creature_formations
-- member. Both already stand on the route, 168951 on point 1 and 168952 on its
-- station, so neither moves. Points 1-8 run south, 9-22 north, 23-28 south again;
-- point_1 8 and point_2 22 are the two turnarounds, which mirrors the follow
-- angle there and keeps 168952 on the same side of the road in both directions.
--
-- Both ride the mechanostrider the rest of the patrolling infantry ride. Neither
-- had a creature_addon row, so both are created. Needs a worldserver restart.
--
-- 167460 and 167461 stood 28 yards up the same road, mounted and idle: the same
-- pair at another moment of the same lap, so they go.

SET @NPC := 168951;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=0 WHERE `guid`=168952;

DELETE FROM `creature_addon` WHERE `guid` IN (@NPC,168952);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,6569,0,0,0,1,0,0,0,0,0,0,NULL),
(168952,0,6569,0,0,0,1,0,0,0,0,0,0,NULL);

DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5414.389,86.5625,393.33792,0,0,0,0,100,0),
(@PATH,2,-5407.3647,58.6875,393.5414,0,0,0,0,100,0),
(@PATH,3,-5389.1665,32.987846,391.09305,0,0,0,0,100,0),
(@PATH,4,-5386.528,0.211806,391.02945,0,0,0,0,100,0),
(@PATH,5,-5388.509,-48.774307,391.0655,0,0,0,0,100,0),
(@PATH,6,-5395.2153,-79.4375,391.72583,0,0,0,0,100,0),
(@PATH,7,-5411.441,-94.614586,393.44574,0,0,0,0,100,0),
(@PATH,8,-5420.238,-126.13021,395.87384,0,0,0,0,100,0),
(@PATH,9,-5411.441,-94.614586,393.44574,0,0,0,0,100,0),
(@PATH,10,-5395.2153,-79.4375,391.72583,0,0,0,0,100,0),
(@PATH,11,-5388.509,-48.774307,391.0655,0,0,0,0,100,0),
(@PATH,12,-5386.528,0.211806,391.02945,0,0,0,0,100,0),
(@PATH,13,-5389.1665,32.987846,391.09305,0,0,0,0,100,0),
(@PATH,14,-5407.3647,58.6875,393.5414,0,0,0,0,100,0),
(@PATH,15,-5414.389,86.5625,393.33792,0,0,0,0,100,0),
(@PATH,16,-5424.3647,129.6007,393.39694,0,0,0,0,100,0),
(@PATH,17,-5440.771,156.53125,394.29123,0,0,0,0,100,0),
(@PATH,18,-5443.151,201.85591,394.24677,0,0,0,0,100,0),
(@PATH,19,-5439.8906,232.07812,394.77075,0,0,0,0,100,0),
(@PATH,20,-5422.262,255.02951,394.69104,0,0,0,0,100,0),
(@PATH,21,-5419.847,279.62674,394.69513,0,0,0,0,100,0),
(@PATH,22,-5414.637,301.73264,394.58746,0,0,0,0,100,0),
(@PATH,23,-5419.847,279.62674,394.69513,0,0,0,0,100,0),
(@PATH,24,-5422.262,255.02951,394.69104,0,0,0,0,100,0),
(@PATH,25,-5439.8906,232.07812,394.77075,0,0,0,0,100,0),
(@PATH,26,-5443.151,201.85591,394.24677,0,0,0,0,100,0),
(@PATH,27,-5440.771,156.53125,394.29123,0,0,0,0,100,0),
(@PATH,28,-5424.3647,129.6007,393.39694,0,0,0,0,100,0);

DELETE FROM `creature_formations` WHERE `leaderGUID`=@NPC OR `memberGUID` IN (@NPC,168952);
INSERT INTO `creature_formations` (`leaderGUID`,`memberGUID`,`dist`,`angle`,`groupAI`,`point_1`,`point_2`) VALUES
(@NPC,@NPC,0,0,515,0,0),
(@NPC,168952,2,270,515,8,22);

DELETE FROM `creature_addon` WHERE `guid` IN (167460,167461);
DELETE FROM `creature` WHERE `guid` IN (167460,167461);

-- @touched: creature,creature_addon,waypoint_data,creature_formations 168951,168952,167460,167461
