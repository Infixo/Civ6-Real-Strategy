-- ===========================================================================
-- Real Strategy - main file for Rulers of England DLC
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================


--LEADER_ELIZABETH / ENGLAND

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_ELIZABETH', 'LEADER', '', 'CONQUEST', 3),
('LEADER_ELIZABETH', 'LEADER', '', 'SCIENCE',  6),
('LEADER_ELIZABETH', 'LEADER', '', 'CULTURE',  3),
('LEADER_ELIZABETH', 'LEADER', '', 'RELIGION', 1),
('LEADER_ELIZABETH', 'LEADER', '', 'DIPLO',    7);

INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('ElizabethCivics', 'CIVIC_FOREIGN_TRADE', 1, 0),
('ElizabethPseudoYields', 'PSEUDOYIELD_GPP_ADMIRAL', 1, 15);


--LEADER_HARALD_ALT / NORWAY

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_HARALD_ALT', 'LEADER', '', 'CONQUEST', 8),
('LEADER_HARALD_ALT', 'LEADER', '', 'SCIENCE',  3),
('LEADER_HARALD_ALT', 'LEADER', '', 'CULTURE',  3),
('LEADER_HARALD_ALT', 'LEADER', '', 'RELIGION', 3),
('LEADER_HARALD_ALT', 'LEADER', '', 'DIPLO',    1);



--LEADER_VICTORIA_ALT / ENGLAND / TRAIT_LEADER_VICTORIA_ALT

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_VICTORIA_ALT', 'LEADER', '', 'CONQUEST', 5),
('LEADER_VICTORIA_ALT', 'LEADER', '', 'SCIENCE',  8),
('LEADER_VICTORIA_ALT', 'LEADER', '', 'CULTURE',  3),
('LEADER_VICTORIA_ALT', 'LEADER', '', 'RELIGION', 1),
('LEADER_VICTORIA_ALT', 'LEADER', '', 'DIPLO',    5);

INSERT INTO AiListTypes (ListType) VALUES
('VictoriaAltYields'),
('VictoriaAltDistricts');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('VictoriaAltYields',    'TRAIT_LEADER_VICTORIA_ALT', 'Yields'),
('VictoriaAltDistricts', 'TRAIT_LEADER_VICTORIA_ALT', 'Districts');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('VictoriaAltTechs', 'TECH_APPRENTICESHIP', 1, 0),
('VictoriaAltTechs', 'TECH_INDUSTRIALIZATION', 1, 0),
('VictoriaAltYields', 'YIELD_PRODUCTION', 1, 10),
('VictoriaAltDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 0);
