local CharaData =
{
	[100] = 
	{
		name = "Liu Bei",
		birth = -520,
		ca          = 60,
		ap          = 80,
		purpose     = 0,
		job         = "KING",
		traits = { 1000, 1030 },
	},
	[101] = 
	{
		name = "Zhuge Liang",	
		birth = -520,		
		ca          = 60,
		ap          = 80,
		purpose     = 0,
		job 		= "",		
		traits = { 1000, 1030 },
	},	
	[102] = 
	{
		name = "Guan Yu",	
		birth = -520,		
		ca          = 60,
		ap          = 80,
		purpose     = 0,
		job 		= "",		
		traits = { 1000, 1030 },
	},
	[103] = 
	{
		name = "Zhang Fei",	
		birth = -550,		
		ca          = 60,
		ap          = 80,		
		purpose     = 0,
		job         = "",
		traits = { 1000, 1030 },
	},
	
	[200] = 
	{
		name = "Cao cao",
		birth = -550,
		ca          = 50,
		ap          = 90,		
		purpose     = 0,		
		job         = "KING",
		traits = { 1001, 1010, 1040 },
	},
	[201] = 
	{
		name = "Xun Yu",
		birth = -550,		
		ca          = 50,
		ap          = 90,		
		purpose     = 0,		
		traits = { 1001, 1010, 1040 },
	},
	[202] = 
	{
		name = "XiaHou Yuan",
		birth = -550,		
		ca          = 50,
		ap          = 90,		
		purpose     = 0,		
		traits = { 1001, 1010, 1040 },
	},
	[203] = 
	{
		name = "XiaHou Dun",		
		birth = -550,
		ca          = 50,
		ap          = 90,		
		purpose     = 0,		
		traits = { 1001, 1010, 1040 },
	},
	
	[300] = 
	{
		name = "Sun Quan",
		birth = -550,
		ca          = 50,
		ap          = 90,		
		purpose     = 0,	
		job         = "KING",		
		traits = { 1001, 1010, 1040 },
	},
	[301] = 
	{
		name = "Zhou Yu",
		birth = -550,
		ca          = 50,
		ap          = 90,		
		purpose     = 0,	
		job         = "KING",		
		traits = { 1001, 1010, 1040 },
	},	
	[302] = 
	{
		name = "Taishi ci",
		birth = -550,
		ca          = 50,
		ap          = 90,		
		purpose     = 0,	
		job         = "KING",		
		traits = { 1001, 1010, 1040 },
	},
	[303] = 
	{
		name = "Gan Lin",
		birth = -550,
		ca          = 50,
		ap          = 90,		
		purpose     = 0,	
		job         = "KING",		
		traits = { 1001, 1010, 1040 },
	},
}

local TroopData =
{
--[[
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
		corps = 2,
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
		name = "Archer",
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
		name = "Archer",
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
		name = "Cavalry",
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
		name = "Cavalry",
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
		name = "Cavalry",
		tableId = 3000,
		exp = 0,
		level =14,
		number=500,
		morale=90,
		leader = 0,
		corps = 0,
	},
	[20]=
	{
		name = "Cavalry",
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
	]]
	--[[
	[500] = 
	{
		name      = "Guard F1",
		tableId   = 500,
		exp       = 0,		
		level     = 5,		
		number    = 100,
		morale    = 40,
	},
	[501] = 
	{
		name      = "Guard F2",
		tableId   = 501,
		exp       = 0,		
		level     = 5,		
		number    = 200,
		morale    = 40,
	},
	[502] = 
	{
		name      = "Guard F3",
		tableId   = 502,
		exp       = 0,		
		level     = 5,		
		number    = 500,
		morale    = 40,
	},
	[510] = 
	{
		name      = "Guard A1",
		tableId   = 510,
		exp       = 0,		
		level     = 5,		
		number    = 100,
		morale    = 40,
	},
	[511] = 
	{
		name      = "Guard A2",
		tableId   = 511,
		exp       = 0,		
		level     = 5,		
		number    = 200,
		morale    = 40,
	},
	[512] = 
	{
		name      = "Guard A3",
		tableId   = 512,
		exp       = 0,		
		level     = 5,		
		number    = 500,
		morale    = 40,
	},
	]]
}

