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
	self._group         = nil
		
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
			
			--helper check
			--print( "check data", self.id, self.name, chara.name )
			if self._group and not self._group:HasChara( chara ) then
				self._group:CharaJoin( chara )
				chara:JoinGroup( self._group )				
				Debug_Assert( nil, "Chara is in the city, but not not in the group" )
			end
		end
	end
	self.charas = charas
	
	local troops = {}
	for k, id in ipairs( self.troops ) do
		local troop = g_troopDataMng:GetData( id )
		if troop.encampment == 0 then
			--print( "Add missing encampment data for troop" )
			troop.location   = self.id
			troop.encampment = self.id
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
				print( "Add missing troop ["..troop.."] of corp in city ["..self.name.."]" )
				table.insert( self.troops, g_troopDataMng:GetData( troop ) )
			end
		end
	end

	self:SetPlots( self.plots, true )
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
		if allocate then
			table.insert( plots, plot )
		end
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
		--print( plotDesc )
		print( "population=" .. Helper_CreateNumberDesc( self.population ) .. "/" .. Helper_CreateNumberDesc( CalcPlotPopulation( self.livingspace ) ) .. "("..self.livingspace..")" )	
		print( "agr="..self.agriculture.."/"..self.maxAgriculture.." Supply="..Helper_CreateNumberDesc( CalcPlotSupply( self.agriculture ) - self.population ) .. "/" .. Helper_CreateNumberDesc( CalcPlotSupply( self.maxAgriculture ) - self.population ) .. " Surplus="..Helper_CreateNumberDesc( CalcPlotSupply( self.agriculture ) - self.population ).."/"..Helper_CreateNumberDesc( CalcPlotSupply( self.maxAgriculture ) - CalcPlotPopulation( self.livingspace ) ) )
		print( "eco="..self.economy.."/"..self.maxEconomy.. " pro="..self.production.."/"..self.maxProduction .. " sec=" ..self.security )	
		print( "military=" .. self:GetMilitaryPower() .. "/" .. self:GetRequiredMilitaryPower() )	
		--InputUtility_Pause( "" )
	end
	if allocate then
		self.plots = plots
	end	
end

function City:SetPlots( plotDatas, reset )
	self.plots = plotDatas
	
	if reset then
		self:UpdatePlots( true )
	end
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

function City:IsCharaStayCity( chara )
	--if not MathUtility_IndexOf( self.charas, chara.id, "id" )  then return false end
	return chara:GetLocation() == self
end

function City:IsInSiege()
	return self:GetTag( CityTag.SIEGE )
end

-- Is city in conflict, like g_warfare, rebellion
function City:IsInConflict()	
	return self:GetTag( CityTag.SIEGE ) or self:GetTag( CityTag.BATTLEFRONT )
end

function City:IsBattleFront()
	return self:GetTag( CityTag.BATTLEFRONT )
end

function City:IsFrontier()
	return self:GetTag( CityTag.FRONTIER ) ~= nil
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

function City:IsAdjacentGroup( group )
	for k, city in ipairs( self.adjacentCities ) do
		if city._group == group then return true end
	end
	return false
end

function City:IsBelongToGroup( group )
	return self._group == group
end

----------------------------------
-- Getter 
----------------------------------

function City:GetGroup()
	return self._group
end

function City:GetLeader()
	return self.leader
end

function City:GetCoordinate()
	return self.coordinate
end

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
		return otherGroup and otherGroup ~= self:GetGroup() and self:GetGroup():IsBelligerent( otherGroup )
	end )
end

-----------------------------------------------------
-- Below Getter mostly use in Task Manager

-- character who can attend meeting
function City:GetNumOfIdleChara()
	return Helper_CountIf( self.charas, function( chara )
		return chara:IsStayCity( self ) and not g_taskMng:GetTaskByActor( chara )
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
		return not chara:IsLeadTroop() and chara:IsStayCity( self ) and not chara:IsImportant() and chara:IsMilitaryOfficer() and not g_taskMng:GetTaskByActor( chara )
	end )
end

function City:GetIdleCorpsList()
	return Helper_ListIf( self.corps, function( corps )
		return corps:IsStayCity( self ) and not g_taskMng:GetTaskByActor( corps )
	end )
end

function City:GetPreparedToAttackCorpsList()
	return Helper_ListIf( self.corps, function( corps )
		return corps:IsStayCity( self ) and corps:IsPreparedToAttack() and not g_taskMng:GetTaskByActor( corps ) and not g_taskMng:GetTaskByActor( corps )
	end )
end

