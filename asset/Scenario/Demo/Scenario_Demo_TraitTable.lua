local TraitTableData = 
{
	[1000] = 
	{
		name = "Butcher",		
		category = "COMBAT",		
		effects =
		{
			{ effect="DAMAGE_ADDITION", value=20 },
			{ effect="NIGHT_ATTACK", value=30 },
			{ effect="BLUFF", value=30 },
		},
	},
	
	[1001] = 
	{
		name = "Protector",		
		category = "COMBAT",		
		effects =
		{
			{ effect="DAMAGE_REDUCTION", value=25 },			
			{ effect="GUARDIAN_FRIENDLY", value=35, prob=5000 },
		},
	},
	
	[1010] = 
	{
		name = "Footman Master",		
		category = "COMBAT",		
		effects =
		{
			{ effect="TROOP_MASTER", value=20, cond="FOOTSOLDIER" },
			{ effect="TROOP_RESIST", value=20, cond="FOOTSOLDIER" },
		},
	},
		
	[1020] = 
	{
		name = "Attack Master",		
		category = "COMBAT",		
		effects =
		{
			{ effect="DAMAGE_ADDITION", value=20 },
			{ effect="SKILL_MASTER",    value=50 },			
		},
	},
	
	[1030] = 
	{
		name = "LIGHTING",		
		category = "COMBAT",		
		effects =
		{
			{ effect="MOVEMENT_ADDITION",  value=20 },
			{ effect="STAMINA_MASTER",     value=50 },			
		},
	},
	
	[1040] = 
	{
		name = "COMMANDER",		
		category = "COMBAT",		
		effects =
		{
			{ effect="MORALE_ADDITION",    value=20 },
			{ effect="MOVEMENT_REDUCTION", value=50 },
			{ effect="ENCOURAGE_MORALE",   value=0.3 },
		},
	},
	
	[300] = 
	{
		name = "FORTIFIED",		
		category = "COMBAT",		
		effects = 
		{
			{ effect="GUARDIAN_FORTIFIED", value=40, range=40, prob=9000 },
		},
	},
	
	[310] =
	{
		name = "SIEGE_ATTACK",
		category = "COMBAT",		
		effects =
		{
			{ effect="SIEGE_ATTACK", value=100 },		
		},
	},
	
	[3000] = 
	{
		name = "SENIOR DIPLOMATIC",
		category = "DIPLOMATIC",
		effects = 
		{
			{ effect="DIPLOMACY_SUCCESS_PROB", value=1 },			
			{ effect="DIPLOMACY_FRIENDLY_BONUS", value=100 },			
		},
	}
}

function Scenario_Demo_Trait_TableData()
	return TraitTableData
end