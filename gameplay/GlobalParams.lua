PlotAdjacentOffsets = {
	{ x = -1, y = -1, distance = 1, },
	{ x = 0,  y = -1, distance = 1, },
	{ x = 1,  y = 0,  distance = 1, },
	{ x = 0,  y = 1,  distance = 1, },
	{ x = -1, y = 1,  distance = 1, },
	{ x = -1, y = 0,  distance = 1, },	
	
	{ x = -1, y = -2, distance = 2, },
	{ x = 0,  y = -2, distance = 2, },
	{ x = 1,  y = -2, distance = 2, },	
	{ x = 1,  y = -1, distance = 2, },
	{ x = 2,  y = 0,  distance = 2, },
	{ x = 1,  y = 1,  distance = 2, },	
	{ x = 1,  y = 2,  distance = 2, },
	{ x = 0,  y = 2,  distance = 2, },
	{ x = -1, y = 2,  distance = 2, },	
	{ x = -2, y = 0,  distance = 2, },
	{ x = -2, y = -1, distance = 2, },
	
	{ x = -2, y = -3, distance = 3, },
	{ x = -1, y = -3, distance = 3, },
	{ x = 0,  y = -3, distance = 3, },
	{ x = 1,  y = -3, distance = 3, },	
	{ x = 2,  y = -2, distance = 3, },
	{ x = 2,  y = -1, distance = 3, },
	{ x = 3,  y = 0,  distance = 3, },
	{ x = 2,  y = 1,  distance = 3, },
	{ x = 2,  y = 2,  distance = 3, },	
	{ x = 1,  y = 3,  distance = 3, },
	{ x = 0,  y = 3,  distance = 3, },
	{ x = -1, y = 3,  distance = 3, },	
	{ x = -2, y = 3,  distance = 3, },	
	{ x = -2, y = 2,  distance = 3, },
	{ x = -3, y = 1,  distance = 3, },	
	{ x = -3, y = 0,  distance = 3, },
	{ x = -3, y = -1, distance = 3, },
	{ x = -2, y = -2, distance = 3, },	
}

local function CheckPlotAdjacentPlot()
	local count = 0
	local lines = {}
	for k, off in ipairs( PlotAdjacentOffsets ) do
		if off.distance > 0 then
			local y = off.y + 6
			local x = off.x + 6
			local line = lines[y]
			if not lines[y] then line = {} lines[y] = line end
			line[x] = off.distance
			--print( x, y, off.distance )
			count = count + 1
		end
	end

	--print( count )
	for y = 1, 10 do
		local line = lines[y]
		if line then
			local content = ""
			if y % 2 == 1 then content = " " end
			for x = 1, 10 do
				if line[x] then
					content = content .. line[x] .. " "
				else
					content = content .. "  "
				end
			end
			print( y .. ": " .. content )
		end
	end
end

GlobalConst = 
{
	------------------------	
	-- Time
	--
	-- Elapsed Time  : Use to elpase Time, minimum unit per turn.
	-- Unit Time     : Standard Time, use to evaluate all functions.
	-- Time Per Year : Standard Time, use to implement some functions.
	-- Move Time     : Standard Time, use to move entity like characters, corps.	
	ELPASED_TIME  = 30,
	UNIT_TIME     = 30,
	TIME_PER_YEAR = 360,
	MOVE_TIME     = 5,
	
	--assets
	INVALID_MONEY = 100000000,
	MAX_MONEY     = 99999999,
	
	--troop
	DEFAULT_TROOP_NUMBER = 1000,
	
	--Gender
	MALE_PROPORTION = 0.55,
	
	--Random Out Chara Limit
	LIMIT_OUTCHARA_BY_PLOT_MODULUS = 0.35,
	MIN_GENERATE_OUTCHARA_PER_TURN = 0,
	MAX_GENERATE_OUTCHARA_PER_TURN = 3,
}

PlotParams =
{
	MAX_PLOT_SECURITY    = 100,
	SAFETY_PLOT_SECURITY = 60,

	-------------------------
	--Population
	-- How many people lived in livingspace unit
	PLOT_POPULATION_CONSTANT         = 100,
	-- Growth & Death Rate Per Year
	PLOT_POPULATION_GROWTH_RATE      = 24,
	PLOT_POPULATION_DEATH_RATE       = 16,
	PLOT_POPULATION_FLUCTUATION_RATE = 6,
	
	--Agriculture -> Supply
	PLOT_SUPPLY_OUTPUT_CONSTANT      = 120,
	
	--Economy -> Income
	PLOT_INCOME_CAPITATION_CONSTNAT = 1,
	PLOT_INCOME_ECONOMY_CONSTANT    = 100,
	
	--Minimum population need
	-- Consider age structure of population, so minimum workforce rate is set to 0.7
	PLOT_NEED_POPULATION_MODULUS     = 0.5,
	PLOT_AGRICULTURE_NEED_POPULATION = 60,
	PLOT_ECONOMY_NEED_POPULATION     = 20,
	PLOT_PRODUCTION_NEED_POPULATION  = 40,
}

RandomParams = 
{
	MAX_PROBABILITY  = 10000,
	PROBABILITY_UNIT = 100,
}

-----------------------------------------
-- Plot & Resource Bonus
PlotResourceBonusType =
{
	NONE              = 0,	
	LIVING_SPACE      = 1,
	AGRICULTURE       = 10,
	ECONOMY           = 11,
	PRODUCTION        = 12,	
	FOOD_OUTPUT       = 20,
	PRODUCTION_OUTPUT = 21,
	MONEY_OUTPUT      = 22,
	SCIENCE_OUTPUT    = 23,
	CULTURE_OUTPUT    = 24,
	FAITH_OUTPUT      = 25,	
	SUPPLY_FOOD       = 30,
	SUPPLY_MODULUS    = 31,
}

-----------------------------------------
-- WarfarePlan

WarfarePlanParams = 
{
	MAX_TARGETCITY_POWER_MODULUS = 2,
}


-----------------------------------------
-- Combat

CombatType =
{
	FIELD_COMBAT  = 0,	
	SIEGE_COMBAT  = 1,
	--NAVAL  = 2,
}

CombatPurpose = 
{
	PROBING       = 0,	
	CONVENTIONAL  = 1,
	DESPERATE     = 2,
}

CombatSide =
{
	INVALID  = 0,
	NEUTRAL  = 1,	
	ATTACKER = 2,	
	DEFENDER = 3,
}

CombatResult = 
{
	--Time out
	DRAW              = 0,	
	--At least gain more advantage than opponent
	TACTICAL_VICTORY  = 1,	
	--All troops neutralized or fled
	TACTICAL_LOSE     = 2,
	---------------------------
	--Seperator
	COMBAT_END_RESULT = 3,	
	---------------------------
	--All enemy neutralized or fled
	STRATEGIC_VICTORY = 3,		
	--Gain less advantage than opponent
	STRATEGIC_LOSE    = 4,
	--
	BRILLIANT_VICTORY = 5,
	DISASTROUS_LOSE   = 6,
}

