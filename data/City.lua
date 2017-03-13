City = class()

function City:Generate( data )
	self:Load( data )
	self:ConvertID2Data()
end

function City:Load( data )	
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	self.type = data.type or CityType.CITY
	
	-----------------------------------
	
	self.adjacentCities = MathUtility_Copy( data.adjacentCities )
	
	self.instruction = CityInstruction[data.instruction] or CityInstruction.NONE
	
	-----------------------------------
	
	self.leader      = data.leader or 0
	
	-----------------------------------
	-- Basic Attributes
	
	self.coordinate    = MathUtility_Copy( data.coordinate )

	self.level       = data.level or 1
	
	self.size        = CitySize[data.size] or CitySize.TOWN

	self.tags        = MathUtility_Copy( data.tags )

	self.money       = data.money or 0
	
	self.food        = data.food or 0
	
	self.militaryService = self.militaryService or 0

	--determine how many military soldier attend when it's in siege
	self.guards      = data.guards or 0	

	-----------------------------------
	-- extension
	
	--Culture circle
	--More deep effects
	self.cultrueCircle = data.cultureCircle or 0
		
	--political point
	self.politicalPoint = data.politicalPoint or 0
	
	--Trait
	--Type-Value datas
	self.traits      = MathUtility_Copy( data.traits )
	
	-----------------------------------
	-- additional datas
	
	--Character
	self.charas      = MathUtility_Copy( data.charas )	
		
	--Garrison Troops
	self.troops      = MathUtility_Copy( data.troops )
	
	--Construction 
	self.constrs     = MathUtility_Copy( data.constrs )
		
	--Corps
	self.corps       = MathUtility_Copy( data.corps )

	--Control Plots
	self.plots       = MathUtility_Copy( data.plots )
	
	-----------------------------------
	-- Dynamic Data
	self.group         = nil
		
	self._militaryPower = -1	
	self._canBuildConstructions = nil
	self._canRecruitTroops = nil
	
	--[[
	--Determines how many troop can supply
	self._supplyIncome  = 0
	self._supplyConsume = 0
	
	self._moneyIncome   = 0	
	self._economyPower  = -1
	]]
end

function City:SaveData()
	self.size = MathUtility_FindEnumKey( CitySize, self.size )

	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	Data_OutputValue( "id", self )
	Data_OutputValue( "name", self )
	
	Data_OutputTable( "coordinate", self )
		
	Data_OutputValue( "size", self )
	Data_OutputValue( "money", self )
	Data_OutputValue( "food", self )
	Data_OutputValue( "militaryService", self )
	
	Data_OutputValue( "level", self )
		
	Data_OutputValue( "cultrueCircle", self )
	Data_OutputValue( "politicalPoint", self )
	
	Data_OutputValue( "instruction", self )
	
	Data_OutputTable( "adjacentCities", self, "id" )

	Data_OutputTable( "tags", self )
	Data_OutputTable( "traits", self )
	
	Data_OutputTable( "charas", self, "id" )
	Data_OutputTable( "troops", self, "id" )
	Data_OutputTable( "corps", self, "id" )
	Data_OutputTable( "constrs", self, "id" )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
	
	self.size = CitySize[self.size]
end

function City:ConvertID2Data()
	local constrs = {}
	for k, id in ipairs( self.constrs ) do
		table.insert( constrs, g_constrTableMng:GetData( id ) )
	end
	self.constrs = constrs

	self.leader = g_charaDataMng:GetData( self.leader )
	
	local charas = {}
	for k, id in ipairs( self.charas ) do
		local chara = g_charaDataMng:GetData( id )		
		if not chara then
			Debug_Error( "Chara is invalid [".. id .. "]" )
		else
			--if chara.home then Debug_Error( "Try to put character on [" .. self.name .. "] is already in [".. chara._city.name .. "]" ) end			
			--chara.home = self
			table.insert( charas, chara )

			if not self.leader or self.leader.contribution < chara.contribution then
				self.leader = chara
				contribution = chara.contribution
			end
			
			--repair data
			--ShowText( "check data", self.id, self.name, chara.name )
			if chara:GetHome() == 0 then
				chara.home = self.id				
			end
			if chara:GetLocation() == 0 then
				chara.location = self.id
			end
			if self.group and not self.group:HasChara( chara ) then
				self.group:AddChara( chara )
				chara:JoinGroup( self )			
				Debug_Assert( nil, "Chara is in the city, but not not in the group" )
			end
		end
	end
	self.charas = charas
	
	local troops = {}
	for k, id in ipairs( self.troops ) do
		local troop = g_troopDataMng:GetData( id )
		if troop.home == 0 then
			--ShowText( "Add missing home data for troop" )
			troop.location = self.id
			troop.home     = self.id
			troop:JoinGroup( self.group )
		end
		table.insert( troops, troop )
	end
	self.troops = troops
		
	local corps = {}
	for k, id in ipairs( self.corps ) do	
		table.insert( corps, g_corpsDataMng:GetData( id ) )
	end
	self.corps = corps
	--add missing troop
	for k, corps in ipairs( self.corps ) do
		for k2, troop in ipairs( corps.troops ) do
			if not MathUtility_IndexOf( self.troops, troop, "id" ) then
				ShowText( "Add missing troop ["..troop.."] of corp in city ["..self.name.."]" )
				table.insert( self.troops, g_troopDataMng:GetData( troop ) )
			end
		end
	end

	self:UpdatePlots( true )
end

