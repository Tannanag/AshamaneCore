-- New Tinkertown, the trogg tunnel west of town: patrol routes for 13 spawns
-- Eight Rockjaw Marauders and four Rockjaw Fungus-Flingers walk fixed routes.
-- Every other Marauder keeps its roam; the other Fungus-Flingers and every
-- Bonepicker stand still or sleep, and are left alone.
--
-- waypoint_data is cyclic, so an out-and-back lists the return leg as further
-- points rather than reversing: the last point leads back to point 1.
-- Point 1 is the node the spawn stands on, so a respawn does not cross its route.
-- creature_addon.path_id is mandatory here -- with MovementType 2 and no path_id
-- the spawn is silently downgraded to idle on load.
-- A creature_addon row replaces the template addon outright, so each row
-- carries the entry's aura again (79253 for the Marauders, 80928 for the
-- Fungus-Flingers) or the spawn would lose it.

-- Rockjaw Marauder 168975 -- 11-node loop, 11 points.
SET @NPC := 168975;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'79253');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5607.580,289.630,393.727,0,0,0,0,100,0),
(@PATH,2,-5599.373,277.460,395.178,0,0,0,0,100,0),
(@PATH,3,-5580.641,271.262,396.147,0,0,0,0,100,0),
(@PATH,4,-5554.327,271.736,396.029,0,0,0,0,100,0),
(@PATH,5,-5542.771,279.502,395.890,0,0,0,0,100,0),
(@PATH,6,-5531.137,290.017,396.597,0,0,0,0,100,0),
(@PATH,7,-5543.066,310.453,396.386,0,0,0,0,100,0),
(@PATH,8,-5558.248,320.939,394.849,0,0,0,0,100,0),
(@PATH,9,-5574.370,322.052,394.440,0,0,0,0,100,0),
(@PATH,10,-5589.743,316.960,393.552,0,0,0,0,100,0),
(@PATH,11,-5598.135,307.509,393.666,0,0,0,0,100,0);

-- Rockjaw Marauder 168317 -- 12-node loop, 12 points; spawn point is 9 yd off point 1.
SET @NPC := 168317;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'79253');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5640.297,430.253,383.260,0,0,0,0,100,0),
(@PATH,2,-5651.627,447.497,384.007,0,0,0,0,100,0),
(@PATH,3,-5670.210,435.649,385.681,0,0,0,0,100,0),
(@PATH,4,-5677.756,426.320,386.534,0,0,0,0,100,0),
(@PATH,5,-5685.010,405.580,390.979,0,0,0,0,100,0),
(@PATH,6,-5688.208,387.346,392.376,0,0,0,0,100,0),
(@PATH,7,-5684.024,375.490,391.647,0,0,0,0,100,0),
(@PATH,8,-5666.762,372.450,390.142,0,0,0,0,100,0),
(@PATH,9,-5656.505,373.358,387.558,0,0,0,0,100,0),
(@PATH,10,-5645.780,380.127,385.299,0,0,0,0,100,0),
(@PATH,11,-5635.241,391.674,383.445,0,0,0,0,100,0),
(@PATH,12,-5634.554,408.153,382.870,0,0,0,0,100,0);

-- Rockjaw Marauder 168528 -- 5 nodes out and back, 8 points.
SET @NPC := 168528;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'79253');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5640.137,516.363,387.255,0,0,0,0,100,0),
(@PATH,2,-5654.481,529.623,387.360,0,0,0,0,100,0),
(@PATH,3,-5674.986,533.267,386.466,0,0,0,0,100,0),
(@PATH,4,-5699.057,543.068,387.702,0,0,0,0,100,0),
(@PATH,5,-5674.986,533.267,386.466,0,0,0,0,100,0),
(@PATH,6,-5654.481,529.623,387.360,0,0,0,0,100,0),
(@PATH,7,-5640.137,516.363,387.255,0,0,0,0,100,0),
(@PATH,8,-5635.768,511.441,386.877,0,0,0,0,100,0);