CombatTroopPurpose = 
{
	NONE          = 0,
	ASSUALT       = 3,
}

CombatTactic =
{
	-- infantry use ATTACK
	-- artillery use FIRE
	-- cavalry use ATTACK
	DEFAULT      = 0,
	-- attack or forward
	ATTACK       = 1,	
	-- fire or forward or attack
	FIRE         = 2,
	-- hold for a while and attack
	HOLD_ATTACK  = 3,	
	-- fire or attack, using in Siege
	DEFEND       = 4,
}

-----------------------------------------

TroopCategory =
{
	CATEGORY_BEG = 10,
	INFANTRY     = 10,
	ARTILLERY    = 20,	
	CAVALRY      = 30,	
	SIEGE_WEAPON = 40,	
	CATEGORY_END = 40,	
	DEFENCE      = 50,
	GATE         = 60,
	TOWER        = 70,
}

TroopStartLine =
{
	DEFENCE = 0,
	BACK    = 1,
	FRONT   = 2,
	CHARGE  = 3,
	MELEE   = 4,
}

TroopTag = 
{
	TRAINING     = 1,
	ORGANIZATION = 2,
	
	MAX_VALUE = 
	{
		--training
		[1] = 100,
	}
}

TroopParams =
{
	LEVEL_UP_EXP = 1000,
	
	MAX_LEVEL    = 10,

	TRAINING = 
	{
		TRAINING_PER_LEVEL   = 10,
		UNTRAINED_VALUE      = 100,
		TRAIN_STANDARD_VALUE = 5,
		TRAIN_DIFF_MODULUS   = 0.25,
	},
}

-----------------------------------------
-- Corps
CorpsTag = 
{
	--
	TEAMWORK      = 1,
	
	--
	ORGANIAZATION = 2,
}

CorpsParams =
{
	NUMBER_OF_TROOP_TO_ESTALIBSH = 3,

	JOB_TROOP_LIMIT =
	{
		NONE_JOB      = 5,
		LOW_RANK_JOB  = 10,
		HIGH_RANK_JOB = 15,
		IMPORTANT_JOB = 20,
		LEADER_JOB    = 25,
	},

	--
	REINFORCE_NEED_TIME          = 5,
	
	TRAIN_CORPS_MINIMUM_UNITTIME = 1,
}

----------------------------------------
-- City

CityTrait = 
{
	AGRICULTURE   = 1,	
	HUSBANDRY     = 2,	
	TECHNOLOGY    = 3,	
	ARCHITECTURE  = 4,	
	MEDICINE      = 5,	
	ART           = 6,	
	ACADEMIA      = 7,	
	VOYAGE        = 8,	
	WEAPON        = 9,	
	TACTICS       = 10,
}

CityCultureCircle = 
{
}


CityLevel = 
{
	VILLAGE      = 1,
	TOWN1        = 2,
	TOWN2        = 3,
	CITY1        = 4,
	CITY2        = 5,
	CITY3        = 6,
	LARGE_CITY1  = 7,
	LARGE_CITY2  = 8,
	LARGE_CITY3  = 9,
	LARGE_CITY4  = 10,
	HUGE_CITY1   = 11,
	HUGE_CITY2   = 12,
	HUGE_CITY3   = 13,
	HUGE_CITY4   = 14,
	METRO_CITY1  = 15,
	METRO_CITY2  = 16,
	METRO_CITY3  = 17,
	METRO_CITY4  = 18,
	METRO_CITY5  = 19,
}

CitySize = 
{
	VILLAGE     = 1,	
	TOWN        = 2,	
	CITY        = 3,	
	LARGE_CITY  = 4,	
	HUGE_CITY   = 5,
	METROPOLIS  = 6,
}

CityTag = 
{
	NONE        = 0,
	
	--Good: Nothing
	--Bad : No repair, No tax, No harvest
	SIEGE       = 1,
	
	--Nomad / Barbarian invade
	--Good: Soldier Quality
    --Bad : War Fearness 
	FRONTIER    = 10,
	
	--Adjacent to enemy
	--Good:
	--Bad : War weariness
	BATTLEFRONT = 11,
	
	--Adjacent Power of other group is higher
	INDANGER    = 12,
	
	--Military Power is less than required power
	WEAK        = 13,

	--Place need gather troops
	--Condition : 
	IMPORTANCE  = 14,

	--Attributes leads, like economic center, agriculture center
	--Condition : 
	CENTER      = 15,
	
	--Economic is well
	--Good: More tax
    --Bad : Breed corruption
	PROSPERITY  = 20,
	
	--Economic is bad
	--Good: 
	--Bad : Less Tax
	DEPRESSED   = 21,

	--Good:
	--Bad : Lose Trust
	BANKRUPT    = 22,
	
	--Supply not enough
    --Bad : People died, troop power down
	STARVATION  = 30,
	
	--Bad : People become refugee
	DESTRUCTION = 31,
	
	--Bad : Cann't [LevyTax]
	DISSATISFIED = 32,
	
	MAX_VALUE = 
	{
		SIEGE       = 3,
		FRONTIER    = 1,
		BATTLEFRONT = 1,
		PROSPERITY  = 3,
		DEPRESSED   = 3,
		BANKRUPT    = 3,
		STARVATION  = 10,
		DESTRUCTION = 3,
		DISSATISFIED = 10,
	},
}

