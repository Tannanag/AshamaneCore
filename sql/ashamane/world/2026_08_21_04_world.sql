-- Coldridge Valley: give twelve spawns their retail patrol routes, from a sniff of
-- the zone. Each route is the observed lap and starts at the node nearest the spawn
-- point, so an NPC does not walk its own path's diameter on every respawn.
-- path_id is guid * 10 throughout.

-- Coldridge Mountaineer 853, guid 166972 -- 42 points
SET @NPC := 166972;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6101.130,395.008,395.597,0,0,0,0,100,0),
(@PATH,2,-6115.750,393.525,395.597,0,0,0,0,100,0),
(@PATH,3,-6127.310,392.842,395.597,0,0,0,0,100,0),
(@PATH,4,-6130.430,383.783,395.597,0,0,0,0,100,0),
(@PATH,5,-6155.240,383.909,395.597,0,0,0,0,100,0),
(@PATH,6,-6167.640,383.766,398.919,0,0,0,0,100,0),
(@PATH,7,-6174.320,376.123,398.238,0,0,0,0,100,0),
(@PATH,8,-6178.790,365.716,398.695,0,0,0,0,100,0),
(@PATH,9,-6176.250,371.865,398.726,0,0,0,0,100,0),
(@PATH,10,-6167.640,383.766,398.919,0,0,0,0,100,0),
(@PATH,11,-6155.240,383.909,395.597,0,0,0,0,100,0),
(@PATH,12,-6130.430,383.783,395.597,0,0,0,0,100,0),
(@PATH,13,-6129.710,375.099,395.597,0,0,0,0,100,0),
(@PATH,14,-6129.790,376.002,395.597,0,0,0,0,100,0),
(@PATH,15,-6117.870,375.622,395.597,0,0,0,0,100,0),
(@PATH,16,-6099.720,375.894,395.597,0,0,0,0,100,0),
(@PATH,17,-6099.200,377.140,395.597,0,0,0,0,100,0),
(@PATH,18,-6093.380,374.979,395.597,0,0,0,0,100,0),
(@PATH,19,-6087.970,379.673,395.597,0,0,0,0,100,0),
(@PATH,20,-6088.800,388.061,395.597,0,0,0,0,100,0),
(@PATH,21,-6094.020,395.521,395.597,0,0,0,0,100,0),
(@PATH,22,-6101.130,395.008,395.597,0,0,0,0,100,0),
(@PATH,23,-6115.750,393.525,395.597,0,0,0,0,100,0),
(@PATH,24,-6127.310,392.842,395.597,0,0,0,0,100,0),
(@PATH,25,-6130.430,383.783,395.597,0,0,0,0,100,0),
(@PATH,26,-6155.240,383.909,395.597,0,0,0,0,100,0),
(@PATH,27,-6167.640,383.766,398.919,0,0,0,0,100,0),
(@PATH,28,-6174.320,376.123,398.238,0,0,0,0,100,0),
(@PATH,29,-6178.790,365.716,398.695,0,0,0,0,100,0),
(@PATH,30,-6176.250,371.865,398.726,0,0,0,0,100,0),
(@PATH,31,-6167.640,383.766,398.919,0,0,0,0,100,0),
(@PATH,32,-6155.240,383.909,395.597,0,0,0,0,100,0),
(@PATH,33,-6130.430,383.783,395.597,0,0,0,0,100,0),
(@PATH,34,-6129.710,375.099,395.597,0,0,0,0,100,0),
(@PATH,35,-6129.790,376.002,395.597,0,0,0,0,100,0),
(@PATH,36,-6104.920,375.059,395.597,0,0,0,0,100,0),
(@PATH,37,-6099.720,375.894,395.597,0,0,0,0,100,0),
(@PATH,38,-6099.200,377.140,395.597,0,0,0,0,100,0),
(@PATH,39,-6093.380,374.979,395.597,0,0,0,0,100,0),
(@PATH,40,-6087.970,379.673,395.597,0,0,0,0,100,0),
(@PATH,41,-6088.800,388.061,395.597,0,0,0,0,100,0),
(@PATH,42,-6094.020,395.521,395.597,0,0,0,0,100,0);

