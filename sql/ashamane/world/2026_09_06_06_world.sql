-- New Tinkertown: Razlo Crushcog's image comes back after the scene.
--
-- The scene despawns him at the end. The despawn action's respawn field is not
-- read by the core, so he fell back on his spawn timer of 300 seconds and was
-- missing for the whole gap between runs. Eight seconds puts him back on his
-- mark, frozen, where he belongs.

UPDATE `creature` SET `spawntimesecs` = 8 WHERE `guid` = 168836;
