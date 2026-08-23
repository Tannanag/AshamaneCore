-- Northshire Valley: reduce the peasants to the three the sniff actually shows,
-- which means putting two of them back.
--
-- The zone has ten Northshire Peasant spawns on this server -- seven woodcutters
-- and, until 2026_08_22_02, three standing with lumber. The sniff shows three,
-- and knowing which three took reading each spawn's own position out of its
-- create packet rather than guessing by proximity.
--
--   sniffed spawn   position                      facing   nearest DB spawn
--   -------------   ---------------------------   ------   -----------------------
--          490087   (-8838.622, -225.329, 82.412)  0.5390   177908  at  2.46 yd
--         8878695   (-8891.614, -275.477, 80.005)  4.8592   177910  at  0.03 yd
--        17267303   (-8855.042, -253.269, 81.168)  5.9167     6366  at  1.38 yd
--
-- Each position was confirmed the same way the guards' facings were: it repeats
-- byte-identically across 8 to 11 packets at a stable offset from that spawn's
-- own guid, so it is that creature's position and not a neighbour's. 177910 lands
-- at 0.03 yd, which is an exact spawn-point identification.
--
-- The other seven are not merely unobserved, they are absent. "Not in the sniff"
-- normally proves nothing, because a creature only enters a capture when the
-- player comes near it. Here the player did come near -- closest approach per
-- spawn, from 6238 recorded player positions:
--
--     5881   1.4 yd   not seen        10954   6.7 yd   not seen
--     6366   1.6 yd   SEEN             6028   7.8 yd   not seen
--    43766   2.3 yd   not seen        10373   8.9 yd   not seen
--   177909   3.1 yd   not seen         6364  28.0 yd   not seen
--   177908  19.2 yd   SEEN           177910  29.5 yd   SEEN
--
-- The player stood 1.4 yd from 5881 and 2.3 yd from 43766 and neither existed.
-- That is absence, not a coverage gap. Note also that the two spawns seen from
-- furthest away, 19.2 and 29.5 yd, are two of the three that are real -- so
-- distance was never the limiting factor.
--
-- This reverses part of 2026_08_22_02, and the reversal is worth stating. That
-- file deleted 177908, 177909 and 177910 as lumber-carrying duplicates standing
-- redundantly beside woodcutters. The redundancy was real; the attribution was
-- backwards. Two of those three are spawns retail has, and six of the seven
-- woodcutters are not. With the phantom woodcutters gone the lumber-carriers are
-- not standing beside anything -- they are the scene. 177909 stays deleted: the
-- player passed 3.1 yd from it and it was not there.

-- 1. The six woodcutters retail does not have.
DELETE FROM `creature_addon` WHERE `guid` IN (5881,6028,6364,10373,10954,43766);
DELETE FROM `creature` WHERE `id`=11260 AND `guid` IN (5881,6028,6364,10373,10954,43766);

-- 2. The surviving woodcutter, moved onto its retail position and facing. It
--    keeps the Stormshield Peasant display and emote 234 from 2026_08_22_11.
UPDATE `creature` SET `position_x`=-8855.042, `position_y`=-253.269, `position_z`=81.168,
    `orientation`=5.9167 WHERE `id`=11260 AND `guid`=6366;

-- 3. The two lumber-carriers, restored at the coordinates and facings the sniff
--    gives rather than the ones they had before. Every other column is copied
--    from surviving spawn 6366, and modelid 89 is the value they carried
--    originally -- the peasant-holding-firewood display, which is what made them
--    read as lumber-carriers. No creature_addon rows: they had none before, so
--    they take no emote and stand idle, unlike the woodcutter.
DELETE FROM `creature` WHERE `guid` IN (177908,177910);
INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(177908,11260,0,6170,9,0,0,0,0,-1,89,0,-8838.622,-225.329,82.412,0.5390,300,0,0,42,0,0,0,0,0,0,0,'',0),
(177910,11260,0,6170,9,0,0,0,0,-1,89,0,-8891.614,-275.477,80.005,4.8592,300,0,0,42,0,0,0,0,0,0,0,'',0);

-- Afterwards Northshire has exactly three Northshire Peasants, standing where
-- retail stands them and facing where retail faces them: 6366 chopping, 177908
-- and 177910 holding lumber.
--
-- What the sniff could not settle, and this file does not pretend to: which
-- display or emote each of the three carries in retail. DisplayID and
-- UNIT_NPC_EMOTESTATE live in the UpdateFields block and WowPacketParser has no
-- layout for 12.1.0, so there is nothing to validate a decode against -- positions
-- and facings are recoverable from these packets, field values are not. The three
-- keep the displays and emotes this server already had for them.
--
-- No `-- @touched:` line: wpp_apply.py resolves the guids against `creature`, and
-- 177908 and 177910 do not exist there until this file runs. Apply with mysql
-- directly. The undo is 2026_08_22_02 plus restoring the six deleted rows, so
-- take a copy of the ten rows before running this if that matters.
