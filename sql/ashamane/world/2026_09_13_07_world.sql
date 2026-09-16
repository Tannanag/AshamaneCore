-- Quest 26333 "No Tanks!": Destroy Mechano-Tank (spell 79751, cast from the
-- Techno-Grenade, item 58200) had no script, so its dummy effect did nothing and the
-- Repaired Mechano-Tanks (42224) -- immune to both PC and NPC damage -- could never be
-- destroyed for credit.
DELETE FROM `spell_script_names` WHERE `spell_id`=79751;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(79751, 'spell_item_destroy_mechano_tank');
