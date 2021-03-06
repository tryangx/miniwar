CharacterAICategory =
{
	CITY_DEVELOP             = 3,

	TECH_PROPOSAL             = 10,
	DIPLOMACY_PROPOSAL        = 11,
	CITY_DEVELOP_PROPOSAL     = 12,
	CITY_HR_PROPOSAL          = 13,
	WAR_PREPAREDNESS_PROPOSAL = 14,
	MILITARY_PROPOSAL         = 15,

	AI_CHOICE_PROPOSAL       = 21,
	AI_SUBMIT_PROPOSAL       = 22,

	GROUP_DISCUSS_PROPOSAL   = 30,

	CITY_DISCUSS_PROPOSAL    = 40,
}

local _chara  = nil
local _actor  = nil
local _ai     = nil
local _target = nil
local _blackboard = nil
local _register = {}
local _states = {}

---------------------------------------------
-- Common

local defaultSwitch = 
{
	TECH_AFFAIRS             = 1,
	WAR_PREPAREDNESS_AFFAIRS = 1,
	MILITARY_AFFAIRS         = 1,
	DIPLOMACY_AFFAIRS        = 1,
	CITY_AFFAIRS             = 1,
	HR_AFFAIRS               = 1,
}
local currentSwitch = defaultSwitch

local function CheckSwitchMode( params )
	local mode = params.mode
	return currentSwitch and currentSwitch[mode] ~= 0
end

debugAIInfo = false
local function debugInfo( content )
	if debugAIInfo then print( _chara:GetGroup().name .. " " .. content ) end
end

local hintProposal = { type = "FILTER", condition = function ()
	print( "hint=", _blackboard.city.name, "chara="..#_blackboard.city.charas, "pow="..GuessCityPower( _blackboard.city ), g_calendar:CreateCurrentDateDesc( true, true ) )
	return true
end }

local debugProposal = { type = "FILTER", condition = function ()
	InputUtility_Pause( "turn to " .. _chara.name, "n" )
	return true
end }

local waitProposal = { type = "FILTER", condition = function ()
	InputUtility_Wait( "abc" )
	return true
end }

local endProposal = { type = "ACTION", action = function ()
	print( _blackboard.city.name, "no proposal" )
	_blackboard.city:DumpTagDetail( "", false, print )
end }

local function QueryGroupData( dataname )
	local _city = _blackboard.city
	local group = _city:GetGroup()
	local value = nil
	if dataname == "FREECHARA_NONCAPITAL_LIST" then
		value = {}
		local capital = group:GetCapital()
		for k, city in ipairs( group.cities ) do
			if capital ~= city and not city:IsUnderstaffed() and not city:IsInSiege() then
				local charaList = city:GetFreeCharaList()
				for k2, chara in ipairs( charaList ) do
					table.insert( value, chara )
				end
			end
		end
	elseif dataname == "MAX_FREE_CHARA_NONCAPITAL_CITYLIST" then
		local maxNumber = 0
		local targetCity = nil
		local capital = group:GetCapital()
		for k, city in ipairs( group.cities ) do
			if capital ~= city then
				local number = city:GetNumOfFreeChara()
				if number > maxNumber then
					targetCity = city
					maxNumber = number
				end
			end
		end
		value = { targetCity }
	elseif dataname == "UNDERSTAFFED_CITYLIST" then
		value = {}
		for k, city in ipairs( group.cities ) do
			if city:IsUnderstaffed() and not city:IsInSiege() then
				table.insert( value, city )
			end
		end
		--InputUtility_Pause( "emptycity="..#value .. "," .. #group.cities )
		
	elseif dataname == "HIRETARGET_CHARALIST" then
		value = {}
		for k, chara in ipairs( g_statistic.outCharacterList ) do
			if chara:GetLocation() == _city then
				table.insert( value, chara )
			end
		end

	elseif dataname == "REDUNTANT_CHARALIST" then
		value = group:GetRedudantCharaList()

	elseif dataname == "REACHABLE_BELLIGERENT_CITYLIST" then
		value = group:GetReachableBelligerentCityList()

	end
	return value
end

local function QueryCityData( dataname )
	local _city = _blackboard.city
	local value = 0

	if dataname == "FREE_CHARALIST" then
		value = _city:GetFreeCharaList()
	elseif dataname == "FREEMILITARYOFFICER_CHARALIST" then
		value = _city:GetFreeMilitaryOfficerList()
	elseif dataname == "NONLEADER_TROOPLIST" then
		value = _city:GetNonLeaderTroopList()		
	elseif dataname == "PREPAREDTOATTACK_CORPSLIST" then
		value = _city:GetPreparedToAttackCorpsList()
		--if _city.id == 1000 then print( _city.name, "Prepared to attack corps=", #value, #_city.corps ) end
	elseif dataname == "FREE_CORPSLIST" then
		value = _city:GetFreeCorpsList()
	elseif dataname == "NONCORPS_TROOPLIST" then
		value = _city:GetNonCorpsTroopList()
	elseif dataname == "VACANCY_CORPSLIST" then
		value = _city:GetVacancyCorpsList()		
	elseif dataname == "UNTRAINED_CORPSLIST" then
		value = _city:GetUntrainedCorpsList()
		if #value <= 0 then debugInfo( "no untrained corps" ) end
	elseif dataname == "UNDERSTAFFED_CROPSLIST" then
		value = _city:GetUnderstaffedCorpsList()
		
	elseif dataname == "ADJACENT_HOSTILE_CITYLIST" then
		value = _city:GetAdjacentHostileCityList()
	elseif dataname == "ADJACENT_BELLIGERENT_CITYLIST" then
		value = _city:GetAdjacentBelligerentCityList()
		if _city.id == -1000 then
			print( _city.name, "adjacent belli city=" ..#value .."/".. #_city.adjacentCities, Helper_ConcatListName( _city.adjacentCities, function ( city )
				return city:GetGroup() and city:GetGroup().name or "NONE"
			end ) )
		end
	elseif dataname == "ADJACENT_NEUTRAL_CITYLIST" then
		value = _city:GetAdjacentNeutralCityList()
	elseif dataname == "ADJACENT_INDANGER_SELFGROUP_CITYLIST" then
		value = _city:GetAdjacentInDangerSelfGroupCityList()
	elseif dataname == "ADJACENT_OCCUPYGOAL_SELFGROUP_CITYLIST" then
		value = _city:GetAdjacentOccupyGoalSelfGroupCityList()	
	elseif dataname == "ADJACENT_DEFENDGOAL_SELFGROUP_CITYLIST" then
		value = _city:GetAdjacentDefendGoalSelfGroupCityList()
	elseif dataname == "CONNECT_OCCUPYGOAL_SELFGROUP_CITYLIST" then
		value = _city:GetConnectOccupyGoalSelfGroupCityList()	
	elseif dataname == "CONNECT_DEFENDGOAL_SELFGROUP_CITYLIST" then
		value = _city:GetConnectDefendGoalSelfGroupCityList()
	elseif dataname == "CONNECT_FRONTIER_SELFGROUP_CITYLIST" then
		value = _city:GetConnectFrontierSelfGroupCityList()
	elseif dataname == "CONNECT_EXPANDABLE_SELFGROUP_CITYLIST" then
		value = _city:GetConnectExpandableSelfGroupCityList()
	end
	return value
end

local function MemoryGroupData( params )
	if not params.dataname or not params.memname then
		InputUtility_Pause( "Missing memory params" )
		return false
	end
	_register[params.memname] = QueryGroupData( params.dataname )
	--ShowText( "memory group", params.memname, #_register[params.memname] )
	return true
end

local function MemoryCityData( params )
	if not params.dataname or not params.memname then
		return false
	end
	_register[params.memname] = QueryCityData( params.dataname )
	--ShowText( "memory city", params.memname, _register[params.memname] )
	return true
end

local function CompareValue( compare, value, compareValue )
	if compare == "EQUALS" then
		return value == compareValue
	elseif compare == "MORE_THAN" then
		if not value or not compareValue then print( value, compareValue ) end
		return value > compareValue
	elseif compare == "LESS_THAN" then
		return value < compareValue
	elseif compare == "MORE_THAN_AND_EQUALS" then
		return value >= compareValue
	elseif compare == "LESS_THAN_AND_EQUALS" then
		return value <= compareValue
	end
	return false
end

local function QueryComparisonValue( params )
	local compareValue = params.number
	if not compareValue then
		if not params.memname then
			return false
		end
		compareValue = _register[params.memname]
	end
	return compareValue
end

local function CompareData( params, dataFunction )
	if ( not params.dataname and not params.datamem ) or not params.number or not params.compare then
		return false
	end
	--source
	local value = nil
	if params.dataname then
		value = dataFunction( params.dataname )
	elseif params.datamem then
		value = _register[params.datamem]
	end
	if typeof( value ) == "table" then
		value = #value
	end
	--destination
	local compareValue = QueryComparisonValue( params )
	if typeof( value ) == "table" then
		value = #value
	end
	if type( compareValue ) == "table" then
		compareValue = #compareValue
	end
	--ShowText( "Compare", value, compareValue, params.dataname, params.datamem )
	return CompareValue( params.compare, value, compareValue )
end

local function CompareGroupData( params )
	return CompareData( params, function ( name )
		return QueryGroupData( name )
	end )
end

local function CompareCityData( params )
	return CompareData( params, function ( name )
		return QueryCityData( name )
	end )
end

-----------------------------------------------------


local function HaveJobPriviage( params )
	return _chara:HasPriviage( params.affair )
end

local function IsLeader( params )
	if _chara == _blackboard.city:GetLeader() then return true end
	if _chara:GetGroup() and _chara:GetGroup():GetLeader() == _chara then return true end
	return false
end

local function IsJobMatch( params )
	return _chara:GetJob() == MathUtility_FindEnumName( CharacterJob, params.job ) 	
end

local function IsCharaLeadTroop( params )
	return _chara:GetTroop() ~= nil
end

local function IsCharaMilitaryOfficer( params )	
	return _chara:IsMilitaryOfficer()
end

local function IsCharaCivialOfficial( params )
	return _chara:IsCivialOfficial()
end

local function CanSubmitProposal()
	return _chara:CanSubmitProposal()
end

local function CanAssignProposal()
	--Don't check whether is leader in this place
	return _chara:CanAssignProposal()	
end

local function CheckInstruction( params )
	local city = _blackboard.city

	if city == city:GetGroup():GetCapital()	then return true end
	
	if city.instruction == CityInstruction.NONE then return true end

	if params.flow == "CITY_AFFAIRS" then
		if city.instruction == CityInstruction.BUILD or city.instruction == CityInstruction.CITY_DEVELOP then return true end
	elseif params.flow == "CITY_BUILD" then
		if city.instruction == CityInstruction.BUILD then return true end
	elseif params.flow == "CITY_DEVELOP" then
		if city.instruction == CityInstruction.CITY_DEVELOP then return true end
	elseif params.flow == "WAR_PREPAREDNESS" then
		--ShowText( "check instruction=".. MathUtility_FindEnumName( CityInstruction, city.instruction ), params.flow )
		if city.instruction == CityInstruction.WAR_PREPAREDNESS then return true end
	elseif params.flow == "MILITARY" then
		if city.instruction == CityInstruction.MILITARY then return true end
	end

	if _ai:GetRandom() < 5000 then return true end
	
	return false
end

-----------------------------------------------------

local function FilterRegisterData( name, fn )
	local list = _register[name]
	local newCharaList = {}
	for k, data in ipairs( list ) do
		if fn( data ) then
			table.insert( newCharaList, data )
		end
	end
	_register[name] = newCharaList
	return #newCharaList > 0
end

local function FindProposalActor( params )
	_actor = nil
	
	if not _chara:IsGroupLeader() and not _chara:IsCityLeader() then
		if not _chara:CanSubmitProposal() then return false end	
	end
	
	local fnFindActor = nil
	local isNeedActor = true
	local type = params.type
	
	--Tech Affairs
	if type == "TECH_RESEARCH" then
		--maybe limit by technician
		
	--Diplomacy Affairs
	elseif type == "DIPLOMACY_AFFAIRS" then
		--exclusive
	--City Affairs
	elseif type == "CITY_INVEST" or type == "CITY_LEVY_TAX" or type == "CITY_BUILD" or type == "CITY_INSTRUCT" or type == "CITY_PATROL" or type == "CITY_FARM" then
		--exclusive
	--HR Affairs
	elseif type == "HR_HIRE" then
		if not FilterRegisterData( "CHARALIST", function( c )
			return not g_taskMng:HasConflictProposalTarget( CharacterProposal[type], nil, c )
		end ) then return false end
	elseif type == "HR_LOOKFORTALENT" then
		--exclusive
	elseif type == "HR_DISPATCH" or type == "HR_CALL" or type == "HR_EXILE" or type == "HR_PROMOTE" or type == "HR_BONUS" then
		isNeedActor = false
		
	--WarPreparedness Affairs
	elseif type == "RECRUIT_TROOP" or type == "CONSCRIPT_TROOP" or type == "ESTABLISH_CORPS" then
		--exclusive
	elseif type == "REINFORCE_CORPS" or type == "TRAIN_CORPS" then
		isNeedActor = false
		--actor is corps leader
		if not FilterRegisterData( "CORPSLIST", function( c )
			return c:GetLeader() and c:GetLeader():CanExecuteProposal()
		end ) then return false end
	elseif type == "REGROUP_CORPS" then
		--actor is corps leader
		if not FilterRegisterData( "CORPSLIST", function( c )
			return c:GetLeader() and c:GetLeader():CanExecuteProposal()
		end ) then return false end
		
	elseif type == "LEAD_TROOP" then
		--actor is free chara
		isNeedActor = false
	
	elseif type == "HARASS_CITY" or type == "SIEGE_CITY" or type == "EXPEDITION" or type == "DEFEND_CITY" or type == "CONTROL_PLOT" or type == "DISPATCH_CORPS" or type == "DISPATCH_TROOPS" then
		--actor is corps
		isNeedActor = false
	end
	
	if not isNeedActor then return true end
	
	local charaList = {}
	for k, chara in ipairs( _chara:GetHome().charas ) do
		if chara:IsAtHome() and chara:CanExecuteProposal() then
			if not fnCheckActor or fnCheckActor( chara ) then
				table.insert( charaList, chara )
			end
		end
	end
	local number = #charaList
	if number > 0 then
		local index = _ai:GetRandomByRange( 1, #charaList )
		_actor = charaList[index]
	end
	return _actor ~= nil
end

local function CheckConflictProposal( params )
	--1st, check conflict proposal
	local isConflict = false
	local type = params.type

	--Check exclusive task
	
	--Tech Affairs
	if type == "TECH_RESEARCH" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _chara:GetGroup(), target = nil } )

	--Diplomacy Affairs
	elseif type == "DIPLOMACY_AFFAIRS" then
	
	--City Affairs
	elseif type == "CITY_INVEST" or type == "CITY_LEVY_TAX" or type == "CITY_BUILD" or type == "CITY_INSTRUCT" or type == "CITY_PATROL" or type == "CITY_FARM" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = nil, target = _blackboard.city } )

	--HR Affairs
	elseif type == "HR_HIRE" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _blackboard.city, target = nil } )
	elseif type == "HR_LOOKFORTALENT" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _blackboard.city, target = nil } )
	elseif type == "HR_DISPATCH" or type == "HR_CALL" or type == "HR_EXILE" or type == "HR_PROMOTE" or type == "HR_BONUS" then			
		
	--WarPreparedness Affairs
	elseif type == "RECRUIT_TROOP" or type == "CONSCRIPT_TROOP" or type == "ESTABLISH_CORPS" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _blackboard.city, target = nil } )
	elseif type == "REINFORCE_CORPS" then
	elseif type == "TRAIN_CORPS" then
	elseif type == "REGROUP_CORPS" then
	elseif type == "LEAD_TROOP" then
	
	--Military Affairs
	elseif type == "HARASS_CITY" or type == "EXPEDITION" or type == "CONTROL_PLOT" or type == "DISPATCH_CORPS" then
	elseif type == "DISPATCH_TROOPS" then
		local troopList = _register["TROOPLIST"]
		for k, troop in ipairs( troopList ) do
			if g_taskMng:GetTaskByActor( troop ) then
				isConflict = true
				break
			end
		end
	elseif type == "SIEGE_CITY" or type == "DEFEND_CITY" then
		local corpsList = _register["CORPSLIST"]
		for k, corps in ipairs( corpsList ) do
			if g_taskMng:GetTaskByActor( corps ) then
				isConflict = true
				InputUtility_Pause( "conflict " .. type .. " corps=" .. NameIDToString( corps ) )
				break
			end
		end		
	end	

	return isConflict
