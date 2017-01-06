-----------------------------------
--
-- Season Table
--
-----------------------------------

local SeasonTableData = 
{
	[1] = 
	{
		id       = 1,
		name     = "spring",
		type     = "SPRING",
		dawnTime = 6,
		duskTime = 18,
		startMon = 3,		
		startDay = 1,
		endMon   = 5,
		endDay   = 30,
		nextSeason = "SUMMER",
	},
	
	[2] = 
	{
		id       = 2,
		name     = "summer",
		type     = "SUMMER",
		dawnTime = 5,
		duskTime = 19,
		startMon = 6,		
		startDay = 1,
		endMon   = 8,
		endDay   = 30,
		nextSeason = "AUTUMN",
	},
	
	[3] = 
	{
		id       = 3,
		name     = "autumn",
		type     = "AUTUMN",
		dawnTime = 6,
		duskTime = 18,
		startMon = 9,		
		startDay = 1,
		endMon   = 11,
		endDay   = 30,
		nextSeason = "WINTER",
	},
	
	[4] = 
	{
		id       = 4,
		name     = "winter",
		type     = "WINTER",
		dawnTime = 7,
		duskTime = 17,
		startMon = 12,		
		startDay = 1,
		endMon   = 2,
		endDay   = 30,
		nextType = "SPRING",
	},
}

function Standard_Season_TableData()
	return SeasonTableData
end

-----------------------------------
--
-- WeatherTableData
--
-----------------------------------
local WeatherTableData = 
{
	[1] =
	{
		id   = 1,
		name = "Sunny",		
		type = "SUNNY",
		movePenalty    = 0,
		damagePenalty  = 0,
		missilePenalty = 0,
	},
	
	[2] =
	{
		id   = 2,
		name = "cloudy",		
		type = "CLOUDY",
		movePenalty    = 0,
		meleePenalty   = 0,
		missilePenalty = 0,
	},
	
	[3] =
	{
		id   = 3,
		name = "rainy",		
		type = "RAINY",
		movePenalty    = 30,
		meleePenalty   = 30,
		missilePenalty = 30,
	},
	
	[4] =
	{
		id   = 4,
		name = "snow",		
		type = "SNOW",
		movePenalty    = 50,
		meleePenalty   = 25,
		missilePenalty = 0,
	},
	
	[5] =
	{
		id   = 5,
		name = "foggy",		
		type = "FOGGY",
		movePenalty    = 25,
		meleePenalty   = 30,
		missilePenalty = 50,
	},
	
	[6] =
	{
		id   = 6,
		name = "storm",		
		type = "STORM",
		movePenalty    = 40,
		meleePenalty   = 40,
		missilePenalty = 40,
	},
	
	[7] =
	{
		id   = 7,
		name = "blizzard",		
		type = "BLIZZARD",
		movePenalty    = 80,
		meleePenalty   = 80,
		missilePenalty = 80,
	},
	
	[8] =
	{
		id   = 8,
		name = "dust_storm",		
		type = "DUST_STORM",
		movePenalty    = 80,
		meleePenalty   = 80,
		missilePenalty = 80,
	},
}

function Standard_Weather_TableData()
	return WeatherTableData
end


