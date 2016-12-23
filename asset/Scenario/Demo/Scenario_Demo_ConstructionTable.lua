local ConstructionTableData = 
{
	[1] =
	{
		id = 1,		
		name = "palace",
		maintenance = 1000,
		desc = "First construction",				
		prerequisites = { points = 100 },
	},
	
	[2] =
	{
		id = 2,		
		name = "barrack",		
		desc = "Military Construct",
		maintenance = 100,
		prerequisites = { points = 100 },
	},
	
	[3] =
	{
		id = 3,		
		name = "farm",		
		desc = "",
		maintenance = 100,
		prerequisites = { points = 100 },
	},
}

function Scenario_Demo_Construction_TableData()
	return ConstructionTableData
end