end

local function CheckProposal( params )
	--check conflict proposal
	if CheckConflictProposal( params ) then
		--print( "has conflict taks", _chara.name )
		return false
	end
	
	--find proper actor
	if not FindProposalActor( params ) then
		--print( "cann't find actor", _chara.name, params.type )
		return false
	end

	return true
end

local function CheckCityInstruction( params )
	if not params.instruction then return false end
	local instruction = params.instruction
	local city = _blackboard.city
	return city and city.instruction == CityInstruction[instruction] or true
end

local function CheckMaintenanceMoney( params )
	local city = _blackboard.city
	return city:CanMaintain()
end

local function CheckEnoughMoney( params )
	if not params.money then return false end
	local money = params.money
	local city = _blackboard.city
	local group = city:GetGroup()
	return city:GetMoney() >= money or group:GetMoney() >= money
end

local function CheckLeakMoney( params )
	if not params.money then return false end
	local money = params.money
	local city = _blackboard.city
	local group = city:GetGroup()
	return group:GetMoney() < money
end

local function CheckProbaility( params )
	if not params.prob then return false end
	local prob = params.prob
	return _ai:GetRandom( "Check probability" ) <= prob
end

---------------------------------------------
-- Character Technological

local function CanResearchTech()
	if not _chara:GetGroup():CanResearch() then
		debugInfo( "group cann't reserach" )
		return false
	end
		
	--[[
	local tendency = CharacterProposalTendency[_chara:GetJob()]
	if not tendency then tendency = CharacterProposalTendency[0] end

	local prob = tendency.PROPOSAL["TECH"]
	if not prob then prob = 0 end

	if _ai:GetRandom( "Character consider tech" ) > prob then return false end
	]]
	local number = #_chara:GetGroup()._canResearchTechs
	if number == 0 then
		debugInfo( "no techs can research" )
		return false
	end
		
	local tech = _chara:GetGroup()._canResearchTechs[_ai:GetRandomByRange( 1, number, "Character choice tech" )]
	_register["TECH"] = tech
	return true
end

local function ResearchTechProposal()
	local tech = _register["TECH"]
	_chara:SubmitProposal( { type = CharacterProposal.TECH_RESEARCH, data = _chara:GetGroup(), target = tech, proposer = _chara, actor = _actor } )
end

local CharacterAI_TechProposal =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="TECH_AFFAIRS" } },
		{ type = "SEQUENCE", desc = "START tech", children =
		{
			{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "TECH_RESEARCH" } },		
			{ type = "FILTER", condition = CanResearchTech },
			{ type = "FILTER", condition = CheckProposal, params = { type="TECH_RESEARCH" } },
			{ type = "ACTION", action = ResearchTechProposal },
		} },
	}
}

---------------------------------------------

