-- ===========================================================================
-- Real Strategy - main file for Great Warlords DLC - Tokugawa
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================


-- LEADER_TOKUGAWA / JAPAN

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_TOKUGAWA', 'LEADER', '', 'CONQUEST', 1),
('LEADER_TOKUGAWA', 'LEADER', '', 'SCIENCE',  8),
('LEADER_TOKUGAWA', 'LEADER', '', 'CULTURE',  6),
('LEADER_TOKUGAWA', 'LEADER', '', 'RELIGION', 1),
('LEADER_TOKUGAWA', 'LEADER', '', 'DIPLO',    4);

INSERT INTO AiListTypes (ListType) VALUES
('TokugawaSettlement'),
('TokugawaPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('TokugawaSettlement', 'TRAIT_LEADER_TOKUGAWA', 'PlotEvaluations'),
('TokugawaPseudoYields', 'TRAIT_LEADER_TOKUGAWA', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('TokugawaSettlement', 'Nearest Friendly City', 0, -2), -- compact empire
('TokugawaPseudoYields', 'PSEUDOYIELD_DISTRICT',   1, 20), -- build a lot of districts
('TokugawaPseudoYields', 'PSEUDOYIELD_UNIT_TRADE', 1, 10); -- we like internal TRs
--('TokugawaPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, 100), -- not interested in conquest
--('TokugawaPseudoYields', 'PSEUDOYIELD_CITY_BASE',     1, -100); -- not interested in conquest
