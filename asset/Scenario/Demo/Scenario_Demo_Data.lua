local CharaData =
{
	[1] = 
	{
		name = "SiMa Cuo",
		location    = 10,
		ca          = 60,
		pa          = 80,
		purpose     = 0,
		status      = "OUT",
		job         = "NONE",
		traits = { 1000, 1030 },
	},
	[2] = 
	{
		name = "Wang Jian",
		location    = 10,		
		ca          = 60,
		pa          = 80,
		purpose     = 0,
		status      = "NOT_APPEAR",
		job         = "NONE",
		traits = { 1000, 1030 },
	},

	[100] = 
	{
		name = "QING WANG",
		location    = 10,		
		ca          = 60,
		pa          = 80,
		purpose     = 0,
		job         = "KING",
		traits = { 1000, 1030 },
	},	
	[102] = 
	{
		name = "BAI QI",		
		location    = 10,		
		ca          = 60,
		pa          = 80,
		purpose     = 0,
		job 		= "MARSHAL",		
		traits = { 1000, 1030 },
	},
	[104] = 
	{
		name = "WANG JIAN",		
		location    = 10,		
		ca          = 60,
		pa          = 80,		
		purpose     = 0,
		traits = { 1000, 1030 },
	},
	[103] = 
	{
		name = "MENG TIAN",		
		location    = 11,		
		ca          = 60,
		pa          = 80,		
		purpose     = 0,		
		job         = "GENERAL",
		contribution = 2000,
		traits = { 1000, 1030 },
	},
	[101] = 
	{
		name = "FAN JU",		
		location    = 10,
		ca          = 60,
		pa          = 80,		
		purpose     = 0,
		job         = "CABINET_MINISTER",
		traits = { 3000 },
	},
	[105] = 
	{
		name = "YAO JA",		
		location    = 10,
		ca          = 60,
		pa          = 80,		
		purpose     = 0,
		traits = { 3000 },
	},
	[106] = 
	{
		name = "LI SI",		
		location    = 10,
		ca          = 60,
		pa          = 80,		
		purpose     = 0,
		job         = "OFFICER",
		contribution = 1200,
		traits = { 3000 },
	},
	
	
	[200] = 
	{
		name = "QI WANG",
		location    = 20,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,		
		job         = "KING",
		traits = { 1001, 1010, 1040 },
	},
	[201] = 
	{
		name = "TIAN DAN",		
		location    = 20,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,		
		traits = { 1001, 1010, 1040 },
	},
	[202] = 
	{
		name = "SUN BIN",		
		location    = 20,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,		
		traits = { 1001, 1010, 1040 },
	},
	[203] = 
	{
		name = "ZHOU JI",		
		location    = 20,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,		
		traits = { 3000 },
	},
	
	[300] = 
	{
		name = "CHU WANG",
		location    = 30,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,	
		job         = "KING",		
		traits = { 1001, 1010, 1040 },
	},
	
	[400] = 
	{
		name = "WEI WANG",
		location    = 40,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,	
		job         = "KING",		
		traits = { 1001, 1010, 1040 },
	},
	
	[500] = 
	{
		name = "ZHAO WANG",
		location    = 50,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,		
		job         = "KING",
		traits = { 1001, 1010, 1040 },
	},
	
	[600] = 
	{
		name = "YAN WANG",
		location    = 60,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,	
		job         = "KING",		
		traits = { 1001, 1010, 1040 },
	},
	
	[700] = 
	{
		name = "HAN WANG",
		location    = 70,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,		
		job         = "KING",
		traits = { 1001, 1010, 1040 },
	},
	
	[800] = 
	{
		name = "ZHONG SHAN WANG",
		location    = 70,		
		ca          = 50,
		pa          = 90,		
		purpose     = 0,	
		job         = "KING",		
		traits = { 1001, 1010, 1040 },
	},
	
	[900] = 
	{
		name = "ZHOU TIANZI",
		location    = 70,
		ca          = 50,
		pa          = 90,		
		purpose     = 0,		
		traits = { 1001, 1010, 1040 },
	},
}

