-- Teldrassil: the 55 drifting Wisps (48623) of Shadowglen and Dolanaar hang in the
-- air and drift around a fixed anchor; on the server they were random walkers on the
-- ground.
--
-- Every 48623 create in the 14 Sep sniff carries MovementFlags 512 (DisableGravity),
-- PlayHoverAnim and AnimTier 3, and drifts in 1.8-yard legs at 2.5 yd/s within a few
-- yards of where it was first seen: across 5,079 moves the radius is 1.6 minimum,
-- 4.0 median, 7.1 maximum, and z never changes by more than 2 yards. That is random
-- wander in the air, not a path. All 55 sniffed wisps match a server spawn (median
-- 1.8 yd, worst 7.8 yd -- the create position is a random point in the disc, not its
-- centre).
--
-- Two things stood in the way. The template's InhabitType was 3 (ground and water):
-- UpdateMovementFlags never granted DisableGravity, UpdateAllowedPositionZ snapped
-- every random destination to the ground, and PathGenerator walked it there along the
-- navmesh. InhabitType 4 (air) flips all three -- the flags become 512 as sniffed,
-- z is kept, and the flying case in BuildPolyPath takes the straight line. 48624
-- already had 4. Then the radius: wander_distance 3 on 59 of the 66 spawns in the
-- box, 0 on the other 7, against a median observed drift of 4.0. Every one of the
-- 7 static spawns is a wisp the sniff saw drifting, so they wander too.
--
-- The wander leg speed is the walk speed (RandomMovementGenerator uses SetWalk),
-- 2.5 yd/s, which is what retail shows. Random movement for a CanFly creature
-- keeps its z, so the observed <= 2 yd z spread holds without a script.
--
-- 11 of the 66 spawns (x 9502-9568, y 702-782, the road west of Dolanaar) were
-- outside the sniff's coverage; they are the same creature in the same area and get
-- the same radius. The two old-model Wisps (3681) near Rut'theran do not appear in
-- the sniff and are left alone. The 47 spawns of 48623 elsewhere on the map are
-- untouched.
--
-- No creature_addon changes: the template addon already carries AnimTier 3 (hover)
-- and the 12 per-spawn rows copy it. Needs a worldserver restart for the template.

UPDATE `creature_template` SET `InhabitType`=4 WHERE `entry`=48623 AND `InhabitType`=3;

-- 66 spawns in the box, 7 of them (276994,277003,277048,277121,277140,277142,277252) previously MovementType 0.
UPDATE `creature` SET `wander_distance`=4, `MovementType`=1 WHERE `id`=48623 AND `guid` IN (
    276865,276870,276872,276994,276995,276996,277003,277047,277048,277049,
    277052,277055,277084,277085,277086,277087,277089,277093,277106,277111,
    277112,277113,277114,277115,277121,277124,277125,277128,277135,277136,
    277140,277142,277143,277144,277157,277160,277166,277179,277180,277187,
    277196,277197,277198,277204,277219,277221,277223,277226,277235,277236,
    277237,277240,277242,277252,277253,277254,277255,277256,277257,277260,
    277274,277275,277278,277279,277286,277287);

-- @touched: creature_template,creature 276865,276870,276872,276994,276995,276996,277003,277047,277048,277049,277052,277055,277084,277085,277086,277087,277089,277093,277106,277111,277112,277113,277114,277115,277121,277124,277125,277128,277135,277136,277140,277142,277143,277144,277157,277160,277166,277179,277180,277187,277196,277197,277198,277204,277219,277221,277223,277226,277235,277236,277237,277240,277242,277252,277253,277254,277255,277256,277257,277260,277274,277275,277278,277279,277286,277287
