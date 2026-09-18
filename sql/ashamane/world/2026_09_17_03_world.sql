-- Teldrassil: Githyiss the Vile (1994, guid 278631) spawns where the 14 Sep sniff
-- has him. Every fresh respawn in dump_12.1.0.69814_2026-09-14_23-03-16 (three of
-- them, 23:31:00 / 23:31:44 / 23:32:31) appears at 10940.778 923.153 1340.672,
-- 5.6 yd from the Gnarlpine Corruption Totem; the server row sat 7 yd west of that.
-- Two of the three come up facing 1.0472. Idle he wanders a leg every ~10 s and never
-- gets more than 4.3 yd from the spot (x 10937.9-10943.6, y 918.6-925.0), so the
-- random movement stays with a 4 yd radius. Each respawn came 31 s after the death,
-- not the row's 300.
-- @touched: creature 278631
UPDATE `creature` SET `position_x`=10940.778, `position_y`=923.1528, `position_z`=1340.6724, `orientation`=1.0472, `spawntimesecs`=30, `wander_distance`=4, `MovementType`=1 WHERE `guid`=278631 AND `id`=1994;
