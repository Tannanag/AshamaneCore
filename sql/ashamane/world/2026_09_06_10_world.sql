-- New Tinkertown, the ruined ground west: patrol routes for eight spawns
-- Three Toxic Sludges and five Living Contamination walk fixed routes instead
-- of roaming. Every other spawn of both entries keeps its roam.
--
-- waypoint_data is cyclic, so an out-and-back lists the return leg as further
-- points rather than reversing: the last point leads back to point 1.
-- Point 1 is the node the spawn stands on, so a respawn does not cross its route.
-- creature_addon.path_id is mandatory here -- with MovementType 2 and no path_id
-- the spawn is silently downgraded to idle on load.

-- Toxic Sludge 168533 -- 4 nodes out and back, 6 points.
SET @NPC := 168533;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5402.780,468.736,385.506,0,0,0,0,100,0),
(@PATH,2,-5395.065,458.535,384.619,0,0,0,0,100,0),
(@PATH,3,-5382.682,444.307,385.976,0,0,0,0,100,0),
(@PATH,4,-5370.835,426.743,384.905,0,0,0,0,100,0),
(@PATH,5,-5382.682,444.307,385.976,0,0,0,0,100,0),
(@PATH,6,-5395.065,458.535,384.619,0,0,0,0,100,0);

-- Toxic Sludge 168547 -- 7 nodes out and back, 12 points.
SET @NPC := 168547;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5311.540,406.684,389.414,0,0,0,0,100,0),
(@PATH,2,-5325.132,407.132,389.383,0,0,0,0,100,0),
(@PATH,3,-5335.753,413.264,388.187,0,0,0,0,100,0),
(@PATH,4,-5342.764,421.189,387.492,0,0,0,0,100,0),
(@PATH,5,-5355.188,422.609,384.479,0,0,0,0,100,0),
(@PATH,6,-5367.333,421.288,385.581,0,0,0,0,100,0),
(@PATH,7,-5375.100,409.641,389.511,0,0,0,0,100,0),
(@PATH,8,-5367.333,421.288,385.581,0,0,0,0,100,0),
(@PATH,9,-5355.188,422.609,384.479,0,0,0,0,100,0),
(@PATH,10,-5342.764,421.189,387.492,0,0,0,0,100,0),
(@PATH,11,-5335.753,413.264,388.187,0,0,0,0,100,0),
(@PATH,12,-5325.132,407.132,389.383,0,0,0,0,100,0);

-- Toxic Sludge 169137 -- 7 nodes out and back, 12 points.
SET @NPC := 169137;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5420.559,556.205,389.087,0,0,0,0,100,0),
(@PATH,2,-5436.835,547.585,387.430,0,0,0,0,100,0),
(@PATH,3,-5439.604,536.873,387.142,0,0,0,0,100,0),
(@PATH,4,-5436.835,547.585,387.430,0,0,0,0,100,0),
(@PATH,5,-5420.559,556.205,389.087,0,0,0,0,100,0),
(@PATH,6,-5405.276,559.358,388.872,0,0,0,0,100,0),
(@PATH,7,-5397.918,549.408,386.294,0,0,0,0,100,0),
(@PATH,8,-5367.174,546.562,386.417,0,0,0,0,100,0),
(@PATH,9,-5352.660,563.882,384.149,0,0,0,0,100,0),
(@PATH,10,-5367.174,546.562,386.417,0,0,0,0,100,0),
(@PATH,11,-5397.918,549.408,386.294,0,0,0,0,100,0),
(@PATH,12,-5405.276,559.358,388.872,0,0,0,0,100,0);

-- Living Contamination 168322 -- 7 nodes out and back, 12 points.
SET @NPC := 168322;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5322.747,544.490,385.117,0,0,0,0,100,0),
(@PATH,2,-5317.665,559.177,385.533,0,0,0,0,100,0),
(@PATH,3,-5310.040,570.979,388.169,0,0,0,0,100,0),
(@PATH,4,-5299.486,574.913,388.349,0,0,0,0,100,0),
(@PATH,5,-5291.543,575.321,386.861,0,0,0,0,100,0),
(@PATH,6,-5299.486,574.913,388.349,0,0,0,0,100,0),
(@PATH,7,-5310.040,570.979,388.169,0,0,0,0,100,0),
(@PATH,8,-5317.665,559.177,385.533,0,0,0,0,100,0),
(@PATH,9,-5322.747,544.490,385.117,0,0,0,0,100,0),
(@PATH,10,-5324.955,529.380,384.684,0,0,0,0,100,0),
(@PATH,11,-5335.988,520.510,384.939,0,0,0,0,100,0),
(@PATH,12,-5324.955,529.380,384.684,0,0,0,0,100,0);