local TroopData =
{
	[1]=
	{
		name = "Footman",
		tableId = 1000,
		number = 1000,
		leader = 0,
		corps = 1,
		traits = { 310 },
	},
	[2]=
	{
		name = "Footman",
		tableId = 1000,
		number=1000,
		leader = 0,
		corps = 0,
		traits = { 310 },
	},
	[3]=
	{
		name = "Red Archer",
		tableId = 2000,
		exp = 0,
		level =8,
		number=1000,
		morale=90,
		leader = 0,
		corps = 0,
	},
	[4]=
	{
		name = "Red Archer",
		tableId = 2000,
		exp = 0,
		level =8,
		number=1000,
		morale=90,
		leader = 0,
		corps = 0,
	},
	[5]=
	{
		name = "Red Cavalry",
		tableId = 3000,
		exp = 0,		
		level =14,
		number=500,
		morale=90,
		leader = 1,
		corps = 0,
	},
	
	[11]=
	{
		name = "Blue Archer",
		tableId = 2000,
		exp = 0,
		level =8,
		number=1000,
		morale=90,
		leader = 0,
		corps = 0,
	},
	[12]=
	{
		name = "Blue Archer",
		tableId = 2000,
		exp = 0,
		level =8,
		number=1000,
		morale=90,
		leader = 0,
		corps = 0,
	},
	[13]=
	{
		name = "Blue Cavalry",
		tableId = 3000,
		exp = 0,
		level =16,		
		number=500,
		morale=90,
		leader = 2,
		corps = 0,
	},
	[14]=
	{
		name = "Blue Cavalry",
		tableId = 3000,		
		exp = 0,
		level = 10,
		number=500,
		morale=90,
		leader = 0,
		corps = 0,
	},
	[15]=
	{
		name = "Blue Cavalry",
		tableId = 3000,
		exp = 0,
		level =14,
		number=500,
		morale=90,
		leader = 0,
		corps = 0,
	},
		
	[100] = 
	{
		name      = "Wall",		
		tableId   = 100,
		level     = 999,		
		number    = 1000,
		morale    = 50,
		traits    = { 300 },
	},
	[200] = 
	{
		name      = "Gate",	
		tableId   = 200,
		level     = 999,		
		number    = 500,
		morale    = 50,
	},
	[210] = 
	{
		name      = "Tower",	
		tableId   = 210,
		level     = 999,		
		number    = 500,
		morale    = 50,
	},
	[300] = 
	{
		name      = "Battering Ram",
		tableId   = 300,
		exp       = 0,		
		level     = 50,		
		number    = 1000,
		morale    = 60,
	},
	[301] = 
	{
		name      = "Trebuchet",
		tableId   = 301,
		exp       = 0,
		number    = 1000,
		morale    = 60,
	},
	[500] = 
	{
		name      = "Militia",
		tableId   = 500,
		exp       = 0,		
		level     = 5,		
		number    = 1000,
		morale    = 40,
	},
}

local CorpsData = 
{
	[1] = 
	{	
		id=1,
		name="Qin Jun",
		encampment=10,
		location=10,
		formation=1,
		troops={ 1 },--, 2, 3, 4, 5, 300, 301 },
		leader = 0,
	},
	
	[2] = {	
		id=2,
		name="Bandit",
		encampment=21,
		location=21,
		formation=1,
		--troops={ 13 },
		troops={ 13, 14, 15, 11, 12 },
		leader = 0,
	},
}

