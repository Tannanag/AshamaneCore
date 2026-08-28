-- New Tinkertown: drop the SpellVisualKit that puts a foreign gun on the caster.
--
-- Spell 85756 is the S.A.F.E. Operatives' own ranged attack. Its SpellVisual 18304
-- has three kits; 17335 and 17336 are the shot itself, and 17337 exists only to
-- attach SpellVisualEffectName 3113 -- model 165559, which no item in the game uses
-- -- to the caster. Fired every few seconds that model replaces the equipped 52355
-- and outlives the fight.
--
-- 0xF483EADB is SpellVisualKit's table hash. Deleted=1 makes DB2Manager::LoadHotfixData
-- erase the record and SMSG_AVAILABLE_HOTFIXES tell the client it is gone, so 18304
-- plays without it. The missile is unaffected: it hangs off the SpellVisual's own
-- SpellVisualMissileSetID 2291, not off a kit.
--
-- Kit 17337 is shared with SpellVisual 19021 (spell 89557 Shoulder-Mounted
-- Drake-Dropper) and 33838 (spell 146773 Shoot); both lose their attached model too.
--
-- Needs a worldserver restart.
DELETE FROM `hotfix_data` WHERE `TableHash`=0xF483EADB AND `RecordId`=17337;
INSERT INTO `hotfix_data` (`Id`,`TableHash`,`RecordId`,`Deleted`) VALUES (394,0xF483EADB,17337,1);
