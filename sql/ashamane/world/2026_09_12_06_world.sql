-- New Tinkertown: the Crushcog Sentry-Bots (42291) that do not patrol roam
-- a 13-yard radius. The core picks each hop within wander_distance of the
-- home position, so 13 is the radius kept, not a diameter. Twelve spawns go
-- from 3 to 13; 168625 stood still and roams too. 168868 stays idle: it
-- stands 2 yd from a node of 169215's route and looks like a duplicate spawn.

UPDATE `creature` SET `MovementType`=1, `wander_distance`=13 WHERE `id`=42291 AND `guid` IN (168625);

UPDATE `creature` SET `wander_distance`=13 WHERE `id`=42291 AND `guid` IN (
    167557, 167558, 167751, 168299, 168419, 168429, 168736, 168783, 168828, 168964,
    168984, 169188);

-- @touched: creature 167557,167558,167751,168299,168419,168429,168625,168736,168783,168828,168964,168984,169188
