-- ===========================================================================
-- Real Strategy - main file for Rulers of The Sahara DLC - Ramses and Alt Cleopatra
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================

-- LEADER_RAMSES / EGYPT / TRAIT_LEADER_RAMSES

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_RAMSES', 'LEADER', '', 'CONQUEST', 1),
('LEADER_RAMSES', 'LEADER', '', 'SCIENCE',  1),
('LEADER_RAMSES', 'LEADER', '', 'CULTURE',  8),
('LEADER_RAMSES', 'LEADER', '', 'RELIGION', 2),
('LEADER_RAMSES', 'LEADER', '', 'DIPLO',    5);

UPDATE AiLists SET LeaderType = 'TRAIT_LEADER_RAMSES' WHERE ListType = 'RamsesTechs'; -- fix

UPDATE AiFavoredItems SET Value = 10 WHERE ListType = 'MaatLoverExploitationPreference' AND Item = 'PSEUDOYIELD_IMPROVEMENT';

--INSERT INTO AiListTypes (ListType) VALUES
--('RamsesYields');
--INSERT INTO AiLists (ListType, LeaderType, System) VALUES
--('RamsesYields', 'TRAIT_LEADER_RAMSES', 'Yields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
--('RamsesYields', 'YIELD_CULTURE', 1, -10),
--('RamsesYields', 'YIELD_PRODUCTION', 1, 10),
('MaatLoverExploitationPreference', 'PSEUDOYIELD_ENVIRONMENT', 1, -10);


-- LEADER_CLEOPATRA_ALT / EGYPT / TRAIT_LEADER_CLEOPATRA_ALT

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_CLEOPATRA_ALT', 'LEADER', '', 'CONQUEST', 1),
('LEADER_CLEOPATRA_ALT', 'LEADER', '', 'SCIENCE',  3),
('LEADER_CLEOPATRA_ALT', 'LEADER', '', 'CULTURE',  7),
('LEADER_CLEOPATRA_ALT', 'LEADER', '', 'RELIGION', 2),
('LEADER_CLEOPATRA_ALT', 'LEADER', '', 'DIPLO',    5);

UPDATE AiLists SET LeaderType = 'TRAIT_LEADER_CLEOPATRA_ALT' WHERE ListType = 'CleopatraAltTechs'; 