CityParams = 
{
	CITY_TAX_RESERVE_RATE = 0.3,
	
	SAFETY_TROOP_MAINTAIN_TIME      = 90,
	
	SAFETY_FOOD_CONSUME_TIME        = 180,
	
	--Chara Limition
	MAX_CHARA_LIMIT                    = 20,
	CAPITAL_EXTRA_CHARA_LIMIT          = 5,	
	FRONTIER_EXTRA_CHARA_LIMIT         = 3,
	IMPORTANCE_EXTRA_CHARA_LIMIT       = 3,
	
	--Chara Requiration
	CAPITAL_MIN_CHARA_REQUIREMENT      = 3,
	FRONTIER_MIN_CHARA_REQUIREMENT     = 2,
	IMPORTANCE_MIN_CHARA_REQUIREMENT   = 2,
	NONCAPITAL_MIN_CHARA_REQUIREMENT   = 1,
	
	--Corps
	CAPITAL_EXTRA_CORPS_REQUIREMENT    = 2,		
	
	-----------------------------	
	
	FOOD = 
	{
		FOOD_CORRUPTION_MODULUS         = 0.015,
		NONGROUP_CITY_FOODRESERVE_TIMES = 24,
		STANDARD_FOODRESERVE_TIMES      = 36,
	},
	
	LEVY_TAX = 
	{
		LEVY_TAX_TIME = { 1, 4, 7, 11, },	
	},
	
	HARVEST = 
	{
		HARVEST_TIME        = { 7 },
		HARVEST_CYCLE_TIME  = 12,
	},
	
	MILITARY = 
	{
		INDANGER_ADJACENT_MINPOWER_MODULUS   = 0.65,
		INDANGER_ADJACENT_MAXPOWER_MODULUS   = 5,
		INDANGER_ADJACENT_TOTALPOWER_MODULUS = 10,
		INDANGER_ADJACENT_AVERAGEPOWER_MODULUS = 2,
		
		--Very important, affect how many solider the city required.
		REQUIRE_MILITARYPOWER_LIMITATION_MODULUS   = 10,
		SAFETY_MILITARYPOWER_PER_PLOT      = 100,
		SECURITY_MILITARYPOWER_PER_PLOT    = 200,
		IMPORTANCE_MILITARYPOWER_PER_PLOT  = 200,
		FRONTIER_MILITARYPOWER_PER_PLOT    = 300,
		BATTLEFRONT_MILITARYPOWER_PER_PLOT = 300,
		SAFETY_ADJACENT_SINGLE_MILITARY_POWER_RATE = 0.5,
		SAFETY_ADJACENT_TOTAL_MILITARY_POWER_RATE  = 0.35,
	},
	
	POPULATION = 
	{
		STARVATION_DECREASE_MODULUS = 0.001,
		STARVATION_DEAD_MODULUS     = 0.05,
	},	
	
	-----------------------------
	
	FARM = 
	{
		STANDARD_MODULUS = 0.04,
		MINIMUM_MODULUS  = 0.1,
		MAXIMUM_MODULUS  = 0.2,
	},	
	
	INVEST = 
	{
		MONEY_PER_PLOT   = 1000,
		STANDARD_MODULUS = 0.04,
		MINIMUM_MODULUS  = 0.1,
		MAXIMUM_MODULUS  = 0.2,
	},
	
	PATROL = 
	{
		MINIMUM_EFFECT  = 1,
		MAXIMUM_EFFECT  = 3,
	},
	
	ECONOMY = 
	{
		INCOME_PER_MODULUS_UNIT       = 1,
		INCOME_POPULATION_MODULUS     = 0.1,
	},
		
	-----------------------------	
}

----------------------------------------
-- Combat
--Combat Damage Bonus Table
DamageBonusTable = {
	--------------- Normal, Pierce, Siege,   Fire
	--NONE Armor
	[0]          = { 100,   150,     150,    200 },
	 
	--LIGHT Armor
	[1]          = { 100,   200,     100,     80 },
	
	--Medium Armor
	[2]          = { 150,   100,     100,    120 },
	
	--Heavy Armor
	[3]          = {  80,    50,     150,    150 },
	
	--FORTIFIED Armor
	[4]          = {  70,    50,     200,     20 },
	
	--WOODEN Armor
	[5]          = { 100,    80,     100,    200 },
}

--------------------------------
-- Group Relative

GroupParams = 
{
	RECRUIT = 
	{
		--Determine the number of soldier when recruit an new troop
		RECRUIT_NUMBER_MODULUS = 0.8,

		RECRUIT_NEED_SECURITY  = 20,
	},
}

GroupMeetingSlot =
{
	[0] =
	{
		TECH             = 1,
		DIPLOMACY        = 2,
		INTERNAL_AFFAIRS = 2,
		HUMAN_RESOURCE   = 2,
		WAR_PREPAREDNESS = 2,
		MILITARY         = 1,
	},
}

GroupGovernment = 
{
	------------------------------------
	-- Comment     : Fallen	
	NONE          = 0,

	------------------------------------
	-- Comment     : 
	-- Destruction : Lose Capital
	-- Order       : No limited
	-- Purpose     : Survive / Power
	-- Belong      : Empire
	-- Special     : 
	-- Condition   : Control 5% Territory in the continent
	-- Leader      : Hereditary ( Leader dead )
	KINGDOM       = 1,
	
	------------------------------------
	-- Comment     : 
	-- Destruction : Lose Capital
	-- Order       : No limited
	-- Purpose     : Conquer
	-- Belong      : Empire
	-- Special     :
	-- Condition   : Control 35% Territory in the continent
	--               Military Rank At least 3rd
	-- Leader      : Hereditary ( Leader dead )
	EMPIRE        = 2,
		
	------------------------------------
	-- Comment     : Independent / Economic / Military Region
	-- Destruction : Lose all cities
	-- Order       : No technological, 
	-- Purpose     : Power / Survive
	-- Belong      : None / Kingdom / Empire
	-- Special     : 
	-- Condition   : Has Capital( At least City )
	-- Leader      : ENFEOFF ( None Leader ) / Hereditary ( Leader dead )
	REGION        = 3,
	
	------------------------------------
	-- Comment     : Sometime like Horde 
	-- Destruction : Lose capital
	-- Order       : No technological, economic, political
	-- Purpose     : Survive
	-- Belong      : Region / Kingdom / Empire
	-- Special     : Character can join only by event
	-- Condition   : Has Capital( Town / village )
	FAMILY        = 4,
	
	------------------------------------
	-- Comment     : 
	-- Destruction : Change government
	-- Order       : No technological, economic, political order
	-- Purpose     : Independent
	-- Belong      : 
	-- Special     : Won't be destroyed
	-- Condition   : Event Occur
	GUERRILLA     = 5,
		
	------------------------------------
	-- Comment     : Modern goverment
	-- Destruction : Lose 75% percent territory
	-- Order       : No limited
	-- Purpose     : Power
	-- Belong      : None
	-- Special     : 
	-- Leader      : Election ( Leader dead / Term end )
	NATION        = 6,
	
	------------------------------------
	-- Comment     : Belong to Indenpendce goverment
	-- Destruction : Lose all cities
	-- Order       : No limited
	-- Purpose     : Short term goal
	-- Belong      : None
	-- Special     : 
	-- Leader      : Election ( Leader dead / Term end )
	WARZONE       = 7,
}

GroupPower =
{
	TOTAL_POWER         = 0,	
	MILITARY_POWER      = 1,	
	ECONOMIC_POWER      = 2,	
	TECHNOLOGICAL_POWER = 3,
	DIPLOMATIC_POWER    = 4,	
	POLITICAL_POWER     = 5,
}

GroupTag = 
{
	REPUTATION   = 1,
	
	-- Always declare war at first
	MILITANT     = 2,
	
	-- Break any contract
	BETRAYER     = 3,

	-- Peace Walker, Always try to avoid war
	--PEACE_WALKER = 3,
	
	SITUATION = 
	{
		--Relation
		MULTIPLE_FRONT = 100,
		AT_WAR         = 101,
		
		--Growth
		UNDEVELOPED = 110,
		PROSPEROUS  = 111,
		
		--Power
		WEAK        = 120,
		STRONG      = 121,		
		
		--Tech
		PRIMITIVE   = 130,
		ADVANCED    = 131,
		
		--HR_AFFAIRS
		UNDERSTAFFED = 140,
		
		--Military
		AGGRESSIVE   = 150,
	},
}

GroupGoalCategory = 
{
	FINAL_GOAL     = 1,
	
	SHORTTERM_GOAL = 2,
}

