-- New Tinkertown, Brewnall Village (area 137): one Dun Morogh Mountaineer walks
-- the loop round the village. Seven of the eight 13076 spawns stand at their
-- positions; 167804 is the one without a fixed post and takes the route.
-- Continuous walk, no pauses. Point 1 is the node nearest the spawn (3.2 yd).
-- The addon row keeps the template's PvPFlags; the other seven spawns are untouched.
-- Dun Morogh Mountaineer (entry 13076) -- sniffed spawn 10495409
--   matched guid 167804 at 3.243 yd from a route node (next candidate 4.0 yd)
--   15 waypoints, circuit of 15 nodes, via gap-free lap, walk (2.35 yd/s), 0 node(s) with a delay
--   was MovementType 0, wander_distance 0, no creature_addon path
SET @NPC := 167804;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,1,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5394.629,317.151,394.579,0,0,0,0,100,0),
(@PATH,2,-5388.861,320.673,394.603,0,0,0,0,100,0),
(@PATH,3,-5377.795,326.042,394.678,0,0,0,0,100,0),
(@PATH,4,-5363.929,327.500,394.190,0,0,0,0,100,0),
(@PATH,5,-5351.942,323.958,394.268,0,0,0,0,100,0),
(@PATH,6,-5346.827,313.973,394.668,0,0,0,0,100,0),
(@PATH,7,-5353.341,304.579,394.278,0,0,0,0,100,0),
(@PATH,8,-5344.709,297.231,394.854,0,0,0,0,100,0),
(@PATH,9,-5344.167,284.884,392.600,0,0,0,0,100,0),
(@PATH,10,-5355.671,286.348,393.793,0,0,0,0,100,0),
(@PATH,11,-5361.591,273.783,394.283,0,0,0,0,100,0),
(@PATH,12,-5374.789,277.402,394.242,0,0,0,0,100,0),
(@PATH,13,-5387.133,287.221,394.209,0,0,0,0,100,0),
(@PATH,14,-5396.016,300.036,394.896,0,0,0,0,100,0),
(@PATH,15,-5397.955,306.351,394.592,0,0,0,0,100,0);

-- 1 paths, 15 waypoint rows total, 0 route(s) skipped
-- @touched: creature,creature_addon,waypoint_data 167804