-- Idle corps means Staying in city
function City:GetNumOfIdleCorps()
	return Helper_CountIf( self.corps, function( corps )
		return not corps:IsStayCity( self ) and not g_taskMng:GetTaskByActor( corps )
	end )
end

function City:GetNumOfVacancyCorps()
	return Helper_CountIf( self.corps, function ( corps )
		return corps:IsStayCity( self ) and corps:GetVacancyNumber() > 0 and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetVacancyCorpsList()
	return Helper_ListIf( self.corps, function ( corps )
		return corps:IsStayCity( self ) and corps:GetVacancyNumber() > 0 and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetUnderstaffedCorpsList()
	return Helper_ListIf( self.corps, function ( corps )
		return corps:IsStayCity( self ) and corps:IsUnderstaffed() and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetNumOfUnderstaffedCorps()
	return Helper_CountIf( self.corps, function ( corps )
		return corps:IsStayCity( self ) and corps:IsUnderstaffed() and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetUntrainedCorpsList()
	return Helper_ListIf( self.corps, function ( corps )
		return corps:IsStayCity( self ) and corps:IsUntrained() and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetNumOfUntrainedCorps()
	return Helper_CountIf( self.corps, function ( corps )
		return corps:IsStayCity( self ) and corps:IsUntrained() and not g_taskMng:GetTaskByActor( corps )
	end )
end
function City:GetNumOfNonLeaderTroop()
	return Helper_CountIf( self.troops, function ( troop )	
		return ( not troop:GetCorps() or troop:GetCorps():IsStayCity( self ) ) and not troop:GetLeader() and not g_taskMng:GetTaskByActor( troop )
	end )
end
function City:GetNonLeaderTroopList()
	return Helper_ListIf( self.troops, function( troop )
		return ( not troop:GetCorps() or troop:GetCorps():IsStayCity( self ) ) and not troop:GetLeader() and not g_taskMng:GetTaskByActor( troop )
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

function City:GetMinPopulation()
	return CalcCityMinPopulation( self )
end

function City:GetMilitaryServicePopulation()
	return math.max( 0, self.population - self:GetMinPopulation() )
end

function City:GetRequiredMilitaryPower()
	local plotNumber = #self.plots
	if self:IsBattleFront() then
		return plotNumber * CityParams.MILITARY.BATTLEFRONT_MILITARYPOWER_PER_PLOT
	elseif self:IsFrontier() then
		return plotNumber * CityParams.MILITARY.FRONTIER_MILITARYPOWER_PER_PLOT
	elseif self:GetGroup() and self == self:GetGroup():GetCapital() then
		return plotNumber * CityParams.MILITARY.SECURITY_MILITARYPOWER_PER_PLOT
	end
	return plotNumber * CityParams.MILITARY.SAFETY_MILITARYPOWER_PER_PLOT
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
	local output = self:GetSupply() * CityParams.HARVEST.HARVEST_CYCLE_TIME
	return math.max( output, 0 )
end

function City:GetSupply()
	local bonus, modulus = self:GetSupplyBonus()
	local supply = CalcPlotSupply( ( self.agriculture + bonus ) * modulus )	
	local ret = supply - self.population
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
	for k, constr in ipairs( self._group._canBuildConstructions ) do				
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
	for k, troop in ipairs( self._group._canRecruitTroops ) do
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

function City:QueryAdajacentCityMilitaryPower() 
	local maxPower, minPower, totalPower, number = 0, 99999999, 0, 0
	local group = self:GetGroup()
	for k, otherCity in ipairs( self.adjacentCities ) do 
		local otherGroup = otherCity:GetGroup()
		if otherGroup and otherGroup ~= group then
			local otherPower = otherCity:GetMilitaryPower()
			if otherPower > maxPower then maxPower = otherPower end
			if otherPower < minPower then minPower = otherPower end
			totalPower = totalPower + otherPower
			number = number + 1
		end
	end
	return totalPower, maxPower, minPower, number
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
	return self:IsPopulationEnough() and not self:IsInSiege() and self:GetGroup().money >= QueryInvestNeedMoney( self )
end
function City:CanFarm()
	return self:IsPopulationEnough() and not self:IsInSiege() and self:GetGroup().money >= QueryFarmNeedMoney( self )
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
		if self.city < constr.prerequisites.money and self._group:GetMoney() < constr.prerequisites.money then
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
	return self.instruction == CityInstruction.NONE and not g_taskMng:IsTaskConflict( TaskType.CITY_INSTRUCT, self )
end
function City:CanRecruit()
	return #self:GetRecruitList() > 0 and not self:IsInSiege() and self:IsPopulationEnough() 
end
function City:CanRecruitTroop( troop )
	if troop.prerequisites.constrs then
		for k, constr in ipairs( troop.prerequisites.constrs ) do
			if not MathUtility_IndexOf( self.constrs, constr, "id" ) then
				return false
			end
		end
	end	
	if troop.prerequisites.money and self._group:GetMoney() < troop.prerequisites.money then
		return false
	end	
	return true
end
function City:CanEstablishCorps()
	--number of corps is less than limit
	if #self.corps >= QueryCityCorpsSupport( self ) then 
		print( NameIDToString( self ) .. " only support corps=" .. QueryCityCorpsSupport( self ) )
		return false
	end
	
	--has enough troop not in the crops
	return self:GetNumOfNonCorpsTroop() >= CorpsParams.NUMBER_OF_TROOP_TO_ESTALIBSH
end
function City:CanRegroupCorps()
	--print( "regroup", self.name, #self.corps, #self.troops, self:GetNumOfVacancyCorps(), self:GetNumOfNonCorpsTroop() )
	return not self:IsInSiege() and self:GetNumOfVacancyCorps() > 0 and self:GetNumOfNonCorpsTroop() > 1
end
function City:CanReinforceCorps()
	return not self:IsInSiege() and self:GetNumOfUnderstaffedCorps() > 0 and self.population > self:GetMinPopulation()
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
	end
	print( content )
end

function City:DumpTroopDetail( indent )
	if #self.troops == 0 then return end
	local content = indent .. "    "
	for k, troop in ipairs( self.troops ) do
		content = content .. ( k > 1 and "," or "" ) .. troop.name .. "(".. troop.number..")"
	end
	print( content )
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
	print( content )
end

function City:DumpAdjacentDetail( indent )
	if #self.adjacentCities == 0 then return end
	local content = indent .. "Adja="
	for k, city in ipairs( self.adjacentCities ) do
		content = content .. ( k > 1 and "," or "" ) .. city.name .. "(" .. (city:GetGroup() and city:GetGroup().name or "" ) .. ")"
	end
	print( content )
end

function City:DumpPlotsDetail( indent )
	if #self.plots == 0 then return end
	local content = indent .. "    "
	for k, plot in ipairs( self.plots ) do
		content = content .. ( k > 1 and "," or "" ) .. plot.table.name
	end
	print( content )
end

function City:DumpTagDetail( indent )
	if #self.tags == 0 then return end
	local content = indent .. "    "
	for k, tag in ipairs( self.tags ) do
		content = content .. ( k > 1 and "," or "" ) .. MathUtility_FindEnumName( CityTag, tag.type )
	end
	print( content )
end

function City:DumpSimple( indent )
	if not indent then indent = "" end
	print( indent .. '[City] #' .. self.id .. ' Name=' .. self.name )
end

function City:Dump( indent )
	if 1 then return end
	if not indent then indent = "" end	
	print( '>>>>>>>>>>>  City >>>>>>>>>>>>>>>>>' )
	print( indent .. '[City] #' .. self.id .. ' Name=' .. self.name )
	self:DumpAdjacentDetail( indent )
	print( indent .. 'Popu/Mil Serv  ', self.population .. "/" .. self:GetMilitaryServicePopulation() )
	print( indent .. 'Agri+Ecom+Prod ', self.agriculture .. "/" .. self.maxAgriculture .. " " .. self.economy .. "/" .. self.maxEconomy .. " " .. self.production .. "/" .. self.maxProduction )
	print( indent .. 'Secu/Min Popu  ', self.security .. "/" .. self:GetMinPopulation() )
	print( indent .. 'Supply/Harvest ', self:GetSupply() .. ' / ' .. self:GetHarvestFood() )
	print( indent .. 'Money / Food   ', self.money .. ' / ' .. self.food .. "+" .. ( self:GetConsumeFood() > 0 and math.floor( self.food / self:GetConsumeFood() ) or "*" ) )
	print( indent .. 'Leader         ', ( self.leader and self.leader.name or "" ) )
	print( indent .. 'Charas         ', #self.charas )
	print( indent .. 'Power/Req Pow  ', self:GetMilitaryPower() .. "/" .. self:GetRequiredMilitaryPower() )
	self:DumpCharaDetail( indent )
	print( indent .. 'Troops+Corps   ', #self.troops .. '+' .. #self.corps )
	self:DumpTroopDetail( indent )
	self:DumpCorpsDetail( indent )
	print( indent .. 'Construction   ', #self.constrs )
	self:DumpConstructionDetail( indent )
	print( indent .. 'Plots          ', #self.plots )	
	--self:DumpPlotsDetail( indent )
	print( indent .. 'Tags           ', #self.tags )
	self:DumpTagDetail( indent )
	print( "<<<<<<<<<<<<<<< City <<<<<<<<<<<<<" )
end

----------------------------------
-- Data operation for fixing problem
----------------------------------

function City:AddCorps( corps )
	table.insert( self.corps, corps )
	for k, troop in ipairs( corps.troops ) do
		if typeof( troop ) == "number" then
			print( "!!! troop data is number" )
			troop = g_troopDataMng:GetData( troop )
		end
		table.insert( self.troops, troop )
	end
end

function City:RemoveCorps( corps )
	MathUtility_Remove( self.corps, corps.id, "id" )
	for k, troop in ipairs( corps.troops ) do
		MathUtility_Remove( self.troops, troop.id, "id" )
	end
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
function City:Instruct( instruction )
	self.instruction = instruction
end

function City:EstablishCorps( corps )
	table.insert( self.corps, corps )
	
	--put corps into group
	if self._group then
		self._group:EstablishCorps( corps )
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
	Debug_Normal( "Patrol result security=" .. oldSecurity .. "->" .. self.security )
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
	--print( self.name, "Harvest food", oldValue .. "+" .. harvest .. "->" .. self.food )
end

function City:GetConsumeFood()
	return self:GetMilitaryPower()
end

function City:ConsumeFood()
	--Consume
	local consume = self:GetConsumeFood()
	--print( self.name, "Consume food", self.food .. "-" .. consume .. "->" .. ( self.food - consume ) )
	self.food = self.food - consume	
	if self.food < 0 then
		self:AppendTag( CityTag.STARVATION, 1, CityParams.MAX_TAG_VALUE["STARVATION"] )
	else
		self:RemoveTag( CityTag.STARVATION, CityParams.MAX_TAG_VALUE["STARVATION"] )
	end
	--Corrupt
	if self.food > 0 then
		local corruption = math.ceil( self.food * CityParams.FOOD.FOOD_CORRUPTION_MODULUS )		
		--print( self.name, "Food Corrupt", self.food .."-" .. corruption .."->"..( self.food - corruption) )
		self.food = self.food - corruption
	end
end

function City:GetTroopSalary()

end

function City:Maintain()
	local maintainTroop = self:GetTroopSalary()
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
				g_movingActorMng:AddMovingActor( MovingActorType.CASH_TRUCK, { number = turnOverMoney, group = self:GetGroup(), location = self } )
			end
		end
	else
		self.money = self.money + income
	end
end


function City:RecruitTroop( troop )
	table.insert( self.troops, troop )
	troop.location   = self
	troop.encampment = self
	self._group:RecruitTroop( troop )
	self._militaryPower = self._militaryPower + troop.number
end

function City:BuildConstruction( constr )
	table.insert( self.constrs, constr )
end

function City:CharaLeave( chara )
	MathUtility_Remove( self.charas, chara.id, "id" )
end

function City:CharaLive( chara )
	chara.location = self
	chara.home     = self
	table.insert( self.charas, chara )
end

function City:CharaEnter( chara )
	chara.location = self
	table.insert( self.charas, chara )
end

function City:JoinGroup( group )
	self._group = group
	
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

function City:Update()
	--Starvation	
	local tag = self:GetTag( CityTag.STARVATION )
	if tag and tag.value > 1 then
		local people = math.ceil( self.population * ( ( 1 + CityParams.POPULATION.STARVATION_DECREASE_MODULUS * tag.value ) ^ tag.value - 1 ) )		
		self.population = self.population - people
		
		--starve to death
		local dead = math.ceil( people * CityParams.POPULATION.STARVATION_DEAD_MODULUS )		
				
		--starve to become refugees
		local refugee = people - dead
		g_movingActorMng:AddMovingActor( MovingActorType.REFUGEE, { number = refugee, location = self } )
		
		print( NameIDToString( self ) .. " in starvation, "..dead.." people die, " .. refugee .. " become refugee, left " .. self.population )
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
	
	self:ConsumeFood()
	
	self:Maintain()
	
	--Adjacent	
	for k, otherCity in ipairs( self.adjacentCities ) do		
		if self._group and otherCity._group ~= self._group then
			self:AppendTag( CityTag.FRONTIER, 1, CityParams.MAX_TAG_VALUE["FRONTIER"] )
			if otherCity._group and self._group:IsBelligerent( otherCity._group ) then
				self:AppendTag( CityTag.BATTLEFRONT, 1, CityParams.MAX_TAG_VALUE["BATTLEFRONT"] )
			end
		end
	end
	
	--Temp data
	self:UpdateDynamicData()
	
	--InputUtility_Pause( "update city=" .. self.name .. " " .. #self.tags )
end