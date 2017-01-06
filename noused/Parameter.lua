----------------------------------
--
--
Parameter = 
{
	------------------------------------------
	-- 
	MIN_CHARA_IN_CAPITAL               = 3,
	
	MIN_CHARA_IN_CAPITAL_PERCENT       = 0.35,

	------------------------------------------
	-- City Internal Affairs Relative
	
	SAFETY_CITY_SUPPLY_CONSUME_RATIO   = 0.6,

	SAFETY_CITY_ECONOMY_RATIO          = 0.6,	
	
	SAFETY_CITY_MILITARY_POWER         = { 500, 2000, 5000, 10000, 50000, 200000 },
	
	SAFETY_CITY_CULTURE_POWER          = { 0, 100, 150, 250, 400, 1000 },
	
	CITY_SIZE_POPULATION               = { 1000, 20000, 200000, 500000, 1000000, 5000000 },
		
	------------------------------------------
	-- City Invest order relative
	CITY_INVEST_MONEY                  = { 100, 500, 1000, 2000, 5000, 10000, 20000 },
	
	CITY_INVEST_IMPROVE_PERCENT_MIN    = 3,
	
	CITY_INVEST_IMPROVE_PERCENT_MAX    = 8,
	
	CITY_DECAY_PROB                    = 2500,	
			
	CITY_DECAY_INVEST                  = { -5, -6, -7, -8, -10 },

	CITY_PROSPERITY_PROB               = 2500,	
	
	CITY_PROSPERITY_INVEST             = { 5, 6, 7, 8, 10 },
	
	CITY_INCOME_MULTIPLIER             = { 1, 1.2, 1.6, 2.1, 3 },
	
	------------------------------------------
	-- Military order relative 
	CORPS_FATIGUE_CAUTION_RATIO        = 0.1,
	
	------------------------------------------
	-- infantry, archer, cavalry, siege weapon
	DEFAULT_TROOP_PROPORTION           = { 40, 25, 20, 15 },
}

ValueRange = 
{
	MAX_FATIGUE               = 100,

}