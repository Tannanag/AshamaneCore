-- New Tinkertown, "Finishin' the Job" (26318): the tunnel caves in.
--
-- The Collapsing Boulders (204047) are not a fixture. They come down at the
-- tunnel mouth as the kegs go and are gone fifteen seconds later; the Detonator
-- script summons them. The permanent spawn showed the cave-in around the clock.
DELETE FROM `gameobject_addon` WHERE `guid`=182990;
DELETE FROM `gameobject` WHERE `guid`=182990 AND `id`=204047;
