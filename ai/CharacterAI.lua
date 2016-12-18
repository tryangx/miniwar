CharacterAICategory =
{
	CITY_DEVELOP             = 3,

	TECH_PROPOSAL             = 10,
	DIPLOMACY_PROPOSAL        = 11,
	CITY_DEVELOP_PROPOSAL     = 12,
	CITY_HR_PROPOSAL          = 13,
	WAR_PREPAREDNESS_PROPOSAL = 14,
	MILITARY_PROPOSAL         = 15,
	DIPLOMACY_PROPOSAL        = 16,

	AI_SELECT_PROPOSAL       = 21,
	AI_SUBMIT_PROPOSAL       = 22,

	GROUP_DISCUSS_PROPOSAL   = 30,

	CITY_DISCUSS_PROPOSAL    = 40,
}

local _chara  = nil
local _ai     = nil
local _target = nil
local _blackboard = nil
local _register = {}

---------------------------------------------
-- Common

local function QueryGroupData( dataname )
	local _city = _blackboard.city
	local group = _city:GetGroup()
	local value = nil
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
		--print( "max free", value )
	elseif dataname == "NUMBER_FREE_CHARA_IN_CAPITAL" then
		value = group:GetCapital():GetNumOfFreeChara()
		--print( "free chara in cap", value )
		
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
	elseif dataname == "EMPTY_CITYLIST" then
		value = {}
		for k, city in ipairs( group.cities ) do
			if #city.charas == 0 then
				table.insert( value, city )
			end
		end
	elseif dataname == "OUTCHARALIST" then
		value = {}
		for k, chara in ipairs( g_outCharacterList ) do
			if chara:GetLocation() and chara:GetLocation():GetGroup() == group then
				table.insert( value, chara )
			end
		end

	elseif dataname == "REACHABLE_BELLIGERENT_CITYLIST" then
		value = group:GetReachableBelligerentCityList()

	end
	return value
end

local function QueryCityData( dataname )
	local _city = _blackboard.city
	local value = 0
	if dataname == "NUMBER_CORPS" then
		value = #_city.corps
	elseif dataname == "NUMBER_TROOP" then
		value = #_city.troops
	elseif dataname == "MAX_CORPS_NUMBER" then
		value = math.floor( _city.size / 2 )
	elseif dataname == "NUMBER_IDLE_CORPS" then
		value = _city:GetNumOfIdleCorps()
	elseif dataname == "NUMBER_FREE_CHARA" then
		value = _city:GetNumOfFreeChara()

	elseif dataname == "FREE_CHARALIST" then
		value = _city:GetFreeCharaList()

	elseif dataname == "NONLEADER_TROOPLIST" then
		value = _city:GetNonLeaderTroopList()

	elseif dataname == "IDLE_CORPSLIST" then
		value = _city:GetIdleCorpsList()
		if #value > 0 then
			--print( "has idle corps")
		end

	elseif dataname == "NONCORPS_TROOPLIST" then
		value = _city:GetNonCorpsTroopList()

	elseif dataname == "VACANCY_CORPSLIST" then
		value = _city:GetVacancyCorpsList()

	elseif dataname == "ADJACENT_HOSTILE_CITYLIST" then
		value = _city:GetAdjacentHostileCityList()
	elseif dataname == "ADJACENT_BELLIGERENT_CITYLIST" then
		value = _city:GetAdjacentBelligerentCityList()
		if #value > 0 then
			--print( "has adja belli" )
		end

	end
	--print( dataname, value )
	return value
end

