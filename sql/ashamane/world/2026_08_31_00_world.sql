-- New Tinkertown: the three firing squads at the Target Acquisition Device drop points.
--
-- Scoped to these ten spawns only. A creature.ScriptName beats the template AIName, so
-- these leave SmartAI behind while every other 45847 in the camp keeps it.
--
--   -5030, 792-797  west platform      -4951, 732-737  east walk
--   -4983, 779-782  middle pair
--
-- Needs a worldserver restart.
UPDATE `creature` SET `ScriptName`='npc_safe_operative_firing_squad'
WHERE `guid` IN (167623,167624,167625,167626,167940,167941,167942,167943,167947,167949);
