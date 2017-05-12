PlotType = 
{
	NONE     = 0,
	LAND     = 1,
	HILLS    = 2,
	MOUNTAIN = 3,
	WATER    = 4,
	
	LIVING   = 10,
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
	ALL         = -1,
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

PlotResourceBonusType =
{
	NONE              = 0,
	LIVING_SPACE      = 1,	
	AGRICULTURE       = 10,
	ECONOMY           = 11,
	PRODUCTION        = 12,	
	FOOD_OUTPUT       = 20,
	PRODUCTION_OUTPUT = 21,
	MONEY_OUTPUT      = 22,
	SCIENCE_OUTPUT    = 23,
	CULTURE_OUTPUT    = 24,
	FAITH_OUTPUT      = 25,
	SUPPLY_FOOD       = 30,
	SUPPLY_MODULUS    = 31,
	MOVE_PENALTY      = 50,
}

PlotTraits = 
{
	[1] = { { type = "AGRICULTURE", value = 150 }, { type = "ECONOMY", value = 0 }, { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 1000 }, },--LAND	
	[2] = { { type = "AGRICULTURE", value = 50 },  { type = "ECONOMY", value = 0 }, { type = "PRODUCTION", value = 100 }, { type = "LIVING_SPACE", value = 100 }, },--HILLS	
	[3] = { { type = "AGRICULTURE", value = 0 },   { type = "ECONOMY", value = 0 }, { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--MOUNTAIN	
	[4] = { { type = "AGRICULTURE", value = 0 },   { type = "ECONOMY", value = 0 }, { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--WATER
}

PlotTerrainTraits =
{
	[1] = { { type = "AGRICULTURE", value = 150 }, { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 100 }, { type = "LIVING_SPACE", value = 0 }, },--PLAINS
	[2] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--GRASSLAND	
	[3] = { { type = "AGRICULTURE", value = 0 },   { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--DESERT	
	[4] = { { type = "AGRICULTURE", value = 50 },  { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 100 }, { type = "LIVING_SPACE", value = 0 }, },--TUNDRA	
	[5] = { { type = "AGRICULTURE", value = 0 },   { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--SNOW	
	[6] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMY", value = 50 },  { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--LAKE	
	[7] = { { type = "AGRICULTURE", value = 150 }, { type = "ECONOMY", value = 100 }, { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--COAST	
	[8] = { { type = "AGRICULTURE", value = 150 }, { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--OCEAN
}

PlotFeatureTratis = 
{
	[1] = { { type = "AGRICULTURE", value = 0 },   { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 100 }, { type = "LIVING_SPACE", value = 0 }, },--WOODS	
	[2] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--RAIN_FOREST	
	[3] = { { type = "AGRICULTURE", value = 100 }, { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--MARSH	
	[4] = { { type = "AGRICULTURE", value = 200 }, { type = "ECONOMY", value = 100 }, { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--OASIS	
	[5] = { { type = "AGRICULTURE", value = 300 }, { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--FLOOD_PLAIN	
	[6] = { { type = "AGRICULTURE", value = 0 },   { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--ICE	
	[7] = { { type = "AGRICULTURE", value = 0 },   { type = "ECONOMY", value = 0 },   { type = "PRODUCTION", value = 0 },   { type = "LIVING_SPACE", value = 0 }, },--FALLOUT
}

PlotTable = class()

function PlotTable:Load( data )
	self.id   = data.id or 0
		
	self.type     = PlotType[data.type] or PlotType.LAND	
	self.terrain  = PlotTerrainType[data.terrain] or PlotTerrainType.PLAINS	
	self.feature  = PlotFeatureType[data.feature] or PlotFeatureType.NONE
	
	self.name     = ( data.type or "" ) .. "_" .. ( ( data.feature and data.feature ~= "NONE" ) and data.feature or "" ) .. "_" .. ( data.terrain or "" ) 
	
	self.traits = MathUtility_Copy( data.traits )
	
	function CheckTrait( trait ) return trait.value > 0 end	
	--add plots
	self.traits = MathUtility_Merge( self.traits, PlotTraits[self.type], CheckTrait )
	--Add terrain traits
	self.traits = MathUtility_Merge( self.traits, PlotTerrainTraits[self.terrain], CheckTrait )
	--Add feature traits
	self.traits = MathUtility_Merge( self.traits, PlotFeatureTratis[self.feature], CheckTrait )
end

function PlotTable:GetBonusValue( bonusType )
	return Helper_SumIf( self.traits, "type", bonusType, "value", PlotResourceBonusType )
end

function PlotTable:GetType()
	return self.type
end

function PlotTable:GetTerrain()
	return self.terrain
end

function PlotTable:GetFeature()
	return self.feature
end