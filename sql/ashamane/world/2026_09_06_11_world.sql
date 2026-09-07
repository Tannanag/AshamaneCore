-- New Tinkertown: the Living Contamination outside the tram entrance stand still
-- Entry 43089 does not roam. These spawns were on random movement with a 3 yd
-- radius; their recorded positions and facings are already right, so only the
-- movement type changes. The three spawns _14 adds are inserted idle already.

UPDATE `creature` SET `MovementType`=0, `wander_distance`=0 WHERE `id`=43089 AND `guid` IN (
    168373, 168374, 168418, 168835, 168863);

-- @touched: creature 168373,168374,168418,168835,168863
