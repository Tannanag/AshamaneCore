-- New Tinkertown, the ruined ground west: roaming radii for the sludges and slimes
-- Both entries roamed within 3 yd, which is far tighter than they keep to. These are
-- every roaming spawn of the two entries -- the patrollers in _10 are excluded, and
-- the spawns _14 removes are not listed.

-- Toxic Sludge: 3 -> 6 yd.
UPDATE `creature` SET `wander_distance`=6 WHERE `id`=42184 AND `guid` IN (
    167531, 167532, 167726, 167728, 168018, 168341, 168423, 168425, 168426, 168435,
    168436, 168441, 168442, 168444, 168539, 168890, 168954, 168995, 169113, 169130,
    169148, 169149, 169150, 169155);

-- Living Contamination: 3 -> 11 yd.
UPDATE `creature` SET `wander_distance`=11 WHERE `id`=42185 AND `guid` IN (
    167530, 167725, 167727, 167884, 167886, 168019, 168325, 168437, 168535, 168544,
    169173, 169179, 169214);

-- @touched: creature 167530,167531,167532,167725,167726,167727,167728,167884,167886,168018,168019,168325,168341,168423,168425,168426,168435,168436,168437,168441,168442,168444,168535,168539,168544,168890,168954,168995,169113,169130,169148,169149,169150,169155,169173,169179,169214
