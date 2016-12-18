local CityTableData = 
{
	[10] = 
	{
		id   = 10,
		name = "Red Capital",
		
		population = 10000,
		
		agriculture    = 100,
		maxAgriculture = 300,
		
		economy        = 100,
		maxEconomy     = 200,
		
		production     = 100,
		maxProduction  = 250,
		
		cultureCircle = 0,
		
		security = 80,
		
		traits = {},
		
		charas = { 1 },
		
		troops = {},	
				
		constructions = {},
		
		resources = {},
		
		adjacentCities = { 11 },
	},
	[11] = 
	{
		id   = 11,
		name = "Red City",
		
		population = 10000,
		
		agriculture    = 100,
		maxAgriculture = 300,
		
		economy        = 100,
		maxEconomy     = 200,
		
		production     = 100,
		maxProduction  = 250,
		
		cultureCircle = 0,
		
		security = 80,
		
		traits = {},
		
		charas = {},
		
		troops = {},	
				
		constructions = {},
		
		resources = {},
		
		adjacentCities = { 10, 21 },
	},
	
	[20] = 
	{
		id   = 20,
		name = "Blue Capital",
		
		population = 10000,
		
		agriculture    = 100,
		maxAgriculture = 300,
		
		economy        = 100,
		maxEconomy     = 200,
		
		production     = 100,
		maxProduction  = 250,
		
		cultureCircle = 0,
		
		security = 80,
		
		traits = {},
		
		charas = { 2 },
		
		troops = {},	
				
		constructions = {},
		
		resources = {},
		
		adjacentCities = { 21 },
	},
	
	[21] = 
	{
		id   = 21,
		name = "Blue City",
		
		population = 10000,
		
		agriculture    = 100,
		maxAgriculture = 300,
		
		economy        = 100,
		maxEconomy     = 200,
		
		production     = 100,
		maxProduction  = 250,
		
		cultureCircle = 0,
		
		security = 80,
		
		traits = {},
		
		charas = {},
		
		troops = {},	
				
		constructions = {},
		
		resources = {},
		
		adjacentCities = { 11, 20 },
	},
}

function Scenario_Demo_City_TableData()
	return CityTableData
end