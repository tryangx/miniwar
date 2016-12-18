require 'unclasslib'

--[[
	Creation Method
	
	1. Random ALTITUDE in several tiles
	
	2. Fill SEA with ALTITUDE
	
	3. Fill Mountain with 
--]]

MapCreatorType = 
{
	SINGLE_CONTINENT,
	
	ISOLATE_CONTINENT,
	
	SERVERAL_CONTINENT,
	
	ARCHIPELAGO,
}

MapCreatorContinentTrait =
{
	
}

MapCreatorWeatherTrait =
{
	HOT,
	
	WARM,
	
	COLD,
}

MapCreatorRainfall =
{
	
}

MapCreatorParam = class()

function MapCreatorParam:__init()
	self.seed = 0
	
	--base
	self.type = MapCreatorType.SINGLE_CONTINENT
	
	--Tile count
	self.GridWidth  = 25
	self.GridHeight = 25
	self.GridNumber = self.GridWidth * self.GridHeight

	--determine mountain spawn point
	--range: 0~100
	self.MountainMinAltitude = 90
		
	--determine sea spawn point
	--range: 0~100
	self.SeaLevelMaxAltitude = 10

	--determine desert, grassland, forest->jungle->swamp
	--range: 0~100
	--self.Rainfall = 50
	self.DesertMinRainfall = 10
	self.GrasslandMinRainfall = 30
	self.ForestMinRainfall = 70
	
	--temperature
	self.temperatureNorthPole = 0
	self.temperatureEquator   = 100
	self.temperatureSouthPole = 0
	self.temperatureRandomizeRange = 6
	--determine forest->jungle, ice->frozen ground, 
	--range: 0~100
		
	self.FrozenMaxTemperature = 10
	self.IceMaxTemperature = 25
	self.JungleMinTemperature = 60
	self.DesertMinTemperature = 50
	self.OasisMaxTemperature = 55
			
	--Terrain Ratio
	self.terrainRatios = {
		10, --sea
		50,	--plain
		30, --hill
		10, --mountain
	}
	self.terrainTotalRatio = 0
	for i,v in ipairs( self.terrainRatios ) do
		self.terrainTotalRatio = self.terrainTotalRatio + v
	end
	
	self.ArchitectureNumbers = {
		{ name = "village", min = 5, max = 6 },
		{ name = "town",    min = 3, max = 4 },
		{ name = "city",    min = 1, max = 2 },
	}
	
	self.ArchitectureRoadNumberLimit = 3
	self.ArchitectureRoadLengthLimit = math.max( self.GridWidth, self.GridHeight )
end

function MapCreatorParam:SetSeed( seed )
	self.seed = seed
end

function MapCreatorParam:GetTerrainLimit( terrain )
	assert( terrain <= MapAreaTerrain.STANDARD_TERRAIN_END, "Only standard terrain has a limit number" )
	return math.floor( self.terrainRatios[terrain] * self.GridNumber / self.terrainTotalRatio )
end

--[[
function MapCreatorParam:GetTerrainRate( terrain )
	return self.terrainRatios[terrain]
end
function MapCreatorParam:AddTerrain( terrain )
	self.terrainNumbers[terrain] = self.terrainNumbers[terrain] + 1
end
function MapCreatorParam:CanAddTerrain( terrain )
	if self.terrainNumbers[terrain] < self:GetTerrainLimitNumber( terrain ) then return true end
	return false
end
]]