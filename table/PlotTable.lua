PlotType = 
{
	NONE     = 0,
	LAND     = 1,
	HILLS    = 2,
	MOUNTAIN = 3,
	WATER    = 4,
}

PlotTerrainType =
{
	NONE      = 0,
	PLAINS    = 1,
	GRASSLAND = 2,	
	DESERT    = 3,
	TUNDRA    = 4,
	SNOW      = 5,
	LAKE      = 6,
	COAST     = 7,
	OCEAN     = 8,
}

PlotFeatureType = 
{
	NONE        = 0,
	WOODS       = 1,
	RAIN_FOREST = 2,
	MARSH       = 3,
	OASIS       = 4,
	FLOOD_PLAIN = 5,
	ICE         = 6,
	FALLOUT     = 7,
}

PlotAddition = 
{
	NONE      = 0,
	RIVER     = 1,
	CLIFFS    = 2,
}

PlotTraitType =
{
	NONE              = 0,
	
	AGRICULTURE       = 10,
	ECONOMIC          = 11,
	PRODUCTION        = 12,
	
	FOOD_OUTPUT       = 20,
	PRODUCTION_OUTPUT = 21,
	MONEY_OUTPUT      = 22,
	SCIENCE_OUTPUT    = 23,
	CULTURE_OUTPUT    = 24,
	FAITH_OUTPUT      = 25,
	
	POPULATION_LIMIT  = 30,
	POPULATION_INIT   = 31,
	
	MOVE_PENALTY      = 50,
}

PlotTraits = 
{
	--LAND
	[1] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 5 }, { type = "POPULATION_INIT", value = 0 }, },
	--HILLS
	[2] = { { type = "AGRICULTURE", value = 0 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 100 }, { type = "POPULATION_LIMIT", value = 1 }, { type = "POPULATION_INIT", value = 0 }, },
	--MOUNTAIN
	[3] = { { type = "AGRICULTURE", value = 0 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--WATER
	[4] = { { type = "AGRICULTURE", value = 0 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
}

PlotTerrainTraits =
{
	--PLAINS
	[1] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 100 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--GRASSLAND
	[2] = { { type = "AGRICULTURE", value = 200 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--DESERT
	[3] = { { type = "AGRICULTURE", value = 0 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--TUNDRA
	[4] = { { type = "AGRICULTURE", value = 50 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 100 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--SNOW
	[5] = { { type = "AGRICULTURE", value = 0 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--LAKE
	[6] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMIC", value = 50 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--COAST
	[7] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMIC", value = 100 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--OCEAN
	[8] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
}

PlotFeatureTratis = 
{
	--WOODS
	[1] = { { type = "AGRICULTURE", value = 0 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 100 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--RAIN_FOREST
	[2] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--MARSH
	[3] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--OASIS
	[4] = { { type = "AGRICULTURE", value = 200 }, { type = "ECONOMIC", value = 100 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--FLOOD_PLAIN
	[5] = { { type = "AGRICULTURE", value = 300 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--ICE
	[6] = { { type = "AGRICULTURE", value = 0 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
	--FALLOUT
	[7] = { { type = "AGRICULTURE", value = 0 }, { type = "ECONOMIC", value = 0 }, { type = "PRODUCTION", value = 0 }, { type = "POPULATION_LIMIT", value = 0 }, { type = "POPULATION_INIT", value = 0 }, },
}

PlotTable = class()

function PlotTable:Load( data )
	self.id   = data.id or 0
		
	self.type     = PlotType[data.type] or PlotType.LAND	
	self.terrain  = PlotTerrainType[data.terrain] or PlotTerrainType.PLAINS	
	self.feature  = PlotFeatureType[data.feature] or PlotFeatureType.NONE
	
	self.name     = ( data.feature or "" ) .. "_" .. ( data.terrain or "" ) .. "_" .. ( data.type or "" )
	
	self.traits = MathUtility_Copy( data.traits )
	
	function CheckTrait( trait ) return trait.value > 0 end	
	--add plots
	self.traits = MathUtility_Merge( self.traits, PlotTraits[self.type], CheckTrait )
	--Add terrain traits
	self.traits = MathUtility_Merge( self.traits, PlotTerrainTraits[self.terrain], CheckTrait )
	--Add feature traits
	self.traits = MathUtility_Merge( self.traits, PlotFeatureTratis[self.feature], CheckTrait )
end

function PlotTable:GetTraitValue( plotTraitType )
	local number = 0
	for k, trait in ipairs( self.traits ) do
		if PlotTraitType[trait.type] == plotTraitType then
			number = number + trait.value
		end
	end
	return number
end