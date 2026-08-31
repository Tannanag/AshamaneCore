-- New Tinkertown: drop one Crazed Leper Gnome (46363) spawn.
--
-- This runs after the file that inserts the block, so the removal survives a
-- re-run of both. Needs a worldserver restart.
DELETE FROM `creature_addon` WHERE `guid`=984626;
DELETE FROM `creature` WHERE `guid`=984626;
