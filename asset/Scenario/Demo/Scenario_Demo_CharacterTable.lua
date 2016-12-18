local CharacterTableData =
{
	[1] = 
	{
		id  = 1,
		name = "Zhang Fei",
		
		ca          = 60,
		pa          = 80,
		
		maxAP       = 90,
		
		talent      = 80,
		
		personality = 0,
		
		purpose     = 0,
		
		traits = { 1000, 1030 },
	},
	
	[2] = 
	{
		id  = 2,
		name = "Yue Fei",
		
		ca          = 50,
		pa          = 90,
		
		maxAP       = 85,
		
		talent      = 90,
		
		personality = 0,
		
		purpose     = 0,
		
		traits = { 1001, 1010, 1040 },
	},
}

function Scenario_Demo_Character_TableData()
	return CharacterTableData
end