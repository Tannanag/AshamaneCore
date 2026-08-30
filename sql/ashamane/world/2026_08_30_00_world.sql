-- New Tinkertown: let Injured Gnomes be created already lying down.
--
-- LoadCreaturesAddon runs inside Creature::UpdateEntry, before the creature is added to
-- the map, so a StandState here is part of the first thing a client is told about the
-- creature. A script setting the same state after the summon is a visible transition
-- instead -- the gnome stands up in the bed and then lies down again.
--
-- creature_addon overrides creature_template_addon wholesale, so this reaches only the
-- spawns with no creature_addon row of their own. Of the eight 46447 spawns that is
-- 168987 alone, and the row below keeps it exactly as it is today.
--
-- Needs a worldserver restart.
UPDATE `creature_template_addon` SET `StandState`=3 WHERE `entry`=46447;

DELETE FROM `creature_addon` WHERE `guid`=168987;
INSERT INTO `creature_addon`
 (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`)
VALUES
 (168987,0,0,0,0,0,1,0,0,0,0,0,0,NULL);
