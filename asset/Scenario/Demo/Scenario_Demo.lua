require "Scenario_Demo_TroopTable"
require "Scenario_Demo_CharacterTable"
require "Scenario_Demo_CityTable"
require "Scenario_Demo_GroupTable"
require "Scenario_Demo_TechTable"
require "Scenario_Demo_ConstructionTable"
require "Scenario_Demo_CorpsFormation"
require "Scenario_Demo_EquipTable"
require "Scenario_Demo_GroupRelationTable"
require "Scenario_Demo_BattlefieldTable"
require "Scenario_Demo_TraitTable"
require "Scenario_Demo_Data_threekindoms"
--require "Scenario_Demo_Data_chuhan"
--require "Scenario_Demo_Data_warringstates"

--------------------------
-- Guard Table
--------------------------
local PlotGuardTableData =
{
	{ plotNumber = 1, ids = { 510, 500 } },
	{ plotNumber = 5, ids = { 511, 501 } },		
	{ plotNumber = 10, ids = { 512, 502 } },
	{ plotNumber = 999, ids = { 512, 502 } },
}
local function ScenarioDemo_QueryPlotGuardIds( plotNumber )
	for k, data in ipairs( PlotGuardTableData ) do
		if plotNumber <= data.plotNumber then
			return data.ids
		end
	end
	return {}
end

local function ScenarioDemo_IsPlotGuard( checkId )
	for k, data in ipairs( PlotGuardTableData ) do
		for k2, id in ipairs( data.ids ) do
			return id == checkId
		end
	end
	return false
end

ScenarioDemo = 
{
	id   = 1,
	name = "Demo",
	
	begdate = 
	{
		year  = 184,
		month = 1,
		day   = 1,
		bc    = 0,
	},
	
	tables = 
	{
		--------------------------------------------------------------------
		-- This is static data which almost like configure table in mod
		--
		--------------------------------------------------------------------
		GROUP_TABLE        = { data = Scenario_Demo_Group_TableData },
		CHARACTER_TABLE    = { data = Scenario_Demo_Character_TableData },
		TROOP_TABLE        = { data = Scenario_Demo_Troop_TableData },
		CITY_TABLE         = { data = Scenario_Demo_City_TableData },
		TECH_TABLE         = { data = Scenario_Demo_Tech_TableData },
		CONSTRUCTION_TABLE = { data = Scenario_Demo_Construction_TableData },
		FORMATION_TABLE    = { data = Scenario_Demo_CorpsFormation_TableData },
		WEAPON_TABLE       = { data = Scenario_Demo_Weapon_TableData },
		ARMOR_TABLE        = { data = Scenario_Demo_Armor_TableData },
		GROUPRELATION_TABLE = { data = Scenario_Demo_GroupRelation_TableData },
		BATTLEFIELD_TABLE  = { data = Scenario_Demo_Battlefield_TableData },		
		TRAIT_TABLE        = { data = Scenario_Demo_Trait_TableData },

		--------------------------------------------------------------------
		-- This is dynamic data which almost like g_scenario in different mod
		--------------------------------------------------------------------
		TROOP_DATA         = { data = Scenario_Demo_Troop_Data },
		CORPS_DATA         = { data = Scenario_Demo_Corps_Data },
		CITY_DATA          = { data = Scenario_Demo_City_Data },
		GROUP_DATA         = { data = Scenario_Demo_Group_Data },
		CHARA_DATA         = { data = Scenario_Demo_Chara_Data },
		GROUPRELATION_DATA = { data = Scenario_Demo_GroupRelation_Data },
	},
	
	functions = 
	{
		QueryPlotGuardIds = ScenarioDemo_QueryPlotGuardIds,
		IsPlotGuard       = ScenarioDemo_IsPlotGuard,
	},
}