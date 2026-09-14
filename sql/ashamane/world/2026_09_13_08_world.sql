-- "Down with Crushcog!" (26364), the Mekkatorque assault.
--
-- 43230 Crushcog Technician, the four already-spawned but unscripted guids beside
-- the guardians, gets its script so the jump-onto-the-guardian beat has something to
-- act on.
UPDATE `creature_template` SET `ScriptName`='npc_crushcog_technician' WHERE `entry`=43230;

-- The mech (42839) has a vehicle_template_accessory row seating Crushcog (42494) in
-- seat 0, but HandleSpellClick -- which InstallAccessory uses to board him -- finds
-- nothing without a npc_spellclick_spells row on the vehicle itself. Without it the
-- accessory spawns but never boards, which is why Crushcog was never seen on the mech.
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry`=42839;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES
(42839, 46598, 1, 0);
