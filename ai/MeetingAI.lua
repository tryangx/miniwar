CharacterAICategory =
{
	CITY_DEVELOP             = 3,

	TECH_PROPOSAL             = 10,
	DIPLOMACY_PROPOSAL        = 11,
	CITY_DEVELOP_PROPOSAL     = 12,
	CITY_HR_PROPOSAL          = 13,
	WAR_PREPAREDNESS_PROPOSAL = 14,
	MILITARY_PROPOSAL         = 15,

	AI_SELECT_PROPOSAL       = 21,
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
	--ShowText( mode .. "=", (currentSwitch and currentSwitch[mode] ~= 0) )
	return currentSwitch and currentSwitch[mode] ~= 0
end

debugAIInfo = false
local function debugInfo( content )
	if debugAIInfo then print( _chara:GetGroup().name .. " " .. content ) end
end

local hintProposal = { type = "FILTER", condition = function ()
	print( "hint" )
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

local CharacterAI_PassProposal = 
{
	type = "ACTION", action = function()
		--print( _chara.name .. " pass" )
	end
}

local function QueryGroupData( dataname )
	local _city = _blackboard.city
	local group = _city:GetGroup()
	local value = nil
	--[[
	if dataname == "NUMBER_EMPTY_CITY" then
		value = 0
		for k, city in ipairs( group.cities ) do
			if #city.charas == 0 then
				value = value + 1
			end
		end
	elseif dataname == "FREE_CHARA_IN_CAPITAL" then
		value = group:GetCapital():GetNumOfFreeChara()	
	elseif dataname == "MAX_FREE_CHARA_IN_NONCAPITAL" then
		value = 0
		local capital = group:GetCapital()
		for k, city in ipairs( group.cities ) do
			if capital ~= city then
				local number = city:GetNumOfFreeChara()
				if number > value then
					value = number
				end
			end
		end
		--ShowText( "max free", value )
	]]
	if dataname == "FREECHARA_INCAPITAL_LIST" then
		value = group:GetCapital():GetFreeCharaList()
	elseif dataname == "NUMBER_FREE_CHARA_IN_CAPITAL" then
		value = group:GetCapital():GetNumOfFreeChara()
		ShowText( "free chara in cap", value )
	elseif dataname == "FREECHARA_NONCAPITAL_LIST" then
		value = {}
		local capital = group:GetCapital()
		for k, city in ipairs( group.cities ) do
			if capital ~= city and not city:IsUnderstaffed() and not city:IsInConflict() then
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
	elseif dataname == "UNDERSTAFFED_NONCAPITAL_CITYLIST" then
		value = {}
		for k, city in ipairs( group.cities ) do
			if not city:IsCapital() and city:IsUnderstaffed() and not city:IsInConflict() then
				table.insert( value, city )
			end
		end
		--InputUtility_Pause( "emptycity="..#value .. "," .. #group.cities )
		
	elseif dataname == "HIRETARGET_CHARALIST" then
		value = {}
		for k, chara in ipairs( g_statistic.outCharacterList ) do
			if chara:GetGroup() then
				InputUtility_Pause( "why", chara.name )
			end
			if chara:GetLocation() and chara:GetLocation() == _city then
				if not g_taskMng:GetTaskByTarget( chara ) then
					table.insert( value, chara )
				end
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
	if dataname == "NUMBER_FREE_CHARA" then
		value = _city:GetNumOfFreeChara()
	--[[
	elseif dataname == "NUMBER_CORPS" then
		value = #_city.corps
	elseif dataname == "NUMBER_TROOP" then
		value = #_city.troops
	elseif dataname == "MAX_CORPS_NUMBER" then
		value = math.max( math.ceil( ( _city.size + 1 ) / 5 ), 1 )				
	elseif dataname == "NUMBER_IDLE_CORPS" then
		value = _city:GetNumOfIdleCorps()	
	elseif dataname == "IDLE_CORPSLIST" then
		value = _city:GetIdleCorpsList()
		--ShowText( "!!!!has idle corps", #value )
		]]	
	elseif dataname == "FREEMILITARYOFFICER_CHARALIST" then
		value = _city:GetFreeMilitaryOfficerList()
	elseif dataname == "NONLEADER_TROOPLIST" then
		value = _city:GetNonLeaderTroopList()		
	elseif dataname == "PREPAREDTOATTACK_CORPSLIST" then
		value = _city:GetPreparedToAttackCorpsList()
		--if #value > 0 then print( "Prepared to attack corps=", #value ) end
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
		--if #value > 0 then print( "Adjacent Belligerent Cities=", #value ) end
	elseif dataname == "ADJACENT_INDANGER_SELFGROUP_CITYLIST" then
		value = _city:GetAdjacentInDangerSelfGroupCityList()
		--if #value > 0 then InputUtility_Pause( "adja indanger=", #value ) end
		
	end
	--ShowText( dataname, value )
	return value
end

local function MemoryGroupData( params )
	if not params.dataname or not params.memname then
		ShowText( "Missing memory params" )
		return false
	end
	_register[params.memname] = QueryGroupData( params.dataname )
	--ShowText( "memory group", params.memname, #_register[params.memname] )
	return true
end

local function MemoryCityData( params )
	if not params.dataname or not params.memname then
		ShowText( "Missing memory params" )
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
			ShowText( "No memory name" )
			return false
		end
		compareValue = _register[params.memname]
	end
	return compareValue
end

local function CompareData( params, dataFunction )
	if ( not params.dataname and not params.datamem ) or not params.number or not params.compare then
		ShowText( "Missing compare params" )
		MathUtility_Dump( params )
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
		ShowText( "convert list to length" )
		value = #value
	end
	if type( compareValue ) == "table" then
		ShowText( "convert list to length" )
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

local function FindProposalActor( params )
	--1st, check conflict proposal
	local fnCheckActor = nil
	local isConflict = false
	local isNeedActor = true
	local type = params.type
	if type == "TECH_RESEARCH" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _chara:GetGroup(), target = nil } )

	elseif type == "DIPLOMACY_AFFAIRS" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _chara:GetGroup(), target = nil } )
		
	elseif type == "CITY_INVEST" or type == "CITY_LEVY_TAX" or type == "CITY_BUILD" or type == "CITY_INSTRUCT" or type == "CITY_PATROL" or type == "CITY_FARM" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = nil, target = _blackboard.city } )
	
	elseif type == "HR_HIRE" or type == "HR_LOOKFORTALENT" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _blackboard.city, target = nil } )	
	elseif type == "HR_DISPATCH" or type == "HR_CALL" or type == "HR_EXILE" or type == "HR_PROMOTE" or type == "HR_BONUS" then
		--actor is the affair target
		isNeedActor = false
	
	elseif type == "RECRUIT_TROOP" or type == "CONSCRIPT_TROOP" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _blackboard.city, target = nil } )
		--fnCheckActor = 
	elseif type == "ESTABLISH_CORPS" then
		isConflict = g_taskMng:HasConflictProposal( { type = CharacterProposal[type], data = _blackboard.city, target = nil } )
	elseif type == "REINFORCE_CORPS" or type == "REGROUP_CORPS" or type == "TRAIN_CORPS" then
		--nothing need to do
	elseif type == "LEAD_TROOP" then
		--actor is chara who lead the troop
		isNeedActor = false
		
	elseif type == "ATTACK_CITY" or type == "EXPEDITION" or type == "CONTROL_PLOT" or type == "DISPATCH_CORPS" then
		--actor is corps who execute the task
		isNeedActor = false
		
	end	
	if isConflict then return false end
	
	--2nd, find actor
	_actor = nil
	if isNeedActor then	
		if _chara:IsGroupLeader() or _chara:IsCityLeader() then
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
		elseif _chara:CanSubmitProposal() then
			_actor = _chara
		end
	end
	return not isNeedActor or _actor ~= nil
