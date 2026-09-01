-- New Tinkertown: the Physician's Assistant faces its work at home.
--
-- 167917's orientation was worked out from the direction the last leg of its walk home
-- leaves it in, which is not what it actually stands at. The scene ends that walk with a
-- facing of its own -- 1.39626, a round 80 degrees -- which points it at the mat beside
-- it rather than off down the room.
--
-- The script puts this back on arrival by reading the spawn, so the value belongs here
-- and not in the script.

UPDATE `creature` SET `orientation`=1.3962633 WHERE `guid`=167917;
