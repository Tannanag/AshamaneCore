-- Coldridge Valley: the three Coldridge Mountaineer patrollers keep the template aura.
-- A creature_addon row replaces creature_template_addon outright, and the
-- August path rows left auras NULL, dropping 18950 from these three spawns.
UPDATE `creature_addon` SET `auras`='18950' WHERE `guid` IN (166972,166975,167026);

-- @touched: creature_addon 166972,166975,167026