end

local function CheckCityInstruction( params )
	if not params.instruction then return false end
	local instruction = params.instruction
	local city = _blackboard.city
	return city and city.instruction == CityInstruction[instruction] or true
end

local function CheckMaintenanceMoney( params )
	local city = _blackboard.city
	return city:GetMoney() >= city:CalcMaintenanceCost() * CityParams.SAFETY_TROOP_MAINTAIN_TIME / GlobalConst.UNIT_TIME
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
	--if g_taskMng:IsTaskConflictWithCity( TaskType.TECH_RESEARCH, city ) then debugInfo( "research tech conflict" ) return false end
	
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
	_chara:SubmitProposal( { type = CharacterProposal.TECH_RESEARCH, data = _chara:GetGroup(), target = tech, proposer = _chara, actor = _chara } )
end

local CharacterAI_TechProposal =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="TECH_AFFAIRS" } },		
		{ type = "SEQUENCE", desc = "START tech", children =
		{
			{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "TECH_RESEARCH" } },		
			{ type = "FILTER", condition = CanResearchTech },
			{ type = "FILTER", condition = FindProposalActor, params = { type="TECH_RESEARCH" } },
			{ type = "ACTION", action = ResearchTechProposal },
		} },
	}
}

---------------------------------------------

local function SubmitDiplomacyProposal( params )
	if _chara:GetTroop() then
		print( "troop leader do diplomacy", _chara.name, _chara:GetTroop().name, _chara:GetLocation().name )
	end
	--ShowText( "submit proposal" )
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
	ShowText( "target=", _target.id, _target.name )
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
		if not g_taskMng:GetTaskByTarget( target ) then
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
		{ type = "FILTER", condition = FindProposalActor, params = { type="DIPLOMACY" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "MAKE_PEACE" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "MAKE_PEACE_DIPLOMACY" } }
	}
}

