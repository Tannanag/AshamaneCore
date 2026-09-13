-- Crushcog Sentry-Bot: the Paintinator shuts it down over five seconds
UPDATE `creature_template` SET `AIName`='', `ScriptName`='npc_crushcog_sentry_bot' WHERE `entry`=42291;
DELETE FROM `smart_scripts` WHERE `entryorguid`=42291 AND `source_type`=0;
UPDATE `creature_text` SET `BroadcastTextId`=42702, `Sound`=10571, `comment`='Crushcog Sentry-Bot - shuts down' WHERE `CreatureID`=42291 AND `GroupID`=0 AND `ID`=0;
