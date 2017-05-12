WeaponTable = class()

function WeaponTable:Load( data )
	self.id   = data.id or 0
	
	self.name = data.name or ""
	
	self.damageType = data.damageType and WeaponDamageType[data.damageType]
	
	self.ballistic = data.ballistic and WeaponBallistic[data.ballistic]
	
	self.range  = data.range or 0
	
	self.weight = data.weight or 0
		
	self.power  = data.power or 0
	
	--require traiging
	self.skill  = data.skill or 0
	
	self.limit  = data.limit or 0
	
	-- unit minutes
	self.cd     = data.cd or 0	
end

function WeaponTable:IsFireWeapon()
	return self.ballistic == WeaponBallistic.SHOOT or self.ballistic == WeaponBallistic.MISSILE
end

function WeaponTable:IsMissileWeapon()
	return self.ballistic == WeaponBallistic.MISSILE
end

function WeaponTable:IsLongWeapon()
	if self.damageType ~= WeaponDamageType.NORMAL and self.damageType ~= WeaponDamageType.PIERCE then return false end
	return self.ballistic == WeaponBallistic.LONG
end

function WeaponTable:IsCloseWeapon()
	if self.damageType ~= WeaponDamageType.NORMAL and self.damageType ~= WeaponDamageType.PIERCE then return false end
	return self.ballistic == WeaponBallistic.CLOSE or self.ballistic == WeaponBallistic.MELEE or self.ballistic == WeaponBallistic.CHARGE
end

function WeaponTable:IsChargeWeapon()
	if self.damageType ~= WeaponDamageType.NORMAL and self.damageType ~= WeaponDamageType.PIERCE then return false end
	return self.ballistic == WeaponBallistic.CHARGE
end

function WeaponTable:IsSiegeWeapon()
	if self.damageType ~= WeaponDamageType.SIEGE then return false end
	return self.ballistic == WeaponBallistic.CLOSE or self.ballistic == WeaponBallistic.MISSILE
end