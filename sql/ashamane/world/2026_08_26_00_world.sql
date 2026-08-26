-- New Tinkertown: rebuild the Crazed Leper Gnome (46363) spawn set from the retail sniff.
--
-- The zone had 78 spawns of 46363 against 42 that retail actually runs, so the
-- whole set is deleted and re-laid from the sniff rather than trimmed by hand.
--
-- Source: dump_12.1.0.69465_2026-08-24_18-06-03-Tinkertown-part1.pkt, retail
-- 12.1.0.69465, a single ~25 minute pass through New Tinkertown. WowPacketParser
-- has no opcode tables for this build, so the dump is raw hex and the coordinates
-- come from decoding the monster-move packets directly (see PACKET-DUMP-HANDOFF.md).
-- The build was registered in WPP as an alias of 69404 to get it to dump the hex at
-- all; the decode was then re-validated on this build before anything below was
-- written -- continuity median 0.136 yd, 93.4% of legs within 3 yd, 58.8% at the
-- 2.5 yd/s creature walk. Those are the numbers the layout was accepted on for
-- 69299, so the field offsets still fit.
--
-- 3,242 move packets for entry 46363 resolve to 57 spawn instances with four or
-- more real legs. A creature that dies comes back on a fresh guid counter, so
-- instances whose observation windows never overlap and whose roam centres sit
-- within 6 yd of each other are the same NPC respawning: folding those gives the
-- 42 spawn points below. Position is the weighted median of each spawn's own
-- observed destinations -- for a random-wander NPC the centre of the roam circle
-- is the spawn point, so that is the right estimator, not the first sighting.
--
-- wander_distance is that spawn's own 95th-percentile displacement from its centre,
-- kept per spawn rather than averaged to one number for the entry. Five of the 42
-- come out wide -- 75.9, 64.2, 54.6, 49.5 and 27.5 yd against a 9.3 yd median --
-- and those are most likely gnomes that were pulled or chased during the sniff
-- rather than genuinely wide roamers. They are written as measured, on the
-- explicit call to take the sniff as-is; if they roam too far in game, the fix is
-- to clamp those five rows to 9.3 and nothing else changes.
--
-- Orientation is not recoverable from move packets -- retail never sends a spawn
-- facing -- so each row takes the heading of that spawn's first observed leg.
-- For a MovementType=1 wanderer this only decides which way it faces for the first
-- few seconds after a respawn.
--
-- Coverage: every one of the 78 deleted spawns sits within 15 yd of an observed
-- roam centre, so the sniff saw the whole of the current footprint and this does
-- not leave a bald patch anywhere. It is still a lower bound -- a gnome that never
-- moved during the pass sends no move packets and would not appear here at all.
--
-- Deliberately left alone:
--   * entry 46391 (5 spawns, faction 14) -- the aggressive gnomes in front of the
--     old dormitory and the loading room. Separate entry, separate task.
--   * entry 46012 Target Acquisition Device (53 spawns) -- untouched. The gnomes
--     that were suspended in them were 46363 rows and are removed by the DELETE
--     below, which is the intent; the devices themselves keep every column.
--   * creature_template for 46363 -- speed_walk is already 0.64, which is exactly
--     the 1.6 yd/s the sniffed gnomes shuffle at, so nothing to change.
--
-- No formation, linked_respawn, pool, game_event or per-guid smart_scripts row
-- references any of the deleted guids -- all five were checked and are empty.
--
-- New guids are 984600-984641, a free contiguous block above the current
-- max guid below 1,000,000 (984521).
--
-- Adding creature rows needs a worldserver restart -- there is no .reload for the
-- spawn table.

-- The 16 addon rows carried the anim auras on a minority of spawns; the auras
-- move to creature_template_addon in the next file so every gnome gets them.
DELETE FROM `creature_addon` WHERE `guid` IN (
 168340,168363,168768,168792,168844,168895,168902,169200,169208,169211,
 169222,169233,169240,169241,169318,169334);

DELETE FROM `creature` WHERE `guid` IN (
 167635,168319,168338,168340,168363,168366,168749,168764,168768,168769,
 168781,168785,168792,168794,168805,168808,168811,168812,168822,168823,
 168825,168826,168834,168844,168895,168896,168902,168911,168925,168931,
 168932,168968,169112,169124,169125,169126,169134,169136,169183,169184,
 169186,169187,169189,169190,169191,169199,169200,169202,169203,169204,
 169205,169206,169207,169208,169211,169219,169221,169222,169229,169231,
 169233,169240,169241,169253,169256,169257,169258,169261,169263,169294,
 169301,169309,169318,169324,169334,169337,169338,169339);

