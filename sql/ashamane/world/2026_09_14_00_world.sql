-- "Down with Crushcog!" (26364) is level 5 content (quest_template QuestLevel 5,
-- MinLevel 2), and Crushcog's Guardian (42294) is correctly level 5 to match. But
-- Mekkatorque (42839 the mech, 42849 himself) and Stonegrind (42852) were level
-- 83/83/80 -- almost certainly a sniffing character's own level carried into the
-- template, the same trap as any other sniffed Level field. Against a level 5
-- guardian that gap makes every hit land and every guardian die in one or two swings
-- regardless of health tuning, which is why the fight reads as instant no matter how
-- much HP the guardians are given. Brought down to a modest, deliberate few levels
-- above the quest instead: still clearly outmatching the guardians, not a wall.
UPDATE `creature_template` SET `minlevel`=10, `maxlevel`=10 WHERE `entry` IN (42839, 42849);
UPDATE `creature_template` SET `minlevel`=8, `maxlevel`=8 WHERE `entry`=42852;
