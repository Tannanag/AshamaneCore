-- Coldridge Valley: let three Coldridge Citizens (37218) wander in place.
--
-- guid 167014 (-6092.18, 375.63), 167015 (-6092.90, 392.90) and 167016
-- (-6087.71, 384.76) stand on the upper shelf of the village at the valley
-- entrance with `MovementType` = 0 and `wander_distance` = 0, so they never
-- move at all. Give them random movement over a deliberately narrow radius so
-- they shuffle around their spot instead of standing at attention.
--
-- 3 yards is about as wide as this group can take. The three sit 9.6 to 17.3
-- yards apart from each other, and 167016 is only 8.4 yards from citizen 167013,
-- which is staying put on the lower shelf (z 393.6 against their 395.5) -- a
-- wider radius would walk them into their neighbours and over the lip.
--
-- Safe to do: entry 37218 has no ScriptName, no AIName, no SAI rows, no waypoint
-- path, no formation, and starts/ends no quests. Its only npcflag is gossip (1),
-- which movement does not affect.
--
-- The other nine spawns of 37218 are intentionally left idle.

UPDATE `creature` SET `MovementType` = 1, `wander_distance` = 3
    WHERE `id` = 37218 AND `guid` IN (167014, 167015, 167016);
