WeaponDamageType = 
{
	-- Normal damage type
	NORMAL       = 1,	
	-- Spear or some like it
	PIERCE       = 2,	
	-- Advanced to defence
	SIEGE        = 3,
		
	--FIRE         = 4,
}

WeaponBallistic =
{
	-- Siege weapon
	CLOSE      = 1,	
	-- Normal weapon like sword, knife, fork
	MELEE      = 2,
	-- Only use in charge attack
	CHARGE     = 3,	
	-- Anti charge attack
	LONG       = 4,	
	-- CrossBow or rifle
	SHOOT      = 5,	
	-- Bow or high ballistic
	MISSILE    = 6,
}

WeaponParams =
{
	LONG_RANGE_WEAPON_LENGTH = 20,
	LONG_WEAPON_LENGTH       = 4,
}

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
	--print( "is fire weapon",self.name, self.range )
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