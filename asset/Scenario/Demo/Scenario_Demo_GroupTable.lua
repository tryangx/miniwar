local GroupTableData =
{
	[1] =
	{
		id   = 1,
		name = "red",		
		goals = { { type="DOMINATE", value=21 } },		
		money = 1000,
		researchAbility = 100,		
		capital = 10,
		cities = { 10, 11 },		
		charas = { 1 },
		troops = { 1 },		
		corps = { 1 },		
		relations = { 1 },
	},
	
	[2] =
	{
		id   = 2,
		name = "blue",				
		money = 1000,
		researchAbility = 100,		
		capital = 20,
		cities = { 20, 21 },		
		charas = { 2 },		
		troops = { 2 },		
		corps = { 2 },
		formations = { 1 },		
		relations = { 2 },
	},
}

function Scenario_Demo_Group_TableData()
	return GroupTableData
end