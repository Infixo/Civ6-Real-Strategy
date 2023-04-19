-- ===========================================================================
-- Real Strategy - main file for Julius Caesar DLC
-- Author: Infixo
-- 2023-04-01: Created
-- ===========================================================================

-- LEADER_JULIUS_CAESAR / ROME

INSERT INTO RSTFlavors (ObjectType, Type, Subtype, Strategy, Value) VALUES
('LEADER_JULIUS_CAESAR', 'LEADER', '', 'CONQUEST', 7),
('LEADER_JULIUS_CAESAR', 'LEADER', '', 'SCIENCE',  4),
('LEADER_JULIUS_CAESAR', 'LEADER', '', 'CULTURE',  3),
('LEADER_JULIUS_CAESAR', 'LEADER', '', 'RELIGION', 1),
('LEADER_JULIUS_CAESAR', 'LEADER', '', 'DIPLO',    1);

UPDATE AiFavoredItems SET Value = 15 WHERE ListType = 'GallicWarsClearingBarbCampPreference' AND Item = 'PSEUDOYIELD_CLEAR_BANDIT_CAMPS'; -- def. 5

-- Let's try to make Caesar value each city the same... maybe he will attack not only capitals
-- city-base is 450, city-cap is 200
-- aggressive yields give +40% to base
-- normal city is then 450*1,4=630, capital is 830
-- need to remove the capital part?

-- 230419 Now capital has a malus...
--INSERT INTO AiListTypes (ListType) VALUES
--('CasearPseudoYields');
--INSERT INTO AiLists (ListType, LeaderType, System) VALUES
--('CasearPseudoYields', 'TRAIT_LEADER_CAESAR', 'PseudoYields');
--INSERT INTO AiFavoredItems (ListType, Item, Favored, Value) VALUES
--('CasearPseudoYields', 'PSEUDOYIELD_CITY_BASE', 1, 10), -- +50% in tot
--('CasearPseudoYields', 'PSEUDOYIELD_CITY_ORIGINAL_CAPITAL', 1, -100); -- should be 0?
