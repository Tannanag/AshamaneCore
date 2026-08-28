-- New Tinkertown: every S.A.F.E. Operative holds its gun.
--
-- SheathState 2 draws the ranged slot, which is where 52355 lives. At SheathState 1
-- the hand slots are drawn and both are empty, so the gun exists only for the shot --
-- and the client renders the cast correctly only when the weapon is already visible.
--
-- creature_addon overrides creature_template_addon wholesale rather than merging, so
-- the per-spawn rows need the same value. Only their sheath changes: two 45847 spawns
-- (168120, 168966) keep emote 69, and two 46449 spawns (168986, 169017) keep
-- StandState 8.
--
-- 47836 has no spawns. Needs a worldserver restart.
UPDATE `creature_template_addon` SET `SheathState`=2 WHERE `entry` IN (45847,46449);

UPDATE `creature_addon` `a` JOIN `creature` `c` ON `c`.`guid`=`a`.`guid`
SET `a`.`SheathState`=2 WHERE `c`.`id` IN (45847,46449);
