print("Loading RealStrategy.lua from Real Strategy version "..GlobalParameters.RST_VERSION_MAJOR.."."..GlobalParameters.RST_VERSION_MINOR);
-- ===========================================================================
-- Real Strategy
-- 2018-12-14: Created by Infixo
-- 2019-03-09: Gathering Storm update
-- ===========================================================================

include("Serialize");

-- InGame functions exposed here
if not ExposedMembers.RST then ExposedMembers.RST = {} end;
local RST = ExposedMembers.RST;

-- Expansions check
local bIsRiseFall:boolean = (Game.ChangePlayerEraScore ~= nil); --Modding.IsModActive("1B28771A-C749-434B-9053-D1380C553DE9"); -- Rise & Fall
print("Rise & Fall", (bIsRiseFall and "YES" or "no"));
local bIsGatheringStorm:boolean = (GameClimate ~= nil); --Modding.IsModActive("4873eb62-8ccc-4574-b784-dda455e74e68"); -- Gathering Storm
print("Gathering Storm:", (bIsGatheringStorm and "YES" or "no"));

-- logging options
local bLogDebug:boolean = ( GlobalParameters.RST_OPTION_LOG_DEBUG == 1 );
local bLogStrat:boolean = ( GlobalParameters.RST_OPTION_LOG_STRAT == 1 );
local bLogGuess:boolean = ( GlobalParameters.RST_OPTION_LOG_GUESS == 1 );
local bLogOther:boolean = ( GlobalParameters.RST_OPTION_LOG_OTHER == 1 );


-- ===========================================================================
-- DATA
-- ===========================================================================

local Strategies:table = {
	NONE     = 0,
	CONQUEST = 1,
	SCIENCE  = 2,  
	CULTURE  = 3, 
	RELIGION = 4,
	DIPLO    = 5, -- reserved for Gathering Storm
	--DEFENSE  = 6, -- supporting
	--NAVAL    = 7, -- supporting
	--TRADE    = 8, -- supporting
};
--dshowtable(Strategies);

local tValidVictories:table = {};
local iMinimumPriority:number = 0;
local iBetterThanUsNerf:number = 0;

local tShowStrat:table = { "CONQUEST", "SCIENCE", "CULTURE", "RELIGION", "DIPLO" }; -- only these will be shown in logs and debugs

local tData:table = {}; -- a table of data sets, one for each player
RST.Data = tData; -- to access data in FireTuner

local tPriorities:table = {}; -- a table of Priorities tables (flavors); constructed from DB

local iMaxNumReligions:number = 0; -- maximum number of religions on this map


-- ===========================================================================
-- DEBUG ROUTINES
-- ===========================================================================

-- debug routine - prints a table (no recursion)
function dshowtable(tTable:table)
	if tTable == nil then print("dshowtable: table is nil"); return; end
	for k,v in pairs(tTable) do
		print(k, type(v), tostring(v));
	end
end

-- debug routine - prints a table, and tables inside recursively (up to 5 levels)
function dshowrectable(tTable:table, iLevel:number)
	local level:number = 0;
	if iLevel ~= nil then level = iLevel; end
	for k,v in pairs(tTable) do
		print(string.rep("---:",level), k, type(v), tostring(v));
		if type(v) == "table" and level < 5 then dshowrectable(v, level+1); end
	end
end

-- debug routine - prints priorities table in a compacted form (1 line, formatted)
function dshowpriorities(pTable:table, sComment:string)
	if not bLogDebug then return; end
	local tOut:table = {};
	--for strat,value in pairs(pTable) do table.insert(tOut, string.format("%s %4.1f :", strat, value)); end
	for _,strat in ipairs(tShowStrat) do table.insert(tOut, string.format(" : %s %4.1f", strat, pTable[strat])); end
	print(Game.GetCurrentGameTurn(), string.format("%40s", sComment), table.concat(tOut, " "));
end


-- ===========================================================================
-- TABLE HELPERS
-- ===========================================================================

-- check if 'value' exists in table 'pTable'; should work for any type of 'value' and table indices
function IsInTable(pTable:table, value)
	for _, data in pairs(pTable) do
		if data == value then return true; end
	end
	return false;
end

-- returns 'key' at which a given 'value' is stored in table 'pTable'; nil if not found; should work for any type of 'value' and table indices
function GetTableKey(pTable:table, value)
	for key,data in pairs(pTable) do
		if data == value then return key; end
	end
	return nil;
end


-- ===========================================================================
-- MULTIPLAYER SUPPORT
-- ===========================================================================

local eOptionRand:number = GlobalParameters.RST_OPTION_RANDOM;
local bUseRandom:boolean = ( eOptionRand ~= 0 );
print("Randomization: "..(bUseRandom and ( eOptionRand == 1 and "ON (math.random)" or "ON (Game.GetRandNum)") or "OFF"));

-- math.random(lower, upper): generates integer numbers between lower and upper (both inclusive)
-- Game.GetRandNum(max):generates integer in range 0..max-1 (max is NOT included)
-- there is no documentation, but I called it with (100) 10000 times and 100 was never rolled

function GetRandomNumber(iMin:number, iMax:number)
	if eOptionRand == 0 then return 0; end
	if eOptionRand == 1 then return math.random(iMin, iMax); end
	return Game.GetRandNum(iMax - iMin + 1, "Real Strategy Roll") + iMin;
end


-- ===========================================================================
-- HELPERS
-- ===========================================================================

-- get a new table with all 0
function PriorityTableNew()
	local tNew:table = {};
	for strat,_ in pairs(Strategies) do tNew[ strat ] = 0; end
	return tNew;
end

-- get a new table with random integers in range -iRand..+iRand (both inclusive)
function PriorityTableRandom(iRand:number)
	local tNew:table = PriorityTableNew();
	-- changed to ipairs for MP support
	for _,strat in ipairs(tShowStrat) do tNew[ strat ] = GetRandomNumber(-iRand, iRand); end
	return tNew;
end

-- set all values to iNum
function PriorityTableSet(pTable:table, iNum:number)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = iNum; end
end

-- set all values to a range iMin..iMax, both inclusive
function PriorityTableMinMax(pTable:table, iMin:number, iMax:number)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = math.min( math.max( pTable[strat], iMin ), iMax ); end
end

-- add two tables
function PriorityTableAdd(pTable:table, pTableToAdd:table)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = pTable[ strat ] + pTableToAdd[ strat ]; end
end

-- multiply two tables
function PriorityTableMultiplyByTable(pTable:table, pTableToMult:table)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = pTable[ strat ] * pTableToMult[ strat ]; end
end

-- multiply by a given number
function PriorityTableMultiply(pTable:table, fModifier:number)
	for strat,_ in pairs(Strategies) do pTable[ strat ] = pTable[ strat ] * fModifier; end
end

-- religion helper - counts us as well!
function PlayerGetNumCivsConverted(ePlayerID:number)
	--print("FUN PlayerGetNumCivsConverted", ePlayerID);
	local iNumCivsConverted = 0;
	--local pPlayerReligion:table = Players[ePlayerID]:GetReligion();
	local eReligionID:number = RST.PlayerGetReligionTypeCreated(ePlayerID); -- compatibility with vanilla pPlayerReligion:GetReligionTypeCreated();
	if eReligionID ~= -1 and eReligionID ~= GameInfo.Religions.RELIGION_PANTHEON.Index then
		-- are we converted?
		if Players[ePlayerID]:GetReligion():GetReligionInMajorityOfCities() == eReligionID then iNumCivsConverted = 1; end
		-- count others
		local pPlayerDiplomacy:table = Players[ePlayerID]:GetDiplomacy();
		for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
			if pPlayerDiplomacy:HasMet(otherID) and Players[otherID]:GetReligion():GetReligionInMajorityOfCities() == eReligionID then
				iNumCivsConverted = iNumCivsConverted + 1;
			end
		end
	end
	return iNumCivsConverted;
end

-- IsMinor() is not available in Gameplay context!
-- see also CivilizationLevels table
function PlayerIsMinor(ePlayerID:number)
	if PlayerConfigurations[ePlayerID] == nil then return false; end
	return PlayerConfigurations[ePlayerID]:GetCivilizationLevelTypeName() == "CIVILIZATION_LEVEL_CITY_STATE";
end

-- get City State category (cultural, industrial, etc.)
-- this is tricky - this info is in TypeProperties table attached to CIVILIZATION_ type
local tCityStateCategories:table = nil;
function GetCityStateCategory(ePlayerID:number)
	--if PlayerConfigurations[ePlayerID] == nil then print("ERROR: GetCityStateCategory cannot get configuration for", ePlayerID); return "(error)"; end -- engine faith
	-- pre-fetch data
	if tCityStateCategories == nil then
		tCityStateCategories = {};
		for row in GameInfo.TypeProperties() do
			if row.Name == "CityStateCategory" then tCityStateCategories[row.Type] = row.Value; end
		end
	end
	local sCivilizationType:string = PlayerConfigurations[ePlayerID]:GetCivilizationTypeName();
	local sCategory:string = tCityStateCategories[ sCivilizationType ];
	--for row in GameInfo.TypeProperties() do
		--if row.Type == sCivilizationType and row.Name == "CityStateCategory" then return row.Value; end
	--end
	if sCategory == nil then
		print("ERROR: GetCityStateCategory cannot find category for", sCivilizationType);
		return "(error)";
	end
	return sCategory;
end

-- scales number of turns according to the game speed
local iCostMultiplier:number = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()].CostMultiplier;
function GameGetNumTurnsScaled(iNumTurns:number)
	return iNumTurns * 100 / iCostMultiplier;
end


-- adjust table of priorities according to game turn
-- it scales lineary from _START to _STOP value during the game
local iMaxGameTurns:number = 0;
function TurnAdjustPriorities(tPriorities:table, iStartPerc:number, iStopPerc:number)
	-- late init
	if iMaxGameTurns == 0 then
		iMaxGameTurns = RST.GameGetMaxGameTurns();
		if iMaxGameTurns == 0 then
			-- no turn limit, must get data from DB
			print("MaxGameTurns: getting from DB");
			local sGameSpeedType:string = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()].GameSpeedType;
			for _,row in ipairs(DB.Query("select sum(TurnsPerIncrement) as MaxGameTurns from GameSpeed_Turns where GameSpeedType = ?", sGameSpeedType)) do
				iMaxGameTurns = row.MaxGameTurns;
			end
		end
		print("MaxGameTurns:", iMaxGameTurns);
	end
	local iCurrentTurn:number = Game.GetCurrentGameTurn();
	local fTurnAdjust:number = iStartPerc + (iStopPerc - iStartPerc) * iCurrentTurn / iMaxGameTurns;
	if bLogDebug then print(Game.GetCurrentGameTurn(), string.format("turn adjust %d..%d (iMaxT=%d,iCurT=%d,perc=%5.1f)", iStartPerc, iStopPerc, iMaxGameTurns, iCurrentTurn, fTurnAdjust)); end
	PriorityTableMultiply(tPriorities, fTurnAdjust/100.0);
	dshowpriorities(tPriorities, "after turn adjust");
end

-- used to check if a district is being produced
function IsPlayerBuilding(ePlayerID:number, sType:string)
	for _,city in Players[ePlayerID]:GetCities():Members() do
		if city:GetBuildQueue():CurrentlyBuilding() == sType then return true; end
	end
	return false;
end


-- ===========================================================================
-- CORE FUNCTIONS
-- ===========================================================================


------------------------------------------------------------------------------
-- This function gathers data specific for a player that can be reused in many places, like Military Strength, Science Positions, Tourism, etc.
-- all data is stored in tData[player].Data
function RefreshPlayerData(data:table)
	if bLogDebug then print(Game.GetCurrentGameTurn(), "FUN RefreshPlayerData", data.PlayerID, data.LeaderType); end
	
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	local tOut:table = {}; -- debug
	
	-- TODO: REMOVE a separate record, this can be a main record, easier access!
	local tNewData:table = {
		Era = pPlayer:GetEra(), -- simple
		ElapsedTurns = 0, -- with game speed scaling
		NumCitiesMajors = 0, -- total number of cities in majors - used for Religion - EXCEPTION - counts also not met!
		NumMajorsAliveAndMet = 0, -- number of alive major civs that we've met
		NumMajorsWithReligion = (RST.PlayerHasReligion(ePlayerID) and 1 or 0), -- number of alive, met and with religion plus us if we have one
		MajorIDsAliveAndMet = {}, -- and their IDs
		ReligionID = RST.PlayerGetReligionTypeCreated(ePlayerID), -- pPlayer:GetReligion():GetReligionTypeCreated(),
		NumCivsConverted = PlayerGetNumCivsConverted(ePlayerID), -- must count ourselves also!
		-- world averages - must calculate only for known civs + us
		AvgMilStr  = RST.GameGetAverageMilitaryStrength(ePlayerID), -- MilitaryStrength
		AvgTechs   = RST.GameGetAverageNumTechsResearched(ePlayerID),
		AvgScience = pPlayer:GetTechs():GetScienceYield(),
		AvgCulture = pPlayer:GetCulture():GetCultureYield(),
		--AvgTourism = RST.PlayerGetTourism(ePlayerID),
		AvgFaith   = pPlayer:GetReligion():GetFaithYield(),
		AvgCities  = RST.PlayerGetNumCitiesFollowingReligion(ePlayerID), -- start with us
	};
	
	-- elapsed turns with game speed scaling
	tNewData.ElapsedTurns = GameGetNumTurnsScaled(Game.GetCurrentGameTurn() - GameConfiguration.GetStartTurn());
	
	-- gather IDs and infos of major civs met
	local pPlayerDiplomacy:table = pPlayer:GetDiplomacy();
	for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		-- cities - will count ourselves here
		tNewData.NumCitiesMajors = tNewData.NumCitiesMajors + Players[otherID]:GetCities():GetCount();
		if pPlayerDiplomacy:HasMet(otherID) then -- HasMet returns false for ourselves, so no need for otherID ~= ePlayerID 
			tNewData.NumMajorsAliveAndMet = tNewData.NumMajorsAliveAndMet + 1;
			if RST.PlayerHasReligion(otherID) then tNewData.NumMajorsWithReligion = tNewData.NumMajorsWithReligion + 1; end
			table.insert(tNewData.MajorIDsAliveAndMet, otherID);
			-- calculate averages
			tNewData.AvgScience = tNewData.AvgScience + Players[otherID]:GetTechs():GetScienceYield();
			tNewData.AvgCulture = tNewData.AvgCulture + Players[otherID]:GetCulture():GetCultureYield();
			--tNewData.AvgTourism = tNewData.AvgTourism + RST.PlayerGetTourism(otherID);
			tNewData.AvgFaith   = tNewData.AvgFaith   + Players[otherID]:GetReligion():GetFaithYield();
			tNewData.AvgCities  = tNewData.AvgCities  + RST.PlayerGetNumCitiesFollowingReligion(otherID);
		end
	end

	-- calculate averages
	tNewData.AvgScience = tNewData.AvgScience / (tNewData.NumMajorsAliveAndMet+1);
	tNewData.AvgCulture = tNewData.AvgCulture / (tNewData.NumMajorsAliveAndMet+1);
	--tNewData.AvgTourism = tNewData.AvgTourism / (tNewData.NumMajorsAliveAndMet+1);
	tNewData.AvgFaith   = tNewData.AvgFaith   / (tNewData.NumMajorsAliveAndMet+1);
	if tNewData.NumMajorsWithReligion > 0 then
		tNewData.AvgCities  = tNewData.AvgCities  / tNewData.NumMajorsWithReligion;
	end
	
	-- replace the data
	data.Data = tNewData;
	--print("RefreshPlayerData:", ePlayerID)
	--dshowrectable(data.Data);
end	


