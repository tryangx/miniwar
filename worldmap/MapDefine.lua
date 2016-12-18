
MapTerrain = {
	
}


MapAreaTerrain = {
	INVALID   = 0,
	BEGIN     = 1,
	STANDARD_TERRAIN_END = 4,
	
	--[[		
		plain    - grassland, forest, jungle, swamp, icefield, desert, wasteland,
		hill     - mountain-forest		
		sea      - ocean, lake
		mountain -
	]]
	
	SEA             = 1,
	PLAIN           = 2,
	HILL            = 3,
	MOUNTAIN        = 4,
	
	GRASSLAND       = 100,
	FOREST          = 101,
	JUNGLE          = 102,	
	SWAMP           = 103,
	DESERT          = 104,	
	ICE             = 105,
	FROZEN_GROUND   = 106,
	OASIS           = 107,
	FLOOD_PLAIN     = 108,
	WASTELAND       = 109,	
	
	MOUNTAIN_FOREST = 200,
	
	LAKE            = 301,
	OCEAN           = 302,	
	
	--to add
	
	END       = 12,
}

MapAreaArchitecture = {
	VILLAGE   = 1,
	TOWN      = 2,
	CITY      = 3,
	CAMP      = 10,
	FORTRESS  = 11,
}

MAP_AREA_ID_BEGIN = 100