-- New Tinkertown: the Gnomeregan Recruits spar with the Living Contamination
-- Eight pairs line the path at the tram entrance, a recruit and a contamination
-- three and a half yards apart facing each other. Nothing made them fight: two
-- stationary creatures never run each other's line-of-sight check, because that
-- only fires on relocation. The recruit's half is C++ (npc_gnomeregan_recruit_sparring),
-- which opens fire and so starts the fight; this file is the rest.

-- The eight that face a contamination. The other four spawns of 43092 stand a
-- hundred and fifty yards south with nothing in front of them and are left alone.
UPDATE `creature` SET `ScriptName` = 'npc_gnomeregan_recruit_sparring' WHERE `guid` IN (
    167457, 167463, 167687, 167688, 167690, 167847, 167855, 167990);

-- The contamination melees on its own once the recruit opens fire; only the bolt
-- needs saying. 21067 is Poison Bolt, on a 12 s cycle.
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` = 43089;
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` = 43089;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(43089, 0, 0, 0, 0, 0, 100, 0, 10800, 13900, 10800, 13900, 11, 21067, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 'Living Contamination - In Combat - Cast Poison Bolt');

-- The recruit carries its rifle drawn, which is SheathState 2 on
-- creature_template_addon. Five of the eight spawns carried a creature_addon row
-- overriding that to 1 and sheathing the rifle; the other three had no row and were
-- right by accident. Dropping the five leaves all eight on the template row, which
-- also carries the aura that holds the rifle. Needs a worldserver restart: there is
-- no .reload for creature_addon.
DELETE FROM `creature_addon` WHERE `guid` IN (
    167463, 167687, 167688, 167690, 167847);

-- @touched: creature 167457,167463,167687,167688,167690,167847,167855,167990