-- Rockjaw Marauder 168517 -- 7 nodes out and back, 12 points.
SET @NPC := 168517;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'79253');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5597.483,512.278,383.806,0,0,0,0,100,0),
(@PATH,2,-5596.588,496.311,384.689,0,0,0,0,100,0),
(@PATH,3,-5593.222,482.929,385.097,0,0,0,0,100,0),
(@PATH,4,-5596.588,496.311,384.689,0,0,0,0,100,0),
(@PATH,5,-5597.483,512.278,383.806,0,0,0,0,100,0),
(@PATH,6,-5591.219,522.038,383.356,0,0,0,0,100,0),
(@PATH,7,-5582.045,532.547,383.694,0,0,0,0,100,0),
(@PATH,8,-5566.719,541.385,385.242,0,0,0,0,100,0),
(@PATH,9,-5555.174,544.486,388.759,0,0,0,0,100,0),
(@PATH,10,-5566.719,541.385,385.242,0,0,0,0,100,0),
(@PATH,11,-5582.045,532.547,383.694,0,0,0,0,100,0),
(@PATH,12,-5591.219,522.038,383.356,0,0,0,0,100,0);

-- Rockjaw Marauder 168590 -- 7 nodes out and back, 12 points.
SET @NPC := 168590;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'79253');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5609.707,408.661,380.583,0,0,0,0,100,0),
(@PATH,2,-5601.200,402.033,381.735,0,0,0,0,100,0),
(@PATH,3,-5588.443,398.918,381.727,0,0,0,0,100,0),
(@PATH,4,-5581.781,384.618,383.890,0,0,0,0,100,0),
(@PATH,5,-5588.443,398.918,381.727,0,0,0,0,100,0),
(@PATH,6,-5601.200,402.033,381.735,0,0,0,0,100,0),
(@PATH,7,-5609.707,408.661,380.583,0,0,0,0,100,0),
(@PATH,8,-5619.134,422.293,381.338,0,0,0,0,100,0),
(@PATH,9,-5632.744,441.074,383.259,0,0,0,0,100,0),
(@PATH,10,-5637.721,453.083,383.961,0,0,0,0,100,0),
(@PATH,11,-5632.744,441.074,383.259,0,0,0,0,100,0),
(@PATH,12,-5619.134,422.293,381.338,0,0,0,0,100,0);

-- Rockjaw Marauder 168613 -- 6 nodes out and back, 10 points.
SET @NPC := 168613;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'79253');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5627.880,463.929,384.607,0,0,0,0,100,0),
(@PATH,2,-5640.616,471.896,386.150,0,0,0,0,100,0),
(@PATH,3,-5655.656,479.529,387.429,0,0,0,0,100,0),
(@PATH,4,-5668.726,483.552,388.815,0,0,0,0,100,0),
(@PATH,5,-5655.656,479.529,387.429,0,0,0,0,100,0),
(@PATH,6,-5640.616,471.896,386.150,0,0,0,0,100,0),
(@PATH,7,-5627.880,463.929,384.607,0,0,0,0,100,0),
(@PATH,8,-5605.662,458.337,383.400,0,0,0,0,100,0),
(@PATH,9,-5578.690,451.957,383.791,0,0,0,0,100,0),
(@PATH,10,-5605.662,458.337,383.400,0,0,0,0,100,0);

-- Rockjaw Marauder 168624 -- 7 nodes out and back, 12 points.
SET @NPC := 168624;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'79253');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5623.571,336.797,388.521,0,0,0,0,100,0),
(@PATH,2,-5637.225,343.008,387.105,0,0,0,0,100,0),
(@PATH,3,-5656.090,332.311,387.452,0,0,0,0,100,0),
(@PATH,4,-5637.225,343.008,387.105,0,0,0,0,100,0),
(@PATH,5,-5623.571,336.797,388.521,0,0,0,0,100,0),
(@PATH,6,-5612.106,336.615,388.485,0,0,0,0,100,0),
(@PATH,7,-5598.698,341.622,389.020,0,0,0,0,100,0),
(@PATH,8,-5581.003,349.976,389.436,0,0,0,0,100,0),
(@PATH,9,-5566.387,355.019,390.435,0,0,0,0,100,0),
(@PATH,10,-5581.003,349.976,389.436,0,0,0,0,100,0),
(@PATH,11,-5598.698,341.622,389.020,0,0,0,0,100,0),
(@PATH,12,-5612.106,336.615,388.485,0,0,0,0,100,0);

-- Rockjaw Marauder 168654 -- 2 nodes, back and forth.
SET @NPC := 168654;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'79253');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5540.143,703.502,372.504,0,0,0,0,100,0),
(@PATH,2,-5554.495,729.958,377.809,0,0,0,0,100,0);