local function SubmitDiplomacyProposal( params )
	--if _chara:GetTroop() then ShowText( "troop leader do diplomacy", _chara.name, _chara:GetTroop().name, _chara:GetLocation().name ) end
	_chara:SubmitProposal( { type = CharacterProposal[params.proposal], target = _target, proposer = _chara, actor = _actor, prob = _blackboard.targetProb } )
end

local function GetDiplomacyTarget( params )
	local totalProb = _blackboard.totalProb
	local relations = _blackboard[params.listname]

	if not totalProb or totalProb <= 0 or not relations then
		return false
	end

	_target = nil
	local value = _ai:GetRandomByRange( 1, totalProb, "Get target" )
	for k, relation in ipairs( relations ) do
		if value < relation.prob then
			_target = relation.group
			_ai:AppendBlackboard( "targetProb", relation.prob )
			break
		else
			value = value - relation.prob
		end
	end
	--ShowText( "target=", _target.id, _target.name )
	return _target ~= nil
end

local function SelectDiplomacyTarget( params )
	local _group = _chara:GetGroup()
	if not _group then
		print( "no group chara do diplomacy", _chara.name )
	end

	local list = _group.relations
	local numOfGroup = #list
	if numOfGroup <= 0 then return false end
	
	local tendency = CharacterProposalTendency.JOB[_chara:GetJob()]
	if not tendency then tendency = CharacterProposalTendency.JOB[0] end

	local method = DiplomacyMethod[params.method]

	local totalProb = 0
	local relations = {}
	for k, relation in ipairs( list ) do
		local target = relation:GetOppGroup( _group.id )
		if g_taskMng:HasConflictProposal( { type = CharacterProposal.DIPLOMACY_AFFAIRS, target = target, group = _chara:GetGroup() } ) then
			--InputUtility_Pause( target.name .. " is in target" )
		else
			local prob = math.floor( EvaluateDiplomacySuccessRate( method, relation, _group, target ) )
			local success = tendency.SUCCESS_CRITERIA[params.method]
			if not success then success = tendency.SUCCESS_CRITERIA["DEFAULT"] or 0 end
			--if target then ShowText( MathUtility_FindEnumName( DiplomacyMethod, method ), "tar="..( target and target.name or "" ), "prob=" .. prob .."/".. success ) end
			if target and prob >= success then
				totalProb = totalProb + prob
				table.insert( relations, { group = target, prob = prob } )
				--ShowText( "Append " .. MathUtility_FindEnumName( DiplomacyMethod, method )  .. "=" .. target.name .. " relation=" .. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " prob=" .. prob )
			end
		end
	end

	if #relations <= 0 then
		--InputUtility_Pause( "no dip relation" )
		return false
	end

	_ai:AppendBlackboard( "relations", relations )
	_ai:AppendBlackboard( "totalProb", totalProb )

	return true
end

local CharacterAI_MakePeaceProposal =
{
	type = "SEQUENCE", desc = "make peace", children =
	{
		{ type = "FILTER", condition = CheckProposal, params = { type="DIPLOMACY_AFFAIRS" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "MAKE_PEACE" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "MAKE_PEACE_DIPLOMACY" } }
	}
}

local CharacterAI_FriendlyProposal =
{
	type = "SEQUENCE", desc = "friendly", children =
	{
		{ type = "FILTER", condition = CheckProposal, params = { type="DIPLOMACY_AFFAIRS" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "FRIENDLY" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "FRIENDLY_DIPLOMACY" } }
	}
}

local CharacterAI_ThreatenProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = CheckProposal, params = { type="DIPLOMACY_AFFAIRS" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "THREATEN" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "THREATEN_DIPLOMACY" } }
	}
}

local CharacterAI_AllyProposal =
{
	type = "SEQUENCE", desc = "Ally", children =
	{
		{ type = "FILTER", condition = CheckProposal, params = { type="DIPLOMACY_AFFAIRS" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "ALLY" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "ALLY_DIPLOMACY" } }
	}
}

local CharacterAI_DeclareWarProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = CheckProposal, params = { type="DIPLOMACY_AFFAIRS" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "DECLARE_WAR" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "DECLARE_WAR_DIPLOMACY" } }
	}
}

local CharacterAI_BreakContractProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = CheckProposal, params = { type="DIPLOMACY_AFFAIRS" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "BREAK_CONTRACT" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "BREAK_CONTRACT_DIPLOMACY" } }
	}
}

local CharacterAI_SurrenderProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = CheckProposal, params = { type="DIPLOMACY_AFFAIRS" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "SURRENDER" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "SURRENDER_DIPLOMACY" } }
	}
}

----------------------------------------

local function CheckDiplomacyTendency( params )
	ShowText( "method=", params.method )
	return true
end

CharacterAI_DiplomacyAffaisBranch =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="DIPLOMACY_AFFAIRS" } },
		--{ type = "NEGATE", children = { { type = "FILTER", condition = IsCharaLeadTroop }, } },
		{ type = "SEQUENCE", children = 
		{
			{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "DIPLOMACY_AFFAIRS" } },
			{ type = "RANDOM_SELECTOR", desc = "Run diplomacy", children =
				{				
					CharacterAI_SurrenderProposal,
					CharacterAI_BreakContractProposal,
					CharacterAI_DeclareWarProposal,
					CharacterAI_FriendlyProposal,
					CharacterAI_AllyProposal,
					CharacterAI_ThreatenProposal,
					CharacterAI_MakePeaceProposal,
				}
			},
		} },
	},
}

---------------------------------------------

local function CanBuild()
	local city = _blackboard.city
	return city:CanBuild()
end
local function CanFarm()
	local city = _blackboard.city
	if city:CanFarm() then return true end
	debugInfo( "no need to farm" )
	return false
end
local function CanInvest()
	local city = _blackboard.city
	if city:CanInvest() then return true end
	debugInfo( "no need to invest" )
	return false
end
local function CanLevyTax()
	local city = _blackboard.city
	if city:CanLevyTax() then return true end
	debugInfo( "no need to levy tax" )
	return false
end
local function NeedLevyTax()
	local city = _blackboard.city
	if not city:CanMaintain() then return true end
	if city:GetGroup() and not city:GetGroup():CanMaintain() then return true end
	return false
end

local function BuildCityProposal()
	local city = _blackboard.city
	local list = city:GetBuildList()
	local index = _ai:GetRandomByRange( 1, #list, "Build construction proposal" )
	local constr = list[index]
	_chara:SubmitProposal( { type = CharacterProposal.CITY_BUILD, target = city, data = constr, proposer = _chara, actor = _actor } )
end

local function FarmCityProposal()
	_chara:SubmitProposal( { type = CharacterProposal.CITY_FARM, target = _blackboard.city, proposer = _chara, actor = _actor } )
end

local function InvestCityProposal()
	_chara:SubmitProposal( { type = CharacterProposal.CITY_INVEST, target = _blackboard.city, proposer = _chara, actor = _actor } )
end

local function LevyTaxCityProposal()
	_chara:SubmitProposal( { type = CharacterProposal.CITY_LEVY_TAX, target = _blackboard.city, proposer = _chara, actor = _actor } )
end

local function CanInstruct()
	local city = _blackboard.city
	
	local list = {}
	for k, otherCity in ipairs( city:GetGroup().cities ) do
		if otherCity ~= city and #otherCity.charas > 0 and otherCity:CanInstruct() then
			table.insert( list, otherCity )
		end
	end	
	if #list > 0 then
		_register["CITYLIST"] = list
		return true
	end
	return false
end

local function InstructCityProposal()
	local list = {}
	for k, instr in pairs( CityInstruction ) do
		table.insert( list, instr )
	end
	local index = _ai:GetRandomByRange( 1, #list, "City instruct proposal" )
	local instruction = list[index]
	
	local cityList = _register["CITYLIST"]
	index = _ai:GetRandomByRange( 1, #cityList, "City Instruct Random" )
	local city = cityList[index]
	
	_chara:SubmitProposal( { type = CharacterProposal.CITY_INSTRUCT, target = city, data = instruction, proposer = _chara, actor = _actor } )
end

local function CanPatrol()
	local city = _blackboard.city
	if city:CanPatrol() then return true end
	debugInfo( "no need to patrol" )
	return false
end

local function PatrolCityProposal()
	_chara:SubmitProposal( { type = CharacterProposal.CITY_PATROL, target = _blackboard.city, proposer = _chara, actor = _actor } )
end

local CharacterAI_CityAffaisDevelopBranch =
{
	type = "SELECTOR", desc = "Develop", children =
	{
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = CheckProposal, params = { type="CITY_PATROL" } },
				{ type = "FILTER", condition = CanPatrol },
				{ type = "ACTION", action = PatrolCityProposal },
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = CheckProposal, params = { type="CITY_BUILD" } },
				{ type = "FILTER", desc = "status check", condition = CanBuild },
				{ type = "ACTION", desc = "end", action = BuildCityProposal },
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = CheckProposal, params = { type="CITY_FARM" } },
				{ type = "FILTER", condition = CanFarm },
				{ type = "ACTION", action = FarmCityProposal },
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = CheckProposal, params = { type="CITY_INVEST" } },
				{ type = "FILTER", condition = CanInvest },
				{ type = "ACTION", action = InvestCityProposal },
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = CheckProposal, params = { type="CITY_LEVY_TAX" } },
				{ type = "FILTER", condition = CanLevyTax },
				{ type = "FILTER", condition = NeedLevyTax },
				{ type = "ACTION", action = LevyTaxCityProposal },
			}
		},
	},
}

--Should redesign, consider about Warzone / Region / Else
local CharacterAI_InstructProposal =
{
	type = "SEQUENCE", desc = "Instruct", children =
	{
		{ type = "FILTER", condition = IsCapital },
		{ type = "FILTER", condition = CanInstruct },
		{ type = "ACTION", action = InstructCityProposal },
	}
}

