-- Northshire Valley: make the Blackrock Spies render see-through, by hotfixing
-- the alpha on their own CreatureDisplayInfo rows.
--
-- The goal has been the same throughout: the spies should not be invisible, they
-- should be see-through. Three earlier attempts missed, and each ruled something
-- out that points here.
--
--   80673 "Camouflage"  -- SpellVisualID 17071, a bespoke Cataclysm quest visual.
--                          Painted them in leafy particles. Removed in _05.
--   84442 "Stealth"     -- correct aura, wrong mechanic. Any SPELL_AURA_MOD_STEALTH
--                          puts the unit through WorldObject::CanDetectStealthOf
--                          (Object.cpp:2334), which hides it past
--                          (30 + (seerLevel-1)*5 - stealth) * 0.3 + reach yards --
--                          about ten for a level 1 player. Invisible until walked
--                          up on, not see-through. Removed in _07.
--   VisFlags 2 (CREEP)  -- the flag HandleModStealth itself raises
--                          (SpellAuraEffects.cpp:1592). Wiring up the dead
--                          creature_addon.VisFlags column and setting it changed
--                          nothing in game, so the client wants more than that
--                          byte. Core change reverted.
--
-- What is left is the one place transparency lives that is not a spell at all:
-- CreatureDisplayInfo.CreatureModelAlpha. It is read client-side for whatever
-- display id the server sends, so it needs no aura, no stand flag and no core
-- code. 2101 display rows in the 7.3.5 client already use it, 55 of them on
-- ModelID 51, which is the spy's own model -- so this is a mechanism the client
-- demonstrably honours on exactly this model.
--
-- Swapping the spies onto one of those 55 was the obvious move and is wrong: the
-- spy's appearance comes from ExtendedDisplayInfoID 24182/24181/24183/24184, and
-- no translucent display shares it, so they would turn into a different orc.
-- Instead this overrides the alpha on the spy's own four rows and changes nothing
-- else about them.
--
-- Every other column is copied verbatim out of the client's own
-- CreatureDisplayInfo.db2 -- model 51 male and 52 female, the four
-- ExtendedDisplayInfoIDs, gender, SizeClass, UnarmedWeaponType -1, scales. Only
-- CreatureModelAlpha moves, 255 -> 128, which is half opacity and the value 23 of
-- the translucent ModelID 51 displays already use.
--
-- Scope: all four ids belong to Blackrock Spy (49874). 36652 is also listed on
-- Blackrock Cannon-Hauler (71723), which has zero spawns in the world, so nothing
-- else in the game can be reached by this.
DELETE FROM `creature_display_info` WHERE `ID` IN (36653,36652,36654,36655);
INSERT INTO `creature_display_info` (ID,CreatureModelScale,ModelID,NPCSoundID,SizeClass,Flags,Gender,ExtendedDisplayInfoID,PortraitTextureFileDataID,CreatureModelAlpha,SoundID,PlayerOverrideScale,PortraitCreatureDisplayInfoID,BloodID,ParticleColorID,CreatureGeosetData,ObjectEffectPackageID,AnimReplacementSetID,UnarmedWeaponType,StateSpellVisualKitID,PetInstanceScale,MountPoofSpellVisualKitID,TextureVariationFileDataID1,TextureVariationFileDataID2,TextureVariationFileDataID3,VerifiedBuild) VALUES
(36653,1,51,0,1,0,0,24182,0,128,0,0,0,0,0,0,0,0,-1,0,1,0,0,0,0,0),
(36652,1,51,0,1,0,0,24181,0,128,0,0,0,0,0,0,0,0,-1,0,1,0,0,0,0,0),
(36654,1,52,0,1,0,1,24183,0,128,0,0,0,0,0,0,0,0,-1,0,1,0,0,0,0,0),
(36655,1,52,0,1,0,1,24184,0,128,0,0,0,0,0,0,0,0,-1,0,1,0,0,0,0,0);

-- hotfix_data is what tells the client to go and fetch the overridden record
-- instead of trusting the copy in its own DB2. Without these four rows the table
-- above is loaded server-side and the client never hears about it, so the spies
-- stay solid. 0xBFDAF9F1 is the CreatureDisplayInfo table hash, read from the
-- table_hash field of the client's CreatureDisplayInfo.db2 header.
DELETE FROM `hotfix_data` WHERE `TableHash`=0xBFDAF9F1 AND `RecordId` IN (36653,36652,36654,36655);
INSERT INTO `hotfix_data` (`TableHash`,`RecordId`,`Deleted`) VALUES
(0xBFDAF9F1,36653,0),
(0xBFDAF9F1,36652,0),
(0xBFDAF9F1,36654,0),
(0xBFDAF9F1,36655,0);

-- This is a hotfixes-database file, not a world one, so wpp_apply.py does not
-- handle it and there is no -- @touched: line. Hotfixes are read once at startup
-- by DB2Manager::LoadHotfixData (DB2Stores.cpp:1242), so this needs a worldserver
-- restart rather than a .reload, and the client may need its cache cleared.
--
-- Undo is the two DELETE statements above on their own.
