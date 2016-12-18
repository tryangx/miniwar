local ConstructionTableData = 
{
	[1] =
	{
		id = 1,
		
		name = "palace",
		
		desc = "First construction",
		
		points = 1000,
		
		prerequisites = {},
	},
	
	[2] =
	{
		id = 2,
		
		name = "barrack",
		
		desc = "Military Construct",
		
		points = 1,

		prerequisites = {},
	},
	
	[3] =
	{
		id = 3,
		
		name = "farm",
		
		desc = "",
		
		points = 1,

		prerequisites = {},
	},
}

function Scenario_Demo_Construction_TableData()
	return ConstructionTableData
end