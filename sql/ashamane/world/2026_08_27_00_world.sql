-- New Tinkertown: hand the sparring S.A.F.E. Operatives to the C++ AI.
--
-- npc_safe_operative_sparring never melees, which no database setting can achieve,
-- and shoots the nearest Crazed Leper Gnome instead. ScriptName is checked before
-- AIName in CreatureAISelector, so these seven spawns take the script while the
-- other 33 spawns of 45847 keep SmartAI.
--
-- Their smart_scripts rows go: the script does the shooting now. The two barkers
-- 984707 and 984708 keep theirs.
--
-- BaseAttackTime returns to 2000. The 9000 was only ever a way to make the gun
-- outnumber a melee swing that could not be suppressed.
UPDATE `creature_template` SET `BaseAttackTime`=2000 WHERE `entry`=45847;

UPDATE `creature` SET `ScriptName`='npc_safe_operative_sparring'
WHERE `id`=45847 AND `guid` IN (984705,984706,984710,984711,167627,167633,167938);

DELETE FROM `smart_scripts` WHERE `source_type`=0 AND `entryorguid` IN
 (-984705,-984706,-984710,-984711,-167627,-167633,-167938);
