-- New Tinkertown: the S.A.F.E. Operative scene outside the starting area.
--
-- Seven Operatives trade fire with the Crazed Leper Gnomes (46391) beside them;
-- two more ignore the fight and bark at passing players. Scripted per guid, not
-- per entry, so the other 31 spawns of 45847 are unaffected.
--
--   spar : 984705 984706 984710 984711 (upper) 167627 167633 167938 (lower)
--   bark : 984707 984708
--
-- Damage is capped by creature_sparring_template in 2026_08_26_08_world.sql, which
-- keeps creatures from taking a leper below 85 percent while leaving players able
-- to kill them. Spell 85756 is provisional.
--
-- AIName goes on the template because per-guid scripts still need it; the spawns
-- without rows of their own get SmartAI with nothing to do.
UPDATE `creature_template` SET `AIName`='SmartAI' WHERE `entry`=45847;

DELETE FROM `creature_text` WHERE `CreatureID`=45847;
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(45847,0,0,'Our men have secured the walkway. Focus on helping those in the main room.',12,0,100,0,0,0,0,0,'S.A.F.E. Operative - Walkway secured');

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid` IN (-984705,-984706,-984710,-984711,-167627,-167633,-167938,-984707,-984708);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(-984705,0,0,0,1,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984705 - OOC - Shoot nearest Crazed Leper Gnome'),
(-984705,0,1,0,0,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984705 - IC - Shoot nearest Crazed Leper Gnome'),
(-984706,0,0,0,1,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984706 - OOC - Shoot nearest Crazed Leper Gnome'),
(-984706,0,1,0,0,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984706 - IC - Shoot nearest Crazed Leper Gnome'),
(-984710,0,0,0,1,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984710 - OOC - Shoot nearest Crazed Leper Gnome'),
(-984710,0,1,0,0,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984710 - IC - Shoot nearest Crazed Leper Gnome'),
(-984711,0,0,0,1,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984711 - OOC - Shoot nearest Crazed Leper Gnome'),
(-984711,0,1,0,0,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984711 - IC - Shoot nearest Crazed Leper Gnome'),
(-167627,0,0,0,1,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167627 - OOC - Shoot nearest Crazed Leper Gnome'),
(-167627,0,1,0,0,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167627 - IC - Shoot nearest Crazed Leper Gnome'),
(-167633,0,0,0,1,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167633 - OOC - Shoot nearest Crazed Leper Gnome'),
(-167633,0,1,0,0,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167633 - IC - Shoot nearest Crazed Leper Gnome'),
(-167938,0,0,0,1,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167938 - OOC - Shoot nearest Crazed Leper Gnome'),
(-167938,0,1,0,0,0,100,0,2000,4000,3000,6000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167938 - IC - Shoot nearest Crazed Leper Gnome'),
(-984707,0,0,0,10,0,100,0,1,8,45000,90000,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 984707 - OOC LOS - Walkway secured'),
(-984708,0,0,0,10,0,100,0,1,8,45000,90000,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 984708 - OOC LOS - Walkway secured');

-- event 1 UPDATE_OOC, 0 UPDATE_IC, 10 OOC_LOS (param1 1 = fires for non-hostiles,
-- param2 range, param3/4 cooldown); action 11 CAST, 1 TALK; target 19
-- CLOSEST_CREATURE (entry, maxDist), 1 SELF.
