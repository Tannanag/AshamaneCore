-- New Tinkertown: hand the walkway barks to npc_safe_operative_barker.
--
-- 984707 and 984708 both keep the bark; only the trigger changes. Their
-- SMART_EVENT_OOC_LOS rows go because the event compares against maxDist plus both
-- combat reaches -- 1.725 for the Operative, 1.5 for the player -- so its smallest
-- usable radius is 4.2 yards and the 8 it carried was really 11.2. That is wider than
-- half the 19 yards between the two spawns, so a player on the walkway stood inside
-- both circles and set off both barks. The script uses the 2.5 yards retail uses.
--
-- ScriptName is checked before AIName in CreatureAISelector, so these two spawns take
-- the script and the rest of 45847 keeps SmartAI.
--
-- Needs a worldserver restart.
DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid` IN (-984707,-984708);

UPDATE `creature` SET `ScriptName`='npc_safe_operative_barker'
WHERE `id`=45847 AND `guid` IN (984707,984708);
