-- ===========================================================================
-- Real Strategy - main file for Rulers of China DLC
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================


-- LEADER_YONGLE / CHINA / TRAIT_LEADER_YONGLE

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_YONGLE', 'LEADER', '', 'CONQUEST', 2),
('LEADER_YONGLE', 'LEADER', '', 'SCIENCE',  7),
('LEADER_YONGLE', 'LEADER', '', 'CULTURE',  6),
('LEADER_YONGLE', 'LEADER', '', 'RELIGION', 1),
('LEADER_YONGLE', 'LEADER', '', 'DIPLO',    1);

DELETE FROM AiFavoredItems WHERE ListType = 'YongleTechs';
DELETE FROM AiLists WHERE ListType = 'YongleTechs';
DELETE FROM AiListTypes WHERE ListType = 'YongleTechs';

INSERT OR REPLACE INTO AiListTypes (ListType) VALUES
('YongleYields'),
('YongleProjects');
INSERT OR REPLACE INTO AiLists (ListType, LeaderType, System) VALUES
('YongleYields',   'TRAIT_LEADER_YONGLE', 'Yields'),
('YongleProjects', 'TRAIT_LEADER_YONGLE', 'Projects');
INSERT OR REPLACE INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('YongleYields', 'YIELD_FOOD', 1, 15),
('YongleProjects', 'PROJECT_LIJIA_FOOD', 1, 0),
('YongleWonders', 'BUILDING_HANGING_GARDENS', 1, 0);

-- XP1 Tier3 gov building
INSERT INTO AiFavoredItems (ListType, Item, Favored)
SELECT 'YongleWonders', 'BUILDING_GOV_SCIENCE', 1
WHERE EXISTS (SELECT * FROM Buildings WHERE BuildingType = 'BUILDING_GOV_SCIENCE');



-- LEADER_WU_ZETIAN / CHINA / TRAIT_LEADER_WU_ZETIAN

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_WU_ZETIAN', 'LEADER', '', 'CONQUEST', 2),
('LEADER_WU_ZETIAN', 'LEADER', '', 'SCIENCE',  5),
('LEADER_WU_ZETIAN', 'LEADER', '', 'CULTURE',  7),
('LEADER_WU_ZETIAN', 'LEADER', '', 'RELIGION', 1),
('LEADER_WU_ZETIAN', 'LEADER', '', 'DIPLO',    1);

DELETE FROM AiFavoredItems WHERE ListType = 'WuZetianTechs';
DELETE FROM AiLists WHERE ListType = 'WuZetianTechs';
DELETE FROM AiListTypes WHERE ListType = 'WuZetianTechs';

INSERT INTO AiListTypes (ListType) VALUES
('WuZetianDiplomacy');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('WuZetianDiplomacy', 'TRAIT_LEADER_WU_ZETIAN', 'DiplomaticActions');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('WuZetianDiplomacy', 'DIPLOACTION_KEEP_PROMISE_DONT_SPY', 0, 0);

-- XP1 Tier2 gov building
INSERT INTO AiFavoredItems (ListType, Item, Favored)
SELECT 'WuZetianWonders', 'BUILDING_GOV_SPIES', 1
WHERE EXISTS (SELECT * FROM Buildings WHERE BuildingType = 'BUILDING_GOV_SPIES');



-- LEADER_QIN_ALT / CHINA / TRAIT_LEADER_QIN

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_QIN_ALT', 'LEADER', '', 'CONQUEST', 4),
('LEADER_QIN_ALT', 'LEADER', '', 'SCIENCE',  4),
('LEADER_QIN_ALT', 'LEADER', '', 'CULTURE',  6),
('LEADER_QIN_ALT', 'LEADER', '', 'RELIGION', 1),
('LEADER_QIN_ALT', 'LEADER', '', 'DIPLO',    1);

DELETE FROM AiFavoredItems WHERE ListType = 'QinAltTechs';
DELETE FROM AiLists WHERE ListType = 'QinAltTechs';
DELETE FROM AiListTypes WHERE ListType = 'QinAltTechs';

UPDATE AiFavoredItems SET Value = 25 WHERE ListType = 'QinAltUnits' AND Item = 'PROMOTION_CLASS_MELEE';

INSERT INTO AiListTypes (ListType) VALUES
('QinAltCivics');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('QinAltCivics', 'TRAIT_LEADER_QIN', 'Civics');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('QinAltCivics', 'CIVIC_CRAFTSMANSHIP', 1, 0),
('QinAltCivics', 'CIVIC_FEUDALISM',     1, 0);
