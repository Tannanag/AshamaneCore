-- New Tinkertown: remove the orphaned ammo cart on the drill ground.
--
-- The cart and cart bunny whose recruit, 168903, is already gone. The recruit
-- standing two yards away is 985010, which keeps its own position.

DELETE FROM `creature_addon` WHERE `guid` IN (168904,168905);

DELETE FROM `creature` WHERE `guid` IN (168904,168905);