-----------------------------------
--
-- Climate Table
--
-----------------------------------
local ClimateTableData =
{
	[1] =
	{
		id = 1,
		name = "test_spring",
		weatherAlterProb = 20,
		weatherDurationMin = 6,
		weatherDurationMax = 12,
		weathers =
		{
			--      sunny, cloudy, rainy, snow, foggy, storm, blizzard, dust_storm
			[1] = { 5500,   2500,   1500,  200,  100,   100,      100,     0 },		--sunny
			[2] = { 5000,   3000,   1000,  100,  500,   200,      200,     0 },		--cloudy
			[3] = { 3000,   3000,   3000,  100,  500,   200,      200,     0 },		--rainy
			[4] = { 4000,   2500,    500, 2500,  300,     0,      200,     0 },		--snow
			[5] = { 5500,   2500,    500,  100, 1000,   200,      200,     0 },		--foggy
			[6] = { 3000,   2500,   2500,  100,  100,  1300,      500,     0 },		--storm
			[7] = { 1500,   1500,   1000, 3000,  200,   200,     2600,     0 },		--blizzard
			[8] = { 4500,   2500,    500,  100,  500,   200,      200,  1500 },		--dust_storm
		},
		weatherIds =
		{
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 4,
			[5] = 5,
			[6] = 6,
			[7] = 7,
			[8] = 8,
		},
	},
	
	[2] =
	{
		id = 2,
		name = "test_summer",
		weatherAlterProb = 30,
		weatherDurationMin = 2,
		weatherDurationMax = 8,
		weathers =
		{
			--      sunny, cloudy, rainy, snow, foggy, storm, blizzard, dust_storm
			[1] = { 5500,   2500,   1500,  200,  100,   100,      100,     0 },		--sunny
			[2] = { 5000,   3000,   1000,  100,  500,   200,      200,     0 },		--cloudy
			[3] = { 3000,   3000,   3000,  100,  500,   200,      200,     0 },		--rainy
			[4] = { 4000,   2500,    500, 2500,  300,     0,      200,     0 },		--snow
			[5] = { 5500,   2500,    500,  100, 1000,   200,      200,     0 },		--foggy
			[6] = { 3000,   2500,   2500,  100,  100,  1300,      500,     0 },		--storm
			[7] = { 1500,   1500,   1000, 3000,  200,   200,     2600,     0 },		--blizzard
			[8] = { 4500,   2500,    500,  100,  500,   200,      200,  1500 },		--dust_storm
		},
		weatherIds =
		{
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 4,
			[5] = 5,
			[6] = 6,
			[7] = 7,
			[8] = 8,
		},
	},
	
	[3] =
	{
		id = 3,
		name = "test_autumn",
		weatherDurationMin = 4,
		weatherDurationMax = 8,
		weathers =
		{
			--      sunny, cloudy, rainy, snow, foggy, storm, blizzard, dust_storm
			[1] = { 5500,   2500,   1500,  200,  100,   100,      100,     0 },		--sunny
			[2] = { 5000,   3000,   1000,  100,  500,   200,      200,     0 },		--cloudy
			[3] = { 3000,   3000,   3000,  100,  500,   200,      200,     0 },		--rainy
			[4] = { 4000,   2500,    500, 2500,  300,     0,      200,     0 },		--snow
			[5] = { 5500,   2500,    500,  100, 1000,   200,      200,     0 },		--foggy
			[6] = { 3000,   2500,   2500,  100,  100,  1300,      500,     0 },		--storm
			[7] = { 1500,   1500,   1000, 3000,  200,   200,     2600,     0 },		--blizzard
			[8] = { 4500,   2500,    500,  100,  500,   200,      200,  1500 },		--dust_storm
		},
		weatherIds =
		{
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 4,
			[5] = 5,
			[6] = 6,
			[7] = 7,
			[8] = 8,
		},
	},
	
	[4] =
	{
		id = 4,
		name = "test_winter",
		weatherDurationMin = 6,
		weatherDurationMax = 10,
		weathers =
		{
			--      sunny, cloudy, rainy, snow, foggy, storm, blizzard, dust_storm
			[1] = { 5500,   2500,   1500,  200,  100,   100,      100,     0 },		--sunny
			[2] = { 5000,   3000,   1000,  100,  500,   200,      200,     0 },		--cloudy
			[3] = { 3000,   3000,   3000,  100,  500,   200,      200,     0 },		--rainy
			[4] = { 4000,   2500,    500, 2500,  300,     0,      200,     0 },		--snow
			[5] = { 5500,   2500,    500,  100, 1000,   200,      200,     0 },		--foggy
			[6] = { 3000,   2500,   2500,  100,  100,  1300,      500,     0 },		--storm
			[7] = { 1500,   1500,   1000, 3000,  200,   200,     2600,     0 },		--blizzard
			[8] = { 4500,   2500,    500,  100,  500,   200,      200,  1500 },		--dust_storm
		},
		weatherIds =
		{
			[1] = 1,
			[2] = 2,
			[3] = 3,
			[4] = 4,
			[5] = 5,
			[6] = 6,
			[7] = 7,
			[8] = 8,
		},
	},
}

function Standard_Climate_TableData()
	return ClimateTableData
end

-----------------------------------
--
-- Calendar Table
--
-----------------------------------
local CalendarTableData =
{
	[1] = 30,
	[2] = 30,
	[3] = 30,
	[4] = 30,
	[5] = 30,
	[6] = 30,
	[7] = 30,
	[8] = 30,
	[9] = 30,
	[10] = 30,
	[11] = 30,
	[12] = 30,
}

function Standard_Calendar_TableData()
	return CalendarTableData
end

-----------------------------------
--
-- Resource Table
--
-----------------------------------

