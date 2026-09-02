-- New Tinkertown: the S.A.F.E. Officer in the Loading Room's north-west corner
-- gestures at the two Operatives seated in front of him.
--
-- Scoped to this one spawn. 46025 has no template AIName, and the Officer who walks
-- the room's patrol does not do this, so the entry is left alone.
--
-- Needs a worldserver restart.
UPDATE `creature` SET `ScriptName`='npc_safe_officer_briefing' WHERE `guid`=167810;