------------------------------------------------------------------------------
-- Gather generic data like Leader, Policies, Beliefs, etc
function GetGenericPriorities(data:table)
	if bLogDebug then print(Game.GetCurrentGameTurn(), "FUN GetGenericPriorities", data.PlayerID, data.LeaderType); end
	
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	
	-- POLICIES
	-- Add priority value based on flavors of policies we've acquired.
	--print("...generic: policies", data.LeaderType);
	local tPolicies:table = RST.PlayerGetSlottedPolicies(ePlayerID);
	local tPolicyPriorities:table = PriorityTableNew();
	for _,policy in ipairs(tPolicies) do
		if tPriorities[policy] then PriorityTableAdd(tPolicyPriorities, tPriorities[policy].Priorities);
		else                        print("WARNING: GetGenericPriorities policy", policy, "not defined in Priorities"); end
	end
	PriorityTableMultiply(tPolicyPriorities, GlobalParameters.RST_WEIGHT_POLICY/100);
	dshowpriorities(tPolicyPriorities, "generic policies");
	
	-- GOVERNMENT
	--print("...generic: government", data.LeaderType);
	local sGovType:string = GameInfo.Governments[ RST.PlayerGetCurrentGovernment(ePlayerID) ].GovernmentType;
	local tGovPriorities:table = PriorityTableNew();
	if tPriorities[sGovType] then PriorityTableAdd(tGovPriorities, tPriorities[sGovType].Priorities);
	else                          print("WARNING: GetGenericPriorities government", sGovType, "not defined in Priorities"); end
	PriorityTableMultiply(tGovPriorities, GlobalParameters.RST_WEIGHT_GOVERNMENT/100);
	dshowpriorities(tGovPriorities, "generic government "..string.gsub(sGovType, "GOVERNMENT_", ""));
	
	-- WONDERS
	-- probably the fastest way is to iterate through Flavors?
	--print("...generic: wonders", data.LeaderType);
	local tWonderPriorities:table = PriorityTableNew();
	for object,data in pairs(tPriorities) do
		if data.Type == "Wonder" and GameInfo.Buildings[data.ObjectType] ~= nil then -- make sure this Wonder is actually in-game
			-- now iterate through cities
			for _,city in pPlayer:GetCities():Members() do
				--print("...checking", data.ObjectType, "in", city:GetName());
				if city:GetBuildings():HasBuilding( GameInfo.Buildings[data.ObjectType].Index ) then
					--print("...player has", object);
					PriorityTableAdd(tWonderPriorities, data.Priorities);
				end
			end
		end
	end
	PriorityTableMultiply(tWonderPriorities, GlobalParameters.RST_WEIGHT_WONDER/100);
	dshowpriorities(tWonderPriorities, "generic wonders");
	
	-- GREAT PEOPLE
	-- Add priority value based on flavors of great people we've acquired.
	--print("...generic: great people", data.LeaderType);
	local tGPs:table = RST.PlayerGetRecruitedGreatPeopleClasses(ePlayerID);
	local tGPPriorities:table = PriorityTableNew();
	for _,class in ipairs(tGPs) do
		if tPriorities[class] then PriorityTableAdd(tGPPriorities, tPriorities[class].Priorities);
		else                       print("WARNING: GetGenericPriorities great person class", class, "not defined in Priorities"); end
	end
	PriorityTableMultiply(tGPPriorities, GlobalParameters.RST_WEIGHT_GREAT_PERSON/100);
	dshowpriorities(tGPPriorities, "generic great people");
	
	-- CITY STATES
	--print("...generic: city states", data.LeaderType);
	local tMinorPriorities:table = PriorityTableNew();
	for _,minor in ipairs(PlayerManager.GetAliveMinors()) do
		if minor:GetInfluence():GetSuzerain() == ePlayerID then
			local sCategory:string = GetCityStateCategory(minor:GetID());
			--print("...suzerain of", sCategory);
			PriorityTableAdd(tMinorPriorities, tPriorities[sCategory].Priorities);
		end
	end
	PriorityTableMultiply(tMinorPriorities, GlobalParameters.RST_WEIGHT_MINOR/100);
	dshowpriorities(tMinorPriorities, "generic city states");

	-- BELIEFS
	-- Add priority value based on flavors of beliefs we've acquired.
	--print("...generic: beliefs", data.LeaderType);
	local tBeliefs:table = RST.PlayerGetBeliefs(ePlayerID);
	local tBeliefPriorities:table = PriorityTableNew();
	for _,beliefID in pairs(tBeliefs) do
		if GameInfo.Beliefs[beliefID] then
			local sBelief:string = GameInfo.Beliefs[beliefID].BeliefType;
			--print("..earned", sBelief);
			if tPriorities[sBelief] then PriorityTableAdd(tBeliefPriorities, tPriorities[sBelief].Priorities);
			else                         print("WARNING: GetGenericPriorities belief", sBelief, "not defined in Priorities"); end
		end
	end
	PriorityTableMultiply(tBeliefPriorities, GlobalParameters.RST_WEIGHT_BELIEF/100);
	dshowpriorities(tBeliefPriorities, "generic beliefs");

	
	--print("...generic priorities for leader", data.LeaderType);
	local tGenericPriorities:table = PriorityTableNew();
	PriorityTableAdd(tGenericPriorities, tPolicyPriorities);
	PriorityTableAdd(tGenericPriorities, tGovPriorities);
	PriorityTableAdd(tGenericPriorities, tWonderPriorities);
	PriorityTableAdd(tGenericPriorities, tGPPriorities);
	PriorityTableAdd(tGenericPriorities, tMinorPriorities);
	PriorityTableAdd(tGenericPriorities, tBeliefPriorities);
	dshowpriorities(tGenericPriorities, "*** generic priorities "..data.LeaderType);
	return tGenericPriorities;
end


------------------------------------------------------------------------------
-- TODO: Add map analysis in the future
function ProcessGeographicData(ePlayerID:number)
	print("FUN ProcessGeographicData", ePlayerID);
end


------------------------------------------------------------------------------
-- functions to check if a player is close to a victory
-- check Game.GetVictoryProgressForPlayer - maybe it could be easier to use? - NOT EXISTS

function PlayerIsCloseToConquestVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToConquestVictory", ePlayerID);
	-- check for number of all capitals taken vs. total major players
	--print( "close to conquest? player", ePlayerID, "capitals, all players", RST.PlayerGetNumCapturedCapitals(ePlayerID), PlayerManager.GetWasEverAliveMajorsCount());
	return ( RST.PlayerGetNumCapturedCapitals(ePlayerID) / (PlayerManager.GetWasEverAliveMajorsCount()-1) ) > 0.6; -- size 4 after 2, size 6 after 3, size 8 after 5, size 10 after 6, size 12 after 7
end

-- return the number of completed space race projects
function PlayerGetNumProjectsSpaceRace(ePlayerID:number)
	--print("FUN PlayerGetNumProjectsSpaceRace", ePlayerID);
	-- count space race projects
	local iTot:number, iNum:number = 0, 0;
	for row in GameInfo.Projects() do
		if row.SpaceRace and row.MaxPlayerInstances == 1 then -- in GS laser projects can be executed more than once
			iTot = iTot + 1;
			iNum = iNum + RST.PlayerGetNumProjectsAdvanced(ePlayerID, row.Index);
		end
	end
	if bIsGatheringStorm then
		-- we will treat the flight as 2 projects
		iTot = iTot + 2;
		local lightYears:number, totalLightYears:number, lightYearsPerTurn:number = RST.PlayerGetScienceVictoryProgress(ePlayerID);
		if lightYears >= totalLightYears * 0.5 then iNum = iNum + 1; end
		if lightYears >= totalLightYears       then iNum = iNum + 1; end
	end
	--print("space race player, num/tot", ePlayerID, iNum, iTot);
	return iNum;
end

-- Gathering Storm - science victory is changed
-- Vanilla is 5 projects, GS is 4 projects + 50 turns of flight
function PlayerIsCloseToScienceVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToScienceVictory", ePlayerID);
	if bIsGatheringStorm then
		return PlayerGetNumProjectsSpaceRace(ePlayerID) >= 3; -- there is 50 turn flight, so we can give more slack at the begining
	else
		return PlayerGetNumProjectsSpaceRace(ePlayerID) >= 2; -- 2 out of 5
	end
end

function PlayerIsCloseToCultureVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToCultureVictory", ePlayerID);
	--print("close to culture? player", ePlayerID, "cultural progress", RST.PlayerGetCultureVictoryProgress(ePlayerID));
	return RST.PlayerGetCultureVictoryProgress(ePlayerID) > 60; -- it is in % (0..100)
end

function PlayerIsCloseToReligionVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToReligionVictory", ePlayerID);
	-- similar condition as for conquest
	--print("close to religion? player", ePlayerID, "converted, all civs", PlayerGetNumCivsConverted(ePlayerID), PlayerManager.GetWasEverAliveMajorsCount());
	return PlayerGetNumCivsConverted(ePlayerID) / PlayerManager.GetWasEverAliveMajorsCount() > 0.6 -- size 4 after 3, size 6 after 4, size 8 after 5, size 10 after 7, size 12 after 8
end

function PlayerIsCloseToDiploVictory(ePlayerID:number)
	--print("FUN PlayerIsCloseToDiploVictory", ePlayerID);
	if not bIsGatheringStorm then return false; end
	-- DV Points >= 70%
	return RST.PlayerGetDiploVictoryProgress(ePlayerID) >= 70;
end

function PlayerIsCloseToAnyVictory(ePlayerID:number)
	return PlayerIsCloseToConquestVictory(ePlayerID) or PlayerIsCloseToCultureVictory(ePlayerID) or PlayerIsCloseToDiploVictory(ePlayerID) or PlayerIsCloseToReligionVictory(ePlayerID) or PlayerIsCloseToScienceVictory(ePlayerID);
end


