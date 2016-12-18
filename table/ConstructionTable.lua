ConstructionTrait = 
{
	NONE      = 0,
	
	--able to be capital
	CAPITAL   = 1,
	
	--
	SUPPLY    = 2,
	
	--able to recruit
	MILITARY  = 3,
		
	ECONOMY   = 4,
	
	CULTRUE   = 5,
}

ConstructionTable = class()

function ConstructionTable:Load( data )

	self.id = data.id or 0
	
	self.name = data.name or ""
	
	self.desc = data.desc or ""
	
	self.points = data.points or 0
	
	self.prerequisites = MathUtility_Copy( data.prerequisites )
end