-- Living Contamination 168443 -- 6 nodes out and back, 10 points.
SET @NPC := 168443;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5312.521,485.175,384.180,0,0,0,0,100,0),
(@PATH,2,-5320.378,480.096,384.765,0,0,0,0,100,0),
(@PATH,3,-5334.361,472.151,384.427,0,0,0,0,100,0),
(@PATH,4,-5348.663,465.576,385.452,0,0,0,0,100,0),
(@PATH,5,-5334.361,472.151,384.427,0,0,0,0,100,0),
(@PATH,6,-5320.378,480.096,384.765,0,0,0,0,100,0),
(@PATH,7,-5312.521,485.175,384.180,0,0,0,0,100,0),
(@PATH,8,-5293.266,489.404,382.775,0,0,0,0,100,0),
(@PATH,9,-5281.602,489.819,382.775,0,0,0,0,100,0),
(@PATH,10,-5293.266,489.404,382.775,0,0,0,0,100,0);

-- Living Contamination 168997 -- 5 nodes out and back, 8 points.
SET @NPC := 168997;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5483.668,559.177,394.107,0,0,0,0,100,0),
(@PATH,2,-5488.762,530.085,388.389,0,0,0,0,100,0),
(@PATH,3,-5489.656,509.019,387.329,0,0,0,0,100,0),
(@PATH,4,-5482.627,487.882,385.997,0,0,0,0,100,0),
(@PATH,5,-5476.207,475.052,385.932,0,0,0,0,100,0),
(@PATH,6,-5482.627,487.882,385.997,0,0,0,0,100,0),
(@PATH,7,-5489.656,509.019,387.329,0,0,0,0,100,0),
(@PATH,8,-5488.762,530.085,388.389,0,0,0,0,100,0);

-- Living Contamination 169011 -- 18 node circuit, 18 points.
SET @NPC := 169011;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5510.198,366.474,391.007,0,0,0,0,100,0),
(@PATH,2,-5519.467,378.637,388.960,0,0,0,0,100,0),
(@PATH,3,-5516.719,395.307,388.328,0,0,0,0,100,0),
(@PATH,4,-5506.391,410.891,384.879,0,0,0,0,100,0),
(@PATH,5,-5493.778,429.068,383.114,0,0,0,0,100,0),
(@PATH,6,-5485.969,442.856,384.273,0,0,0,0,100,0),
(@PATH,7,-5474.757,455.988,384.651,0,0,0,0,100,0),
(@PATH,8,-5467.408,464.186,385.337,0,0,0,0,100,0),
(@PATH,9,-5438.734,467.344,385.515,0,0,0,0,100,0),
(@PATH,10,-5422.363,459.884,385.862,0,0,0,0,100,0),
(@PATH,11,-5428.551,450.795,385.081,0,0,0,0,100,0),
(@PATH,12,-5437.602,436.927,386.381,0,0,0,0,100,0),
(@PATH,13,-5441.721,423.080,388.366,0,0,0,0,100,0),
(@PATH,14,-5442.818,409.181,390.954,0,0,0,0,100,0),
(@PATH,15,-5458.557,402.738,390.229,0,0,0,0,100,0),
(@PATH,16,-5474.530,385.778,392.274,0,0,0,0,100,0),
(@PATH,17,-5480.974,372.314,393.536,0,0,0,0,100,0),
(@PATH,18,-5493.042,363.696,393.075,0,0,0,0,100,0);

-- Living Contamination 169171 -- 7 nodes out and back, 12 points.
SET @NPC := 169171;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5377.075,508.128,385.247,0,0,0,0,100,0),
(@PATH,2,-5362.855,515.441,385.071,0,0,0,0,100,0),
(@PATH,3,-5377.075,508.128,385.247,0,0,0,0,100,0),
(@PATH,4,-5381.648,498.274,384.608,0,0,0,0,100,0),
(@PATH,5,-5375.323,483.998,384.553,0,0,0,0,100,0),
(@PATH,6,-5365.521,478.964,384.035,0,0,0,0,100,0),
(@PATH,7,-5360.731,462.255,385.079,0,0,0,0,100,0),
(@PATH,8,-5364.658,453.384,384.137,0,0,0,0,100,0),
(@PATH,9,-5360.731,462.255,385.079,0,0,0,0,100,0),
(@PATH,10,-5365.521,478.964,384.035,0,0,0,0,100,0),
(@PATH,11,-5375.323,483.998,384.553,0,0,0,0,100,0),
(@PATH,12,-5381.648,498.274,384.608,0,0,0,0,100,0);

-- @touched: creature,creature_addon,waypoint_data 168533,168547,169137,168322,168443,168997,169011,169171
