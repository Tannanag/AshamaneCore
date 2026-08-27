-- New Tinkertown: stop the leper gnomes killing S.A.F.E. Operatives.
--
-- 2026_08_26_08_world.sql capped damage on 46391, which is the lookup for damage
-- dealt TO a leper -- it stops the Operatives killing them, not the reverse. The
-- Operatives had no cap of their own, so a leper could and did finish one off,
-- taking it out of the scene until respawn.
--
-- 85 matches 46391 and every other row in the table. Unit::DealDamage applies the
-- cap only for non-player-owned creature attackers, so this changes nothing for
-- players -- and 45847 is IMMUNE_TO_PC anyway.
DELETE FROM `creature_sparring_template` WHERE `CreatureID`=45847;
INSERT INTO `creature_sparring_template` (`CreatureID`,`HealthLimitPct`) VALUES (45847,85);
