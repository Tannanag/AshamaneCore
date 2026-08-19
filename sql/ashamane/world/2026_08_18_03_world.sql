-- Coldridge Valley: the Wayward Fire Elemental gets its patrol route after all.
--
-- Held back from 2026_08_18_00_world.sql because two sniffed spawns both claimed
-- guid 167308 and the emitter would not guess between them. They are the same
-- elemental: a creature that dies comes back with a fresh guid counter, so one
-- NPC killed twice reads as three spawns keyed on (entry, counter).
--
-- The three instances never coexist, which two separate NPCs would have to:
--
--   311438   17:44:41 -> 17:51:33   centre (-6497.2, 331.3)
--   316420   17:52:05 -> 17:52:24   centre (-6490.8, 314.2)
--   316482   17:53:09 -> 17:57:40   centre (-6496.9, 331.5)
--
-- 311438 and 316482 sit 0.3 yd apart and share 13 bit-identical waypoint
-- coordinates, which is the same stored route replayed by the same spawn --
-- random wander never repeats a coordinate exactly. The 95 s between them is
-- the respawn timer.
--
-- Folding them back together turns three partial observations into one route
-- and upgrades its derivation from a spanning-tree guess to a lap the elemental
-- was watched walking end to end, gap-free: 12 nodes walked as 22 stops, out and
-- back along the lava, matched to 167308 at 0.004 yd. Four nodes seen only in
-- fragments are dropped rather than guessed into the order.
--
-- The DB has one spawn of 37112 and retail has one elemental. Nothing to add.


-- Wayward Fire Elemental (entry 37112) -- sniffed spawn 311438
--   matched guid 167308 at 0.004 yd from a route node (the only spawn of this entry in the box)
--   22 waypoints, out-and-back over 12 nodes (22 stops per lap), via gap-free lap, walk (2.36 yd/s), 0 node(s) with a delay, 4 unlinked node(s) dropped
--   was MovementType 0, wander_distance 0, no creature_addon path
SET @NPC := 167308;  SET @PATH := @NPC * 10;
UPDATE `creature` SET `wander_distance`=0, `MovementType`=2 WHERE `guid`=@NPC;
DELETE FROM `creature_addon` WHERE `guid`=@NPC;
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(@NPC,@PATH,0,0,0,0,1,0,0,0,0,0,0,NULL);
DELETE FROM `waypoint_data` WHERE `id`=@PATH;
INSERT INTO `waypoint_data` (`id`,`point`,`position_x`,`position_y`,`position_z`,`orientation`,`delay`,`move_type`,`action`,`action_chance`,`wpguid`) VALUES
(@PATH,1,-6492.823,339.056,368.494,0,0,0,0,100,0),
(@PATH,2,-6484.156,338.507,369.161,0,0,0,0,100,0),
(@PATH,3,-6485.476,331.351,369.273,0,0,0,0,100,0),
(@PATH,4,-6490.104,327.458,369.177,0,0,0,0,100,0),
(@PATH,5,-6492.639,323.155,369.032,0,0,0,0,100,0),
(@PATH,6,-6501.009,322.615,368.539,0,0,0,0,100,0),
(@PATH,7,-6504.955,326.509,367.973,0,0,0,0,100,0),
(@PATH,8,-6505.262,331.286,368.026,0,0,0,0,100,0),
(@PATH,9,-6506.288,335.095,368.531,0,0,0,0,100,0),
(@PATH,10,-6503.399,337.201,368.452,0,0,0,0,100,0),
(@PATH,11,-6498.719,336.800,368.202,0,0,0,0,100,0),
(@PATH,12,-6499.469,336.865,367.974,0,0,0,0,100,0),
(@PATH,13,-6484.156,338.507,369.161,0,0,0,0,100,0),
(@PATH,14,-6485.476,331.351,369.273,0,0,0,0,100,0),
(@PATH,15,-6490.104,327.458,369.177,0,0,0,0,100,0),
(@PATH,16,-6492.639,323.155,369.032,0,0,0,0,100,0),
(@PATH,17,-6501.009,322.615,368.539,0,0,0,0,100,0),
(@PATH,18,-6504.955,326.509,367.973,0,0,0,0,100,0),
(@PATH,19,-6505.262,331.286,368.026,0,0,0,0,100,0),
(@PATH,20,-6506.288,335.095,368.531,0,0,0,0,100,0),
(@PATH,21,-6503.399,337.201,368.452,0,0,0,0,100,0),
(@PATH,22,-6498.719,336.800,368.202,0,0,0,0,100,0);

-- Coldridge Mountaineer (entry 853) -- sniffed spawn 75787448
--   matched guid 167026 at 6.210 yd from a route node (next candidate 20.8 yd)
--   3 waypoints, circuit of 3 nodes, via lap spanning a gap, walk (2.49 yd/s), 1 node(s) with a delay, 6 unlinked node(s) dropped
--   was MovementType 2, wander_distance 0, path 1670260 with 11 waypoints
-- 1 path, 22 waypoint rows
-- @touched: creature,creature_addon,waypoint_data 167308
