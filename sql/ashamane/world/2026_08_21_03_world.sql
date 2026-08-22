-- Coldridge Valley: port the Joren Ironstock invasion vignette, and rebuild the
-- static Rockjaw Invader spawns underneath it.
-- Reference: TrinityCore sql/old/10.x/world/23111_2024_02_08/2024_01_01_01_world.sql
--
-- Upstream deletes every static 37070 spawn and leaves only Joren's summons. That is
-- wrong here: quest 24469 needs 6 invader kills, and summons arrive one at a time and
-- despawn after 18 seconds. These are the 13 stock TDB spawns less the 2 that stood
-- behind Joren rather than up the pass; his summons play out on top of them.
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
(167369, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6269.25, 305.163, 382.544, 0.572368, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0),
(167372, 37070, 0, 6176, 132, '0', 0, 0, 0, -1, 730, 0, -6237.68, 375.519, 385.447, 4.96282, 300, 4, 0, 42, 0, 1, 0, 0, 0, 0, 0, '', 0);

-- 2018_05_01_04_start_area_fix.sql left UNIT_FLAG_IMMUNE_TO_NPC (0x200) on him, which
-- makes AttackStart reject his own summons and the vignette never run.
UPDATE `creature_template` SET `unit_flags` = 32768 WHERE `entry` = 37081;

-- Sparring is what keeps him standing through it; 37070 and 37177 already have rows.
DELETE FROM `creature_sparring_template` WHERE `CreatureID` = 37081;
INSERT INTO `creature_sparring_template` (`CreatureID`, `HealthLimitPct`) VALUES
(37081, 85);

-- CREATURE_FLAG_EXTRA_CIVILIAN, so Mountaineers do not wander in and break the loop.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 2 WHERE `entry` = 853;

UPDATE `creature_template` SET `ScriptName` = 'npc_joren_ironstock' WHERE `entry` = 37081;