GroupGoal = 
{
	-- Never win
	NONE          = 0,
	
	--------------------------
	-- Final goal
	
	--Control percent of City( Only city of vassal can be counted )
	DOMINATION_TERRIORITY = 10,
	DOMINATION_CITY       = 11,
	--DOMINATION_PLOT       = 12,
	--Power is over than special percent number
	POWER_LEADING         = 20,
	
	--------------------------
	-- Short term goal
	SHORT_TERM_GOAL   = 100,
	--
	SURVIVIVAL        = 100,
	--
	INDEPENDENCE      = 101,
	--Control special city
	OCCUPY_CITY       = 110,
	
	
	--[[
		--Divide goal to final goal and short team goal two kinds.
		--Short team goal will determine every year, gropu can gain lots bonus after finished it in a year.		
	--Final Goal
	DOMINATION_GOAL    = 10,
	LEADING_GOAL       = 20,
	
	--Short Goal	
	SURVIVAL_GOAL      = 100,
	
	----------------------------------
	-- Domination	
	DOMINATION_GOAL_BEG  = 20,	
	-- own special city
	OCCUPY          = 20,
	-- conpercent of the territory in the continent which the capital stays
	CONQUER         = 21,
	DOMINATION_GOAL_END  = 29,		
	----------------------------------
	-- Leading
	LEADING_GOAL_BEG = 30,	
	-- Tech, Economic, Troops, Terriority at least rank [value]
	MILITARY_POWER   = 31,
	LEADING_GOAL_END = 39,		
	-- Extension maybe economic or anything else
	
	----------------------------------	
	-- Survival	
	SURVIVAL_GOAL_BEG  = 10,		
	-- Survive for specific time.
	SURVIVE            = 10,
	-- Avoid becoming slave group for specific time
	INDEPENDENT        = 11,	
	SURVIVAL_GOAL_END  = 19,		
	]]
}

GroupGoalDiplomacyEffect =
{
	SURVIVAL_GOAL   = { SURVIVAL_GOAL =  0.02, DOMINATION_GOAL = -0.02, LEADING_GOAL = -0.02 }, 
	DOMINATION_GOAL = { SURVIVAL_GOAL = -0.02, DOMINATION_GOAL = -0.04, LEADING_GOAL = -0.03 }, 
	LEADING_GOAL    = { SURVIVAL_GOAL = -0.02, DOMINATION_GOAL = -0.03, LEADING_GOAL = -0.04 }, 
}

GroupRelationDiplomacyEffect = 
{
	--UNKNOWN
	[0] = 0,
	--NEUTRAL
	[1] = 0,
	--VASSAL
	[2] = 0.03,
	--DEPENDENCE
	[3] = 0.02,
	--ALLIANCE
	[4] = 0.02,
	--FRIEND
	[5] = 0.01,
	--HOSTILITY
	[6] = -0.01,
	--ENEMY
	[7] = -0.02,
	--TRUCE
	[8] = 0,
	--BELLIGERENT
	[9] = -0.04,
}

--------------------------------
-- City

CityType = 
{
	CITY  = 1,	
	FIELD = 2,	
	PASS  = 3,
}

CityInstruction =
{
	NONE             = 0,
	CITY_DEVELOP     = 1,
	WAR_PREPAREDNESS = 2,
	ATTACK           = 3,
}

--------------------------------
-- Group relation

GroupRelationType = 
{
	UNKNOWN      = 0,
	NEUTRAL      = 1,
	VASSAL       = 2,	
	DEPENDENCE   = 3,	
	ALLIANCE     = 4,	
	FRIEND       = 5,
	HOSTILITY    = 6,
	ENEMY        = 7,
	TRUCE        = 8,
	BELLIGERENT  = 9,
}

DiplomacyMethod = 
{
	NONE           = 0,	
	FRIENDLY       = 1,	
	THREATEN       = 2,	
	ALLY           = 3,	
	DECLARE_WAR    = 4,	
	MAKE_PEACE     = 5,	
	BREAK_CONTRACT = 6,	
	SURRENDER      = 7,	
	METHOD_END     = 8,
	--extension
	SEPARATE       = 100,
}

GroupTendency = 
{	
	RATIONAL        = 1,
	
	SURVIVE         = 2,
	
	CONSERVATIVE    = 3,
	
	AGGRESSIVE      = 4,
	
	INSANE          = 5,
}

DiplomacyTendency = 
{
	--RATIONAL
	[1] =
	{
		MAKEPEACE_NUMBER_BELLIGERENT = 2,
		MAKEPEACE_BELLIGERENT_DAYS   = 180,
		MAKEPEACE_POWER_RATIO        = 0.5,
		
		FRIENDLY_HOSTILITY_RATIO     = 2.5,
	},
	
	--SURVIVE
	[2] =
	{
		MAKEPEACE_NUMBER_BELLIGERENT = 1,

		MAKEPEACE_BELLIGERENT_DAYS   = 90,
		MAKEPEACE_POWER_RATIO        = 1.5,
		
		FRIENDLY_HOSTILITY_RATIO     = 1.5,
	},
	
	--CONSERVATIVE
	[3] =
	{
		MAKEPEACE_NUMBER_BELLIGERENT = 2,
		MAKEPEACE_BELLIGERENT_DAYS   = 360,
		MAKEPEACE_POWER_RATIO        = 2,
		
		FRIENDLY_HOSTILITY_RATIO     = 2,
	},
	
	--AGGRESSIVE
	[4] =
	{
		MAKEPEACE_NUMBER_BELLIGERENT = 3,
		MAKEPEACE_BELLIGERENT_DAYS   = 720,
		MAKEPEACE_POWER_RATIO        = 2.5,
		
		FRIENDLY_HOSTILITY_RATIO     = 5,
	},
	
	--INSANE
	[5] =
	{
		MAKEPEACE_NUMBER_BELLIGERENT = 4,
		MAKEPEACE_BELLIGERENT_DAYS   = 1080,
		MAKEPEACE_POWER_RATIO        = 6,
		
		FRIENDLY_HOSTILITY_RATIO     = 6,
	},
}

GroupRelationDetail = 
{
	------------------------
	-- Flag Category
	LAST_TARGET           = 1,	
	-- Kill leader of group or event leads
	OLD_ENEMY             = 2,
    -- Threaten or event leads, ignore militant penalty
	CASUS_BELLI           = 3,		
	-- Break contract or sth. else?
	BETRAYER              = 4,	
	-- Refused the proposal in last diplomacy meeting
	DECLINATURE           = 5,	
	-- In law
	IN_LAW                = 6,
	-- Who declared the war first.
	WAR_DECLARER          = 7,
	
	------------------------
	-- Evaluation Category		
	-- Measure the hostility between two groups
	HOSTILITY_LEVEL       = 10,
	
	------------------------
	-- Time Category	
	-- 
	BELLIGERENT_DURATION  = 20,
	
	-- Truce time remains
	TRUCE_TIME_REMAINS    = 21,
	
	TRUCE_TIME_DURATION   = 22,
	
	-- Alliance time remains
	ALLIANCE_TIME_REMAINS = 23,
	
	-- event leads, effects determined in the future
	IN_LAW_REMAINS        = 24,	
}

