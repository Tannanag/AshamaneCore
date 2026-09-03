-- New Tinkertown: the S.A.F.E. Guide walks a new mage to Bipsi Frostflinger.
--
-- 47351 has no spawn. It is summoned when 26197 is accepted and unsummons again at
-- the trainer, so the route and the timings live in npc_safe_guide; only the two
-- lines and the script binding are here.
--
-- `Emote` 1 is the OneShotTalk that plays with each line.

DELETE FROM `creature_text` WHERE `CreatureID`=47351;
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(47351,0,0,'Follow me, $n, and I\'ll introduce you to your trainer, Bipsi Frostflinger.',12,0,100,1,0,0,47531,0,'S.A.F.E. Guide'),
(47351,1,0,'Bipsi, this is $n, one of the most recent survivors to emerge from Gnomeregan.',12,0,100,1,0,0,47532,0,'S.A.F.E. Guide');

UPDATE `creature_template` SET `ScriptName`='npc_safe_guide' WHERE `entry`=47351;
