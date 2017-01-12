--[[
	City Produce
	
	#Agriculture -> Supply
	Supply = power( Agriculture, 2 ) * 0.5
	
	
--]]

------------------------------
-- City relative

function QueryCityCorpsSupport( city )
	local numPlot = #city.plots
	return math.floor( numPlot ^ 0.5 )
end

function QueryCityNeedChara( city )
	local isCapital = city:GetGroup():GetCapital() == city
	local numPlot = #city.plots
	local need = math.max( 1, math.floor( numPlot ^ 0.5 ) - 1 )
	return need
end

------------------------------
-- Invest / Farm

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
	return math.ceil( Random_SyncGetRange( minRet, maxRet, "Invest Bonus Random" ) )
end

function CalcFarmBonusValue( current, maximum )
	local minRet = maximum * CityParams.FARM.STANDARD_MODULUS + ( maximum - current ) * CityParams.FARM.MINIMUM_MODULUS
	local maxRet = maximum * CityParams.FARM.STANDARD_MODULUS + ( maximum - current ) * CityParams.FARM.MAXIMUM_MODULUS
	return math.ceil( Random_SyncGetRange( minRet, maxRet, "Farm Bonus Random" ) )
end

--------------------------
-- Plot

function CalcPlotPopulation( livingSpace )
	return math.ceil( livingSpace * PlotParams.PLOT_POPULATION_CONSTANT )
end

function CalcPlotSupply( agriculture )
	return math.ceil( agriculture * PlotParams.PLOT_SUPPLY_OUTPUT_CONSTANT )
end

function CalcPlotIncome( population, economy )
	local part1 = math.ceil( population * PlotParams.PLOT_INCOME_CAPITATION_CONSTNAT )
	local part2 = math.ceil( economy * PlotParams.PLOT_INCOME_ECONOMY_CONSTANT )
	return part1 + part2
end

--------------------------
-- City
function CalcCityMinPopulation( city )
	local agr, maxAgr, ecn, maxEcn, prd, maxPrd = city:GetGrowthData()
	local farmer   = city.agriculture * PlotParams.PLOT_AGRICULTURE_NEED_POPULATION
	local merchant = city.economy * PlotParams.PLOT_ECONOMY_NEED_POPULATION
	local worker   = city.production * PlotParams.PLOT_PRODUCTION_NEED_POPULATION
	local rate = PlotParams.PLOT_NEED_POPULATION_MINMODULUS
	--local total = math.ceil( ( farmer + merchant + worker ) * MathUtility_Clamp( 1.1 - 0.004 * city.security, 0.2, 1 ) )
	local total = math.ceil( ( farmer + merchant + worker ) * MathUtility_Clamp( 1 - 0.005 * city.security, 0.2, 1 ) )
	--InputUtility_Pause( city.name .. " need population=" .. total .. " now=" .. city.population )
	return total
end

--------------------------
-- Time spend on the road

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
-- Group Situation Tag
function CheckGroupStuMultipleFronts( group )
	local enemies = #group:GetBelligerentRelations()
	local prob = enemies * 4000 - 3000
	local rand = Random_SyncGetProb()
	--print( "multiplefronts=" ..rand .."/" .. prob )
	return rand < prob
end

function CheckGroupUndeveloped( group )
	local groupMaxAgr, groupMaxEcn, groupMaxPrd, groupAgr, groupEcn, groupPrd = 0, 0, 0, 0, 0, 0
	for k, city in ipairs( group.cities ) do
		local agr, maxAgr, ecn, maxEcn, prd, maxPrd = city:GetGrowthData()
		groupMaxAgr = groupMaxAgr + maxAgr
		groupMaxEcn = groupMaxEcn + maxEcn
		groupMaxPrd = groupMaxPrd + maxPrd
		groupAgr = groupAgr + agr
		groupEcn = groupEcn + ecn
		groupPrd = groupPrd + prd
	end
	local prob = ( 1 - ( groupAgr + groupEcn + groupPrd ) / ( groupMaxAgr + groupMaxEcn + groupMaxPrd ) ) * 10000
	local rand = Random_SyncGetProb()
	--print( "undeveloped=" ..rand .."/" .. prob )
	return rand < prob
end

function CheckGroupStuWeak( group )
	local curPower = group:GetPower()
	local totalPower, maxPower, minPower, number = group:GetBelligerentGroupPower()
	local avgPower = number > 0 and totalPower / number or 0
	local prob = maxPower * 8000 / ( curPower + maxPower ) + totalPower * 3500 / ( curPower + totalPower ) + avgPower * 3500 / ( curPower + avgPower )
	--InputUtility_Pause( curPower, maxPower, totalPower, avgPower )
	local rand = Random_SyncGetProb()	
	--print( "weak=" ..rand .."/" .. prob )
	return rand < prob
end

function CheckGroupStuPrimitive( group )
	--Need global data about how many tech owns by every group
	return false
end

function CheckGroupStuUnderstaff( group )
	--Need to determine the number of character limitation owns by group 
	return false
end

function CheckGroupStuAggressive( group )
	local prob = 0
	if group:HasGoal( GroupGoal.DOMINATION_GOAL_BEG, GroupGoal.DOMINATION_GOAL_END ) then prob = prob + 3000 end
	if group:HasGoal( GroupGoal.LEADING_BEG, GroupGoal.LEADING_END ) then prob = prob + 1500 end
	local rand = Random_SyncGetProb()
	--print( "aggressive=" ..rand .."/" .. prob )
	return rand < prob
end

--------------------------
-- Diplomacy

function EvaluateDiplomacySuccessRate( method, relation, group, target )
	if not relation:IsMethodValid( method, group, target ) or not target then
		return 0
	end
	local prob = 0
	--print( "evaluate", MathUtility_FindEnumName( DiplomacyMethod, method ) )
	if method == DiplomacyMethod.FRIENDLY then
		prob = relation:EvalFriendlyProb( _chara, group, target )
	elseif method == DiplomacyMethod.THREATEN then
		prob = relation:EvalThreatenProb( _chara, group, target )
	elseif method == DiplomacyMethod.ALLY then
		prob = relation:EvalAllyProb( _chara, group, target )
	elseif method == DiplomacyMethod.DECLARE_WAR then
		prob = relation:EvalDeclareWarProb( _chara, group, target )
	elseif method == DiplomacyMethod.MAKE_PEACE then
		prob = relation:EvalMakePeaceProb( _chara, group, target )
	elseif method == DiplomacyMethod.BREAK_CONTRACT then
		prob = relation:EvalBreakContractProb( _chara, group, target )
	elseif method == DiplomacyMethod.SURRENDER then
		prob = relation:EvalSurrenderProb( _chara, group, target )
	end
	--diplomatic
	if _chara then
		trait = _chara:QueryTrait( TraitEffectType.DIPLOMACY_SUCCESS_PROB )
		if trait then
			prob = prob + trait.value
		end
		if _chara:IsDiplomatic() then
			prob = prob + GroupRelationParam.DIPLOMATIC_BONUS
		end
	end
	return math.floor( prob )
end