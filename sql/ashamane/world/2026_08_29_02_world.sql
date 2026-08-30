-- New Tinkertown: the S.A.F.E. Operatives stand ready.
--
-- EmoteState 214 EMOTE_STATE_READY_RIFLE. Their ranged slot holds 52355, a gun
-- (Item.db2 ClassID 2, SubclassID 3), which SheathState 2 already draws.
--
-- creature_addon overrides creature_template_addon wholesale rather than merging, so
-- the 18 per-spawn rows need the same value. 168120 and 168966 are the exception and
-- keep emote 69 EMOTE_STATE_USE_STANDING: they are working, not standing guard.
--
-- Unit::Attack clears UNIT_NPC_EMOTESTATE, so the seven spawns running
-- npc_safe_operative_sparring re-assert it in AttackStart -- they never evade, so
-- nothing else would.
--
-- Needs a worldserver restart.
UPDATE `creature_template_addon` SET `emote`=214 WHERE `entry`=45847;

UPDATE `creature_addon` `a` JOIN `creature` `c` ON `c`.`guid`=`a`.`guid`
SET `a`.`emote`=214 WHERE `c`.`id`=45847 AND `a`.`guid` NOT IN (168120,168966);
