------------------------------
-- Group relative

function GuessGroupPower( tarGroup, currentGroup )
	return tarGroup:GetPower()
end

function QueryGroupNeedCorpsForWar( group )
	local relations = group:GetBelligerentRelations()
	local number = math.max( 1, math.ceil( #group.cities / 2.5 ) )
	number = number + #relations
	return number
end

function QueryGroupCharaLimit( group )
	local leader = group:GetLeader()
	if not leader then
		InputUtility_Pause( "chara limit with no leader")
	end
	local number = CharacterParams.SUBORDINATE_LIMIT[leader:GetJob()]	
	if not number then
		number = CharacterParams.SUBORDINATE_LIMIT.DEFAULT
	end
	number = number + math.floor( group:GetPlotNumber() * 0.35 ) + #group.cities
	return number
end

------------------------------
-- City relative

function QueryCityGuardsLimit( city )
	local plotNumber = #city.plots
	local number = ( plotNumber ^ 1.3 ) * 100
	if not city:GetGroup() then number = number * 0.5 end
	return math.ceil( number )
end
function QueryCityGuardsRecover( city )
	local plotNumber = #city.plots
	local number = math.ceil( plotNumber ^ 0.5 ) * 100
	return number
end

function QueryCityCorpsSupport( city )
	local plotNumber = #city.plots
	local ret = math.floor( plotNumber ^ 0.5 )
	if city:IsCapital() then ret = ret + CityParams.CAPITAL_EXTRA_CORPS_REQUIREMENT end
	return ret
end

--Determine how many chara( minimum ) supported in the city
function QueryCityCharaLimit( city )
	local plotNumber = #city.plots
	local ret = plotNumber * 0.35
	local extraReq = 0
	if city:IsCapital() then
		extraReq = extraReq + CityParams.CAPITAL_EXTRA_CHARA_LIMIT
	else
		--if city:IsBattleFront() then extraReq = extraReq + CityParams.BATTLEFRONT_EXTRA_CHARA_LIMIT
		--elseif city:IsFrontier() then extraReq = extraReq + CityParams.FRONTIER_EXTRA_CHARA_LIMIT end
		if city:IsImportance() then extraReq = extraReq + CityParams.IMPORTANCE_EXTRA_CHARA_LIMIT end
	end
	return math.min( math.ceil( ret + extraReq ), CityParams.MAX_CHARA_LIMIT )
end

--Determine how many chara( minimum ) required for the city
function QueryCityNeedChara( city )
	local plotNumber = #city.plots
	local ret = plotNumber * 0.15
	local minReq = city:IsCapital() and CityParams.CAPITAL_MIN_CHARA_REQUIREMENT or CityParams.NONCAPITAL_MIN_CHARA_REQUIREMENT
		
	if city:IsBattleFront() then
		minReq = minReq + CityParams.BATTLEFRONT_MIN_CHARA_REQUIREMENT
	elseif city:IsFrontier() then
		minReq = minReq + CityParams.FRONTIER_MIN_CHARA_REQUIREMENT
	end
		
	if city:IsImportance() then minReq = minReq + CityParams.IMPORTANCE_MIN_CHARA_REQUIREMENT end

	if city:IsExpandable() then minReq = minReq + CityParams.EXPANDABLE_MIN_CHARA_REQUIREMENT end

	return math.ceil( math.max( ret, minReq ) )
end

function QueryCityReqMilitaryPower( city )
local plotNumber = #city.plots
	if city:IsInDanger() then
		plotNumber = plotNumber * 1.5
	end

	--safety military power requirment	
	local req = CityParams.MILITARY.SAFETY_MILITARYPOWER_PER_PLOT

	--frontier or battlefront
	if city:IsBattleFront() then
		req = req + CityParams.MILITARY.BATTLEFRONT_MILITARYPOWER_PER_PLOT
	elseif city:IsFrontier() then
		req = req + CityParams.MILITARY.FRONTIER_MILITARYPOWER_PER_PLOT
	end

	--adjacent to shorterm goal
	if city:GetGroup() then
		--capital or center
		if city:IsCapital() then
			req = req + CityParams.MILITARY.IMPORTANCE_MILITARYPOWER_PER_PLOT
		elseif city:IsCenter() then
			req = req + CityParams.MILITARY.SECURITY_MILITARYPOWER_PER_PLOT
		end

		if city:IsAdjacentOccupyCityGoal() then
			req = req + CityParams.MILITARY.IMPORTANCE_MILITARYPOWER_PER_PLOT		
		end
		if city:IsDefendGoal() then
			req = req + CityParams.IMPORTANCE_MILITARYPOWER_PER_PLOT
		end
	end

	return math.ceil( req ) * plotNumber
end

function QueryCitySupportSoldier()
	
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

-- How many people can lved in the plot
function CalcPlotPopulation( livingSpace )
	return math.ceil( livingSpace * PlotParams.PLOT_POPULATION_CONSTANT )
end

-- How many people can raised by agriculture unit
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

function GuessCityPower( tarCity, currentCity )
	if tarCity == currentCity then
		return tarCity:GetPower()
	end
	local power = tarCity:GetReqMilitaryPower() + tarCity.guards
	return power
end

-- How many people required for each work position 
function CalcCityMinPopulation( city )
	local agr, maxAgr, ecn, maxEcn, prd, maxPrd = city:GetGrowthData()
	local farmer   = city.agriculture * PlotParams.PLOT_AGRICULTURE_NEED_POPULATION
	local merchant = city.economy * PlotParams.PLOT_ECONOMY_NEED_POPULATION
	local worker   = city.production * PlotParams.PLOT_PRODUCTION_NEED_POPULATION
	local rate = PlotParams.PLOT_NEED_POPULATION_MODULUS
	local total = math.ceil( ( farmer + merchant + worker ) * rate )
	--InputUtility_Pause( city.name .. " need population=" .. total .. " now=" .. city.population .. " productivity=" .. productivity )
	return total
end

-- How many people required for normal working status
function CalcCityReqPopulation( city )
	local agr, maxAgr, ecn, maxEcn, prd, maxPrd = city:GetGrowthData()
	local farmer   = city.agriculture * PlotParams.PLOT_AGRICULTURE_NEED_POPULATION
	local merchant = city.economy * PlotParams.PLOT_ECONOMY_NEED_POPULATION
	local worker   = city.production * PlotParams.PLOT_PRODUCTION_NEED_POPULATION
	--Temporary, use security as a factor to calculate rpoductivity
	local productivity = MathUtility_Clamp( 1.1 - 0.004 * city.security, 0.2, 1 )
	local total = math.ceil( ( farmer + merchant + worker ) * productivity )
	--InputUtility_Pause( city.name .. " need population=" .. total .. " now=" .. city.population .. " productivity=" .. productivity )
	return total
end

--------------------------
-- Time spend on the task

function CalcLookforTalentTime( city )
	local plotNumber = #city.plots
	return math.max( 1, math.floor( plotNumber ^ 0.5 ) - 1 )
end

function CalcSpendTimeOnCityAffairs( city )
	local plotNumber = #city.plots
	return math.max( 1, math.floor( plotNumber ^ 0.5 ) )
end

function CalcSpendTimeOnRoad( currentCity, targetCity )
	if not currentCity or not targetCity then
		ShowText( "invalid city, cann't calculate time spend on the road", currentCity, targetCity )
		return 0
	end
	local pos1 = currentCity:GetCoordinate()
	local pos2 = targetCity:GetCoordinate()
	local distance = math.abs( pos1.x - pos2.x ) + math.abs( pos1.y - pos2.y )
	--InputUtility_Pause( "distance", currentCity.name, targetCity.name, distance, distance * GlobalConst.MOVE_TIME )
	return distance * GlobalConst.CHARA_MOVE_TIME
end

function CalcCorpsSpendTimeOnRoad( currentCity, targetCity )
	if not currentCity or not targetCity then
		ShowText( "invalid city, cann't calculate time spend on the road" )
		return 0
	end
	local pos1 = currentCity:GetCoordinate()
	local pos2 = targetCity:GetCoordinate()
	local distance = math.abs( pos1.x - pos2.x ) + math.abs( pos1.y - pos2.y )
	return distance * GlobalConst.CORPS_MOVE_TIME
end

--------------------------
-- Group Situation Tag

function CheckGroupStuAtWar( group )
	return #group:GetBelligerentRelations() > 0
end

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
	if group:HasGoal( GroupGoal.POWER_LEADING, GroupGoal.POWER_LEADING ) then prob = prob + 1500 end
	if group:HasGoal( GroupGoal.OCCUPY_CITY ) then prob = prob + 6500 end
	
	local curPower = group:GetPower()
	local totalPower, maxPower, minPower, number = group:GetBelligerentGroupPower()
	local avgPower = number > 0 and totalPower / number or 0
	if curPower >= maxPower then prob = prob + 3500 end
	if curPower >= minPower then prob = prob + 1500 end
	if curPower >= avgPower then prob = prob + 1500 end
	
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

------------------------------
-- Corps Relative
function QueryCorpsTroopLimit( corps )
	local leader = corps:GetLeader()
	local support = CorpsParams.JOB_TROOP_LIMIT.NONE_JOB
	if leader then
		if leader:IsLeaderJob() then support = CorpsParams.JOB_TROOP_LIMIT.LEADER_JOB
		elseif leader:IsImportantJob() then support = CorpsParams.JOB_TROOP_LIMIT.IMPORTANT_JOB
		elseif leader:IsHighRankJob() then support = CorpsParams.JOB_TROOP_LIMIT.HIGH_RANK_JOB
		elseif leader:IsLowRankJob() then support = CorpsParams.JOB_TROOP_LIMIT.LOW_RANK_JOB
		end
	end
	return support
end

------------------------------
-- Troop relative
function QueryRecruitTroopNumber( troop )
	return troop.maxNumber * GroupParams.RECRUIT.RECRUIT_NUMBER_MODULUS
end