local ResourceType = 
{
	--Strategic
	COPPER         = 100,
	IRON           = 101,
	HORSE          = 102,
	NITER          = 110,
	COAL           = 120,
	OIL            = 130,
	ALUMINUM       = 140,
	URANIUM        = 150,
	
	--Bonus	
	RICE           = 200,
	WHEAT          = 201,
	CORN           = 202,
	POTATO         = 203,
	SALT           = 204,
	FRUITS         = 205,
	
	POULTRY        = 210,
	PIG            = 211,
	CATTLE         = 212,	
	SHEEP          = 213,
	DEER           = 214,
	FISH           = 215,	
	SHRIMP         = 216,
	
	CLAY           = 220,
	STONE          = 221,	
	
	--Luxury
	SILVER         = 300,
	GOLD           = 301,
	PLATINUM       = 302,

	JADE           = 310,
	DIAMOND        = 311,
	MARBLE         = 312,
	
	IVORY          = 320,
	PEARLS         = 321,
	WHALE          = 322,
	
	FURS           = 330,
	DYES           = 331,
	SILK           = 332,
	
	SUGAR          = 340,
	WINE           = 341,
	LIQUOR         = 342, 
	TEA            = 343,
	TOBACCO        = 344,
	COFFEE         = 345,
	
	SPICES         = 350,
	INCENSE        = 351,
	
	MECURY         = 360,	
	
	--Natural	
}

