-- New Tinkertown: the Dead Frostmane Trolls cannot be selected
-- 42220 lies dead across the zone (34 spawns) and could be targeted. It gets
-- the not-selectable and feign-death flags a corpse carries; the immune flags
-- it already had stay.
UPDATE `creature_template` SET `unit_flags`=570458880, `unit_flags2`=2049 WHERE `entry`=42220;