local CityData = 
{
	[10] = 
	{
		name = "Xian Yang",
		coordinate = { x = 1, y = 5 },
		population = 60000,
		size = "CITY",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",		
		cultureCircle = 0,		
		security = 80,		
		traits = {},
		charas = { 100, 101, 102, 105, 104 },
		corps  = { 1 },	
		troops = { 1, 2 },	
		constructions = {},		
		resources = {},--{ 200, 201, 202, 203, 204, 205, 206 },
		plots = { { x = 1, y = 1 }, { x = 2, y = 1 } },
		adjacentCities = { 11, 30, 40, 70 },
	},
	[11] = 
	{
		name = "Han gu guan",
		coordinate = { x = 2, y = 5 },
		population = 3000,
		size = "TOWN",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",			
		cultureCircle = 0,		
		security = 100,
		instruction = "ECONOMIC",
		traits = {},
		charas = { 103 },
		corps  = { },
		troops = { },
		constructions = {},		
		resources = {},
		plots = { { x = 2, y = 2 }, { x = 2, y = 2 } },
		adjacentCities = { 10, 40 },
	},
	
	[20] = 
	{
		name = "LIN ZI",
		coordinate = { x = 8, y = 3 },
		population = 200000,		
		size = "LARGE_CITY",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",		
		cultureCircle = 0,		
		security = 80,		
		traits = {},		
		charas = { 200, 201, 202, 203 },		
		corps  = {},		
		troops = {},				
		constructions = {},		
		resources = {},		
		adjacentCities = { 40, 50, 60 },
	},
		
	[30] = 
	{
		name = "YING",
		coordinate = { x = 6, y = 10 },
		population = 180000,		
		size = "LARGE_CITY",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",			
		cultureCircle = 0,		
		security = 80,		
		traits = {},		
		charas = {},		
		corps  = {},		
		troops = {},				
		constructions = {},		
		resources = {},		
		adjacentCities = { 10, 70 },
	},
	
	[40] = 
	{
		name = "DA LIANG",
		coordinate = { x = 4, y = 4 },
		population = 250000,		
		size = "LARGE_CITY",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",			
		cultureCircle = 0,		
		security = 80,		
		traits = {},		
		charas = {},		
		corps  = {},		
		troops = {},				
		constructions = {},		
		resources = {},		
		adjacentCities = { 10, 11, 20, 50, 70 },
	},
	
	[50] = 
	{
		name = "HAN DAN",
		coordinate = { x = 10, y = 4 },
		population = 120000,
		size = "LARGE_CITY",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",			
		cultureCircle = 0,		
		security = 80,		
		traits = {},		
		charas = {},		
		corps  = {},		
		troops = {},				
		constructions = {},		
		resources = {},		
		adjacentCities = { 20, 40, 60, 70 },
	},
	
	[60] = 
	{
		name = "JI",
		coordinate = { x = 8, y = 0 },
		population = 60000,		
		size = "CITY",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",			
		cultureCircle = 0,		
		security = 80,		
		traits = {},		
		charas = {},		
		corps  = {},		
		troops = {},				
		constructions = {},		
		resources = {},		
		adjacentCities = { 20, 50 },
	},
	
	[70] = 
	{
		name = "XIN ZHENG",
		coordinate = { x = 6, y = 5 },
		population = 100000,	
		size = "LARGE_CITY",		
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",			
		cultureCircle = 0,		
		security = 80,		
		traits = {},		
		charas = {},		
		corps  = {},		
		troops = {},				
		constructions = {},		
		resources = {},		
		adjacentCities = { 10, 30, 40, 50 },
	},
	
	[80] = 
	{
		name = "LING SHOU",
		coordinate = { x = 7, y = 3 },
		population = 18000,		
		size = "CITY",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",			
		cultureCircle = 0,		
		security = 80,		
		traits = {},		
		charas = {},		
		corps  = {},
		troops = {},				
		constructions = {},		
		resources = {},		
		adjacentCities = {},
	},
	
	[90] = 
	{
		name = "LUO YI",
		coordinate = { x = 4, y = 6 },
		population = 25000,		
		size = "CITY",
		agriculture    = "50%",
		economy        = "50%",
		production     = "50%",		
		cultureCircle = 0,		
		security = 80,		
		traits = {},		
		charas = {},		
		corps  = {},		
		troops = {},				
		constructions = {},		
		resources = {},		
		adjacentCities = {},
	},
}