local ResourceTableData = 
{
	--Strategic Resource
	[100] = 
	{
		name="Copper", category="STRATEGIC", bonuses={ { type="ECONOMY", value=50 }, { type="PRODUCTION", value=50 }, }, 
		conditions={ 
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="HILLS" },
					{ type="PLOT_TERRAIN_TYPE_EXCEPT", value="SNOW" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},	
		}
	},
	[101] = 
	{
		name="Iron", category="STRATEGIC", bonuses={ { type="ECONOMY", value=50 }, { type="PRODUCTION", value=100 }, }, 
		conditions={
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="HILLS" },
					{ type="PLOT_TERRAIN_TYPE_EXCEPT", value="SNOW" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},	
		}
	},
	[110] = { name="Aluminum", category="STRATEGIC" },
	[111] = { name="Uranium", category="STRATEGIC" },
	
	[120] = 
	{
		name="Horse", category="STRATEGIC", bonuses={ { type="ECONOMY", value=50 }, },
		conditions={ 
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LAND" },
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LAND" },
					{ type="PLOT_TERRAIN_TYPE", value="GRASSLAND" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},	
		}
	},
	[130] = { name="Niter", category="STRATEGIC" },
	[140] = { name="Coal", category="STRATEGIC" },
	[141] = { name="Oil", category="STRATEGIC" },
	[142] = { name="Gas", category="STRATEGIC" },
	
	--Bonus Resource
	[200] = 
	{
		name="RICE", category="BONUS", bonuses={ { type="SUPPLY_FOOD", value=200 }, }, 
		conditions={ 
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE", value="MARSH" },
				}
			},
		}
	},
	[201] = 
	{
		name="WHEAT", category="BONUS", bonuses={ { type="SUPPLY_FOOD", value=150 }, }, 
		conditions={ 
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TERRAIN_TYPE", value="DESERT" },
					{ type="PLOT_FEATURE_TYPE", value="FLOOD_PLAIN" },
				}
			},			
		}		
	},
	[202] = { name="CORN", category="BONUS", bonuses={ { type="SUPPLY_FOOD", value=200 } }, },
	[203] = { name="POTATO", category="BONUS", bonuses={ { type="SUPPLY_FOOD", value=200 }, }, },
	[204] = { name="FRUITS", category="BONUS", bonuses={ { type="SUPPLY_FOOD", value=50 }, { type="SUPPLY_MODULUS", value=1.2 }, }, },
	[205] =
	{
		name="SALT", category="BONUS", bonuses={ { type="SUPPLY_MODULUS", value=1.4 }, },
		conditions={
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TERRAIN_TYPE_EXCEPT", value="GRASSLAND" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
			--[[
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LAND" },
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
					{ type="NEAR_PLOT_TYPE", value="WATER" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="HILLS" },
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LAND" },
					{ type="PLOT_TERRAIN_TYPE", value="DESERT" },
					{ type="NEAR_FEATURE_TYPE", value="OASIS" },
				}
			},
			]]
		}
	},
	[206] = 
	{
		name="FERTILE", category="BONUS", bonuses={ { type="SUPPLY_MODULUS", value=1.8 }, },
		conditions={ 
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LAND" },
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
					{ type="AWAY_FROM_TERRAIN_TYPE", value="DESERT" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LAND" },
					{ type="PLOT_TERRAIN_TYPE", value="GRASSLAND" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
					{ type="AWAY_FROM_TERRAIN_TYPE", value="DESERT" },
				}
			},
		}
	},
	[207] =
	{
		name="INFERTILE", category="BONUS", bonuses={ { type="SUPPLY_MODULUS", value=0.6 }, },
		conditions={ 
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LAND" },
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
					{ type="NEAR_TERRAIN_TYPE", value="DESERT" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LAND" },
					{ type="PLOT_TERRAIN_TYPE", value="GRASSLAND" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
					{ type="NEAR_TERRAIN_TYPE", value="DESERT" },
				}
			},
		}
	},
	
	--Luxury Resource
	[300] = 
	{
		name="SILVER", category="LUXURY", bonuses={ { type="ECONOMY", value=200 }, }, 
		conditions={
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LIVING" },
					{ type="PLOT_TERRAIN_TYPE", value="DESERT" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LIVING" },
					{ type="PLOT_TERRAIN_TYPE", value="TUNDRA" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
		}
	},
	[301] = 
	{
		name="GOLD", category="LUXURY", bonuses={ { type="ECONOMY", value=500 }, }, 
		conditions={
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LIVING" },
					{ type="PLOT_TERRAIN_TYPE", value="DESERT" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LIVING" },
					{ type="PLOT_TERRAIN_TYPE", value="TUNDRA" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
		}
	},
	
	[400] = { name="Everest", category="NATURAL", },
	
	--Artificial Resource
	[500] =
	{
		name="Settlement", cateogory="ARTIFICIAL", bonuses={ { type="LIVING_SPACE", value=100 }, },
		conditions={
			{ type="CONDITION_BRANCH", value=
				{
					{ type="PLOT_TYPE", value="LIVING" },
					{ type="PLOT_TERRAIN_TYPE", value="PLAINS" },
					{ type="PLOT_FEATURE_TYPE_EXCEPT", value="ALL" },
				}
			},
		}
	},
}

function Standard_Resource_TableData()
	return ResourceTableData
end


-----------------------------------
--
-- Plot Table
--
-----------------------------------

local PlotTableData =
{
	--Land
	[1000] = 
	{
		type    = "LAND",
		terrain = "PLAINS",
		feature = "NONE",
		tratis  = {},
	},	
	[1100] = 
	{
		type    = "LAND",
		terrain = "GRASSLAND",
		feature = "NONE",
		tratis  = {},
	},	
	[1200] = 
	{
		type    = "LAND",
		terrain = "DESERT",
		feature = "NONE",
		tratis  = {},
	},	
	[1300] = 
	{
		type    = "LAND",
		terrain = "TUNDRA",
		feature = "NONE",
		tratis  = {},
	},	
	[1400] = 
	{
		type    = "LAND",
		terrain = "SNOW",
		feature = "NONE",
		tratis  = {},
	},
	
	--Hills
	[2000] = 
	{
		type    = "HILLS",
		terrain = "PLAINS",
		feature = "NONE",
		tratis  = {},
	},	
	[2100] = 
	{
		type    = "HILLS",
		terrain = "GRASSLAND",
		feature = "NONE",
		tratis  = {},
	},	
	[2200] = 
	{
		type    = "HILLS",
		terrain = "DESERT",
		feature = "NONE",
		tratis  = {},
	},	
	[2300] = 
	{
		type    = "HILLS",
		terrain = "TUNDRA",
		feature = "NONE",
		tratis  = {},
	},
	[2400] = 
	{
		type    = "HILLS",
		terrain = "SNOW",
		feature = "NONE",
		tratis  = {},
	},	
	
	--Mountains
	[3000] = 
	{
		type    = "MOUNTAIN",
		terrain = "PLAINS",
		feature = "NONE",
		tratis  = {},
	},	
	[3100] = 
	{
		type    = "MOUNTAIN",
		terrain = "GRASSLAND",
		feature = "NONE",
		tratis  = {},
	},	
	[3200] = 
	{
		type    = "MOUNTAIN",
		terrain = "DESERT",
		feature = "NONE",
		tratis  = {},
	},
	[3300] = 
	{
		type    = "MOUNTAIN",
		terrain = "TUNDRA",
		feature = "NONE",
		tratis  = {},
	},	
	[3400] = 
	{
		type    = "MOUNTAIN",
		terrain = "SNOW",
		feature = "NONE",
		tratis  = {},
	},
	
	--Water
	[4000] = 
	{
		type    = "WATER",
		terrain = "LAKE",
		feature = "NONE",
		tratis  = {},
	},
	[4100] = 
	{
		type    = "WATER",
		terrain = "COAST",
		feature = "NONE",
		tratis  = {},
	},
	[4200] = 
	{
		type    = "WATER",
		terrain = "OCEAN",
		feature = "NONE",
		tratis  = {},
	},
}

function Standard_Plot_TableData()
	return PlotTableData
end