-- Coldridge Mountaineer 853, guid 166975 -- 15 points
SET @NPC := 166975;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6080.260,383.485,393.597,0,0,0,0,100,0),
(@PATH,2,-6075.880,384.170,393.597,0,0,0,0,100,0),
(@PATH,3,-6065.810,383.761,393.548,0,0,0,0,100,0),
(@PATH,4,-6077.330,384.505,393.597,0,0,0,0,100,0),
(@PATH,5,-6081.070,393.094,393.818,0,0,0,0,100,0),
(@PATH,6,-6089.590,400.611,395.662,0,0,0,0,100,0),
(@PATH,7,-6094.960,397.080,395.597,0,0,0,0,100,0),
(@PATH,8,-6104.310,396.571,396.021,0,0,0,0,100,0),
(@PATH,9,-6108.480,398.134,395.597,0,0,0,0,100,0),
(@PATH,10,-6111.330,398.886,395.597,0,0,0,0,100,0),
(@PATH,11,-6109.580,390.309,395.597,0,0,0,0,100,0),
(@PATH,12,-6108.310,376.966,395.597,0,0,0,0,100,0),
(@PATH,13,-6098.930,372.751,395.597,0,0,0,0,100,0),
(@PATH,14,-6089.930,366.932,395.597,0,0,0,0,100,0),
(@PATH,15,-6081.340,376.956,393.565,0,0,0,0,100,0);

-- Jona Ironstock 37087, guid 166999 -- 12 points
SET @NPC := 166999;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6087.650,378.986,395.597,0,0,0,0,100,0),
(@PATH,2,-6087.110,384.087,395.597,0,0,0,0,100,0),
(@PATH,3,-6088.330,388.927,395.597,0,0,0,0,100,0),
(@PATH,4,-6091.980,392.017,395.597,0,0,0,0,100,0),
(@PATH,5,-6097.100,394.399,395.597,0,0,0,0,100,0),
(@PATH,6,-6101.170,393.582,395.643,0,0,0,0,100,0),
(@PATH,7,-6105.890,389.401,395.597,0,0,0,0,100,0),
(@PATH,8,-6107.840,384.884,395.597,0,0,0,0,100,0),
(@PATH,9,-6106.490,378.385,395.597,0,0,0,0,100,0),
(@PATH,10,-6103.130,374.660,395.597,0,0,0,0,100,0),
(@PATH,11,-6097.210,372.309,395.647,0,0,0,0,100,0),
(@PATH,12,-6091.910,375.050,395.597,0,0,0,0,100,0);

-- Coldridge Citizen 37218, guid 167012 -- 25 points
SET @NPC := 167012;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6066.910,389.326,393.537,0,0,0,0,100,0),
(@PATH,2,-6067.550,394.507,392.800,0,0,0,0,100,0),
(@PATH,3,-6067.020,399.549,392.792,0,0,0,0,100,0),
(@PATH,4,-6064.040,399.736,392.850,0,0,0,0,100,0),
(@PATH,5,-6057.680,398.434,392.801,0,0,0,0,100,0),
(@PATH,6,-6064.630,399.957,392.869,0,0,0,0,100,0),
(@PATH,7,-6067.630,399.628,392.795,0,0,0,0,100,0),
(@PATH,8,-6067.970,393.330,392.800,0,0,0,0,100,0),
(@PATH,9,-6067.630,390.549,392.876,0,0,0,0,100,0),
(@PATH,10,-6070.250,385.453,393.718,0,0,0,0,100,0),
(@PATH,11,-6072.050,382.976,393.742,0,0,0,0,100,0),
(@PATH,12,-6074.470,382.807,393.597,0,0,0,0,100,0),
(@PATH,13,-6076.020,385.981,393.597,0,0,0,0,100,0),
(@PATH,14,-6078.620,381.453,393.597,0,0,0,0,100,0),
(@PATH,15,-6077.720,378.448,393.630,0,0,0,0,100,0),
(@PATH,16,-6080.440,375.686,393.597,0,0,0,0,100,0),
(@PATH,17,-6088.110,368.946,395.609,0,0,0,0,100,0),
(@PATH,18,-6095.620,368.960,395.620,0,0,0,0,100,0),
(@PATH,19,-6098.980,365.108,395.597,0,0,0,0,100,0),
(@PATH,20,-6102.100,363.615,395.597,0,0,0,0,100,0),
(@PATH,21,-6097.100,366.309,395.597,0,0,0,0,100,0),
(@PATH,22,-6098.620,365.490,395.597,0,0,0,0,100,0),
(@PATH,23,-6081.210,374.755,394.027,0,0,0,0,100,0),
(@PATH,24,-6075.090,382.682,393.597,0,0,0,0,100,0),
(@PATH,25,-6070.760,382.821,393.650,0,0,0,0,100,0);