local CharacterAI_FriendlyProposal =
{
	type = "SEQUENCE", desc = "friendly", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="DIPLOMACY" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "FRIENDLY" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "FRIENDLY_DIPLOMACY" } }
	}
}

local CharacterAI_ThreatenProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="DIPLOMACY" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "THREATEN" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "THREATEN_DIPLOMACY" } }
	}
}

local CharacterAI_AllyProposal =
{
	type = "SEQUENCE", desc = "Ally", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="DIPLOMACY" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "ALLY" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "ALLY_DIPLOMACY" } }
	}
}

local CharacterAI_DeclareWarProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="DIPLOMACY" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "DECLARE_WAR" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "DECLARE_WAR_DIPLOMACY" } }
	}
}

local CharacterAI_BreakContractProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="DIPLOMACY" } },
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "BREAK_CONTRACT" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "BREAK_CONTRACT_DIPLOMACY" } }
	}
}

local CharacterAI_SurrenderProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="DIPLOMACY" } },
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
	--if g_taskMng:IsTaskConflictWithCity( TaskType.CITY_BUILD, city ) then debugInfo( "has build conflict task" ) return false end
	return city:CanBuild()
end
local function CanFarm()
	local city = _blackboard.city
	--if g_taskMng:IsTaskConflictWithCity( TaskType.CITY_FARM, city ) then debugInfo( "has farm conflict task" ) return false end
	if city:CanFarm() then return true end
	debugInfo( "no need to farm" )
	return false
end
local function CanInvest()
	local city = _blackboard.city
	--if g_taskMng:IsTaskConflictWithCity( TaskType.CITY_INVEST, city ) then debugInfo( "has invest conflict task" ) return false end
	if city:CanInvest() then return true end
	debugInfo( "no need to invest" )
	return false
