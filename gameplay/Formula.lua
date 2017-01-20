------------------------------
-- Group relative
function QueryGroupNeedCorpsForWar( group )
	local relations = group:GetBelligerentRelations()
	local number = math.max( 1, math.ceil( #group.cities / 2.5 ) )
	number = number + #relations
	return number
end

function QueryGroupCharaLimit( group )
	local leader = group:GetLeader()
	local params = CharacterParams.SUBORDINATE_LIMIT[leader:GetJob()]
	if not params then params = CharacterParams.SUBORDINATE_LIMIT.DEFAULT end
	return params
end

------------------------------
-- City relative

function QueryCityCorpsSupport( city )
	local numPlot = #city.plots
	local ret = math.floor( numPlot ^ 0.5 )
	if city:IsCapital() then ret = ret + CityParams.CAPITAL_EXTRA_CORPS_REQUIREMENT end
	return ret
end

function QueryCityCharaLimit( city )
	local numPlot = #city.plots
	local ret = math.max( 1, math.floor( numPlot ^ 0.5 ) )
	if city:IsCapital() then ret = ret + CityParams.CAPITAL_EXTRA_CHARA_LIMIT end
	return ret
end

function QueryCityNeedChara( city )
	local numPlot = #city.plots
	local ret = math.max( 1, math.floor( numPlot ^ 0.5 ) + CityParams.NONCAPITAL_EXTRA_CHARA_REQUIREMENT )
	if city:IsCapital() then ret = ret + CityParams.CAPITAL_EXTRA_CHARA_REQUIREMENT end
	--fortress modification?
	--print( city.name, " need ", ret, numPlot ^ 0.5 )
	return ret
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
-- Time spend on the task

function CalcSpendTimeOnCityAffairs( city )
	local numPlot = #city.plots
	return math.max( 1, math.floor( numPlot ^ 0.5 ) )
end

function CalcSpendTimeOnRoad( currentCity, targetCity )
	if not currentCity or not targetCity then
		ShowText( "invalid city, cann't calculate time spend on the road" .. currentCity, targetCity )
		return 0
	end
	local pos1 = currentCity:GetCoordinate()
	local pos2 = targetCity:GetCoordinate()
	local distance = math.abs( pos1.x - pos2.x ) + math.abs( pos1.y - pos2.y )
	return distance * GlobalConst.MOVE_TIME
end

function CalcCorpsSpendTimeOnRoad( currentCity, targetCity )
	if not currentCity or not targetCity then
		ShowText( "invalid city, cann't calculate time spend on the road" )
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
	--ShowText( "multiplefronts=" ..rand .."/" .. prob )
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
	--ShowText( "undeveloped=" ..rand .."/" .. prob )
	return rand < prob
end

function CheckGroupStuWeak( group )
	local curPower = group:GetPower()
	local totalPower, maxPower, minPower, number = group:GetBelligerentGroupPower()
	local avgPower = number > 0 and totalPower / number or 0
	local prob = maxPower * 8000 / ( curPower + maxPower ) + totalPower * 3500 / ( curPower + totalPower ) + avgPower * 3500 / ( curPower + avgPower )
	--InputUtility_Pause( curPower, maxPower, totalPower, avgPower )
	local rand = Random_SyncGetProb()	
	--ShowText( "weak=" ..rand .."/" .. prob )
	return rand < prob
end

function CheckGroupStuPrimitive( group )
	local techs = #group.techs
	return techs <= g_statistic.minNumOfResearchTech or techs <= math.ceil( g_statistic.numOfReserachTech / #g_statistic.activateGroups )
end

function CheckGroupStuUnderstaff( group )
	if #group.charas < QueryGroupCharaLimit( group ) then
		local prob = 5000
		local rand = Random_SyncGetProb()
		return true--rand < prob
	end
	return false
end

function CheckGroupStuAggressive( group )
	local prob = 0
	if group:HasGoal( GroupGoal.DOMINATION_TERRIORITY, GroupGoal.DOMINATION_CITY ) then prob = prob + 3500 end
	if group:HasGoal( GroupGoal.POWER_LEADING, GroupGoal.POWER_LEADING ) then prob = prob + 1000 end
	if group:HasGoal( GroupGoal.OCCUPY_CITY ) then prob = prob + 7000 end
	
	local curPower = group:GetPower()
	local totalPower, maxPower, minPower, number = group:GetBelligerentGroupPower()
	local avgPower = number > 0 and totalPower / number or 0
	if curPower >= maxPower then prob = prob + 2500 end
	if curPower >= minPower then prob = prob + 1000 end
	if curPower >= avgPower then prob = prob + 1000 end
	
	local rand = Random_SyncGetProb()
	--InputUtility_Pause( group.name .. " aggressive=" ..rand .."/" .. prob )
	--if rand < prob then print( "aggressive=" ..rand .."/" .. prob ) end
	return rand < prob
end

--------------------------
-- Diplomacy

function EvaluateDiplomacySuccessRate( method, relation, group, target )
	if not relation:IsMethodValid( method, group, target ) or not target then
		return 0
	end
	local prob = 0
	--ShowText( "evaluate", MathUtility_FindEnumName( DiplomacyMethod, method ) )
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