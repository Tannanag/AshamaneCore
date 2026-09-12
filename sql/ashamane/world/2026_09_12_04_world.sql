-- New Tinkertown, "Down with Crushcog!" (26364): the camp cheers the hand-in.
--
-- Jarvi Shadowstep runs the scene from npc_jarvi_shadowstep: High Tinker
-- Mekkatorque rides in as a summon and the soldiers around Jarvi cheer the
-- player. The beats live in the script; only the lines and bindings are here.
--
-- 42849 keeps its groups 0-8; group 9 is the arrival line. The infantry and
-- mountaineer lines carry no `Emote`: the script rolls the gesture separately.

DELETE FROM `creature_text` WHERE `CreatureID` IN (42353,42316,13076) OR (`CreatureID`=42849 AND `GroupID`=9);
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(42353,0,0,'$n, along with High Tinker Mekkatorque and Mountaineer Stonegrind, has defeated Razlo Crushcog!',12,0,100,5,0,0,42801,0,'Jarvi Shadowstep'),
(42353,1,0,'The victorious heroes have returned! Control of Chill Breeze Valley is ours once again!',12,0,100,4,0,0,42802,0,'Jarvi Shadowstep'),
(42849,9,0,'Razlo Crushcog is no more! The people of Ironforge and Gnomeregan speak with one voice this day. Hear us well, Thermaplugg. The day of your defeat approaches!',12,0,100,4,0,20889,42999,0,'High Tinker Mekkatorque'),
(42316,0,0,'Three cheers for $n!',12,0,100,0,0,13838,42805,0,'Gnomeregan Infantry'),
(42316,1,0,'Victory at last!',12,0,100,0,0,0,42807,0,'Gnomeregan Infantry'),
(13076,0,0,'I\'ll drink to that!',12,0,100,0,0,0,42809,0,'Dun Morogh Mountaineer');

UPDATE `creature_template` SET `ScriptName`='npc_jarvi_shadowstep' WHERE `entry`=42353;

-- Mekkatorque rides a mechanostrider, at the front and when he arrives at the camp.
UPDATE `creature_template_addon` SET `mount`=31692 WHERE `entry`=42849;

-- The four infantry on the line hold their rifles at the ready; the one by the
-- camp's fire sits. Needs a worldserver restart.
UPDATE `creature_addon` SET `SheathState`=2 WHERE `guid` IN (167614,167797,167929,168066);
UPDATE `creature_addon` SET `StandState`=1 WHERE `guid`=167621;