-- Coldridge Citizen 37218, guid 167017 -- 9 points
SET @NPC := 167017;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6066.970,370.811,393.597,0,0,0,0,100,0),
(@PATH,2,-6069.180,382.866,393.609,0,0,0,0,100,0),
(@PATH,3,-6074.950,386.149,393.597,0,0,0,0,100,0),
(@PATH,4,-6081.570,392.512,393.689,0,0,0,0,100,0),
(@PATH,5,-6088.330,399.516,395.597,0,0,0,0,100,0),
(@PATH,6,-6081.270,393.029,393.822,0,0,0,0,100,0),
(@PATH,7,-6074.950,386.149,393.597,0,0,0,0,100,0),
(@PATH,8,-6071.470,385.264,393.950,0,0,0,0,100,0),
(@PATH,9,-6067.960,380.767,393.706,0,0,0,0,100,0);

-- Sten Stoutarm 658, guid 167020 -- 3 points
SET @NPC := 167020;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6240.077,347.385,383.848,0,0,0,0,100,0),
(@PATH,2,-6243.069,345.675,383.369,0,0,0,0,100,0),
(@PATH,3,-6229.550,346.663,383.664,0,0,0,0,100,0);

-- Coldridge Mountaineer 853, guid 167026 -- 11 points
SET @NPC := 167026;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6187.380,381.038,393.550,0,0,0,0,100,0),
(@PATH,2,-6210.330,374.399,387.752,0,0,0,0,100,0),
(@PATH,3,-6221.240,358.794,384.928,0,0,0,0,100,0),
(@PATH,4,-6225.120,345.355,383.451,0,0,0,0,100,0),
(@PATH,5,-6232.760,338.974,383.238,0,0,0,0,100,0),
(@PATH,6,-6225.120,345.355,383.451,0,0,0,0,100,0),
(@PATH,7,-6218.740,364.024,385.571,0,0,0,0,100,0),
(@PATH,8,-6213.270,373.000,387.177,0,0,0,0,100,0),
(@PATH,9,-6199.650,378.702,390.182,0,0,0,0,100,0),
(@PATH,10,-6184.350,382.753,394.600,0,0,0,0,100,0),
(@PATH,11,-6181.540,384.817,395.536,0,0,0,0,100,0);

-- Coldridge Mountaineer 853, guid 167027 -- 20 points
SET @NPC := 167027;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6255.720,310.069,383.152,0,0,0,0,100,0),
(@PATH,2,-6248.780,318.549,382.724,0,0,0,0,100,0),
(@PATH,3,-6236.730,321.102,382.642,0,0,0,0,100,0),
(@PATH,4,-6248.780,318.549,382.724,0,0,0,0,100,0),
(@PATH,5,-6255.720,310.069,383.152,0,0,0,0,100,0),
(@PATH,6,-6254.480,290.208,383.707,0,0,0,0,100,0),
(@PATH,7,-6253.690,267.724,385.809,0,0,0,0,100,0),
(@PATH,8,-6258.820,243.262,391.910,0,0,0,0,100,0),
(@PATH,9,-6266.330,224.865,399.189,0,0,0,0,100,0),
(@PATH,10,-6264.500,208.361,406.227,0,0,0,0,100,0),
(@PATH,11,-6264.220,191.137,412.652,0,0,0,0,100,0),
(@PATH,12,-6253.900,175.225,419.043,0,0,0,0,100,0),
(@PATH,13,-6237.220,160.976,426.151,0,0,0,0,100,0),
(@PATH,14,-6253.900,175.225,419.043,0,0,0,0,100,0),
(@PATH,15,-6264.220,191.137,412.652,0,0,0,0,100,0),
(@PATH,16,-6264.500,208.361,406.227,0,0,0,0,100,0),
(@PATH,17,-6266.330,224.865,399.189,0,0,0,0,100,0),
(@PATH,18,-6258.820,243.262,391.910,0,0,0,0,100,0),
(@PATH,19,-6253.690,267.724,385.809,0,0,0,0,100,0),
(@PATH,20,-6254.480,290.208,383.707,0,0,0,0,100,0);

