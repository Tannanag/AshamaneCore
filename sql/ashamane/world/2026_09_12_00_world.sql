-- New Tinkertown: the Captured Demolitionists (42645) react to being freed.
-- 1.4 s after the cage opens the gnome gestures and says one of six lines,
-- 3.7 s later runs 10 yd straight out of the cage, and vanishes 1.7 s after
-- that. The old list said nothing (no creature_text), walked 5 yd and had a
-- dead invoker-cast row (SetData carries no invoker, so it never fired; quest
-- credit comes from the cage script alone).
-- The cage (204019) closes itself 60 s after opening so it can be used again;
-- it loads with NODESPAWN, so the reset leaves it in place. The gnome comes
-- back on the same clock: 53 s after its despawn.

DELETE FROM `creature_text` WHERE `CreatureID`=42645;
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(42645,0,0,'Thank you for breaking me out of here!',12,0,100,1,0,0,42579,0,'Captured Demolitionist'),
(42645,0,1,'I don''t ever want to smell unwashed trogg again!',12,0,100,1,0,0,42580,0,'Captured Demolitionist'),
(42645,0,2,'Thanks. Now, let''s blow up that cave!',12,0,100,1,0,0,42581,0,'Captured Demolitionist'),
(42645,0,3,'You have no idea how happy I am to see you!',12,0,100,1,0,0,42582,0,'Captured Demolitionist'),
(42645,0,4,'Finally, someone who''s not a trogg!',12,0,100,1,0,0,42583,0,'Captured Demolitionist'),
(42645,0,5,'I''m free! I''m really free!',12,0,100,5,0,0,42584,0,'Captured Demolitionist');

DELETE FROM `smart_scripts` WHERE `entryorguid`=4264500 AND `source_type`=9;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(4264500,9,0,0,0,0,100,0,1400,1400,0,0,0,'',1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Captured Demolitionist - On Script - Say Line 0'),
(4264500,9,1,0,0,0,100,0,3700,3700,0,0,0,'',114,0,0,0,0,0,0,1,0,0,0,0,10,0,0,'Captured Demolitionist - On Script - Move Forward 10 yd'),
(4264500,9,2,0,0,0,100,0,1700,1700,0,0,0,'',41,0,0,0,0,0,0,1,0,0,0,0,0,0,0,'Captured Demolitionist - On Script - Despawn');

UPDATE `creature` SET `spawntimesecs`=53 WHERE `id`=42645 AND `guid` IN (167479,167696,167861,167862,167999,168001,168456,168459,168460,168518,168541,168570,168576,168587,168610,168616,168617);

UPDATE `gameobject_template` SET `Data2`=60000 WHERE `entry`=204019 AND `type`=1;

-- @touched: creature_text 42645; smart_scripts 4264500; creature 42645 x17; gameobject_template 204019
