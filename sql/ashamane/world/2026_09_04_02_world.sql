-- New Tinkertown: Gnomeregan Recruits haul ammo carts out of town.
--
-- Three posts, one recruit each. `npc_gnomeregan_recruit_column` picks a route by
-- matching the spawn against the three column starts it holds, so these positions are
-- what decides which way each one walks -- moving a spawn more than five yards off its
-- mark leaves it standing.
--
-- The cart and the bunny that rides it are summoned and seated by the script for the
-- length of a run, so no cart or bunny spawn belongs at these three posts.
--
-- `modelid` 0 rather than one of 31654-31657: every other 43276 spawn pins one model, but
-- each run here is made by a fresh recruit, so the four are left to
-- CreatureTemplate::GetRandomValidModelId and the column is not four copies of one gnome.
--
-- Needs a worldserver restart: `creature` rows are not reachable by `.reload`.

DELETE FROM `creature` WHERE `guid` BETWEEN 985010 AND 985012;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(985010,43276,0,6457,133,'0',0,0,0,-1,0,0,-5128.63,441.328,396.082,4.9749,300,0,0,2550,0,0,0,0,0,0,0,'npc_gnomeregan_recruit_column',0),
(985011,43276,0,6457,133,'0',0,0,0,-1,0,0,-5140.95,454.278,393.619,5.3469,300,0,0,2550,0,0,0,0,0,0,0,'npc_gnomeregan_recruit_column',0),
(985012,43276,0,6457,133,'0',0,0,0,-1,0,0,-5184.94,467.078,388.518,4.3842,300,0,0,2550,0,0,0,0,0,0,0,'npc_gnomeregan_recruit_column',0);