local CharacterAI_CityAffaisBranch =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="CITY_AFFAIRS" } },
		{ type = "SEQUENCE", children = 
		{
			{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "CITY_AFFAIRS" } },	
			{ type = "SELECTOR", children =
				{
					{ type = "SEQUENCE", children =
						{
							{ type = "FILTER", condition = CheckInstruction, params = { flow = "CITY_DEVELOP" } },
							CharacterAI_CityAffaisDevelopBranch,
						}
					},
					--[[
					{ type = "SEQUENCE", children =
						{
							{ type = "FILTER", condition = CheckInstruction, params = { flow = "CITY_AFFAIRS" } },
							CharacterAI_InstructProposal,
						}
					},
					]]
				},
			}
		} },
	},
}
---------------------------------------------

local function DispatchCharaProposal()
	local cityList = _register["CITYLIST"]
	local index = _ai:GetRandomByRange( 1, #cityList, "Dispatch Chara Proposal destination" )
	local city = cityList[index]

	local charaList = _register["CHARALIST"]
	index = _ai:GetRandomByRange( 1, #charaList, "Dispatch Chara Proposal character" )
	local chara = charaList[index]
	
	_actor = chara

	_chara:SubmitProposal( { type = CharacterProposal.HR_DISPATCH, data = city, target = chara, proposer = _chara, actor = _actor } )
end

local function CallCharaProposal()
	local city = _blackboard.city
	local charaList = _register["CHARALIST"]
	local index = _ai:GetRandomByRange( 1, #charaList, "Dispatch Chara Proposal character" )
	local chara = charaList[index]
	
	_actor = chara
	
	_chara:SubmitProposal( { type = CharacterProposal.HR_CALL, data = city, target = chara, proposer = _chara, actor = _actor } )
end

local function HasCityTag( params )
	local flag = params.flag
	local tag = _blackboard.city:GetTag( CityTag[flag] )
	return tag ~= nil
end

local function IsCityUnderstaffed()
	return _blackboard.city:IsUnderstaffed()
end

local function IsCityInSiege()
	return _blackboard.city:IsInSiege()
end

local function IsCapital()
	return _blackboard.city:IsCapital()
end

local function CanCallChara()
	local city = _blackboard.city
	local group = city:GetGroup()
	return #city.charas < math.ceil( #group.charas / #group.cities )
end

local function CanHireChara()	
	local city = _blackboard.city
	local group = city:GetGroup()
	if #group.charas >= QueryGroupCharaLimit( group ) then
		return false
	end
	local need = QueryCityCharaLimit( city )
	local has = #city.charas
	return has < need
end

local function NeedHireChara()
	local city = _blackboard.city
	if #city.charas < QueryCityNeedChara( city ) then return true end
	if city:GetTag( CityTag.AGGRESSIVE ) then return true end
	if city:IsBattlefront() then return true end
	return true
end

local function HireCharaProposal()
	local charaList = _register["CHARALIST"]
	
	local index

	index = _ai:GetRandomByRange( 1, #charaList, "Hire Chara" )
	local chara = charaList[index]
	
	if chara:GetGroup() then
		InputUtility_Pause( chara.name .. " already in group=" .. chara:GetGroup().name )
		return
	end	

	_chara:SubmitProposal( { type = CharacterProposal.HR_HIRE, data = _blackboard.city, target = chara, proposer = _chara, actor = _actor } )
end

local CharacterAI_HireCharaProposal =
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = CanHireChara },		
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "HIRETARGET_CHARALIST", memname = "CHARALIST" } },		
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },		
		{ type = "FILTER", condition = CheckProposal, params = { type="HR_HIRE" } },		
		{ type = "ACTION", action = HireCharaProposal },
	}
}
local CharacterAI_CallCharaProposal =
{
	type = "SEQUENCE", desc = "Call", children =
	{
		{ type = "FILTER", condition = IsCapital },
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "FREECHARA_NONCAPITAL_LIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },		
		{ type = "FILTER", condition = CheckProposal, params = { type="HR_CALL" } },
		{ type = "ACTION", action = CallCharaProposal },
	}
}
local CharacterAI_DispatchCharaProposal =
{
	type = "SEQUENCE", desc = "Dispatch to Empty City", children =
	{
		{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityUnderstaffed }, } },
		{ type = "SELECTOR", desc = "Expedition", children =
			{
				{ type = "SEQUENCE", desc="dispatch to defend city", children = 
					{
						{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "UNDERSTAFFED_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },		
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREE_CHARALIST", memname = "CHARALIST" } },		
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="HR_DISPATCH" } },
						{ type = "ACTION", action = DispatchCharaProposal },
					}
				},
				--[[
				{ type = "SEQUENCE", desc="dispatch to frontier city", children = 
					{
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "CONNECT_FRONTIER_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },		
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREE_CHARALIST", memname = "CHARALIST" } },		
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="HR_DISPATCH" } },
						{ type = "ACTION", action = DispatchCharaProposal },
					}
				},
				{ type = "SEQUENCE", desc="dispatch to expandable city", children = 
					{
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "CONNECT_EXPANDABLE_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },		
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREE_CHARALIST", memname = "CHARALIST" } },		
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="HR_DISPATCH" } },
						{ type = "ACTION", action = DispatchCharaProposal },
					}
				},
				]]
			}
		},
	}
}

local function NeedExileChara()
	local city = _blackboard.city
	local group = city:GetGroup()
	return QueryGroupCharaLimit( group ) < #group.charas	
end

local function ExileCharaProposal()
	local charaList = _register["CHARALIST"]
	
	local index

	index = _ai:GetRandomByRange( 1, #charaList, "Exile Chara" )
	local chara = charaList[index]

	_chara:SubmitProposal( { type = CharacterProposal.HR_EXILE, data = _blackboard.city, target = chara, proposer = _chara, actor = _actor } )
end

local CharacterAI_ExileCharaProposal =
{
	type = "SEQUENCE", desc = "EXILE", children =
	{
		{ type = "FILTER", condition = IsCapital },		
		{ type = "FILTER", condition = NeedExileChara },
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "REDUNTANT_CHARALIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
		{ type = "FILTER", condition = CheckProposal, params = { type="HR_EXILE" } },
		{ type = "ACTION", condition = ExileCharaProposal },
	}
}

local function LookForTalentProposal()
	_chara:SubmitProposal( { type = CharacterProposal.HR_LOOKFORTALENT, data = _blackboard.city, target = _chara, proposer = _chara, actor = _actor } )
end

local CharacterAI_LookForTalentProposal = 
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = CanHireChara },
		--{ type = "FILTER", condition = NeedHireChara },
		{ type = "FILTER", condition = CheckProposal, params = { type="HR_LOOKFORTALENT" } },
		{ type = "ACTION", action = LookForTalentProposal },
	}
}

local CharacterAI_HumanResourceBranch =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="HR_AFFAIRS" } },
		{ type = "SEQUENCE", desc = "START HR proposal", children =
		{
			{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "HR_AFFAIRS" } },
			{ type = "FILTER", condition = CheckInstruction, params = { flow = "HUMAN_RESOURCE" } },
			{ type = "SELECTOR", children =
				{
					CharacterAI_HireCharaProposal,
					CharacterAI_LookForTalentProposal,
					CharacterAI_CallCharaProposal,
					CharacterAI_DispatchCharaProposal,
					CharacterAI_ExileCharaProposal,					
				},
			},
		} },
	},
}

---------------------------------------------

local function CanEstablishCorps()
	local city = _blackboard.city
	return city:CanEstablishCorps()
end

local function EstablishProposal()
	local troopList = _register["TROOPLIST"]
	--troopList = nil
	_chara:SubmitProposal( { type = CharacterProposal.ESTABLISH_CORPS, data = _blackboard.city, target = troopList, proposer = _chara, actor = _actor } )
end

local CharacterAI_EstablishCorpsProposal = 
{
	type = "SEQUENCE", desc = "Establish Corps", children =
	{
		{ type = "FILTER", condition = CanEstablishCorps },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
		{ type = "FILTER", condition = CheckProposal, params = { type="ESTABLISH_CORPS" } },
		{ type = "ACTION", action = EstablishProposal },
	}
}

---------------------------------------------
local function CanRecruit( checkCity )
	local city = checkCity or _blackboard.city
	return city:CanRecruit()
end
local function NeedRecruit( checkCity )
	local city = checkCity or _blackboard.city
	local troopNumber = GlobalConst.DEFAULT_TROOP_NUMBER
	if city:GetMilitaryService() < troopNumber or city:GetSupplySoldier() < troopNumber + city:GetMilitaryPower() then
		return false
	end

	--Rear area, no need to expand ( conquer neutralized )
	if city:GetTag( CityTag.SAFE ) and not city:GetTag( EXPANDABLE ) then
		return false
	end
	
	local reqPower = city:GetReqMilitaryPower()
	local power  = city:GetMilitaryPower()	
	
	--We always try to keep the number as we required?
	if power < reqPower then
		return true
	elseif city:IsInDanger() then
		return true
	elseif power >= reqPower * CityParams.MILITARY.REQUIRE_MILITARYPOWER_LIMITATION_MODULUS	then
		--local list = city:GetAdjacentGroupMilitaryPowerList()
		--MathUtility_Foreach( list, function( k, v ) print( k .. "=" .. v ) end )
		--print( city.name.. " Cann't recruit, Out of required power=" .. power .. "/" .. reqPower * CityParams.MILITARY.REQUIRE_MILITARYPOWER_LIMITATION_MODULUS	)
		return false
	end	
	return true
