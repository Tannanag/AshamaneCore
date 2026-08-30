-- New Tinkertown: the two S.A.F.E. Operatives kneeling over a casualty.
--
-- 168986 holds 168987 and 169017 holds 169004, each in a vehicle seat, kneeling and
-- talking to the gnome it is holding. Neither rotates its line, so the two lines are
-- two groups rather than one group of two.
--
-- Which Operative says which line is a guess: both lines are spoken by an entry 46449,
-- but there is nothing tying either to a position. Swapping the two GroupIDs is the fix
-- if they are the wrong way round.
--
-- 168987 loses the creature_addon row added in 2026_08_30_00_world.sql. That row existed
-- only to keep 168987 standing while the template default changed underneath it; as a
-- casualty being held it wants the template's StandState 3 like every other one.
--
-- Needs a worldserver restart.
DELETE FROM `creature_text` WHERE `CreatureID`=46449;
INSERT INTO `creature_text`
 (`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`) VALUES
(46449,0,0,'Stay with me. You''re going to make it out of here.',12,0,100,0,0,0,0,0,'S.A.F.E. Operative - tending casualty (168986)'),
(46449,1,0,'We''re going to get you some help.',12,0,100,0,0,0,0,0,'S.A.F.E. Operative - tending casualty (169017)');

DELETE FROM `creature_addon` WHERE `guid`=168987;

UPDATE `creature` SET `ScriptName`='npc_safe_operative_medic'
WHERE `guid` IN (168986,169017) AND `id`=46449;
