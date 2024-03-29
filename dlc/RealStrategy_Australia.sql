-- ===========================================================================
-- Real Strategy - main file for Australia DLC
-- Author: Infixo
-- 2019-01-05: Created
-- 2023-04-19: Removal of Start Biases, use Real Fixes or Better Balance Start
-- ===========================================================================

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES -- generated from Excel
('LEADER_JOHN_CURTIN', 'LEADER', '', 'CONQUEST', 3),
('LEADER_JOHN_CURTIN', 'LEADER', '', 'SCIENCE',  7),
('LEADER_JOHN_CURTIN', 'LEADER', '', 'CULTURE',  5),
('LEADER_JOHN_CURTIN', 'LEADER', '', 'RELIGION', 1),
('LEADER_JOHN_CURTIN', 'LEADER', '', 'DIPLO',    3);


-- LEADER_JOHN_CURTIN / AUSTRALIA

DELETE FROM LeaderTraits WHERE LeaderType = 'LEADER_JOHN_CURTIN' AND TraitType = 'TRAIT_LEADER_SCIENCE_MAJOR_CIV'; -- 210623 not needed

INSERT INTO AiListTypes (ListType) VALUES
('CurtinSettlement'),
--('CurtinDiplomacy'), -- 2019-06-25 Added in June 2019 Patch
('CurtinPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('CurtinSettlement',   'TRAIT_LEADER_CITADEL_CIVILIZATION', 'PlotEvaluations'),
--('CurtinDiplomacy',    'TRAIT_LEADER_CITADEL_CIVILIZATION', 'DiplomaticActions'),
('CurtinPseudoYields', 'TRAIT_LEADER_CITADEL_CIVILIZATION', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('CurtinSettlement', 'Coastal', 0, 10),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_LIBERATION_WAR', 1, 0),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_PROTECTORATE_WAR', 1, 0),
('CurtinDiplomacy', 'DIPLOACTION_DECLARE_RECONQUEST_WAR', 1, 0),
--('CurtinDiplomacy', 'DIPLOACTION_LIBERATE_CITY', 1, 0), -- 2019-06-25 Added in June 2019 Patch
('CurtinPseudoYields', 'PSEUDOYIELD_IMPROVEMENT', 1, 15), -- outback station
--('CurtinPseudoYields', 'PSEUDOYIELD_TOURISM', 1, 10),     -- 2019-04-04 Firaxis wants him more sciency
('CurtinPseudoYields', 'PSEUDOYIELD_GPP_SCIENTIST', 1, 15), -- 2019-04-04 Firaxis wants him more sciency
('CurtinPseudoYields', 'PSEUDOYIELD_ENVIRONMENT', 1, 20);
