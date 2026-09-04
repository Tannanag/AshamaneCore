-- New Tinkertown: the Irradiated Technicians work their posts.

-- The twenty-seven 42223 spawns split cleanly in two and the split is already in the DB:
-- eleven carry `creature_addon`.`emote` 133 and hold a working pose, and the other sixteen
-- have no addon row, so they inherit aura 78858 from the template addon. Nothing overlaps.
--
-- What was missing is that the sixteen only ever *held* 78858. They never cast it, so there
-- was no channel and no cast pose -- they stood idle with an invisible buff. They now channel
-- it on themselves on a fixed ~10.9 s timer, which is a continuous loop: the spell is a
-- channel and the re-cast interrupts the tail of the previous one.
--
-- A guid-scoped script replaces the entry script outright rather than merging with it, so the
-- channel goes on the entry script -- which is what the sixteen run -- and the eleven posed
-- spawns get a guid script carrying the combat cast alone, keeping them out of the loop.
--
-- Equipment needs no change: `equipment_id` 0 falls through to `LoadEquipment(1)`, and equip
-- template 1 is item 1911, the small wrench, which is what these already hold.

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid`=42223 AND `id`=1;
DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid` IN (-167572,-167575,-167576,-167577,-167770,-167913,-168047,-168049,-168051,-168575,-168593);

INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(42223,0,1,0,1,0,100,0,1000,11000,10900,10900,0,'',11,78858,1,0,0,0,0,1,0,0,0,0,0,0,0,'Channel Irradiated Technician State'),
(-167572,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-167575,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-167576,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-167577,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-167770,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-167913,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-168047,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-168049,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-168051,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-168575,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun'),
(-168593,0,0,0,0,0,100,0,4500,6500,18000,19000,0,'',11,84148,0,0,0,0,0,2,0,0,0,0,0,0,0,'Cast Irradiation Gun');
