--[[
	City Produce
	
	#Agriculture -> Supply
	Supply = power( Agriculture, 2 ) * 0.5
	
	
--]]

function QueryFarmNeedMoney( city )
	local money = 0
	return money
end

function QueryInvestNeedMoney( city )
	local size = city.size
	local money = CityParams.INVEST.MONEY_PER_PLOT * #city.plots
	--InputUtility_Pause( "invest money=" .. money .. " " .. city.economy .. " " .. city.maxEconomy .. " " .. params.INVEST_FUND )
	return money
end

function CalcInvestBonusValue( current, maximum )
	local minRet = maximum * CityParams.INVEST.STANDARD_MODULUS + ( maximum - current ) * CityParams.INVEST.MINIMUM_MODULUS
	local maxRet = maximum * CityParams.INVEST.STANDARD_MODULUS + ( maximum - current ) * CityParams.INVEST.MAXIMUM_MODULUS
	return math.ceil( g_syncRandomizer:GetInt( minRet, maxRet, "Invest Bonus Random" ) )
end

function CalcFarmBonusValue( current, maximum )
	local minRet = maximum * CityParams.FARM.STANDARD_MODULUS + ( maximum - current ) * CityParams.FARM.MINIMUM_MODULUS
	local maxRet = maximum * CityParams.FARM.STANDARD_MODULUS + ( maximum - current ) * CityParams.FARM.MAXIMUM_MODULUS
	return math.ceil( g_syncRandomizer:GetInt( minRet, maxRet, "Farm Bonus Random" ) )
end

--------------------------
-- Plot

function CalcPlotPopulation( livingSpace )
	return math.ceil( livingSpace * GlobalConst.PLOT.PLOT_POPULATION_CONSTANT )
end

function CalcPlotSupply( agriculture )
	return math.ceil( agriculture * GlobalConst.PLOT.PLOT_SUPPLY_OUTPUT_CONSTANT )
end

function CalcPlotIncome( population, economy )
	local part1 = math.ceil( population * GlobalConst.PLOT.PLOT_INCOME_CAPITATION_CONSTNAT )
	local part2 = math.ceil( economy * GlobalConst.PLOT.PLOT_INCOME_ECONOMY_CONSTANT )
	return part1 + part2
end

--------------------------

function CalcSpendTimeOnRoad( currentCity, targetCity )
	if not currentCity or not targetCity then
		print( "invalid city, cann't calculate time spend on the road" .. currentCity, targetCity )
		return 0
	end
	local pos1 = currentCity:GetCoordinate()
	local pos2 = targetCity:GetCoordinate()
	local distance = math.abs( pos1.x - pos2.x ) + math.abs( pos1.y - pos2.y )
	return distance * GlobalConst.MOVE_TIME
end

function CalcCorpsSpendTimeOnRoad( currentCity, targetCity )
	if not currentCity or not targetCity then
		print( "invalid city, cann't calculate time spend on the road" )
		return 0
	end
	local pos1 = currentCity:GetCoordinate()
	local pos2 = targetCity:GetCoordinate()
	local distance = math.abs( pos1.x - pos2.x ) + math.abs( pos1.y - pos2.y )
	return distance * 3 * GlobalConst.MOVE_TIME
end

--------------------------