INSERT INTO `creature` (`guid`,`id`,`map`,`zoneId`,`areaId`,`spawnDifficulties`,`phaseUseFlags`,`PhaseId`,`PhaseGroup`,`terrainSwapMap`,`modelid`,`equipment_id`,`position_x`,`position_y`,`position_z`,`orientation`,`spawntimesecs`,`wander_distance`,`currentwaypoint`,`curhealth`,`curmana`,`MovementType`,`npcflag`,`unit_flags`,`unit_flags2`,`unit_flags3`,`dynamicflags`,`ScriptName`,`VerifiedBuild`) VALUES
(984600,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5126.7986,768.8076,287.4157,3.6767,300,9.3,0,42,0,1,0,0,0,0,0,'',69465), -- 34 moves, 1 sniffed instance(s)
(984601,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5120.5747,755.1045,287.4513,3.4924,300,7.9,0,42,0,1,0,0,0,0,0,'',69465), -- 23 moves, 1 sniffed instance(s)
(984602,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5105.8486,761.1406,287.4904,5.0439,300,6.6,0,42,0,1,0,0,0,0,0,'',69465), -- 45 moves, 1 sniffed instance(s)
(984603,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5096.4697,756.2247,287.5355,2.6857,300,7.2,0,42,0,1,0,0,0,0,0,'',69465), -- 52 moves, 1 sniffed instance(s)
(984604,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5083.2017,778.6718,283.3875,5.1333,300,7.5,0,42,0,1,0,0,0,0,0,'',69465), -- 81 moves, 1 sniffed instance(s)
(984605,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5050.1001,769.901,283.3875,3.0682,300,75.9,0,42,0,1,0,0,0,0,0,'',69465), -- 20 moves, 1 sniffed instance(s)
(984606,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5046.7642,772.6444,283.3875,0.0,300,18.4,0,42,0,1,0,0,0,0,0,'',69465), -- 71 moves, 1 sniffed instance(s)
(984607,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5030.6528,775.127,283.7938,0.3602,300,54.6,0,42,0,1,0,0,0,0,0,'',69465), -- 23 moves, 1 sniffed instance(s)
(984608,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5024.7598,723.394,276.3875,0.0,300,27.5,0,42,0,1,0,0,0,0,0,'',69465), -- 37 moves, 1 sniffed instance(s)
(984609,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5021.7297,737.821,276.351,0.0,300,12.5,0,42,0,1,0,0,0,0,0,'',69465), -- 36 moves, 1 sniffed instance(s)
(984610,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5020.2656,755.6418,276.6386,0.0229,300,6.7,0,42,0,1,0,0,0,0,0,'',69465), -- 93 moves, 1 sniffed instance(s)
(984611,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5019.9948,781.2721,276.3875,2.1229,300,7.3,0,42,0,1,0,0,0,0,0,'',69465), -- 89 moves, 2 sniffed instance(s)
(984612,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5019.2615,729.1789,276.3875,0.0,300,9.4,0,42,0,1,0,0,0,0,0,'',69465), -- 40 moves, 1 sniffed instance(s)
(984613,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5017.8931,743.7597,276.3802,0.0,300,9.7,0,42,0,1,0,0,0,0,0,'',69465), -- 55 moves, 1 sniffed instance(s)
(984614,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5017.6817,797.2965,276.3875,3.4806,300,9.3,0,42,0,1,0,0,0,0,0,'',69465), -- 62 moves, 3 sniffed instance(s)
(984615,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5009.0627,790.4803,276.4347,0.9094,300,7.5,0,42,0,1,0,0,0,0,0,'',69465), -- 52 moves, 3 sniffed instance(s)
(984616,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5008.7846,818.3354,276.3875,0.0,300,10.8,0,42,0,1,0,0,0,0,0,'',69465), -- 59 moves, 2 sniffed instance(s)
(984617,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5007.8193,727.295,276.397,4.8736,300,8.5,0,42,0,1,0,0,0,0,0,'',69465), -- 67 moves, 1 sniffed instance(s)
(984618,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5002.4497,717.4216,276.4417,0.0,300,10.2,0,42,0,1,0,0,0,0,0,'',69465), -- 37 moves, 1 sniffed instance(s)
(984619,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5001.5044,751.4783,279.9969,4.5905,300,5.5,0,42,0,1,0,0,0,0,0,'',69465), -- 80 moves, 1 sniffed instance(s)
(984620,46363,0,1,5495,'0',0,0,0,-1,35025,0,-5000.6572,783.0983,280.0099,4.1765,300,7.2,0,42,0,1,0,0,0,0,0,'',69465), -- 54 moves, 4 sniffed instance(s)
(984621,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4999.7864,806.7556,276.3875,0.5341,300,10.4,0,42,0,1,0,0,0,0,0,'',69465), -- 76 moves, 1 sniffed instance(s)
(984622,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4997.3628,819.8016,276.3875,2.0759,300,8.8,0,42,0,1,0,0,0,0,0,'',69465), -- 107 moves, 1 sniffed instance(s)
(984623,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4996.1294,733.4733,277.0891,6.2387,300,6.9,0,42,0,1,0,0,0,0,0,'',69465), -- 90 moves, 1 sniffed instance(s)
(984624,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4994.9814,767.1358,288.5906,0.8268,300,8.3,0,42,0,1,0,0,0,0,0,'',69465), -- 48 moves, 2 sniffed instance(s)
(984625,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4992.6415,774.7109,288.4551,2.1653,300,13.6,0,42,0,1,0,0,0,0,0,'',69465), -- 36 moves, 3 sniffed instance(s)
(984626,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4987.2075,780.1032,283.8914,1.4663,300,49.5,0,42,0,1,0,0,0,0,0,'',69465), -- 35 moves, 1 sniffed instance(s)
(984627,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4984.8438,766.5307,288.6149,0.6844,300,11.7,0,42,0,1,0,0,0,0,0,'',69465), -- 50 moves, 2 sniffed instance(s)
(984628,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4984.7009,813.9656,276.4499,1.391,300,9.6,0,42,0,1,0,0,0,0,0,'',69465), -- 44 moves, 1 sniffed instance(s)
(984629,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4982.1968,712.4256,276.5453,0.0,300,15.5,0,42,0,1,0,0,0,0,0,'',69465), -- 35 moves, 1 sniffed instance(s)
(984630,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4978.0331,783.7961,279.9969,3.2799,300,9.2,0,42,0,1,0,0,0,0,0,'',69465), -- 80 moves, 3 sniffed instance(s)
(984631,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4977.9971,755.6264,279.9969,3.5803,300,6.2,0,42,0,1,0,0,0,0,0,'',69465), -- 101 moves, 1 sniffed instance(s)
(984632,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4977.1025,805.8516,276.501,0.0,300,7.5,0,42,0,1,0,0,0,0,0,'',69465), -- 123 moves, 1 sniffed instance(s)
(984633,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4973.2075,727.0336,276.3875,4.1073,300,6.4,0,42,0,1,0,0,0,0,0,'',69465), -- 38 moves, 1 sniffed instance(s)
(984634,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4969.4565,716.596,276.3875,0.0,300,10.7,0,42,0,1,0,0,0,0,0,'',69465), -- 79 moves, 1 sniffed instance(s)
(984635,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4968.8528,732.97,276.3875,0.0,300,9.3,0,42,0,1,0,0,0,0,0,'',69465), -- 8 moves, 1 sniffed instance(s)
(984636,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4967.4541,800.7003,276.4052,0.2621,300,8.4,0,42,0,1,0,0,0,0,0,'',69465), -- 131 moves, 1 sniffed instance(s)
(984637,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4964.4712,737.4164,276.3875,0.0,300,12.9,0,42,0,1,0,0,0,0,0,'',69465), -- 35 moves, 1 sniffed instance(s)
(984638,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4963.5112,812.024,276.3875,1.6858,300,8.7,0,42,0,1,0,0,0,0,0,'',69465), -- 103 moves, 1 sniffed instance(s)
(984639,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4963.2822,763.2754,276.4249,0.0,300,10.7,0,42,0,1,0,0,0,0,0,'',69465), -- 36 moves, 1 sniffed instance(s)
(984640,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4958.9712,792.3315,276.4298,0.3309,300,8.9,0,42,0,1,0,0,0,0,0,'',69465), -- 55 moves, 1 sniffed instance(s)
(984641,46363,0,1,5495,'0',0,0,0,-1,35025,0,-4955.1426,778.299,276.3875,4.5979,300,64.2,0,42,0,1,0,0,0,0,0,'',69465); -- 39 moves, 1 sniffed instance(s)

-- No `-- @touched:` line: wpp_apply.py's revert writes column UPDATEs against
-- guids that must already exist in `creature`, which cannot undo a DELETE plus a
-- re-INSERT on a fresh guid block. The undo for this file is the hand-written
-- snapshot in /home/serverproject/tinkertown-reverts/2026_08_26_gnomes_revert.sql,
-- taken before it was applied. Apply this file with mysql directly.
