--[[
	Group AI Design

	Group 
	
	in generally, group has five different ways to promotion the power.
	
	economic, political, diplomatic, military, technological 
	
	
--]]


--------------------------------
-- Local variables

local _group  = nil
local _ai     = nil
local _target = nil

local function AIDebug( content )
	Debug_Log( content )
end

--------------------------------
-- Group Research
-- 
--------------------------------
local function NeedResearch()
	if _group.researchTechId ~= 0 then return false end
	local availableTechs = {}
	g_techTableMng:Foreach( function ( tech )
		if MathUtility_IndexOf( _group.techs, tech.id, "id" ) then return end
		if tech.prerequisites then
			for k, id in pairs( tech.prerequisite ) do
				if not MathUtility_IndexOf( _group.techs, id ) then return end
			end
		end			
		table.insert( availableTechs, tech )
	end )
	--Debug_Log( "Available tech", #availableTechs )
	if #availableTechs <= 0 then return false end
	
	--simply select random technique now
	--There should be a recommended research path
	_target = availableTechs[_ai:RandomRange( 1, #availableTechs, "Research Shuffle" )]
	--Debug_Log( "Tech ", _target, #availableTechs )
	
	_args = { tech = _target }

	return true
end

local function DoResearch()
	Order_Issue( _group, OrderType.RESEARCH, _args )
end

--------------------------------
-- Invest
--------------------------------
local function NeedInvest()
	local cityList = {}
	for k, city in ipairs(_group.cities) do
		--prerequisite
		if city:CanInvest() and _group.money >= Parameter.CITY_INVEST_MONEY[city.size] + Parameter.CITY_INVEST_MONEY[city.size] then
			local prob1 = ( city.maxEconomy - city.economy ) * 5000 / city.maxEconomy
			local prob2 = ( city.maxProduction - city.production ) * 5000 / city.maxProduction
			local prob3 = ( city.maxAgriculture - city.agriculture ) * 5000 / city.maxAgriculture
			local prob = math.max( prob1, prob2, prob3 )
			--print( "invest add", prob )
			if _ai:GetRandom( "Invest Prob" ) < prob then
				table.insert( cityList, city )
			end
		end
	end
	local cityNum = #cityList
	if cityNum <= 0 then return false end
	
	_target = cityList[_ai:RandomRange( 1, cityNum, "Invest City" )]
	
	_args = { city = _target }
	
	return true
end

local function DoInvest()
	Order_Issue( _group, OrderType.INVEST, _args )
end

--------------------------------
-- Recruit
--------------------------------
local function NeedRecruit()
	--check battlefront
	local cityList = {}
	local idleCityList = {}
	local safetyMilitaryPower = 0
	for k, city in ipairs(_group.cities) do
		if city:CanRecruit() then
			if city:IsInConflict() then
				table.insert( cityList, city )
			end			
			table.insert( idleCityList, city )
			safetyMilitaryPower = safetyMilitaryPower + Parameter.SAFETY_CITY_MILITARY_POWER[city.size]
		end
	end
	
	if #cityList > 0 then
		_target = cityList[_ai:RandomRange( 1, #cityList, "Recruit Shuffle" )]
		_args = { city = _target }
		
		return true
	end

	local idleCityNum = #idleCityList
	if idleCityNum <= 0 then
		AIDebug( "No city is idle for recruiting" )
		return false
	end

	-- We should consider about aggressive lord in further
	if _group._militaryPower > safetyMilitaryPower then
		AIDebug( "Enough power " .. _group._militaryPower .. "," .. safetyMilitaryPower )
		return false
	end

	local ratio = ( safetyMilitaryPower - _group._militaryPower ) * 10000 / safetyMilitaryPower
	if _ai:GetRandom( "Recruit Prob" ) < ratio then
		_target = idleCityList[_ai:RandomRange( 1, idleCityNum, "Recruit City" )]
		_args = { city = _target }		
		
		return true
	end
	
	return false
end

local function DoRecruit()
	Order_Issue( _group, OrderType.RECRUIT, _args )
end

--------------------------------
-- Build
--------------------------------
local function NeedBuild()
	--city is ready for building
	local cityList = {}
	for k, city in ipairs(_group.cities) do
		if city:CanBuild() then
			local buildList = city:GetBuildList()
			if #buildList > 0 then
				--MathUtility_Dump( buildList )
				table.insert( cityList, city )
			end
		end
	end
	
	if #cityList <= 0 then return false end	
	_target = cityList[_ai:RandomRange( 1, #cityList, "Build City" )]	
	
	_args = { city = _target }	
	
	return true
end

local function DoBuild()
	Order_Issue( _group, OrderType.BUILD, _args )
end

--------------------------------
-- Tax
--------------------------------
local function NeedTax()
	--Low money
	local cityNum = #_group.cities
	if _group.money < cityNum * 1000 then
		if _ai:GetRandom( "Check Tax" ) > 4500 then return false end
	elseif _group.money < cityNum * 2500 then
		if _ai:GetRandom( "Check Tax" ) > 2000 then return false end
	end
	
	local cityList = {}
	for k, city in ipairs(_group.cities) do
		if not city:IsInConflict() then
			table.insert( cityList, city )
		end
	end
	
	if #cityList <= 0 then return false end	
	_target = cityList[_ai:RandomRange( 1, #cityList, "Tax City" )]	
	
	_args = { city = _target }
	
	return true
end

local function DoTax()	
	Order_Issue( _group, OrderType.TAX, _args )
end

--------------------------------
-- Attack
--------------------------------
local function NeedAttack()	
	-------------------------
	-- Find idle corps ( version 1.0 )
	-- 1. Corps is idle
	-- 2. Corps is not too tired
	-- 
	local corpsList = {}
	for k, corps in ipairs(_group.corps) do
		if Order_IsWaitingOrder( corps ) and corps:GetMedianFatigue() / ValueRange.MAX_FATIGUE < Parameter.CORPS_FATIGUE_CAUTION_RATIO then
			--print( "Corps", corps.id, corps:GetPower(), corps.name )
			MathUtility_Insert( corpsList, { corps = corps, power = corps:GetPower() }, "power" )
		end
	end
	
	print( "NeedAttack--Corps=", #corpsList )
	if #corpsList <= 0 then return false end
	
	--find enemy
	local relations = {}
	for k, relation in ipairs(_group.relations) do		
		if relation.type >= GroupRelationType.NEUTRAL then
			--MathUtility_Dump( relation )
			table.insert( relations, { id = relation.tid, type = relation.type, value = relation:GetHostilityEvaluation() } )
		end
	end
	
	print( "NeedAttack--Relation=", #relations )
	if #relations <= 0 then return false end
	
	table.sort( relations, function( left, right )
		return left.value > right.value or left.type > right.type
	end	)
	
	--find adjacent city in battlefront	
	local cityList = {}
	local targetGroup = relation[1]:GetOppGroup( _group.id )
	for k, city in ipairs( targetGroup.cities ) do
		if city:IsInConflict() or city:IsAdjacentGroup( _group ) then
			table.insert( cityList, city )
		end
	end
		
	print( "NeedAttack--City=", #cityList )
		
	local cityNum = #cityList
	if cityNum <= 0 then return false end
	
	--simply random
	_target = cityList[_ai:RandomRange( 1, cityNum, "Check Attack" )]
	
	local corps = corpsList[_ai:RandomRange( 1, #corpsList, "Check Attack" )].corps
	
	--print( "Corps", corps.id, corps.name )
		
	--simply send the single corps
	_args = { city = _target, corps = corps }	
	
	return true
end

local function DoAttack()
	Order_Issue( _group, OrderType.ATTACK, _args )
end


--------------------------------
-- Dispatch Chara

local function NeedDispatchChara()
	local idleCharaList = {}
	for k, chara in ipairs( _group.charas ) do	
		if chara:IsStayCity( _group:GetCapital() ) then	
			table.insert( idleCharaList, chara )
		end
	end
	
	local idleCharaNum = #idleCharaList
	if idleCharaNum <= 0 then return false end
	
	local leakCharaCityList = {}
	for k, city in ipairs( _group.cities ) do
		if city ~= _group.capital and #city.charas < 1 then
			table.insert( leakCharaCityList, city )
		end
	end
	
	local leakCharaCityNum = #leakCharaCityList
	if leakCharaCityNum <= 0 then return false end	
	
	local charaNum     = #_group.charas
	
	if idleCharaNum + Parameter.MIN_CHARA_IN_CAPITAL >= #_group.charas or idleCharaNum * Parameter.MIN_CHARA_IN_CAPITAL_PERCENT > charaNum then
		if _ai:GetRandom() > 8000 then return false end
	end
	
	local charaIndex = _ai:RandomRange( 1, idleCharaNum, "Check Dispatch" )
	local cityIndex  = _ai:RandomRange( 1, #leakCharaCityList, "Check Dispatch" )
	
	_target = idleCharaList[charaIndex]
	
	_args = { chara = _target, city = leakCharaCityList[cityIndex] }
	
	return true
end

local function DoDispatchChara()
	Order_Issue( _group, OrderType.DISPATCH_CHARA, _args )
end

--------------------------------
-- Establish corps

local function NeedEstablishCorps()	
	--find chara leak city
	local cityList = {}
	for k, city in ipairs(_group.cities) do
		if city:IsBorder() and city:HasNoCorpsTroop() then
			table.insert( cityList, city )
		end
	end
		
	local cityNum = #cityList	
	if cityNum == 0 then return false end
		
	_target = cityList[_ai:RandomRange( 1, cityNum, "Establish Corps" )]	
	
	_args = { city = _target }
	
	return true
end

local function DoEstablishCorps()
	Order_Issue( _group, OrderType.ESTABLISH_CORPS, _args )
end

--------------------------------
-- Lead Troop

local function NeedLeadTroop()
	--idle chara & idle troop
	local idleCharaList = {}
	for k, chara in ipairs( _group.charas ) do
		if not chara:IsLeadTroop() then
			table.insert( idleCharaList, chara )
		end
	end
	if #idleCharaList <= 0 then return false end
	
	local idleTroopList = {}
	for k, troop in ipairs( _group.troops ) do
		if not troop:GetLeader() then
			table.insert( idleTroopList, troop )
		end
	end
	if #idleTroopList <= 0 then return false end
	
	local charaIndex = _ai:RandomRange( 1, #idleCharaList, "Check Lead Troop" )
	local troopIndex = _ai:RandomRange( 1, #idleTroopList, "Check Lead Troop" )
	
	_target = idleCharaList[charaIndex]
	
	_args = { chara = _target, troop = idleTroopList[troopIndex] }
	
	return true
end

local function DoLeadTroop()
	Order_Issue( _group, OrderType.LEAD_TROOP, _args )
end

--------------------------------

local function DoRest()
	Order_Issue( _group, OrderType.REST, _args )
end

--------------------------------

local g_groupAI_Normal = 
{
	type = "SELECTOR", desc = "START", children = 
	{
		--{ type = "RANDOM_SELECTOR", desc = "Random", children = 
		{ type = "SELECTOR", desc = "test", children = 
			{			
			--	{ type = "CONDITION_ACTION", desc = "Research", condition = NeedResearch, action = DoResearch },	
				
			--	{ type = "CONDITION_ACTION", desc = "Build", condition = NeedBuild, action = DoBuild },
				
			--	{ type = "CONDITION_ACTION", desc = "Invest", condition = NeedInvest, action = DoInvest },
				
			--	{ type = "CONDITION_ACTION", desc = "Tax", condition = NeedTax, action = DoTax },				
				
				{ type = "CONDITION_ACTION", desc = "Recruit", condition = NeedRecruit, action = DoRecruit },				
				
				{ type = "CONDITION_ACTION", desc = "Establish corps", condition = NeedEstablishCorps, action = DoEstablishCorps },
				
				{ type = "CONDITION_ACTION", desc = "Attack", condition = NeedAttack, action = DoAttack },
				
			--	{ type = "CONDITION_ACTION", desc = "Dispatch", condition = NeedDispatchChara, action = DoDispatchChara },
				
			--	{ type = "CONDITION_ACTION", desc = "LeadTroop", condition = NeedLeadTroop, action = DoLeadTroop },
			}
		},
		{ type = "ACTION", desc = "REST", action = DoRest },
	},	
}

g_groupAI = class()


function g_groupAI:SetActor( actor )	
	_group = actor
end

function g_groupAI:SetRandomizer( randomizer )
	self.randomizer = randomizer
end

function g_groupAI:Run()
	self.behavior:Run( self.behaviorTree )
end

function g_groupAI:GetRandom( desc )
	return self:RandomRange( 1, RandomParams.MAX_PROBABILITY, desc )
end

function g_groupAI:RandomRange( min, max, desc )
	--if desc then Debug_Log( "Generate Random: " .. desc ) end
	if self.randomizer then return self.randomizer:GetInt( min, max ) end	
	return math.random( min, max )
end

function g_groupAI:__init()
	self.behaviorTree = BehaviorNode()
	self.behaviorTree:BuildTree( g_groupAI_Normal )
	self.behavior = Behavior()
	
	_ai    = self
end

-------------------------------------------
--[[
function g_groupAI:UpdateGroup()
	--research
	if _group.researchTechId ~= 0 then
		if _group.researchPoints < _group.researchAbility then
			--finished
			table.insert( _group.techs, _group.researchTechId )
			_group.researchPoints = 0
			_group.researchTechId = 0
			
			tech = g_techTableMng:GetData( _group.researchTechId )
			reporter.AddReport( _group.id, "[" .. _group.name .. "] finished technique [" .. tech.name .. "]" )
		else
			_group.researchPoints = _group.researchPoints - _group.researchAbility
		end
	end
end
]]

---------------------------------------------
-- Different Government AI
---------------------------------------------

-- Region
local g_groupAI_Region = 
{
	type = "SELECTOR", desc = "START", children =
	{
		{ type = "RANDOM_SELECTOR", desc = "Random", children = 
			{
				{ type = "CONDITION_ACTION", desc = "Recruit", condition = NeedRecruit, action = DoRecruit },
			}
		}
	}
}

local g_groupAI_Kindom = 
{
	type = "SELECTOR", desc = "START", children =
	{
		{ type = "RANDOM_SELECTOR", desc = "Random", children = 
			{
				{ type = "CONDITION_ACTION", desc = "Recruit", condition = NeedRecruit, action = DoRecruit },
			}
		}
	}
}
