-- New Tinkertown: the wrecked battle suits stop being targetable.
--
-- The nine 43261 spawns lying in front of the recruit camp are wreckage, but they
-- carried only IMMUNE_TO_PC | IMMUNE_TO_NPC. That stops a player attacking one and
-- does nothing else: each still takes a nameplate, a target ring and a mouseover.
--
-- `unit_flags` gains UNIT_FLAG_NOT_SELECTABLE (0x02000000) and 0x20000000, and
-- `unit_flags2` gains UNIT_FLAG2_FEIGN_DEATH so the suit lies as a wreck instead of
-- standing to attention. 46345 Destroyed Battle Suit already carries the same set.
--
-- 42224 Repaired Mechano-Tank was missing IMMUNE_TO_PC, so the friendly tanks
-- parked around the camp could be attacked.

UPDATE `creature_template` SET `unit_flags`=570426112, `unit_flags2`=2049, `unit_flags3`=8192 WHERE `entry`=43261;

UPDATE `creature_template` SET `unit_flags`=768, `unit_flags3`=16 WHERE `entry`=42224;
