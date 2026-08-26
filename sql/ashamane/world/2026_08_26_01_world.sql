-- New Tinkertown: animation auras for the Crazed Leper Gnome (46363).
--
-- 95205 Irradiated (NPC), 86400 Leper Gnome Slime Drip, 86414 Leper Gnome Zombie
-- Anim. All three are SPELL_AURA_DUMMY, so the animation is client-side and
-- survives movement where an emote state would not.
UPDATE `creature_template_addon` SET `SheathState`=1, `auras`='95205 86400 86414' WHERE `entry`=46363;