local GroupData =
{
	[1] =
	{
		name = "QIN",
		goals = { { type="CONQUER", value = 6, rate = 80 } },
		leader = 100,
		money = 1000,
		researchAbility = 100,
		power = 400000,
		capital = 10,
		cities = { 10, 11 },		
		charas = { 100, 101, 102, 103, 104, 105 },
		troops = {},
		corps = { 1 },
		relations = { 10, 11, 12, 13, 14, 15, 16, 17 },
		tags = {
			{ type = "MILITANT", value = 6 },
		}		
	},
	--[[
	[2] =
	{
		name = "QI",
		goals = { { type="CONQUER", rate = 80 } },
		leader = 200,
		money = 1000,
		researchAbility = 100,
		power = 350000,
		capital = 20,
		cities = { 20 },
		charas = { 200, 201, 202, 203 },
		troops = {},
		corps = {},
		relations = { 10, 20, 21, 22, 23, 24, 25, 26 },
	},
	[3] =
	{
		name = "Chu",
		goals = { { type="CONQUER", rate = 80 } },
		leader = 300,		
		money = 10000,
		researchAbility = 100,
		power = 500000,
		capital = 30,
		cities = { 30 },
		charas = { 300 },
		troops = {},
		corps = {},		
		relations = { 11, 20, 30, 31, 32, 33, 34, 35 },
	},
	--]]
	[4] =
	{
		name = "Wei",
		goals = { { type="CONQUER", rate = 80 } },
		leader = 400,		
		money = 1000,
		researchAbility = 100,
		power = 250000,
		capital = 40,
		cities = { 40 },
		charas = { 400 },
		troops = {},
		corps = {},		
		relations = { 12, 21, 30, 40, 41, 42, 43, 44 },
	},
	--[[
	[5] =
	{
		name = "Zhao",
		goals = { { type="CONQUER", rate = 80 } },
		leader = 500,
		money = 1000,
		researchAbility = 100,
		power = 300000,
		capital = 50,
		cities = { 50 },
		charas = { 500 },
		troops = {},
		corps = {},		
		relations = { 13, 22, 31, 40, 50, 51, 52, 53 },
	},
	[6] =
	{
		name = "Yan",
		goals = { { type="CONQUER", rate = 80 } },
		leader = 600,
		money = 1000,
		researchAbility = 100,
		power = 250000,
		capital = 60,
		cities = { 60 },
		charas = { 600 },
		troops = {},
		corps = {},		
		relations = { 14, 23, 32, 41, 50, 60, 61, 62 },
	},
	[7] =
	{
		name = "Han",
		goals = { { type="CONQUER", rate = 80 } },
		leader = 700,
		money = 1000,
		researchAbility = 100,
		power = 150000,
		capital = 70,
		cities = { 70 },
		charas = { 700 },
		troops = {},
		corps = {},		
		relations = { 15, 24, 33, 42, 51, 60, 70, 71 },
	},
	[8] =
	{
		name = "ZS",
		goals = { { type="SURVIVE", value = 240 } },
		leader = 800,
		money = 1000,
		researchAbility = 100,
		power = 15000,
		capital = 80,
		cities = { 80 },
		charas = { 800 },
		troops = {},
		corps = {},		
		relations = { 16, 25, 34, 43, 52, 61, 70, 80 },
	},
	[9] =
	{
		name = "ZHOU",
		goals = { { type="INDEPENDENT", value = 120 } },
		leader = 900,
		money = 10000,
		researchAbility = 100,
		power = 2500,
		capital = 90,
		cities = { 90 },
		charas = { 900 },
		troops = {},
		corps = {},		
		relations = { 17, 26, 35, 44, 53, 62, 71, 80 },
	},
	--]]
}

