-- New Tinkertown: the Ammo Cart Bunny loses its second model.
--
-- 43279 carried two models, 20570 and 22769, and CreatureTemplate::GetRandomValidModelId
-- picks between them evenly. 20570 is a shared placeholder display -- some sixty unrelated
-- marker and anchor creatures list it -- and at CreatureDisplayInfo scale 1.25 against
-- 22769's 0.35 it is drawn several times the size of the cart it is meant to sit on.
--
-- All 19 authored 43279 spawns pin `creature`.`modelid` 22769, so the bad model never
-- showed until the recruit columns began summoning bunnies: a summon has no `creature` row
-- and falls through to the template roll.

UPDATE `creature_template` SET `modelid1`=22769, `modelid2`=0 WHERE `entry`=43279;