local CorpsData = 
{
--[[
	[1] = 
	{	
		id=1,
		name="Qin Jun",
		home=10,
		location=10,
		formation=1,
		troops={ 1 },--, 2, 3, 4, 5, 300, 301 },
		leader = 0,
	},
	
	[2] = {	
		id=2,
		name="Qin Jun2",
		home=10,
		location=10,
		formation=1,
		--troops={ 13 },
		troops={ 13 },--, 14, 15, 11, 12 },
		leader = 0,
	},
	
	[3] = {	
		id=3,
		name="Wei Jun2",
		home=40,
		location=40,
		formation=1,
		--troops={ 13 },
		troops={ 20 },--, 14, 15, 11, 12 },
		leader = 0,
	},
	]]
}

local CityData = 
{
	--North of HuangHe
	[100] = 
	{
		name = "Dai Xiang",
		coordinate = { x = 66, y = 6 },
		level = 10,
		--charas = { 100, 101, 102, 103 },
		adjacentCities = { 101 },
	},
	[101] = 
	{
		name = "Bei Ping",
		coordinate = { x = 66, y = 9 },
		level = 10,
		--charas = { 100, 101, 102, 103 },
		adjacentCities = { 100, 103 },
	},
	[102] = 
	{
		name = "Jing Yang",
		coordinate = { x = 42, y = 12 },
		level = 8,
		adjacentCities = { 104 },
	},
	[103] = 
	{
		name = "Nan Pi",
		coordinate = { x = 54, y = 15 },
		level = 10,
		adjacentCities = { 101, 104 },
	},
	[104] = 
	{
		name = "Ye",
		coordinate = { x = 42, y = 18 },
		level = 11,
		adjacentCities = { 102, 103, 200 },
	},
	
	--Middle 
	[200] = 
	{
		name = "Chen Liu",
		coordinate = { x = 54, y = 27 },
		level = 11,
		charas = { 200, 201, 202, 203 },
		adjacentCities = { 104, 201, 300, 400 },
	},
	[201] = 
	{
		name = "Xu Chang",
		coordinate = { x = 54, y = 33 },
		level = 10,
		adjacentCities = { 200, 202, 401 },
	},
	[202] = 
	{
		name = "Shou Chun",
		coordinate = { x = 60, y = 39 },
		level = 10,
		adjacentCities = { 201, 301, 500, 601 },
	},
	
	--East 	
	[300] = 
	{
		name = "Xu Zhou",
		coordinate = { x = 66, y = 30 },
		level = 9,
		adjacentCities = { 200, 301, 302 },
	},
	[301] = 
	{
		name = "Xia Pi",
		coordinate = { x = 66, y = 33 },
		level = 7,
		adjacentCities = { 202, 300 },
	},
	[302] = 
	{
		name = "Bei Hai",
		coordinate = { x = 48, y = 33 },
		level = 8,
		adjacentCities = { 300 },
	},
	
	--Capital
	[400] = 
	{
		name = "Luo Yang",
		coordinate = { x = 42, y = 27 },
		level = 15,
		adjacentCities = { 200, 402 },
	},
	[401] = 
	{
		name = "Nan Yang",
		coordinate = { x = 42, y = 33 },
		level = 10,
		adjacentCities = { 201, 600 },
	},
	[402] = 
	{
		name = "Chang An",
		coordinate = { x = 30, y = 27 },
		level = 13,
		adjacentCities = { 400, 800, 900 },
	},	
	
	--South
	[500] = 
	{
		name = "Jian Ye",
		coordinate = { x = 60, y = 45 },
		level = 11,
		charas = { 300, 301, 302, 303 },
		adjacentCities = { 202, 501, 502 },
	},
	[501] = 
	{
		name = "Cai Shang",
		coordinate = { x = 54, y = 48 },
		level = 9,
		adjacentCities = { 500, 602, 701 },
	},
	[502] = 
	{
		name = "Gui Ji",
		coordinate = { x = 66, y = 51 },
		level = 10,
		adjacentCities = { 500, 503 },
	},
	[503] = 
	{
		name = "Wu",
		coordinate = { x = 66, y = 57 },
		level = 11,
		adjacentCities = { 502 },
	},
	
	--Center
	[600] = 
	{
		name = "Xiang Yang",
		coordinate = { x = 36, y = 42 },
		level = 13,
		adjacentCities = { 401, 601, 602, 1001 },
	},
	[601] = 
	{
		name = "Jiang Xia",
		coordinate = { x = 48, y = 42 },
		level = 8,
		adjacentCities = { 202, 501, 600, 602 },
	},
	[602] = 
	{
		name = "Jiang Ling",
		coordinate = { x = 42, y = 48 },
		level = 9,
		adjacentCities = { 501, 600, 601, 701 },
	},
	
	--South Four state
	[700] = 
	{
		name = "Chang Sha",
		coordinate = { x = 48, y = 54 },
		level = 10,
		adjacentCities = { 501, 602, 701, 702 },
	},
	[701] = 
	{
		name = "Ling Ling",
		coordinate = { x = 36, y = 54 },
		level = 6,
		adjacentCities = { 700, 702, 1001 },
	},
	[702] = 
	{
		name = "Gui Yang",
		coordinate = { x = 42, y = 60 },
		level = 6,
		adjacentCities = { 700, 701 },
	},
	
	[800] = 
	{
		name = "Hong Nong",
		coordinate = { x = 18, y = 21 },
		level = 7,
		adjacentCities = { 402, 801 },
	},
	[801] = 
	{
		name = "Tian Shui",
		coordinate = { x = 12, y = 15 },
		level = 4,
		adjacentCities = { 800, 802 },
	},
	[802] = 
	{
		name = "An Ding",
		coordinate = { x = 6, y = 12 },
		level = 3,
		adjacentCities = { 801 },
	},
	
	[900] = 
	{
		name = "Han Zhong",
		coordinate = { x = 24, y = 33 },
		level = 11,
		adjacentCities = { 402, 800, 901 },
	},
	[901] = 
	{
		name = "Zhi Tong",
		coordinate = { x = 18, y = 36 },
		level = 6,
		adjacentCities = { 900, 1000 },
	},
	
	[1000] = 
	{
		name = "Cheng Du",
		coordinate = { x = 18, y = 36 },
		level = 13,
		charas = { 100, 101, 102, 103 },
		adjacentCities = { 901, 1001, 1002 },
	},
	[1001] = 
	{
		name = "Jiang Zhou",
		coordinate = { x = 30, y = 48 },
		level = 8,
		adjacentCities = { 600, 701, 1000 },
	},
	[1002] = 
	{
		name = "Jian Ling",
		coordinate = { x = 18, y = 51 },
		level = 6,
		adjacentCities = { 1000, 1003 },
	},
	[1003] = 
	{
		name = "Yong An",
		coordinate = { x = 12, y = 57 },
		level = 5,
		adjacentCities = { 1002, 1004 },
	},
	[1004] = 
	{
		name = "Yun Nan",
		coordinate = { x = 12, y = 63 },
		level = 6,
		adjacentCities = { 1003 },
	},
}