local GroupRelationData = 
{
	[10] = 
	{
		--QIN VS QI
		sid=1, tid=2, evaluation=0, type="FRIEND", traits = {}			
	},
	[11] = 
	{
		--QIN VS CHU
		sid=1, tid=3, evaluation=0, type="ENEMY", traits = {}			
	},
	[12] = 
	{
		--QIN VS WEI
		sid=1, tid=4, evaluation=0, type="NEUTRAL", traits = 
		{
			{ type = "OLD_ENEMY", id = 0, value = 5 },
		}
	},
	[13] = 
	{
		--QIN VS ZHAO
		sid=1, tid=5, evaluation=0, type="HOSTILITY", traits = {}			
	},
	[14] = 
	{
		--QIN VS YAN
		sid=1, tid=6, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[15] = 
	{
		--QIN VS HAN
		sid=1, tid=7, evaluation=0, type="ENEMY", traits = {}			
	},
	[16] = 
	{
		--QIN VS ZHONG SHAN
		sid=1, tid=8, evaluation=0, type="VASSAL", traits = {}			
	},
	[17] = 
	{
		--QIN VS ZHOU
		sid=1, tid=9, evaluation=0, type="TRUCE", traits = {}			
	},
	
	[20] = 
	{
		--QI VS CHU
		sid=2, tid=3, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[21] = 
	{
		--QI VS WEI
		sid=2, tid=4, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[22] = 
	{
		--QI VS ZHAO
		sid=2, tid=5, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[23] = 
	{
		--QI VS YAN
		sid=2, tid=6, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[24] = 
	{
		--QI VS HAN
		sid=2, tid=7, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[25] = 
	{
		--QI VS ZHONG SHAN
		sid=2, tid=8, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[26] = 
	{
		--QI VS ZHOU
		sid=2, tid=9, evaluation=0, type="NEUTRAL", traits = {}			
	},
	
	[30] = 
	{
		--CHU VS WEI
		sid=3, tid=4, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[31] = 
	{
		--CHU VS ZHAO
		sid=3, tid=5, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[32] = 
	{
		--CHU VS YAN
		sid=3, tid=6, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[33] = 
	{
		--CHU VS HAN
		sid=3, tid=7, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[34] = 
	{
		--CHU VS ZS
		sid=3, tid=8, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[35] = 
	{
		--CHU VS 
		sid=3, tid=9, evaluation=0, type="NEUTRAL", traits = {}			
	},
	
	[40] = 
	{
		--WEI VS ZHAO
		sid=4, tid=5, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[41] = 
	{
		--WEI VS YAN
		sid=4, tid=6, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[42] = 
	{
		--WEI VS HAN
		sid=4, tid=7, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[43] = 
	{
		--CHU VS ZS
		sid=4, tid=8, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[44] = 
	{
		--CHU VS 
		sid=4, tid=9, evaluation=0, type="NEUTRAL", traits = {}			
	},
	
	[50] = 
	{
		--ZHAO VS YAN
		sid=5, tid=6, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[51] = 
	{
		--ZHAO VS HAN
		sid=5, tid=7, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[52] = 
	{
		--CHU VS 
		sid=5, tid=8, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[53] = 
	{
		--CHU VS 
		sid=5, tid=9, evaluation=0, type="NEUTRAL", traits = {}			
	},
	
	[60] = 
	{
		--YAN VS HAN
		sid=6, tid=7, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[61] = 
	{
		--YAN VS 
		sid=6, tid=8, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[62] = 
	{
		--YAN VS 
		sid=6, tid=9, evaluation=0, type="NEUTRAL", traits = {}			
	},
	
	[70] = 
	{
		--CHU VS 
		sid=7, tid=8, evaluation=0, type="NEUTRAL", traits = {}			
	},
	[71] = 
	{
		--CHU VS 
		sid=7, tid=9, evaluation=0, type="NEUTRAL", traits = {}			
	},
	
	[80] = 
	{
		sid=8, tid=9, evaluation=0, type="NEUTRAL", traits = {}			
	},
}

local PlotData = 
{
	{
		x = 1,
		y = 1,
		tableId = 100,
		assets = { },
	},
	{
		x = 2,
		y = 1,
		tableId = 200,
	},
	{
		x = 1,
		y = 2,
		tableId = 300,
	},
	{
		x = 2,
		y = 2,
		tableId = 400,
	},
}

function Scenario_Demo_GroupRelation_TableData()
	return GroupRelationData
end

function Scenario_Demo_Troop_Data()
	return TroopData
end

function Scenario_Demo_Corps_Data()
	return CorpsData
end

function Scenario_Demo_City_Data()
	return CityData
end

function Scenario_Demo_Group_Data()
	return GroupData
end

function Scenario_Demo_Chara_Data()
	return CharaData
end

function Scenario_Demo_GroupRelation_Data()
	return GroupRelationData
end

function Scenario_Demo_Plot_Data()
	return PlotData
end