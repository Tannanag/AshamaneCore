-- Northshire Valley: set the other two peasants chopping as well.
--
-- 2026_08_22_13 cut the peasants to the three the sniff shows and restored 177908
-- and 177910 exactly as this server had held them before they were deleted --
-- displayid 89, the peasant-holding-firewood model, and no creature_addon row, so
-- they stood idle. Only 6366 chopped.
--
-- That was deliberately conservative: the sniff fixes where the three stand and
-- which way they face, but not what they are doing. DisplayID and
-- UNIT_NPC_EMOTESTATE live in the UpdateFields block, and WowPacketParser has no
-- layout for build 12.1.0, so unlike positions and facings there is nothing to
-- validate a decode of those fields against. Restoring what the server already
-- had was the option that invented least. All three chopping is a choice about
-- how the scene should look, not a correction the dump supports -- it is recorded
-- here as such.
--
-- Both changes are needed together, and the display is the part that is easy to
-- miss. displayid 89 resolves to ModelID 89, a model nothing in this database
-- pairs with a chopping emote. 59356 resolves to ModelID 49, which is the rig
-- 2026_08_22_11 moved the woodcutters onto precisely because it plays emote 234 --
-- these spawns did it before that pass, and Stormshield Peasant and Stormwind Dock
-- Worker do it on 21 live spawns today. Giving 177908 and 177910 the emote while
-- leaving them on displayid 89 would repeat the mistake 2026_08_22_11 fixed: the
-- emote set, the animation absent.
UPDATE `creature` SET `modelid`=59356 WHERE `id`=11260 AND `guid` IN (177908,177910);

-- The addon rows mirror 6366's exactly, which is the one peasant already chopping
-- correctly: emote 234 EMOTE_STATE_WORK_CHOPWOOD, SheathState 1, everything else
-- zero and no auras.
DELETE FROM `creature_addon` WHERE `guid` IN (177908,177910);
INSERT INTO `creature_addon` (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(177908,0,0,0,0,0,1,0,234,0,0,0,0,NULL),
(177910,0,0,0,0,0,1,0,234,0,0,0,0,NULL);

-- All three Northshire Peasants now stand on their sniffed positions and facings,
-- on the Stormshield Peasant display, chopping. Positions, facings and the count
-- come from the dump; the display and the emote do not.
--
-- Scope: `id`=11260 is pinned and both guids are listed. 6366 is untouched -- it
-- already carries this display and this emote. creature_template 11260 is not
-- modified.
--
-- No `-- @touched:` line: this writes `modelid`, which wpp_apply.py does not
-- snapshot. Apply with mysql directly. The undo is:
--
--   DELETE FROM `creature_addon` WHERE `guid` IN (177908,177910);
--   UPDATE `creature` SET `modelid`=89 WHERE `id`=11260 AND `guid` IN (177908,177910);