local GroupData =
{
	[1] =
	{
		name = "SHU",
		goals = { { type="DOMINATION_TERRIORITY", target = 75, duration = 90 } },
		leader = 100,
		capital = 1000,
		cities = { 1000 },		
		charas = { 100, 101, 102, 103 },
		troops = {},
		corps = {},--{ 1, 2 },
		relations = {  },
		tags = {
			{ type = "MILITANT", value = 6 },
		}
	},	
	[2] =
	{
		name = "WEI",
		goals = { { type="DOMINATION_TERRIORITY", target = 75, duration = 90 } },
		leader = 200,
		capital = 200,
		cities = { 200 },
		charas = { 200, 201, 202, 203 },
		troops = {},
		corps = {},
		relations = {  },
	},
	
	[3] =
	{
		name = "WU",
		goals = { { type="DOMINATION_TERRIORITY", target = 75, duration = 90 } },
		leader = 300,		
		money = 10000,
		capital = 500,
		cities = { 500 },
		charas = { 300, 301, 302, 303 },
		troops = {},
		corps = {},		
		relations = {  },
	},
}

local GroupRelationData = 
{
--[[
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
		sid=1, tid=4, evaluation=0, type="BELLIGERENT", traits = 
		{
			{ type = "OLD_ENEMY", id = 0, value = 5 },
		}
	},
	]]
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