end
local function CanLevyTax()
	local city = _blackboard.city
	--if g_taskMng:IsTaskConflictWithCity( TaskType.CITY_LEVY_TAX, city ) then debugInfo( "has invest conflict task" ) return false end
	if city:CanLevyTax() then return true end
	debugInfo( "no need to levy tax" )
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
	--if g_taskMng:IsTaskConflictWithCity( TaskType.CITY_INSTRUCT, city ) then return false end	
	
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
	--if g_taskMng:IsTaskConflictWithCity( TaskType.CITY_PATROL, city ) then return false end	
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
				{ type = "FILTER", condition = FindProposalActor, params = { type="CITY_BUILD" } },
				{ type = "FILTER", desc = "status check", condition = CanBuild },
				{ type = "ACTION", desc = "end", action = BuildCityProposal },
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = FindProposalActor, params = { type="CITY_FARM" } },
				{ type = "FILTER", condition = CanFarm },
				{ type = "ACTION", action = FarmCityProposal },
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = FindProposalActor, params = { type="CITY_INVEST" } },
				{ type = "FILTER", condition = CanInvest },
				{ type = "ACTION", action = InvestCityProposal },
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = FindProposalActor, params = { type="CITY_PATROL" } },
				{ type = "FILTER", condition = CanPatrol },
				{ type = "ACTION", action = PatrolCityProposal },
			}
		},
		{ type = "SEQUENCE", children =
			{
				{ type = "FILTER", condition = FindProposalActor, params = { type="CITY_LEVY_TAX" } },
				{ type = "FILTER", condition = CanLevyTax },
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
	index = _ai:GetRandomByRange( 1, #cityList, "Dispatch Chara Proposal character" )
	local chara = charaList[index]

	_chara:SubmitProposal( { type = CharacterProposal.HR_DISPATCH, data = city, target = chara, proposer = _chara, actor = _actor } )
end

local function CallCharaProposal()
	local city = _blackboard.city
	local charaList = _register["CHARALIST"]
	local index = _ai:GetRandomByRange( 1, #charaList, "Dispatch Chara Proposal character" )
	local chara = charaList[index]
	--InputUtility_Pause( "call chara=" .. chara.name, "loc=" .. chara:GetLocation().name, city.name )
	_chara:SubmitProposal( { type = CharacterProposal.HR_CALL, data = city, target = chara, proposer = _chara, actor = _actor } )
end

local function HasCityTag( params )
	local flag = params.flag
	local tag = _blackboard.city:GetTag( CityTag[flag] )
	return tag ~= nil
end

local function IsCityWeak()
	return _blackboard.city:IsWeak()
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
	if QueryGroupCharaLimit( group ) <= #group.charas then return false end
	local need = QueryCityCharaLimit( city )
	local has = #city.charas
	return has < need
end

local function HireCharaProposal()
	local charaList = _register["CHARALIST"]
	
	local index

	index = _ai:GetRandomByRange( 1, #charaList, "Hire Chara" )
	local chara = charaList[index]
	
	if chara:GetGroup() then
		print( "hire hint", _chara.name, _chara:GetGroup().name )
		InputUtility_Pause( chara.name .. " already in group=" .. chara:GetGroup().name )
		return		
	end

	_chara:SubmitProposal( { type = CharacterProposal.HR_HIRE, data = chara:GetLocation(), target = chara, proposer = _chara, actor = _actor } )
end

local CharacterAI_HireCharaProposal =
{
	type = "SEQUENCE", desc = "HIRE", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="HR_HIRE" } },
		{ type = "FILTER", condition = CanHireChara },
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "HIRETARGET_CHARALIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
		{ type = "ACTION", action = HireCharaProposal },
	}
}
local CharacterAI_CallCharaProposal =
{
	type = "SEQUENCE", desc = "Call", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="HR_CALL" } },
		{ type = "FILTER", condition = IsCapital },
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "FREECHARA_NONCAPITAL_LIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
		{ type = "ACTION", action = CallCharaProposal },
	}
}
local CharacterAI_DispatchCharaProposal =
{
	type = "SEQUENCE", desc = "Dispatch to Empty City", children =
	{
		{ type = "FILTER", condition = IsCapital },
		{ type = "FILTER", condition = FindProposalActor, params = { type="HR_DISPATCH" } },
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "UNDERSTAFFED_NONCAPITAL_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREECHARA_INCAPITAL_LIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 1 } },
		{ type = "ACTION", action = DispatchCharaProposal },
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

	_chara:SubmitProposal( { type = CharacterProposal.HR_EXILE, data = chara:GetLocation(), target = chara, proposer = _chara, actor = _actor } )
end

local CharacterAI_ExileCharaProposal =
{
	type = "SEQUENCE", desc = "EXILE", children =
	{
		{ type = "FILTER", condition = IsCapital },
		{ type = "FILTER", condition = FindProposalActor, params = { type="HR_EXILE" } },
		{ type = "FILTER", condition = NeedExileChara },
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "REDUNTANT_CHARALIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
		{ type = "ACTION", condition = ExileCharaProposal },
	}
}

local function LookForTalentProposal()	
	_chara:SubmitProposal( { type = CharacterProposal.HR_LOOKFORTALENT, data = _chara:GetLocation(), target = _chara, proposer = _chara, actor = _actor } )
end

local CharacterAI_LookForTalentProposal = 
{
	type = "SEQUENCE", desc = "HIRE", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="HR_LOOKFORTALENT" } },
		{ type = "FILTER", condition = CanHireChara },
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
	--if g_taskMng:IsTaskConflictWithCity( TaskType.ESTABLISH_CORPS, city ) then return false end	
	return city:CanEstablishCorps()
end

local function EstablishProposal()
	local troopList = _register["TROOPLIST"]
	--[[
	for k, troop in ipairs( troopList ) do
		print( NameIDToString( troop ) )
	end
	]]
	--InputUtility_Pause( "establish=" .. #troopList )
	troopList = nil
	_chara:SubmitProposal( { type = CharacterProposal.ESTABLISH_CORPS, data = _blackboard.city, target = troopList, proposer = _chara, actor = _actor } )
end

local CharacterAI_EstablishCorpsProposal = 
{
	type = "SEQUENCE", desc = "Establish Corps", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="ESTABLISH_CORPS" } },
		{ type = "FILTER", condition = CanEstablishCorps },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
		{ type = "ACTION", action = EstablishProposal },
	}
}