end
local function RecruitCityProposal( checkCity )
	local city = checkCity or _blackboard.city
	local list = city:GetRecruitList()
	local index = _ai:GetRandomByRange( 1, #list, "Recruit troop proposal" )
	local troop = list[index]
	_chara:SubmitProposal( { type = CharacterProposal.RECRUIT_TROOP, data = city, target = troop, proposer = _chara, actor = _actor } )
end
local CharacterAI_RecruitTroopProposal = 
{
	type = "SEQUENCE", desc = "Recruit Troop", children =
	{
		{ type = "FILTER", condition = CanRecruit },
		{ type = "FILTER", condition = NeedRecruit },
		{ type = "FILTER", condition = CheckProposal, params = { type="RECRUIT_TROOP" } },
		{ type = "ACTION", action = RecruitCityProposal },
	}
}

local function RegroupCorpsProposal()
	local corpsList = _register["CORPSLIST"]
	local troopList = _register["TROOPLIST"]

	local index

	index = _ai:GetRandomByRange( 1, #corpsList, "Regroup corps proposal" )
	local corps = corpsList[index]

	local troops = {}
	MathUtility_Shuffle( troopList, _ai:GetRandomizer() )
	for k, troop in ipairs( troopList ) do
		if not g_taskMng:GetTaskByActor( troop ) then
			table.insert( troops, troop )
		end
	end
	
	_actor = corps:GetLeader()
	
	_chara:SubmitProposal( { type = CharacterProposal.REGROUP_CORPS, data = corps, target = troops, proposer = _chara, actor = _actor } )
end

local CharacterAI_RegroupCorpsProposal = 
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "VACANCY_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
		{ type = "FILTER", condition = CheckProposal, params = { type="REGROUP_CORPS" } },
		{ type = "ACTION", action = RegroupCorpsProposal },
	}
}

local function TrainCorpsProposal()
	local corpsList = _register["CORPSLIST"]

	local index

	index = _ai:GetRandomByRange( 1, #corpsList, "Regroup corps proposal" )
	local corps = corpsList[index]
	
	_actor = corps:GetLeader()

	_chara:SubmitProposal( { type = CharacterProposal.TRAIN_CORPS, target = corps, proposer = _chara, actor = _actor } )
end


local CharacterAI_TrainCorpsProposal = 
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "UNTRAINED_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = CheckProposal, params = { type="TRAIN_CORPS" } },
		{ type = "ACTION", action = TrainCorpsProposal },
	}
}

local function NeedReinforceCorps( checkCity )
	local city = checkCity or _blackboard.city
	
	local troopNumber = 0
	local finalCorpsList = {}
	local corpsList = _register["CORPSLIST"]
	for k, corps in ipairs( corpsList ) do
		local need = corps:GetUnderstaffedNumber()
		if need <= city:GetMilitaryService() then
			if troopNumber < need then troopNumber = need end
			table.insert( finalCorpsList, corps )
		end
	end
	if #finalCorpsList <= 0 then
		return false
	end
	
	local reqPower = city:GetReqMilitaryPower()
	local supply = city:GetSupplyPopulation()
	local power  = city:GetMilitaryPower()	
	
	--Make supply enough to evoid starvation
	if supply < city.population + power then
		debugInfo( "Cann't reinforce, out of supply" )
		return false
	end

	--Limit by the food consume
	if ( power + troopNumber ) * CityParams.SAFETY_FOOD_CONSUME_TIME / GlobalConst.UNIT_TIME > city.food then
		debugInfo( "Cann't reinforce, out of food" )
		return false
	end
	
	local limitPower = reqPower * CityParams.MILITARY.REQUIRE_MILITARYPOWER_LIMITATION_MODULUS	

	--We always try to keep the number as we required?
	if power < reqPower then return true end

	_register["CORPSLIST"] = finalCorpsList
	
	--InputUtility_Pause( "reinforce=" .. troopNumber )
	
	return city:IsPopulationEnough()
end
local function ReinforceCorpsProposal()
	local corpsList = _register["CORPSLIST"]
	local index
	index = _ai:GetRandomByRange( 1, #corpsList, "Reinforce corps proposal" )
	local corps = corpsList[index]
	
	_actor = corps:GetLeader()
	
	_chara:SubmitProposal( { type = CharacterProposal.REINFORCE_CORPS, target = corps, proposer = _chara, actor = _actor } )
end
local CharacterAI_ReinforceCorpsProposal = 
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "UNDERSTAFFED_CROPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = NeedReinforceCorps },
		{ type = "FILTER", condition = CheckProposal, params = { type="REINFORCE_CORPS" } },
		{ type = "ACTION", action = ReinforceCorpsProposal },
	}
}

local function LeadTroopProposal()
	local charaList = _register["CHARALIST"]
	local troopList = _register["TROOPLIST"]

	local index

	index = _ai:GetRandomByRange( 1, #charaList, "Lead Troop Proposal character" )
	local chara = charaList[index]

	index = _ai:GetRandomByRange( 1, #troopList, "Lead Troop Proposal troop" )
	local troop = troopList[index]
	
	_actor = chara
	
	_chara:SubmitProposal( { type = CharacterProposal.LEAD_TROOP, target = troop, data = chara, proposer = _chara, actor = _actor } )
end

local CharacterAI_LeadTroopProposal =
{
	type = "SEQUENCE", desc = "Lead", children =
	{
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREEMILITARYOFFICER_CHARALIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONLEADER_TROOPLIST", memname = "TROOPLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
		{ type = "FILTER", condition = CheckProposal, params = { type="LEAD_TROOP" } },
		{ type = "ACTION", action = LeadTroopProposal },
	}
}

local CharacterAI_WarPreparednessBranch =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="WAR_PREPAREDNESS_AFFAIRS" } },
		{ type = "SEQUENCE", desc = "START War Preparedness proposal", children =
		{
			{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "WAR_PREPAREDNESS_AFFAIRS" } },		
			{ type = "FILTER", condition = CheckInstruction, params = { flow = "WAR_PREPAREDNESS" } },
			{ type = "SELECTOR", desc = "START War Preparedness proposal", children =
				{
					CharacterAI_ReinforceCorpsProposal,
					CharacterAI_RegroupCorpsProposal,
					CharacterAI_RecruitTroopProposal,
					CharacterAI_EstablishCorpsProposal,
					CharacterAI_LeadTroopProposal,
					CharacterAI_TrainCorpsProposal,
				}
			},
		} }
	},
}

---------------------------------------------

local function CheckHarassCityPlan()
	local city = _blackboard.city
	local corpsList = _register["CORPSLIST"]
	local maxCorpsPower = 0
	local findCorps = nil
		
	for k, corps in ipairs( corpsList ) do
		local power = corps:GetPower()
		if power > 0 then
			if power > maxCorpsPower then
				if not findCorps or _ai:RandomProb() < 7000 * ( maxCorpsPower / power ) then
					findCorps = corps
					maxCorpsPower = power
				end
			elseif power > maxCorpsPower * 0.65 then
				if not findCorps or _ai:RandomProb() < 3000 * ( power / maxCorpsPower ) then
					findCorps = corps
					maxCorpsPower = power
				end
			elseif not findCorps or _ai:RandomProb() < 5000 then
				findCorps = corps
			end
		end
	end
	local findCity = nil
	local cityList = _register["CITYLIST"]
	for k, adjaCity in ipairs( cityList ) do
		local power = GuessCityPower( adjaCity )
		--if adjaCity:GetGroup() then print( "NeutralCity="..adjaCity.name, "pow="..power ) end
		if power > maxCorpsPower then
			--most situation
			local prob = 3000 * ( power / maxCorpsPower )
			if not findCity or _ai:RandomProb() < prob then
				findCity = adjaCity
			end
		else
			local prob = 8000 * ( maxCorpsPower / power )
			if not findCity or _ai:RandomProb() < prob then
				findCity = adjaCity
			end
		end
	end
	if findCorps and findCity then
		_register["CITYTARGET"]  = findCity
		_register["CORPSTARGET"] = findCorps
		--ShowText( "harass corps=" .. NameIDToString( findCorps ).."+"..findCorps:GetPower() .. " vs " .. NameIDToString( findCity ).."+".. GuessCityPower( findCity ) )
		return true
	end
	return false
end

local function HarassProposal()
	local city = _register["CITYTARGET"]
	local corps = _register["CORPSTARGET"]
	
	if city:GetGroup() == corps:GetGroup() then
		InputUtility_Pause( "why", NameIDToString( corps ), city.name )
	end
	
	if corps:GetLocation():IsInSiege() then
		local combat = g_warfare:GetCombatByLocation( corps:GetLocation() )
		InputUtility_Pause( "cann't harass in siege status", combat, corps:GetLocation().name )
	end
	
	_actor = corps
	
	_chara:SubmitProposal( { type = CharacterProposal.HARASS_CITY, target = city, data = corps, proposer = _chara, actor = _actor } )
end

