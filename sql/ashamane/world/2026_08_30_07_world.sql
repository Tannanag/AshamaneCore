-- New Tinkertown: drop the temporary Crazed Leper Gnome (46363) markers.
--
-- Removes the per-guid rows added for identification, putting the four back on
-- the creature_template_addon row. Needs a worldserver restart.
DELETE FROM `creature_addon` WHERE `guid` IN (984605,984607,984608,984641);