local function MemoryGroupData( params )
	if not params.dataname or not params.memname then
		print( "Missing memory params" )
		return false
	end
	_register[params.memname] = QueryGroupData( params.dataname )
	--print( "memory group", params.memname, #_register[params.memname] )
	return true
end

local function MemoryCityData( params )
	if not params.dataname or not params.memname then
		print( "Missing memory params" )
		return false
	end
	_register[params.memname] = QueryCityData( params.dataname )
	--print( "memory city", params.memname, _register[params.memname] )
	return true
end

local function CompareValue( compare, value, compareValue )
	if compare == "EQUALS" then
		return value == compareValue
	elseif compare == "MORE_THAN" then
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
			print( "No memory name" )
			return false
		end
		compareValue = _register[params.memname]
	end
	return compareValue
end

local function CompareData( params, dataFunction )
	if ( not params.dataname and not params.datamem ) or not params.number or not params.compare then
		print( "Missing compare params" )
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
		print( "convert list to length" )
		value = #value
	end
	if type( compareValue ) == "table" then
		print( "convert list to length" )
		compareValue = #compareValue
	end
	--print( "Compare", value, compareValue, params.dataname, params.datamem )
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
	local priviage = CharacterParams.PRIVIAGE[_chara:GetJob()]
	if not priviage then return false end
	if #_chara:GetLocation().charas <= 2 then
		--return true
	end
	--print( _chara.name .. " job=" .. MathUtility_FindEnumName( CharacterJob, _chara:GetJob() ) .. " have priviage " .. params.affair, priviage[params.affair] )
	if priviage["ALL"] or priviage[params.affair] then return true end
	--print( _chara.name .. " job=" .. MathUtility_FindEnumName( CharacterJob, _chara:GetJob() ) .. " don't have priviage " .. params.affair, priviage[params.affair] )
	return false
end

local function IsJobMatch( params )
	return _chara:GetJob() == MathUtility_FindEnumName( CharacterJob, params.job ) 	
end

local function IsCharaMilitaryOfficer( params )	
	return _chara:IsMilitaryOfficer()
end

local function IsCharaOfficer( params )
	return _chara:IsOfficer()
end

-----------------------------------------------------

local function CheckCityInstruction( params )
	if not params.instruction then return false end
	local instruction = params.instruction
	local city = _blackboard.city
	return city and city.instruction == CityInstruction[instruction] or true
end

local function CheckEnoughMoney( params )
	if not params.money then return false end
	local money = params.money
	local city = _blackboard.city
	local group = city:GetGroup()
	--print( "check enough money", group:GetMoney(), money )
	return group:GetMoney() >= money
end

local function CheckLeakMoney( params )
	if not params.money then return false end
	local money = params.money
	local city = _blackboard.city
	local group = city:GetGroup()
	--print( "check leak money", group:GetMoney(), money )
	return group:GetMoney() < money
end

local function CheckProbaility( params )
	if not params.prob then return false end
	local prob = params.prob
	return _ai:GetRandom( "Check probability" ) <= prob
end

local function CanBuild()
	local city = _blackboard.city
	return city:CanBuild()
end

---------------------------------------------
-- Character Technological

local function CanResearchTech()
	if not _chara:GetGroup():CanResearch() then return false end	
		
	--[[
	local tendency = CharacterProposalTendency[_chara:GetJob()]
	if not tendency then tendency = CharacterProposalTendency[0] end

	local prob = tendency.PROPOSAL["TECH"]
	if not prob then prob = 0 end

	if _ai:GetRandom( "Character consider tech" ) > prob then return false end
	]]
	local number = #_chara:GetGroup()._canResearchTechs
	if number == 0 then return false end
		
	local tech = _chara:GetGroup()._canResearchTechs[_ai:RandomRange( 1, number, "Character choice tech" )]
	_target = { type = CharacterProposal.TECH_RESEARCH, tech = tech, chara = _chara }

	return true
end

local function ResearchTechProposal()
	_chara:SubmitProposal( _target )
end

local CharacterAI_TechProposal =
{
	type = "SEQUENCE", desc = "START tech", children =
	{
		{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "TECH_RESEARCH" } },		
		{ type = "FILTER", condition = CanResearchTech },
		{ type = "ACTION", action = ResearchTechProposal },
	}
}

---------------------------------------------

local function SubmitDiplomacyProposal( params )
	--print( "submit proposal" )
	_chara:SubmitProposal( { type = CharacterProposal[params.proposal], group = _target, chara = _chara, prob = _blackboard.targetProb } )
end

local function GetDiplomacyTarget( params )
	local totalProb = _blackboard.totalProb
	local relations = _blackboard[params.listname]

	if not totalProb or totalProb <= 0 or not relations then
		return false
	end

	_target = nil
	local value = _ai:RandomRange( 1, totalProb, "Get target" )
	for k, relation in ipairs( relations ) do
		if value < relation.prob then
			_target = relation.group
			_ai:AppendBlackboard( "targetProb", relation.prob )
			break
		else
			value = value - relation.prob
		end
	end
	--print( "target=", _target.id, _target.name )
	return _target ~= nil
end

function EvaluateDiplomacy( method, relation, group, target )
	if not relation:IsMethodValid( method, group, target ) or not target then
		return 0
	end
	local prob = 0
	--print( "evaluate", MathUtility_FindEnumName( DiplomacyMethod, method ) )
	if method == DiplomacyMethod.FRIENDLY then
		prob = relation:EvalFriendlyProb( _chara, group, target )
	elseif method == DiplomacyMethod.THREATEN then
		prob = relation:EvalThreatenProb( _chara, group, target )
	elseif method == DiplomacyMethod.ALLY then
		prob = relation:EvalAllyProb( _chara, group, target )
	elseif method == DiplomacyMethod.DECLARE_WAR then
		prob = relation:EvalDeclareWarProb( _chara, group, target )
	elseif method == DiplomacyMethod.MAKE_PEACE then
		prob = relation:EvalMakePeaceProb( _chara, group, target )
	elseif method == DiplomacyMethod.BREAK_CONTRACT then
		prob = relation:EvalBreakContractProb( _chara, group, target )
	elseif method == DiplomacyMethod.SURRENDER then
		prob = relation:EvalSurrenderProb( _chara, group, target )
	end
	--diplomatic
	if _chara then
		trait = _chara:QueryTrait( TraitEffectType.DIPLOMACY_SUCCESS_PROB )
		if trait then
			prob = prob + trait.value
		end
		if _chara:IsDiplomatic() then
			prob = prob + GroupRelationParam.DIPLOMATIC_BONUS
		end
	end
	return math.floor( prob )
