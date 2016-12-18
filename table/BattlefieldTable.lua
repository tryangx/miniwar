BattlefieldTerrain = 
{
	PLAIN    = 1,
	
	FOREST   = 2,
	
	RIVER    = 3,
	
	VALLEY   = 4,
	
	FORTRESS = 5,
	
	TOWN     = 6,
	
	CITY     = 7,
}

BattlefieldTable = class()

function BattlefieldTable:Load( data )
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	-- determine how long the combat occured after dawn
	self.time = data.time or 0
	
	-- determine how many soldiers works in the troop
	self.width = data.width or 1000
	
	-- determine how many troop in a row
	self.column = data.column or 5
	
	-- determine how much time two 
	self.distance = data.distance or 0	

	self.terrains = MathUtility_Copy( data.terrains )
end