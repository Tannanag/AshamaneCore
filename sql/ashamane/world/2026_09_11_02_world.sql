-- New Tinkertown, the trogg tunnel: sleeping troggs
-- Five Rockjaw Bonepickers and six Rockjaw Fungus-Flingers sleep at their
-- spawn points. The sleep was a stunned flag on both templates, which flagged
-- every spawn of both entries -- the eleven mining Bonepickers and the four
-- walking Fungus-Flingers included -- and a stunned caster fails every cast,
-- so Bone Toss, Fling Fungus and Poisonous Mushroom never went off. The
-- Fungus-Flinger aggro row already strips Trogg Sleep, but nothing applied it.
-- The flag comes off the templates; the sleepers carry Trogg Sleep (77831),
-- which stuns on its own and breaks on damage or aggro.

UPDATE `creature_template` SET `unit_flags`=0 WHERE `entry` IN (42221, 43325);

-- Sleeping Bonepickers.
DELETE FROM `creature_addon` WHERE `guid` IN (168014, 168351, 168582, 168584, 168588);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(168014,0,0,0,0,0,1,0,0,0,0,0,0,'77831'),
(168351,0,0,0,0,0,1,0,0,0,0,0,0,'77831'),
(168582,0,0,0,0,0,1,0,0,0,0,0,0,'77831'),
(168584,0,0,0,0,0,1,0,0,0,0,0,0,'77831'),
(168588,0,0,0,0,0,1,0,0,0,0,0,0,'77831');

-- Sleeping Fungus-Flingers keep their shield.
DELETE FROM `creature_addon` WHERE `guid` IN (168430, 168461, 168464, 168465, 168466, 168468);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(168430,0,0,0,0,0,1,0,0,0,0,0,0,'80928 77831'),
(168461,0,0,0,0,0,1,0,0,0,0,0,0,'80928 77831'),
(168464,0,0,0,0,0,1,0,0,0,0,0,0,'80928 77831'),
(168465,0,0,0,0,0,1,0,0,0,0,0,0,'80928 77831'),
(168466,0,0,0,0,0,1,0,0,0,0,0,0,'80928 77831'),
(168468,0,0,0,0,0,1,0,0,0,0,0,0,'80928 77831');

-- Bonepicker: wake before the aggro cast, or the cast fails as stunned.
DELETE FROM `smart_scripts` WHERE `entryorguid`=42221 AND `source_type`=0 AND `id` IN (0, 1);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(42221,0,0,0,4,0,100,1,0,0,0,0,0,'',28,77831,0,0,0,0,0,1,0,0,0,0,0,0,0,'Rockjaw Bonepicker - On Aggro - Remove Aura \'Trogg Sleep\''),
(42221,0,1,0,4,0,100,1,0,0,0,0,0,'',11,82625,0,0,0,0,0,2,0,0,0,0,0,0,0,'Rockjaw Bonepicker - On Aggro - Cast \'Bone Toss\'');

-- @touched: creature_template,creature_addon,smart_scripts 168014,168351,168582,168584,168588,168430,168461,168464,168465,168466,168468
