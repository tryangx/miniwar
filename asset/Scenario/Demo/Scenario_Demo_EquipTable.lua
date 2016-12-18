local WeaponTableData = 
{	
	[1] = 
	{
		name   = "Spear",
		damageType = "PIERCE",
		power  = 110,
		ballistic  = "LONG",
		range  = 4,
		weight = 6,
		cd     = 45,
	},
		
	[2] = 
	{
		name   = "Bow",
		damageType = "PIERCE",
		power  = 50,
		ballistic  = "MISSILE",
		range  = 100,
		weight = 5,
		cd     = 70,
	},
	
	[3] = 
	{
		name   = "Lance",
		damageType = "PIERCE",
		power  = 160,
		ballistic  = "CHARGE",
		range  = 3,
		weight = 12,
		cd     = 90,
	},
	
	[4] = 
	{
		name   = "Sword",
		damageType = "NORMAL",
		power  = 120,
		ballistic  = "MELEE",
		range  = 2,
		weight = 5,
		cd     = 40,
	},
	
	[5] = 
	{
		name   = "Dagger",
		damageType = "NORMAL",
		power  = 60,
		ballistic  = "MELEE",
		range  = 1,
		weight = 3,
		cd     = 30,
	},
	
	[200] = 
	{
		name   = "Tower Archer",
		damageType = "PIERCE",
		power  = 40,
		ballistic  = "MISSILE",
		range  = 100,
		weight = 10,
		cd     = 60,
	},
	
	[300] = 
	{
		name   = "Battering Ram",
		damageType = "SIEGE",
		power  = 200,
		ballistic  = "CLOSE",
		range  = 1,
		weight = 10,
		cd     = 60,
	},
	
	[301] = 
	{
		name   = "Rock",
		damageType = "SIEGE",
		power  = 400,
		ballistic  = "MISSILE",
		range  = 250,
		weight = 15,
		cd     = 90,
	},
	
	[500] = 
	{
		name   = "Fork",
		damageType = "NORMAL",
		power  = 80,
		ballistic  = "MELEE",
		range  = 1,
		weight = 4,
		cd     = 60,
	},
}

function Scenario_Demo_Weapon_TableData()
	return WeaponTableData
end

local ArmorTableData = 
{
	[1] = 
	{
		id     = 1,
		name   = "scarf",
		type   = "NONE",
		part   = "HEAD",
		weight = 1,
		protection = 5,
	},

	[2] = 
	{
		id     = 2,
		name   = "helmet",
		type   = "LIGHT",
		part   = "HEAD",
		weight = 5,
		protection = 10,
	},
	
	[3] = 
	{
		id     = 3,
		name   = "leather armor",
		type   = "MEDIUM",
		part   = "BODY",
		weight = 8,
		protection = 10,
	},
	
	[4] = 
	{
		id     = 4,
		name   = "plate armor",
		type   = "HEAVY",
		part   = "BODY",
		weight = 15,
		protection = 50,
	},
	
	[5] = 
	{
		id     = 5,
		name   = "wooden shield",
		type   = "MEDIUM",
		part   = "SHIELD",
		weight = 8,
		protection = 25,
		traits = 
		{
			SHIELD,
		}
	},
	
	[100] =
	{
		name       = "stone",
		type       = "FORTIFIED",
		part       = "BODY",
		weight     = 999,
		protection = 100,
	},
	
	[101] =
	{
		name       = "iron gate",
		type       = "FORTIFIED",
		part       = "BODY",
		weight     = 999,
		protection = 100,
	},
	
	[300] = 
	{
		name       = "Battering Ram Armor",
		type       = "WOODEN",
		part       = "BODY",
		weight     = 20,
		protection = 100,
	},
	
	[301] = 
	{
		name       = "Trebuchet Armor",
		type       = "WOODEN",
		part       = "BODY",
		weight     = 30,
		protection = 60,
	},
}

function Scenario_Demo_Armor_TableData()
	return ArmorTableData
end