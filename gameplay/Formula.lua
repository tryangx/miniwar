--[[
	City Produce
	
	#Agriculture -> Supply
	Supply = power( Agriculture, 2 ) * 0.5
	
	
--]]

function QueryInvestNeedMoney( city )
	local size = city.size
	local params = CityParams[size]
	if not params then return GlobalConst.INVALID_MONEY end
	local money = math.ceil( ( city.economy / city.maxEconomy + 1 ) * params.INVEST_FUND )
	--InputUtility_Pause( "invest money=" .. money .. " " .. city.economy .. " " .. city.maxEconomy .. " " .. params.INVEST_FUND )
	return money
end

function CalcInvestBonusValue( current, maximum )
	local minRet = maximum * CityParams.INVEST.STANDARD_MODULUS + ( maximum - current ) * CityParams.INVEST.MINIMUM_MODULUS
	local maxRet = maximum * CityParams.INVEST.STANDARD_MODULUS + ( maximum - current ) * CityParams.INVEST.MAXIMUM_MODULUS
	return math.ceil( g_globalRandomizer:GetInt( minRet, maxRet, "Invest Bonus Random" ) )
end

--------------------------

function CalcSpendTimeOnRoad( currentCity, targetCity )
	if not currentCity or not targetCity then
		print( "invalid city, cann't calculate time spend on the road" .. currentCity, targetCity )
		return 0
	end
	local pos1 = currentCity:GetPosition()
	local pos2 = targetCity:GetPosition()
	local distance = math.abs( pos1.x - pos2.x ) + math.abs( pos1.y - pos2.y )
	return distance * GlobalConst.MOVE_TIME
end

function CalcCorpsSpendTimeOnRoad( currentCity, targetCity )
	if not currentCity or not targetCity then
		print( "invalid city, cann't calculate time spend on the road" )
		return 0
	end
	local pos1 = currentCity:GetPosition()
	local pos2 = targetCity:GetPosition()
	local distance = math.abs( pos1.x - pos2.x ) + math.abs( pos1.y - pos2.y )
	return distance * 3 * GlobalConst.MOVE_TIME
end