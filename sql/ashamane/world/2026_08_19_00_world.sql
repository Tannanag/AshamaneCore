-- Coldridge Valley: collapse the Kharanos tunnel when "A Trip to Ironforge" is
-- turned in, and hold Milo Geartwinge back until Hands signals for him.
--
-- The quest chain out of the valley is 218 Ice and Fire -> 24490 A Trip to
-- Ironforge -> 24491 Follow that Gyro-Copter! -> 24492 Pack Your Bags, and the
-- quest text spells the beat out. Hands Springsprocket (6782) ends 24490 with
-- "To Ironforge?  Well first, you'll need to go through Kharanos, and before
-- that, you'll have to go through this tunnel.", and then offers 24491, which
-- opens "D-d-did you see that?  How the whole cave just crumbled like that? ...
-- The Gnomeregan Airmen have a flight path not far from here.  I'll send up a
-- signal, and they should be here to help.  I imagine they'll land back over at
-- Anvilmar."  So the tunnel comes down between the two, and Milo lands after.
--
-- None of that happens on this server today: nothing collapses, and Milo has
-- been standing at Anvilmar next to his gyro since the character logged in.
--
-- Retail wires the whole thing through the two quest spells, and both already
-- exist in our DB2s:
--
--   70046  A Trip to Ironforge - Quest Complete   (quest_template.RewardSpell of 24490)
--            eff0 FORCE_CAST -> 70042
--            eff1 PLAY_SOUND 12549  -- Hands' "...and whaaaaa....?" line
--   70042  eff0 APPLY_AREA_AURA_PARTY, MOD_INVISIBILITY_DETECT type 7 value 1, permanent
--   70047  Follow That Gyro-Copter - Quest Start  (source spell of 24491)
--            eff1 FORCE_CAST -> 70044
--   70044  APPLY_AURA MOD_INVISIBILITY_DETECT type 8 value 1000, permanent
--   70045  APPLY_AURA MOD_INVISIBILITY        type 8 value 100,  permanent
--
-- i.e. the rubble is invisibility type 7 and Milo is invisibility type 8, and
-- each quest step hands the player the matching detect aura.  The spell scripts
-- for 70046 and 70047 are already in
-- src/server/scripts/EasternKingdoms/zone_dun_morogh_area_coldridge_valley.cpp
-- and already registered in spell_script_names; they had nothing to act on.
--
-- Three things were missing, and they are what this file adds.

