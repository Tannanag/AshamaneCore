-- Teldrassil: Dentaria Silverglade (49479) at the mouth of Shadowthread Cave points
-- the way when a player accepts 28729 "Teldrassil: Crown of Azeroth" and 28730
-- "Precious Waters". Both come from the cured spawn (300000154, the one Tarindrella
-- sends the player to); the entry-level accept rows already said the right lines
-- but with no emote and no turn.
--
-- From dump_12.1.0.69814_2026-09-14_23-03-16, T0 = CMSG_QUEST_GIVER_ACCEPT_QUEST:
--   28729 (23:35:12.4)  +1.6  emote 397 (OneShotPointNoSheathe), face 5.6200 -- the
--                             moonwell -- "The moonwell is to the northeast, on the
--                             other side of the pool and up the hill."
--                       +6.5  face back 5.9709
--   28730 (23:38:28.9)  +2.0  emote 397, face 3.0369 -- Aldrassil's ramp -- "The
--                             ramp up to Aldrassil is just in sight over there.
--                             Circle around and find Tenaron up top."
--                       +6.9  face back 5.9709
-- (the 28730 bark ran again at 23:38:46 for a second player: it is the NPC's list,
-- restarted per accept, not per-player). The point comes with the text, so it goes
-- on the two creature_text rows; the return is SET_ORIENTATION on self, which is
-- the spawn's orientation (5.9709 on 300000154). 28725's accept row stays as it was:
-- the sniff did not catch that accept.
--
-- Needs a restart (or .reload smart_scripts / creature_text).

DELETE FROM `smart_scripts` WHERE `entryorguid`=49479 AND `source_type`=0 AND `id` IN (2, 3);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (4947901, 4947902) AND `source_type`=9;
INSERT INTO `smart_scripts` (`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,`event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param_string`,`action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,`target_type`,`target_param1`,`target_param2`,`target_param3`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`) VALUES
(49479,   0, 2, 0, 19, 0, 100, 0, 28729, 0,    0, 0, 0, '', 80, 4947901, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Teldrassil: Crown of Azeroth accepted - action list'),
(49479,   0, 3, 0, 19, 0, 100, 0, 28730, 0,    0, 0, 0, '', 80, 4947902, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Precious Waters accepted - action list'),
(4947901, 9, 0, 0, 0,  0, 100, 0, 1600,  1600, 0, 0, 0, '', 66, 0,       0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 5.6200, 'Dentaria Silverglade - on Teldrassil: Crown of Azeroth accepted - face the moonwell'),
(4947901, 9, 1, 0, 0,  0, 100, 0, 0,     0,    0, 0, 0, '', 1,  2,       0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Teldrassil: Crown of Azeroth accepted - say text 2'),
(4947901, 9, 2, 0, 0,  0, 100, 0, 4900,  4900, 0, 0, 0, '', 66, 0,       0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Teldrassil: Crown of Azeroth accepted - face back'),
(4947902, 9, 0, 0, 0,  0, 100, 0, 2000,  2000, 0, 0, 0, '', 66, 0,       0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 3.0369, 'Dentaria Silverglade - on Precious Waters accepted - face the ramp up to Aldrassil'),
(4947902, 9, 1, 0, 0,  0, 100, 0, 0,     0,    0, 0, 0, '', 1,  3,       0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Precious Waters accepted - say text 3'),
(4947902, 9, 2, 0, 0,  0, 100, 0, 4900,  4900, 0, 0, 0, '', 66, 0,       0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,      'Dentaria Silverglade - on Precious Waters accepted - face back');

-- Both lines come with the point.
UPDATE `creature_text` SET `Emote`=397 WHERE `CreatureID`=49479 AND `GroupID` IN (2, 3);
