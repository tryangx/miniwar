local CorpsFormationData = 
{
	[1] = 
	{
		id = 1,
		name = "Standard",
		
		minTroop = 1,
		maxTroop = 8,
		
		--infantry, archer, cavalry
		troopProps = { 0.5, 0.3, 0.2 },
	},
}

function Scenario_Demo_CorpsFormation_TableData()
	return CorpsFormationData
end