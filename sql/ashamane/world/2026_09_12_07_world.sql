-- New Tinkertown: Crushcog Sentry-Bot (42291) runs at 8 yd/s (8/7 of base),
-- not 5. speed_walk 1 is already right. All 20 spawns of the entry are in
-- this camp.

UPDATE `creature_template` SET `speed_run`=1.142857 WHERE `entry`=42291;

-- @touched: creature_template 42291
