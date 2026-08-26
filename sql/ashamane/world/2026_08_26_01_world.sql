-- New Tinkertown: retail animation auras for the Crazed Leper Gnome (46363).
--
-- 95205 Irradiated (NPC), 86400 Leper Gnome Slime Drip, 86414 Leper Gnome Zombie
-- Anim. All three are SPELL_AURA_DUMMY: the animation is client-side, which is why
-- it survives movement where an emote state would not. Previously only 95205 was
-- on the template, the other two on 16 of the 78 old creature_addon rows.
UPDATE `creature_template_addon` SET `SheathState`=1, `auras`='95205 86400 86414' WHERE `entry`=46363;

