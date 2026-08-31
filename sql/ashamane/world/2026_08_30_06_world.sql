-- New Tinkertown: colour the four wide-roaming Crazed Leper Gnomes (46363).
--
-- TEMPORARY. These four carry the wander_distance values well above the rest
-- of the pack; the glow is only so they can be picked out in the field. Drop
-- this file once the radii are settled.
--
--   984605  75.9 yd  red      984607  54.6 yd  purple
--   984641  64.2 yd  blue     984608  27.5 yd  yellow
--
-- A creature_addon row replaces the creature_template_addon row outright, so
-- 46363's SheathState and its three auras are repeated here on purpose.
-- Needs a worldserver restart.
DELETE FROM `creature_addon` WHERE `guid` IN (984605,984607,984608,984641);

INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(984605,0,0,0,0,0,1,0,0,0,0,0,0,'95205 86400 86414 22518'),
(984641,0,0,0,0,0,1,0,0,0,0,0,0,'95205 86400 86414 22576'),
(984607,0,0,0,0,0,1,0,0,0,0,0,0,'95205 86400 86414 22581'),
(984608,0,0,0,0,0,1,0,0,0,0,0,0,'95205 86400 86414 22580');