-- 1. The rubble itself.
--
-- Coordinates, rotation and spawn time are the 4.3.4 sniff (TrinityCore
-- sql/old/4.3.4/world/18_2017_05_16/2017_04_16_04_world.sql, VerifiedBuild
-- 23877).  It sits 34 yd up the tunnel from Hands, on the line his camp makes
-- with the Coldridge Pass side.
--
-- Divergence from the sniff, on purpose: retail hides this object with
-- `gameobject_addon` invisibilityType 7 / invisibilityValue 1, paired with the
-- detect aura 70042 above.  We put it in a phase instead.  Invisibility only
-- gates *drawing* the object -- GameObjectModelOwnerImpl::IsInPhase, which is
-- what the dynamic collision tree asks, compares phase shifts and knows nothing
-- about invisibility.  Display 2230 has a real collision model (roughly
-- 10 x 15 x 10 yd, GameObjectModels.dtree), so an invisibility-gated spawn would
-- put an invisible wall across the tunnel for every character who has not done
-- the quest yet.  A phase gates the model and the drawing together.
SET @OGUID := 210120200;
DELETE FROM `gameobject` WHERE `guid`=@OGUID;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnDifficulties`, `phaseUseFlags`, `PhaseId`, `PhaseGroup`, `terrainSwapMap`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `isActive`, `VerifiedBuild`) VALUES
(@OGUID, 201711, 0, 0, 0, '0', 0, 170, 0, -1, -6218.997, 118.5677, 431.6347, 2.600535, 0, 0, 0.9636297, 0.267241, 120, 255, 1, 0, 23877); -- Coldridge Tunnel Cave In

-- 2. The phase that carries it.
--
-- 170 is an existing generic "Quest Zone-Specific 01" phase.  Phases are scoped
-- by area: PhasingHandler::OnAreaChange clears the shift and rebuilds it from
-- `phase_area` for the current area and its parents, so 170 being used in area
-- 4720 already cannot leak into Coldridge and ours cannot leak out.
--
-- Both sides of the tunnel are listed.  The rubble sits within a few yards of
-- the 132/800 boundary (a Coldridge Mountaineer at -6233.7, 117.7 is area 132,
-- a Rockjaw Raider at -6205.1, 99.9 is area 800), and area 800's parent is Dun
-- Morogh rather than Coldridge Valley, so neither area covers the other.  With
-- only one of them the rubble would flicker in and out as the player crosses.
DELETE FROM `phase_area` WHERE `AreaId` IN (132, 800) AND `PhaseId`=170;
INSERT INTO `phase_area` (`AreaId`, `PhaseId`, `Comment`) VALUES
(132, 170, 'Coldridge Valley - Kharanos tunnel collapsed, after quest 24490 rewarded'),
(800, 170, 'Coldridge Pass - Kharanos tunnel collapsed, after quest 24490 rewarded');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=26 AND `SourceGroup`=170 AND `SourceEntry` IN (132, 800);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(26, 170, 132, 0, 0, 8, 0, 24490, 0, 0, 0, 0, 0, '', 'Set phase 170 in area 132 if quest 24490 rewarded'),
(26, 170, 800, 0, 0, 8, 0, 24490, 0, 0, 0, 0, 0, '', 'Set phase 170 in area 800 if quest 24490 rewarded');

-- 3. Milo, and the spell that calls him in.
--
-- The two spawns are scoped by guid, not by entry: 37198 has a second spawn at
-- -6390.2, 291.6, 461.4 that has nothing to do with this, and 37113's summoned
-- flight copy (37518) must stay visible to whoever is riding.  So this goes in
-- `creature_addon` per guid rather than `creature_template_addon`.
--
-- Auras are the sniffed pair.  70045 is the one that hides them.  70042 is
-- retail's rubble-detect, kept because it is what the sniff has on these two and
-- because it costs nothing; our phase is what actually reveals the rubble.
--
-- They are also put in phase 170, so they belong to the collapsed valley the
-- same way the rubble does.  The invisibility is what times Milo's *arrival*:
-- phase 170 lands at the turn-in of 24490, 70044 only at the accept of 24491,
-- and Milo is meant to show up on the signal, not on the collapse.
UPDATE `creature` SET `PhaseId`=170 WHERE `guid` IN (210115304, 10612185); -- Milo Geartwinge 37113, Milo's Gyro 37198

DELETE FROM `creature_addon` WHERE `guid` IN (210115304, 10612185);
INSERT INTO `creature_addon` (`guid`, `path_id`, `mount`, `StandState`, `AnimTier`, `VisFlags`, `SheathState`, `PvPFlags`, `emote`, `aiAnimKit`, `movementAnimKit`, `meleeAnimKit`, `visibilityDistanceType`, `auras`) VALUES
(210115304, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '70045 70042'), -- Milo Geartwinge
(10612185,  0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, '70045 70042'); -- Milo's Gyro

-- 70047 is cast when 24491 is accepted.  Player::AddQuest already does this from
-- quest_template_addon.SourceSpellID; the column was simply 0, so the player
-- never got 70044 and Milo would have stayed invisible forever.
UPDATE `quest_template_addon` SET `SourceSpellID`=70047 WHERE `ID`=24491; -- Follow that Gyro-Copter!

-- @touched: gameobject 210120200; creature 210115304,10612185;
-- @touched: creature_addon 210115304,10612185; quest_template_addon 24491;
-- @touched: phase_area (132,170),(800,170); conditions (26,170,132),(26,170,800)

-- 4. Bind Hands to the script that plays his cave-in line.
--
-- npc_hands_springsprocket is a CreatureScript, so it only ever runs if the name is
-- on the template. He has no AI of his own otherwise, and this does not give him one:
-- the script is a quest-reward hook, so his default ScriptedAI is untouched.
UPDATE `creature_template` SET `ScriptName`='npc_hands_springsprocket' WHERE `entry`=6782; -- Hands Springsprocket

-- @touched: creature_template 6782
