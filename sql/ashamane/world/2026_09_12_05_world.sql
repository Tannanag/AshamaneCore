-- New Tinkertown: six Crushcog Sentry-Bots (42291) patrol the camp instead
-- of pacing 3-yard circles or standing still. One loop round the south of the
-- camp, two out-and-backs side by side along the north road, three along
-- the west edge. They run (move_type 1) and never stop at a node.
-- waypoint_data is cyclic, so an out-and-back lists the return leg as further
-- points. Point 1 is the node the spawn stands on; 168422 stands 9 yd off
-- the east end of its route and walks that once on a respawn.
-- creature_addon.path_id is mandatory with MovementType 2; the template
-- addon carries no auras, so the rows add none.

-- Crushcog Sentry-Bot 168806 -- 14 nodes round the south loop, one lap of 14 points, 381 yd per lap.
SET @NPC := 168806;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC AND `id`=42291;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5201.899,83.231,386.111,0,0,1,0,100,0),
(@PATH,2,-5187.656,119.771,386.111,0,0,1,0,100,0),
(@PATH,3,-5187.250,140.056,386.115,0,0,1,0,100,0),
(@PATH,4,-5191.156,159.752,386.138,0,0,1,0,100,0),
(@PATH,5,-5205.443,171.007,386.114,0,0,1,0,100,0),
(@PATH,6,-5235.936,180.757,386.111,0,0,1,0,100,0),
(@PATH,7,-5267.743,176.490,386.111,0,0,1,0,100,0),
(@PATH,8,-5283.752,156.533,386.114,0,0,1,0,100,0),
(@PATH,9,-5302.299,126.878,386.114,0,0,1,0,100,0),
(@PATH,10,-5310.577,99.319,386.111,0,0,1,0,100,0),
(@PATH,11,-5298.054,82.502,386.111,0,0,1,0,100,0),
(@PATH,12,-5276.588,67.302,386.111,0,0,1,0,100,0),
(@PATH,13,-5250.653,62.840,386.111,0,0,1,0,100,0),
(@PATH,14,-5219.134,66.127,386.111,0,0,1,0,100,0);

-- Crushcog Sentry-Bot 167752 -- 10 nodes out and back along the north road, 18 points, 436 yd per lap.
SET @NPC := 167752;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC AND `id`=42291;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5214.056,205.087,386.111,0,0,1,0,100,0),
(@PATH,2,-5198.179,182.601,386.111,0,0,1,0,100,0),
(@PATH,3,-5178.377,168.927,386.111,0,0,1,0,100,0),
(@PATH,4,-5163.174,161.059,386.111,0,0,1,0,100,0),
(@PATH,5,-5144.444,135.778,386.111,0,0,1,0,100,0),
(@PATH,6,-5163.174,161.059,386.111,0,0,1,0,100,0),
(@PATH,7,-5178.377,168.927,386.111,0,0,1,0,100,0),
(@PATH,8,-5198.179,182.601,386.111,0,0,1,0,100,0),
(@PATH,9,-5214.056,205.087,386.111,0,0,1,0,100,0),
(@PATH,10,-5227.264,224.332,386.111,0,0,1,0,100,0),
(@PATH,11,-5247.384,236.488,386.111,0,0,1,0,100,0),
(@PATH,12,-5271.335,230.816,386.111,0,0,1,0,100,0),
(@PATH,13,-5291.893,223.969,386.111,0,0,1,0,100,0),
(@PATH,14,-5313.757,234.925,386.111,0,0,1,0,100,0),
(@PATH,15,-5291.893,223.969,386.111,0,0,1,0,100,0),
(@PATH,16,-5271.335,230.816,386.111,0,0,1,0,100,0),
(@PATH,17,-5247.384,236.488,386.111,0,0,1,0,100,0),
(@PATH,18,-5227.264,224.332,386.111,0,0,1,0,100,0);

