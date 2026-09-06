-- New Tinkertown: the S.A.F.E. line reports to Nevin Twistwrench.
--
-- Nevin takes `npc_nevin_twistwrench`, which runs the arrivals beside him: about every
-- 77 seconds a S.A.F.E. Operative, Technician or Officer appears at his side, steps up,
-- salutes, walks out of the camp to the north and goes off at the far end. The one that
-- arrives is summoned by the script, so it has no spawn row here.
--
-- Scoped to guid 167450. 42396 is Nevin everywhere and only this spawn is the scene.
--
-- The two Operatives beside him sit; they had no `creature_addon` row and so inherited
-- 45847's template row, which stands them up with emote 214 EMOTE_STATE_READY_RIFLE.
--
-- Needs a worldserver restart: `creature_addon` is not reloadable, and the script has to
-- be compiled and installed to `ashamaneServer/bin/scripts`.

UPDATE `creature` SET `ScriptName`='npc_nevin_twistwrench' WHERE `guid`=167450;

-- The DELETE is what lets the updater re-run this file.
DELETE FROM `creature_addon` WHERE `guid` IN (167478,167857);

INSERT INTO `creature_addon`
(`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(167478,0,0,1,0,0,1,0,0,0,0,0,0,''),
(167857,0,0,1,0,0,1,0,0,0,0,0,0,'');
