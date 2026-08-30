-- New Tinkertown: remove the stacked Injured Gnomes at the Operative's spawn.
--
-- 169255 and 169266 stand 0.08 yards apart at the top of the ramp, so the two models
-- clip through each other. 169286 now summons the gnome it carries down to the bed from
-- that same spot, which leaves nothing for the static pair to do.
--
-- Needs a worldserver restart.
DELETE FROM `creature_addon` WHERE `guid` IN (169255,169266);
DELETE FROM `creature` WHERE `guid` IN (169255,169266);
