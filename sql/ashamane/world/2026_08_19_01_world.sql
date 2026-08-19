-- Coldridge Valley: put the default phase back under the collapsed-tunnel phase.
--
-- Fixes 2026_08_19_00_world.sql, which gave the player phase 170 in areas 132 and
-- 800 and emptied the zone: after turning 24490 in, the rubble and Milo were the
-- only things left standing.
--
-- PhaseShift::CanSee only short-circuits to "visible" when *both* sides are
-- Unphased; otherwise it needs the two phase sets to intersect. And
-- PhaseShift::UpdateUnphasedFlag sets Unphased as
--
--     if (NonCosmeticReferences && !DefaultReferences)  clear Unphased
--     else                                              set Unphased
--
-- with DEFAULT_PHASE 169 being the only id that counts toward DefaultReferences.
-- So a player holding {170} and nothing else is no longer Unphased, every
-- ordinary spawn in Coldridge is (PhasingHandler::InitDbPhaseShift sets Unphased
-- when PhaseId is 0), and the two sets do not intersect -- so all 333 of them
-- disappear.
--
-- Holding {169, 170} instead keeps DefaultReferences at 1, so the player stays
-- Unphased and still sees everything unphased, while the intersection on 170
-- adds the rubble and Milo on top. That is what the existing rows in this table
-- are doing where they read "Mardum Default Phase" and "Tanaan Default Phase".
--
-- No conditions on these rows: ConditionMgr::IsObjectMeetToConditions returns
-- true for an empty list, so 169 is granted to everyone in the two areas, which
-- is the state the zone was in before 2026_08_19_00 and is what makes that file
-- a no-op for anyone who has not done the quest.
DELETE FROM `phase_area` WHERE `AreaId` IN (132, 800) AND `PhaseId`=169;
INSERT INTO `phase_area` (`AreaId`, `PhaseId`, `Comment`) VALUES
(132, 169, 'Coldridge Valley - default phase, so phase 170 adds to the world instead of replacing it'),
(800, 169, 'Coldridge Pass - default phase, so phase 170 adds to the world instead of replacing it');

-- Side effect worth naming: gameobject 21006022, a Copper Vein at -5965, 19.9,
-- 371.1 in Coldridge Pass, is spawned with PhaseId 169. Nothing granted 169 in
-- area 800 until now, so that node has been invisible to every player. It comes
-- back with this. That is the right outcome for an ore node, and it is the only
-- spawn in either area carrying a phase besides the two this branch set.

-- @touched: phase_area (132,169),(800,169)
