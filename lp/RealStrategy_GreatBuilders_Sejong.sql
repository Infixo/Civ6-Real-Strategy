-- ===========================================================================
-- Real Strategy - main file for Great Builders DLC - Sejong
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================

-- LEADER_SEJONG / KOREA / TRAIT_LEADER_SEJONG

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_SEJONG', 'LEADER', '', 'CONQUEST', 3),
('LEADER_SEJONG', 'LEADER', '', 'SCIENCE',  9),
('LEADER_SEJONG', 'LEADER', '', 'CULTURE',  3),
('LEADER_SEJONG', 'LEADER', '', 'RELIGION', 1),
('LEADER_SEJONG', 'LEADER', '', 'DIPLO',    3);

INSERT INTO AiListTypes (ListType) VALUES
('SejongPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SejongPseudoYields', 'TRAIT_LEADER_SEJONG', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('SejongPseudoYields', 'PSEUDOYIELD_TECHNOLOGY', 1, 25); -- testing?
