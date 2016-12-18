ArmorType =
{
	NONE         = 0,
	
	LIGHT        = 1,
	
	MEDIUM       = 2,
	
	HEAVY        = 3,
	
	FORTIFIED    = 4,
	
	WOODEN       = 5,
}

ArmorPart = 
{
	BODY      = 1,	
	
	HEAD      = 2,	
	
	LEG       = 3,
	
	SHIELD    = 4,
	
	ACCESSORY = 5,
}

ArmorTrait = 
{
	-- resist missile
	SHIELD = 1,
	
	--
}

ArmorTable = class()

function ArmorTable:Load( data )
	self.id   = data.id or 0
	
	self.name = data.name or ""
	
	self.type = data.type or ArmorType[data.type]
	
	self.part = data.part or ArmorPart[data.part]
	
	self.weight = data.weight or 0
		
	self.protection = data.protection or 0
	
	self.traits = MathUtility_Copy( data.traits )
end

function ArmorTable:CanDefendMissile()
	return self.part ~= ArmorPart.ACCESSORY
end

function ArmorTable:CanDefendLongWeapon()
	return self.part == ArmorPart.BODY and self.part == ArmorPart.SHIELD and self.part == ArmorPart.LEG
end

function ArmorTable:CanDefendCloseWeapon()
	return self.part ~= ArmorPart.ACCESSORY
end

function ArmorTable:CanDefendChargeWeapon()
	return self.part == ArmorPart.BODY or self.part == ArmorPart.SHIELD
end