---------------------------------------------
local function CanRecruit( checkCity )
	local city = checkCity or _blackboard.city
	--if g_taskMng:IsTaskConflictWithCity( TaskType.RECRUIT_TROOP, city ) then return false end
	return city:CanRecruit()
end
local function NeedRecruit( checkCity )
	local city = checkCity or _blackboard.city
	local troopNumber = GlobalConst.DEFAULT_TROOP_NUMBER
	local militaryService = city:GetMSPopulation()
	if militaryService < troopNumber then
		--ShowText( "military service not enough " )
		return false
	end
	
	local reqPower = city:GetReqMilitaryPower()
	local supply = city:GetSupply()
	local power  = city:GetMilitaryPower()	
	--InputUtility_Pause( "Popu=" .. city.population .. " Pow=" .. power .. " req_pow=" .. reqPower, " sol=" .. troopNumber .. " sup=" .. supply )
	
	--Make supply enough to evoid starvation
	if supply < city.population + power then
		ShowText( "Cann't recruit, out of supply" )
		return false
	end

	--Limit by the food consume
	if ( power + troopNumber ) * CityParams.SAFETY_FOOD_CONSUME_TIME / GlobalConst.UNIT_TIME > city.food then
		debugInfo( "Cann't recruit, out of food" )
		return false
	end
	
	--We always try to keep the number as we required?
	if power < reqPower then
		return true
	elseif city.population < city:GetReqPopulation() then
		--print( city.name.. " Cann't recruit, Out of required popu=" .. city.population.. "/" .. city:GetReqPopulation() )
		return false
	elseif power >= reqPower * CityParams.MILITARY.REQUIRE_MILITARYPOWER_LIMITATION_MODULUS	then
		local list = city:GetAdjacentGroupMilitaryPowerList()
		--MathUtility_Foreach( list, function( k, v ) print( k .. "=" .. v ) end )
		--print( city.name.. " Cann't recruit, Out of required power=" .. power .. "/" .. reqPower * CityParams.MILITARY.REQUIRE_MILITARYPOWER_LIMITATION_MODULUS	)
		return false
	end	
	return city:IsPopulationEnough()
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
		{ type = "FILTER", condition = FindProposalActor, params = { type="RECRUIT_TROOP" } },
		{ type = "FILTER", condition = CanRecruit },
		{ type = "FILTER", condition = NeedRecruit },
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
	_chara:SubmitProposal( { type = CharacterProposal.REGROUP_CORPS, data = corps, target = troops, proposer = _chara, actor = _actor } )
end

local CharacterAI_RegroupCorpsProposal = 
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="REGROUP_CORPS" } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "VACANCY_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
		{ type = "ACTION", action = RegroupCorpsProposal },
	}
}

local function TrainCorpsProposal()
	local corpsList = _register["CORPSLIST"]

	local index

	index = _ai:GetRandomByRange( 1, #corpsList, "Regroup corps proposal" )
	local corps = corpsList[index]

	_chara:SubmitProposal( { type = CharacterProposal.TRAIN_CORPS, target = corps, proposer = _chara, actor = _actor } )
end


local CharacterAI_TrainCorpsProposal = 
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="TRAIN_CORPS" } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "UNTRAINED_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "ACTION", action = TrainCorpsProposal },
	}
}

local function CanReinforceCorps()
	local city = _blackboard.city
	return city:CanReinforceCorps()
end
local function NeedReinforceCorps( checkCity )
	local city = checkCity or _blackboard.city
	
	local troopNumber = 0
	local finalCorpsList = {}
	local corpsList = _register["CORPSLIST"]
	for k, corps in ipairs( corpsList ) do
		local need = corps:GetUnderstaffedNumber()
		if need <= city:GetMSPopulation() then
			if troopNumber < need then troopNumber = need end
			table.insert( finalCorpsList, corps )
		end
	end
	if #finalCorpsList <= 0 then
		return false
	end
	
	local reqPower = city:GetReqMilitaryPower()
	local supply = city:GetSupply()
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
	
	_chara:SubmitProposal( { type = CharacterProposal.REINFORCE_CORPS, target = corps, proposer = _chara, actor = _actor } )
end
local CharacterAI_ReinforceCorpsProposal = 
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="REINFORCE_CORPS" } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "UNDERSTAFFED_CROPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = NeedReinforceCorps },
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
	
	_chara:SubmitProposal( { type = CharacterProposal.LEAD_TROOP, target = troop, data = chara, proposer = _chara, actor = _actor } )