-- Crushcog Sentry-Bot 168422 -- 9 nodes out and back beside the north road, 16 points, 394 yd per lap.
SET @NPC := 168422;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC AND `id`=42291;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5152.662,166.924,386.112,0,0,1,0,100,0),
(@PATH,2,-5140.085,152.667,386.112,0,0,1,0,100,0),
(@PATH,3,-5152.662,166.924,386.112,0,0,1,0,100,0),
(@PATH,4,-5173.712,174.368,386.111,0,0,1,0,100,0),
(@PATH,5,-5189.203,189.083,386.111,0,0,1,0,100,0),
(@PATH,6,-5202.469,210.406,386.111,0,0,1,0,100,0),
(@PATH,7,-5215.113,231.644,386.111,0,0,1,0,100,0),
(@PATH,8,-5237.088,251.146,386.122,0,0,1,0,100,0),
(@PATH,9,-5266.859,246.868,386.111,0,0,1,0,100,0),
(@PATH,10,-5291.316,240.590,386.111,0,0,1,0,100,0),
(@PATH,11,-5266.859,246.868,386.111,0,0,1,0,100,0),
(@PATH,12,-5237.088,251.146,386.122,0,0,1,0,100,0),
(@PATH,13,-5215.113,231.644,386.111,0,0,1,0,100,0),
(@PATH,14,-5202.469,210.406,386.111,0,0,1,0,100,0),
(@PATH,15,-5189.203,189.083,386.111,0,0,1,0,100,0),
(@PATH,16,-5173.712,174.368,386.111,0,0,1,0,100,0);

-- Crushcog Sentry-Bot 168702 -- 7 nodes, a line out and back with a short loop at the east end, 11 points, 286 yd per lap.
SET @NPC := 168702;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC AND `id`=42291;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5346.128,155.170,386.156,0,0,1,0,100,0),
(@PATH,2,-5339.080,136.804,386.202,0,0,1,0,100,0),
(@PATH,3,-5312.268,118.812,386.124,0,0,1,0,100,0),
(@PATH,4,-5339.080,136.804,386.202,0,0,1,0,100,0),
(@PATH,5,-5346.128,155.170,386.156,0,0,1,0,100,0),
(@PATH,6,-5338.458,181.997,386.111,0,0,1,0,100,0),
(@PATH,7,-5308.518,187.658,386.111,0,0,1,0,100,0),
(@PATH,8,-5286.653,181.576,386.111,0,0,1,0,100,0),
(@PATH,9,-5281.436,171.476,386.112,0,0,1,0,100,0),
(@PATH,10,-5308.518,187.658,386.111,0,0,1,0,100,0),
(@PATH,11,-5338.458,181.997,386.111,0,0,1,0,100,0);

-- Crushcog Sentry-Bot 168784 -- 7 nodes out and back along the west edge, 12 points, 249 yd per lap.
SET @NPC := 168784;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC AND `id`=42291;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5374.035,155.118,386.111,0,0,1,0,100,0),
(@PATH,2,-5366.207,133.944,386.111,0,0,1,0,100,0),
(@PATH,3,-5364.483,115.038,386.111,0,0,1,0,100,0),
(@PATH,4,-5366.207,133.944,386.111,0,0,1,0,100,0),
(@PATH,5,-5374.035,155.118,386.111,0,0,1,0,100,0),
(@PATH,6,-5376.866,177.432,386.111,0,0,1,0,100,0),
(@PATH,7,-5368.215,197.814,386.111,0,0,1,0,100,0),
(@PATH,8,-5356.075,212.085,386.111,0,0,1,0,100,0),
(@PATH,9,-5339.967,223.142,386.111,0,0,1,0,100,0),
(@PATH,10,-5356.075,212.085,386.111,0,0,1,0,100,0),
(@PATH,11,-5368.215,197.814,386.111,0,0,1,0,100,0),
(@PATH,12,-5376.866,177.432,386.111,0,0,1,0,100,0);

-- Crushcog Sentry-Bot 169215 -- 7 nodes out and back along the outer west edge, 12 points, 267 yd per lap.
SET @NPC := 169215;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC AND `id`=42291;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5388.217,153.054,386.112,0,0,1,0,100,0),
(@PATH,2,-5376.726,130.988,386.111,0,0,1,0,100,0),
(@PATH,3,-5374.753,115.993,386.111,0,0,1,0,100,0),
(@PATH,4,-5376.726,130.988,386.111,0,0,1,0,100,0),
(@PATH,5,-5388.217,153.054,386.112,0,0,1,0,100,0),
(@PATH,6,-5389.738,174.569,386.111,0,0,1,0,100,0),
(@PATH,7,-5384.281,199.760,386.121,0,0,1,0,100,0),
(@PATH,8,-5367.406,217.733,386.111,0,0,1,0,100,0),
(@PATH,9,-5349.922,230.010,386.111,0,0,1,0,100,0),
(@PATH,10,-5367.406,217.733,386.111,0,0,1,0,100,0),
(@PATH,11,-5384.281,199.760,386.121,0,0,1,0,100,0),
(@PATH,12,-5389.738,174.569,386.111,0,0,1,0,100,0);
-- @touched: creature,creature_addon,waypoint_data 168806,167752,168422,168702,168784,169215
