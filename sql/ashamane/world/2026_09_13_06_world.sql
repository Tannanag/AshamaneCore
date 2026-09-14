-- New Tinkertown, "Finishin' the Job" (26318): the Powder Kegs (204041) cannot be
-- clicked. Only the Detonator sets them off; a player who used one directly made it
-- vanish for twenty seconds on its own. NOT_SELECTABLE takes the cursor away and is
-- put back on every respawn; the trigger's spell goes through Use regardless.
DELETE FROM `gameobject_template_addon` WHERE `entry`=204041;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `WorldEffectID`) VALUES
(204041, 0, 16, 0, 0, 0);
