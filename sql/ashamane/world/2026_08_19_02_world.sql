-- Coldridge Valley: lift the monk trainer out of the floor.
--
-- creature 210112024 was hand-placed -- x, y, z all whole numbers, orientation
-- 1, VerifiedBuild 0 -- and its z was guessed one notch low. The Anvilmar floor
-- around it is flat and well witnessed:
--
--   guid    NPC                    distance   z
--   ------  ---------------------  --------   -------
--   167010  Coldridge Citizen         3.31    395.543
--   166974  Coldridge Mountaineer    10.95    395.626
--   166984  Thorgas Grimson          13.52    395.623
--
-- Taking the nearest witness rather than the mean: 3.3 yd away is close enough
-- that any real slope in the floor is smaller than the difference between the
-- candidates.
UPDATE `creature` SET `position_z`=395.543 WHERE `guid`=210112024; -- Lo 63285, Monk Trainer

-- @touched: creature 210112024
