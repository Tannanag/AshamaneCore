-- New Tinkertown: the S.A.F.E. Operative carrying injured gnomes to the bed.
--
-- 169286 carries an Injured Gnome down to the bed, sets it down, walks back and
-- despawns, on a loop of about 65 seconds. Retail runs the scene the same way.
--
-- 169319 goes with it. The script summons the gnome it sets down, at 169319's exact
-- position, so leaving the static spawn in place would put two gnomes in one bed.
--
-- Needs a worldserver restart.
UPDATE `creature` SET `ScriptName`='npc_safe_operative_carrier'
WHERE `guid`=169286 AND `id`=46449;

DELETE FROM `creature_addon` WHERE `guid`=169319;
DELETE FROM `creature` WHERE `guid`=169319;
