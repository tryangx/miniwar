local BattlefieldTableData = 
{
	[1] = 
	{
		id       = 1,
		name     = "grassland",
		time     = 2,
		width    = 1000,
		column   = 5,
		distance = 100,
		terrains =
		{
			"PLAIN",		
		}
	},
	
	[2] = 
	{
		id       = 2,
		name     = "forest",
		time     = 3,
		width    = 300,
		column   = 3,
		distance = 80,
		terrains =
		{
			"PLAIN",
			"FOREST",
		}
	},
	
	[3] = 
	{
		id       = 3,
		name     = "city",
		time     = 4,		
		width    = 600,
		column   = 5,
		distance = 100,
		terrains =
		{
			"PLAIN",
			"FORTRESS",
			"CITY",
		}
	},
}

function Scenario_Demo_Battlefield_TableData()
	return BattlefieldTableData
end