local function ExpeditionProposal()
	local cityList = _register["CITYLIST"]
	local index = _ai:GetRandomByRange( 1, #cityList, "Attack Proposal city" )
	local city = cityList[index]

	local corpsList = _register["CORPSLIST"]
	local index = _ai:GetRandomByRange( 1, #corpsList, "Attack Proposal corps" )
	local corps = corpsList[index]
	
	_actor = corps

	_chara:SubmitProposal( { type = CharacterProposal.EXPEDITION, target = city, data = corps, proposer = _chara, actor = _actor } )
end

local function IsCityInDanger()
	local city = _blackboard.city
	return city:IsInDanger()
end

local function CheckDispatchProposal()
	local cityList = _register["CITYLIST"]
	local corpsList = _register["CORPSLIST"]
	
	local list = {}
	for k, city in ipairs( cityList ) do
		for k2, corps in ipairs( corpsList ) do			
			if city:GetSupplySoldier() > city:GetMilitaryPower() + corps:GetPower() then
				table.insert( list, { city = city, corps = corps } )
			else
				ShowText( NameIDToString( city ) .. " sup=" .. city:GetSupplySoldier() .. " pow=" .. city:GetMilitaryPower() .. " corps=" .. corps:GetPower() )
			end
		end
	end

	if #list <= 0 then return false end

	local index = _ai:GetRandomByRange( 1, #list )
	_register["CITYTARGET"] = list[index].city
	_register["CORPSTARGET"] = list[index].corps

	return true
end

local function CheckDispatchTroopsProposal()
	local cityList = _register["CITYLIST"]
	local troopsList = _register["TROOPLIST"]

	local list = {}
	for k, city in ipairs( cityList ) do
		local troopList = {}
		local power = 0
		for k2, troop in ipairs( troopsList ) do
			power = troop:GetPower()
			if city:GetSupplySoldier() > city:GetMilitaryPower() + power then
				table.insert( troopList, troop )
			else
				break
			end
		end
		table.insert( list, { city = city, troopList = troopList } )
	end

	if #list <= 0 then return false end

	local index = _ai:GetRandomByRange( 1, #list )
	_register["CITYTARGET"] = list[index].city
	_register["TROOPLIST"] = list[index].troopList

	return true
end

local function DispatchCorpsProposal( params )
	local city = _register["CITYTARGET"]
	local corps = _register["CORPSTARGET"]
	
	if corps:GetLocation() == city then
		print( city.name, _blackboard.city.name )
		InputUtility_Pause( "dispatch to same city" )
	end

	_actor = corps
	
	_chara:SubmitProposal( { type = CharacterProposal.DISPATCH_CORPS, target = city, data = corps, proposer = _chara, actor = _actor } )
end

local function DispatchTroopsProposal()
	local city = _register["CITYTARGET"]
	local troopList = _register["TROOPLIST"]
	
	_actor = troopList[1]

	_chara:SubmitProposal( { type = CharacterProposal.DISPATCH_TROOPS, target = city, data = troopList, proposer = _chara, actor = _actor } )
end

local function CheckSiegePlan()
	local city = _blackboard.city
	local corpsList = _register["CORPSLIST"]
	local totalPower = 0
	local maxPower, maxPowerCorps = 0, nil
	local minPower, minPowrCorps = 99999999, nil
	local randSelProb, randSelPower, randSelCorps = 2000, 0, nil

	for k, corps in ipairs( corpsList ) do
		local curPower = corps:GetPower()
		totalPower = totalPower + curPower
		if curPower > maxPower then
			maxPower = curPower
			maxPowerCorps = corps
		end
		if curPower < minPower then
			minPower = curPower
			minPowrCorps = corps
		end
		if _ai:GetRandom() < randSelProb then
			randSelPower = curPower
			randSelCorps = corps
		end
	end

	local tag = city:GetTag( CityTag.FRONTIER )
	if tag and tag.value > 1 then
		local excludeCorps = nil
		local selMethod = _ai:GetRandomByRange( 1, 3 )
		if selMethod == 1 then
			--left maxpower corps to defend
			excludeCorps = maxPowerCorps
			totalPower = totalPower - maxPower
		elseif selMethod == 2 then
			--left minpower corps to defend
			excludeCorps = minPowerCorps
			totalPower = totalPower - minPower
		else
			--left randomize corps to defend
			excludeCorps = randSelCorps
			totalPower = totalPower - randSelPower
		end
	end

	local findNeutralCity = nil
	local findCity = nil
	local cityList = _register["CITYLIST"]
	for k, adjaCity in ipairs( cityList ) do
		local power = GuessCityPower( adjaCity )
		--print( power, totalPower, city.name )
		if power < totalPower then
			local prob
			if not adjaCity:GetGroup() then
				--print( "can attack", totalPower, power, city.name, adjaCity.name )
				prob = 10000
			elseif totalPower > power * WarfarePlanParams.SIEGECITY_GARRISONPOWER_LESSTHAN_TIMES then
				prob = 8000
			else
				prob = 5000 * ( totalPower / power )
			end
			if not findCity or _ai:RandomProb() < prob then
				findCity = adjaCity
			end
		else
			--too strong, pass			
		end
	end

	if not findCity then
		--print( city.name, totalPower, "cann't find target ", #cityList )
		return false
	end

	local findCorps = nil
	local findCorpsList = {}
	for k, corps in ipairs( corpsList ) do
		if corps ~= excludeCorps then
			--actually, we should find the slowest corps, but now instead by the high rank			
			local leader = corps:GetLeader()
			if leader then
				if not findCorps or leader:IsMoreImportant( findCorps:GetLeader() ) then
					findCorps = corps
				end
			end
			table.insert( findCorpsList, corps )
		end
	end

	_register["CITYTARGET"] = findCity
	_register["CORPSLIST"] = findCorpsList
	_register["CORPSLEADER"] = findCorps

	ShowText( "siegecity city=" .. findCity.name .. " pow=" .. totalPower .. "+" ..#findCorpsList .. "/" .. GuessCityPower( findCity ) )

	city:AppendTag( CityTag.SUBMIT_PROPOSAL, 1 )

	return true	
end

local function SiegeCityProposal()
	local city = _register["CITYTARGET"]
	local corpsList = _register["CORPSLIST"]
	_actor = _register["CORPSLEADER"]

	_chara:SubmitProposal( { type = CharacterProposal.SIEGE_CITY, target = city, data = corpsList, proposer = _chara, actor = _actor } )
end

local CharacterAI_HarassCityProposal =
{
	type = "SEQUENCE", desc = "Harass", children =
	{
		{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInDanger }, } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "PREPAREDTOATTACK_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },				
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },	
		{ type = "FILTER", condition = CheckProposal, params = { type="HARASS_CITY" } },
		{ type = "FILTER", condition = CheckHarassCityPlan },
		{ type = "ACTION", action = HarassProposal },
	}
}

local CharacterAI_SiegeCityProposal =
{
	type = "SEQUENCE", desc = "SIEGE", children =
	{
		{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInDanger }, } },				
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "PREPAREDTOATTACK_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },			
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },		
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },				
		{ type = "FILTER", condition = CheckProposal, params = { type="SIEGE_CITY" } },		
		{ type = "FILTER", condition = CheckSiegePlan },
		{ type = "ACTION", action = SiegeCityProposal },
	}
}

local CharacterAI_OccupyNeutralCityProposal =
{
	type = "SEQUENCE", desc = "OCCUPY NEUTRAL", children =
	{
		{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInDanger }, } },
		{ type = "FILTER", condition = HasCityTag, params = { flag = "EXPANDABLE" } },		
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "PREPAREDTOATTACK_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_NEUTRAL_CITYLIST", memname = "CITYLIST" } },		
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = CheckProposal, params = { type="SIEGE_CITY" } },
		{ type = "FILTER", condition = CheckSiegePlan },
		{ type = "ACTION", action = SiegeCityProposal },
	}
}

local CharacterAI_ExpeditionProposal =
{
	type = "SEQUENCE", desc = "Expedition", children =
	{
		{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInDanger }, } },--??
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "PREPAREDTOATTACK_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },		
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "EQUALS", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "REACHABLE_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = CheckProposal, params = { type="EXPEDITION" } },
		{ type = "ACTION", action = ExpeditionProposal },
	}
}

local CharacterAI_DispatchCorpsProposal = 
{
	type = "SEQUENCE", desc = "Expedition", children =
	{
		{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInDanger }, } },		
		{ type = "SELECTOR", desc = "Expedition", children =
			{
				{ type = "SEQUENCE", desc="dispatch to defend city", children = 
					{
						--{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_DEFENDGOAL_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "CONNECT_DEFENDGOAL_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREE_CORPSLIST", memname = "CORPSLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_CORPS" } },
						{ type = "FILTER", condition = CheckDispatchProposal },
						{ type = "ACTION", action = DispatchCorpsProposal },
					}
				},
				{ type = "SEQUENCE", desc="dispatch to city in danger", children = 
					{
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_INDANGER_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREE_CORPSLIST", memname = "CORPSLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_CORPS" } },
						{ type = "FILTER", condition = CheckDispatchProposal },
						{ type = "ACTION", action = DispatchCorpsProposal },
					}
				},
				{ type = "SEQUENCE", desc="dispatch to city near goal", children = 
					{
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "CONNECT_OCCUPYGOAL_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREE_CORPSLIST", memname = "CORPSLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_CORPS" } },
						{ type = "FILTER", condition = CheckDispatchProposal },
						{ type = "ACTION", action = DispatchCorpsProposal },
					}
				},		
				{ type = "SEQUENCE", desc="transfer to frontier", children = 
					{
						{ type = "FILTER", condition = HasCityTag, params = { flag = "SAFE" } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "CONNECT_FRONTIER_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREE_CORPSLIST", memname = "CORPSLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_CORPS" } },	
						{ type = "FILTER", condition = CheckDispatchProposal },
						{ type = "ACTION", action = DispatchCorpsProposal },
					}
				},
				{ type = "SEQUENCE", desc="transfer to expandable city", children = 
					{
						{ type = "FILTER", condition = HasCityTag, params = { flag = "SAFE" } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "CONNECT_EXPANDABLE_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREE_CORPSLIST", memname = "CORPSLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_CORPS" } },	
						{ type = "FILTER", condition = CheckDispatchProposal },
						{ type = "ACTION", action = DispatchCorpsProposal },
					}
				},
			}
		},
	}
}