-- Rockjaw Fungus-Flinger 168664 -- 7 nodes out and back, 12 points.
SET @NPC := 168664;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'80928');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5571.361,670.023,387.014,0,0,0,0,100,0),
(@PATH,2,-5571.639,680.196,384.753,0,0,0,0,100,0),
(@PATH,3,-5570.523,693.330,381.131,0,0,0,0,100,0),
(@PATH,4,-5571.639,680.196,384.753,0,0,0,0,100,0),
(@PATH,5,-5571.361,670.023,387.014,0,0,0,0,100,0),
(@PATH,6,-5570.519,662.358,387.966,0,0,0,0,100,0),
(@PATH,7,-5565.984,655.326,388.975,0,0,0,0,100,0),
(@PATH,8,-5555.858,653.267,389.290,0,0,0,0,100,0),
(@PATH,9,-5545.667,652.436,391.803,0,0,0,0,100,0),
(@PATH,10,-5555.858,653.267,389.290,0,0,0,0,100,0),
(@PATH,11,-5565.984,655.326,388.975,0,0,0,0,100,0),
(@PATH,12,-5570.519,662.358,387.966,0,0,0,0,100,0);

-- Rockjaw Fungus-Flinger 168667 -- 5 nodes, 7 points; the far node is skipped on the way back.
SET @NPC := 168667;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'80928');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5516.212,654.030,391.966,0,0,0,0,100,0),
(@PATH,2,-5514.815,649.689,391.533,0,0,0,0,100,0),
(@PATH,3,-5517.073,647.226,391.167,0,0,0,0,100,0),
(@PATH,4,-5516.212,654.030,391.966,0,0,0,0,100,0),
(@PATH,5,-5519.708,658.458,391.643,0,0,0,0,100,0),
(@PATH,6,-5523.471,661.701,391.782,0,0,0,0,100,0),
(@PATH,7,-5519.708,658.458,391.643,0,0,0,0,100,0);

-- Rockjaw Fungus-Flinger 168675 -- 5 nodes out and back, 8 points; spawn point is on the first leg.
SET @NPC := 168675;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'80928');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5497.028,636.116,393.316,0,0,0,0,100,0),
(@PATH,2,-5507.640,640.125,394.962,0,0,0,0,100,0),
(@PATH,3,-5513.130,636.413,393.924,0,0,0,0,100,0),
(@PATH,4,-5518.698,636.924,394.519,0,0,0,0,100,0),
(@PATH,5,-5523.778,640.955,395.507,0,0,0,0,100,0),
(@PATH,6,-5518.698,636.924,394.519,0,0,0,0,100,0),
(@PATH,7,-5513.130,636.413,393.924,0,0,0,0,100,0),
(@PATH,8,-5507.640,640.125,394.962,0,0,0,0,100,0);

-- Rockjaw Fungus-Flinger 168674 -- 8 nodes out and back, 14 points.
SET @NPC := 168674;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'80928');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5546.088,579.476,394.881,0,0,0,0,100,0),
(@PATH,2,-5544.562,593.646,393.688,0,0,0,0,100,0),
(@PATH,3,-5543.944,601.773,392.934,0,0,0,0,100,0),
(@PATH,4,-5539.453,609.547,393.999,0,0,0,0,100,0),
(@PATH,5,-5533.971,612.609,394.794,0,0,0,0,100,0),
(@PATH,6,-5526.274,613.620,393.513,0,0,0,0,100,0),
(@PATH,7,-5519.882,620.769,393.814,0,0,0,0,100,0),
(@PATH,8,-5515.535,630.078,393.774,0,0,0,0,100,0),
(@PATH,9,-5519.882,620.769,393.814,0,0,0,0,100,0),
(@PATH,10,-5526.274,613.620,393.513,0,0,0,0,100,0),
(@PATH,11,-5533.971,612.609,394.794,0,0,0,0,100,0),
(@PATH,12,-5539.453,609.547,393.999,0,0,0,0,100,0),
(@PATH,13,-5543.944,601.773,392.934,0,0,0,0,100,0),
(@PATH,14,-5544.562,593.646,393.688,0,0,0,0,100,0);

-- @touched: creature,creature_addon,waypoint_data 168975,168317,168528,168517,168590,168613,168624,168654,168664,168667,168675,168674