end

local CharacterAI_LeadTroopProposal =
{
	type = "SEQUENCE", desc = "Lead", children =
	{
		{ type = "FILTER", condition = FindProposalActor, params = { type="LEAD_TROOP" } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "FREEMILITARYOFFICER_CHARALIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "NONLEADER_TROOPLIST", memname = "TROOPLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
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

local function CheckWarPlan()
	local city = _blackboard.city
	local corpsList = _register["CORPSLIST"]
	local maxCorpsPower = 0
	local findCorps = nil
	for k, corps in ipairs( corpsList ) do
		local power = corps:GetPower()
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
	local findCity = nil
	local cityList = _register["CITYLIST"]
	--print( NameIDToString( city ), "targetcity="..#cityList )
	for k, adjaCity in ipairs( cityList ) do
		local power = GuessCityPower( adjaCity )--city:GetPower()
		--print( adjaCity.name, "pow="..power )
		if power > maxCorpsPower then
			if power < maxCorpsPower * WarfarePlanParams.MAX_TARGETCITY_POWER_MODULUS then
				if not findCity or _ai:RandomProb() < 3000 * ( power / maxCorpsPower ) then
					findCity = adjaCity
				end
			end
		else
			if not findCity or _ai:RandomProb() < 7000 * ( maxCorpsPower / power ) then
				findCity = adjaCity
			end
		end
	end
	if findCorps and findCity then
		_register["CITYTARGET"]  = findCity
		_register["CORPSTARGET"] = findCorps
		--InputUtility_Pause( "Corps="..NameIDToString(findCorps).." pow="..maxCorpsPower.." City="..findCity.name.." pow="..findCity:GetPower() )
		return true
	else
		--Helper_DumpName( cityList )
		--print( "impossible to capture city" )
	end
	return false
end

local function AttackProposal()
	local city = _register["CITYTARGET"]
	local corps = _register["CORPSTARGET"]
	
	if city:GetGroup() == corps:GetGroup() then
		InputUtility_Pause( "why", NameIDToString( corps ), city.name )
	end
	
	if corps:GetLocation():IsInSiege() then
		local combat = g_warfare:GetCombatByLocation( corps:GetLocation() ) 
		if combat then combat:Dump() end
		InputUtility_Pause( "cann't attack in siege status", combat, corps:GetLocation().name )
	end
	
	_chara:SubmitProposal( { type = CharacterProposal.ATTACK_CITY, target = city, data = corps, proposer = _chara, actor = _actor } )
end

local function ExpeditionProposal()
	local cityList = _register["CITYLIST"]
	local index = _ai:GetRandomByRange( 1, #cityList, "Attack Proposal city" )
	local city = cityList[index]

	local corpsList = _register["CORPSLIST"]
	local index = _ai:GetRandomByRange( 1, #corpsList, "Attack Proposal corps" )
	local corps = corpsList[index]

	_chara:SubmitProposal( { type = CharacterProposal.EXPEDITION, target = city, data = corps, proposer = _chara, actor = _actor } )
end

local function IsCityInDanger()
	local _city = _blackboard.city
	return _city:IsInDanger()
end

local function DispatchCorpsProposal()
	local cityList = _register["CITYLIST"]
	local index = _ai:GetRandomByRange( 1, #cityList )
	local city = cityList[index]

	local corpsList = _register["CORPSLIST"]
	local index = _ai:GetRandomByRange( 1, #corpsList )
	local corps = corpsList[index]
	
	if corps:GetLocation() == city then
		print( city.name, _blackboard.city.name )
		InputUtility_Pause( "dispatch to same city" )
	end
	
	_chara:SubmitProposal( { type = CharacterProposal.DISPATCH_CORPS, target = city, data = corps, proposer = _chara, actor = _actor } )
end

local CharacterAI_AttackProposal =
{
	type = "SEQUENCE", desc = "ATTACK", children =
	{
		{ type = "NEGATE", children = { { type = "FILTER", condition = IsCityInDanger }, } },--??
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "PREPAREDTOATTACK_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },		
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },		
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = FindProposalActor, params = { type="ATTACK_CITY" } },
		{ type = "FILTER", condition = CheckWarPlan },
		{ type = "ACTION", action = AttackProposal },
	}
}
local CharacterAI_ExpeditionProposal =
{
	type = "SEQUENCE", desc = "Expedition", children =
	{
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "PREPAREDTOATTACK_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },		
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "EQUALS", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "REACHABLE_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = FindProposalActor, params = { type="EXPEDITION" } },
		{ type = "ACTION", action = ExpeditionProposal },
	}
}

local CharacterAI_DispatchCorpsProposal = 
{
	type = "SEQUENCE", desc = "Expedition", children =
	{
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_INDANGER_SELFGROUP_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "PREPAREDTOATTACK_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = FindProposalActor, params = { type="DISPATCH_CORPS" } },
		{ type = "ACTION", action = DispatchCorpsProposal },
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
			{ type = "SELECTOR", desc = "START Military proposal", children =
				{
					CharacterAI_AttackProposal,
					CharacterAI_ExpeditionProposal,
					CharacterAI_DispatchCorpsProposal,
				}
			}
		} },
	},
}

---------------------------------------------

local function SelectMeetingProposal()
	--ShowText( #_blackboard, _chara.stamina )
	if _chara.stamina > CharacterParams.STAMINA["ACCEPT_PROPOSAL"] and _blackboard.proposals and #_blackboard.proposals > 0 then
		--select proposal
		if  _ai:GetRandom( "Select meeting topic" ) <= RandomParams.MAX_PROBABILITY + ( _chara.stamina - CharacterParams.STAMINA["ACCEPT_PROPOSAL"] ) * RandomParams.PROBABILITY_UNIT then		
			local proposalList = {}
			for k, proposal in ipairs( _blackboard.proposals ) do				
				if g_taskMng:IsLegal( proposal ) then
					--print( "insert proposal=", Meeting:CreateProposalDesc( proposal ) )--.proposer.name )
					table.insert( proposalList, proposal )
				end
			end
			if #proposalList > 0 then
				--print( "resel", #proposalList)
				local index = _ai:GetRandomByRange( 1, #proposalList, "Select proposal" )
				_chara:SubmitProposal( { type = CharacterProposal.AI_SELECT_PROPOSAL, proposal = proposalList[index], proposer = _chara, actor = _actor } )
				return
			end
		end
	end
	
	--AI Leader Submit proposal
	if _chara.stamina > CharacterParams.STAMINA["SUBMIT_PROPOSAL"] then
		--InputUtility_Pause( "ai submit proposal himself" )
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

local CharacterAI_DefaultPriorityProposal = 
{
	--type = "SELECTOR", desc = "", children =	
	type = "RANDOM_SELECTOR", desc = "", children =
	{
		CharacterAI_WarPreparednessBranch,
		CharacterAI_TechProposal,
		CharacterAI_DiplomacyAffaisBranch,
		CharacterAI_CityAffaisBranch,
		CharacterAI_HumanResourceBranch,
		CharacterAI_MilitaryBranch,
	},	
}

---------------------------------------------

local function CheckPriority( params )
	local group = _blackboard.city:GetGroup()
	local category = params.category
	local tag = nil
	if category == "WAR_PREPAREDNESS_AFFAIRS" then
	elseif category == "RECRUIT_TROOP" then	
		tag = group:GetAsset( GroupTag.SITUATION.WEAK )
		
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
		tag = group:GetAsset( GroupTag.SITUATION.AGGRESSIVE )
		--if tag then InputUtility_Pause( group.name, "aggress") end
		
	elseif category == "AT_WAR" then
		tag = group:GetAsset( GroupTag.SITUATION.AT_WAR )
	
	end
	
	return tag ~= nil
end

------------------------------
-- Priority proposal

local HRHirePriorityProposal = 
{
	type = "SEQUENCE", children = { 
		{ type = "FILTER", condition = CheckConflictProposal, params = { type = CharacterProposal.HR_HIRE } },
		{ type = "FILTER", condition = CheckPriority, params = { category="HR_HIRE" } },
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="HR_AFFAIRS" } },					
		CharacterAI_HireCharaProposal 
	}
}

local HRRecruitPriorityProposal = 
{
	type = "SEQUENCE", children = { 
		{ type = "FILTER", condition = CheckPriority, params = { category="RECRUIT_TROOP" } },
		{ type = "FILTER", condition = CheckSwitchMode, params = { mode="HR_AFFAIRS" } },
		CharacterAI_RecruitTroopProposal,
	}
}


local MilitaryPriorityProposal = 
{
	type = "SEQUENCE", children = {	
		{ type = "FILTER", condition = CheckPriority, params = { category="AT_WAR" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", dataname= "PREPAREDTOATTACK_CORPSLIST", number = 0 } },
		CharacterAI_MilitaryBranch,
	},
}

local WarPreparednessPriorityProposal =
{
	type = "SEQUENCE", children = {
		{ type = "FILTER", condition = HasCityTag, params = { flag="WEAK" } },
		CharacterAI_WarPreparednessBranch,
	}
}

------------------------------

local TroopLeaderDiscussProposal = 
{
	type = "SEQUENCE", children =
	{
		{ type = "FILTER", condition = IsCharaLeadTroop },
		CharacterAI_WarPreparednessBranch,
		CharacterAI_MilitaryBranch,
		CharacterAI_HumanResourceBranch,
		CharacterAI_CityAffaisBranch,		
		CharacterAI_PassProposal,
	},
}

local CharacterAI_AggressiveMilitaryProposal =
{
	type = "SELECTOR", children = {
		CharacterAI_MilitaryBranch,
		CharacterAI_WarPreparednessBranch,
	},
}

local CharacterAI_AISubmitProposal =
{
	type = "SEQUENCE", desc = "Start submit proposal", children =
	{
		{ type = "FILTER", condition = CanAssignProposal },
		{ type = "SELECTOR", children = 
			{
				TroopLeaderDiscussProposal,
				MilitaryPriorityProposal,
				WarPreparednessPriorityProposal,
				HRHirePriorityProposal,
				HRRecruitPriorityProposal,
				{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="MILITARY_AGGRESSIVE" } }, CharacterAI_AggressiveMilitaryProposal } },
				{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="DIPLOMACY_AFFAIRS" } }, CharacterAI_DiplomacyAffaisBranch } },
				{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="MILITARY_AFFAIRS" } }, CharacterAI_MilitaryBranch } },				
				{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="CITY_AFFAIRS" } }, CharacterAI_CityAffaisBranch } },				
				{ type = "SEQUENCE", children = { { type = "FILTER", condition = CheckPriority, params = { category="RESEARCH_TECH" } }, CharacterAI_TechProposal } },
				CharacterAI_DefaultPriorityProposal,
			},
		},
	}
}

