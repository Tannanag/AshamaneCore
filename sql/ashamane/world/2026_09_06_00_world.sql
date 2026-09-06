-- New Tinkertown: remove six spawns and the recruits' ammo carts.
--
-- Three Gnomeregan Recruits, a S.A.F.E. Operative and two Gnomeregan Infantry,
-- plus the ammo cart and cart bunny standing with each recruit.

DELETE FROM `creature_addon` WHERE `guid` IN
(168813,168814,168815,168869,168870,168871,168894,169007,169008,169302,169303,169304);

DELETE FROM `creature` WHERE `guid` IN
(168813,168814,168815,168869,168870,168871,168894,169007,169008,169302,169303,169304);
