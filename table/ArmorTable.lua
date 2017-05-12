ArmorTable = class()

function ArmorTable:Load( data )
	self.id   = data.id or 0
	
	self.name = data.name or ""
	
	self.type = data.type and ArmorType[data.type] or ArmorType.NONE
	
	self.part = data.part and ArmorPart[data.part] or ArmorPart.BODY
	
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