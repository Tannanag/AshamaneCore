-- New Tinkertown: Tock Sprysprocket's restoration demonstration (quest 26264)
--
-- The apparatus, the helm and the gnome have no spawns. All three are summoned and
-- every beat is driven from npc_tock_sprysprocket, so only the lines, the poses and
-- the script binding are here.
--
-- `Emote` carries the gesture that plays with each line. The three gestures that
-- stand on their own, with no line attached, are in the script.

DELETE FROM `creature_text` WHERE `CreatureID` IN (42611, 43033);
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(42611,0,0,'My brother has spent years working on a cure for leper gnomes. Using his notes, I think I\'ve perfected a process for restoring gnomes who\'ve devolved to sludge.',12,0,100,1,0,0,42915,0,'Tock Sprysprocket'),
(42611,1,0,'Let\'s give this a try. Goggles, everyone!',12,0,100,1,0,0,42918,0,'Tock Sprysprocket'),
(42611,2,0,'Absolutely amazing! We\'ve done it!',12,0,100,5,0,0,42922,0,'Tock Sprysprocket'),
(42611,3,0,'Sure, he\'s a little small, even by gnome standards, but he\'s all there! The real question is, what will he remember?',12,0,100,1,0,0,42923,0,'Tock Sprysprocket'),
(42611,4,0,'Wait, come back! I have readings to take!',12,0,100,25,0,0,42925,0,'Tock Sprysprocket'),
(42611,5,0,'You need to see a medic!',12,0,100,5,0,0,42926,0,'Tock Sprysprocket'),
(42611,6,0,'Better make that a rocket scientist.',12,0,100,5,0,0,43022,0,'Tock Sprysprocket'),
(43033,0,0,'What... what happened to me?',12,0,100,6,0,0,42921,0,'Recovered Gnome'),
(43033,1,0,'Don\'t talk about me like I\'m not here! All I know is I\'m hungry and I need to get out of these hideous, smelly clothes!',12,0,100,5,0,0,42924,0,'Recovered Gnome');

-- Neither the gnome nor the apparatus takes part in a fight, and the apparatus cannot
-- be clicked at all.
UPDATE `creature_template` SET `unit_flags` = 768 WHERE `entry` = 43033;
UPDATE `creature_template` SET `unit_flags` = 33587968 WHERE `entry` = 43035;

-- The gnome comes out of the machine slumped and gets to his feet a few seconds later.
-- The stand state is on the addon rather than set after the summon: LoadCreaturesAddon
-- runs inside Creature::UpdateEntry, before the creature reaches the map, so he is
-- already sitting in the first block a client is sent about him. Setting it afterwards
-- would show him standing first and then sitting down.
DELETE FROM `creature_template_addon` WHERE `entry` = 43033;
INSERT INTO `creature_template_addon`
    (`entry`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(43033, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, '');

UPDATE `creature_template` SET `ScriptName` = 'npc_tock_sprysprocket' WHERE `entry` = 42611;
