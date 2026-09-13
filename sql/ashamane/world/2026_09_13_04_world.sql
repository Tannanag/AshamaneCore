-- Gnomeregan: the GS-9x Multi-Bot is dismissed when "A Job for the Multi-Bot" is turned in.
--
-- 79435 is the reward spell for 26205; its script effect had nothing behind it, and
-- without an entry condition its 60 yard area target picked up everything. Grindspark's
-- existing quest-reward row keeps casting it.

DELETE FROM `spell_script_names` WHERE `spell_id`=79435;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(79435, 'spell_despawn_multi_bot');

DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId`=13 AND `SourceEntry`=79435;
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(13, 1, 79435, 0, 0, 31, 0, 3, 42598, 0, 0, 0, 0, '', 'Despawn GS-9x Multibot - targets GS-9x Multi-Bot');

-- @touched: spell_script_names 79435; conditions 13/79435
