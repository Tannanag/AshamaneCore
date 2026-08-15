-- Coldridge Valley: restore the static Rockjaw Invader (37070) spawns.
--
-- 2026_08_14_01_world.sql followed upstream TrinityCore in deleting every static
-- spawn of 37070, leaving only the ones Joren Ironstock summons. That is wrong for
-- this server: quest 24469 "Hold the Line!" requires 6 Rockjaw Invader kills, and
-- summoned invaders arrive one at a time and despawn after 18 seconds.
--
-- These are the 13 stock TDB spawns (guid 167268-167372) as they stood after the
-- duplicate hand-placed rows were dropped in 2026_08_14_00_world.sql -- not the
-- inflated set of 27. Joren's summons now play out on top of these.

DELETE FROM `creature` WHERE `id` = 37070;
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(167268, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6296.17, 326.164, 376.828, 0.0802196, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167269, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6266.06, 310.896, 382.809, -1.45674, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167271, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6290.69, 348.408, 377.022, -2.47413, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167273, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6294.01, 314.756, 376.628, -2.07352, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167276, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6280.72, 370.715, 381.87, 0.432933, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167278, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6278.89, 393.446, 381.37, 2.03069, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167282, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6258.61, 404.793, 383.891, 1.86152, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167297, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6235.97, 404.548, 388.52, 4.83771, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167352, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6259.55, 393.766, 383.098, 5.70256, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167366, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6204.6, 304.649, 388.96, 2.29419, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167369, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6269.25, 305.163, 382.544, 0.572368, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167371, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6209.6, 310.083, 388.104, 2.28721, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167372, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6237.68, 375.519, 385.447, 4.96282, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0);
