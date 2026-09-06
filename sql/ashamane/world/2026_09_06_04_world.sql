-- New Tinkertown: Mekkatorque's Mechanostrider stands still.
--
-- 167451 is the only spawn of 40057. It sat on random movement with a 3 yd
-- wander radius; it belongs parked beside Mekkatorque at its spawn point.

UPDATE `creature` SET `wander_distance` = 0, `MovementType` = 0 WHERE `guid` = 167451;
