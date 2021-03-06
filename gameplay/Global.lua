package.path = package.path .. ";asset/Scenario/Standard/?.lua"

g_gameId = os.time()
g_gameId = 1492585842

g_language = "eng"--"chs"

---------------------------------------
-- Utility
require "Randomizer"
require "MathUtility"
require "FileUtility"
require "DebugUtility"
require "LogUtility"
require "HelperUtility"
require "InputUtility"
require "MenuUtility"
require "ProfileUtility"
require "LocalizeUtility"

require "Behavior"

---------------------------------------
-- Manager
require "TableManager"
require "DataManager"

---------------------------------------
-- Helper
require "Report"
require "DataUtility"
require "Statistic"
require "Chronicle"

---------------------------------------
-- Configure
--require "Parameter"
require "Policy"
require "GlobalParams"

---------------------------------------
-- Table
require "GameScenario"
require "CharacterTable"
require "TraitTable"
require "CityTable"
require "ConstructionTable"
require "CorpsFormationTable"
require "GroupTable"
require "TechniqueTable"
require "TroopTable"
require "WeaponTable"
require "ArmorTable"
require "GroupRelationTable"
require "BattlefieldTable"
require "WeatherTable"
require "SeasonTable"
require "ClimateTable"
require "ResourceTable"
require "PlotTable"

require "Scenario_Standard_Table"
require "Scenario_Standard_CombatEvent"

---------------------------------------
-- Data Mediator
require "Proposal"
require "Character"
require "CharacterTemplate"
require "Group"
require "City"
require "Troop"
require "Corps"
require "Plot"

---------------------------------------
-- Logical
require "GameMap"
require "GameEvent"
require "Task"
require "TaskOperation"
--require "FullCombat"
require "QuickCombat"
require "CombatEvent"
require "Warfare"
require "GroupRelation"
require "Climate"
require "Season"
require "Calendar"
require "PlotMap"
require "Dialogue"
require "Formula"
require "Meeting"
require "Diplomacy"
require "MovingActor"
require "Goal"
require "CharacterGrowth"

---------------------------------------
-- AI
require "CharacterAI"

---------------------------------------
-- Gameplay
g_scenario = GameScenario()

g_warfare  = Warfare()

g_meeting = Meeting()

g_diplomacy = Diplomacy()

g_taskMng   = TaskManager()

g_movingActorMng = MovingActorManager()

g_plotMap  = PlotMap()

g_climate  = Climate()
g_season   = Season()
g_calendar = Calendar()

g_statistic = Statistic()

g_chronicle = Chronicle()

g_charaTemplate = CharacterTemplate()

g_gameEvent = GameEvent()

g_gameMap = GameMap()

---------------------------
-- Configure Table
g_groupTableMng     = TableManager( "GROUP_TABLE", GroupTable )
g_cityTableMng      = TableManager( "CITY_TABLE",  CityTable )
g_charaTableMng     = TableManager( "CHARACTER_TABLE", CharacterTable )
g_troopTableMng     = TableManager( "TROOP_TABLE", TroopTable )
g_techTableMng      = TableManager( "TECH_TABLE",  TechniqueTable )
g_constrTableMng    = TableManager( "CONSTRUCTION_TABLE", ConstructionTable )
g_formationTableMng = TableManager( "FORMATION_TABLE", CorpsFormationTable )
g_weaponTableMng    = TableManager( "WEAPON_TABLE", WeaponTable )
g_armorTableMng     = TableManager( "ARMOR_TABLE", ArmorTable )
g_groupRelationTableMng = TableManager( "GROUPRELATION_TABLE", GroupRelationTable )
g_battlefieldTableMng   = 	TableManager( "BATTLEFIELD_TABLE", BattlefieldTable )
g_weatherTableMng       = TableManager( "WEATHER_TABLE", WeatherTable )
g_climateTableMng       = TableManager( "CLIMATE_TABLE", ClimateTable )
g_seasonTableMng        = TableManager( "SEASON_TABLE", SeasonTable )
g_traitTableMng         = TableManager( "TRAIT_TABLE", TraitTable )
g_resourceTableMng      = TableManager( "RESOURCE_TABLE", ResourceTable )
g_plotTableMng          = TableManager( "PLOT_TABLE", PlotTable )

---------------------------
-- Running Data
g_groupDataMng = DataManager( "GROUP_DATA", Group )
g_cityDataMng  = DataManager( "CITY_DATA",  City )
g_charaDataMng = DataManager( "CHARACTER_DATA", Character )
g_troopDataMng = DataManager( "TROOP_DATA", Troop )
g_corpsDataMng = DataManager( "CORPS_DATA", Corps )
g_groupRelationDataMng = DataManager( "GROUPRELATION_DATA", GroupRelation )
g_combatDataMng = DataManager( "COMBAT_DATA", Combat )

---------------------------
-- Randomizer

-- Lock step
g_syncRandomizer = Randomizer( g_gameId )

-- Local game
g_asyncRandomizer = Randomizer( g_gameId )

---------------------------
-- AI

g_charaAI = CharacterAI()
g_charaAI:SetRandomizer( g_syncRandomizer )

---------------------------
-- Combat Event Trigger

combatEventTrigger = CombatEventTrigger()

---------------------------

g_reporter = Report()

g_menu = MenuUtility()

g_gameMode = GameMode.SCENARIO_GAME

---------------------------
-- Running Data