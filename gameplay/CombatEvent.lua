CombatEventTriggerCondition =
{
	SPECIFIED_PHASE      = 100,

	PROBABILITY          = 101,
	
	HAS_TRAIT            = 110,
}

CombatEventLimit = 
{
	TOTAL_TIMES          = 1,
	
	DELAY_TIMES          = 2,
	
	SIDE_TIMES           = 3,
}

-------------------------------
-- Global interface

CombatEventEnviroment = 
{
	RANDOMIZER      = 1,

	COMBAT_POINTER  = 2,
	
	TROOP_POINTER   = 3,
}

--------------------------------

CombatEventTrigger = class()

function CombatEventTrigger:__init()
	self.bhvTree = BehaviorNode()	
	self.bhv     = Behavior()
end

function CombatEventTrigger:InitData()
	self.bhvTree:BuildTree( Standard_CombatEvents )
end

function CombatEventTrigger:Trigger()		
	return self.bhv:Run( self.bhvTree )
end

function CombatEventTrigger:SetCombatEventEnviroment( type, data )
	SetCombatEventEnviroment( type, data )
end

function CombatEventTrigger:UpdateCombatEventTime( elapsedTime )
	UpdateCombatEventTime( elapsedTime )
end