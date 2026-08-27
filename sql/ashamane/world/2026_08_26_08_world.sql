-- New Tinkertown: let the Crazed Leper Gnomes (46391) be sparred with.
--
-- HealthLimitPct 85 stops creatures taking them below 85% or killing them, so the
-- S.A.F.E. Operatives can trade fire with them forever. Unit::DealDamage applies
-- this only when the attacker is a creature that is not player-owned, so a player
-- still kills them normally.
--
-- All five 46391 spawns are the scene gnomes, so this is entry-wide by design.
-- Their respawn drops to 30s, against 300s for the ordinary leper gnomes (46363).
DELETE FROM `creature_sparring_template` WHERE `CreatureID`=46391;
INSERT INTO `creature_sparring_template` (`CreatureID`,`HealthLimitPct`) VALUES (46391,85);

UPDATE `creature` SET `spawntimesecs`=30 WHERE `guid` IN (168891,168892,168893,168496,168497) AND `id`=46391;
