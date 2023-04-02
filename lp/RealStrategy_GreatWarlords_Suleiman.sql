-- ===========================================================================
-- Real Strategy - main file for Great Warlords DLC - Alt Suleiman
-- Author: Infixo
-- 2023-04-02: Created
-- ===========================================================================


-- LEADER_SULEIMAN_ALT / OTTOMAN

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_SULEIMAN_ALT', 'LEADER', '', 'CONQUEST', 7),
('LEADER_SULEIMAN_ALT', 'LEADER', '', 'SCIENCE',  5),
('LEADER_SULEIMAN_ALT', 'LEADER', '', 'CULTURE',  3),
('LEADER_SULEIMAN_ALT', 'LEADER', '', 'RELIGION', 1),
('LEADER_SULEIMAN_ALT', 'LEADER', '', 'DIPLO',    1);

UPDATE AiFavoredItems SET Value = 15 WHERE ListType = 'SuliemanAltUnits' AND Item = 'PROMOTION_CLASS_SIEGE';

INSERT INTO AiListTypes (ListType) VALUES
('SuliemanAltYields'),
('SuliemanAltPseudoYields');
INSERT INTO AiLists (ListType, LeaderType, System) VALUES
('SuliemanAltYields',       'TRAIT_LEADER_SULEIMAN_ALT', 'Yields'),
('SuliemanAltPseudoYields', 'TRAIT_LEADER_SULEIMAN_ALT', 'PseudoYields');
INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
('SuliemanAltYields', 'YIELD_FAITH', 1, -20),
('SuliemanAltPseudoYields', 'PSEUDOYIELD_GPP_PROPHET', 1, -25),
('SuliemanAltPseudoYields', 'PSEUDOYIELD_GOLDENAGE_POINT', 1, 20),
('SuliemanAltPseudoYields', 'PSEUDOYIELD_CITY_DEFENSES', 1, -10); -- we have bombards
