-- New Tinkertown: the Loading Room teleporter scene.
--
-- A rescued gnome is teleported into the Loading Room about once a minute. The
-- Physician's Assistant walks over, points it towards a mat, leads it there and stands
-- over it while it rests; the gnome is taken away again before the next one arrives.
-- The whole run is driven by npc_physicians_assistant_greeter.
--
-- Two spawns stood in for parts of this scene and have to give way to it:
--
--   168936  the Rescued Survivor standing on the teleporter. Its position and facing
--           are exactly where the scene puts each arrival, which is where the script
--           takes them from. A permanent gnome there means two of them once the scene
--           runs.
--   169002  a Physician's Assistant standing on a node of the Assistant's own walk
--           back. Only two spawns of 42552 belong in the room -- 167775, which is
--           static and correct, and the one that plays the scene.
--
-- 167917 becomes the scene actor. It is moved from the post it stands at during the
-- scene to the spot the Assistant idles at between runs, which is where it must start
-- and where it returns to; the post is now a position in the script instead. The
-- facing is the direction the last leg of the walk home leaves it in.
--
-- The seven arrival lines and the Assistant's greeting come from BroadcastTextIds
-- 46477 to 46484. Four of the seven are confirmed in play; the other three sit inside
-- the same block and are the only other lines in it that fit.

DELETE FROM `creature_addon` WHERE `guid` IN (168936,169002);
DELETE FROM `creature` WHERE `guid` IN (168936,169002);

UPDATE `creature` SET `position_x`=-5164.96, `position_y`=775.741, `position_z`=287.3875,
  `orientation`=3.06154, `MovementType`=0, `wander_distance`=0,
  `ScriptName`='npc_physicians_assistant_greeter'
WHERE `guid`=167917;

DELETE FROM `creature_text` WHERE `CreatureID`=46267 AND `GroupID`=0;
DELETE FROM `creature_text` WHERE `CreatureID`=42552 AND `GroupID`=0;
INSERT INTO `creature_text` (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(46267,0,0,'Thank the Light! I\'ve made it.',12,0,100,0,0,0,46477,0,'Rescued Survivor - arrival'),
(46267,0,1,'It\'s a relief to be surrounded by normal gnomes again!',12,0,100,0,0,0,46478,0,'Rescued Survivor - arrival'),
(46267,0,2,'I thought I was goner!',12,0,100,0,0,0,46479,0,'Rescued Survivor - arrival'),
(46267,0,3,'You... you\'re not going to try to eat me, are you?',12,0,100,0,0,0,46480,0,'Rescued Survivor - arrival'),
(46267,0,4,'I never would\'ve made it on my own...',12,0,100,0,0,0,46481,0,'Rescued Survivor - arrival'),
(46267,0,5,'Thank you for getting me out of there!',12,0,100,0,0,0,46482,0,'Rescued Survivor - arrival'),
(46267,0,6,'My family... did you find my family?',12,0,100,0,0,0,46483,0,'Rescued Survivor - arrival'),
(42552,0,0,'Ah, a new arrival. Right this way, sir.',12,0,100,0,0,0,46484,0,'Physician\'s Assistant - greeting');
