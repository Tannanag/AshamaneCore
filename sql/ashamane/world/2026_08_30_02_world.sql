-- New Tinkertown: move the second tending Operative onto its post.
--
-- 169017 stood about 4.7 yards off, on a post that is not one of the three this camp
-- has. It moves onto the empty one and gets a casualty of its own to hold, 985000, set
-- against it at the same offset and height that 168987 sits against 168986.
--
-- 169004 does not move and is no longer the gnome 169017 holds. It stays a casualty
-- lying where it is.
--
-- 985000 gets no creature_addon row on purpose: creature_template_addon has 46447
-- lying down, which is what a held casualty wants, and a per-guid row would override
-- the whole template rather than merge with it.
--
-- Needs a worldserver restart.
UPDATE `creature`
SET `position_x`=-4989.83, `position_y`=870.15, `position_z`=274.39, `orientation`=0.34907
WHERE `guid`=169017 AND `id`=46449;

DELETE FROM `creature` WHERE `guid`=985000;
INSERT INTO `creature`
 (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`)
VALUES
 (985000,46447,0,1,5495,'0',0,0,0,-1,0,0,-4989.67,870.48,275.06,1.91986,300,0,0,55,0,0,0,0,0,0,0,'',0);
