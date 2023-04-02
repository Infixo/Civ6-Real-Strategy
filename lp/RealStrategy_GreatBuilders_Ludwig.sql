-- ===========================================================================
-- Real Strategy - main file for Great Builders DLC - Ludwig
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================

-- LEADER_LUDWIG / GERMANY / TRAIT_LEADER_LUDWIG

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_LUDWIG', 'LEADER', '', 'CONQUEST', 2),
('LEADER_LUDWIG', 'LEADER', '', 'SCIENCE',  5),
('LEADER_LUDWIG', 'LEADER', '', 'CULTURE',  9),
('LEADER_LUDWIG', 'LEADER', '', 'RELIGION', 1),
('LEADER_LUDWIG', 'LEADER', '', 'DIPLO',    5);


INSERT INTO AiListTypes (ListType) VALUES
('LudwigYields'),
('LudwigPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('LudwigYields',       'TRAIT_LEADER_LUDWIG', 'Yields'),
('LudwigPseudoYields', 'TRAIT_LEADER_LUDWIG', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('LudwigYields', 'YIELD_CULTURE', 1, 10),
('LudwigPseudoYields', 'PSEUDOYIELD_DISTRICT', 1, 10), -- more districts
('LudwigPseudoYields', 'PSEUDOYIELD_WONDER', 1, 20);