GroupRelationParam = 
{
	DEFAULT_TRUCE_DAY    = 180,
	
	DEFAULT_ALLIANCE_DAY = 720,
	
	--Detail
	MAX_DETAIL_VALUE = 
	{
		OLD_ENEMY       = 5,
		CASUS_BELLI     = 5,
		BETRAYER        = 5,
		DECLINATURE     = 5,
		IN_LAW          = 3,
		HOSTILITY_LEVEL = 5,
	},
	
	--Tag
	MAX_TAG_VALUE =
	{
		--militant
		[1] = 3,
		
		--betrayer
		[2] = 3,
	},	
	METHOD_MOD = 
	{
		MAX_SINGLE_MOD = 10,
		
		ALLY = 
		{
			POWER_MODULUS = 6500,
			DETAIL_MODULUS =
			{
				LAST_TARGET     = 0,
				OLD_ENEMY       = -0.5,
				CASUS_BELLI     = 0,
				BETRAYER        = -0.25,
				DECLINATURE     = -0.25,
				IN_LAW          = 0.5,
				HOSTILITY_LEVEL = -0.25,
			},
			SELF_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = 0,
			},
			TARGET_TAG_MODULUS = 
			{
				MILITANT     = -0.25,
				BETRAYER     = 0,
			},
			FRIEND_BELLIGERENT     = -1,
			TARGET_MULTIPLE_FRONTS = 1,
			SELF_MULTIPLE_FRONTS   = 1.5,
			DISTANCE = 2,
		},
		MAKE_PEACE = 
		{
			POWER_MODULUS = 10000,
			DETAIL_MODULUS =
			{
				LAST_TARGET     = 0,
				OLD_ENEMY       = -0.25,
				CASUS_BELLI     = 0,
				BETRAYER        = -0.2,
				DECLINATURE     = 0,
				IN_LAW          = 0.25,
				HOSTILITY_LEVEL = -0.1,
			},
			SELF_TAG_MODULUS = 
			{
				MILITANT     = -0.2,
				BETRAYER     = 0.2,
			},
			TARGET_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = -0.2,
			},
			FRIEND_BELLIGERENT     = -1,
			TARGET_MULTIPLE_FRONTS = -1,
			SELF_MULTIPLE_FRONTS   = 2,
			DISTANCE = 2,
		},
		FRIENDLY = 
		{
			POWER_MODULUS = 3500,
			[1] = 2,  --NEUTRAL	
			[3] = 1,  --DEPENDENCE			
			[4] = 2,  --ALLIANCE			
			[5] = 3,  --FRIEND			
			[6] = -3, --HOSTILITY			
			[7] = -4, --ENEMY
			DETAIL_MODULUS =
			{
				LAST_TARGET     = 0,
				OLD_ENEMY       = -0.35,
				CASUS_BELLI     = 0,
				BETRAYER        = 0,
				DECLINATURE     = 0,
				IN_LAW          = 0,
				HOSTILITY_LEVEL = -0.25,
			},
			SELF_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = 0,
			},
			TARGET_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = 0,
			},
			SAME_ENEMY             = 3,
			FRIEND_BELLIGERENT     = -1,
			TARGET_MULTIPLE_FRONTS = 0,
			SELF_MULTIPLE_FRONTS   = 1,			
			SELF_IS_DEPENDENCY     = -3,
			DISTANCE   = 0,
			SELF_GOALS = 
			{
				SURVIVAL    = 3,
				DOMINATION  = 1,
				LEADING     = 1,
			},
			TARGET_GOALS = 
			{
				SURVIVAL    = 2,
				DOMINATION  = 0,
				LEADING     = 0,
			},
		},
		THREATEN =
		{
			POWER_PENALTY_MODULUS = 20000,
			NATIVE_POWER_MODULUS = 5000,
			--POWER_MODULUS = 10000,
			[3] = -3,  --DEPENDENCE	
			[5] = -1,  --FRIEND
			[6] = -2, --HOSTILITY			
			[7] = -3, --ENEMY	
			[9] = -4, --BELLIGERENT
			DETAIL_MODULUS =
			{
				LAST_TARGET     = 0,
				OLD_ENEMY       = -0.35,
				CASUS_BELLI     = 0,
				BETRAYER        = 0,
				DECLINATURE     = -0.25,
				IN_LAW          = 0,
				HOSTILITY_LEVEL = 0,
			},
			SELF_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = 0,
			},
			TARGET_TAG_MODULUS = 
			{
				MILITANT     = -0.15,
				BETRAYER     = 0,
			},
			TARGET_MULTIPLE_FRONTS   = 2,
			SELF_MULTIPLE_FRONTS     = -1.5,
			DISTANCE                 = -10,
			SELF_GOALS = 
			{
				SURVIVAL    = -2,
				DOMINATION  = 1,
				LEADING     = 1,
			},
			TARGET_GOALS = 
			{
				SURVIVAL    = 3,
				DOMINATION  = -3,
				LEADING     = -3,
			},
		},		
		SURRENDER =
		{
			POWER_PENALTY_MODULUS = -10000,
			POWER_MODULUS = -5000,
			[1] = -2, 	--NEUTRAL
			[5] = -3,	--FRIEND			
			[6] = -1,   --HOSTILITY			
			[7] = 1, 	--ENEMY
			[8] = 0, 	--TRUCE
			[9] = 2,    --BELLIGERENT
			DETAIL_MODULUS =
			{
				LAST_TARGET     = 0,
				OLD_ENEMY       = -0.35,
				CASUS_BELLI     = 0,
				BETRAYER        = 0,
				DECLINATURE     = -0.2,
				IN_LAW          = 0,
				HOSTILITY_LEVEL = -0.2,
			},
			SELF_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = -0.15,
			},
			TARGET_TAG_MODULUS = 
			{
				MILITANT     = -0.15,
				BETRAYER     = 0,
			},
			FRIEND_BELLIGERENT       = -1,
			TARGET_MULTIPLE_FRONTS   = -3,
			SELF_MULTIPLE_FRONTS     = 1,
			DISTANCE                 = -5,
			SELF_GOALS =
			{
				SURVIVAL    = 3,
				DOMINATION  = -4,
				LEADING     = -1,
				INDEPENDENT = -4,
			},
			TARGET_GOALS = 
			{
				SURVIVAL    = -2,
				DOMINATION  = 1,
				LEADING     = 1,
			},
		},
		DECLARE_WAR =
		{
			POWER_PENALTY_MODULUS = 20000,
			POWER_MODULUS = 6000,
			[1] = -2, 	--NEUTRAL		
			[5] = -4, 	--FRIEND			
			[6] = 3, 	--HOSTILITY			
			[7] = 5, 	--ENEMY		
			DETAIL_MODULUS =
			{
				LAST_TARGET     = 0,
				OLD_ENEMY       = 0.5,
				CASUS_BELLI     = 0.5,
				BETRAYER        = 0,
				DECLINATURE     = 0.25,
				IN_LAW          = 0,
				HOSTILITY_LEVEL = 0.2,
			},
			SELF_TAG_MODULUS = 
			{
				MILITANT     = 0.2,
				BETRAYER     = 0,
			},
			TARGET_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = 0,
			},
			FRIEND_BELLIGERENT     = 1,
			TARGET_MULTIPLE_FRONTS = 1,			
			SELF_MULTIPLE_FRONTS   = -2.5,
			DISTANCE               = -8,
			SELF_GOALS =
			{
				SURVIVAL    = -2,
				DOMINATION  = 4,
				LEADING     = 2,
				INDEPENDENT = -2,
			},
			TARGET_GOALS = 
			{
				SURVIVAL    = 1,
				DOMINATION  = 1,
				LEADING     = 1,
				INDEPENDENT = -1,
			},
		},
		BREAK_CONTRACT =
		{
			POWER_PENALTY_MODULUS = 5000,
			POWER_MODULUS = 8000,
			[2] = -3, --VASSAL
			[3] = -2, --DEPENDENCE
			[4] = -6, --ALLIANCE
			[8] = -5, --TRUCE
			DETAIL_MODULUS =
			{
				LAST_TARGET     = 0,
				OLD_ENEMY       = 0.25,
				CASUS_BELLI     = 0,
				BETRAYER        = 0.15,
				DECLINATURE     = 0,
				IN_LAW          = 0,
				HOSTILITY_LEVEL = 0.1,
			},
			SELF_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = 0.1,
			},
			TARGET_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = 0,
			},
			FRIEND_BELLIGERENT     = 1,
			TARGET_MULTIPLE_FRONTS = 1,	
			SELF_MULTIPLE_FRONTS   = -2,
			DISTANCE               = -5,
			SELF_GOALS = 
			{
				SURVIVAL     = -3,
				DOMINATION   = 0,
				LEADING      = 0,
			},
			TARGET_GOALS =
			{
				SURVIVAL     = -2,
				DOMINATION   = -1,
				LEADING      = -1,
				INDEPENDENT  = -3,
			},
		},
		SEPARATE =
		{
			POWER_PENALTY_MODULUS = 10000,
			POWER_MODULUS = 8000,
			[2] = 4, --VASSAL
			[3] = 2, --DEPENDENCE
			DETAIL_MODULUS =
			{
				LAST_TARGET     = 0,
				OLD_ENEMY       = 0.35,
				CASUS_BELLI     = 0,
				BETRAYER        = 0.2,
				DECLINATURE     = 0,
				IN_LAW          = 0,
				HOSTILITY_LEVEL = 0.15,
			},
			SELF_TAG_MODULUS = 
			{
				MILITANT     = 0,
				BETRAYER     = 0,
			},
			TARGET_TAG_MODULUS = 
			{
				MILITANT     = -1,
				BETRAYER     = 0,
			},
			FRIEND_BELLIGERENT     = 1,
			TARGET_MULTIPLE_FRONTS = 1,	
			SELF_MULTIPLE_FRONTS   = -2,
			DISTANCE               = 4,
			SELF_GOALS = 
			{
				SURVIVAL     = -3,
				DOMINATION   = 2,
				LEADING      = 2,
				INDEPENDENT  = 2,
			},
			TARGET_GOALS =
			{
				SURVIVAL     = 2,
				DOMINATION   = -2,
				LEADING      = -2,
			},
		}
	},
	
	--Diplomatic
	DIPLOMATIC_BONUS         = 500,

	--Evaluation
	MIN_EVALUATION           = -500,	
	MAX_EVALUATION           = 500,
	STANDARD_EVALUATION      = 0,
	EVALUATION_RANGE         = 1000,
	
	--Deteriorate
	LEAVE_DETERIORATE        = 10,	
	
	--Friendly
	FRIENDLY_IMPROVE             = 200,	
	
	--threaten
	THREATEN_DETERIORATE_RATIO   = 0.35,
	
	---------------------------
	--make peace
	MAKE_PEACE_DAYS_PROB_MOD     = -900,
	
	MAKE_PEACE_DAYS_POW_MODULUS  = 10,
	MAKE_PEACE_BELLIGERENT_TIME  = 180,	
	MAKE_PEACE_PROFIT_NEED       = 10000,
	MAKE_PEACE_PROFIT_MODULUS    = 0.35,
	MAKE_PEACE_DECLARER_PENALTY  = -6000,
	
	--Declare war
	DECLARE_WAR_PROFIT_NEED      = 10000,
	DECLARE_WAR_PROFIT_MODULUS   = 0.1,
	
	DECLARE_WAR_TRUCE_DURATION_MODULUS = 1,
}

