-- Shadowglen: Moonpetal Lilies (207346) can only be picked by a player on
-- Iverron's Antidote (28724); Melithar's Stolen Bags (195074) only on Demonic
-- Thieves (28715).
--
-- Both are type 3 chests whose only loot is the quest item, so a player without
-- the quest opened an empty loot window -- and, the chest being consumable, the
-- object despawned for its 300 s respawn anyway. The core already computes
-- GO_DYNFLAG_LO_ACTIVATE per player for a chest with quest loot that player
-- needs (GameObject::ActivateToQuest); the client only turns that into "cannot
-- interact" when the object carries GO_FLAG_INTERACT_COND (4), and both
-- templates had gameobject_template_addon.flags 0. Retail sends both with
-- Flags 65540 = INTERACT_COND | 0x10000 (a 12.x bit this core does not define)
-- in dump_12.1.0.69814_2026-09-14_23-03-16; the lily also with FactionTemplate
-- 210, which the vanilla lily 152095 (flags 4, faction 210) already carries.
UPDATE `gameobject_template_addon` SET `flags`=4, `faction`=210 WHERE `entry`=207346;
UPDATE `gameobject_template_addon` SET `flags`=4 WHERE `entry`=195074;
