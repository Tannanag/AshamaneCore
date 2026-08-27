-- New Tinkertown: make the S.A.F.E. Operatives (45847) targetable.
--
-- unit_flags was 33555200 = NOT_SELECTABLE | IMMUNE_TO_PC | IMMUNE_TO_NPC, so the
-- cursor never changed over them. 256 is IMMUNE_TO_PC alone, matching the S.A.F.E.
-- Officer (46025) and Technician (46230), and what retail runs.
UPDATE `creature_template` SET `unit_flags`=256 WHERE `entry`=45847;