-----------------------------------

--Character Trait Effect Type
TraitEffectType = 
{
	--Used to be placeholder for character's trait
	NONE,

	----------------------------
	-- Activate
	----------------------------
	--Recover morale immediately
	ENCOURAGE_MORALE    = 100,
	
	--Reduce opponent's morale immediately.
	REDUCE_MORALE       = 101,
	
	NIGHT_ATTACK        = 110,
	
	BLUFF               = 120,
	
	----------------------------
	-- Addition or Reduction
	----------------------------	
	-- damage addition value% when attack enemy
	DAMAGE_ADDITION     = 200,	
	-- damage reduction value% when attacked by enemy
	DAMAGE_REDUCTION    = 201,
	
	-- damage addition value% when lead the special category troop
	TROOP_MASTER        = 210,	
	-- damage reduction value% when attacked by the special category troop
	TROOP_RESIST        = 211,
	
	-- fatigue penalty decrease value% when attack
	-- fatigue penalty decrease value% when defend
	SKILL_MASTER        = 220,	
	-- fatigue penalty increase value% when attack
	-- fatigue penalty increase value% when defend
	SKILL_DULL          = 221,
	
	-- fatigue penalty decrease value% when move
	STAMINA_MASTER      = 230,	
	-- fatigue penalty increase value% when move
	STAMINA_LACK        = 231,
		
	-- movement addition
	MOVEMENT_ADDITION   = 240,	
	-- movement reduction
	MOVEMENT_REDUCTION  = 241,
	
	-- morale addition when restore or lost
	MORALE_ADDITION     = 240,	
	-- morale reduction when restore or lost
	MORALE_REDUCTION    = 241,
	
	-- Decrease weather penalty value%
	WEATHER_ADAPTION    = 250,
	-- Increase weather penalty value%
	WEATHER_MALADAPTION = 251,
	
	----------------------------
	-- Passive
	----------------------------	
	-- suffer damage value% when friendly been hit
	GUARDIAN_FORTIFIED  = 300,
	
	-- suffer damage value% when friendly been hit
	GUARDIAN_FRIENDLY   = 301,
	
	-- climb wall with ladder?
	SIEGE_ATTACK        = 310,
	
	-- unsupported
	-- increase wounded number been healed
	MEDIC               = 320,
	
	----------------------------
	-- Diplomatic
	----------------------------
	DIPLOMACY_SUCCESS_PROB   = 400,
	
	DIPLOMACY_FRIENDLY_BONUS = 401,
}


---------------------------------
-- Character

CharacterType = 
{
	HISTRORIC = 1,
	FICTIONAL = 2,
}