local CharacterAI_DispatchTroopsProposal = 
{
	type = "SEQUENCE", desc = "Expedition", children =
	{	
		{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInDanger }, } },
		{ type = "SELECTOR", children =
			{
				{ type = "SEQUENCE", desc="dispatch to defend city", children = 
					{
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_DEFENDGOAL_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_TROOPS" } },
						{ type = "FILTER", condition = CheckDispatchTroopsProposal },
						{ type = "ACTION", action = DispatchTroopsProposal },
					}
				},
				{ type = "SEQUENCE", desc="dispatch to city in danger", children = 
					{
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_INDANGER_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_TROOPS" } },
						{ type = "FILTER", condition = CheckDispatchTroopsProposal },
						{ type = "ACTION", action = DispatchTroopsProposal },
					}
				},
				{ type = "SEQUENCE", desc="dispatch to city near goal", children = 
					{
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_OCCUPYGOAL_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_TROOPS" } },
						{ type = "FILTER", condition = CheckDispatchTroopsProposal },
						{ type = "ACTION", action = DispatchTroopsProposal },
					}
				},	
				{ type = "SEQUENCE", desc="transfer to frontier", children = 
					{
						{ type = "FILTER", condition = HasCityTag, params = { flag = "SAFE" } },						
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "CONNECT_FRONTIER_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_TROOPS" } },
						{ type = "FILTER", condition = CheckDispatchTroopsProposal },
						{ type = "ACTION", action = DispatchTroopsProposal },
					}
				},	
				{ type = "SEQUENCE", desc="transfer to expandable", children = 
					{
						{ type = "FILTER", condition = HasCityTag, params = { flag = "SAFE" } },						
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "CONNECT_EXPANDABLE_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
						{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
						{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
						{ type = "FILTER", condition = CheckProposal, params = { type="DISPATCH_TROOPS" } },
						{ type = "FILTER", condition = CheckDispatchTroopsProposal },
						{ type = "ACTION", action = DispatchTroopsProposal },
					}
				},
			}
		},
	}
}

local CharacterAI_MilitaryBranch =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="MILITARY_AFFAIRS" } },
		{ type = "SEQUENCE", desc = "START Military proposal", children =
		{
			{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInSiege }, } },
			{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "MILITARY_AFFAIRS" } },
			{ type = "FILTER", condition = CheckInstruction, params = { flow = "MILITARY" } },
			{ type = "RANDOM_SELECTOR", desc = "START Military proposal", children =
				{
					CharacterAI_OccupyNeutralCityProposal,
					CharacterAI_SiegeCityProposal,
					CharacterAI_HarassCityProposal,
					--CharacterAI_ExpeditionProposal,
					CharacterAI_DispatchCorpsProposal,
					CharacterAI_DispatchTroopsProposal,
				}
			}
		} },
	},
}


local CharacterAI_ExpandBranch =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="MILITARY_AFFAIRS" } },
		{ type = "SEQUENCE", desc = "START Military proposal", children =
			{
				{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInSiege }, } },
				{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "MILITARY_AFFAIRS" } },
				{ type = "FILTER", condition = CheckInstruction, params = { flow = "MILITARY" } },
				CharacterAI_OccupyNeutralCityProposal,
			}
		},
	},
}

---------------------------------------------

local function SelectMeetingProposal()
	--Accept the proposal submited by other character
	if _chara.stamina > CharacterParams.STAMINA["ACCEPT_PROPOSAL"] and _blackboard.proposals and #_blackboard.proposals > 0 then
		--select proposal
		if  _ai:GetRandom( "Select meeting topic" ) <= RandomParams.MAX_PROBABILITY + ( _chara.stamina - CharacterParams.STAMINA["ACCEPT_PROPOSAL"] ) * RandomParams.PROBABILITY_UNIT then		
			local proposalList = {}
			for k, proposal in ipairs( _blackboard.proposals ) do
				if not g_taskMng:HasConflictProposal( proposal ) then
					--ShowText( "insert proposal=", Proposal_CreateDesc( proposal ) )
					table.insert( proposalList, proposal )
				end
			end
			if #proposalList > 0 then
				--ShowText( "resel", #proposalList)
				local index = _ai:GetRandomByRange( 1, #proposalList, "Select proposal" )
				_chara:SubmitProposal( { type = CharacterProposal.AI_CHOICE_PROPOSAL, proposal = proposalList[index], proposer = _chara, actor = _actor } )
				return
			end
			--print( "resel=0")
		end
	end
	
	--AI Leader Submit proposal by himself
	if _chara.stamina > CharacterParams.STAMINA["SUBMIT_PROPOSAL"] then
		--print( "ai submit proposal himself" )
		_chara:SubmitProposal( { type = CharacterProposal.AI_SUBMIT_PROPOSAL, proposer = _chara, actor = _actor } )
		return
	end
	
	--Next/End
	_chara:SubmitProposal( { type = CharacterProposal.NEXT_TOPIC, proposer = _chara, actor = _actor } )
end

local CharacterAI_AISelectProposal =
{
	type = "SELECTOR", desc = "START select proposal", children =
	{
		{ type = "ACTION", desc = "execute", action = SelectMeetingProposal },
	}
}

---------------------------------------------

	
---------------------------------------------

local function CheckPriority( params )
	local city  = _blackboard.city
	local group = _blackboard.city:GetGroup()
	local category = params.category
	local tag = nil
	if category == "WAR_PREPAREDNESS_AFFAIRS" then

	elseif category == "RECRUIT_TROOP" then	
		tag = group:GetAsset( GroupTag.SITUATION.WEAK ) or city:GetTag( CityTag.INDANGER )
		
	elseif category == "TECH_AFFAIRS" then

	elseif category == "RESEARCH_TECH" then
		tag = group:GetAsset( GroupTag.SITUATION.PRIMITIVE )
		
	elseif category == "DIPLOMACY_AFFAIRS" then
		tag = group:GetAsset( GroupTag.SITUATION.BELLIGERENT )
	
	elseif category == "CITY_AFFAIRS" then
		tag = group:GetAsset( GroupTag.SITUATION.UNDEVELOPED )
		
	elseif category == "HR_AFFAIRS" then

	elseif category == "HR_HIRE" then
		tag = group:GetAsset( GroupTag.SITUATION.UNDERSTAFFED )

	elseif category == "MILITARY_AFFAIRS" then

	elseif category == "MILITARY_AGGRESSIVE" then
		tag = group:GetAsset( GroupTag.SITUATION.AGGRESSIVE ) or city:GetTag( CityTag.ADVANTAGE )
		--if tag ~= nil then print( city.name, group.name, tag ) end
		
	elseif category == "AT_WAR" then
		tag = group:GetAsset( GroupTag.SITUATION.AT_WAR )
	
	end
	
	return tag ~= nil
end

------------------------------
-- Priority proposal

local function IsUnderattack()
	local city = _blackboard.city
	local taskList = g_taskMng:GetIntelTaskList( _blackboard.city )
	for k, task in ipairs( taskList ) do
		if task:IsInvasionTask() then
			if task.actor:GetLocation() == city then
				--The enemy is at the gate
				return false
			end
		end
	end
	_register["TASKLIST"] = taskList
	return #taskList > 0
end

local function CheckDefendProposal()
	local city = _blackboard.city
	local corpsList = _register["CORPSLIST"]
	local totalPower, enemyPower = 0, 0
	
	--calculate enemy power
	local taskList = _register["TASKLIST"]
	for k, task in ipairs( taskList ) do
		if task:IsInvasionTask() then
			enemyPower = enemyPower + task.actor:GetPower()
		end
	end

	local findCorps = nil

	--calculate self power
	for k, corps in ipairs( corpsList ) do
		local curPower = corps:GetPower()
		totalPower = totalPower + curPower
		local leader = corps:GetLeader()
		if leader then
			if not findCorps or leader:IsMoreImportant( findCorps:GetLeader() ) then
				findCorps = corps
			end
		end
	end

	--enemy is too strong, evade field-combat
	if totalPower * WarfarePlanParams.DEFENDCITY_ENEMYPOWER_LESSTHAN_TIMES < enemyPower then
		return false
	end

	_register["CORPSLIST"]   = corpsList
	_register["CORPSLEADER"] = findCorps

	return true	
end

local function DefendCityProposal()
	local corpsList = _register["CORPSLIST"]	
	_actor = _register["CORPSLEADER"]
	_chara:SubmitProposal( { type = CharacterProposal.DEFEND_CITY, target = _blackboard.city, data = corpsList, proposer = _chara, actor = _actor } )
end

local DefendPriorityProposal =
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = IsUnderattack },
		{ type = "SEQUENCE", children = 
			{
				{ type = "FILTER", condition = MemoryCityData, params = { dataname = "PREPAREDTOATTACK_CORPSLIST", memname = "CORPSLIST" } },
				{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
				{ type = "FILTER", condition = CheckProposal, params = { type="DEFEND_CITY" } },
				{ type = "FILTER", condition = CheckDefendProposal },
				{ type = "ACTION", action = DefendCityProposal },
			}
		},		
	}
}

local HRPriorityProposal = 
{
	type = "SEQUENCE", children = { 
		{ type = "FILTER", condition = CheckPriority, params = { category="HR_HIRE" } },
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="HR_AFFAIRS" } },
		{ type = "SELECTOR", children = 
			{
				CharacterAI_HireCharaProposal,
				CharacterAI_LookForTalentProposal,
				CharacterAI_DispatchCharaProposal,
			}
		},		
	}
}

