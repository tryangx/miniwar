local TroopTableData = 
{
	[100] = 
	{
		name = "Wall",		
		category = "DEFENCE",		
		startLine = "DEFENCE",
		radius    = 1,		
		level     = 999,		
		maxNumber = 5000,		
		maxMorale = 100,		
		capacity  = 0,		
		movement  = 0,		
		supplyConsume = 0,		
		weapons   = {},
		armors    = { 100 },		
		traits    = { 300 },		
		prerequisites = { points=400, money=0, constrs = { 999 }, tech=-1, resource=0 }
	},
	[200] = 
	{
		name = "Gate",		
		category = "GATE",		
		startLine = "DEFENCE",		
		radius    = 1,		
		level     = 999,		
		maxNumber = 2000,
		maxMorale = 100,		
		capacity  = 0,		
		movement  = 0,		
		supplyConsume = 0,		
		weapons   = {},
		armors    = { 101 },		
		traits    = {},		
		prerequisites = { points=400, money=0, constrs = { 999 }, tech=1, resource=0 }
	},
	[210] = 
	{
		name = "Tower",		
		category = "TOWER",		
		startLine = "DEFENCE",		
		radius    = 1,
		level     = 999,		
		maxNumber = 500,
		maxMorale = 100,		
		capacity  = 0,		
		movement  = 0,		
		supplyConsume = 0,		
		weapons   = { 200 },
		armors    = { 101 },		
		traits    = {},
		prerequisites = { points=400, money=0, constrs = { 999 }, tech=1, resource=0 }
	},
	
	[300] = 
	{
		name = "Battering Ram",		
		category = "SIEGE_WEAPON",		
		startLine = "FRONT",		
		radius    = 5,		
		level     = 5,		
		maxNumber = 1000,		
		maxMorale = 100,		
		capacity  = 0,		
		movement  = 30,		
		supplyConsume = 40,		
		weapons   = { 300 },
		armors    = { 300 },		
		traits    = {},		
		prerequisites = { points=400, money=0, constrs = { 999 }, tech=-1, resource=0 },
	},
	
	
	[301] = 
	{
		name = "Trebuchet",		
		category = "SIEGE_WEAPON",		
		startLine = "BACK",		
		level     = 8,		
		maxNumber = 600,		
		maxMorale = 100,		
		capacity  = 0,		
		movement  = 0,		
		supplyConsume = 40,		
		weapons   = { 301 },
		armors    = { 301 },		
		traits    = {},		
		prerequisites = { points=400, money=0, constrs = { 999 }, tech=-1, resource=0 },
	},
	
	[500] = 
	{
		name = "Militia",		
		category = "Footman",		
		level     = 3,		
		maxNumber = 1000,		
		maxMorale = 80,		
		capacity  = 0,		
		movement  = 20,		
		supplyConsume = 30,		
		weapons   = { 500 },
		armors    = {},		
		traits    = {},		
		prerequisites = { points=100 },
	},
	
	[1000] = 
	{
		id   = 1000,
		name = "Footman",		
		category = "INFANTRY",		
		level     = 8,		
		maxNumber = 1000,		
		maxMorale = 100,		
		capacity  = 10,		
		movement  = 35,		
		supplyConsume = 100,		
		weapons   = { 1, 4 },
		armors    = { 2 },		
		traits    = { 310 },		
		prerequisites = { points=400, money=0, tech=0, resource=0 },
	},
	[2000] = 
	{
		id   = 2000,
		name = "Archer",		
		category = "ARTILLERY",		
		startLine = "BACK",		
		level     = 8,		
		maxNumber = 1000,
		maxMorale = 90,		
		capacity  = 20,		
		movement  = 40,		
		supplyConsume = 80,		
		weapons   = { 2, 5 },
		armors    = { 3 },		
		traits    = {},		
		prerequisites = { points=400, money=0, tech=0, resource=0 },
	},
	[3000] = 
	{
		id   = 3000,
		name = "Cavalry",		
		category = "CAVALRY",		
		startLine = "CHARGE",		
		level     = 10,		
		maxNumber = 500,
		maxMorale =	110,		
		capacity  = 40,		
		movement  = 70,		
		consume = 200,		
		weapons   = { 3, 4 },
		armors    = { 4 },		
		traits    = {},
		prerequisites = { points=400, money=0, tech=0, resource=0 },
	},
}

function Scenario_Demo_Troop_TableData()
	return TroopTableData
end