-- Teldrassil: the Shade of the Kaldorei (34574) at the Shadowglen moonwell is one
-- Shade per player, seen by that player alone, on the sniffed timeline.
--
-- dump_12.1.0.69814_2026-09-14_23-03-16: entering areatrigger 5466 (r 11.96 at the
-- moonwell) has the Moonwell Bunny 34575 cast 65657 "Forcecast Summon Shade of the
-- Kaldorei" at the player, who casts 65656 himself; the Shade is created with
-- CreatedBy = the player and SummonProperties 492 -- flags 16, PERSONAL_SPAWN, the
-- row of Salanar the Horseman, the Bridenbrad naaru, Zuni, Swiftclaw and
-- Mekkatorque's Sanctum image. The scene itself (npc_shade_of_the_kaldorei,
-- at_shadowglen_moonwell in zone_teldrassil.cpp) is 43 s of lines, three walks and
-- two facings, then the player gets SMSG_COOLDOWN_EVENT 65656: the 2 min cooldown
-- of the summon spell starts at the fade, which is the per-player lockout.
--
-- Until now the bunny cast 65656 itself on OOC line of sight with a 119 s cooldown
-- of its own, so the Shade belonged to the bunny (visible to everyone, no personal
-- spawn) and the next player within two minutes got nothing. The SmartAI scene ran
-- 0 / 1 / 5 s where the sniff has 0.1 / 2.5 / 11.4 / 20.2 / 26.8 / 36.8 / 40.9, had
-- no facings and no OneShotExclamation, and its waypoint nodes were the sniffed
-- points within a yard; they move into the script.
--
-- creature_text: only the third line (emote 5, OneShotExclamation) and the fifth
-- (emote 1, OneShotTalk) come with an SMSG_EMOTE; the others had emote 1 here.
-- spell_target_position 65656: the create block has the Shade at o 2.4435 (the
-- spell's own PositionFacing 2.698 is what the core used with the NULL).
-- creature 276888: the bunny wandered 3 yd around the well; it is a trigger.
-- creature_template 34574: unit_flags IMMUNE_TO_PC|IMMUNE_TO_NPC as in the sniff
-- (Flags 33544 = those two + PVP_ATTACKABLE from the player ownership + 0x8000).
--
-- Needs a restart (new script, areatrigger_scripts and spell_target_position load
-- at startup).

UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_shade_of_the_kaldorei', `unit_flags`=768 WHERE `entry`=34574;

DELETE FROM `smart_scripts` WHERE `entryorguid`=34574 AND `source_type`=0;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (3457400, 3457401, 3457402) AND `source_type`=9;
DELETE FROM `waypoints` WHERE `entry`=34574;

-- The bunny keeps its "set invisible on reset" row (id 0); the cast row goes.
DELETE FROM `smart_scripts` WHERE `entryorguid`=34575 AND `source_type`=0 AND `id`=1;

UPDATE `creature` SET `MovementType`=0, `wander_distance`=0 WHERE `guid`=276888 AND `id`=34575;

UPDATE `creature_text` SET `Emote`=0 WHERE `CreatureID`=34574 AND `GroupID` IN (1, 2, 4);
UPDATE `creature_text` SET `Emote`=5 WHERE `CreatureID`=34574 AND `GroupID`=3;
UPDATE `creature_text` SET `Emote`=1 WHERE `CreatureID`=34574 AND `GroupID`=5;

UPDATE `spell_target_position` SET `Orientation`=2.4435 WHERE `ID`=65656 AND `EffectIndex`=0;

DELETE FROM `areatrigger_scripts` WHERE `entry`=5466;
INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`) VALUES (5466, 'at_shadowglen_moonwell');