local MilitaryPriorityProposal = 
{
	type = "SEQUENCE", children = {	
		{ type = "SELECTOR", desc="attack neutral", children = 
			{
				CharacterAI_ExpandBranch,
			}
		},
		--[[
		{ type = "SEQUENCE", desc="War Priority", children = 
			{
				{ type = "FILTER", condition = CheckPriority, params = { category="AT_WAR" } },
				{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", dataname= "PREPAREDTOATTACK_CORPSLIST", number = 0 } },
				CharacterAI_MilitaryBranch,
			}
		},
		]]
	},
}

local WarPreparednessPriorityProposal =
{
	type = "SEQUENCE", children = {
		CharacterAI_WarPreparednessBranch,
	}
}

local CharacterAI_DebugConflictProposal = 
{
	type = "SELECTOR", children =
	{
		--[[
		--WAR_PREPAREDNESS
		CharacterAI_ReinforceCorpsProposal,
		CharacterAI_RegroupCorpsProposal,
		CharacterAI_RecruitTroopProposal,
		CharacterAI_EstablishCorpsProposal,
		CharacterAI_LeadTroopProposal,
		CharacterAI_TrainCorpsProposal,
		--Military
		CharacterAI_HarassCityProposal,
		CharacterAI_ExpeditionProposal,
		CharacterAI_DispatchCorpsProposal,
		--Tech
		CharacterAI_TechProposal,
		--CityAffairs
		CharacterAI_CityAffaisDevelopBranch,
		--Diplomacy
		CharacterAI_SurrenderProposal,
		CharacterAI_BreakContractProposal,
		CharacterAI_DeclareWarProposal,
		CharacterAI_FriendlyProposal,
		CharacterAI_AllyProposal,
		CharacterAI_ThreatenProposal,
		CharacterAI_MakePeaceProposal,
		--HR
		CharacterAI_HireCharaProposal,
		CharacterAI_LookForTalentProposal,
		CharacterAI_CallCharaProposal,
		CharacterAI_DispatchCharaProposal,
		CharacterAI_ExileCharaProposal,
		]]
		--endProposal,
	}
}

------------------------------

local CharacterAI_AggressiveMilitaryProposal =
{
	type = "SELECTOR", children = {
		CharacterAI_MilitaryBranch,
		CharacterAI_WarPreparednessBranch,
	},
}


local OfficerSubmitProposal =
{
	type = "RANDOM_SELECTOR", desc = "", children =
	{
		CharacterAI_TechProposal,
		CharacterAI_WarPreparednessBranch,
		CharacterAI_CityAffaisBranch,
		CharacterAI_HumanResourceBranch,
		CharacterAI_DiplomacyAffaisBranch,
		CharacterAI_MilitaryBranch,
	},
}

local DiplomaticSubmitProposal =
{
	type = "SELECTOR", desc = "", children =
	{
		CharacterAI_DiplomacyAffaisBranch,
		CharacterAI_WarPreparednessBranch,
		CharacterAI_TechProposal,		
		CharacterAI_HumanResourceBranch,
		CharacterAI_CityAffaisBranch,		
		CharacterAI_MilitaryBranch,
	},
}

local GeneralSubmitProposal = 
{
	type = "SELECTOR", desc = "", children =
	{
		CharacterAI_MilitaryBranch,
		CharacterAI_WarPreparednessBranch,		
		CharacterAI_TechProposal,
		CharacterAI_CityAffaisBranch,
		CharacterAI_DiplomacyAffaisBranch,
		CharacterAI_HumanResourceBranch,
	},
}

local LeaderSubmitProposal = 
{
	type = "SELECTOR", children = 
	{
		{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="MILITARY_AGGRESSIVE" } }, CharacterAI_AggressiveMilitaryProposal } },
		{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="DIPLOMACY_AFFAIRS" } }, CharacterAI_DiplomacyAffaisBranch } },
		{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="MILITARY_AFFAIRS" } }, CharacterAI_MilitaryBranch } },
		{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="CITY_AFFAIRS" } }, CharacterAI_CityAffaisBranch } },
		{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="RESEARCH_TECH" } }, CharacterAI_TechProposal } },
	},
}

local CharacterAI_DefaultPriorityProposal = 
{
	type = "SELECTOR", children = 
	{
		CharacterAI_DebugConflictProposal,

		--Underattack
		DefendPriorityProposal,
		--Leak character
		HRPriorityProposal,
		--Expand & Attack weak
		MilitaryPriorityProposal,

		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = IsLeader },
				LeaderSubmitProposal,
			}
		},

		--[[
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = IsJobMatch, params = { job = "DIPLOMATIC" } },
				DiplomaticSubmitProposal,
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = IsCharaMilitaryOfficer },
				GeneralSubmitProposal,
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = IsCharaCivialOfficial },
				OfficerSubmitProposal,
			}
		},
		]]
		{ type = "RANDOM_SELECTOR", desc = "", children =
			{
				CharacterAI_WarPreparednessBranch,
				CharacterAI_TechProposal,
				CharacterAI_DiplomacyAffaisBranch,
				CharacterAI_CityAffaisBranch,
				CharacterAI_HumanResourceBranch,
				CharacterAI_MilitaryBranch,
			},
		},
	}
}

---------------------------------------------

local CharacterAI_AISubmitProposal =
{
	type = "SEQUENCE", desc = "AI Submit", children =
	{
		{ type = "FILTER", condition = CanAssignProposal },
		CharacterAI_DefaultPriorityProposal,
	}
}

---------------------------------------------

local CharacterAI_GroupDiscussProposal =
{
	type = "SEQUENCE", desc = "Group Discuss", children =
	{
		{ type = "FILTER", condition = CanSubmitProposal },		
		CharacterAI_DefaultPriorityProposal,
	}
}

---------------------------------------------

local CharacterAI_CityDiscussProposal =
{
	type = "SEQUENCE", desc = "Group Discuss", children =
	{
		{ type = "FILTER", condition = CanSubmitProposal },
		CharacterAI_DefaultPriorityProposal,
	}
}

---------------------------------------------

CharacterAI = class()

function CharacterAI:__init()
	self.behavior = Behavior()

	self.techChoice = BehaviorNode()
	self.techChoice:BuildTree( CharacterAI_TechChoice )
	self.cityDevelop = BehaviorNode()
	self.cityDevelop:BuildTree( CharacterAI_Develop )

	self.techProposal = BehaviorNode()
	self.techProposal:BuildTree( CharacterAI_TechProposal )
	self.cityDevelopProposal = BehaviorNode()
	self.cityDevelopProposal:BuildTree( CharacterAI_CityAffaisBranch )
	self.cityHRProposal= BehaviorNode()
	self.cityHRProposal:BuildTree( CharacterAI_HumanResourceBranch )
	self.warPreparednessProposal = BehaviorNode()
	self.warPreparednessProposal:BuildTree( CharacterAI_WarPreparednessBranch )
	self.militaryProposal = BehaviorNode()
	self.militaryProposal:BuildTree( CharacterAI_MilitaryBranch )
	self.diplomacyProposal= BehaviorNode()
	self.diplomacyProposal:BuildTree( CharacterAI_DiplomacyAffaisBranch )

	self.aiSelectProposal = BehaviorNode()
	self.aiSelectProposal:BuildTree( CharacterAI_AISelectProposal )
	self.aiSubmitProposal = BehaviorNode()
	self.aiSubmitProposal:BuildTree( CharacterAI_AISubmitProposal )

	self.groupDiscussProposal = BehaviorNode()
	self.groupDiscussProposal:BuildTree( CharacterAI_GroupDiscussProposal )

	self.cityDiscussProposal = BehaviorNode()
	self.cityDiscussProposal:BuildTree( CharacterAI_CityDiscussProposal )

	self.standardAI = self.techAI

	_ai = self
end

function CharacterAI:SetType( type )
	if type == CharacterAICategory.CITY_DEVELOP then
		self.standardAI = self.cityDevelop

	elseif type == CharacterAICategory.TECH_PROPOSAL then
		self.standardAI = self.techProposal
	elseif type == CharacterAICategory.CITY_DEVELOP_PROPOSAL then
		self.standardAI = self.cityDevelopProposal
	elseif type == CharacterAICategory.CITY_HR_PROPOSAL then
		self.standardAI = self.cityHRProposal
	elseif type == CharacterAICategory.WAR_PREPAREDNESS_PROPOSAL then
		self.standardAI = self.warPreparednessProposal
	elseif type == CharacterAICategory.MILITARY_PROPOSAL then
		self.standardAI = self.militaryProposal
	elseif type == CharacterAICategory.DIPLOMACY_PROPOSAL then
		self.standardAI = self.diplomacyProposal

	elseif type == CharacterAICategory.AI_CHOICE_PROPOSAL then
		self.standardAI = self.aiSelectProposal
	elseif type == CharacterAICategory.AI_SUBMIT_PROPOSAL then
		self.standardAI = self.aiSubmitProposal

	elseif type == CharacterAICategory.GROUP_DISCUSS_PROPOSAL then
		self.standardAI = self.groupDiscussProposal

	elseif type == CharacterAICategory.CITY_DISCUSS_PROPOSAL then
		self.standardAI = self.cityDiscussProposal
	end
end

function CharacterAI:SetActor( actor )
	_chara = actor
end

function CharacterAI:SetRandomizer( randomizer )
	self.randomizer = randomizer
end

function CharacterAI:SetBlackboard( blackboard )
	_blackboard = blackboard
end

function CharacterAI:AppendBlackboard( name, data )
	if not _blackboard then
		_blackboard = {}
	end
	_blackboard[name] = data
end

function CharacterAI:ClearState()
	_states = {}
end

function CharacterAI:Run()
	if #_register > 0 then _register = {} end
	ProfileStart( "Character AI" )
	self.behavior:Run( self.standardAI )
	ProfileEnd( "Character AI" )
end

function CharacterAI:GetRandomizer()
	return self.randomizer
end

function CharacterAI:GetRandom( desc )
	return self:GetRandomByRange( 1, RandomParams.MAX_PROBABILITY, desc )
end

function CharacterAI:GetRandomByRange( min, max, desc )
	if desc then Debug_Log( "Generate Random: " .. desc ) end
	if self.randomizer then return self.randomizer:GetInt( min, max ) end
	return math.random( min, max )
end

function CharacterAI:RandomProb( desc )
	if desc then Debug_Log( "Generate Random: " .. desc ) end
	if self.randomizer then return self.randomizer:GetInt( 1, 10000 ) end
	return math.random( 1, 10000 )
end
