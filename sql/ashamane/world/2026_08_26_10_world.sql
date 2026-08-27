-- New Tinkertown: keep the non-sparring S.A.F.E. Operatives out of the fight.
--
-- Only four of the twelve camp Operatives spar. The rest were being dragged into
-- combat anyway, because faction 2300 and the lepers' faction 14 are hostile and
-- they stand a few yards apart. unit_flags 768 is IMMUNE_TO_PC plus IMMUNE_TO_NPC,
-- which takes them out of NPC combat while leaving them selectable.
--
-- Per-spawn unit_flags replaces the template value outright when non-zero
-- (ObjectMgr::ChooseCreatureFlags), so 768 here supersedes the template's 256.
--
-- 984705, 984706, 984710 and 984711 keep 0 and stay in the fight.
UPDATE `creature` SET `unit_flags`=768
WHERE `id`=45847 AND `guid` IN (984700,984701,984702,984703,984704,984707,984708,984709);
