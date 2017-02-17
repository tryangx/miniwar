--------------------------
-- Condition Function

local function CheckGameTurn( params )
	local turn = params.turn
	return g_game.turn == turn
end

--------------------------
-- Action Function

local function CharacterAppear( chara )
	chara.status = CharacterStatus.OUT
end

local function AllCityRecruitImmediate( params )
	local id = params.id
	local troop = g_troopTableMng:GetData( id )	
	if troop then
		g_cityDataMng:Foreach( function ( city )
			city:PrepareRecruit( troop.maxNumber * GroupParams.RECRUIT.NUMBER_STANDARD_MODULUS )
			CityRecruitTroop( city, troop )
		end )
	end
end

-------------------------

local Event_100 = 
{
	type = "SEQUENCE",
	desc = "new game",
	children = 
	{
		{ type = "FILTER", condition = CheckGameTurn, params = { turn = 1 } },
		{ type = "ACTION", action = AllCityRecruitImmediate, params = { id = 500 } },
	},
}
local All_Event = 
{
	type = "SELECTOR", children = 
	{
		--Event_100,
	},
}

-------------------------

GameEvent = class()

function GameEvent:__init()
	self.bhvTree = BehaviorNode()	
	self.bhv     = Behavior()
end

function GameEvent:InitData()
	self.bhvTree:BuildTree( All_Event )
end

function GameEvent:Trigger()	
	self.bhv:Run( self.bhvTree )
end