end

local function SelectDiplomacyTarget( params )
	local _group = _chara:GetGroup()

	local list = _group.relations--:GetFriendRelations()

	local numOfGroup = #list
	if numOfGroup <= 0 then
		return false
	end
	local tendency = CharacterProposalTendency[_chara:GetJob()]
	if not tendency then tendency = CharacterProposalTendency[0] end

	local method = DiplomacyMethod[params.method]

	local totalProb = 0
	local relations = {}
	for k, relation in ipairs( list ) do
		local target = relation:GetOppGroup( _group.id )
		local prob = math.floor( EvaluateDiplomacy( method, relation, _group, target ) )
		local success = tendency.SUCCESS_CRITERIA[params.method]
		--print( "prob=", prob, success )
		if prob >= success then
			totalProb = totalProb + prob
			table.insert( relations, { group = target, prob = prob } )
			--print( "Append " .. MathUtility_FindEnumName( DiplomacyMethod, method )  .. "=" .. target.name .. " relation=" .. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " prob=" .. prob )
		end
	end

	if #relations <= 0 then
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
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "MAKE_PEACE" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "MAKE_PEACE_DIPLOMACY" } }
	}
}

local CharacterAI_FriendlyProposal =
{
	type = "SEQUENCE", desc = "friendly", children =
	{
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "FRIENDLY" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "FRIENDLY_DIPLOMACY" } }
	}
}

local CharacterAI_ThreatenProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "THREATEN" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "THREATEN_DIPLOMACY" } }
	}
}

local CharacterAI_AllyProposal =
{
	type = "SEQUENCE", desc = "Ally", children =
	{
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "ALLY" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "ALLY_DIPLOMACY" } }
	}
}

local CharacterAI_DeclareWarProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "DECLARE_WAR" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "DECLARE_WAR_DIPLOMACY" } }
	}
}

local CharacterAI_BreakContractProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "BREAK_CONTRACT" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "BREAK_CONTRACT_DIPLOMACY" } }
	}
}

local CharacterAI_SurrenderProposal =
{
	type = "SEQUENCE", desc = "threaten", children =
	{
		{ type = "FILTER", condition = SelectDiplomacyTarget, params = { method = "SURRENDER" } },
		{ type = "FILTER", condition = GetDiplomacyTarget, params = { listname = "relations" } },
		{ type = "ACTION", desc = "action", action = SubmitDiplomacyProposal, params = { proposal = "SURRENDER_DIPLOMACY" } }
	}
}

----------------------------------------

local function CheckDiplomacyTendency( params )
	print( "method=", params.method )
	return true
end

CharacterAI_DiplomacyProposal =
{
	type = "SEQUENCE", children = 
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
	}	
}

---------------------------------------------

local function CheckInstruction( params )
	local city = _blackboard.city

	if city == city:GetGroup():GetCapital()	then return true end
	
	if city.instruction == CityInstruction.NONE then return true end

	if params.flow == "CITY_AFFAIRS" then
		if city.instruction == CityInstruction.BUILD or city.instruction == CityInstruction.ECONOMIC then return true end
	elseif params.flow == "CITY_BUILD" then
		if city.instruction == CityInstruction.BUILD then return true end
	elseif params.flow == "CITY_ECONOMIC" then
		if city.instruction == CityInstruction.ECONOMIC then return true end
	elseif params.flow == "WAR_PREPAREDNESS" then
		--print( "check instruction=".. MathUtility_FindEnumName( CityInstruction, city.instruction ), params.flow )
		if city.instruction == CityInstruction.WAR_PREPAREDNESS then return true end
	elseif params.flow == "MILITARY" then
		if city.instruction == CityInstruction.MILITARY then return true end
	end

	if _ai:GetRandom() < 5000 then return true end

	return false
end

---------------------------------------------

