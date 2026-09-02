-- New Tinkertown: the two S.A.F.E. Operatives in the north-west corner sit down.
--
-- 168075 and 168133 had no `creature_addon` row, so both fell back to the template's
-- emote 214 EMOTE_STATE_READY_RIFLE and stood at attention. Their pose is a stand
-- state rather than an emote state: they sit, and carry no emote at all. A guid row
-- replaces the template row outright rather than merging with it, so emote 0 here is
-- what clears the inherited 214.
--
-- 168120 keeps its emote 69 and only changes sheath. It is written out in full so the
-- three Operatives that hold a post in this room read from one place.
--
-- 1 is UNIT_STAND_STATE_SIT; 69 is EMOTE_STATE_USE_STANDING; SheathState 1 is melee.

DELETE FROM `creature_addon` WHERE `guid` IN (168075,168120,168133);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(168075,0,0,1,0,0,1,0,0,0,0,0,0,NULL),
(168133,0,0,1,0,0,1,0,0,0,0,0,0,NULL),

(168120,0,0,0,0,0,1,0,69,0,0,0,0,NULL);
