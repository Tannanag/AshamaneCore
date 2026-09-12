-- New Tinkertown: Boss Bruggor (42773, guid 168644) walks a fixed line
-- instead of pacing a 3-yard circle. Four nodes out and back along the
-- ridge above the detonator, 55 yd per lap at walk speed, no stops at the
-- ends. Point 1 is the node he spawns on, so a respawn starts on its route.
-- waypoint_data is cyclic, so the return leg is listed as further points.
-- creature_addon.path_id is mandatory with MovementType 2; the template
-- addon carries no auras, so the row adds none.
-- His SmartAI (Enrage at 30% with its line, Club in combat) is untouched --
-- both spells are the whole of his cast list and both exist in the client.

-- Boss Bruggor 168644 -- 4 nodes out and back, 6 points.
SET @NPC := 168644;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC AND `id`=42773;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,'');
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-5539.186,727.467,378.269,0,0,0,0,100,0),
(@PATH,2,-5534.602,721.538,377.917,0,0,0,0,100,0),
(@PATH,3,-5527.891,716.504,377.952,0,0,0,0,100,0),
(@PATH,4,-5534.602,721.538,377.917,0,0,0,0,100,0),
(@PATH,5,-5539.186,727.467,378.269,0,0,0,0,100,0),
(@PATH,6,-5546.078,736.932,378.328,0,0,0,0,100,0);

-- @touched: creature,creature_addon,waypoint_data 168644
