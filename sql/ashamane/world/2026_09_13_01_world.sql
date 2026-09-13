-- New Tinkertown: three Gnomeregan Recruits haul ammo carts down the main road in
-- single file.
--
-- The column starts at Brewnall (-5411, 300) and takes the road the length of the
-- town, 590 yards, to (-5421, -288) where it leaves the zone and is gone; the next
-- three set off a few seconds later. 168770 is the leader and moves to the head of
-- the route; npc_gnomeregan_recruit_column summons the two behind it, their carts and
-- bunnies included, so the script goes on the template and the nine static spawns
-- of recruit, cart and bunny that stood along the road come out: they were this
-- column caught at three moments of one run, carts a step ahead of each recruit.
-- Needs a worldserver restart.

UPDATE `creature_template` SET `ScriptName`='npc_gnomeregan_recruit_column' WHERE `entry`=43276;

UPDATE `creature` SET `zoneId`=0, `areaId`=0, `position_x`=-5410.63, `position_y`=299.778, `position_z`=394.70734, `orientation`=4.39823, `MovementType`=0, `wander_distance`=0 WHERE `guid`=168770;

DELETE FROM `creature` WHERE `guid` IN (168771,168772,168773,168774,168775,168776,168777,168778,168851,168852,168853,168854,168855,168856,168857,168858,168859,168877,168878,168879,168880,168881,168882,168883,168884,168885);

-- @touched: creature,creature_template 168770,168771,168772,168773,168774,168775,168776,168777,168778,168851,168852,168853,168854,168855,168856,168857,168858,168859,168877,168878,168879,168880,168881,168882,168883,168884,168885
