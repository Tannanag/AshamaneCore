-- New Tinkertown: correct the script name on Nevin Twistwrench.
--
-- `npc_nevin_twistwrench` belongs to entry 45966, a different Nevin, who irradiates
-- players for the Decontamination quest. Two script objects cannot share a name, so the
-- arrivals script assigned in 2026_09_06_02_world.sql is renamed rather than that one.

UPDATE `creature` SET `ScriptName`='npc_nevin_twistwrench_arrivals' WHERE `guid`=167450;