local function BuildCity()
	local city = _blackboard.city
	local constructionList = city:GetBuildList()
	if #constructionList <= 0 then return end

	local index = _ai:RandomRange( 1, #constructionList, "Select Construction" )
	local construction = constructionList[index]

	CityBuildConstruction( city, construction )
end
local function CanInvest()
	local city = _blackboard.city
	return city:CanInvest()
end
local function CanLevyTax()
	local city = _blackboard.city
	return city:CanLevyTax()
end

local function InvestCity()
	local city = _blackboard.city
	CityInvest( city )
end

local function CityLevyTax()
	local city = _blackboard.city
	CityLevyTax( city )
end

local function RecruitCity()
	local city = _blackboard.city
	CityRecruit( city )
end

local CharacterAI_Develop =
{
	type = "SELECTOR", desc = "START Develop", children =
	{
		{ type = "SEQUENCE", desc = "Military Prior", children =
			{
				{ type = "FILTER", desc = "instruction check", condition = CheckCityInstruction, params = { instruction = "MILITARY" } },
				--{ type = "FILTER", desc = "money check", condition = CheckMoney, params = { money = 10000 } },
				--{ type = "FILTER", desc = "prob check", condition = CheckProbaility, params = { prob = 6000 } },
				{ type = "ACTION", desc = "end", action = RecruitCity },
			}
		},

		{ type = "SEQUENCE", desc = "Economic Prior", children =
			{
				{ type = "FILTER", desc = "instruction check", condition = CheckCityInstruction, params = { instruction = "ECONOMIC" } },
				{ type = "SELECTOR", desc = "invest branch", children =
					{
						{ type = "FILTER", desc = "money check", condition = CheckEnoughMoney, params = { money = 10000 } },
						{ type = "ACTION", desc = "end", action = InvestCity },
					}
				},
				{ type = "SELECTOR", desc = "tax branch", children =
					{
						{ type = "FILTER", desc = "money check", condition = CheckLeakMoney, params = { money = 5000 } },
						{ type = "ACTION", desc = "end", action = CityLevyTax },
					}
				},
			}
		},

		{ type = "SEQUENCE", desc = "Construction Prior", children =
			{
				{ type = "FILTER", desc = "instruction check", condition = CheckCityInstruction, params = { instruction = "CONSTRUCTION" } },
				{ type = "FILTER", desc = "status check", condition = CanBuild },
				--{ type = "FILTER", desc = "money check", condition = CheckMoney, params = { money = 10000 } },
				--{ type = "FILTER", desc = "prob check", condition = CheckProbaility, params = { prob = 6000 } },
				{ type = "ACTION", desc = "end", action = BuildCity },
			}
		},
	},
}

local function BuildCityProposal()
	local city = _blackboard.city
	local list = city:GetBuildList()
	local index = _ai:RandomRange( 1, #list, "Build construction proposal" )
	local constr = list[index]
	_chara:SubmitProposal( { type = CharacterProposal.CITY_BUILD, city = city, constr = constr, chara = _chara } )
end

local function InvestCityProposal()
	--print( "invest " )
	_chara:SubmitProposal( { type = CharacterProposal.CITY_INVEST, city = _blackboard.city, chara = _chara } )
end

local function LevyTaxCityProposal()
	_chara:SubmitProposal( { type = CharacterProposal.CITY_LEVY_TAX, city = _blackboard.city, chara = _chara } )
end

local function CanInstruct()
	return true
end

local function InstructCityProposal()
	local list = {}
	for k, instr in pairs( CityInstruction ) do
		table.insert( list, instr )
	end
	local index = _ai:RandomRange( 1, #list, "City instruct proposal" )
	local instruction = list[index]
	_chara:SubmitProposal( { type = CharacterProposal.CITY_INSTRUCT, city = _blackboard.city, instruction = instruction, chara = _chara } )
end

local CharacterAI_CityAffaisConstructionProposal =
{
	type = "SEQUENCE", desc = "Construction", children =
	{
		{ type = "FILTER", desc = "status check", condition = CanBuild },
		{ type = "ACTION", desc = "end", action = BuildCityProposal },
	}
}

local CharacterAI_CityAffaisEconomicProposal =
{
	type = "SELECTOR", desc = "Economic", children =
	{
		{ type = "SEQUENCE", desc = "invest branch", children =
			{
				{ type = "FILTER", desc = "money check", condition = CheckEnoughMoney, params = { money = 10000 } },
				{ type = "FILTER", desc = "money check", condition = CanInvest },
				{ type = "ACTION", desc = "end", action = InvestCityProposal },
			}
		},
		{ type = "SEQUENCE", desc = "tax branch", children =
			{
				{ type = "FILTER", desc = "money check", condition = CheckLeakMoney, params = { money = 5000 } },
				{ type = "FILTER", desc = "money check", condition = CanLevyTax },
				{ type = "ACTION", desc = "end", action = LevyTaxCityProposal },
			}
		},
	}
}
local CharacterAI_InstructProposal =
{
	type = "SEQUENCE", desc = "Instruct", children =
	{
		{ type = "FILTER", desc = "status check", condition = IsCapital },
		{ type = "FILTER", desc = "", condition = CanInstruct },
		{ type = "ACTION", desc = "end", action = InstructCityProposal },
	}
}

local CharacterAI_CityAffaisProposal =
{
	type = "SEQUENCE", children = 
	{
		{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "CITY_AFFAIRS" } },	
		{ type = "SELECTOR", desc = "START City Affairs proposal", children =
			{
				{ type = "SEQUENCE", desc = "Instruction branch", children =
					{
						{ type = "FILTER", condition = CheckInstruction, params = { flow = "CITY_BUILD" } },
						CharacterAI_CityAffaisConstructionProposal,
					}
				},
				{ type = "SEQUENCE", desc = "Instruction branch", children =
					{
						{ type = "FILTER", condition = CheckInstruction, params = { flow = "CITY_ECONOMIC" } },
						CharacterAI_CityAffaisEconomicProposal,
					}
				},
				{ type = "SEQUENCE", desc = "total branch", children =
					{
						{ type = "FILTER", condition = CheckInstruction, params = { flow = "CITY_AFFAIRS" } },
						{ type = "RANDOM_SELECTOR", desc = "START Develop proposal", children =
							{
								CharacterAI_CityAffaisConstructionProposal,
								CharacterAI_CityAffaisEconomicProposal,
								CharacterAI_InstructProposal,
							},
						},
					},
				},
			},
		}
	}
}
---------------------------------------------

local function DispatchCharaProposal()
	local _city = _blackboard.city
	local group = _city:GetGroup()

	local cityList = _register["CITYLIST"]
	local index = _ai:RandomRange( 1, #cityList, "Dispatch Chara Proposal destination" )
	local city = cityList[index]

	local charas = {}
	for k, chara in ipairs( _city.charas ) do
		if chara:IsFree() then
			table.insert( charas, chara )
		end
	end

	index = _ai:RandomRange( 1, #cityList, "Dispatch Chara Proposal character" )
	local chara = charas[index]

	_chara:SubmitProposal( { type = CharacterProposal.HR_DISPATCH, targetCity = city, targetChara = chara, chara = _chara } )
end

local function CallCharaProposal()
	local city = _chara:GetCity()

	local cityList = _register["CITYLIST"]
	local index = _ai:RandomRange( 1, #cityList, "Dispatch Chara Proposal destination" )
	local fromCity = cityList[index]

	local charas = {}
	for k, chara in ipairs( fromCity.charas ) do
		if not chara:IsLeadTroop() and not chara:IsImportant() then
			table.insert( charas, chara )
		end
	end
	index = _ai:RandomRange( 1, #cityList, "Dispatch Chara Proposal character" )
	local chara = charas[index]

	_chara:SubmitProposal( { type = CharacterProposal.HR_CALL, targetCity = city, targetChara = chara, chara = _chara } )
end

local function LeadTroopProposal()
	local charaList = _register["CHARALIST"]
	local troopList = _register["TROOPLIST"]

	local index

	index = _ai:RandomRange( 1, #charaList, "Lead Troop Proposal character" )
	local chara = charaList[index]

	index = _ai:RandomRange( 1, #troopList, "Lead Troop Proposal troop" )
	local troop = troopList[index]

	_chara:SubmitProposal( { type = CharacterProposal.LEAD_TROOP, targetTroop = troop, targetChara = chara, chara = _chara } )
end

local function IsCapital()
	local city = _blackboard.city
	return city == city:GetGroup():GetCapital()
end

local function CanHireChara()	
	local city = _blackboard.city
	local group = city:GetGroup()
	local leader = group:GetLeader()
	local params = CharacterParams.SUBORDINATE_LIMIT[leader:GetJob()]
	return params and params < #group.charas or 0
end

local function NeedExileChara()
	--never
	return false
end

local function HireCharaProposal()
	local charaList = _register["CHARALIST"]
	
	local index

	index = _ai:RandomRange( 1, #charaList, "Hire Chara" )
	local chara = charaList[index]

	_chara:SubmitProposal( { type = CharacterProposal.HR_HIRE, targetChara = chara, targetCity = chara:GetLocation(), chara = _chara } )
end

local CharacterAI_HireCharaProposal =
{
	type = "SEQUENCE", desc = "HIRE", children =
	{
		{ type = "FILTER", condition = CanHireChara },						
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "OUTCHARALIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
		{ type = "ACTION", action = HireCharaProposal },
	}
}
local CharacterAI_CallCharaProposal =
{
	type = "SEQUENCE", desc = "Call", children =
	{
		{ type = "FILTER", condition = IsCapital },
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "MAX_FREE_CHARA_NONCAPITAL_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "LESS_THAN", dataname = "NUMBER_FREE_CHARA_IN_CAPITAL", number = 2 } },
		{ type = "ACTION", action = CallCharaProposal },
	}
}
local CharacterAI_DispatchCharaProposal =
{
	type = "SEQUENCE", desc = "Dispatch to Empty City", children =
	{
		{ type = "FILTER", condition = IsCapital },
		{ type = "FILTER", condition = MemoryGroupData, params = { dataname = "EMPTY_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareGroupData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", dataname = "NUMBER_FREE_CHARA", number = 1 } },
		{ type = "ACTION", action = DispatchCharaProposal },
	}
}
local CharacterAI_ExileCharaProposal =
{
	type = "SEQUENCE", desc = "EXILE", children =
	{
		{ type = "FILTER", condition = NeedExileChara },
	}
}

local CharacterAI_HumanResourceProposal =
{
	type = "SEQUENCE", desc = "START HR proposal", children =
	{
		{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "HR_AFFAIRS" } },
		{ type = "FILTER", condition = CheckInstruction, params = { flow = "HUMAN_RESOURCE" } },
		{ type = "SELECTOR", children =
			{
				CharacterAI_HireCharaProposal,						
				CharacterAI_CallCharaProposal,
				CharacterAI_DispatchCharaProposal,
				CharacterAI_ExileCharaProposal,
			},
		},
	}
}

---------------------------------------------

local function CanRecruit( checkCity )
	local city = checkCity or _blackboard.city
	return city:CanRecruit()
end

local function IsCityInDanger( checkCity )
	local city = checkCity or _blackboard.city
	local power  = city:GetMilitaryPower()
	if power == 0 then
		return true
	end	
	local list = city:GetAdjacentGroupMilitaryPowerList()
	for k, otherPower in pairs( list ) do
		--print( "power comparsion", otherPower, power )
		if otherPower > power and power / otherPower < CityParams.SAFETY_MILITARY_POWER_RATE_TO_ADJACENT_GROUP then
			InputUtility_Pause( "Indanger", otherPower, power)
			return true
		end
	end
	return false
end

local function NeedRecruit( checkCity )
	local city = checkCity or _blackboard.city
	local reqPower
	if city:IsInConflict() then
		reqPower = city:GetBattlefrontMilitaryPower()
	else
		reqPower = city:GetSafetyMilitaryPower()
	end
	local supply = city:GetSupply()
	local power  = city:GetMilitaryPower()
	local troopNumber = city:GetMaxNumberRecruitTroop()
	local minPopulation = city:GetMinPopulation()
	--print( "Popu=" .. city.population .. "/" .. minPopulation, " Pow=" .. power .. "/" .. reqPower, " Sol=" .. troopNumber .. "/" .. supply )
	
	--we need keep enough population
	if city:GetMinPopulation() > city.population then 
		print( "Cann't recruit, Population is less than minimum required number" )
		return false
	end

	--we don't want to make starvation
	if power + troopNumber > supply then
		print( "Cann't recruit, Out of supply" )
		return false
	end

	--we always try to keep the number as we required
	if power >= reqPower then
		print( "Cann't recruit, Out of required power" )
		return false
	end

	return true
end

local function CanEstablishCorps()
	local city = _blackboard.city
	return city:CanEstablishCorps()
end

local function CanReinforceCorps()
	local city = _blackboard.city
	return city:CanReinforceCorps()
end

local function RecruitCityProposal( checkCity )
	local city = checkCity or _blackboard.city
	local list = city:GetRecruitList()
	local index = _ai:RandomRange( 1, #list, "Recruit troop proposal" )
	local troop = list[index]
	_chara:SubmitProposal( { type = CharacterProposal.RECRUIT_TROOP, city = city, troop = troop, chara = _chara } )
end

local function ReinforceCorpsProposal()
	local corpsList = _register["CORPSLIST"]
	local troopList = _register["TROOPLIST"]

	local index

	index = _ai:RandomRange( 1, #corpsList, "Reinforce corps proposal" )
	local corps = corpsList[index]

	local troops = {}
	MathUtility_Shuffle( troopList, _ai:GetRandomizer() )
	for k, troop in ipairs( troopList ) do
		table.insert( troops, troop )
	end

	_chara:SubmitProposal( { type = CharacterProposal.REINFORCE_CORPS, corps = corps, troops = troops, chara = _chara } )
end

local function EstablishProposal()
	_chara:SubmitProposal( { type = CharacterProposal.ESTABLISH_CORPS, city = _blackboard.city, chara = _chara } )
end


local debugProposal = { type = "FILTER", condition = function ()
	print( "turn to " .. _chara.name )
	return true
end }

local waitProposal = { type = "FILTER", condition = function ()
	InputUtility_Wait( "abc" )
	return true
end }

local CharacterAI_EstablishCorpsProposal = 
{
	type = "SEQUENCE", desc = "Establish Corps", children =
	{
		{ type = "FILTER", condition = CanEstablishCorps },
		{ type = "ACTION", action = EstablishProposal },
	}
}
local CharacterAI_RecruitTroopProposal = 
{
	type = "SEQUENCE", desc = "Recruit Troop", children =
	{
		{ type = "FILTER", condition = CanRecruit },
		{ type = "FILTER", condition = NeedRecruit },
		{ type = "FILTER", condition = IsCityInDanger },
		{ type = "ACTION", action = RecruitCityProposal },
	}
}
local CharacterAI_ReinforceCorpsProposal = 
{
	type = "SEQUENCE", desc = "Reinforce Corps", children =
	{
		{ type = "FILTER", desc = "compare number of vacancy corps", condition = MemoryCityData, params = { dataname = "VACANCY_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", desc = "memory number of vacancy corps", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", desc = "compare number of troops not in corps", condition = MemoryCityData, params = { dataname = "NONCORPS_TROOPLIST", memname = "TROOPLIST" } },
		{ type = "FILTER", desc = "memory number of troops not in corps", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
		{ type = "ACTION", action = ReinforceCorpsProposal },
	}
}
local CharacterAI_LeadTroopProposal =
{
	type = "SEQUENCE", desc = "Lead", children =
	{
		{ type = "FILTER", desc = "get list of troops without leader", condition = MemoryCityData, params = { dataname = "NONLEADER_TROOPLIST", memname = "TROOPLIST" } },
		{ type = "FILTER", desc = "compare number of troops without leader", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "TROOPLIST", number = 0 } },
		{ type = "FILTER", desc = "get list of ", condition = MemoryCityData, params = { dataname = "FREE_CHARALIST", memname = "CHARALIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CHARALIST", number = 0 } },
		{ type = "ACTION", action = LeadTroopProposal },
	}
}

local CharacterAI_WarPreparednessProposal =
{
	type = "SEQUENCE", desc = "START War Preparedness proposal", children =
	{
		{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "WAR_PREPAREDNESS_AFFAIRS" } },		
		{ type = "FILTER", condition = CheckInstruction, params = { flow = "WAR_PREPAREDNESS" } },
		{ type = "SELECTOR", desc = "START War Preparedness proposal", children =
			{
				CharacterAI_RecruitTroopProposal,
				CharacterAI_ReinforceCorpsProposal,
				CharacterAI_EstablishCorpsProposal,
				CharacterAI_LeadTroopProposal,
			}
		},
	}
}

---------------------------------------------

local function AttackProposal()
	local cityList = _register["CITYLIST"]
	local index = _ai:RandomRange( 1, #cityList, "Attack Proposal city" )
	local city = cityList[index]

	local corpsList = _register["CORPSLIST"]
	local index = _ai:RandomRange( 1, #corpsList, "Attack Proposal corps" )
	local corps = corpsList[index]

	_chara:SubmitProposal( { type = CharacterProposal.ATTACK_CITY, targetCity = city, targetCorps = corps, chara = _chara } )
end

local function ExpeditionProposal()
	local cityList = _register["CITYLIST"]
	local index = _ai:RandomRange( 1, #cityList, "Attack Proposal city" )
	local city = cityList[index]

	local corpsList = _register["CORPSLIST"]
	local index = _ai:RandomRange( 1, #corpsList, "Attack Proposal corps" )
	local corps = corpsList[index]

	_chara:SubmitProposal( { type = CharacterProposal.EXPEDITION, targetCity = city, targetCorps = corps, chara = _chara } )
end

local CharacterAI_AttackProposal =
{
	type = "SEQUENCE", desc = "ATTACK", children =
	{
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "IDLE_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "ACTION", action = AttackProposal },
	}
}
local CharacterAI_ExpeditionProposal =
{
	type = "SEQUENCE", desc = "Expedition", children =
	{
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "ADJACENT_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "EQUALS", datamem = "CITYLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "IDLE_CORPSLIST", memname = "CORPSLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CORPSLIST", number = 0 } },
		{ type = "FILTER", condition = MemoryCityData, params = { dataname = "REACHABLE_BELLIGERENT_CITYLIST", memname = "CITYLIST" } },
		{ type = "FILTER", condition = CompareCityData, params = { compare = "MORE_THAN", datamem = "CITYLIST", number = 0 } },
		{ type = "ACTION", action = ExpeditionProposal },
	}
}
				
local CharacterAI_MilitaryProposal =
{
	type = "SEQUENCE", desc = "START Military proposal", children =
	{
		{ type = "FILTER", condition = HaveJobPriviage, params = { affair = "MILITARY_AFFAIRS" } },
		{ type = "FILTER", condition = CheckInstruction, params = { flow = "MILITARY" } },		
		{ type = "RANDOM_SELECTOR", desc = "START Military proposal", children =
			{
				CharacterAI_AttackProposal,
				CharacterAI_ExpeditionProposal,
			}
		}
	}
}

---------------------------------------------

local function SelectMeetingProposal()	
	if NeedRecruit( _chara:GetLocation() ) and IsCityInDanger( _chara:GetLocation() ) and CanRecruit( _chara:GetLocation() ) then
		_chara:SubmitProposal( { type = CharacterProposal.AI_SUBMIT_PROPOSAL, chara = _chara } )
		return
	end
	--print( #_blackboard, _chara.stamina )
	if _chara.stamina > CharacterParams.STAMINA["ACCEPT_PROPOSAL"] and #_blackboard > 0 then
		for k, proposal in ipairs( _blackboard ) do
			if proposal.type == CharacterProposal.RECRUIT_TROOP then
				--InputUtility_Pause( "Pripority recruit" )
				_chara:SubmitProposal( { type = CharacterProposal.AI_SELECT_PROPOSAL, proposal = proposal, chara = _chara } )
				return
			end
		end
		--select proposal
		if  _ai:GetRandom( "Select meeting topic" ) <= RandomParams.MAX_PROBABILITY + ( _chara.stamina - CharacterParams.STAMINA["ACCEPT_PROPOSAL"] ) * RandomParams.PROBABILITY_UNIT then
			local index = _ai:RandomRange( 1, #_blackboard, "Select proposal" )
			_chara:SubmitProposal( { type = CharacterProposal.AI_SELECT_PROPOSAL, proposal = _blackboard[index], chara = _chara } )
			return
		end		
	end
	if _chara.stamina > CharacterParams.STAMINA["SUBMIT_PROPOSAL"] then
		--InputUtility_Pause( "ai submit proposal himself" )
		_chara:SubmitProposal( { type = CharacterProposal.AI_SUBMIT_PROPOSAL, chara = _chara } )
		return
	end
	--InputUtility_Pause( "ai next topic" )
	_chara:SubmitProposal( { type = CharacterProposal.NEXT_TOPIC, chara = _chara } )
end

local CharacterAI_AISelectProposal =
{
	type = "SELECTOR", desc = "START select proposal", children =
	{
		{ type = "ACTION", desc = "execute", action = SelectMeetingProposal },
	}
}

---------------------------------------------

local function CanSubmitProposal()
	return _chara:CanSubmitProposal()
end

local CharacterAI_AISubmitProposal =
{
	type = "SEQUENCE", desc = "Start submit proposal", children =
	{
		{ type = "FILTER", condition = CanSubmitProposal },
		{ type = "SELECTOR", desc = "", children =		
			{
				CharacterAI_WarPreparednessProposal,				
				CharacterAI_TechProposal,
				CharacterAI_DiplomacyProposal,
				CharacterAI_CityAffaisProposal,
				CharacterAI_HumanResourceProposal,
				CharacterAI_MilitaryProposal,
			}
		},
	}
}

---------------------------------------------

local OfficerDiscussProposal =
{
	type = "SELECTOR", desc = "", children =
	{
		CharacterAI_TechProposal,
		CharacterAI_WarPreparednessProposal,
		CharacterAI_HumanResourceProposal,
		CharacterAI_CityAffaisProposal,
		CharacterAI_DiplomacyProposal,
		CharacterAI_MilitaryProposal,
	},
}

local DiplomaticDiscussProposal =
{
	type = "SELECTOR", desc = "", children =
	{
		CharacterAI_DiplomacyProposal,
		CharacterAI_WarPreparednessProposal,
		CharacterAI_TechProposal,		
		CharacterAI_HumanResourceProposal,
		CharacterAI_CityAffaisProposal,		
		CharacterAI_MilitaryProposal,
	},
}

local GeneralDiscussProposal = 
{
	type = "SELECTOR", desc = "", children =
	{
		CharacterAI_WarPreparednessProposal,
		CharacterAI_MilitaryProposal,
		CharacterAI_TechProposal,
		CharacterAI_CityAffaisProposal,
		CharacterAI_DiplomacyProposal,
		CharacterAI_HumanResourceProposal,
	},
}

local CharacterAI_GroupDiscussProposal =
{
	type = "SEQUENCE", desc = "Start submit proposal", children =
	{
		{ type = "FILTER", condition = CanSubmitProposal },
		{ type = "SELECTOR", children = 
			{
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
						{ type = "FILTER", condition = IsCharaOfficer },
						OfficerDiscussProposal,
					}
				},				
				{ type = "SELECTOR", desc = "", children =
					{
						CharacterAI_WarPreparednessProposal,
						CharacterAI_TechProposal,
						CharacterAI_DiplomacyProposal,
						CharacterAI_CityAffaisProposal,
						CharacterAI_HumanResourceProposal,
						CharacterAI_MilitaryProposal,
					},
				}
			}
		}
	}
}

local CharacterAI_CityDiscussProposal =
{
	type = "SEQUENCE", desc = "Start submit proposal", children =
	{
		{ type = "FILTER", condition = CanSubmitProposal },
		{ type = "RANDOM_SELECTOR", desc = "", children =
			{
				CharacterAI_WarPreparednessProposal,
				CharacterAI_CityAffaisProposal,
				CharacterAI_HumanResourceProposal,
				CharacterAI_MilitaryProposal,
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
	self.cityDevelopProposal:BuildTree( CharacterAI_CityAffaisProposal )
	self.cityHRProposal= BehaviorNode()
	self.cityHRProposal:BuildTree( CharacterAI_HumanResourceProposal )
	self.warPreparednessProposal = BehaviorNode()
	self.warPreparednessProposal:BuildTree( CharacterAI_WarPreparednessProposal )
	self.militaryProposal = BehaviorNode()
	self.militaryProposal:BuildTree( CharacterAI_MilitaryProposal )
	self.diplomacyProposal= BehaviorNode()
	self.diplomacyProposal:BuildTree( CharacterAI_DiplomacyProposal )

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
	--print( "Blackboard=", name, _blackboard[name] )
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
	return self:RandomRange( 1, RandomParams.MAX_PROBABILITY, desc )
end

function CharacterAI:RandomRange( min, max, desc )
	if desc then Debug_Log( "Generate Random: " .. desc ) end
	if self.randomizer then return self.randomizer:GetInt( min, max ) end
	return math.random( min, max )
end
