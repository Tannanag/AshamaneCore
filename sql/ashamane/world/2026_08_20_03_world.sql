-- Coldridge Valley: clear the tunnel when the player flies out, and leave Milo
-- behind when it clears.
--
-- 2026_08_19_00_world.sql brought the Kharanos tunnel down by putting the rubble
-- (gameobject 201711, guid 210120200) in phase 170 and granting that phase in
-- areas 132 and 800 once quest 24490 "A Trip to Ironforge" is rewarded. It never
-- wrote the other half: nothing ever takes the phase away. A player who finishes
-- the chain, rides out to Kharanos and walks back finds the valley still sealed
-- and no way through it, because the gyro is a one-shot -- 24492's reward spell
-- summons a private copy, and the parked one is no longer clickable
-- (2026_08_20_02_world.sql).
--
-- Milo and his gyro were put in phase 170 as well, "so they belong to the
-- collapsed valley the same way the rubble does". That was decorative -- what
-- actually times Milo's arrival is invisibility 70045 on him against detect
-- 70044 on the player, handed out when 24491 is accepted -- and it becomes
-- actively wrong the moment the phase can end, because ending it would take Milo
-- and his gyro out of the world along with the rubble.

-- 1. End the phase when the player flies out.
--
-- The trigger is 24492 "Pack Your Bags" being rewarded, not 24491. 24491 is only
-- "report to Milo" and is turned in before the ride; 24492's turn-in is the ride
-- (RewardSpell 70032 -> FORCE_CAST 70035 -> vehicle summon + 70036 "Riding
-- Milo's Gyro"), so rewarding it is the same instant the player leaves.
--
-- Conditions in one ElseGroup are ANDed and separate ElseGroups are ORed
-- (ConditionMgr::IsObjectMeetToConditionList, ConditionMgr.cpp:827), so this row
-- goes in ElseGroup 0 next to the existing 24490 row: phase 170 applies while
-- 24490 is rewarded AND 24492 is not.
--
-- The phase is recomputed on the spot rather than at the next area change --
-- Player::RewardQuest ends with SendQuestUpdate, which calls
-- PhasingHandler::OnConditionChange (Player.cpp:16904). Note the ordering there:
-- the reward spell is cast first (Player.cpp:16089) and the phase update follows,
-- so the summoned gyro inherits the player's shift while it still carries 170
-- while the player himself drops to 169. Both still count as Unphased, since
-- PhasingHandler sets that flag for any shift holding DEFAULT_PHASE 169
-- (PhasingHandler.cpp:450), and PhaseShift::CanSee returns true for two Unphased
-- shifts on its first line -- so the player does not fall off the vehicle
-- mid-hand-off.
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=26 AND `SourceGroup`=170 AND `SourceEntry` IN (132, 800) AND `ConditionTypeOrReference`=8 AND `ConditionValue1`=24492;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(26, 170, 132, 0, 0, 8, 0, 24492, 0, 0, 1, 0, 0, '', 'Drop phase 170 in area 132 once quest 24492 rewarded - tunnel is clear again'),
(26, 170, 800, 0, 0, 8, 0, 24492, 0, 0, 1, 0, 0, '', 'Drop phase 170 in area 800 once quest 24492 rewarded - tunnel is clear again');

-- 2. Take Milo and his gyro back out of that phase, so the valley keeps them.
--
-- PhaseId 0 leaves a spawn with an empty phase shift, which PhasingHandler flags
-- Unphased, and every player standing in 132 or 800 is Unphased too because
-- `phase_area` grants them 169 unconditionally there. So both are visible before
-- the collapse, during it and after it, and the only thing still deciding when
-- Milo is *seen* is the invisibility pair he was always meant to be gated by.
--
-- Scoped to these two guids: 37198 also has a parked spawn at -6390.2, 291.6,
-- 461.4 (guid 10610917) that is already PhaseId 0 and unrelated, and the flight
-- copy is summoned rather than spawned.
UPDATE `creature` SET `PhaseId`=0 WHERE `guid` IN (210115304, 10612185); -- Milo Geartwinge 37113, Milo's Gyro 37198

-- Left in phase 170 on purpose: gameobject 210120200, the rubble itself. It is
-- the only thing that should come and go with the phase.

-- @touched: conditions (26,170,132),(26,170,800); creature 210115304,10612185
