-- New Tinkertown: correct the position of S.A.F.E. Operative guid 168894.
--
-- It sits about 7 yd from where retail puts it, which is why it read as a spawn
-- with no counterpart rather than a match.
UPDATE `creature` SET `position_x`=-5203.571,`position_y`=506.904,`position_z`=388.607,`orientation`=3.957 WHERE `guid`=168894 AND `id`=45847;
