-- New Tinkertown: turn the east firing squad to face its drop point.
--
-- The four spawns of this line carried 6.1959, the same value as the line on the west
-- platform, but their drop point is on the opposite side of them -- so they stood with
-- their backs to it. 3.0543 is 6.1959 turned through pi, which keeps the same offset
-- from the drop bearing that the west line has.

UPDATE `creature` SET `orientation`=3.0543 WHERE `guid` IN (167940,167941,167942,167943);