function City:UpdatePlots( allocate )
	self.agriculture    = 0
	self.economy        = 0
	self.production     = 0
	self.maxAgriculture = self.agriculture
	self.maxEconomy     = self.economy
	self.maxProduction  = self.production
	self.livingspace    = 0
	self.population     = 0
	self.security       = 0
	local plotDesc = ""
	local plots = {}
	for k, pos in pairs( self.plots ) do
		local plot = g_plotMap:GetPlot( pos.x, pos.y )
		if allocate then table.insert( plots, plot ) end
		if plot then
			plotDesc = plotDesc .. ( plot.table and plot.table.name or "--" ) .. ","
			self.maxAgriculture = self.maxAgriculture + plot:GetBonusValue( PlotResourceBonusType.AGRICULTURE )
			self.maxEconomy     = self.maxEconomy     + plot:GetBonusValue( PlotResourceBonusType.ECONOMY )
			self.maxProduction  = self.maxProduction  + plot:GetBonusValue( PlotResourceBonusType.PRODUCTION )
			self.livingspace    = self.livingspace    + plot:GetBonusValue( PlotResourceBonusType.LIVING_SPACE )
			
			self.agriculture    = self.agriculture    + plot:GetAsset( PlotAssetType.AGRICULTURE )
			self.economy        = self.economy        + plot:GetAsset( PlotAssetType.ECONOMY )
			self.production     = self.production     + plot:GetAsset( PlotAssetType.PRODUCTION )			
			self.population     = self.population     + plot:GetAsset( PlotAssetType.POPULATION )
			self.security       = self.security       + plot:GetAsset( PlotAssetType.SECURITY )
		end
	end
	--use average evaluation
	self.security = math.floor( self.security / #self.plots )
	
	if self:GetGroup() then 
		print( self.name .. " plot="..#self.plots .. " lv=" .. self.level )
		--ShowText( plotDesc )
		print( "popu1=" .. Helper_CreateNumberDesc( self.population ) .. "/" .. Helper_CreateNumberDesc( CalcPlotPopulation( self.livingspace ) ) .. "("..self.livingspace..")" )	
		print( "popu2=" .. self:GetMinPopulation() .. "(Min)/" .. self:GetMSPopulation() .. "(Serv)" )
		print( "agr="..self.agriculture.."/"..self.maxAgriculture.." Supply="..Helper_CreateNumberDesc( CalcPlotSupply( self.agriculture ) - self.population ) .. "/" .. Helper_CreateNumberDesc( CalcPlotSupply( self.maxAgriculture ) - self.population ) .. " Surplus="..Helper_CreateNumberDesc( CalcPlotSupply( self.agriculture ) - self.population ).."/"..Helper_CreateNumberDesc( CalcPlotSupply( self.maxAgriculture ) - CalcPlotPopulation( self.livingspace ) ) )
		print( "eco="..self.economy.."/"..self.maxEconomy.. " pro="..self.production.."/"..self.maxProduction .. " sec=" ..self.security )	
		print( "military=" .. self:GetMilitaryPower() .. "/" .. self:GetReqMilitaryPower() )	
		--InputUtility_Pause()
	end
	if allocate then self.plots = plots end
end

function City:SetPlots( plotDatas, reset )
	self.plots = plotDatas
	if reset then self:UpdatePlots( true ) end
end

function City:InitAdjacentCity()
	local adjCities = {}
	for k, id in ipairs( self.adjacentCities ) do
		local city = g_cityDataMng:GetData( id )
		if city then
			table.insert( adjCities, city )
		end		
	end	
	self.adjacentCities = adjCities
end

----------------------------------
-- Getter 

function City:IsCapital()
	return self:GetGroup() and self:GetGroup():GetCapital() == self
end

function City:IsCharaStayCity( chara )
	--if not MathUtility_IndexOf( self.charas, chara.id, "id" )  then return false end
	return chara:GetLocation() == self
end

function City:IsWeak()
	return self:GetTag( CityTag.WEAK )
end

function City:IsInSiege()
	return self:GetTag( CityTag.SIEGE )
end

-- Is city in conflict, like g_warfare, rebellion
function City:IsInConflict()	
	return self:GetTag( CityTag.SIEGE ) or self:GetTag( CityTag.BATTLEFRONT )
end

function City:IsInDanger()
	return self:GetTag( CityTag.INDANGER )
end

function City:IsBattleFront()
	return self:GetTag( CityTag.BATTLEFRONT )
end

function City:IsFrontier()
	return self:GetTag( CityTag.FRONTIER ) ~= nil
end

function City:IsUnderstaffed()
	return #self.charas < QueryCityNeedChara( self )
end

function City:HasChara( chara )
	if not chara then return false end
	return MathUtility_IndexOf( self.charas, chara.id, "id" )
end

function City:HasCorps( corps )
	return MathUtility_IndexOf( self.corps, corps ) ~= nil
end

function City:HasNoCorpsTroop()
	for k, troop in ipairs( self.troops ) do
		if not troop:GetCorps() then return true end
	end
	return false
end

function City:HasNoLeaderTroop()
	for k, troop in ipairs( self.troops ) do
		if not troop:GetLeader() then return true end
	end
	return false
end

function City:IsAdjacentLocation( location )
	for k, city in ipairs( self.adjacentCities ) do
		if city == location then return true end
	end
	return false
end

function City:IsAdjacentGroup( group )
	for k, city in ipairs( self.adjacentCities ) do
		if city:GetGroup() == group then return true end
	end
	return false
end

----------------------------------
-- Getter 
----------------------------------

function City:GetGroup()
	return self.group
end

function City:GetLeader()
	return self.leader
end

function City:GetPower()
	local power =  0
	for k, troop in ipairs( self.corps ) do
		power = troop:GetPower()
	end
	return power
end

function City:GetCoordinate()
	return self.coordinate
end

------------------------------------
-- Below use for AI

function City:GetAdjacentGroupMilitaryPowerList()
	return Helper_ListEach( self.adjacentCities, function( city, list )
		local otherGroup = city:GetGroup()
		if otherGroup and otherGroup ~= self:GetGroup() then
			if list[otherGroup.id] then
				list[otherGroup.id] = list[otherGroup.id] + city:GetMilitaryPower()
			else
				list[otherGroup.id] = city:GetMilitaryPower()
			end
		end
	end )
end

function City:GetAdjacentHostileCityList()
	return Helper_ListIf( self.adjacentCities, function( city )
		local otherGroup = city:GetGroup()
		return otherGroup ~= self:GetGroup() and self:GetGroup():IsHostility( otherGroup )
	end )
end

function City:GetAdjacentBelligerentCityList()	
	return Helper_ListIf( self.adjacentCities, function( city )
		local otherGroup = city:GetGroup()
		if not self:GetGroup() then return false end
		return otherGroup ~= self:GetGroup() and self:GetGroup():IsBelligerent( otherGroup )
	end )
end

function City:GetAdjacentInDangerSelfGroupCityList()
	return Helper_ListIf( self.adjacentCities, function( city )
		return city:GetGroup() == self:GetGroup() and city:IsInDanger()
	end )
end

function City:QueryAdajacentCityMilitaryPower() 
	local maxPower, minPower, totalPower, number = nil, nil, 0, 0
	local group = self:GetGroup()
	for k, otherCity in ipairs( self.adjacentCities ) do 
		local otherGroup = otherCity:GetGroup()
		if otherGroup and otherGroup ~= group then			
			local otherPower = otherCity:GetMilitaryPower()
			if not maxPower or otherPower > maxPower then maxPower = otherPower end
			if not minPower or otherPower < minPower then minPower = otherPower end
			totalPower = totalPower + otherPower
			number = number + 1
			if self.id == 10 then
				print( self.name .. " adja " .. otherCity.name .. "=" .. otherPower)
			end
		end
	end
	return totalPower, maxPower or 0, minPower or 0, number
end

-----------------------------------------------------
-- Below Getter mostly use in Task Manager

-- character who can attend meeting
function City:GetNumOfIdleChara()
	return Helper_CountIf( self.charas, function( chara )
		return chara:IsAtHome() and not g_taskMng:GetTaskByActor( chara )
	end )
end

function City:GetNumOfFreeChara()
	return Helper_CountIf( self.charas, function( chara )
		return chara:IsFree()
	end )
end

function City:GetNumOfFreeChara()
	return Helper_CountIf( self.charas, function( chara )
		return chara:IsFree()
	end )
end
function City:GetFreeCharaList()
	return Helper_ListIf( self.charas, function( chara )
		return chara:IsFree()
	end )
end

function City:GetFreeMilitaryOfficerList()
	return Helper_ListIf( self.charas, function( chara )
		return not chara:GetTroop() and chara:IsAtHome() and chara:IsMilitaryOfficer() and not g_taskMng:GetTaskByActor( chara )
	end )
end

function City:GetIdleCorpsList()
	return Helper_ListIf( self.corps, function( corps )
		return corps:IsAtHome() and not g_taskMng:GetTaskByActor( corps )
	end )
end

function City:GetPreparedToAttackCorpsList( hint )
	return Helper_ListIf( self.corps, function( corps )
		return corps:IsAtHome() and corps:IsPreparedToAttack() and not g_taskMng:GetTaskByActor( corps )
	end )
end

-- Idle corps means Staying in city
function City:GetNumOfIdleCorps()
	return Helper_CountIf( self.corps, function( corps )
		return not corps:IsAtHome() and not g_taskMng:GetTaskByActor( corps )
	end )
end

function City:GetNumOfVacancyCorps()
	return Helper_CountIf( self.corps, function ( corps )
		return corps:IsAtHome() and corps:GetVacancyNumber() > 0 and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetVacancyCorpsList()
	return Helper_ListIf( self.corps, function ( corps )
		return corps:IsAtHome() and corps:GetVacancyNumber() > 0 and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetUnderstaffedCorpsList()
	return Helper_ListIf( self.corps, function ( corps )
		return corps:IsAtHome() and corps:IsUnderstaffed() and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetNumOfUnderstaffedCorps()
	return Helper_CountIf( self.corps, function ( corps )
		return corps:IsAtHome() and corps:IsUnderstaffed() and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetUntrainedCorpsList()
	return Helper_ListIf( self.corps, function ( corps )
		return corps:IsAtHome() and corps:IsUntrained() and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetNumOfUntrainedCorps()
	return Helper_CountIf( self.corps, function ( corps )
		return corps:IsAtHome() and corps:IsUntrained() and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetNumOfNonLeaderTroop()
	return Helper_CountIf( self.troops, function ( troop )	
		return ( not troop:GetCorps() or troop:GetCorps():IsAtHome() ) and not troop:GetLeader() and not g_taskMng:GetTaskByActor( troop )
	end )
end
function City:GetNonLeaderTroopList()
	return Helper_ListIf( self.troops, function( troop )
		return ( not troop:GetCorps() or troop:GetCorps():IsAtHome() ) and not troop:GetLeader() and not g_taskMng:GetTaskByActor( troop )
	end )
end

function City:GetNumOfNonCorpsTroop()
	return Helper_CountIf( self.troops, function( troop )
		return not troop:GetCorps() and not g_taskMng:GetTaskByActor( troop )
	end )
end
function City:GetNonCorpsTroopList()
	return Helper_ListIf( self.troops, function( troop )
		return not troop:GetCorps() and not g_taskMng:GetTaskByActor( troop )
	end )
end

-------------------------------------------------

function City:GetMilitaryPower()	
	if self._militaryPower >= 0 then return self._militaryPower end
	
	local power = 0
	for k, troop in ipairs( self.troops ) do
		power = power + troop.number
	end
	self._militaryPower = power		
	return self._militaryPower
end

function City:GetReqPopulation()
	return CalcCityReqPopulation( self )
end

function City:GetMinPopulation()
	return CalcCityMinPopulation( self )
end

function City:GetMSPopulation()
	local militaryService = self.population - self:GetMinPopulation()
	--no female, XD
	militaryService = math.ceil( militaryService * GlobalConst.MALE_PROPORTION )
	return math.max( 0, militaryService )
end

function City:GetReqMilitaryPower()
	local plotNumber = #self.plots
	if self:IsInDanger() then
		plotNumber = plotNumber * 1.5
	end
	local ret = 0
	if self:IsBattleFront() then
		ret = plotNumber * CityParams.MILITARY.BATTLEFRONT_MILITARYPOWER_PER_PLOT
	elseif self:IsFrontier() then
		ret = plotNumber * CityParams.MILITARY.FRONTIER_MILITARYPOWER_PER_PLOT
	elseif self:GetGroup() and self == self:GetGroup():GetCapital() then
		ret = plotNumber * CityParams.MILITARY.SECURITY_MILITARYPOWER_PER_PLOT
	else
		ret = plotNumber * CityParams.MILITARY.SAFETY_MILITARYPOWER_PER_PLOT
	end
	return math.ceil( ret )
end

function City:GetSupplyBonus()
	local standard = 0
	local modulus = 0
	local modulusNum = 0
	for k, plot in ipairs( self.plots ) do
		local resource = plot:GetResource()
		if resource then			
			if resource.category == ResourceCategory.BONUS then
				local index = MathUtility_IndexOf( resource.bonuses, "SUPPLY_FOOD", "type" )
				if index then				
					standard = standard + resource.bonuses[index].value
				end
				local index = MathUtility_IndexOf( resource.bonuses, "SUPPLY_MODULUS", "type" )
				if index then				
					modulus = modulus + resource.bonuses[index].value
					modulusNum = modulusNum + 1
				end
			end
		end
	end
	if modulus == 0 then
		modulus = 1
	else
		modulus = modulus / modulusNum
	end
	--return 0, 1
	return standard, modulus
end

function City:GetHarvestFood()
	local output = ( self:GetSupply() - self.population ) * CityParams.HARVEST.HARVEST_CYCLE_TIME
	return math.max( output, 0 )
end

function City:GetSupply()
	local bonus, modulus = self:GetSupplyBonus()
	local supply = CalcPlotSupply( ( self.agriculture + bonus ) * modulus )
	local ret = supply
	--InputUtility_Pause( self.name, "output=" .. supply, "popu=".. self.population, " surplus="..ret, bonus, modulus)
	return ret
end

function City:GetMaxSupply()
	local bonus, modulus = self:GetSupplyBonus()
	local supply = CalcPlotSupply( ( self.agriculture + bonus ) * modulus )
	return supply - self.population
end

function City:GetIncomeModulus()
	local standard = CityParams.ECONOMY.INCOME_PER_MODULUS_UNIT
	return standard
end

function City:GetMoney()
	return self.money
end

-- Get turn income
function City:GetIncome()
	return math.ceil( self.economy * self:GetIncomeModulus() + CityParams.ECONOMY.INCOME_POPULATION_MODULUS * self.population )
end

function City:CalcMaintenanceCost()
	local cost = 0
	for k, troop in ipairs( self.troops ) do
		cost = cost + troop.table.salary 
	end
	for k, constr in ipairs( self.constrs ) do
		cost = cost + constr.maintenance
	end
	return cost
end

-- Get Build List
function City:GetBuildList()
	if self._canBuildConstructions then return self._canBuildConstructions end
	self._canBuildConstructions = {}	
	for k, constr in ipairs( self.group._canBuildConstructions ) do				
		local match = true		
		if MathUtility_IndexOf( self.constrs, constr.id, "id" ) then
			match = false
		end
		if match then
			match = self:CanBuildConstruction( constr )
		end
		if match then
			table.insert( self._canBuildConstructions, constr )
		end
	end
	return self._canBuildConstructions
end

function City:GetRecruitList()
	if self._canRecruitTroops then return self._canRecruitTroops end
	self._canRecruitTroops = {}
	for k, troop in ipairs( self.group._canRecruitTroops ) do
		local match = self:CanRecruitTroop( troop )
		if match then
			table.insert( self._canRecruitTroops, troop )
		end
	end
	return self._canRecruitTroops
end

function City:GetTag( tagType )
	return Helper_GetVarb( self.tags, tagType )
end

function City:SetTag( tagType, value )
	Helper_SetVarb( self.tags, tagType, value )
end

function City:AppendTag( tagType, value, range )
	Helper_AppendVarb( self.tags, tagType, value, range )
end

function City:RemoveTag( tagType, value )
	Helper_RemoveVarb( self.tags, tagType, value )
end

function City:GetGrowthData()
	return self.agriculture, self.maxAgriculture, self.economy, self.maxEconomy, self.production, self.maxProduction
end

------------------------------------------

function City:IsPopulationEnough()
	return self:GetMinPopulation() < self.population
end

function City:CanDispatch()
	return not self:IsInSiege()
end

function City:CanBuild()
	return self:GetBuildList() and #self._canBuildConstructions > 0 and not self:IsInSiege() 
end
-- Check city is not building any construction or recruit any troop
function City:CanInvest()
	return self.economy < self.economy and not self:IsInSiege() and self:GetGroup().money >= QueryInvestNeedMoney( self )-- and self:IsPopulationEnough()
end
function City:CanFarm()
	return self.agriculture < self.maxAgriculture and not self:IsInSiege() and self:GetGroup().money >= QueryFarmNeedMoney( self ) --and self:IsPopulationEnough() 
end
function City:CanBuildConstruction( constr )
	--require constrs
	if constr.prerequisites.constrs then
		for k, constr in ipairs( constr.prerequisites.constrs ) do
			if not MathUtility_IndexOf( self.constrs, constr, "id" ) then
				return false
			end
		end
	end
	
	if constr.prerequisites.money then
		if self.city < constr.prerequisites.money and self.group:GetMoney() < constr.prerequisites.money then
			return false
		end
	end
	
	return true
end
function City:CanLevyTax()
	return not self:IsInSiege()
end
function City:CanPatrol()
	return not self:IsInSiege() and self.security < PlotParams.SAFETY_PLOT_SECURITY
end
function City:CanInstruct()
	return self.instruction == CityInstruction.NONE and not g_taskMng:IsTaskConflictWithCity( TaskType.CITY_INSTRUCT, self )
end
function City:CanRecruit()
	return #self:GetRecruitList() > 0 and not self:IsInSiege()-- and self:IsPopulationEnough() 
end
function City:CanRecruitTroop( troop )
	if troop.prerequisites.constrs then
		for k, constr in ipairs( troop.prerequisites.constrs ) do
			if not MathUtility_IndexOf( self.constrs, constr, "id" ) then
				return false
			end
		end
	end	
	if troop.prerequisites.money and self.group:GetMoney() < troop.prerequisites.money then
		return false
	end	
	return true
end
function City:CanEstablishCorps()
	--number of corps is less than limit
	if #self.corps >= QueryCityCorpsSupport( self ) then
		--ShowText( NameIDToString( self ) .. " only support corps=" .. QueryCityCorpsSupport( self ) )
		return false
	end
	
	--has enough troop not in the crops
	return self:GetNumOfNonCorpsTroop() >= CorpsParams.NUMBER_OF_TROOP_TO_ESTALIBSH
end
function City:CanRegroupCorps()
	ShowText( "regroup", self.name, #self.corps, #self.troops, self:GetNumOfVacancyCorps(), self:GetNumOfNonCorpsTroop() )
	return not self:IsInSiege() and self:GetNumOfVacancyCorps() > 0 and self:GetNumOfNonCorpsTroop() > 1
end
function City:CanReinforceCorps()
	return not self:IsInSiege() and self:GetNumOfUnderstaffedCorps() > 0 and self:IsPopulationEnough()
end
function City:CanTrainCorps()
	return not self:IsInSiege() and self:GetNumOfUntrainedCorps() > 0
end

function City:CanDispatchCorps()
	return self:GetNumOfIdleCorps() > 0
end

function City:CanLeadTroop()
	return self:GetNumOfNonLeaderTroop() > 0 and self:GetNumOfFreeChara() > 0
end

----------------------------------------

function City:DumpCharaDetail( indent )
	if #self.charas == 0 then return end
	local content = indent .. "    "
	for k, chara in ipairs( self.charas ) do
		content = content .. ( k > 1 and ", " or "" ) .. chara.name
		if g_taskMng:GetTaskByActor( chara ) then content = content .. "(busy)" end
		if chara:GetTroop() then content = content .. "("..NameIDToString( chara:GetTroop() )..")" end
		if chara:IsAtHome() then content = content .. "(home)" end
		content = content .. ( chara:GetGroup() and chara:GetGroup().name or "" )
	end
	ShowText( content )
end

function City:DumpTroopDetail( indent )
	if #self.troops == 0 then return end
	local inCorps, nonCorps = 0, 0
	local contentInCorps = indent .. "    "
	local contentNonCorps = indent .. "    "
	for k, troop in ipairs( self.troops ) do
		if troop:GetCorps() then
			inCorps = inCorps + 1
			contentInCorps = contentInCorps .. NameIDToString( troop ).. "+".. troop.number.." "
			if troop:GetLeader() then contentInCorps = contentInCorps .. "LD=" .. troop:GetLeader().name end
		else
			nonCorps = nonCorps + 1
			contentNonCorps = contentNonCorps .. NameIDToString( troop ).. "(".. troop.number..") "
			if troop:GetLeader() then contentNonCorps = contentNonCorps .. "LD=" .. troop:GetLeader().name end
		end		
	end
	ShowText( indent .. "    " .. "InGroup=" .. inCorps )
	ShowText( contentInCorps )
	ShowText( indent .. "    " .. "NoneGroup" .. nonCorps )
	ShowText( contentNonCorps )
end

function City:DumpCorpsDetail( indent )
	if #self.troops == 0 then return end
	local content = indent .. "    "
	for k, corps in ipairs( self.corps ) do
		corps:Dump( indent )
	end
end


function City:DumpConstructionDetail( indent )
	if #self.constrs == 0 then return end
	local content = indent .. "    "
	for k, constr in ipairs( self.constrs ) do
		content = content .. ( k > 1 and "," or "" ) .. constr.name
	end
	ShowText( content )
end

function City:DumpAdjacentDetail( indent )
	if #self.adjacentCities == 0 then return end
	local content = indent .. "Adja="
	local group = self:GetGroup()
	for k, city in ipairs( self.adjacentCities ) do
		content = content .. ( k > 1 and "," or "" ) .. city.name
		local otherGroup = city:GetGroup()
		if otherGroup and otherGroup ~= group then
			content = content .. "-" .. city:GetGroup().name
			if group then
				local relation = group:GetGroupRelation( otherGroup.id )
				if relation then
					content = content .. "+" .. MathUtility_FindEnumName( GroupRelationType, relation.type )
				end
			end
		end
	end
	ShowText( content )
end

function City:DumpPlotsDetail( indent )
	if #self.plots == 0 then return end
	local content = indent .. "    "
	for k, plot in ipairs( self.plots ) do
		content = content .. ( k > 1 and "," or "" ) .. plot.table.name
	end
	ShowText( content )
end

function City:DumpTagDetail( indent )
	if #self.tags == 0 then return end
	local content = indent .. "    "
	for k, tag in ipairs( self.tags ) do
		content = content .. ( k > 1 and "," or "" ) .. MathUtility_FindEnumName( CityTag, tag.type )
	end
	ShowText( content )
end

function City:DumpSimple( indent )
	if not indent then indent = "" end
	ShowText( indent .. '[City] #' .. self.id .. ' Name=' .. self.name )
end

function City:DumpBrief()
	local indent = ""
	ShowText( '>>>>>>>>>>>  City >>>>>>>>>>>>>>>>>' )
	ShowText( indent .. '[City] #' .. self.id .. ' Name=' .. self.name .. ' Group=' .. ( self.group and self.group.name or "[none]" ) )
	self:DumpAdjacentDetail( indent )
	ShowText( indent .. 'Popu/Mil Serv  ', Helper_CreateNumberDesc( self.population ) .. "/" .. Helper_CreateNumberDesc( self:GetMSPopulation() ) .. "(Mil)+" .. self.militaryService )
	ShowText( indent .. 'Agri+Ecom+Prod ', self.agriculture .. "/" .. self.maxAgriculture .. " " .. self.economy .. "/" .. self.maxEconomy .. " " .. self.production .. "/" .. self.maxProduction )
	ShowText( indent .. 'Secu/Min Popu  ', self.security .. "/" .. Helper_CreateNumberDesc( self:GetReqPopulation() ) .. "(Req)/" .. Helper_CreateNumberDesc( self:GetMinPopulation() ) .. "(Min)" )
	ShowText( indent .. 'Money / Food   ', Helper_CreateNumberDesc( self.money ) .. ' / ' .. Helper_CreateNumberDesc( self.food ) .. "+" .. ( self:GetConsumeFood() > 0 and math.floor( self.food / self:GetConsumeFood() ) or "*" ) )
	ShowText( indent .. 'Supply/Harvest ', Helper_CreateNumberDesc( self:GetSupply() ) .. ' / ' .. Helper_CreateNumberDesc( self:GetHarvestFood() ) )	
	ShowText( indent .. 'Power/Req Pow  ', self:GetMilitaryPower() .. "/" .. self:GetReqMilitaryPower() )
	ShowText( indent .. 'Leader         ', ( self.leader and self.leader.name or "" ) )
	ShowText( indent .. 'Charas         ', #self.charas )	
	--self:DumpCharaDetail( indent )
	ShowText( indent .. 'Troops+Corps   ', #self.troops .. '+' .. #self.corps )
	--self:DumpTroopDetail( indent )
	--self:DumpCorpsDetail( indent )
	ShowText( indent .. 'Construction   ', #self.constrs )
	--self:DumpConstructionDetail( indent )
	ShowText( indent .. 'Plots          ', #self.plots )	
	--self:DumpPlotsDetail( indent )
	ShowText( indent .. 'Tags           ', #self.tags )
	self:DumpTagDetail( indent )
	ShowText( "<<<<<<<<<<<<<<< City <<<<<<<<<<<<<" )
end

function City:Dump( indent, force )
	if not force then
		if 1 then return end
		if IsSimulating() then return end
	end
	if not indent then indent = "" end	
	ShowText( '>>>>>>>>>>>  City >>>>>>>>>>>>>>>>>' )
	ShowText( indent .. '[City] #' .. self.id .. ' Name=' .. self.name .. ' Group=' .. ( self.group and self.group.name or "[none]" ) )
	self:DumpAdjacentDetail( indent )
	ShowText( indent .. 'Popu/Mil Serv  ', Helper_CreateNumberDesc( self.population ) .. "/" .. Helper_CreateNumberDesc( self:GetMSPopulation() ) .. "(Mil)+" .. self.militaryService )
	ShowText( indent .. 'Agri+Ecom+Prod ', self.agriculture .. "/" .. self.maxAgriculture .. " " .. self.economy .. "/" .. self.maxEconomy .. " " .. self.production .. "/" .. self.maxProduction )
	ShowText( indent .. 'Secu/Min Popu  ', self.security .. "/" .. Helper_CreateNumberDesc( self:GetReqPopulation() ) .. "(Req)/" .. Helper_CreateNumberDesc( self:GetMinPopulation() ) .. "(Min)" )
	ShowText( indent .. 'Money / Food   ', Helper_CreateNumberDesc( self.money ) .. ' / ' .. Helper_CreateNumberDesc( self.food ) .. "+" .. ( self:GetConsumeFood() > 0 and math.floor( self.food / self:GetConsumeFood() ) or "*" ) )
	ShowText( indent .. 'Supply/Harvest ', Helper_CreateNumberDesc( self:GetSupply() ) .. ' / ' .. Helper_CreateNumberDesc( self:GetHarvestFood() ) )	
	ShowText( indent .. 'Power/Req Pow  ', self:GetMilitaryPower() .. "/" .. self:GetReqMilitaryPower() )
	ShowText( indent .. 'Leader         ', ( self.leader and self.leader.name or "" ) )
	ShowText( indent .. 'Charas         ', #self.charas )	
	self:DumpCharaDetail( indent )
	ShowText( indent .. 'Troops+Corps   ', #self.troops .. '+' .. #self.corps )
	self:DumpTroopDetail( indent )
	self:DumpCorpsDetail( indent )
	ShowText( indent .. 'Construction   ', #self.constrs )
	self:DumpConstructionDetail( indent )
	ShowText( indent .. 'Plots          ', #self.plots )	
	--self:DumpPlotsDetail( indent )
	ShowText( indent .. 'Tags           ', #self.tags )
	self:DumpTagDetail( indent )
	ShowText( "<<<<<<<<<<<<<<< City <<<<<<<<<<<<<" )
end

----------------------------------
-- Data operation for fixing problem
----------------------------------

function City:AddCorps( corps )	
	Helper_AddDataSafety( self.corps, corps )
end
function City:RemoveCorps( corps )
	Helper_RemoveDataSafety( self.corps, corps )
end
function City:AddTroop( troop )
	Helper_AddDataSafety( self.troops, troop )
end
function City:RemoveTroop( troop )
	Helper_RemoveDataSafety( self.troops, troop )
end
function City:AddChara( chara )
	Helper_AddDataSafety( self.charas, chara )
end
function City:RemoveChara( chara )
	Helper_RemoveDataSafety( self.charas, chara )
end

----------------------------------
-- Iteration operation
----------------------------------
function City:ForeachAdjacentCity( fn )
	for k, city in ipairs( self.adjacentCities ) do
		fn( city )
	end
end

function City:ForeachChara( fn )
	for k, chara in ipairs( self.charas ) do
		fn( chara )
	end
end

----------------------------------
-- Order operation
----------------------------------
function City:LosePopulation( number )
	self.population = self.population - number
end

function City:Instruct( instruction )
	self.instruction = instruction
end

function City:EstablishCorps( corps )
	table.insert( self.corps, corps )
	corps:JoinGroup( self.group, self )
	
	--put corps into group
	if self.group then
		self.group:EstablishCorps( corps )
	end
end

function City:Patrol()
	local oldSecurity = self.security
	self.security = 0
	for k, plot in ipairs( self.plots ) do
		local current = plot:GetAsset( PlotAssetType.SECURITY )
		local delta   = Random_SyncGetRange( CityParams.PATROL.MINIMUM_EFFECT, CityParams.PATROL.MAXIMUM_EFFECT )
		local final   = MathUtility_Clamp( current + delta, 0, PlotParams.MAX_PLOT_SECURITY )
		plot:SetAsset( PlotAssetType.SECURITY, final )
		self.security = self.security + final
	end
	self.security = math.floor( self.security / #self.plots )
	--print( self.name, "Patrol result security=" .. oldSecurity .. "->" .. self.security )
end

function City:Farm()
	local oldValue = self.agriculture
	local increase = 0
	self.agriculture = 0
	for k, plot in ipairs( self.plots ) do
		local current = plot:GetAsset( PlotAssetType.AGRICULTURE )
		local delta   = CalcFarmBonusValue( current, plot.maxAgriculture )
		local final   = MathUtility_Clamp( current + delta, 0, plot.maxAgriculture )
		plot:SetAsset( PlotAssetType.AGRICULTURE, final )
		self.agriculture = self.agriculture + final
		increase = increase + delta
	end
	Debug_Normal( "Farm result agriculture=" .. oldValue .. "->" .. self.agriculture .. "/" .. self.maxAgriculture .. " +" .. increase )
end

function City:Invest()	
	local oldValue = self.economy
	local increase = 0
	self.economy = 0
	for k, plot in ipairs( self.plots ) do
		local current = plot:GetAsset( PlotAssetType.ECONOMY )
		local delta   = CalcInvestBonusValue( current, plot.maxEconomy )
		local final   = MathUtility_Clamp( current + delta, 0, plot.maxEconomy )
		plot:SetAsset( PlotAssetType.ECONOMY, final )
		self.economy = self.economy + final
		increase = increase + delta
	end
	Debug_Normal( "Farm result economy=" .. oldValue .. "->" .. self.economy .. "/" .. self.maxEconomy .. " +" .. increase )
	
	--local proDelta = CalcInvestBonusValue( self.production, self.maxProduction )
	--self.production = MathUtility_Clamp( self.production + proDelta, 0, self.maxProduction )	
	--Debug_Normal( "Invest result economy=" .. self.production .. "/" .. self.maxProduction .. " +" .. proDelta )
end

function City:Harvest()
	--Harvest
	local oldValue = self.food
	local harvest = self:GetHarvestFood()
	self.food = self.food + harvest
	if not self:GetGroup() then
		self.food = MathUtility_Clamp( self.food, 0, self.population * CityParams.FOOD.NONGROUP_CITY_FOODRESERVE_TIMES )
	end
	--ShowText( self.name, "Harvest food", oldValue .. "+" .. harvest .. "->" .. self.food )
end

function City:GetConsumeFood()
	return self:GetMilitaryPower()
end

function City:ConsumeFood()
	--Consume
	local consume = self:GetConsumeFood()
	--ShowText( self.name, "Consume food", self.food .. "-" .. consume .. "->" .. ( self.food - consume ) )
	self.food = self.food - consume	
	if self.food < 0 then
		self:AppendTag( CityTag.STARVATION, 1, CityTag.MAX_VALUE["STARVATION"] )
	else
		self:RemoveTag( CityTag.STARVATION )
	end
	--Corrupt
	if self.food > 0 then
		local corruption = math.ceil( self.food * CityParams.FOOD.FOOD_CORRUPTION_MODULUS )		
		--ShowText( self.name, "Food Corrupt", self.food .."-" .. corruption .."->"..( self.food - corruption) )
		self.food = self.food - corruption
	end
end

function City:Maintain()
	local maintainTroop = self:CalcMaintenanceCost()
	self.money = self.money - maintainTroop
	if self.money < 0 then
		self.money = 0
		self:AppendTag( CityTag.BANKRUPT, 1, CityTag.MAX_VALUE["BANKRUPT"] )
	end
end

function City:LevyTax( income )
	if self:GetGroup() then
		local reserveMoney = math.floor( income * CityParams.CITY_TAX_RESERVE_RATE )
		self.money = self.money + reserveMoney		
		local turnOverMoney = income - reserveMoney
		if turnOverMoney then
			if self:GetGroup() and self:GetGroup():GetCapital() == self then
				self:GetGroup():ReceiveTax( turnOverMoney, self )
			else
				g_movingActorMng:CreateActor( MovingActorType.CASH_TRUCK, { number = turnOverMoney, group = self:GetGroup(), location = self } )
			end
		end
	else
		self.money = self.money + income
	end
end

function City:PrepareRecruit( number )
	self.militaryService = self.militaryService + number
	self.population = self.population - number
	--InputUtility_Pause( self.name .. "prepare", self.militaryService, number )
end

function City:CancelRecruit( number )
	self.militaryService = self.militaryService - number
	self.population = self.population + number
	--InputUtility_Pause( self.name .. "cancel", self.militaryService, number )
end

function City:AddTroop( troop )
	table.insert( self.troops, troop )
	self._militaryPower = self._militaryPower + troop.number
end

function City:RecruitTroop( troop )
	table.insert( self.troops, troop )
	troop.location   = self
	troop.home = self
	if self:GetGroup() then
		self:GetGroup():RecruitTroop( troop )
	end	
	self.militaryService = self.militaryService - troop.number
	self._militaryPower = self._militaryPower + troop.number
	--InputUtility_Pause( self.name .. "finish", self.militaryService, troop.number )
	
	--reduce agriculture/economy/production	
end

function City:BuildConstruction( constr )
	table.insert( self.constrs, constr )
end

function City:FindAdjacentCityByGroup( group )
	local cities = {}
	for k, city in ipairs( self.adjacentCities ) do
		if city:GetGroup() == group then
			table.insert( cities, city )
		end
	end
	if #cities == 0 then
		if self:GetGroup() then
			return self:GetGroup():GetCapital()
		end
	end
	local index = Random_SyncGetRange( 1, #cities )
	return cities[index]
end

function City:SelectLeader( leader )
	--Helper_DumpName( self.charas, function ( chara ) return MathUtility_FindEnumName( CharacterStatus, chara.status ) end )
	if #self.charas ~= 0 then
		print( self.name, " vote leader=".. NameIDToString( leader ), " old=" .. NameIDToString( self.leader ), "chara=", #self.charas )
	end
	self.leader = leader
	if #self.charas ~= 0 and not self.leader then
		quickSimulate = false
		self:Dump( nil, true )
		InputUtility_Pause( "select leader" )
		quickSimulate = true
	end
end

function City:VoteLeader()
	--find new leader
	local reference = nil	
	for k, chara in ipairs( self.charas ) do
		if chara:IsInService() and ( not reference or chara:IsMoreImportant( reference ) ) then
			reference = chara
		end
	end
	return reference
end

function City:CheckLeader()
	if ( not self.leader or not self.leader:IsInService() ) and #self.charas > 0 then
		self:SelectLeader( self:VoteLeader() )
	end
end

--[[
function City:CharaEnter( chara )
	chara.location = self
	table.insert( self.charas, chara )
end
]]

function City:JoinGroup( group )
	self.group = group
	
	--reset datas
	self.instruction = CityInstruction.NONE
end

----------------------------------
-- 
----------------------------------
function City:UpdateDynamicData()
	--update build
	self._canBuildConstructions = nil
	self._canRecruitTroops = nil
	
	self._militaryPower = -1
end

function City:CheckData()
	local hint = ""
	function CheckData( datas, city )
		for k, data in ipairs( datas ) do
			if data:GetHome() ~= city then
				local content = ( NameIDToString( data ) .. " isn't in " .. city.name .. ", now is in " .. ( data:GetHome() and data:GetHome().name or "none" ) ) .. " | "
				hint = hint .. content
				print( content )
			end
		end
	end
	CheckData( self.corps, self )
	CheckData( self.troops, self )
	CheckData( self.charas, self )	
	if string.len( hint ) > 0 then
		quickSimulate = false
		self:Dump( nil, true )
		InputUtility_Pause( hint )
	end
end

function City:Update()
	--Temp data
	self:UpdateDynamicData()
	
	--check data is wrong?
	self:CheckData()

	--check leader
	self:CheckLeader()
	
	--Adjacent
	for k, otherCity in ipairs( self.adjacentCities ) do		
		if self.group and otherCity:GetGroup() ~= self.group then
			self:AppendTag( CityTag.FRONTIER, 1, CityTag.MAX_VALUE["FRONTIER"] )
			if otherCity:GetGroup() and self:GetGroup():IsBelligerent( otherCity:GetGroup() ) then
				self:AppendTag( CityTag.BATTLEFRONT, 1, CityTag.MAX_VALUE["BATTLEFRONT"] )
			end
		end
	end
	
	--Starvation
	local tag = self:GetTag( CityTag.STARVATION )
	if tag and tag.value > 1 then
		local people = math.ceil( self.population * ( ( 1 + CityParams.POPULATION.STARVATION_DECREASE_MODULUS * tag.value ) ^ tag.value - 1 ) )		
		self.population = self.population - people
		
		--starve to death
		local dead = math.ceil( people * CityParams.POPULATION.STARVATION_DEAD_MODULUS )		
				
		--starve to become refugees
		local refugee = people - dead
		g_movingActorMng:CreateActor( MovingActorType.REFUGEE, { number = refugee, location = self } )
		
		ShowText( NameIDToString( self ) .. " in starvation, "..dead.." people die, " .. refugee .. " become refugee, left " .. self.population )
	end

	--Harvest
	if Helper_IsHarvestTime() then
		self:Harvest()
	end
	
	--Levy Tax
	if Helper_IsLevyTaxTime() then
		local income = self:GetIncome()
		self:LevyTax( income )
	end
	
	--Consume food by troop
	self:ConsumeFood()
	
	--Consume money to maintain troops and construction, etc
	self:Maintain()	
		
	--Security down
	if self:IsInConflict() then
		local plotNumber = #self.plots
		self.security = MathUtility_Clamp( self.security - math.ceil( Random_SyncGetRange( 1, plotNumber ^ 0.5 ) ), 0, PlotParams.MAX_PLOT_SECURITY )
		--if self.security < 40 then InputUtility_Pause( self.name  .. "="..self.security ) end
	end
	
	--Development down
	if not self:IsPopulationEnough() then
		if self.agriculture > self.maxAgriculture * 0.35 then
			self.agriculture = MathUtility_Clamp( self.agriculture - math.ceil( Random_SyncGetRange( 5, 10 ) * self.agriculture * 0.01 ), 0, nil )		
		end
		if self.economy > self.maxEconomy * 0.35 then
			self.economy     = MathUtility_Clamp( self.economy - math.ceil( Random_SyncGetRange( 5, 10 ) * self.economy * 0.01 ), 0, nil )		
		end
	end
	
	--Guards
	local maxGuardNumber = QueryCityGuardsLimit( self )
	if self.guards < maxGuardNumber then
		local recoverGuard = QueryCityGuardsRecover( self )
		
		local minPoulation = self:GetMinPopulation()
		if self.population < minPoulation + recoverGuard then
			recoverGuard = minPoulation - self.population
		end
		if recoverGuard > 0 then
			if self.guards + recoverGuard > maxGuardNumber then
				recoverGuard = maxGuardNumber - self.guards
			end
			self.guards = self.guards + recoverGuard
			self.population = self.population - recoverGuard
		end
	end
	
	--In danger Tag
	local totalPower, maxPower, minPower, number = self:QueryAdajacentCityMilitaryPower()
	local avgPower = number ~= 0 and totalPower / number or 0
	local localPower = self:GetPower()
	if localPower < minPower * CityParams.MILITARY.INDANGER_ADJACENT_MINPOWER_MODULUS
		or localPower * CityParams.MILITARY.INDANGER_ADJACENT_MAXPOWER_MODULUS < maxPower
		or localPower * CityParams.MILITARY.INDANGER_ADJACENT_TOTALPOWER_MODULUS < totalPower
		or localPower * CityParams.MILITARY.INDANGER_ADJACENT_AVERAGEPOWER_MODULUS < avgPower then
		local content = self.name .. " in danger=" .. localPower
		if localPower < minPower * CityParams.MILITARY.INDANGER_ADJACENT_MINPOWER_MODULUS then
			content = content .. " min=" .. localPower .. "/" .. minPower * CityParams.MILITARY.INDANGER_ADJACENT_MINPOWER_MODULUS
		end
		if localPower * CityParams.MILITARY.INDANGER_ADJACENT_MAXPOWER_MODULUS < maxPower then
			content = content .. " max=" .. localPower * CityParams.MILITARY.INDANGER_ADJACENT_MAXPOWER_MODULUS .. "/" .. maxPower
		end
		if localPower * CityParams.MILITARY.INDANGER_ADJACENT_TOTALPOWER_MODULUS < totalPower then
			content = content .. " tot=" .. localPower * CityParams.MILITARY.INDANGER_ADJACENT_TOTALPOWER_MODULUS .. "/" .. totalPower
		end
		if localPower * CityParams.MILITARY.INDANGER_ADJACENT_AVERAGEPOWER_MODULUS < avgPower then
			content = content .. " tot=" .. localPower * CityParams.MILITARY.INDANGER_ADJACENT_TOTALPOWER_MODULUS .. "/" .. totalPower
		end
		--print( content )
		self:AppendTag( CityTag.INDANGER, 1 )
	else
		self:RemoveTag( CityTag.INDANGER )
	end
	
	--weak
	if localPower < self:GetReqMilitaryPower() then
		self:AppendTag( CityTag.WEAK, 1 )
	else
		self:RemoveTag( CityTag.WEAK )
	end
	
	--InputUtility_Pause( "update city=" .. self.name .. " " .. #self.tags )
end