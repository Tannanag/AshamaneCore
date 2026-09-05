-- New Tinkertown: the Physician's Assistants work the wounded.
--
-- Two assistants tend the four Wounded Infantry laid out east of the ramp. Each holds a
-- working pose at its own bench, walks the few yards to a patient, works over them for about
-- six seconds, walks back and settles again facing the way it started. The two are not in
-- step: 167858 covers the patient to its north-east and pauses to point before resuming, and
-- 167994 covers the patient to its south-west and does not. Both walk; neither runs.
--
-- The third assistant spawn, 169009, is removed. It stood on the exact spot 167994 walks to,
-- wearing the facing 167994 arrives with, so the scene would have run alongside a frozen copy
-- of itself standing inside the walker.
--
-- The four patients hold three different poses -- two kneeling, one sitting, one lying -- and
-- each periodically renews `Wounded` (46577) on itself. The four Healing Shields carry the
-- shield aura (79344) permanently, which is the bubble drawn over each patient.
--
-- The assistants' working pose is driven from the script and deliberately NOT from
-- `creature_addon`.`emote`: the pose has to drop while they walk, and an addon emote would be
-- reapplied underneath the script and fight it.
--
-- `AIName` goes on both templates. Every spawn of 42501 and 42557 is part of this scene. Of
-- the five 42552 spawns, 167917 keeps its own `ScriptName` -- a spawn script outranks
-- `AIName`, so the Loading Room greeter is unaffected -- and 167775 gets an event-less SmartAI,
-- which stands as still as it does now.

-- -----------------------------------------------------------------------------
-- spawns
-- -----------------------------------------------------------------------------

DELETE FROM `creature_addon` WHERE `guid`=169009;
DELETE FROM `creature` WHERE `guid`=169009;

UPDATE `creature` SET `position_x`=-5062.8125, `position_y`=484.02603, `position_z`=401.74854,
       `orientation`=2.775073528289795, `modelid`=32946 WHERE `guid`=167994;
UPDATE `creature` SET `position_x`=-5073.549, `position_y`=479.02777, `position_z`=401.62393,
       `orientation`=1.500983119010925, `modelid`=32944 WHERE `guid`=167858;

UPDATE `creature` SET `modelid`=32921 WHERE `guid` IN (167859,168102);

-- -----------------------------------------------------------------------------
-- poses and auras
-- -----------------------------------------------------------------------------

DELETE FROM `creature_addon` WHERE `guid` IN (167859,167997,168102,168103,167476,167477,167695,168101);
INSERT INTO `creature_addon`
  (`guid`,`path_id`,`mount`,`StandState`,`AnimTier`,`VisFlags`,`SheathState`,`PvPFlags`,`emote`,`aiAnimKit`,`movementAnimKit`,`meleeAnimKit`,`visibilityDistanceType`,`auras`) VALUES
(167859,0,0,8,0,0,1,0,0,0,0,0,0,''),
(167997,0,0,1,0,0,1,0,0,0,0,0,0,''),
(168102,0,0,8,0,0,1,0,0,0,0,0,0,''),
(168103,0,0,3,0,0,1,0,0,0,0,0,0,''),
(167476,0,0,0,0,0,1,0,0,0,0,0,0,'79344'),
(167477,0,0,0,0,0,1,0,0,0,0,0,0,'79344'),
(167695,0,0,0,0,0,1,0,0,0,0,0,0,'79344'),
(168101,0,0,0,0,0,1,0,0,0,0,0,0,'79344');

-- -----------------------------------------------------------------------------
-- the scene
-- -----------------------------------------------------------------------------

UPDATE `creature_template` SET `AIName`='SmartAI' WHERE `entry` IN (42552,42501);

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid` IN (-167858,-167994,42501);
DELETE FROM `smart_scripts` WHERE `source_type`=9 AND `entryorguid` IN (4255201,4255202);

INSERT INTO `smart_scripts`
  (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
   `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,
   `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
   `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES

-- 167994 -- the south-west assistant
(-167994,0,0,0,25,0,100,0,0,0,0,0,0,'',59,0,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - On Reset - Walk"),
(-167994,0,1,0,25,0,100,0,0,0,0,0,0,'',17,69,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - On Reset - Hold the working pose"),
(-167994,0,2,0,1,0,100,0,21150,33300,21150,33300,0,'',80,4255201,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Out of Combat - Tend the patient"),

(4255201,9,1,0,1,0,100,0,0,0,0,0,0,'',17,0,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Break off"),
(4255201,9,2,0,1,0,100,0,850,850,0,0,0,'',69,1,0,1,0,0,0,8,0,0,0,-5065.6655,482.6812,401.65927,0,"Physician's Assistant - Walk to the patient"),
(4255201,9,3,0,1,0,100,0,1264,1264,0,0,0,'',17,69,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Work on the patient"),
(4255201,9,4,0,1,0,100,0,5300,6890,0,0,0,'',17,0,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Finish"),
(4255201,9,5,0,1,0,100,0,0,0,0,0,0,'',69,2,0,1,0,0,0,8,0,0,0,-5062.8125,484.02603,401.74854,0,"Physician's Assistant - Walk back"),
(4255201,9,6,0,1,0,100,0,1264,1264,0,0,0,'',66,0,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Face the bench"),
(4255201,9,7,0,1,0,100,0,1530,1530,0,0,0,'',17,69,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Resume the working pose"),

-- 167858 -- the north-east assistant
(-167858,0,0,0,25,0,100,0,0,0,0,0,0,'',59,0,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - On Reset - Walk"),
(-167858,0,1,0,25,0,100,0,0,0,0,0,0,'',17,69,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - On Reset - Hold the working pose"),
(-167858,0,2,0,1,0,100,0,26700,41020,26700,41020,0,'',80,4255202,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Out of Combat - Tend the patient"),

(4255202,9,1,0,1,0,100,0,0,0,0,0,0,'',17,0,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Break off"),
(4255202,9,2,0,1,0,100,0,870,870,0,0,0,'',69,1,0,1,0,0,0,8,0,0,0,-5068.8184,480.60806,401.73004,0,"Physician's Assistant - Walk to the patient"),
(4255202,9,3,0,1,0,100,0,1996,1996,0,0,0,'',17,69,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Work on the patient"),
(4255202,9,4,0,1,0,100,0,5250,6880,0,0,0,'',17,0,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Finish"),
(4255202,9,5,0,1,0,100,0,0,0,0,0,0,'',69,2,0,1,0,0,0,8,0,0,0,-5073.549,479.02777,401.62393,0,"Physician's Assistant - Walk back"),
(4255202,9,6,0,1,0,100,0,1996,1996,0,0,0,'',66,0,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Face the bench"),
(4255202,9,7,0,1,0,100,0,1590,5360,0,0,0,'',5,25,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Point"),
(4255202,9,8,0,1,0,100,0,2820,2820,0,0,0,'',17,69,0,0,0,0,0,1,0,0,0,0,0,0,0,"Physician's Assistant - Resume the working pose"),

-- the patients
(42501,0,0,0,1,0,100,0,62000,165000,62000,165000,0,'',11,46577,0,0,0,0,0,1,0,0,0,0,0,0,0,"Wounded Infantry - Out of Combat - Renew Wounded");
