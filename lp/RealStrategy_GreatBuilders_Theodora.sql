-- ===========================================================================
-- Real Strategy - main file for Great Builders DLC - Theodora
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================

-- LEADER_THEODORA / BYZANTIUM / TRAIT_LEADER_THEODORA

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_THEODORA', 'LEADER', '', 'CONQUEST', 4),
('LEADER_THEODORA', 'LEADER', '', 'SCIENCE',  1),
('LEADER_THEODORA', 'LEADER', '', 'CULTURE',  6),
('LEADER_THEODORA', 'LEADER', '', 'RELIGION', 8),
('LEADER_THEODORA', 'LEADER', '', 'DIPLO',    1);

INSERT INTO AiListTypes (ListType) VALUES
('TheodoraDistricts'),
('TheodoraPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('TheodoraDistricts',    'TRAIT_LEADER_THEODORA', 'Districts'),
('TheodoraPseudoYields', 'TRAIT_LEADER_THEODORA', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('TheodoraDistricts', 'DISTRICT_HOLY_SITE', 1, 0),
('TheodoraPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15),
('TheodoraPseudoYields', 'PSEUDOYIELD_HAPPINESS', 1, 15);
