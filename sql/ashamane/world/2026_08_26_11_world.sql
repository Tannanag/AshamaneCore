-- New Tinkertown: make the sparring S.A.F.E. Operatives use their guns.
--
-- They were meleeing. With hostile factions three to four yards apart the core
-- will always swing: TargetedMovementGenerator returns early when the owner is
-- already inside the ranged offset, so SET_RANGED_MOVEMENT cannot push them back
-- out, and this core has no no-melee creature flag.
--
-- So the swing is made rare instead. BaseAttackTime goes from 2s to 9s while the
-- shoot lands every 2-3s, leaving roughly four shots per swing. This is entry-wide
-- and the only stat touched; set it back to 2000 to undo.
--
-- The aggro row still sets a ranged hold, which does nothing at this spacing but
-- keeps them at range if a leper is ever pulled away and they re-engage.
--
-- Redefines the seven sparring guids only. The two barkers keep what
-- 2026_08_26_09_world.sql gave them.
UPDATE `creature_template` SET `BaseAttackTime`=9000 WHERE `entry`=45847;

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid` IN (-984705,-984706,-984710,-984711,-167627,-167633,-167938);
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(-984705,0,0,0,4,0,100,0,0,0,0,0,0,79,8,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 984705 - On Aggro - Hold at range'),
(-984705,0,1,0,1,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984705 - OOC - Shoot nearest Crazed Leper Gnome'),
(-984705,0,2,0,0,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984705 - IC - Shoot nearest Crazed Leper Gnome'),
(-984706,0,0,0,4,0,100,0,0,0,0,0,0,79,8,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 984706 - On Aggro - Hold at range'),
(-984706,0,1,0,1,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984706 - OOC - Shoot nearest Crazed Leper Gnome'),
(-984706,0,2,0,0,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984706 - IC - Shoot nearest Crazed Leper Gnome'),
(-984710,0,0,0,4,0,100,0,0,0,0,0,0,79,8,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 984710 - On Aggro - Hold at range'),
(-984710,0,1,0,1,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984710 - OOC - Shoot nearest Crazed Leper Gnome'),
(-984710,0,2,0,0,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984710 - IC - Shoot nearest Crazed Leper Gnome'),
(-984711,0,0,0,4,0,100,0,0,0,0,0,0,79,8,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 984711 - On Aggro - Hold at range'),
(-984711,0,1,0,1,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984711 - OOC - Shoot nearest Crazed Leper Gnome'),
(-984711,0,2,0,0,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 984711 - IC - Shoot nearest Crazed Leper Gnome'),
(-167627,0,0,0,4,0,100,0,0,0,0,0,0,79,8,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 167627 - On Aggro - Hold at range'),
(-167627,0,1,0,1,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167627 - OOC - Shoot nearest Crazed Leper Gnome'),
(-167627,0,2,0,0,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167627 - IC - Shoot nearest Crazed Leper Gnome'),
(-167633,0,0,0,4,0,100,0,0,0,0,0,0,79,8,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 167633 - On Aggro - Hold at range'),
(-167633,0,1,0,1,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167633 - OOC - Shoot nearest Crazed Leper Gnome'),
(-167633,0,2,0,0,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167633 - IC - Shoot nearest Crazed Leper Gnome'),
(-167938,0,0,0,4,0,100,0,0,0,0,0,0,79,8,0,0,0,0,0,1,0,0,0,0,0,0,0,'S.A.F.E. Operative 167938 - On Aggro - Hold at range'),
(-167938,0,1,0,1,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167938 - OOC - Shoot nearest Crazed Leper Gnome'),
(-167938,0,2,0,0,0,100,0,2000,3000,2000,3000,0,11,85756,0,0,0,0,0,19,46391,25,0,0,0,0,0,'S.A.F.E. Operative 167938 - IC - Shoot nearest Crazed Leper Gnome');

-- event 4 AGGRO, 1 UPDATE_OOC, 0 UPDATE_IC; action 79 SET_RANGED_MOVEMENT
-- (distance, angle), 11 CAST; target 19 CLOSEST_CREATURE (entry, maxDist), 1 SELF.