-- Coldridge Citizen 37218, guid 167038 -- 48 points
SET @NPC := 167038;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6061.660,393.167,392.800,0,0,0,0,100,0),
(@PATH,2,-6068.020,393.368,392.800,0,0,0,0,100,0),
(@PATH,3,-6067.910,390.681,392.800,0,0,0,0,100,0),
(@PATH,4,-6067.810,389.477,393.559,0,0,0,0,100,0),
(@PATH,5,-6068.400,383.965,393.623,0,0,0,0,100,0),
(@PATH,6,-6079.960,383.828,393.597,0,0,0,0,100,0),
(@PATH,7,-6081.070,392.474,393.588,0,0,0,0,100,0),
(@PATH,8,-6088.340,399.752,395.597,0,0,0,0,100,0),
(@PATH,9,-6096.200,397.608,395.597,0,0,0,0,100,0),
(@PATH,10,-6091.120,392.281,395.597,0,0,0,0,100,0),
(@PATH,11,-6087.000,383.484,395.597,0,0,0,0,100,0),
(@PATH,12,-6090.010,377.354,395.597,0,0,0,0,100,0),
(@PATH,13,-6097.650,368.788,395.597,0,0,0,0,100,0),
(@PATH,14,-6109.990,372.745,395.716,0,0,0,0,100,0),
(@PATH,15,-6120.650,375.186,395.597,0,0,0,0,100,0),
(@PATH,16,-6129.930,375.748,395.597,0,0,0,0,100,0),
(@PATH,17,-6130.130,383.755,395.597,0,0,0,0,100,0),
(@PATH,18,-6140.630,384.170,395.597,0,0,0,0,100,0),
(@PATH,19,-6130.130,383.755,395.597,0,0,0,0,100,0),
(@PATH,20,-6129.930,375.748,395.597,0,0,0,0,100,0),
(@PATH,21,-6120.650,375.186,395.597,0,0,0,0,100,0),
(@PATH,22,-6109.990,372.745,395.716,0,0,0,0,100,0),
(@PATH,23,-6097.650,368.788,395.597,0,0,0,0,100,0),
(@PATH,24,-6090.010,377.354,395.597,0,0,0,0,100,0),
(@PATH,25,-6087.000,383.484,395.597,0,0,0,0,100,0),
(@PATH,26,-6091.120,392.281,395.597,0,0,0,0,100,0),
(@PATH,27,-6096.200,397.608,395.597,0,0,0,0,100,0),
(@PATH,28,-6088.340,399.752,395.597,0,0,0,0,100,0),
(@PATH,29,-6081.070,392.474,393.588,0,0,0,0,100,0),
(@PATH,30,-6079.960,383.828,393.597,0,0,0,0,100,0),
(@PATH,31,-6068.400,383.965,393.623,0,0,0,0,100,0),
(@PATH,32,-6067.810,389.477,393.559,0,0,0,0,100,0),
(@PATH,33,-6068.020,393.368,392.800,0,0,0,0,100,0),
(@PATH,34,-6061.660,393.167,392.800,0,0,0,0,100,0),
(@PATH,35,-6061.180,373.740,393.013,0,0,0,0,100,0),
(@PATH,36,-6057.430,370.148,394.049,0,0,0,0,100,0),
(@PATH,37,-6055.420,370.240,395.200,0,0,0,0,100,0),
(@PATH,38,-6052.290,370.102,395.458,0,0,0,0,100,0),
(@PATH,39,-6052.060,373.281,395.644,0,0,0,0,100,0),
(@PATH,40,-6052.270,378.208,398.800,0,0,0,0,100,0),
(@PATH,41,-6052.100,380.988,398.988,0,0,0,0,100,0),
(@PATH,42,-6052.060,373.281,395.644,0,0,0,0,100,0),
(@PATH,43,-6052.290,370.102,395.458,0,0,0,0,100,0),
(@PATH,44,-6055.420,370.240,395.200,0,0,0,0,100,0),
(@PATH,45,-6057.430,370.148,394.049,0,0,0,0,100,0),
(@PATH,46,-6061.050,370.405,393.597,0,0,0,0,100,0),
(@PATH,47,-6058.500,370.233,393.707,0,0,0,0,100,0),
(@PATH,48,-6061.180,373.740,393.013,0,0,0,0,100,0);

-- Frostmane Blade 37507, guid 167209 -- 12 points
SET @NPC := 167209;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6528.170,402.971,382.694,0,0,0,0,100,0),
(@PATH,2,-6539.790,386.633,381.870,0,0,0,0,100,0),
(@PATH,3,-6541.570,377.342,381.706,0,0,0,0,100,0),
(@PATH,4,-6526.960,380.441,382.888,0,0,0,0,100,0),
(@PATH,5,-6512.760,382.574,385.090,0,0,0,0,100,0),
(@PATH,6,-6499.150,391.222,385.234,0,0,0,0,100,0),
(@PATH,7,-6512.760,382.574,385.090,0,0,0,0,100,0),
(@PATH,8,-6526.960,380.441,382.888,0,0,0,0,100,0),
(@PATH,9,-6541.570,377.342,381.706,0,0,0,0,100,0),
(@PATH,10,-6539.790,386.633,381.870,0,0,0,0,100,0),
(@PATH,11,-6528.170,402.971,382.694,0,0,0,0,100,0),
(@PATH,12,-6524.860,419.767,386.261,0,0,0,0,100,0);