---------------------------------------------

local OfficerDiscussProposal =
{
	type = "SELECTOR", desc = "", children =
	{
		CharacterAI_TechProposal,
		CharacterAI_WarPreparednessBranch,
		CharacterAI_CityAffaisBranch,
		CharacterAI_HumanResourceBranch,
		CharacterAI_DiplomacyAffaisBranch,
		CharacterAI_MilitaryBranch,
	},
}

local DiplomaticDiscussProposal =
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

local GeneralDiscussProposal = 
{
	type = "SELECTOR", desc = "", children =
	{
		CharacterAI_WarPreparednessBranch,
		CharacterAI_MilitaryBranch,
		CharacterAI_TechProposal,
		CharacterAI_CityAffaisBranch,
		CharacterAI_DiplomacyAffaisBranch,
		CharacterAI_HumanResourceBranch,
	},
}

local CharacterAI_GroupDiscussProposal =
{
	type = "SEQUENCE", desc = "Start submit proposal", children =
	{
		{ type = "FILTER", condition = CanSubmitProposal },
		{ type = "SELECTOR", children = 
			{
				--MilitaryPriorityProposal,
				{ type = "SEQUENCE", children =
					{
						{ type = "FILTER", condition = IsJobMatch, params = { job = "DIPLOMATIC" } },
						DiplomaticDiscussProposal,
					}
				},	
				{ type = "SEQUENCE", children =
					{
						{ type = "FILTER", condition = IsCharaMilitaryOfficer },
						GeneralDiscussProposal,
					}
				},				
				{ type = "SEQUENCE", children =
					{
						{ type = "FILTER", condition = IsCharaCivialOfficial },
						OfficerDiscussProposal,
					}
				},
				CharacterAI_DefaultPriorityProposal,
			}
		}
	}
}

---------------------------------------------

local CharacterAI_CityDiscussProposal =
{
	type = "SEQUENCE", desc = "Start submit proposal", children =
	{
		{ type = "FILTER", condition = CanSubmitProposal },
		{ type = "RANDOM_SELECTOR", desc = "", children =
			{
				CharacterAI_WarPreparednessBranch,
				CharacterAI_CityAffaisBranch,
				CharacterAI_HumanResourceBranch,
				CharacterAI_MilitaryBranch,
			},
		}
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

	elseif type == CharacterAICategory.AI_SELECT_PROPOSAL then
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
	--ShowText( "Blackboard=", name, _blackboard[name] )
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
