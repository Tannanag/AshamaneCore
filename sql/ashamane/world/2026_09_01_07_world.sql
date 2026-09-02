-- New Tinkertown: the four Clean Cannon X-2 crew themselves.
--
-- Each cannon has a S.A.F.E. Operative entered at its guid + 1, standing about half a
-- yard away on the ground. In the dump none of the four stands: all four ride their
-- cannon in its single seat, and there is no other 45847 near a cannon. So the ground
-- spawns are stand-ins for a gunner that belongs in the seat.
--
-- `npc_clean_cannon_x2` seats the neighbouring spawn on the cannon. It is scoped to the
-- four guids rather than to 46208, which today has exactly these four spawns and so
-- would come to the same thing -- but only today.
--
-- The gunners had no `creature_addon` row and fell back to the template's emote 214
-- EMOTE_STATE_READY_RIFLE with SheathState 2. Seated, they carry no emote state at all
-- and sheath melee. A guid row replaces the template row outright rather than merging
-- with it, so emote 0 here is what clears the inherited 214.
--
-- SheathState 1 is melee. Needs a worldserver restart: `creature_addon` has no reload.

UPDATE `creature` SET `ScriptName`='npc_clean_cannon_x2' WHERE `guid` IN (167786,167789,167792,167922);

DELETE FROM `creature_addon` WHERE `guid` IN (167787,167790,167793,167923);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(167787,0,0,0,0,0,1,0,0,0,0,0,0,NULL),
(167790,0,0,0,0,0,1,0,0,0,0,0,0,NULL),
(167793,0,0,0,0,0,1,0,0,0,0,0,0,NULL),
(167923,0,0,0,0,0,1,0,0,0,0,0,0,NULL);
