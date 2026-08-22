
-- Coldridge Valley: drop the Wrath-era trainer options, and lift the monk trainer
-- out of the floor.
--
-- Five of the eight class trainers still carried "I wish to unlearn my talents."
-- and "I wish to know about Dual Talent Specialization." The dual-spec row is typed
-- 1 (GOSSIP_OPTION_GOSSIP) rather than 18, so the hard-disable in
-- Player::PrepareGossipMenu never catches it and it renders as an ordinary line into
-- the 3.3.5 explainer menu. Neither has been trainer business since 4.0.
--
-- Each of the five menus belongs to one creature with one spawn in area 132, so this
-- is Coldridge-only despite touching a shared table. Option 0 (train) and 4676's
-- "<Take the letter>" are kept; menus 4461 and 10371 are shared and left alone.
DELETE FROM `gossip_menu_option`        WHERE `MenuId` IN (4675, 4676, 4678, 4679, 4684) AND `OptionIndex` IN (1, 2);
DELETE FROM `gossip_menu_option_action` WHERE `MenuId` IN (4675, 4676, 4678, 4679, 4684) AND `OptionIndex` IN (1, 2);
DELETE FROM `gossip_menu_option_box`    WHERE `MenuId` IN (4675, 4676, 4678, 4679, 4684) AND `OptionIndex` IN (1, 2);
DELETE FROM `gossip_menu_option_locale` WHERE `MenuId` IN (4675, 4676, 4678, 4679, 4684) AND `OptionIndex` IN (1, 2);

-- 2. Lo, the monk trainer, was buried to the knees. The spawn was hand-placed --
--    x, y, z all whole numbers, orientation 1, VerifiedBuild 0 -- with z a notch
--    low. The Anvilmar floor there is flat and well witnessed; the nearest is
--    Coldridge Citizen 167010, 3.31 yd away on 395.543.
UPDATE `creature` SET `position_z`=395.543 WHERE `guid`=210112024; -- Lo 63285, Monk Trainer
