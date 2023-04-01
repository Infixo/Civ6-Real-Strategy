-- ===========================================================================
-- Real Strategy - main file for Great Negotiators DLC
-- Author: Infixo
-- 2023-04-01: Created
-- ===========================================================================



-- LEADER_ABRAHAM_LINCOLN / AMERICA

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_ABRAHAM_LINCOLN', 'LEADER', '', 'CONQUEST', 3),
('LEADER_ABRAHAM_LINCOLN', 'LEADER', '', 'SCIENCE',  6),
('LEADER_ABRAHAM_LINCOLN', 'LEADER', '', 'CULTURE',  7),
('LEADER_ABRAHAM_LINCOLN', 'LEADER', '', 'RELIGION', 1),
('LEADER_ABRAHAM_LINCOLN', 'LEADER', '', 'DIPLO',    4);


INSERT INTO AiListTypes (ListType) VALUES
('LincolnDistricts'),
('LincolnUnitBuilds');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('LincolnDistricts',  'TRAIT_LEADER_LINCOLN', 'Districts'),
('LincolnUnitBuilds', 'TRAIT_LEADER_LINCOLN', 'UnitPromotionClasses');

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('LincolnDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 0), -- he must build IZs
('LincolnUnitBuilds', 'PROMOTION_CLASS_MELEE', 1, -50); -- don't build! we get them from IZs



-- LEADER_NZINGA_MBANDE / KONGO

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_NZINGA_MBANDE', 'LEADER', '', 'CONQUEST', 3),
('LEADER_NZINGA_MBANDE', 'LEADER', '', 'SCIENCE',  3),
('LEADER_NZINGA_MBANDE', 'LEADER', '', 'CULTURE',  7),
('LEADER_NZINGA_MBANDE', 'LEADER', '', 'RELIGION', 3),
('LEADER_NZINGA_MBANDE', 'LEADER', '', 'DIPLO',    3);

-- first fix buggy definitions
UPDATE AiFavoredItems SET ListType = 'NzingaCivics' WHERE ListType = 'NzingaWonders' AND Item = 'CIVIC_DRAMA_POETRY';
UPDATE AiFavoredItems SET ListType = 'NzingaCivics' WHERE ListType = 'NzingaWonders' AND Item = 'CIVIC_GUILDS';
UPDATE AiFavoredItems SET Value = -20 WHERE ListType = 'SettleOneContinent' AND Item = 'Foreign Continent'; -- wrong usage of Foreign Continent



-- LEADER_SALADIN_ALT / ARABIA

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_SALADIN_ALT', 'LEADER', '', 'CONQUEST', 5),
('LEADER_SALADIN_ALT', 'LEADER', '', 'SCIENCE',  4),
('LEADER_SALADIN_ALT', 'LEADER', '', 'CULTURE',  1),
('LEADER_SALADIN_ALT', 'LEADER', '', 'RELIGION', 6),
('LEADER_SALADIN_ALT', 'LEADER', '', 'DIPLO',    1);

-- reuse existing Saladin
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SaladinYields',       'TRAIT_LEADER_SALADIN_ALT', 'Yields'),
('SaladinPseudoYields', 'TRAIT_LEADER_SALADIN_ALT', 'PseudoYields');

