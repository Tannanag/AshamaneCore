-- Coldridge Valley: stand the six Frostmane Novices around the fire elemental
-- still, and turn them to face it.
--
-- These six ring the lava pool the Wayward Fire Elemental patrols
-- (path 1673080, applied in 2026_08_18_03_world.sql). They hold an attack pose
-- without a target, which is the intended scene, but they were roaming at
-- wander_distance 3 -- so a menacing ring drifts out of formation and ends up
-- facing outward. The pose is correct; the wander is not.
--
-- Their wander is not from this branch's work: entry 946 has no UPDATE in
-- 2026_08_18_01_world.sql, all fourteen of its spawns were already
-- MovementType 1 / wander_distance 3, and only these six are changed here.
--
-- The ring is a real cluster, not a radius picked to taste. Distances to the
-- centre of the elemental's route run 12.5 to 18.6 yd and the next Novice out is
-- 30.2 yd, and the six sit at 0, 58, 114, 153, 246 and 299 degrees around it --
-- evenly spread, which is what a ring is.
--
-- Facing is the centroid of the 12 distinct nodes of path 1673080,
-- (-6497.025, 332.158), rather than the average of its 22 waypoint rows, which
-- would pull toward the nodes the out-and-back walks twice.
--
-- That the stored facings were already meant to point inward is the check on
-- this: every one of the six is within 1 to 33 degrees of the centre already
-- (median 14), while the Novices further out sit 32 to 172 degrees off. This
-- corrects a facing that was roughly right and had been left to drift; it does
-- not invent one.
--
-- Left alone: 167173 at 30.2 yd and 167172 at 34.2 yd, the next two out. They
-- are not part of the ring by distance or by angle, and they keep their wander.

UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=5.124 WHERE `guid`=167085;  -- 12.5 yd out, turns 1 deg
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=3.149 WHERE `guid`=167170;  -- 15.8 yd out, turns 5 deg
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=4.150 WHERE `guid`=167136;  -- 16.1 yd out, turns 14 deg
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=2.070 WHERE `guid`=167159;  -- 16.6 yd out, turns 33 deg
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=1.156 WHERE `guid`=167239;  -- 17.5 yd out, turns 14 deg
UPDATE `creature` SET `MovementType`=0, `wander_distance`=0, `orientation`=5.817 WHERE `guid`=167237;  -- 18.6 yd out, turns 16 deg

-- 6 spawns
-- @touched: creature 167085,167136,167159,167170,167237,167239
