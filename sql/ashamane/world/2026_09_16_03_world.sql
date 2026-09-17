-- Teldrassil: Moriana Dawnlight (34756) and Doranel Amberleaf (34757) hold their
-- marks at the top of Aldrassil and play their conversation off areatrigger 5481.
--
-- Spawns 276791 / 276790 already stand on the sniffed positions and orientations
-- to the bit (10456.585, 831.691 o 2.0246 / 10455.996, 832.972 o 5.0615) but were
-- MovementType 1 / wander_distance 3, so both walked off them. The 14 Sep sniff
-- never shows either move except to turn. MovementType 0.
--
-- The conversation was an OOC line-of-sight bark on Amberleaf (25 yd, 25 s
-- cooldown) with the second line and two SET_ORIENTATION rows in a timed list:
-- Dawnlight never turned and Amberleaf turned to a fixed angle. Retail fires it on
-- entering areatrigger 5481 (r 3.95 at 10452.4, 843.4, 1380.3, the spot between
-- them), locks it out for 30 s with 88811 "CSA Area Trigger Dummy Timer Aura" on
-- Dawnlight, and has both turn to the player and then back to their spawn
-- orientation. That is npc_moriana_dawnlight + at_aldrassil_dawnlight_amberleaf in
-- zone_teldrassil.cpp (see the comment there for why not SmartAI); the SmartAI on
-- Amberleaf goes so the bark does not fire twice. Both creature_text rows stay.
--
-- Needs the rebuilt worldserver and a restart (or a respawn of the two after
-- `.reload creature_template` -- the areatrigger_scripts table is loaded once).

UPDATE `creature` SET `MovementType`=0, `wander_distance`=0 WHERE `guid` IN (276790, 276791);

UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_moriana_dawnlight' WHERE `entry`=34756;
UPDATE `creature_template` SET `AIName`='', `ScriptName`='' WHERE `entry`=34757;
DELETE FROM `smart_scripts` WHERE (`entryorguid`=34757 AND `source_type`=0) OR (`entryorguid`=3475700 AND `source_type`=9);

DELETE FROM `areatrigger_scripts` WHERE `entry`=5481;
INSERT INTO `areatrigger_scripts` (`entry`, `ScriptName`) VALUES (5481, 'at_aldrassil_dawnlight_amberleaf');

-- @touched: creature,creature_template 276790,276791
