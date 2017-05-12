--[[
	Weapon Mod = [ Weapon.Power - Weapon.Weight * 0.5, Weapon.Power ]
	Armor Mod = Armor.Protection
]]
local WeaponTableData = 
{
	--100~199 Melee weapon
	[100]   = { name = "Dagger", damageType = "NORMAL", power = 35, range = 8, weight = 12, ballistic = "MELEE", cd = 50, },
	--[101]   = { name = "Bronze Sword", damageType = "NORMAL", power = 25, range = 5, weight = 2, ballistic = "MELEE", cd = 45, },
	--[102]   = { name = "Gladius", damageType = "NORMAL", power = 27, range = 4, weight = 3, ballistic = "MELEE", cd = 45, },

	--[110]   = { name = "Rapier", damageType = "PIERCE", power = 27, range = 8, weight = 2, ballistic = "MELEE", cd = 45, },
	--[111]   = { name = "Estoc", damageType = "PIERCE", power = 45, range = 8, weight = 1, ballistic = "MELEE", cd = 45, },

	[120]   = { name = "Sword", damageType = "NORMAL", power = 50, range = 10, weight = 18, ballistic = "MELEE", cd = 50 },
	--[121]   = { name = "Broardsword", damageType = "NORMAL", power = 50, range = 16, weight = 4, ballistic = "MELEE", cd = 40 },
	--[122]   = { name = "Long Sword", damageType = "NORMAL", power = 50, range = 18, weight = 4, ballistic = "MELEE", cd = 40 },	
	--[124]   = { name = "Two-handed Sword", damageType = "NORMAL", power = 36, range = 12, weight = 5, ballistic = "MELEE", cd = 40 },		

	--[130]   = { name = "Falchion", damageType = "NORMAL", power = 28, range = 8, weight = 3, ballistic = "MELEE", cd = 40 },

	--[140]   = { name = "Katana", damageType = "NORMAL", power = 28, range = 9, weight = 3, ballistic = "MELEE", cd = 40 },
	
	[190]   = { name = "Fork", damageType = "NORMAL", power = 30, range = 15, weight = 20, ballistic = "MELEE", cd = 50, },
	

	---------------------------
	--200~299 Long weapon			
	[200]  = { name = "Spear", damageType = "NORMAL", power = 75, range = 30, weight = 20, ballistic = "LONG", cd = 80,	},
	--[201]  = { name = "Pike", damageType = "NORMAL", power = 27, range = 10, weight = 6, ballistic = "LONG", cd = 60, },
	[202]  = { name = "Lance", damageType = "NORMAL", power = 150, range = 20, weight = 20, ballistic = "CHARGE", cd = 100, },
	--[203]  = { name = "Halberd", damageType = "NORMAL", power = 32, range = 20, weight = 20, ballistic = "MELEE", cd = 60, },

	--300~399 Missile weapon
	--[[
	[300]  = { name = "Short Bow", damageType = "PIERCE", power = 24, range = 20, weight = 6, ballistic = "MISSILE", cd = 30, },
	[301]  = { name = "Bow", damageType = "PIERCE", power = 26, range = 90, weight = 6, ballistic = "MISSILE", cd = 70, },	
	[302]  = { name = "Longbow", damageType = "PIERCE", power = 28, range = 120, weight = 6, ballistic = "MISSILE", cd = 60, },
	[303]  = { name = "Crossbow", damageType = "PIERCE", power = 30, range = 15, weight = 8, ballistic = "MISSILE", cd = 60, },	
	[304]  = { name = "Stone", damageType = "NORMAL", power = 22, range = 10, weight = 2, ballistic = "MISSILE", cd = 45,	},
	[305]  = { name = "Javelin", damageType = "PIERCE", power = 25, range = 15, weight = 10, ballistic = "MISSILE", cd = 45,	},

	--400+ Siege weapon	
	[400] = { name = "Tower Archer", damageType = "PIERCE", power = 24, range = 100, weight = 4, ballistic = "MISSILE", cd = 60, },
	[401] = { name = "Battering Ram", damageType = "SIEGE", power = 40, range = 10, weight = 10, ballistic = "CLOSE", cd = 60, },	
	[402] = { name = "Huge Rock", damageType = "SIEGE", power = 60, range = 350, weight = 40, ballistic = "MISSILE", cd = 90, },	
	]]
}

function Scenario_Demo_Weapon_TableData()
	return WeaponTableData
end

local ArmorTableData = 
{
	--Body	
	[100] = { name = "Cloth", type = "LIGHT", part  = "BODY", weight = 10, protection = 20, },	
	[101] = { name = "Leather armor", type = "MEDIUM", part  = "BODY", weight = 35, protection = 40, },
	[102] = { name = "Plate armor", type = "HEAVY", part  = "BODY",	weight = 65, protection = 85, },

	--Head
	--[[
	[200] = { name = "Scarf", type = "LIGHT", part  = "HEAD", weight = 1, protection = 18, },
	[201] = { name = "Helmet", type = "MEDIUM", part  = "HEAD", weight = 3, protection = 21, },	
	]]
	
	--Sheild
	[300] = { name = "Wooden Shield", type = "WOODEN", part  = "SHIELD", weight = 25, protection = 30, traits = { SHIELD, } },
	[301] = { name = "Shield", type = "MEDIUM", part = "SHIELD", weight = 45, protection = 55, traits = { SHIELD, } },
		
	--Siege Armor
	--[[
	[1000] = { name = "Battering Ram Armor", type = "WOODEN", part = "BODY", weight = 10, protection = 150, },	
	[1001] = { name = "Trebuchet Armor", type = "WOODEN", part = "BODY", weight = 15, protection = 100, },

	--Fortified
	[2000] = { name = "Stone gate", type = "FORTIFIED", part = "BODY", weight = 0, protection = 50, },	
	[2001] = { name = "Iron gate", type = "FORTIFIED", part = "BODY", weight = 0, protection = 50, },
	]]
}

function Scenario_Demo_Armor_TableData()
	return ArmorTableData
end