CharacterStatus = 
{
	--Appear in the game
	NORMAL     = 0,
	--Not join any group
	OUT        = 1,
	--Not appear in the game, means it's deactivate
	NOT_APPEAR = 2,
	--Appeared in the game, it's deactivate now
	LEAVE      = 3,
	--Appeared in the game, it's dead
	DEAD       = 4,
	--Captured in war, reserved
	PRISONER   = 5,
}

CharacterGoal = 
{
	NONE          = 0,
	
	SURVIVE,
	
	INDEPENDENT,
	
	DOMINATE,
	
	CONQUER,
	
	POWER,
	
	-- Extension
	THRONE,
}

CharacterAction =
{
	NONE           = 0,
	
	--Personal
	ATTEND_MEETING = 100,
	ENJOY_SELF     = 101,	
	HAVE_REST      = 102,
	
	--Job 
	INTERNAL_AFFAIS = 200,	
	INVEST          = 201,
	LEVY_TAX        = 202,
}

CharacterJob = 
{
	NONE              = 0,
	
	LOW_RANK_JOB      = 100,	
	OFFICER           = 101,
	CIVIAL_OFFICIAL   = 102,
	MILITARY_OFFICER  = 103,
	
	SPY               = 120,
	TRADER            = 130,
	BUILDER           = 140,
	MISSIONARY        = 150,
		
	HIGH_RANK_JOB     = 200,
	ASSISTANT_MINISTER= 201,
	DIPLOMATIC        = 202,
	GENERAL           = 210,
	CAPTAIN           = 211,
	AGENT             = 220,	
	MERCHANT          = 230,
	TECHNICIAN        = 240,
	APOSTLE           = 250,
		
	IMPORTANT_JOB     = 300,	
	PREMIER           = 301,
	MAYOR             = 302,
	CABINET_MINISTER  = 302,
	MARSHAL           = 310,
	ADMIRAL           = 311,
	SPYMASTER         = 320,
	ASSASSIN          = 321,
	MONOPOLY          = 330,
	SCIENTIST         = 340,
	INQUISITOR        = 350,
	
	LEADER_JOB        = 400,
	EMPEROR           = 401,	--Empire
	KING              = 402,	--Kindom
	LORD              = 403,	--Region
	LEADER            = 404,	--Guerrilla
	CHIEF             = 405,	--Family
	PRESIDENT         = 406,    --Nation
}

CharacterProposal =
{
	NONE             = 0,
	
	-- Personal
	CHARA_BACKHOME   = 1,
	CORPS_MOVETO     = 2,
	TROOP_MOVETO     = 3,
	
	AFFAIRS_PROPOSAL = 10,
	
	-- Lord
	INSTRUCT_AFFAIRS = 10,
	CITY_INSTRUCT    = 11,
	CORPS_INSTRUCT   = 12,
	INSTRUCT_AFFAIRS_END = 19,
	
	-- Tech
	TECH_AFFAIRS     = 20,
	TECH_RESEARCH    = 21,
	TECH_AFFAIRS_END = 29,
	
	-- City relative	
	CITY_AFFAIRS     = 30,
	CITY_INVEST      = 31,	
	CITY_LEVY_TAX    = 32,
	CITY_BUILD       = 33,
	CITY_INSTRUCT    = 34,
	CITY_PATROL      = 35,
	CITY_FARM        = 36,
	CITY_AFFAIRS_END = 39,
	
	-- Human resource	
	HR_AFFAIRS       = 40,
	HR_DISPATCH      = 41,	
	HR_CALL          = 42,
	HR_HIRE          = 43,
	HR_EXILE         = 44,
	HR_PROMOTE       = 45,--Need AI
	HR_BONUS         = 46,--Need implement
	HR_LOOKFORTALENT = 47,
    HR_AFFAIRS_END   = 49,
	
	-- War preparedness	
	WAR_PREPAREDNESS_AFFAIRS = 50,
	RECRUIT_TROOP    = 51,
	LEAD_TROOP       = 52,
	ESTABLISH_CORPS  = 53,	
	REINFORCE_CORPS  = 54,
	REGROUP_CORPS    = 55,
	TRAIN_CORPS      = 56,
	CONSCRIPT_TROOP  = 57,--Need implement
	WAR_PREPAREDNESS_AFFAIRS_END = 59,
	
	-- Military
	MILITARY_AFFAIRS = 60,
	ATTACK_CITY      = 61,
	EXPEDITION       = 62,
	CONTROL_PLOT     = 63,--Need AI
	DISPATCH_CORPS   = 64,
	SIEGE_CITY       = 65,
	MEET_ATTACK      = 66,
	MILITARY_AFFAIRS_END = 69,

	-- Diplomacy
	DIPLOMACY_AFFAIRS        = 70,
	FRIENDLY_DIPLOMACY       = 71,
	THREATEN_DIPLOMACY       = 72,
	ALLY_DIPLOMACY           = 73,	
	MAKE_PEACE_DIPLOMACY     = 74,
	DECLARE_WAR_DIPLOMACY    = 75,
	BREAK_CONTRACT_DIPLOMACY = 76,
	SURRENDER_DIPLOMACY      = 77,
	DIPLOMACY_AFFAIRS_END    = 79,
	
	--Intelligence
	
	------------------------------
	
	PROPOSAL_COMMAND    = 200,
	
	-- AI Relative	
	AI_COLLECT_PROPOSAL = 201,
	AI_SUBMIT_PROPOSAL  = 202,
	AI_SELECT_PROPOSAL  = 203,
	
	-- Player Choice	
	PLAYER_EXECUTE_PROPOSAL = 300,	
	PLAYER_GIVEUP_PROPOSAL  = 301,
	PLAYER_ENTRUST_PROPOSAL = 302,
	
	NEXT_TOPIC              = 310,
	END_MEETING             = 311,
}

