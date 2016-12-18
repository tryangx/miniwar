ResourceCategory = 
{
	NONE      = 0,
	STRATEGIC = 1,	
	BONUS     = 2,
	LUXURY    = 3,
	NATURAL   = 4,
}

ResourceBonus =
{
	SUPPLY_FOOD    = 1,
	SUPPLY_MODULUS = 2,
}

ResourceTable = class()

function ResourceTable:Load( data )
	self.id   = data.id or 0	
	self.name = data.name or 0
	self.category = ResourceCategory[data.category] or ResourceCategory.NONE
	self.bonuses = MathUtility_Copy( data.bonuses )
end