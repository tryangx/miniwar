--[[
	CUT_SUPPLY_FOOD,
	
	NIGHT_ATTACK,
	
	
	BLUFF
		in field combat, threaten
	
	Lure enemy
		in siege combat, lure defender go out of city	
]]

-------------------------------
-- Global method

local DebugEvent = nil

local _behavior = nil
local _randomizer = nil

local _combat = nil
local _troop  = nil

local _eventId    = 0
local _traitValue = 0

local _triggerTimeRecords = {}
local _triggerSideFrequencyRecords = {}

function SetCombatEventEnviroment( type, data )
	if type == CombatEventEnviroment.RANDOMIZER then
		_randomizer = data
	elseif type == CombatEventEnviroment.COMBAT_POINTER then
		_combat = data
	elseif type == CombatEventEnviroment.TROOP_POINTER then
		_troop = data
	end
end

function UpdateCombatEventTime( elapsedTime )
	for k, record in pairs( _triggerTimeRecords ) do
		for k, item in pairs( record ) do
			if item.time then
				if item.time > elapsedTime then
					item.time = item.time - elapsedTime
				else
					record[k] = nil
				end
			end
		end
	end	
end

------------------------------------------

local function IsStage( params )	
	local stage = params.stage
	if DebugEvent then print( "check stage", _combat.stage, stage ) end
	return _combat.stage == CombatStage[stage]
end

local function IsPhase( params )	
	local phase = params.phase
	if DebugEvent then print( "check phase", _combat.phase, phase ) end
	return _combat.phase == CombatPhase[phase]
end

local function HasTroopData()
	return _troop ~= nil
end

local function HasTrait( params )	
	if not params then Debug_Asset( "Parameters invalid" ) return false end
	local trait = TraitEffectType[params.trait]	
	local troop = _combat:HasTraitValue( trait )
	if troop then
		_troop = troop
		if DebugEvent then print( _troop:GetNameDesc() .. " has trait=" .. trait .. "[" .. params.trait.."]" ) end
	else
		if DebugEvent then print( "no trait=" .. trait .. "[" .. params.trait.."]" ) end
	end
	return troop ~= nil
end

local function HasTroopTrait( params )
	if not params then Debug_Asset( "Parameters invalid" ) return false end
	local trait = TraitEffectType[params.trait]	
	local traitValue = _combat:GetTraitValue( _troop, trait )
	if traitValue then
		_traitValue = traitValue
		if DebugEvent then print( _troop:GetNameDesc() .. " has trait=" .. trait .. "[" .. params.trait.."]" ) end
	else
		if DebugEvent then print( _troop:GetNameDesc() .. " didn't has trait=" .. trait .. "[" .. params.trait.."]" ) end
	end
	return traitValue
end

local function CheckProbability( params )
	if not params then Debug_Asset( "Parameters invalid" ) return false end
	local prob = params.prob
	local min, max = 1, params.maxProb or 10000
	
	local value = _randomizer:GetInt( min, max )
	if prob >= value then
		if DebugEvent then print( "Probability ok", prob, value ) end
		return true
	end
	if DebugEvent then print( "Probability failed", prob, value ) end
	return false
end

local function CheckTime( params )
	local id = _eventId
	local troopId = _troop and _troop.id or 0
	local record = _triggerTimeRecords[id]
	if not record then return true end
	for k, item in pairs( record ) do
		if item.troopId == troopId and item.time > 0 then 
			if DebugEvent then print( "event exist " .. item.time ) end
			return false
		elseif item.side == _troop._combatSide and item.time > 0 then
			if DebugEvent then print( "event exist " .. item.time ) end
			return false
		end
	end
	if DebugEvent then print( "event time ok" ) end
	return true
end

local function CheckSideFrequency( params )
	local id = _eventId
	local side = _troop and _troop._combatSide or CombatSide.INVALID
	local frequency = params.frequency
	local record = _triggerSideFrequencyRecords[id]
	if not record or not record.side then
		if DebugEvent then print( "event side frequency ok" ) end
		return true
	end
	if record.side < frequency then
		if DebugEvent then print( "event side frequency ok" ) end
		return true
	end
	if DebugEvent then  print( "event occurred" ) end
	return false
end

local function RecordTime( params )
	local id = _eventId
	local troopId = _troop and _troop.id or 0
	local time = params.time
	if not _triggerTimeRecords[id] then _triggerTimeRecords[id] = {} end
	table.insert( _triggerTimeRecords[id], { troopId = troopId, time = params.time } )
end


local function RecordSideTime( params )
	local id = _eventId
	local time = params.time
	if not _triggerTimeRecords[id] then _triggerTimeRecords[id] = {} end
	table.insert( _triggerTimeRecords[id], { side = _troop._combatSide, time = params.time } )
end

local function RecordSideFrequency( params )
	local id = _eventId
	local side = _troop and _troop._combatSide or CombatSide.INVALID
	if not _triggerSideFrequencyRecords[id] then _triggerSideFrequencyRecords[id] = {} end	
	if _triggerSideFrequencyRecords[id].side then
		_triggerSideFrequencyRecords[id].side = _triggerSideFrequencyRecords[id].side + 1
	else
		_triggerSideFrequencyRecords[id].side = 1
	end
	--print( _triggerSideFrequencyRecords[id].side )
end

local function SetEventId( params )
	local id = params.id
	_eventId = id
end

-------------------------------

-- Use for encourage event
local function DoEncourageAllFriendly()
	--_combat:Log( "Trigger Encourage Event!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! " .. _traitValue )
	if not _troop then 
		print( "Invalid troop for EncourageAllFriendly()" )
	end
	_combat:EncourageSideMorale( _troop, _traitValue, "Encourage Event" )
