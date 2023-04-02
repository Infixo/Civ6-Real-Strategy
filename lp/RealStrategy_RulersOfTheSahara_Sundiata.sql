-- ===========================================================================
-- Real Strategy - main file for Rulers of The Sahara DLC - Sundiata Keita
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================

-- LEADER_SUNDIATA_KEITA / MALI / TRAIT_LEADER_SUNDIATA_KEITA

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_SUNDIATA_KEITA', 'LEADER', '', 'CONQUEST', 2),
('LEADER_SUNDIATA_KEITA', 'LEADER', '', 'SCIENCE',  2),
('LEADER_SUNDIATA_KEITA', 'LEADER', '', 'CULTURE',  8),
('LEADER_SUNDIATA_KEITA', 'LEADER', '', 'RELIGION', 2),
('LEADER_SUNDIATA_KEITA', 'LEADER', '', 'DIPLO',    4);

-- fix wrong assignments
UPDATE AiLists SET LeaderType = 'TRAIT_LEADER_SUNDIATA_KEITA' WHERE ListType IN ('KeitaGreatWorks','KeitaCivics','KeitaTechs','KeitaWonders');

INSERT INTO AiListTypes (ListType) VALUES
('KeitaYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('KeitaYields', 'TRAIT_LEADER_SUNDIATA_KEITA', 'Yields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('KeitaYields', 'YIELD_GOLD', 1, 20),
('KeitaGreatWorks', 'PSEUDOYIELD_GPP_WRITER', 1, 20);
