-- New Tinkertown: the doubled S.A.F.E. Technician in the Loading Room goes.

-- 169037 and 168135 are the same technician twice. They stand 0.20 yards apart at the
-- same height, on the same orientation of 4.06662, both posed with emote 233, so the two
-- models sit inside one another and the room shows one flickering worker rather than two.
-- 168135 stays and keeps the post.
--
-- That leaves nine technicians in the room, which is what the spread of positions holds.

DELETE FROM `creature_addon` WHERE `guid`=169037;
DELETE FROM `creature` WHERE `guid`=169037;