end

local function DoShowDialogue( params )
	_combat:Log( "Trigger Encourage Event!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! " )
	local id = _eventId
	if id == 1000 then
		Debug_Log( "Listen, it's time to die" )
	end
end

local function DoNightAttack()
	_combat:Log( "!!!!!!!!!!!!!!!night attack" )
	_combat:NightAttack( _troop )
end

local function DoBluff()
	_combat:Log( "!!!!!!!!!!!!!!Bluff" )
	_combat:AddSideBuff( _troop._combatSide, CombatBuff.BLUFF )
end

-------------------------------
-- Encourage Event
local combatEvent_100 =
{
	type = "SEQUENCE",
	desc = "Encourage",
	children = 
	{
		{ type = "ACTION", desc = "Set Event id", condition = SetEventId, params = { id = 100 } },

		{ type = "FILTER", desc = "Check troop", condition = HasTroopData },
		{ type = "FILTER", desc = "Check stage", condition = IsStage, params = { stage = "FIRST_ROUND" } },		
		{ type = "FILTER", desc = "Check trigger time", condition = CheckTime },		
		{ type = "FILTER", desc = "Check trigger frequency", condition = CheckSideFrequency, params = { frequency = 3 } },	
		{ type = "FILTER", desc = "Check trait", condition = HasTroopTrait, params = { trait = "ENCOURAGE_MORALE" } },		
		{ type = "FILTER", desc = "Check probability", condition = CheckProbability, params = { prob = 10000 } },
				
		{ type = "ACTION", desc = "Execute event", action = DoEncourageAllFriendly },
		
		{ type = "ACTION", desc = "Trigger Event", action = RecordSideFrequency },		
		{ type = "ACTION", desc = "Trigger Event", action = RecordTime, params = { time = 180 } },
		{ type = "ACTION", desc = "Trigger Event", action = RecordSideTime, params = { time = 180 } },
	},
}

local combatEvent_101 =
{
	type = "SEQUENCE",
	desc = "Night Attack",
	children = 
	{
		{ type = "ACTION", desc = "Set Event id", condition = SetEventId, params = { id = 101 } },
	
		{ type = "FILTER", desc = "Check stage", condition = IsStage, params = { stage = "THINKING" } },
		{ type = "FILTER", desc = "Check phase", condition = IsPhase, params = { phase = "NIGHTFALL" } },
		{ type = "FILTER", desc = "Check trigger time", condition = CheckTime },
		{ type = "FILTER", desc = "Check trait", condition = HasTrait, params = { trait = "NIGHT_ATTACK" } },		
		{ type = "FILTER", desc = "Check probability", condition = CheckProbability, params = { prob = 10000 } },

		{ type = "ACTION", desc = "Execute event", action = DoNightAttack },
		
		{ type = "ACTION", desc = "Trigger Event", action = RecordSideFrequency },
		{ type = "ACTION", desc = "Trigger Event", action = RecordTime, params = { time = 180 } },
		{ type = "ACTION", desc = "Trigger Event", action = RecordSideTime, params = { time = 180 } },
	},
}

local combatEvent_102 =
{
	type = "SEQUENCE",
	desc = "Bluff",
	children = 
	{
		{ type = "ACTION", desc = "Set Event id", condition = SetEventId, params = { id = 102 } },
	
		{ type = "FILTER", desc = "Check stage", condition = IsStage, params = { stage = "UPDATING" } },
		{ type = "FILTER", desc = "Check phase", condition = IsPhase, params = { phase = "PREPARATION" } },
		{ type = "FILTER", desc = "Check trigger time", condition = CheckTime },
		{ type = "FILTER", desc = "Check trait", condition = HasTrait, params = { trait = "BLUFF" } },
		{ type = "FILTER", desc = "Check probability", condition = CheckProbability, params = { prob = 10000 } },

		{ type = "ACTION", desc = "Execute event", action = DoBluff },
		
		{ type = "ACTION", desc = "Trigger Event", action = RecordSideFrequency },
		{ type = "ACTION", desc = "Trigger Event", action = RecordTime, params = { time = 180 } },
		{ type = "ACTION", desc = "Trigger Event", action = RecordSideTime, params = { time = 180 } },
	},
}


-------------------------------
-- Dialogue Event
local combatEvent_1000 =
{
	type = "SEQUENCE",
	desc = "Dialogue",
	children = 
	{
		{ type = "ACTION", desc = "Set Event id", condition = SetEventId, params = { id = 1000 } },
		
		{ type = "FILTER", desc = "Check stage", condition = IsStage, params = { stage = "THINKING" } },		
		{ type = "FILTER", desc = "Check time", condition = CheckEvent },		
		{ type = "FILTER", desc = "Check side frequency", condition = CheckSideFrequency, params = { frequency = 1 } },
		{ type = "FILTER", desc = "Check prob", condition = CheckProbability, params = { prob = 10000 } },
				
		{ type = "ACTION", desc = "Execute event", action = DoShowDialogue },
		
		{ type = "ACTION", desc = "Trigger Event", action = RecordSideFrequency },		
		{ type = "ACTION", desc = "Trigger Event", action = RecordTime, params = { time = 1440 } },
	},
}

Standard_CombatEvents = 
{
	type = "RANDOM_SELECTOR", desc = "CombatEvents", children = 
	{
		--combatEvent_100,
		combatEvent_102,
		--combatEvent_1000,
	},	
}