------------------------------------------------------------------------------
-- Specific: CONQUEST
function GetPriorityConquest(data:table)
	--print("FUN GetPriorityConquest", data.PlayerID, data.LeaderType);
	-- check if this victory type is enabled
	if tValidVictories.CONQUEST == 0 then return -200; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	local pPlayerDiplomacy:table = pPlayer:GetDiplomacy();
	
	-- first check is for Hostility, Deceptiveness, etc. - those are not supported in Civ6
	-- iPriority += ((GetPlayer()->GetDiplomacy()->GetBoldness() + iGeneralApproachModifier + GetPlayer()->GetDiplomacy()->GetMeanness()) * (10 - iEra)); // make a little less likely as time goes on
	-- try to use generic Flavor?
	--if tPriorities[data.LeaderType] then
	-- ???????? There is already Era Bias factor for each victory - is this really needed?
	iPriority = tPriorities[data.LeaderType].Priorities.CONQUEST;
	iPriority = iPriority * 2 * (1.0 - data.Data.Era/#GameInfo.Eras); -- PARAMETER???
	if bLogDebug then print("...era adjusted extra conquest, priority=", iPriority); end
	--end

	-- early game, if we haven't met any Major Civs yet, then we probably shouldn't be planning on conquering the world
	--local iElapsedTurns:number = Game.GetCurrentGameTurn() - GameConfiguration.GetStartTurn(); -- TODO: GameSpeed scaling!
	if data.Data.ElapsedTurns >= GlobalParameters.RST_CONQUEST_NOBODY_MET_NUM_TURNS then -- def. 20, AI_GS_CONQUEST_NOBODY_MET_FIRST_TURN
		if data.Data.NumMajorsAliveAndMet == 0 then 
			iPriority = iPriority + GlobalParameters.RST_CONQUEST_NOBODY_MET_PRIORITY; -- def. -50, AI_GRAND_STRATEGY_CONQUEST_NOBODY_MET_WEIGHT
			if bLogDebug then print("...turn", Game.GetCurrentGameTurn(), "no majors met, priority=", iPriority); end
		end
	end

	-- If we're at war, then boost the weight a bit (ignore minors)
	for _,otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		if pPlayerDiplomacy:IsAtWarWith(otherID) then
			if bLogDebug then print("we are at war with", otherID); end
			iPriority = iPriority + GlobalParameters.RST_CONQUEST_AT_WAR_PRIORITY;
		end
	end

	-- include captured capitals
	local iNumCapturedCapitals:number = RST.PlayerGetNumCapturedCapitals(ePlayerID);
	--if iNumCapturedCapitals > 1 then
	iPriority = iPriority + GlobalParameters.RST_CONQUEST_CAPTURED_CAPITAL_PRIORITY * iNumCapturedCapitals;
	--end
	if bLogDebug then print("...player has captured", iNumCapturedCapitals, "capitals; priority=", iPriority); end
	
	-- How many turns must have passed before we test for us having a weak military?
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then -- AI_GS_CONQUEST_MILITARY_STRENGTH_FIRST_TURN, def. 60
		-- Compare our military strength to the rest of the world
		-- Reduce world average if we're rocking multiple capitals (VP specific)
		local iWorldMilitaryStrength:number = data.Data.AvgMilStr * 100 / (100 + iNumCapturedCapitals * 10); -- ??????
		if iWorldMilitaryStrength > 0 then
			local fStrengthRatio:number = (RST.PlayerGetMilitaryStrength(ePlayerID) - iWorldMilitaryStrength) / iWorldMilitaryStrength;
			local iMilitaryRatio:number = fStrengthRatio * GlobalParameters.RST_CONQUEST_POWER_RATIO_MULTIPLIER; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			if fStrengthRatio > 1.0 then -- it actually means that our power is 2x more
				-- use logarithmic function, otherwise this is getting out ot control
				iMilitaryRatio = GlobalParameters.RST_CONQUEST_POWER_RATIO_MULTIPLIER + GlobalParameters.RST_CONQUEST_POWER_RATIO_LOG_MULTIPLIER * math.log(fStrengthRatio);
			end
			iPriority = iPriority + iMilitaryRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			if bLogDebug then print("...military ratio", iMilitaryRatio, "player/world", RST.PlayerGetMilitaryStrength(ePlayerID), iWorldMilitaryStrength, "priority=", iPriority); end
		end
	end
	
	-- Desperate factor
	--local iEra:number = pPlayer:GetEra();
	local bDesperate:boolean = not PlayerIsCloseToAnyVictory(ePlayerID);
	if bLogDebug then print("...era, desperate", data.Data.Era, bDesperate); end
	local iPriorityDangerPlayers:number = 0;
	local iNumCities:number = 0;
	for _,otherID in ipairs(data.Data.MajorIDsAliveAndMet) do
		if PlayerIsCloseToAnyVictory(otherID) then
			if bLogDebug then print("player", otherID, "is close to a victory"); end
			iPriorityDangerPlayers = iPriorityDangerPlayers + (bDesperate and GlobalParameters.RST_CONQUEST_SOMEONE_CLOSE_TO_VICTORY or GlobalParameters.RST_CONQUEST_BOTH_CLOSE_TO_VICTORY);
		end
		iNumCities = iNumCities + Players[otherID]:GetCities():GetCount();
	end
	-- increase priority by desperate factor
	iPriority = iPriority + iPriorityDangerPlayers * data.Data.Era;
	if bLogDebug then print("iPriorityDangerPlayers", iPriorityDangerPlayers, "priority=", iPriority); end
	
	-- cramped factor - checks for all plots' ownership but it is cheating - use cities instead (available in deal screen)
	-- HNT: this can be used for Defense also - if we lack with cities, we need better defense
	-- but first it checks our current land and nearby plots - if there are any usable?
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		local iOurCities:number = pPlayer:GetCities():GetCount();
		local iAvgCities:number = (iNumCities + iOurCities) / (data.Data.NumMajorsAliveAndMet + 1);
		if (iOurCities < iAvgCities) and ((iAvgCities - iOurCities) <= 4.0) then
			-- only boost for max. 4 cities; if we're are lacking more then we are simply too weak for CONQUEST
			iPriority = iPriority + GlobalParameters.RST_CONQUEST_LESS_CITIES_WEIGHT * ( iAvgCities - iOurCities );
			if bLogDebug then print("our cities, on average", iOurCities, iAvgCities, "priority=", iPriority); end
		end
	end

	-- if we do not have nukes and we know someone else who does... [CHEATING??? CHECK]
	if RST.PlayerGetNumWMDs(ePlayerID) == 0 then
		for _,otherID in ipairs(data.Data.MajorIDsAliveAndMet) do
			if RST.PlayerGetNumWMDs(otherID) > 0 then
				iPriority = iPriority + GlobalParameters.RST_CONQUEST_NUKE_THREAT;
				if bLogDebug then print("player", otherID, "has NUKES; priority=", iPriority); end
				break;
			end
		end -- for
	end -- 0 nukes
	
	--print("GetPriorityConquest:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
-- Specific: SCIENCE
function GetPriorityScience(data:table)
	--print("FUN GetPriorityScience", data.PlayerID, data.LeaderType);
	-- check if this victory type is enabled
	if tValidVictories.SCIENCE == 0 then return -200; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];

	-- if I already completed some projects I am very likely to follow through
	local iSpaceRaceProjects:number = PlayerGetNumProjectsSpaceRace(ePlayerID);
	iPriority = iPriority + iSpaceRaceProjects * GlobalParameters.RST_SCIENCE_PROJECT_WEIGHT;
	if bLogDebug then print("...space race projects", iSpaceRaceProjects, "priority=", iPriority); end
	
	-- Add in our base science value.
	--iPriority = iPriority + pPlayer:GetTechs():GetScienceYield() * GlobalParameters.RST_SCIENCE_YIELD_WEIGHT / 100.0;
	--iPriorityBonus += (m_pPlayer->GetScienceYield() / 250); -- VERY IMPORTANT! VP uses 250, but science in VP can be as high as Ks, so for 10000 (late game) it gives 40; in Civ6 it is usually in 00s, like 300-500?
	--print("...added science yield, yield", pPlayer:GetTechs():GetScienceYield(), "priority=", iPriority);

	-- How many turns must have passed before we test for us against others
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our science output to the rest of the world
		-- Reduce world average if we've completed some space race projects (VP specific)
		local iWorld:number = data.Data.AvgScience * 100 / (100 + iSpaceRaceProjects * 10); -- ??????
		if iWorld > 0 then
			local iRatio:number = (pPlayer:GetTechs():GetScienceYield() - iWorld) * GlobalParameters.RST_SCIENCE_YIELD_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			if bLogDebug then print("...science ratio", iRatio, "player/world", pPlayer:GetTechs():GetScienceYield(), iWorld, "priority=", iPriority); end
		end
	end

	
	-- VP uses an algorithm based on civ relative position in a pack by num of techs AI_GS_CULTURE_AHEAD_WEIGHT=50 - max that we can get from that
	-- seems ok however it doesn't account for how much we are ahead (or behind)
	-- similar approach to relative power - get average techs and if we are ahead, then add some weight
	-- also, account for late game - being ahead should be more valued then?
	-- num_techs_better_than_avg * per_tech
	-- no era adjustment here - if we are doing good, our position will only get better plus yield will matter more
	-- How many turns must have passed before we test for us having a weak military?
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our num techs to the rest of the world
		--local iWorld:number = RST.GameGetAverageNumTechsResearched(ePlayerID); --, true, true); -- include us and only known
		local iWorld:number = data.Data.AvgTechs;
		if iWorld > 0 then
			local iRatio:number = (RST.PlayerGetNumTechsResearched(ePlayerID) - iWorld) * GlobalParameters.RST_SCIENCE_TECH_WEIGHT;
			--local iRatio:number = (RST.PlayerGetNumTechsResearched(ePlayerID) - iWorld) * (GlobalParameters.RST_SCIENCE_TECH_RATIO_MULTIPLIER + 3 * iWorld) / iWorld; -- slightly modified formula, adding 3*World prevents the diff from diminishing too quickly!
			--if iRatio > 0 then -- let's not use negatives yet
			iPriority = iPriority + iRatio;
			--end
			if bLogDebug then print("...tech ratio", iRatio, "player/world", RST.PlayerGetNumTechsResearched(ePlayerID), iWorld, "priority=", iPriority); end
		end
	end
	
	-- check for spaceport
	if RST.PlayerHasSpaceport(ePlayerID) then
		iPriority = iPriority + GlobalParameters.RST_SCIENCE_HAS_SPACEPORT;
		if bLogDebug then print("...player has spaceport, priority=", iPriority); end
	end
	
	--print("GetPriorityScience:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
-- Specific: CULTURE
function GetPriorityCulture(data:table)
	--print("FUN GetPriorityCulture", data.PlayerID, data.LeaderType);
	-- check if this victory type is enabled
	if tValidVictories.CULTURE == 0 then return -200; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	
	-- the later the game the greater the chance
	--iPriority = tPriorities[data.LeaderType].Priorities.CULTURE * pPlayer:GetEra() * GlobalParameters.RST_CULTURE_ERA_BIAS / 100.0;
	--print("...science weight, era, science bias", tPriorities[data.LeaderType].Priorities.SCIENCE, pPlayer:GetEra(), iPriority);

	-- Add in our base culture and tourism value
	-- VP uses /240 for culture = 3,3%, late game is getting into 5000+ => 20 pts || Civ6 ~500
	-- VP uses /1040 for tourism = 0,8%, late game is getting into 1000+ => 1 pts (?) || Civ6 ~500
	--iPriority = iPriority + pPlayer:GetCulture():GetCultureYield() * GlobalParameters.RST_CULTURE_YIELD_WEIGHT / 100.0;
	--print("...added culture yield, yield", pPlayer:GetCulture():GetCultureYield(), "priority=", iPriority);
	
	-- How many turns must have passed before we test for us against others
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our culture output to the rest of the world
		local iWorld:number = data.Data.AvgCulture; -- * 100 / (100 + math.max(0,(data.Data.NumCivsConverted-1)) * 10); -- ??????
		if iWorld > 0 then
			local iRatio:number = (pPlayer:GetCulture():GetCultureYield() - iWorld) * GlobalParameters.RST_CULTURE_YIELD_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			if bLogDebug then print("...culture ratio", iRatio, "player/world", pPlayer:GetCulture():GetCultureYield(), iWorld, "priority=", iPriority); end
		end
	end
	
	--iPriority = iPriority + RST.PlayerGetTourism(ePlayerID) * GlobalParameters.RST_CULTURE_TOURISM_WEIGHT / 100.0;
	--print("...added tourism yield, yield", RST.PlayerGetTourism(ePlayerID), "priority=", iPriority);
	
	-- How many turns must have passed before we test for us against others
	-- Tourism is hard to come by early - maybe we should wait longer?
	--[[
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our tourism output to the rest of the world
		local iWorld:number = data.Data.AvgTourism; -- * 100 / (100 + math.max(0,(data.Data.NumCivsConverted-1)) * 10); -- ??????
		if iWorld > 0 then
			local iRatio:number = (RST.PlayerGetTourism(ePlayerID) - iWorld) * GlobalParameters.RST_CULTURE_TOURISM_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			print("...tourism ratio", iRatio, "player/world", RST.PlayerGetTourism(ePlayerID), iWorld, "priority=", iPriority);
		end
	end
	--]]
	
	-- in Civ5 it is influential - 50 pts. per civ getAI_GS_CULTURE_INFLUENTIAL_CIV_MOD
	-- also similar algorithm to check if we are ahead or behind - it used pure yields however, not policies or similar
	-- can't use - no info on civics available! no cheating!
	-- simple idea - the more % we have, the more it adds
	iPriority = iPriority + GlobalParameters.RST_CULTURE_PROGRESS_MULTIPLIER * (math.exp(RST.PlayerGetCultureVictoryProgress(ePlayerID) * GlobalParameters.RST_CULTURE_PROGRESS_EXPONENT / 10000.0) - 1.0);
	if bLogDebug then print("...added cultural progress, perc%", RST.PlayerGetCultureVictoryProgress(ePlayerID), "priority=", iPriority); end
	
	-- PICKLE here: no holding back! what could be the negative?
	
	--print("GetPriorityCulture:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
-- Specific: RELIGION
function GetPriorityReligion(data:table)
	--print("FUN GetPriorityReligion", data.PlayerID, data.LeaderType);
	-- check if this victory type is enabled
	if tValidVictories.RELIGION == 0 then return -200; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	
	-- check if we can have a religion at all (Kongo)
	-- simple version, complex one should check ExcludedGreatPersonClasses and ExcludedDistricts, then Trait and then Leader :(
	if data.LeaderType == "LEADER_MVEMBA" then -- TRAIT_LEADER_RELIGIOUS_CONVERT
		if bLogDebug then print("This is Kongo - no religious victory"); end
		return -200;
	end
	
	-- first, check if we have a religion
	if data.Data.ReligionID == -1 or data.Data.ReligionID == GameInfo.Religions.RELIGION_PANTHEON.Index then
		if bLogDebug then print("...we don't have a religion"); end
		-- we don't have a religion - abandon this victory if we cannot get one
		if #Game.GetReligion():GetReligions() >= iMaxNumReligions then
			if bLogDebug then print("...and we cannot get one - no religious victory"); end
			return -200;
		end
	else
		--if data.Data.ReligionID ~= GameInfo.Religions.RELIGION_PANTHEON.Index then
		iPriority = iPriority + GlobalParameters.RST_RELIGION_RELIGION_WEIGHT;
		if bLogDebug then print("...religion founded", data.Data.ReligionID, "priority=", iPriority); end
	end

	-- check number of beliefs - done even better in generic because it weights with flavors
	--iPriority = iPriority + RST.PlayerGetNumBeliefsEarned(ePlayerID) * GlobalParameters.RST_RELIGION_BELIEF_WEIGHT;
	--print("...added num beliefs, num", RST.PlayerGetNumBeliefsEarned(ePlayerID), "priority=", iPriority);
	
	-- faith yield - change to comparison to average?
	--iPriority = iPriority + pPlayer:GetReligion():GetFaithYield() * GlobalParameters.RST_RELIGION_FAITH_YIELD_WEIGHT / 100.0;
	--print("...added faith yield, yield", pPlayer:GetReligion():GetFaithYield(), "priority=", iPriority);
	
	-- WorldRankings displays how many civs were converted
	if data.Data.NumCivsConverted > 1 then
		iPriority = iPriority + (data.Data.NumCivsConverted-1) * GlobalParameters.RST_RELIGION_CONVERTED_WEIGHT;
		if bLogDebug then print("...converted >1 civs, num", data.Data.NumCivsConverted , "priority=", iPriority); end
	end

	-- How many turns must have passed before we test for us against others
	if data.Data.ElapsedTurns >= GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then
		-- Compare our faith output to the rest of the world
		-- Reduce world average if we're rocking multiple converts (VP specific) - not counting ourselves
		local iWorld:number = data.Data.AvgFaith * 100 / (100 + math.max(0,(data.Data.NumCivsConverted-1)) * 10); -- ??????
		if iWorld > 0 then
			--local iRatio:number = (pPlayer:GetReligion():GetFaithYield() - iWorld) * GlobalParameters.RST_RELIGION_FAITH_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			local iRatio:number = (pPlayer:GetReligion():GetFaithYield() - iWorld) * (GlobalParameters.RST_RELIGION_FAITH_FACTOR * (data.Data.Era+1)) / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio;
			if bLogDebug then print("...faith ratio", iRatio, "player/world/era", pPlayer:GetReligion():GetFaithYield(), iWorld, data.Data.Era, "priority=", iPriority); end
		end
	end
		-- no, no... cities are limited, so it should be treated the same way as CultureProgress, expotential progress
		--[[
		iWorld = data.Data.AvgCities;
		if iWorld > 0 then
			local iRatio:number = (RST.PlayerGetNumCitiesFollowingReligion(ePlayerID) - iWorld) * GlobalParameters.RST_RELIGION_CITIES_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			print("...cities ratio", iRatio, "player/world", RST.PlayerGetNumCitiesFollowingReligion(ePlayerID) , iWorld, "priority=", iPriority);
		end
		--]]

	-- use expotential formula for Cities
	-- to convert first cities, you need religion + missionaries, so at least T80+
	-- other civs should have at least 2-3 cities, so our first cities will account for 10-20% of the whole, giving a smooth start
	if data.Data.NumCitiesMajors > 0 then -- first turn
		local fCitiesProgress:number = RST.PlayerGetNumCitiesFollowingReligion(ePlayerID) / data.Data.NumCitiesMajors;
		iPriority = iPriority + GlobalParameters.RST_RELIGION_CITIES_MULTIPLIER * (math.exp(fCitiesProgress * GlobalParameters.RST_RELIGION_CITIES_EXPONENT / 100.0) - 1.0);
		if bLogDebug then print("...cities progress, num, all", RST.PlayerGetNumCitiesFollowingReligion(ePlayerID), data.Data.NumCitiesMajors, "priority=", iPriority); end
	end
	
	-- early game, if we haven't met any Major Civs yet, then we probably shouldn't be planning on conquering the world with our religion - see also Conquest
	if data.Data.ElapsedTurns >= GlobalParameters.RST_RELIGION_NOBODY_MET_NUM_TURNS then
		if data.Data.NumMajorsAliveAndMet == 0 then 
			iPriority = iPriority + GlobalParameters.RST_RELIGION_NOBODY_MET_PRIORITY;
			if bLogDebug then print("...turn", Game.GetCurrentGameTurn(), "no majors met, priority=", iPriority); end
		end
	end

	-- each inqusition launched decreases the priority [cheating?] - REMOVE????
	-- there is another way - since religious units may enter, then just OBSERVE if there are Inqusitors!
	-- need 2 checks, one on TurnBegin and then TurnEnd and this flag goes to Stored! once detected, there is no need to do so anymore
	-- HINT: this is like being at war with conquest??? - maybe we should boost it actually?
	for _,otherID in ipairs(data.Data.MajorIDsAliveAndMet) do
		if Players[otherID]:GetReligion():HasLaunchedInquisition() then
			if bLogDebug then print("...player", otherID, "has launched inqusition"); end
			iPriority = iPriority + GlobalParameters.RST_RELIGION_INQUISITION_WEIGHT;
		end
	end
	
	--print("GetPriorityReligion:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
-- Specific: DIPLO
--[[

I am not sure if scoring for Diplo should start immediately. Maybe in Medieval Era, together with WC?
if Game.GetEras():GetCurrentEra() >= GlobalParameters.WORLD_CONGRESS_INITIAL_ERA then

Things to score
Big milestones (like cities captured) are DV points.
7 and more = close to victory.
Suzerain of a CS - it is in general however. Maybe give it more?
Alliances and their level.
Maybe ae should add this to „general section”. Certainly cultural, scientific and religious are helpful for respective victories.
Yield here is Favor per turn. It is rather rare, 20-30 is a lot.
Money is important. Maybe count TRs and even GPT?
Careful with GPT, crazy values possible.
--]]

function GetPriorityDiplo(data:table)
	if bLogDebug then print("FUN GetPriorityDiplo", data.PlayerID, data.LeaderType); end
	-- check if this victory type is enabled
	if tValidVictories.DIPLO == 0 then return -200; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pPlayer:table = Players[ePlayerID];
	
	-- VP alorithm
	-- Add in our base gold value. iPriorityBonus += (m_pPlayer->GetTreasury()->CalculateBaseNetGold() / 25);
	-- adds Paper from Alliances
	-- policies & buildings & religion
	-- votes controlled - checks for allied City States
	-- it compares with the 2nd highest 
	-- calculates votes needed to win
	-- if we control >50%, then boosts *5, >75% boosts *10

	--Big milestones (like cities captured) are DV points.
	--7 and more = close to victory.
	local progress:number = RST.PlayerGetDiploVictoryProgress(ePlayerID);
	iPriority = iPriority + progress * GlobalParameters.RST_DIPLO_PROGRESS_WEIGHT; -- 0.100, so each DPV = 50
	if progress > 50 then iPriority = iPriority + (progress - 50) * GlobalParameters.RST_DIPLO_PROGRESS_WEIGHT; end
	if bLogDebug then print("...diplo progress", progress, iPriority); end
	
	--Suzerain of a CS - it is in general however. Maybe give it more?
	
	--Alliances and their level.
	--Maybe ae should add this to „general section”. Certainly cultural, scientific and religious are helpful for respective victories.
	-- NO. Alliance is only 1 of the type. What matters is level. However this and suzerain boils down do FPT value (favor per turn).
	
	--Yield here is Favor per turn (FPT). It is rather rare, 20-30 is a lot.
	local totalFavor:number   = pPlayer:GetDiplomacy():GetFavor(); 
	local favorPerTurn:number = pPlayer:GetDiplomacy():GetFavorPerTurn();
	iPriority = iPriority + favorPerTurn * GlobalParameters.RST_DIPLO_FAVOR_PER_TURN_WEIGHT;
	if bLogDebug then print("...favor per turn", favorPerTurn, iPriority); end
	
	--Money is important. Maybe count TRs and even GPT?
	--Careful with GPT, crazy values possible.
	-- AI sells favor easily unless you have a lot, and are a threat. They are not willing to sell any more. Money is not a good measure here???
	
	return iPriority;
end


------------------------------------------------------------------------------
-- Get the base Priority for a Grand Strategy; these are elements common to ALL Grand Strategies
-- Base Priority looks at Personality Flavors (0 - 10) and multiplies * the Flavors attached to a Grand Strategy (0-10),
-- so expect a number between 0 and 100 back from this
function EstablishStrategyBasePriority(data:table)
	if bLogDebug then print(Game.GetCurrentGameTurn(), "FUN EstablishStrategyBasePriority", data.PlayerID, data.LeaderType); end
	data.Priorities = PriorityTableNew();
	--if tPriorities["BasePriority"] == nil then
		--print("WARNING: BasePriority table not defined."); return;
	--end
	if tPriorities[data.LeaderType] == nil then
		print("WARNING: EstablishStrategyBasePriority Priorities table for leader", data.LeaderType, "not defined."); return;
	end
	-- multiply Leader flavors by base priority weight
	PriorityTableAdd(data.Priorities, tPriorities[data.LeaderType].Priorities);
	PriorityTableMultiply(data.Priorities, GlobalParameters.RST_WEIGHT_LEADER);
	--print("...base priorities for leader", data.LeaderType);
	dshowpriorities(data.Priorities, "*** base priorities "..data.LeaderType);
	
	-- the later the game the greater the chance
	local tEraBiasPriorities:table = PriorityTableNew();
	PriorityTableAdd(tEraBiasPriorities, tPriorities[data.LeaderType].Priorities);
	PriorityTableMultiply(tEraBiasPriorities, data.Data.Era * GlobalParameters.RST_STRATEGY_LEADER_ERA_BIAS / 100.0);
	--print("...era bias for era", data.Data.Era); --Players[data.PlayerID]:GetEra());
	dshowpriorities(tEraBiasPriorities, "era bias for era "..tostring(data.Data.Era));
	
	--print("EstablishStrategyBasePriority:");
	PriorityTableAdd(data.Priorities, tEraBiasPriorities);
	dshowpriorities(data.Priorities, "EstablishStrategyBasePriority");
end


------------------------------------------------------------------------------
-- Main function
function RefreshAndProcessData(ePlayerID:number)
	--print(Game.GetCurrentGameTurn(), "FUN RefreshAndProcessData", ePlayerID);
	
	-- do all pre-checks so others won't have to
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	
	-- check if data needs to be refreshed
	local data:table = tData[ePlayerID];
	if data == nil or data.Data == nil then return false; end -- GH #15
	--if not data.Dirty then return; end
	if data.TurnRefreshStrategy == Game.GetCurrentGameTurn() then return; end -- we already refreshed on this turn

	-- active turns with game speed scaling
	local iNumTurnsActive:number = GameGetNumTurnsScaled(Game.GetCurrentGameTurn() - data.TurnRefreshStrategy);
	--print(Game.GetCurrentGameTurn(), data.LeaderType, "...current strategy", data.ActiveStrategy, "turn refresh", data.TurnRefreshStrategy, "active for", iNumTurnsActive, "turns");
	if not( data.TurnRefreshStrategy == -1 or data.ActiveStrategy == "NONE" or iNumTurnsActive >= GlobalParameters.RST_STRATEGY_NUM_TURNS_MUST_BE_ACTIVE ) then
		return;
	end
	
	-- we should go here if: TurnRefreshStrategy == -1, ActiveStrategy == "NONE", or current strategy needs to be refreshed after being active for X turns
	RefreshPlayerData(data);
	
	-- Base Priority looks at Personality Flavors (0 - 10) and multiplies * the Flavors attached to a Grand Strategy (0-10),
	-- so expect a number between 0 and 100 back from this
	EstablishStrategyBasePriority(data);
	
	-- Loop through all GrandStrategies to set their Priorities
	-- specific conditions - TODO: can this be expandable? like Lua function as a parameter
	--                       TODO: if objects were used, then data would be self and functions would look like self:GetPriorityConquest()
	local tSpecificPriorities:table = PriorityTableNew();
	tSpecificPriorities.CONQUEST = GetPriorityConquest(data);
	tSpecificPriorities.SCIENCE  = GetPriorityScience(data);
	tSpecificPriorities.CULTURE  = GetPriorityCulture(data);
	tSpecificPriorities.RELIGION = GetPriorityReligion(data);
	tSpecificPriorities.DIPLO    = GetPriorityDiplo(data);
	dshowpriorities(tSpecificPriorities, "*** specific priorities "..data.LeaderType);
	
	-- time adjustment: reduce the potency of these until the mid game.
	TurnAdjustPriorities(tSpecificPriorities, GlobalParameters.RST_STRATEGY_ADJUST_SPECIFIC_START, GlobalParameters.RST_STRATEGY_ADJUST_SPECIFIC_STOP);
	--dshowpriorities(tSpecificPriorities, "specific after turn adjust");

	-- get generic priorities and adjust for time
	local tGenericPriorities:table = GetGenericPriorities(data);
	TurnAdjustPriorities(tGenericPriorities, GlobalParameters.RST_STRATEGY_ADJUST_GENERIC_START, GlobalParameters.RST_STRATEGY_ADJUST_GENERIC_STOP);
	--dshowpriorities(tGenericPriorities, "generic after turn adjust");

	-- sum it up: base adjusted, specific adjusted, generic adjusted
	PriorityTableAdd(data.Priorities, tSpecificPriorities);
	PriorityTableAdd(data.Priorities, tGenericPriorities);
	dshowpriorities(data.Priorities, "applying specific & generic priorities");
	
	-- random element
	if bUseRandom then
		--for strat,value in pairs(data.Priorities) do -- changed to ipairs for MP support
		for _,strat in ipairs(tShowStrat) do
			data.Priorities[strat] = data.Priorities[strat] + GetRandomNumber(0,GlobalParameters.RST_STRATEGY_RANDOM_PRIORITY); -- AI_GS_RAND_ROLL
		end
		dshowpriorities(data.Priorities, "applying a bit of randomization");
	end
	
	-- Give a boost to the current strategy so that small fluctuation doesn't cause a big change
	if data.ActiveStrategy ~= "NONE" then
		--print("...boosting current strategy", data.ActiveStrategy);
		--data.Priorities[data.ActiveStrategy] = data.Priorities[data.ActiveStrategy] + GetRandomNumber(GlobalParameters.RST_STRATEGY_CURRENT_PRIORITY/2, GlobalParameters.RST_STRATEGY_CURRENT_PRIORITY); -- AI_GRAND_STRATEGY_CURRENT_STRATEGY_WEIGHT
		data.Priorities[data.ActiveStrategy] = data.Priorities[data.ActiveStrategy] + GlobalParameters.RST_STRATEGY_CURRENT_PRIORITY;
		dshowpriorities(data.Priorities, "boosting current strategy "..data.ActiveStrategy);
	end
			
	-- Tally up how many players we think are pursuing each Grand Strategy
	local tBetterNum:table = PriorityTableNew();
	for _,otherID in ipairs(data.Data.MajorIDsAliveAndMet) do
		local sOtherStrategy:string = GuessOtherPlayerStrategy(data, otherID); -- WARNING! can they pursue 2 strategies? if so, make changes here!
		if sOtherStrategy ~= "NONE" then -- and sOtherStrategy == data.ActiveStrategy then -- we need to compare all, not only active!
			if OtherPlayerDoingBetterThanUs(data, otherID, sOtherStrategy) then
				if bLogDebug then print("...player", otherID, "is doing better than us with", sOtherStrategy); end
				tBetterNum[sOtherStrategy] = tBetterNum[sOtherStrategy] + 1;
			end
		end
	end
	dshowpriorities(tBetterNum, "num players better than us");
	
	-- Now modify our preferences based on how many people are going for stuff
	-- For each player following the strategy and being better than us, reduce our priority by 33%
	local tNerfFactor:table = PriorityTableNew();
	PriorityTableAdd(tNerfFactor, data.Priorities); -- copy
	PriorityTableMultiply(tNerfFactor, iBetterThanUsNerf/100.0);
	PriorityTableMultiplyByTable(tNerfFactor, tBetterNum);
	dshowpriorities(tNerfFactor, "nerf factors");
	
	--print("...final priorities", data.LeaderType);
	PriorityTableAdd(data.Priorities, tNerfFactor);
	dshowpriorities(data.Priorities, "*** final priorities "..data.LeaderType);
	
	-- 2019-01-26: Switch off not-valid victories
	PriorityTableMultiplyByTable(data.Priorities, tValidVictories);
	dshowpriorities(data.Priorities, "*** final valid "..data.LeaderType);
	
	-- Now see which Grand Strategy should be active, based on who has the highest Priority right now
	local iBestPriority:number = iMinimumPriority; --GlobalParameters.RST_STRATEGY_MINIMUM_PRIORITY; -- minimum score to activate a strategy
	for strat,value in pairs(data.Priorities) do
		if value > iBestPriority then
			iBestPriority = value;
			data.ActiveStrategy = strat;
			--data.NumTurnsActive = 0;
		end
	end
	
	-- finish
	--if data.ActiveStrategy ~= "NONE" then
		--data.NumTurnsActive = data.NumTurnsActive + 1
	--end
	--data.Dirty = false; -- data is refreshed
	data.TurnRefreshStrategy = Game.GetCurrentGameTurn(); -- data is refreshed
	if bLogDebug then print(Game.GetCurrentGameTurn(), data.LeaderType, "...selected", data.ActiveStrategy, "priority", iBestPriority); end
	
	-- log strategy to Log.lua
	if bLogStrat then
		local tLog:table = {};
		table.insert(tLog, tostring(Game.GetCurrentGameTurn()));
		table.insert(tLog, "RSTSTRAT");
		table.insert(tLog, data.LeaderType);
		table.insert(tLog, string.format("%s @ %4.1f", data.ActiveStrategy, iBestPriority)); -- guessed strategy
		for _,strat in ipairs(tShowStrat) do -- others for reference, only ones defined in tShowStrat, also include nerfs!
			local tStr:string = string.format("%s @ %4.1f", strat, data.Priorities[strat]);
			if tNerfFactor[strat] ~= 0 then tStr = tStr..string.format(" (%4.1f)", tNerfFactor[strat]); end
			table.insert(tLog, tStr);
		end 
		print(table.concat(tLog, ", "));
	end
	SavePlayerData(ePlayerID, "RefreshAndProcessData");
	--dshowrectable(tData[ePlayerID]); -- show all info
end


------------------------------------------------------------------------------
-- What others are doing?
-- This is a simplified version of main algorithms that uses only part of the information
-- (1) Leader affinity - ok, once we know who we are dealing with - human player learns that (a bit of metagaming, but it is fair)
-- (2) Victory-related stuff (yields, techs, capitals, converted civs
-- (3) Specific - government type, religion, science projects

------------------------------------------------------------------------------
function GetOtherPlayerPriorityConquest(data:table, eOtherID:number)
	--print("FUN GetOtherPlayerPriorityConquest", data.LeaderType, eOtherID);
	-- check if this victory type is enabled
	--if not RST.GameIsVictoryEnabled("VICTORY_CONQUEST") then return -200; end
	if tValidVictories.CONQUEST == 0 then return -200; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;

	-- VP includes info about attacked and captured minors
	
	-- include captured capitals
	local iNumCapturedCapitals:number = RST.PlayerGetNumCapturedCapitals(eOtherID);
	--if iNumCapturedCapitals > 1 then
	iPriority = iPriority + GlobalParameters.RST_CONQUEST_CAPTURED_CAPITAL_PRIORITY * iNumCapturedCapitals;
	--end
	if bLogDebug then print("...other player has captured", iNumCapturedCapitals, "capitals; priority=", iPriority); end
	
	-- Compare his military strength to the rest of the world
	local iWorldMilitaryStrength:number = RST.GameGetAverageMilitaryStrength(ePlayerID); -- include us and only known
	-- Reduce world average if he's rocking multiple capitals (VP specific)
	iWorldMilitaryStrength = iWorldMilitaryStrength * 100 / (100 + iNumCapturedCapitals * 10); -- ??????
	if iWorldMilitaryStrength > 0 then
		local fStrengthRatio:number = (RST.PlayerGetMilitaryStrength(eOtherID) - iWorldMilitaryStrength) / iWorldMilitaryStrength;
		local iMilitaryRatio:number = fStrengthRatio * GlobalParameters.RST_CONQUEST_POWER_RATIO_MULTIPLIER; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		if fStrengthRatio > 1.0 then -- it actually means that our power is 2x more
			-- use logarithmic function, otherwise this is getting out ot control
			iMilitaryRatio = GlobalParameters.RST_CONQUEST_POWER_RATIO_MULTIPLIER + GlobalParameters.RST_CONQUEST_POWER_RATIO_LOG_MULTIPLIER * math.log(fStrengthRatio);
		end
		iPriority = iPriority + iMilitaryRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		if bLogDebug then print("...military ratio", iMilitaryRatio, "player/world", RST.PlayerGetMilitaryStrength(eOtherID), iWorldMilitaryStrength, "priority=", iPriority); end
	end

	-- interesting, VP uses also "Warmonger threat" from Diplomacy! not sure if this can be extracted easily in Civ6
	-- InGame: Player	GetDiplomacy	GetWarmongerLevel

	-- 2019-01-27: use the scaler because Religion has 4 items scored
	iPriority = iPriority * GlobalParameters.RST_GUESS_SCALER_CONQUEST / 100;
	
	--print("GetOtherPlayerPriorityConquest", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
function GetOtherPlayerPriorityScience(data:table, eOtherID:number)
	--print("FUN GetOtherPlayerPriorityScience", data.LeaderType, eOtherID);
	-- check if this victory type is enabled
	--if not RST.GameIsVictoryEnabled("VICTORY_TECHNOLOGY") then return -200; end
	if tValidVictories.SCIENCE == 0 then return -200; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pOther:table = Players[eOtherID];

	-- if he already completed some projects, he is very likely to follow through
	local iSpaceRaceProjects:number = PlayerGetNumProjectsSpaceRace(eOtherID);
	iPriority = iPriority + iSpaceRaceProjects * GlobalParameters.RST_SCIENCE_PROJECT_WEIGHT;
	if bLogDebug then print("...space race projects", iSpaceRaceProjects, "priority=", iPriority); end

	-- Add in his base science value.
	--iPriority = iPriority + pOther:GetTechs():GetScienceYield() * GlobalParameters.RST_SCIENCE_YIELD_WEIGHT / 100.0;
	--print("...added science yield, yield", pOther:GetTechs():GetScienceYield(), "priority=", iPriority);
	
	-- VP uses an algorithm based on civ relative position in a pack by num of techs AI_GS_CULTURE_AHEAD_WEIGHT=50 - max that we can get from that
	-- seems ok however it doesn't account for how much we are ahead (or behind)
	-- similar approach to relative power - get average techs and if we are ahead, then add some weight
	-- also, account for late game - being ahead should be more valued then?
	-- num_techs_better_than_avg * per_tech
	-- no era adjustment here - if we are doing good, our position will only get better plus yield will matter more
	-- How many turns must have passed before we test for us having a weak military?

	-- Compare our num techs to the rest of the world
	--[[
	local iWorldNumTechs:number = RST.GameGetAverageNumTechsResearched(ePlayerID); --, true, true); -- include us and only known
	if iWorldNumTechs > 0 then
		-- the PICKLE here: when we are behind, we get a negative value - it is not the case with Culture nor Religion
		local iTechBoost:number = (RST.PlayerGetNumTechsResearched(eOtherID) - iWorldNumTechs) * GlobalParameters.RST_SCIENCE_TECH_WEIGHT;
		if iTechBoost > 0 then -- let's not use negatives yet
			iPriority = iPriority + iTechBoost;
		end
		print("...tech boost", iTechBoost, "player/world", RST.PlayerGetNumTechsResearched(eOtherID), iWorldNumTechs, "priority=", iPriority);
	end
	--]]
	-- How many turns must have passed before we test for us against others
	
	-- Compare his science output to the rest of the world
	-- Reduce world average if he's completed some space race projects (VP specific)
	local iWorld:number = data.Data.AvgScience * 100 / (100 + iSpaceRaceProjects * 10);
	if iWorld > 0 then
		local iRatio:number = (pOther:GetTechs():GetScienceYield() - iWorld) * GlobalParameters.RST_SCIENCE_YIELD_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's yield relative the world average.
		if bLogDebug then print("...science ratio", iRatio, "player/world", pOther:GetTechs():GetScienceYield(), iWorld, "priority=", iPriority); end
	end

	-- Compare our num techs to the rest of the world
	iWorld = data.Data.AvgTechs;
	if iWorld > 0 then
		local iRatio:number = (RST.PlayerGetNumTechsResearched(eOtherID) - iWorld) * GlobalParameters.RST_SCIENCE_TECH_WEIGHT;
		--local iRatio:number = (RST.PlayerGetNumTechsResearched(eOtherID) - iWorld) * (GlobalParameters.RST_SCIENCE_TECH_RATIO_MULTIPLIER + 3 * iWorld) / iWorld; -- slightly modified formula, adding 3*World prevents the diff from diminishing too quickly!
		iPriority = iPriority + iRatio;
		if bLogDebug then print("...tech ratio", iRatio, "player/world", RST.PlayerGetNumTechsResearched(eOtherID), iWorld, "priority=", iPriority); end
	end

	-- 2019-01-27: use the scaler because Religion has 4 items scored
	iPriority = iPriority * GlobalParameters.RST_GUESS_SCALER_SCIENCE / 100;

	--print("GetOtherPlayerPriorityScience:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
function GetOtherPlayerPriorityCulture(data:table, eOtherID:number)
	--print("FUN GetOtherPlayerPriorityCulture", data.LeaderType, eOtherID);
	-- check if this victory type is enabled
	--if not RST.GameIsVictoryEnabled("VICTORY_CULTURE") then return -200; end
	if tValidVictories.CULTURE == 0 then return -200; end
	
	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pOther:table = Players[eOtherID];

	-- Add in our base culture and tourism value
	-- VP uses /240 for culture = 3,3%, late game is getting into 5000+ => 20 pts || Civ6 ~500
	-- VP uses /1040 for tourism = 0,8%, late game is getting into 1000+ => 1 pts (?) || Civ6 ~500
	--iPriority = iPriority + pOther:GetCulture():GetCultureYield() * GlobalParameters.RST_CULTURE_YIELD_WEIGHT / 100.0;
	--print("...added culture yield, yield", pOther:GetCulture():GetCultureYield(), "priority=", iPriority);
	--iPriority = iPriority + RST.PlayerGetTourism(eOtherID) * GlobalParameters.RST_CULTURE_TOURISM_WEIGHT / 100.0;
	--print("...added tourism yield, yield", RST.PlayerGetTourism(eOtherID), "priority=", iPriority);

	-- Compare our culture output to the rest of the world
	local iWorld:number = data.Data.AvgCulture;
	if iWorld > 0 then
		local iRatio:number = (pOther:GetCulture():GetCultureYield() - iWorld) * GlobalParameters.RST_CULTURE_YIELD_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		if bLogDebug then print("...culture ratio", iRatio, "player/world", pOther:GetCulture():GetCultureYield(), iWorld, "priority=", iPriority); end
	end

	-- Compare our tourism output to the rest of the world
	--[[
	iWorld = data.Data.AvgTourism;
	if iWorld > 0 then
		local iRatio:number = (RST.PlayerGetTourism(eOtherID) - iWorld) * GlobalParameters.RST_CULTURE_TOURISM_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		print("...tourism ratio", iRatio, "player/world", RST.PlayerGetTourism(eOtherID), iWorld, "priority=", iPriority);
	end
	--]]
	
	-- in Civ5 it is influential - 50 pts. per civ getAI_GS_CULTURE_INFLUENTIAL_CIV_MOD
	-- also similar algorithm to check if we are ahead or behind - it used pure yields however, not policies or similar
	-- can't use - no info on civics available! no cheating!
	-- simple idea - the more % we have, the more it adds
	iPriority = iPriority + GlobalParameters.RST_CULTURE_PROGRESS_MULTIPLIER * (math.exp(RST.PlayerGetCultureVictoryProgress(eOtherID) * GlobalParameters.RST_CULTURE_PROGRESS_EXPONENT / 10000.0) - 1.0);
	if bLogDebug then print("...added cultural progress, perc%", RST.PlayerGetCultureVictoryProgress(eOtherID), "priority=", iPriority); end

	-- 2019-01-27: use the scaler because Religion has 4 items scored
	iPriority = iPriority * GlobalParameters.RST_GUESS_SCALER_CULTURE / 100;
	
	--print("GetOtherPlayerPriorityCulture:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
function GetOtherPlayerPriorityReligion(data:table, eOtherID:number)
	--print("FUN GetOtherPlayerPriorityReligion", data.LeaderType, eOtherID);
	-- check if this victory type is enabled
	--if not RST.GameIsVictoryEnabled("VICTORY_RELIGIOUS") then return -200; end
	if tValidVictories.RELIGION == 0 then return -200; end

	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pOther:table = Players[eOtherID];
	
	-- check if we can have a religion at all (Kongo)
	-- simple version, complex one should check ExcludedGreatPersonClasses and ExcludedDistricts, then Trait and then Leader :(
	if PlayerConfigurations[eOtherID]:GetLeaderTypeName() == "LEADER_MVEMBA" then -- TRAIT_LEADER_RELIGIOUS_CONVERT
		if bLogDebug then print("This is Kongo - no religious victory"); end
		return -200;
	end
	
	-- first, check if he has religion
	local eReligionID:number = RST.PlayerGetReligionTypeCreated(eOtherID); -- pOther:GetReligion():GetReligionTypeCreated();
	if eReligionID == -1 or eReligionID == GameInfo.Religions.RELIGION_PANTHEON.Index then
		if bLogDebug then print("...he doesn't have a religion"); end
		-- we don't have a religion - abandon this victory if we cannot get one
		if #Game.GetReligion():GetReligions() >= iMaxNumReligions then
			if bLogDebug then print("...and he cannot get one - no religious victory"); end
			return -200;
		end
	else
		iPriority = iPriority + GlobalParameters.RST_RELIGION_RELIGION_WEIGHT;
		if bLogDebug then print("...religion founded", eReligionID, "priority=", iPriority); end
	end

	-- check number of beliefs
	--iPriority = iPriority + RST.PlayerGetNumBeliefsEarned(eOtherID) * GlobalParameters.RST_RELIGION_BELIEF_WEIGHT;
	--print("...added num beliefs, num", RST.PlayerGetNumBeliefsEarned(eOtherID), "priority=", iPriority);
	
	-- faith yield - change to comparison to average?
	--iPriority = iPriority + pOther:GetReligion():GetFaithYield() * GlobalParameters.RST_RELIGION_FAITH_YIELD_WEIGHT / 100.0;
	--print("...added faith yield, yield", pOther:GetReligion():GetFaithYield(), "priority=", iPriority);
	
	-- WorldRankings displays how many civs were converted
	local iNumCivsConverted:number = PlayerGetNumCivsConverted(eOtherID);
	if iNumCivsConverted > 1 then
		iPriority = iPriority + (iNumCivsConverted-1) * GlobalParameters.RST_RELIGION_CONVERTED_WEIGHT;
		if bLogDebug then print("...converted >1 civs, num", iNumCivsConverted , "priority=", iPriority); end
	end
	
	-- Compare our faith output to the rest of the world
	-- Reduce world average if he's rocking multiple converts (VP specific) - not counting ourselves
	local iWorld:number = data.Data.AvgFaith * 100 / (100 + math.max(0,(iNumCivsConverted-1)) * 10);
	if iWorld > 0 then
		--local iRatio:number = (pOther:GetReligion():GetFaithYield() - iWorld) * GlobalParameters.RST_RELIGION_FAITH_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		local iRatio:number = (pOther:GetReligion():GetFaithYield() - iWorld) * (GlobalParameters.RST_RELIGION_FAITH_FACTOR * (data.Data.Era+1)) / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
		iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
		if bLogDebug then print("...faith ratio", iRatio, "player/world/era", pOther:GetReligion():GetFaithYield(), iWorld, data.Data.Era, "priority=", iPriority); end
	end
	-- check only if he has a religion
	--[[
	if RST.PlayerHasReligion(eOtherID) then
		iWorld = data.Data.AvgCities;
		if iWorld > 0 then
			local iRatio:number = (RST.PlayerGetNumCitiesFollowingReligion(eOtherID) - iWorld) * GlobalParameters.RST_RELIGION_CITIES_RATIO_MULTIPLIER / iWorld; -- -100 = we are at 0, 0 = we are average, +100 = we are 2x as average, +200 = we are 3x as average, etc.
			iPriority = iPriority + iRatio; -- This will add between -100 and 100 depending on this player's MilitaryStrength relative the world average. The number will typically be near 0 though, as it's fairly hard to get away from the world average
			print("...cities ratio", iRatio, "player/world", RST.PlayerGetNumCitiesFollowingReligion(eOtherID) , iWorld, "priority=", iPriority);
		end
	end
	--]]
	
	-- cities converted use expotential formula for Cities
	if data.Data.NumCitiesMajors > 0 then -- first turn
		local fCitiesProgress:number = RST.PlayerGetNumCitiesFollowingReligion(eOtherID) / data.Data.NumCitiesMajors;
		iPriority = iPriority + GlobalParameters.RST_RELIGION_CITIES_MULTIPLIER * (math.exp(fCitiesProgress * GlobalParameters.RST_RELIGION_CITIES_EXPONENT / 100.0) - 1.0);
		if bLogDebug then print("...cities progress, num, all", RST.PlayerGetNumCitiesFollowingReligion(eOtherID), data.Data.NumCitiesMajors, "priority=", iPriority); end
	end

	-- 2019-01-27: use the scaler because Religion has 4 items scored
	iPriority = iPriority * GlobalParameters.RST_GUESS_SCALER_RELIGION / 100;
	
	--print("GetOtherPlayerPriorityReligion:", iPriority);
	return iPriority;
end


------------------------------------------------------------------------------
function GetOtherPlayerPriorityDiplo(data:table, eOtherID:number)
	if bLogDebug then print("FUN GetOtherPlayerPriorityDiplo", data.LeaderType, eOtherID); end
	-- check if this victory type is enabled
	if tValidVictories.DIPLO == 0 then return -200; end

	local iPriority:number = 0;
	local ePlayerID:number = data.PlayerID;
	local pOther:table = Players[eOtherID];

	--Big milestones (like cities captured) are DV points.
	--7 and more = close to victory.
	local progress:number = RST.PlayerGetDiploVictoryProgress(eOtherID);
	iPriority = iPriority + progress * GlobalParameters.RST_DIPLO_PROGRESS_WEIGHT; -- 0.100, so each DPV = 50
	if progress > 50 then iPriority = iPriority + (progress - 50) * GlobalParameters.RST_DIPLO_PROGRESS_WEIGHT; end
	if bLogDebug then print("...diplo progress", progress, iPriority); end
	
	--Yield here is Favor per turn (FPT). It is rather rare, 20-30 is a lot.
	local totalFavor:number   = pOther:GetDiplomacy():GetFavor(); 
	local favorPerTurn:number = pOther:GetDiplomacy():GetFavorPerTurn();
	iPriority = iPriority + favorPerTurn * GlobalParameters.RST_DIPLO_FAVOR_PER_TURN_WEIGHT;
	if bLogDebug then print("...favor per turn", favorPerTurn, iPriority); end
	
	iPriority = iPriority * GlobalParameters.RST_GUESS_SCALER_DIPLO / 100;
	
	if bLogDebug then print("GetOtherPlayerPriorityDiplo:", iPriority); end
	return iPriority;
end


------------------------------------------------------------------------------
function GuessOtherPlayerStrategy(data:table, eOtherID:number)
	if bLogDebug then print(Game.GetCurrentGameTurn(), "FUN GuessOtherPlayerStrategy", data.PlayerID, eOtherID); end
	
	local sLeaderType:string = PlayerConfigurations[eOtherID]:GetLeaderTypeName();

	-- get specifics
	local tSpecificPriorities:table = PriorityTableNew();
	tSpecificPriorities.CONQUEST = GetOtherPlayerPriorityConquest(data, eOtherID);
	tSpecificPriorities.SCIENCE  = GetOtherPlayerPriorityScience(data, eOtherID);
	tSpecificPriorities.CULTURE  = GetOtherPlayerPriorityCulture(data, eOtherID);
	tSpecificPriorities.RELIGION = GetOtherPlayerPriorityReligion(data, eOtherID);
	tSpecificPriorities.DIPLO    = GetOtherPlayerPriorityDiplo(data, eOtherID);
	dshowpriorities(tSpecificPriorities, "*** specific priorities "..sLeaderType);
	-- no turn adjustment because we don't have the base priorities
	
	-- we do not know all generic info, so what we know is boosted
	
	-- GOVERNMENT
	--print("...generic: government", sLeaderType);
	local sGovType:string = GameInfo.Governments[ RST.PlayerGetCurrentGovernment(eOtherID) ].GovernmentType;
	local tGovPriorities:table = PriorityTableNew();
	if tPriorities[sGovType] then PriorityTableAdd(tGovPriorities, tPriorities[sGovType].Priorities);
	else                          print("WARNING: GuessOtherPlayerStrategy government", sGovType, "not defined in Priorities"); end
	PriorityTableMultiply(tGovPriorities, 2.0 * GlobalParameters.RST_WEIGHT_GOVERNMENT/100);
	dshowpriorities(tGovPriorities, "generic government "..string.gsub(sGovType, "GOVERNMENT_", ""));
	
	-- GREAT PEOPLE
	--print("...generic: great people", sLeaderType);
	local tGPs:table = RST.PlayerGetRecruitedGreatPeopleClasses(eOtherID);
	local tGPPriorities:table = PriorityTableNew();
	for _,class in ipairs(tGPs) do
		if tPriorities[class] then PriorityTableAdd(tGPPriorities, tPriorities[class].Priorities);
		else                       print("WARNING: GuessOtherPlayerStrategy great person class", class, "not defined in Priorities"); end
	end
	PriorityTableMultiply(tGPPriorities, 1.5 * GlobalParameters.RST_WEIGHT_GREAT_PERSON/100);
	dshowpriorities(tGPPriorities, "generic great people");
	
	-- CITY STATES
	--print("...generic: city states", sLeaderType);
	local tMinorPriorities:table = PriorityTableNew();
	for _,minor in ipairs(PlayerManager.GetAliveMinors()) do
		if minor:GetInfluence():GetSuzerain() == eOtherID then
			local sCategory:string = GetCityStateCategory(minor:GetID());
			--print("...suzerain of", sCategory);
			PriorityTableAdd(tMinorPriorities, tPriorities[sCategory].Priorities);
		end
	end
	PriorityTableMultiply(tMinorPriorities, 2.0 * GlobalParameters.RST_WEIGHT_MINOR/100);
	dshowpriorities(tMinorPriorities, "generic city states");
	
	-- no randomization while guessing (guess is random enough :))
	
	local tSumPriorities:table = PriorityTableNew(); -- final here
	PriorityTableAdd(tSumPriorities, tGovPriorities);
	PriorityTableAdd(tSumPriorities, tGPPriorities);
	PriorityTableAdd(tSumPriorities, tMinorPriorities);
	-- turn adjusted because at the begining they are insignificant
	TurnAdjustPriorities(tSumPriorities, GlobalParameters.RST_STRATEGY_ADJUST_GENERIC_START, GlobalParameters.RST_STRATEGY_ADJUST_GENERIC_STOP);

	-- get total
	PriorityTableAdd(tSumPriorities, tSpecificPriorities);
	dshowpriorities(tSumPriorities, "*** sum of all priorities "..sLeaderType);

	-- 2019-01-26: Switch off not-valid victories
	PriorityTableMultiplyByTable(tSumPriorities, tValidVictories);
	dshowpriorities(tSumPriorities, "*** sum of all valid "..sLeaderType);
	
	-- Now see which Grand Strategy should be active, based on who has the highest Priority right now
	local sGuessStrategy:string = "NONE";
	local iBestPriority:number = 0; -- GlobalParameters.RST_STRATEGY_MINIMUM_PRIORITY * 0.5; -- minimum score to activate a strategy
	for strat,value in pairs(tSumPriorities) do
		if value > iBestPriority then
			iBestPriority = value;
			sGuessStrategy = strat;
		end
	end
	if bLogDebug then print(Game.GetCurrentGameTurn(), sLeaderType, "...guessed", sGuessStrategy, "priority", iBestPriority); end
	
	-- log guesses to Log.lua
	if bLogGuess then
		local tLog:table = {};
		table.insert(tLog, tostring(Game.GetCurrentGameTurn()));
		table.insert(tLog, "RSTGUESS");
		table.insert(tLog, data.LeaderType); -- who is guessing
		table.insert(tLog, sLeaderType); -- whom to guess
		table.insert(tLog, string.format("%s @ %4.1f", sGuessStrategy, iBestPriority)); -- guessed strategy
		for _,strat in ipairs(tShowStrat) do table.insert(tLog, string.format("%s @ %4.1f", strat, tSumPriorities[strat])); end -- others for reference, only ones defined in tShowStrat
		print(table.concat(tLog, ", "));
	end
	
	return sGuessStrategy;
end


------------------------------------------------------------------------------
-- Test if other player is doing better than we in a specific strategy
-- Returns TRUE only if better, equal returns false
-- there also approx. 5% slack in comparison to allow for small fluctuations
function OtherPlayerDoingBetterThanUs(data:table, eOtherID:number, sStrategy:string)
	if bLogDebug then print("FUN OtherPlayerDoingBetterThanUs", data.PlayerID, eOtherID, sStrategy); end
	if sStrategy == "NONE" then return false; end
	local ePlayerID:number = data.PlayerID;
	------------------------------------------------------------------------------
	if sStrategy == "CONQUEST" then
		local iNumCapitalsUs:number   = RST.PlayerGetNumCapturedCapitals(ePlayerID);
		local iNumCapitalsThem:number = RST.PlayerGetNumCapturedCapitals(eOtherID);
		local iMilitaryPowerUs:number   = math.max(1, RST.PlayerGetMilitaryStrength(ePlayerID));
		local iMilitaryPowerThem:number = math.max(1, RST.PlayerGetMilitaryStrength(eOtherID));
		if bLogDebug then print("cities us/them", iNumCapitalsUs, iNumCapitalsThem, "power us/them", iMilitaryPowerUs, iMilitaryPowerThem); end
		-- basically, each taken capital is worth an entire army
		iMilitaryPowerUs   = iMilitaryPowerUs   * math.max(1, iNumCapitalsUs);
		iMilitaryPowerThem = iMilitaryPowerThem * math.max(1, iNumCapitalsThem);
		return iMilitaryPowerThem / iMilitaryPowerUs > 1.05; -- allow for 5% slack
	------------------------------------------------------------------------------
	elseif sStrategy == "SCIENCE" then
		local iSpaceRaceProjectsUs:number   = PlayerGetNumProjectsSpaceRace(ePlayerID);
		local iSpaceRaceProjectsThem:number = PlayerGetNumProjectsSpaceRace(eOtherID);
		local iNumTechsUs:number = RST.PlayerGetNumTechsResearched(ePlayerID);
		local iNumTechsThem:number = RST.PlayerGetNumTechsResearched(eOtherID);
		if bLogDebug then print("projects us/them", iSpaceRaceProjectsUs, iSpaceRaceProjectsThem, "techs us/them", iNumTechsUs, iNumTechsThem); end
		-- compare projects
		if iSpaceRaceProjectsThem > iSpaceRaceProjectsUs then return true; end
		if iSpaceRaceProjectsThem < iSpaceRaceProjectsUs then return false; end
		-- compare techs
		return (iNumTechsThem - iNumTechsUs) > 1; -- allow for 1 tech of slack
	------------------------------------------------------------------------------
	elseif sStrategy == "CULTURE" then
		local iProgressUs:number   = RST.PlayerGetCultureVictoryProgress(ePlayerID);
		local iProgressThem:number = RST.PlayerGetCultureVictoryProgress(eOtherID);
		local iCultureUs:number   = math.max(1, Players[ePlayerID]:GetCulture():GetCultureYield());
		local iCultureThem:number = math.max(1, Players[eOtherID]:GetCulture():GetCultureYield());
		--local iTourismUs:number   = math.max(1, RST.PlayerGetTourism(ePlayerID));
		--local iTourismThem:number = math.max(1, RST.PlayerGetTourism(eOtherID));
		if bLogDebug then print("progress us/them", iProgressUs, iProgressThem, "culture us/them", iCultureUs, iCultureThem); end
		-- compare actual victory progress, however we are considered equal if difference is less than 5pp
		if (iProgressThem - iProgressUs) > 5 then return true; end
		-- otherwise, compare coulture output, again with 5% slack
		return (iCultureThem / iCultureUs) > 1.05;
		-- Civ 5 compares also Culture yield, but it is not so important in Civ6 - changed from Tourism into Culture, Tourism is too volatile early game
	------------------------------------------------------------------------------
	elseif sStrategy == "RELIGION" then
		local iConvertedUs:number   = PlayerGetNumCivsConverted(ePlayerID);
		local iConvertedThem:number = PlayerGetNumCivsConverted(eOtherID);
		local iFaithUs:number   = math.max(1, Players[ePlayerID]:GetReligion():GetFaithYield());
		local iFaithThem:number = math.max(1, Players[eOtherID]:GetReligion():GetFaithYield());
		if bLogDebug then print("converts us/them", iConvertedUs, iConvertedThem, "faith us/them", iFaithUs, iFaithThem); end
		-- compare number of civs converted multiplies by Faith yield (see also Conquest)
		-- basically 1 converted Civ is worth entire yield output
		iFaithUs   = iFaithUs   * math.max(1, iConvertedUs);
		iFaithThem = iFaithThem * math.max(1, iConvertedThem);
		return iFaithThem / iFaithUs > 1.05; -- allow for 5% slack
	------------------------------------------------------------------------------
	elseif sStrategy == "DIPLO" then
		-- compare number of diplo victory points
		local iProgressUs:number   = RST.PlayerGetDiploVictoryProgress(ePlayerID);
		local iProgressThem:number = RST.PlayerGetDiploVictoryProgress(eOtherID);
		-- calculate how much favor players gonna have during the next voting
		local iNumTurnsWC:number = RST.WorldCongressGetTurnsLeft(); -- num turns to the next world congress
		local iFavorUs:number   = math.max(1, Players[ePlayerID]:GetDiplomacy():GetFavor()) + iNumTurnsWC * Players[ePlayerID]:GetDiplomacy():GetFavorPerTurn();
		local iFavorThem:number = math.max(1, Players[eOtherID]:GetDiplomacy():GetFavor())  + iNumTurnsWC * Players[eOtherID]:GetDiplomacy():GetFavorPerTurn();
		if bLogDebug then print("progress us/them", iProgressUs, iProgressThem, "favor us/them", iFavorUs, iFavorThem); end
		-- compare actual victory progress, however we are considered equal if difference is less than 15pp
		if (iProgressThem - iProgressUs) > 15 then return true; end
		-- otherwise, compare favor poll; to safely outvote the opponent, we need 20-50% more favor (favor => votes relation is not linear)
		return (iFavorThem / iFavorUs) > 1.25;
	------------------------------------------------------------------------------
	else
		print("WARNING: OtherPlayerDoingBetterThanUs, unknown strategy", sStrategy);
		return false;
	end
end


-- ===========================================================================
-- GAME EVENTS
-- ===========================================================================

------------------------------------------------------------------------------
-- PlayerTurnActivated = { "player", "bIsFirstTime" },
-- TESTING - it should be deactivated later, there is no need to call this here
--[[
function OnPlayerTurnActivated( ePlayerID:number, bIsFirstTime:boolean)
	print("FUN OnPlayerTurnActivated", ePlayerID, bIsFirstTime);
	RefreshAndProcessData(ePlayerID);
end
--]]

------------------------------------------------------------------------------
-- PlayerTurnDeactivated = { "player" },
-- TESTING
--[[
function OnPlayerTurnDeactivated(ePlayerID:number)
	print("FUN OnPlayerTurnDeactivated", ePlayerID);
	local pPlayer:table = Players[ePlayerID];
	if not (pPlayer ~= nil and pPlayer:IsAlive() and pPlayer:IsMajor()) then return; end
	tData[ePlayerID].Dirty = true; -- default mode - later can be changed for specific events (e.g. Policy changed, gov changed, etc.)
end
--]]


------------------------------------------------------------------------------
-- StrategyConditions calls via 'Call Lua Function'
-- Called separately for each player, including Minors, Free Cities and Barbarians
-- For player X it is called BEFORE PlayerTurnActivated(X)
-- For a Human, it is called AFTER LocalPlayerTurnBegin, but before PlayerTurnActivated(0)
-- Please note that Conditions are checked in the order they are defined in the DB, so it is
-- recommended to put Disqualifers at the begining i.e. for Minors
------------------------------------------------------------------------------

function ActiveStrategyConquest(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyConquest", ePlayerID, iThreshold);
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "CONQUEST");
	return tData[ePlayerID].ActiveStrategy == "CONQUEST";
end
GameEvents.ActiveStrategyConquest.Add(ActiveStrategyConquest);

function ActiveStrategyScience(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyScience", ePlayerID, iThreshold);
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "SCIENCE");
	return tData[ePlayerID].ActiveStrategy == "SCIENCE";
end
GameEvents.ActiveStrategyScience.Add(ActiveStrategyScience);

function ActiveStrategyCulture(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyCulture", ePlayerID, iThreshold);
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "CULTURE");
	return tData[ePlayerID].ActiveStrategy == "CULTURE";
end
GameEvents.ActiveStrategyCulture.Add(ActiveStrategyCulture);

function ActiveStrategyReligion(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyReligion", ePlayerID, iThreshold);
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "RELIGION");
	return tData[ePlayerID].ActiveStrategy == "RELIGION";
end
GameEvents.ActiveStrategyReligion.Add(ActiveStrategyReligion);

function ActiveStrategyDiplo(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyDiplo", ePlayerID, iThreshold);
	RefreshAndProcessData(ePlayerID);
	--print(Game.GetCurrentGameTurn(), "...strategy is", tData[ePlayerID].ActiveStrategy, tData[ePlayerID].ActiveStrategy == "DIPLO");
	return tData[ePlayerID].ActiveStrategy == "DIPLO";
end
GameEvents.ActiveStrategyDiplo.Add(ActiveStrategyDiplo);

-- for testing purposes only
function CheckTurnNumber(iPlayerID:number, iThreshold:number)
	print(Game.GetCurrentGameTurn(), "FUN CheckTurnNumber", iPlayerID, iThreshold);
	return Game.GetCurrentGameTurn() >= iThreshold;
end
GameEvents.CheckTurnNumber.Add(CheckTurnNumber);


-- helper, get number of wars and opponents power
function PlayerGetNumWars(ePlayerID:number)
	local iNumWars:number, iOpponentPower:number = 0,0;
	local pPlayerDiplomacy:table = Players[ePlayerID]:GetDiplomacy();
	for _,otherID in ipairs(PlayerManager:GetAliveMajorIDs()) do
		if pPlayerDiplomacy:IsAtWarWith(otherID) then
			iNumWars = iNumWars + 1;
			iOpponentPower = iOpponentPower + RST.PlayerGetMilitaryStrength(otherID);
		end
	end
	return iNumWars, iOpponentPower;
end


------------------------------------------------------------------------------
-- DEFENSE
-- Lua doesn't provide direct information on who has started the war.
-- There is an event that can be used Events.DiplomacyDeclareWar.Add( OnDiplomacyDeclareWar(actingPlayer, reactingPlayer) );

-- first version, simple - just check for War, Capital and MilitaryStrength
-- can use later iThreshold for e.g. number of simultaneus wars
-- or strength difference

function ActiveStrategyDefense(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyDefense", ePlayerID, iThreshold);
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	--RefreshAndProcessData(ePlayerID);
	local data:table = tData[ePlayerID];
	local iOurPower:number = RST.PlayerGetMilitaryStrength(ePlayerID);
	local iNumWars:number, iOpponentPower:number = PlayerGetNumWars(ePlayerID);
	--[[
	local pPlayerDiplomacy:table = Players[ePlayerID]:GetDiplomacy();
	for _,otherID in ipairs(PlayerManager:GetAliveMajorIDs()) do
		if pPlayerDiplomacy:IsAtWarWith(otherID) then
			iNumWars = iNumWars + 1;
			iOpponentPower = iOpponentPower + RST.PlayerGetMilitaryStrength(otherID);
		end
	end
	--]]
	data.ActiveDefense = iOurPower*100 < iOpponentPower*iThreshold;
	if iNumWars == 0 then data.ActiveDefense = false; end
	if bLogOther then print(Game.GetCurrentGameTurn(),"RSTDEFEN", ePlayerID, iThreshold, "...power our/theirs", iOurPower, iOpponentPower, "wars", iNumWars, "active?", data.ActiveDefense); end
	-- must add some kind of momentum - game doesn't react so quickly?? or maybe not, this could be a nice counterattack
	-- peace -> war: 50+10 i.e. 60% - must start faster?
	-- war -> war: 50-10 - must stop a bit earlier, because cities will produce units from the queue - I could include units in production - need special function for that
	-- for _,c in Players[1]:GetCities():Members() do print(c:GetName(),c:GetBuildQueue():CurrentlyBuilding()) end
	-- war -> peace: stops immediately
	SavePlayerData(ePlayerID, "ActiveStrategyDefense");
	return data.ActiveDefense;
end
GameEvents.ActiveStrategyDefense.Add(ActiveStrategyDefense);


------------------------------------------------------------------------------
-- CATCHING
-- will activate if our power falls below iThreshold% of the World average (known civs)
-- this should be approx. 40% because it includes also us and we are low
-- use data.Data.AvgMilStr
-- similar mechanism could be used also for Yields, like YIELD_SCIENCE, YIELD_CULTURE, etc.
function ActiveStrategyCatching(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyCatching", ePlayerID, iThreshold);
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	local data:table = tData[ePlayerID];
	if data == nil or data.Data == nil then return false; end
	if data.Data.ElapsedTurns < GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then return false; end -- don't compare yet
	if data.Data.AvgMilStr == nil then return false; end -- not calculated yet
	local iOurPower:number = RST.PlayerGetMilitaryStrength(ePlayerID);
	data.ActiveCatching = iOurPower*100 < data.Data.AvgMilStr*iThreshold;
	if bLogOther then print(Game.GetCurrentGameTurn(), "RSTCATCH", ePlayerID, iThreshold, "...power our/theirs", iOurPower, data.Data.AvgMilStr, "active?", data.ActiveCatching); end
	SavePlayerData(ePlayerID, "ActiveStrategyCatching");
	return data.ActiveCatching;
end
GameEvents.ActiveStrategyCatching.Add(ActiveStrategyCatching);


------------------------------------------------------------------------------
-- ENOUGH
-- will activate if our power will rise above iThreshold% of the World average (known civs)
-- this should be approx. 250% because it includes also us and we are high
-- use data.Data.AvgMilStr
-- similar mechanism could be used also for Yields, like YIELD_SCIENCE, YIELD_CULTURE, etc.
function ActiveStrategyEnough(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyEnough", ePlayerID, iThreshold);
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	local data:table = tData[ePlayerID];
	if data == nil or data.Data == nil then return false; end
	if data.Data.ElapsedTurns < GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then return false; end -- don't compare yet
	if data.Data.AvgMilStr == nil then return false; end -- not calculated yet
	local iOurPower:number = RST.PlayerGetMilitaryStrength(ePlayerID);
	data.ActiveEnough = iOurPower*100 > data.Data.AvgMilStr*iThreshold;
	if bLogOther then print(Game.GetCurrentGameTurn(), "RSTENOUG", ePlayerID, iThreshold, "...power our/theirs", iOurPower, data.Data.AvgMilStr, "active?", data.ActiveEnough); end
	SavePlayerData(ePlayerID, "ActiveStrategyEnough");
	return data.ActiveEnough;
end
GameEvents.ActiveStrategyEnough.Add(ActiveStrategyEnough);


------------------------------------------------------------------------------
-- PEACE
function ActiveStrategyPeace(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyPeace", ePlayerID, iThreshold);
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	local data:table = tData[ePlayerID];
	local iNumWars:number, _ = PlayerGetNumWars(ePlayerID);
	data.ActivePeace = iNumWars == 0;
	if bLogOther then print(Game.GetCurrentGameTurn(),"RSTPEACE", ePlayerID, iThreshold, "...wars", iNumWars, "active?", data.ActivePeace); end
	SavePlayerData(ePlayerID, "ActiveStrategyPeace");
	return data.ActivePeace;
end
GameEvents.ActiveStrategyPeace.Add(ActiveStrategyPeace);


------------------------------------------------------------------------------
-- WAR
function ActiveStrategyAtWar(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyAtWar", ePlayerID, iThreshold);
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	local data:table = tData[ePlayerID];
	local iNumWars:number, _ = PlayerGetNumWars(ePlayerID);
	data.ActiveAtWar = iNumWars > 0;
	if bLogOther then print(Game.GetCurrentGameTurn(),"RSTATWAR", ePlayerID, iThreshold, "...wars", iNumWars, "active?", data.ActiveAtWar); end
	SavePlayerData(ePlayerID, "ActiveStrategyAtWar");
	return data.ActiveAtWar;
end
GameEvents.ActiveStrategyAtWar.Add(ActiveStrategyAtWar);


------------------------------------------------------------------------------
-- Simple catching up when falling behind the average num of techs
-- Will not activate if there is a Campus being produced

function ActiveStrategyMoreScience(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyMoreScience", ePlayerID, iThreshold);
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	local data:table = tData[ePlayerID];
	if data == nil or data.Data == nil then return false; end
	if data.Data.ElapsedTurns < GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then return false; end -- don't compare yet
	if data.Data.AvgTechs == nil then return false; end -- not calculated yet
	if IsPlayerBuilding(ePlayerID, "DISTRICT_CAMPUS") or IsPlayerBuilding(ePlayerID, "DISTRICT_SEOWON") then
		if bLogOther then print(Game.GetCurrentGameTurn(), "RSTSCIEN", ePlayerID, iThreshold, "...Campus is being produced - not active"); end
		return false;
	end
	-- actual comparison
	local iOurTechs:number = RST.PlayerGetNumTechsResearched(ePlayerID);
	-- threshold: 0.1 * num + 1, it gives nice 2,3,4,.. for 10,20,30,.. techs => call with iThreshold = 90
	data.ActiveScience = iOurTechs*100 < data.Data.AvgTechs*iThreshold - 125; -- 1 tech = 100
	if bLogOther then print(Game.GetCurrentGameTurn(), "RSTSCIEN", ePlayerID, iThreshold, "...techs our/avg", iOurTechs, data.Data.AvgTechs, "active?", data.ActiveScience); end
	SavePlayerData(ePlayerID, "ActiveStrategyMoreScience");
end
GameEvents.ActiveStrategyMoreScience.Add(ActiveStrategyMoreScience);


------------------------------------------------------------------------------
-- Simple catching up when falling behind the average culture
-- This functions also as a counter to Tourism to some extent
-- Will not activate if there is a Theater being produced

function ActiveStrategyMoreCulture(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyMoreCulture", ePlayerID, iThreshold);
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	local data:table = tData[ePlayerID];
	if data == nil or data.Data == nil then return false; end
	if data.Data.ElapsedTurns < GlobalParameters.RST_STRATEGY_COMPARE_OTHERS_NUM_TURNS then return false; end -- don't compare yet
	if data.Data.AvgCulture == nil then return false; end -- not calculated yet
	if IsPlayerBuilding(ePlayerID, "DISTRICT_THEATER") or IsPlayerBuilding(ePlayerID, "DISTRICT_ACROPOLIS") then
		if bLogOther then print(Game.GetCurrentGameTurn(), "RSTCULTR", ePlayerID, iThreshold, "...Theater is being produced - not active"); end
		return false;
	end
	-- actual comparison
	local iOurCulture:number = Players[ePlayerID]:GetCulture():GetCultureYield();
	-- culture reaches high values, so we can go with just %, approx. 75-80%
	data.ActiveCulture = iOurCulture*100 < data.Data.AvgCulture*iThreshold;
	if bLogOther then print(Game.GetCurrentGameTurn(), "RSTCULTR", ePlayerID, iThreshold, "...culture our/avg", iOurCulture, data.Data.AvgCulture, "active?", data.ActiveCulture); end
	SavePlayerData(ePlayerID, "ActiveStrategyMoreCulture");
end
GameEvents.ActiveStrategyMoreCulture.Add(ActiveStrategyMoreCulture);


-- ===========================================================================
-- ANTI STRATEGIES
-- Activation conditions are very simple. They are global.
-- ===========================================================================

function ActiveStrategyAntiConquest(ePlayerID:number, iThreshold:number)
	return tValidVictories.CONQUEST == 0;
end
GameEvents.ActiveStrategyAntiConquest.Add(ActiveStrategyAntiConquest);

function ActiveStrategyAntiCulture(ePlayerID:number, iThreshold:number)
	return tValidVictories.CULTURE == 0;
end
GameEvents.ActiveStrategyAntiCulture.Add(ActiveStrategyAntiCulture);

function ActiveStrategyAntiReligion(ePlayerID:number, iThreshold:number)
	return tValidVictories.RELIGION == 0;
end
GameEvents.ActiveStrategyAntiReligion.Add(ActiveStrategyAntiReligion);

function ActiveStrategyAntiScience(ePlayerID:number, iThreshold:number)
	return tValidVictories.SCIENCE == 0;
end
GameEvents.ActiveStrategyAntiScience.Add(ActiveStrategyAntiScience);

function ActiveStrategyAntiDiplo(ePlayerID:number, iThreshold:number)
	return tValidVictories.DIPLO == 0;
end
GameEvents.ActiveStrategyAntiDiplo.Add(ActiveStrategyAntiDiplo);


-- ===========================================================================
-- NAVAL STRATEGIES SUPPORT
-- ===========================================================================

------------------------------------------------------------------------------
-- Detection algorithm - calculates percentage of the coast in relation to the total land
-- Coast is considered a land that has sea within N tiles, algorithm uses 2 as default
-- I've tested it also with N=3 - gives better results for Islands but N=2 is better overall
-- Algorithm only counts revealed tiles, however it "knows" where the sea is even if it is not revealed
-- This small cheat compensates the fact that human player chooses the map and simply knows in advance what it is :)
-- Note: the algorithm considers Lakes as part of the land.

function IsPlotLand(pPlot:table)
	if pPlot:IsWater() then return pPlot:IsLake(); end
	return true;
end

function IsPlotWater(pPlot:table) -- no lakes!
	if pPlot:IsWater() then return not pPlot:IsLake(); end
	return false;
end

-- works only for Land!
function HasWaterWithinRange(pStartingPlot:table, iRange:number)
	if IsPlotWater(pStartingPlot) then return false; end
	local iPlotX:number = pStartingPlot:GetX(); 
	local iPlotY:number = pStartingPlot:GetY();
	-- iterate through plots
	for dy = -iRange, iRange do
		for dx = -iRange, iRange do
			local pPlot:table = Map.GetPlotXYWithRangeCheck(iPlotX, iPlotY, dx, dy, iRange);
			if pPlot and IsPlotWater(pPlot) then return true; end
		end
	end
	return false;
end

-- return a percentage of Coast to Land for all Revealed tiles, and num of Revealed tiles
function PlayerCalculateIslandFactor(ePlayerID:number, iRange:number)
	--print("FUN PlayerCalculateIslandFactor");
	
	local pPlayerVis:table = PlayersVisibility[ePlayerID];
	local iLand:number, iCoast:number, iRev:number = 0, 0, 0;
	for idx = 0, Map.GetPlotCount()-1 do
		if pPlayerVis:IsRevealed(idx) then
			iRev = iRev + 1;
			local pPlot:table = Map.GetPlotByIndex(idx);
			if IsPlotLand(pPlot) then
				iLand = iLand + 1;
				if HasWaterWithinRange(pPlot, iRange) then iCoast = iCoast + 1; end
			end
		end
	end
	--print("...rev/land/coast", iRev, iLand, iCoast);
	if iLand == 0 then return 0, iRev; end -- should never happen for majors, may happen for Free Cities
	return math.floor(iCoast * 100 / iLand), iRev;
end

local iThresholdPangea:number  = GlobalParameters.RST_NAVAL_THRESHOLD_PANGEA;
local iThresholdCoastal:number = GlobalParameters.RST_NAVAL_THRESHOLD_COASTAL;
local iThresholdIsland:number  = GlobalParameters.RST_NAVAL_THRESHOLD_ISLAND;

function InitializeNaval()
	if bLogDebug then print("Initial naval thresholds",iThresholdPangea,iThresholdCoastal,iThresholdIsland); end
	local iMapSize:number = math.floor( Map.GetPlotCount()/570 + 0.5 );
	local iDelta:number = (iMapSize - GlobalParameters.RST_NAVAL_MAP_SIZE_DEFAULT) * GlobalParameters.RST_NAVAL_MAP_SIZE_SHIFT / 100;
	if bLogDebug then print("Map Size & Delta", iMapSize, iDelta); end
	iThresholdPangea = iThresholdPangea + iDelta;
	iThresholdCoastal = iThresholdCoastal + iDelta;
	iThresholdIsland = iThresholdIsland + iDelta;
	if bLogDebug then print("Final naval thresholds",iThresholdPangea,iThresholdCoastal,iThresholdIsland); end
end

function RefreshNavalData(ePlayerID:number)
	--print(Game.GetCurrentGameTurn(), "FUN RefreshNavalData", ePlayerID);

	-- check if data needs to be refreshed
	local data:table = tData[ePlayerID];
	if data == nil or data.Data == nil then return false; end	
	if data.TurnRefreshNaval == Game.GetCurrentGameTurn() then return; end -- we already refreshed on this turn
	
	-- active turns with game speed scaling
	local iNumTurnsActive:number = GameGetNumTurnsScaled(Game.GetCurrentGameTurn() - data.TurnRefreshNaval);
	--if data.TurnRefreshNaval == -1 then iNumTurnsActive = GameGetNumTurnsScaled(Game.GetCurrentGameTurn() - GameConfiguration.GetStartTurn()); end
	--print(Game.GetCurrentGameTurn(), data.LeaderType, "...old naval strategy", data.ActiveNaval, "turn refresh", data.TurnRefreshNaval, "active for", iNumTurnsActive, "turns");
	if iNumTurnsActive < GlobalParameters.RST_NAVAL_NUM_TURNS then
		--print("...not active long enough");
		return;
	end
	local iCoastFactor:number, iNumRevealed:number = PlayerCalculateIslandFactor(ePlayerID, 2);
	
	-- ok, time to determine the strategy
	data.ActiveNaval = 1; -- default
	if     iCoastFactor < iThresholdPangea  then data.ActiveNaval = 0; -- Pangea
	elseif iCoastFactor > iThresholdIsland  then data.ActiveNaval = 3; -- Island
	elseif iCoastFactor > iThresholdCoastal then data.ActiveNaval = 2; end -- Coastal
	data.TurnRefreshNaval = Game.GetCurrentGameTurn();
	data.NavalFactor = iCoastFactor;
	data.NavalRevealed = iNumRevealed;
	if bLogOther then print(Game.GetCurrentGameTurn(), "RSTNAVAL", ePlayerID, "...factor/revealed", iCoastFactor, iNumRevealed, "active naval", data.ActiveNaval); end
	SavePlayerData(ePlayerID, "RefreshNavalData");
end

function ActiveStrategyNaval(ePlayerID:number, iThreshold:number)
	if ePlayerID == 62 or ePlayerID == 63 then return false; end
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	RefreshNavalData(ePlayerID);
	return tData[ePlayerID].ActiveNaval == iThreshold;
end
GameEvents.ActiveStrategyNaval.Add(ActiveStrategyNaval);

-- iThreshold - max num of cities
function ActiveStrategyExploreLand(ePlayerID:number, iThreshold:number)
	--print("FUN ActiveStrategyExploreLand", ePlayerID, iThreshold);
	if ePlayerID == 62 or ePlayerID == 63 then return false; end
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	--print("...cities", Players[ePlayerID]:GetCities():GetCount());
	if Players[ePlayerID]:GetCities():GetCount() > iThreshold then return false; end
	RefreshNavalData(ePlayerID);
	--print("...naval", tData[ePlayerID].ActiveNaval, "active?", tData[ePlayerID].ActiveNaval < 2);
	return tData[ePlayerID].ActiveNaval < 2; -- includes 0 (Pangea) & 1 (Default)
end
GameEvents.ActiveStrategyExploreLand.Add(ActiveStrategyExploreLand);


------------------------------------------------------------------------------
-- Threat Detection
-- Diplo Relation – Unfriendly / Denounced?
-- Military – Comparable / Weak / Very weak
-- Comparable = not less than 75%? / Weak 50-75% / Very weak < 50%
-- Unfriendly + Very weak = Threat
-- Denounced + Weak/Very weak = Threat
-- for i=0,5 do pd=Players[i]:GetAi_Diplomacy(); print(i,pd:GetDiplomaticState(3),pd:GetDiplomaticScore(3)) end
-- How to detect if we are close to each other? Easy, go through all plots? No, only Cities and check how far they. The further, the less threat.

function ActiveStrategyThreat(ePlayerID:number, iThreshold:number)
	--print(Game.GetCurrentGameTurn(), "FUN ActiveStrategyThreat", ePlayerID, iThreshold);
	if not PlayerManager.IsAlive(ePlayerID) then return false; end -- have faith in the engine -- nope :( GH #15
	local data:table = tData[ePlayerID];
	local iNumWars:number, _ = PlayerGetNumWars(ePlayerID);
	data.ActiveThreat = iNumWars > 0;
	if bLogOther then print(Game.GetCurrentGameTurn(),"RSTATWAR", ePlayerID, iThreshold, "...wars", iNumWars, "active?", data.ActiveThreat); end
	return data.ActiveThreat;
end
GameEvents.ActiveStrategyThreat.Add(ActiveStrategyThreat);


------------------------------------------------------------------------------
-- 2019-03-20 GameEvents not available in UI context
--[[ 2019-03-23
function ActiveStrategyMoreGreatWorkSlots(ePlayerID:number, iThreshold:number)
	if RST.ActiveStrategyMoreGreatWorkSlots == nil then
		print(Game.GetCurrentGameTurn(), "Warning! ActiveStrategyMoreGreatWorkSlots not connected.", ePlayerID, iThreshold);
		return false;
	end -- not connected
	return RST.ActiveStrategyMoreGreatWorkSlots(ePlayerID, iThreshold);
end
GameEvents.ActiveStrategyMoreGreatWorkSlots.Add(ActiveStrategyMoreGreatWorkSlots);
--]]


------------------------------------------------------------------------------
-- MoveUnit from Gameplay context
--[[
function MoveUnitToPlot(ePlayerID:number, iUnitID:number, iX:number, iY:number)
	--print("FUN MoveUnitToPlot", ePlayerID, iUnitID, iX, iY);
	local pUnit:table = UnitManager.GetUnit(ePlayerID, iUnitID);
	if pUnit ~= nil then UnitManager.MoveUnit(pUnit, iX, iY); end
end
RST.MoveUnitToPlot = MoveUnitToPlot;
--]]


-- ===========================================================================
-- SAVING/LOADING PERSISTENT DATA
-- ===========================================================================
-- 1. Saving - all data is saved in SavePlayerData function called in events that change the data
--   Warning! Cannot use SaveComplete - its called AFTER the actual save.
-- 2. Loading - little more complex
--   2a. Initialize - cannot use ExposedMembers
--		i. get constant data (map/game parameters)
--		ii. retrieve config parameters
--		iii. initialize objects with DB data
--		This step should leave all save-file related data empty, like in a newly created game
--   2b. LoadComplete
--		i. Random Leader flavors.
--		ii. Current game state.
--   2c. LoadScreenClose - basically nothing to do?

local iDataVersion = 2; -- internal number for versioning data stored in save files; version 1 was pre-GS (no diplo)

------------------------------------------------------------------------------
-- Save player and game related data into Game and Player Values
-- Serialize values using serialize()

function SaveDataToGameSlot(sSlotName:string, data)
	--print("FUN SaveDataToGameSlot() (slot,type)", sSlotName, type(data));
	--dshowrectable(data);
	local sData = serialize(data);
	--print("-->>", sData);
	RST.GameConfigurationSetValue(sSlotName, sData);
	--local sCheck:string = RST.GameConfigurationGetValue(sSlotName);
	--print("check:", sCheck == sData);
end

function SaveDataToPlayerSlot(ePlayerID:number, sSlotName:string, data)
	--print("FUN SaveDataToPlayerSlot (pid,slot,type)", ePlayerID, sSlotName, type(data));
	--dshowrectable(data);
	local sData = serialize(data);
	--print("-->>", sData);
	RST.PlayerConfigurationSetValue(ePlayerID, sSlotName, sData);
	--local sCheck:string = RST.PlayerConfigurationGetValue(ePlayerID, sSlotName);
	--print("check:", sCheck == sData);
end

function SavePlayerData(ePlayerID:number, sFunction:string)
	--if bLogDebug then print(Game.GetCurrentGameTurn(), "FUN SavePlayerData", ePlayerID, sFunction); end
	SaveDataToPlayerSlot(ePlayerID, "RSTPlayerData", tData[ePlayerID]);
end


------------------------------------------------------------------------------
-- Load persistent data (careful - it is BEFORE OnLoadScreenClose)
-- Deserialize values using loadstring()

function LoadDataFromGameSlot(sSlotName:string)
	--print("FUN LoadDataFromGameSlot() (slot)", sSlotName);
	local sData:string = RST.GameConfigurationGetValue(sSlotName);
	--print("<<--", sData);
	if sData == nil then print("WARNING: LoadDataFromGameSlot no data in slot", sSlotName); return nil; end
	local tTable = loadstring(sData)();
	--dshowrectable(tTable);
	return tTable;
end

function LoadDataFromPlayerSlot(ePlayerID:number, sSlotName:string)
	--print("FUN LoadDataFromPlayerSlot() (pid,slot)", ePlayerID, sSlotName);
	local sData:string = RST.PlayerConfigurationGetValue(ePlayerID, sSlotName);
	--print("<<--", sData);
	if sData == nil then print("WARNING: LoadDataFromPlayerSlot no data in slot", sSlotName, "for player", ePlayerID); return nil; end
	local tTable = loadstring(sData)();
	--dshowrectable(tTable);
	return tTable;
end

-- this event is called ONLY when loading a save file
function OnLoadComplete()
	--print("FUN OnLoadComplete");
	-- check data version
	local iSaveFileVersion = LoadDataFromGameSlot("RSTDataVersion");
	if iSaveFileVersion ~= iDataVersion then
		if bLogDebug then print("WARNING: OnLoadComplete Different data version, not loading (ver/save)", iDataVersion, iSaveFileVersion); end
		return;
	end
	-- initialize players from a save file
	if bLogDebug then print("--- LOADING PLAYERS ---"); end
	for _,playerID in ipairs(PlayerManager.GetAliveIDs()) do
		local data:table = LoadDataFromPlayerSlot(playerID, "RSTPlayerData");
		if data ~= nil then -- but make sure we really loaded the data
			tData[playerID] = data;
			if bLogDebug then print("...loaded player", data.PlayerID, data.LeaderType); end
			--dshowrectable(tData[playerID]);
		end
	end
	if bLogDebug then print("--- END LOADING PLAYERS ---"); end
end

function OnLoadScreenClose()
	--print("FUN OnLoadScreenClose");
	InitializeRandomFlavors();
	InitializeValidVictories();
	-- perform initial save for all players (to avoid warnings later)
	for pid, _ in pairs(tData) do
		SavePlayerData(pid, "Initial");
	end
	-- register data version
	SaveDataToGameSlot("RSTDataVersion", iDataVersion);
end


-- ===========================================================================
-- INITIALIZE
-- ===========================================================================

--[[
Data
- Each civ needs its own set of data - should be stored in the table []????
- Not needed, assuming that all is refreshed!
- However, it is possible that some data could be stored between turns, e.g. current strategy
- Weights should be parameters

Main function:
- uses bDirty to mark dirty data
- gather current data about ourselves
- store each element in a table of priorities, with the name and weight?
- recalculate (easy)
- log results (details)
- guess what others are doing
- AI logic?

Event functions
- There will be many or few, but they will be called for many strategies, so multiple times
- Recalculate only once and later just return quickly results
- Need bDirty to mark the need to recalculate
--]]

------------------------------------------------------------------------------
-- Read flavors and parameters, initialize players
function InitializeData()
	--print("FUN InitializeData");
	
	-- get max religions
	local mapSizeType:string = GameInfo.Maps[Map.GetMapSize()].MapSizeType;
	for row in GameInfo.Map_GreatPersonClasses() do
		if row.MapSizeType == mapSizeType and row.GreatPersonClassType == "GREAT_PERSON_CLASS_PROPHET" then
			iMaxNumReligions = row.MaxWorldInstances;
			break;
		end
	end
	if bLogDebug then print("Max religions:", iMaxNumReligions); end

	-- initialize players
	for _,playerID in ipairs(PlayerManager.GetAliveIDs()) do
		local data:table = {
			PlayerID = playerID,
			LeaderType = PlayerConfigurations[playerID]:GetLeaderTypeName(),
			--Dirty = true,
			TurnRefreshStrategy = -1, -- turn number when Strategy was refreshed last time (used with the counter)
			ActiveStrategy = "NONE",
			TurnRefreshData = -1, -- turn number when various other data was refreshed last time  (basically used each turn)
			ActiveDefense = false,
			ActiveCatching = false,
			ActiveEnough = false,
			ActivePeace = false,
			ActiveAtWar = false,
			ActiveScience = false,
			ActiveCulture = false,
			ActiveThreat = false,
			-- more slots
			ActiveMoreGWSlots = false,
			TurnRefreshSlots = GameConfiguration.GetStartTurn(), -- skip the 1st turn update
			-- naval
			ActiveNaval = 1, -- 0 Pangea, 1 Default, 2 Coastal (aka Naval), 3 Island
			TurnRefreshNaval = GameConfiguration.GetStartTurn(), -- skip the 1st turn update
			NavalFactor = -1,
			NavalRevealed = -1,
			-- data refreshed every turn
			OurMilitaryStrength = 0,
			AvgMilitaryStrength = 0,
			NumWars = 0,
			--NumTurnsActive = 0,
			Data = {}, -- this will be refreshed whenever needed, but only once per turn
			Stored = {}, -- this will be stored between turns (persistent) and eventually perhaps in the save file
		};
		tData[playerID] = data;
		if bLogDebug then print("...registering player", data.PlayerID, data.LeaderType); end
	end
	
	-- initalize flavors
	for flavor in GameInfo.RSTFlavors() do
		local data:table = tPriorities[flavor.ObjectType];
		if data == nil then
			data = {
				ObjectType = flavor.ObjectType,
				Type = flavor.Type,
				Subtype = flavor.Subtype,
				Priorities = PriorityTableNew(),
			};
			tPriorities[flavor.ObjectType] = data;
		end
		data.Priorities[flavor.Strategy] = flavor.Value;
	end

	-- 2020-05-15 Support for modded Civs - if they don't supply a parameter, the default 3 will be assigned
	for _,row in ipairs(DB.Query("select LeaderType from Leaders where InheritFrom = 'LEADER_DEFAULT'")) do
		local data:table = tPriorities[row.LeaderType];
		if data == nil then
			data = {
				ObjectType = row.LeaderType,
				Type = "LEADER",
				Subtype = "",
				Priorities = PriorityTableNew(),
			};
			PriorityTableSet(data.Priorities, 3);
			tPriorities[row.LeaderType] = data;
		end
	end
	
	print("Table of priorities:"); -- debug
	for objType,data in pairs(tPriorities) do
		--print("object,type,subtype", data.ObjectType, data.Type, data.Subtype);
		dshowpriorities(data.Priorities, data.ObjectType);
	end
	
end


-- randomize a bit leaders
-- this will called afer the game is loaded, so it will either get saved data or generate new ones

function InitializeRandomFlavors()
	--print("FUN InitializeRandomFlavors");
	
	if not bUseRandom then return; end -- no randomization at all
	
	local sData:string = GameConfiguration.GetValue("RSTRandomFlavors");
	local tRandomData:table = {};

	if sData ~= nil then
		-- note that there is no versioning here - a new field for DIPLO will be added together with GS which will make all save files obsolete anyway
		-- load from save file
		if bLogDebug then print("...RSTRandomFlavors EXISTS - load data"); end
		tRandomData = LoadDataFromGameSlot("RSTRandomFlavors");
	else
		-- generate new ones
		if bLogDebug then print("...RSTRandomFlavors NOT exists - generate randoms"); end
		
		-- changed to avoid pairs (unknown order)
		for _,row in ipairs(DB.Query("select LeaderType from Leaders where InheritFrom = 'LEADER_DEFAULT' order by LeaderType")) do
			local tRandomFlavors:table = PriorityTableRandom(GlobalParameters.RST_STRATEGY_LEADER_RANDOM);
			--dshowpriorities(tRandomFlavors, "...randomizing "..row.LeaderType);
			tRandomData[row.LeaderType] = tRandomFlavors;
		end
		-- store for the future
		SaveDataToGameSlot("RSTRandomFlavors", tRandomData);
	end
	
	--print("*** data in tRandomData ***");
	--dshowrectable(tRandomData);
	
	-- apply random values - only for leaders retrieved/generated, order doesn't matter here
	for leaderType, randomFlavors in pairs(tRandomData) do
		local data = tPriorities[leaderType];
		if data ~= nil and data.Type == "LEADER" then
			local tRandom:table = 
			dshowpriorities(randomFlavors, "...randomizing "..data.ObjectType);
			PriorityTableAdd(data.Priorities, randomFlavors);
			PriorityTableMinMax(data.Priorities, 1, 9);
			dshowpriorities(data.Priorities, "...leader "..data.ObjectType);
		else
			print("WARNING: InitializeRandomFlavors Priorities table for leader", leaderType, "not defined.");
		end
	end
end


------------------------------------------------------------------------------
function InitializeValidVictories()
	--print("FUN InitializeValidVictories");
	tValidVictories = PriorityTableNew();
	local iNumV:number = 0;
	if RST.GameIsVictoryEnabled("VICTORY_CONQUEST")   then tValidVictories.CONQUEST = 1; iNumV = iNumV + 1; end
	if RST.GameIsVictoryEnabled("VICTORY_TECHNOLOGY") then tValidVictories.SCIENCE  = 1; iNumV = iNumV + 1; end
	if RST.GameIsVictoryEnabled("VICTORY_CULTURE")    then tValidVictories.CULTURE  = 1; iNumV = iNumV + 1; end
	if RST.GameIsVictoryEnabled("VICTORY_RELIGIOUS")  then tValidVictories.RELIGION = 1; iNumV = iNumV + 1; end
	if RST.GameIsVictoryEnabled("VICTORY_DIPLOMATIC") then tValidVictories.DIPLO    = 1; iNumV = iNumV + 1; end
	dshowpriorities(tValidVictories, "Valid Victories");
	iMinimumPriority  = GlobalParameters.RST_STRATEGY_MINIMUM_PRIORITY * iNumV;
	iBetterThanUsNerf = GlobalParameters.RST_STRATEGY_BETTER_THAN_US_NERF * (iNumV+1);
	if bLogDebug then print(Game.GetCurrentGameTurn(), "Num Victories", iNumV, "Minimum Priority", iMinimumPriority, "BetterThanUsNerf", iBetterThanUsNerf); end
end


------------------------------------------------------------------------------
function Initialize()
	--print("FUN Initialize");
	
	-- for FireTuner
	ExposedMembers.RST.PlayerGetNumProjectsSpaceRace = PlayerGetNumProjectsSpaceRace;
	ExposedMembers.RST.PlayerGetNumCivsConverted = PlayerGetNumCivsConverted;
	ExposedMembers.RST.GameGetNumTurnsScaled = GameGetNumTurnsScaled;
	
	-- this part must NOT use ExposedMembers
	InitializeData();
	InitializeNaval();

	-- loading persistent data
	Events.LoadComplete.Add( OnLoadComplete ); -- fires ONLY when loading a game from a save file, when it's ready to start (i.e. circle button appears)
	Events.LoadScreenClose.Add ( OnLoadScreenClose );  -- fires when the game is about to begin i.e. after clicking the big circle buttons; fires AFTER LoadComplete
	
end	
Initialize();

print("OK loaded RealStrategy.lua from Real Strategy");