CharacterParams =
{
	ATTRIBUTE = 
	{
		MAX_SATISFACTION = 250,
		MAX_AP           = 250,
		MAX_TRUST        = 250,	
		MAX_CONTRIBUTION = 10000,	
		
		LOW_TRUST        = 50,
		LOW_CONTRIBUTION = 100,
	},

	TRAIT = 
	{
		TRAIT_REQUIREMENT_PER_SLOT = 40,
	},
	
	SUBORDINATE_LIMIT = 
	{
		DEFAULT = 10,
		--Emperor
		[400] = 80,
		--King
		[401] = 40,
		--Lord
		[402] = 20,
		--Leader
		[403] = 16,
		--Chief
		[404] = 16,
		--President
		[405] = 40,
	},
	
	PRIVIAGE = 
	{
		[0] = { CITY_AFFAIRS = 1 },		
		--Officer
		[101] = { CITY_AFFAIRS = 1, HR_AFFAIRS = 1, WAR_PREPAREDNESS_AFFAIRS = 1, MILITARY_AFFAIRS = 1 },
		--Civial Official
		[102] = { CITY_AFFAIRS = 1, HR_AFFAIRS = 1, },
		--Military Officer
		[103] = { WAR_PREPAREDNESS_AFFAIRS = 1, MILITARY_AFFAIRS = 1, },
		--Cabinet minister
		[200] = { TECH_RESEARCH = 1, CITY_AFFAIRS = 1, HR_AFFAIRS = 1 },
		--Diplomatic
		[201] = { DIPLOMACY_AFFAIRS = 1, CITY_AFFAIRS = 1 },
		--General
		[210] = { WAR_PREPAREDNESS_AFFAIRS = 1, MILITARY_AFFAIRS = 1, },
		--Captain
		[211] = { WAR_PREPAREDNESS_AFFAIRS = 1, MILITARY_AFFAIRS = 1, },
		
		--Premier
		[301] = { CITY_INSTRUCT = 1, TECH_RESEARCH = 1, CITY_AFFAIRS = 1, HR_AFFAIRS = 1, DIPLOMACY_AFFAIRS = 1, },
		--Mayor
		[302] = { TECH_RESEARCH = 1, CITY_AFFAIRS = 1, HR_AFFAIRS = 1, WAR_PREPAREDNESS_AFFAIRS = 1, MILITARY_AFFAIRS = 1 },
		--Marshal
		[310] = { CORPS_INSTRUCT = 1, TECH_RESEARCH = 1, WAR_PREPAREDNESS_AFFAIRS = 1, MILITARY_AFFAIRS = 1, },
		--Admiral
		[311] = { CORPS_INSTRUCT = 1, TECH_RESEARCH = 1, WAR_PREPAREDNESS_AFFAIRS = 1, MILITARY_AFFAIRS = 1, },
		
		--Group Leader
		[401] = { ALL = 1 },
		[402] = { ALL = 1 },
		[403] = { ALL = 1 },
		[404] = { ALL = 1 },
		[405] = { ALL = 1 },
		[406] = { ALL = 1 },
	},

	JOB_PROMOTION =
	{
		[0] = { 
			limit = 0,
			promotions = {
				{ job = "OFFICER",             contribution = 0 },
				{ job = "MILITARY_OFFICER",    contribution = 0 },
			},
		},
		--OFFICER
		[101] = { 
			limit = 0,
			promotions = {
				{ job = "CIVIAL_OFFICIAL", contribution = 100 },
				{ job = "MILITARY_OFFICER", contribution = 100 },
			},
		},
		--CIVIAL_OFFICIAL
		[102] = {
			limit = 0,
			promotions = {
				{ job = "ASSISTANT_MINISTER", contribution = 1000 },
				{ job = "DIPLOMATIC",       contribution = 1000, trait = {} },				
			},
		},		
		--MILITARY_OFFICER
		[103] = {
			limit = 0,
			promotions = {
				{ job = "GENERAL", contribution = 1000 },
				{ job = "CAPTAIN", contribution = 1000 },
			},
		},
		
		--ASSISTANT_MINISTER
		[201] = {
			limit = 6,
			promotions = {
				{ job = "PREMIER", contribution = 5000 },
				{ job = "MAYOR",   contribution = 3000 },
				{ job = "CABINET_MINISTER",   contribution = 3000 },
			},
		},
		--DIPLOMATIC
		[202] = {
			limit = 3,
			promotions = {
				{ job = "PREMIER", contribution = 5000 },
				{ job = "MAYOR",   contribution = 3000 },
			},
		},
		--GENERAL           = 202,
		[210] = {
			limit = 10,
			promotions = {
				{ job = "MARSHAL", contribution = 5000 },
			},
		},	
		--CAPTAIN
		[211] = {
			limit = 10,
			promotions = {
				{ job = "ADMIRAL", contribution = 4000 },
			},
		},
		
		--PREMIER
		[301] = {
			limit = 1,
		},
		--MAYOR
		[302] = {
			limit = 8,
		},
		--CABINET_MINISTER
		[303] = {
			limit = 6,
		},
		--MARSHAL
		[310] = {
			limit = 1,
		},
		--ADMIRAL
		[311] = {
			limit = 1,
		},
	},

	STAMINA = 
	{
		STANDARD_STAMINA = 100,	
		RESTORE_STAMINA_RATE = 0.35,
		SUBMIT_PROPOSAL  = 35,
		ACCEPT_PROPOSAL  = 25,
		ASSIGN_PROPOSAL  = 10,
		EXECUTE_PROPOSAL = 40,
	},
	
	PROPOSAL_TENDENCY = 
	{
	},
}

CharacterProposalTendency = 
{
	JOB = 
	{
		--Default
		[0] = 
		{
			SUCCESS_CRITERIA = {FRIENDLY=5000, THREATEN=5000, ALLY=5000, DECLARE_WAR=5000, MAKE_PEACE=5000,BREAK_CONTRACT=5000,SURRENDER=5000,},
			PROPOSAL = { TECH=3500,FRIENDLY=3500,THREATEN=3500,ALLY=3500,DECLARE_WAR=3500,MAKE_PEACE=3500,BREAK_CONTRACT=3500,SURRENDER=3500,},
		},		
		--OFFICER
		[10] = 
		{
			SUCCESS_CRITERIA = { DEFAULT=5000, },
			PROPOSAL = { TECH=3000,FRIENDLY=3000,THREATEN=3000,ALLY=4000,DECLARE_WAR=4000,MAKE_PEACE=3000,BREAK_CONTRACT=2000,SURRENDER=3000,},
		},		
		--General
		[11] = 
		{
			SUCCESS_CRITERIA = { DEFAULT=5000, },
			PROPOSAL = { TECH=0,FRIENDLY=2500,THREATEN=5000,ALLY=2500,DECLARE_WAR=5000,MAKE_PEACE=500,BREAK_CONTRACT=2000,SURRENDER=500,},
		},
		--DIPLOMATIC
		[100] = 
		{
			SUCCESS_CRITERIA = { DEFAULT=5000, },
			PROPOSAL = { TECH=0,FRIENDLY=5000,THREATEN=3000,ALLY=4000,DECLARE_WAR=2500,MAKE_PEACE=3500,BREAK_CONTRACT=1500,SURRENDER=2500,},
		},		
		--CABINET_MINISTER
		[101] = 
		{
			SUCCESS_CRITERIA = { DEFAULT=5000, },
			PROPOSAL = { TECH=8000,FRIENDLY=5000,THREATEN=3000,ALLY=4000,DECLARE_WAR=1000,MAKE_PEACE=2000,BREAK_CONTRACT=1500,SURRENDER=1500,},
		},		
		--MARSHAL
		[102] = 
		{
			SUCCESS_CRITERIA = { DEFAULT=5000, },
			PROPOSAL = { TECH=4000,FRIENDLY=3000,THREATEN=6000,ALLY=3000,DECLARE_WAR=5000,MAKE_PEACE=0,BREAK_CONTRACT=2500,SURRENDER=0,},			
		},
		[402] =
		{
			SUCCESS_CRITERIA = { DEFAULT=5000, },
			PROPOSAL = { TECH=4000,FRIENDLY=3000,THREATEN=6000,ALLY=3000,DECLARE_WAR=5000,MAKE_PEACE=0,BREAK_CONTRACT=2500,SURRENDER=0,},			
		}
	},
}