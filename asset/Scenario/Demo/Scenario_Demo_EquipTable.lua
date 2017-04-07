local WeaponTableData = 
{
	--100~199 Melee weapon
	[100]   = { name = "Dagger", damageType = "NORMAL", power = 50, ballistic = "MELEE", range = 1, weight = 3, cd = 30, },
	[101]   = { name = "Fork", damageType = "NORMAL", power = 60, ballistic = "MELEE", range = 1, weight = 4, cd = 45, },
	[102]   = { name = "Sword", damageType = "NORMAL", power = 100, ballistic = "MELEE", range = 2, weight = 6, cd = 40 },	

	--200~299 Long weapon		
	[200]  = { name = "Spear", damageType = "PIERCE", power = 110, ballistic = "LONG", range = 6, weight = 6, cd = 45,	},
	[201]  = { name = "Pike", damageType = "PIERCE", power = 160, ballistic = "LONG", range = 10, weight = 12, cd = 60, },
	[202]  = { name = "Lance", damageType = "PIERCE", power = 160, ballistic = "CHARGE", range = 4, weight = 12, cd = 90, },
	[203]  = { name = "Halberd", damageType = "NORMAL", power = 120, ballistic = "MELEE", range = 5, weight = 12, cd = 60, },

	--300~399 Missile weapon
	[300]  = { name = "Short Bow", damageType = "NORMAL", power = 35, ballistic = "MISSILE", range = 80, weight = 2, cd = 30, },
	[301]  = { name = "Bow", damageType = "PIERCE", power = 50, ballistic = "MISSILE", range = 100, weight = 5, cd = 70, },	
	[302]  = { name = "Longbow", damageType = "NORMAL", power = 110, ballistic = "MISSILE", range = 120, weight = 4, cd = 60, },
	[303]  = { name = "Crossbow", damageType = "NORMAL", power = 130, ballistic = "MISSILE", range = 60, weight = 4, cd = 60, },	
	[304]  = { name = "Stone", damageType = "NORMAL", power = 20, ballistic = "MISSILE", range = 20, weight = 6, cd = 45,	},
	[305]  = { name = "Javelin", damageType = "PIERCE", power = 30, ballistic = "MISSILE", range = 30, weight = 6, cd = 45,	},

	--400+ Siege weapon	
	[400] = { name = "Tower Archer", damageType = "PIERCE", power = 40, ballistic = "MISSILE", range = 100, weight = 10, cd = 60, },
	[401] = { name = "Battering Ram", damageType = "SIEGE", power = 200, ballistic = "CLOSE", range = 1, weight = 10, cd = 60, },	
	[402] = { name = "Huge Rock", damageType = "SIEGE", power = 400, ballistic = "MISSILE", range = 250, weight = 15, cd = 90, },	
}

function Scenario_Demo_Weapon_TableData()
	return WeaponTableData
end

local ArmorTableData = 
{
	--Fortified
	[100] = { name = "stone", type = "FORTIFIED", part = "BODY", weight = 999, protection = 100, },	
	[101] = { name = "iron gate", type = "FORTIFIED", part = "BODY", weight = 999, protection = 100, },		

	--Head
	[200] = { name = "scarf", type = "NONE", part  = "HEAD", weight = 1, protection = 5, },
	[201] = { name = "helmet", type = "LIGHT", part  = "HEAD", weight = 5, protection = 10,	},	

	--Body	
	[300] = { name = "Cloth", type = "MEDIUM", part  = "BODY", weight = 8, protection = 10, },	
	[301] = { name = "Leather armor", type = "MEDIUM", part  = "BODY", weight = 8, protection = 10, },	
	[302] = { name = "Plate armor", type = "HEAVY", part  = "BODY",	weight = 15, protection = 50, },
	
	--Sheild
	[400] = { name = "Wooden Shield", type = "MEDIUM", part  = "SHIELD", weight = 8, protection = 25, traits = { SHIELD, } },
	[401] = { name = "Shield", type = "MEDIUM", part = "SHIELD", weight = 8, protection = 25, traits = { SHIELD, } },
	
	--Siege Armor
	[500] = { name = "Battering Ram Armor", type = "WOODEN", part = "BODY", weight = 20, protection = 100, },	
	[501] = { name = "Trebuchet Armor", type = "WOODEN", part = "BODY", weight = 30, protection = 60, },
}

function Scenario_Demo_Armor_TableData()
	return ArmorTableData
end