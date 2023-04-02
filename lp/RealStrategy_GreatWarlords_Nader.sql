-- ===========================================================================
-- Real Strategy - main file for Great Warlords DLC - Nader Shah
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================


-- LEADER_NADER_SHAH / PERSIA

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_NADER_SHAH', 'LEADER', '', 'CONQUEST', 7),
('LEADER_NADER_SHAH', 'LEADER', '', 'SCIENCE',  3),
('LEADER_NADER_SHAH', 'LEADER', '', 'CULTURE',  5),
('LEADER_NADER_SHAH', 'LEADER', '', 'RELIGION', 1),
('LEADER_NADER_SHAH', 'LEADER', '', 'DIPLO',    1);

INSERT INTO AiListTypes (ListType) VALUES
('NaderPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('NaderPseudoYields', 'TRAIT_LEADER_NADER_SHAH', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('NaderPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- pairidaeza
('NaderPseudoYields', 'PSEUDOYIELD_CITY_DEFENDING_UNITS', 1, -20),
('NaderPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 30);
