-- New Tinkertown: the spare S.A.F.E. Officer in the Loading Room goes.

-- 167812 stood a yard off point 18 of 168990's round, so with that patrol in the officer
-- now walks through his double. He was a stand-in for a stretch of it and is surplus.
--
-- 167810 keeps his post. He stands ten yards clear of the route and is not a stand-in
-- for any part of it.
--
-- Nothing else referenced the spawn -- no addon, formation, pool or event row.

DELETE FROM `creature_addon` WHERE `guid`=167812;
DELETE FROM `creature` WHERE `guid`=167812;
