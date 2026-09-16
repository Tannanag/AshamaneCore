-- New Tinkertown, the trogg tunnel: Rockjaw Marauder roam radius
-- Fifteen Marauders roam at 3 yd; they cover about 13 yd. Spawns that walk a
-- route (2026_09_15_02) are not touched, nor are the five at the tunnel mouth
-- that were not seen roaming.
UPDATE `creature` SET `MovementType`=1, `wander_distance`=13 WHERE `id`=42222 AND `guid` IN (
    167722, 167724, 167883, 168106, 168107, 168424, 168449, 168519,
    168531, 168594, 168606, 168612, 168623, 168976, 169157);

-- @touched: creature 167722,167724,167883,168106,168107,168424,168449,168519,168531,168594,168606,168612,168623,168976,169157
