-- Coldridge Valley: port the Joren Ironstock invasion vignette from upstream TrinityCore.
--
-- Upstream replaced the static Rockjaw Invader (37070) spawns with a scripted vignette:
-- Joren Ironstock (37081) summons invaders one at a time from seven fixed points and guns
-- them down. The fight is self-limiting and cleans up after itself instead of leaving a
-- permanent pack parked at the valley entrance.
--
-- Reference: TrinityCore sql/old/10.x/world/23111_2024_02_08/2024_01_01_01_world.sql

-- Drop the remaining static invader spawns; npc_joren_ironstock summons them now.
DELETE FROM `creature` WHERE `id` = 37070;

-- Joren must be attackable by NPCs or AttackStart is rejected and the vignette never runs.
-- 2018_05_01_04_start_area_fix.sql left UNIT_FLAG_IMMUNE_TO_NPC (0x200) set on him.
UPDATE `creature_template` SET `unit_flags` = 32768 WHERE `entry` = 37081;

-- Sparring is what keeps him standing through it. 37070 and 37177 are already covered.
DELETE FROM `creature_sparring_template` WHERE `CreatureID` = 37081;
INSERT INTO `creature_sparring_template` (`CreatureID`, `HealthLimitPct`) VALUES
(37081, 85);

-- Keep Coldridge Mountaineers from wandering in and breaking the loop.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` | 2 WHERE `entry` = 853;

UPDATE `creature_template` SET `ScriptName` = 'npc_joren_ironstock' WHERE `entry` = 37081;
