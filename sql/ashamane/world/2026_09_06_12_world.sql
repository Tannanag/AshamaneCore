-- New Tinkertown, the ruined ground west: two Living Contamination start roaming
-- Both stood still on a radius of 0. They take the same 11 yd radius as the rest
-- of entry 42185.

UPDATE `creature` SET `MovementType`=1, `wander_distance`=11 WHERE `id`=42185 AND `guid` IN (
    168420, 168542);

-- @touched: creature 168420,168542
