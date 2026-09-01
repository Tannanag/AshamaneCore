-- New Tinkertown: the Rescued Survivors sit and kneel, and stop wandering.
--
-- Two of the fifteen spawns had no counterpart anywhere in the Loading Room and stood
-- in the middle of ground the rest of the group already covers, so they go.
--
-- The ten that stay hold one of two poses. Five already carried StandState 8, kneeling;
-- the other five had no `creature_addon` row at all and fell back to the template's 0,
-- standing, when they should be sitting. All ten are listed here rather than only the
-- five that change, so the whole set of poses reads from one place.
--
-- All ten were also on MovementType 1 with a 3 yard wander. Random movement never
-- clears a stand state, so the effect was a gnome drifting around its spawn point still
-- kneeling. None of them move, so the wander goes with the pose fix -- without it the
-- poses below are set and then dragged out of place.
--
-- 168936 is left alone. It is the one the Physician's Assistant leads to a bed, it does
-- move, and its standing pose at spawn is already what the template gives it.
--
-- 1 is UNIT_STAND_STATE_SIT and 8 is UNIT_STAND_STATE_KNEEL.

DELETE FROM `creature_addon` WHERE `guid` IN (168897,168909);
DELETE FROM `creature` WHERE `guid` IN (168897,168909);

UPDATE `creature` SET `MovementType`=0, `wander_distance`=0 WHERE `guid` IN
  (167580,167581,167582,167772,167773,167774,167776,167777,167916,167918);

DELETE FROM `creature_addon` WHERE `guid` IN
  (167580,167581,167582,167772,167773,167774,167776,167777,167916,167918);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(167580,0,0,1,0,0,1,0,0,0,0,0,0,NULL),
(167581,0,0,1,0,0,1,0,0,0,0,0,0,NULL),
(167582,0,0,1,0,0,1,0,0,0,0,0,0,NULL),
(167916,0,0,1,0,0,1,0,0,0,0,0,0,NULL),
(167918,0,0,1,0,0,1,0,0,0,0,0,0,NULL),

(167772,0,0,8,0,0,1,0,0,0,0,0,0,NULL),
(167773,0,0,8,0,0,1,0,0,0,0,0,0,NULL),
(167774,0,0,8,0,0,1,0,0,0,0,0,0,NULL),
(167776,0,0,8,0,0,1,0,0,0,0,0,0,NULL),
(167777,0,0,8,0,0,1,0,0,0,0,0,0,NULL);