-- Rockjaw Goon 37073, guid 167220 -- 28 points
SET @NPC := 167220;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6364.460,384.545,379.323,0,0,0,0,100,0),
(@PATH,2,-6363.350,364.764,378.457,0,0,0,0,100,0),
(@PATH,3,-6359.610,346.500,379.521,0,0,0,0,100,0),
(@PATH,4,-6366.280,339.219,384.798,0,0,0,0,100,0),
(@PATH,5,-6372.590,335.236,386.049,0,0,0,0,100,0),
(@PATH,6,-6379.400,320.790,386.097,0,0,0,0,100,0),
(@PATH,7,-6384.080,300.424,386.770,0,0,0,0,100,0),
(@PATH,8,-6384.460,281.269,389.702,0,0,0,0,100,0),
(@PATH,9,-6384.080,300.424,386.770,0,0,0,0,100,0),
(@PATH,10,-6379.400,320.790,386.097,0,0,0,0,100,0),
(@PATH,11,-6372.590,335.236,386.049,0,0,0,0,100,0),
(@PATH,12,-6366.280,339.219,384.798,0,0,0,0,100,0),
(@PATH,13,-6359.610,346.500,379.521,0,0,0,0,100,0),
(@PATH,14,-6363.350,364.764,378.457,0,0,0,0,100,0),
(@PATH,15,-6364.460,384.545,379.323,0,0,0,0,100,0),
(@PATH,16,-6361.230,401.899,375.875,0,0,0,0,100,0),
(@PATH,17,-6342.580,416.611,377.730,0,0,0,0,100,0),
(@PATH,18,-6329.820,426.830,379.581,0,0,0,0,100,0),
(@PATH,19,-6318.870,438.510,381.301,0,0,0,0,100,0),
(@PATH,20,-6303.200,447.109,385.710,0,0,0,0,100,0),
(@PATH,21,-6287.560,449.660,385.665,0,0,0,0,100,0),
(@PATH,22,-6270.790,450.490,386.067,0,0,0,0,100,0),
(@PATH,23,-6287.560,449.660,385.665,0,0,0,0,100,0),
(@PATH,24,-6303.200,447.109,385.710,0,0,0,0,100,0),
(@PATH,25,-6318.870,438.510,381.301,0,0,0,0,100,0),
(@PATH,26,-6329.820,426.830,379.581,0,0,0,0,100,0),
(@PATH,27,-6342.580,416.611,377.730,0,0,0,0,100,0),
(@PATH,28,-6361.230,401.899,375.875,0,0,0,0,100,0);

-- Wayward Fire Elemental 37112, guid 167308 -- 22 points
SET @NPC := 167308;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6485.480,331.351,369.273,0,0,0,0,100,0),
(@PATH,2,-6490.100,327.458,369.177,0,0,0,0,100,0),
(@PATH,3,-6492.640,323.155,369.032,0,0,0,0,100,0),
(@PATH,4,-6501.010,322.615,368.539,0,0,0,0,100,0),
(@PATH,5,-6504.960,326.509,367.973,0,0,0,0,100,0),
(@PATH,6,-6505.260,331.286,368.026,0,0,0,0,100,0),
(@PATH,7,-6506.290,335.095,368.531,0,0,0,0,100,0),
(@PATH,8,-6503.400,337.201,368.452,0,0,0,0,100,0),
(@PATH,9,-6498.720,336.800,368.202,0,0,0,0,100,0),
(@PATH,10,-6499.470,336.865,367.974,0,0,0,0,100,0),
(@PATH,11,-6484.160,338.507,369.161,0,0,0,0,100,0),
(@PATH,12,-6485.480,331.351,369.273,0,0,0,0,100,0),
(@PATH,13,-6490.100,327.458,369.177,0,0,0,0,100,0),
(@PATH,14,-6492.640,323.155,369.032,0,0,0,0,100,0),
(@PATH,15,-6501.010,322.615,368.539,0,0,0,0,100,0),
(@PATH,16,-6504.960,326.509,367.973,0,0,0,0,100,0),
(@PATH,17,-6505.260,331.286,368.026,0,0,0,0,100,0),
(@PATH,18,-6506.290,335.095,368.531,0,0,0,0,100,0),
(@PATH,19,-6503.400,337.201,368.452,0,0,0,0,100,0),
(@PATH,20,-6498.720,336.800,368.202,0,0,0,0,100,0),
(@PATH,21,-6492.820,339.056,368.494,0,0,0,0,100,0),
(@PATH,22,-6484.160,338.507,369.161,0,0,0,0,100,0);
