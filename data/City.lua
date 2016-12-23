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
	
	self.position    = MathUtility_Copy( data.position )
	
	self.population  = data.population or ""
	
	self.money       = data.money or 0
	
	self.food        = data.food or 0
	
	self.size        = CitySize[data.size] or CitySize.TOWN

	self.tags        = MathUtility_Copy( data.tags )
	
	--Agriculture Surplus -> Growth
	--Economy Surplus     -> Culture & Tech
	--Production Surplus  -> 	
	
	--Determines supply
	--Supply use to feed troops and people
	--First, supply provide to the troops, not enough part will cause troop get a debuff ( debuff will increase during starvation, troop will disapear when it's reach the line )
	--Second, left supply provides to people, it will cause buff or debuff which will lead population increase or decrease.
	self.agriculture    = data.agriculture or 0
	
	--Determine income every turn
	self.economy        = data.economy or 0
	
	--Determine how many turn cost to build construction
	self.production     = data.production or 0
	
	-----------------------------------
	-- extension
	
	--Culture circle
	--More deep effects
	self.cultrueCircle = data.cultureCircle or 0
	
	--Determine ???
	self.security    = data.security or 0
	
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
	
	--Resource around
	self.resources   = MathUtility_Copy( data.resources )

	--Control Plots
	self.plots       = MathUtility_Copy( data.plots )
	
	-----------------------------------
	-- Dynamic Data
	self._group         = nil
	
	--Determines how many troop can supply
	self._supplyIncome  = 0
	self._supplyConsume = 0
	
	self._moneyIncome   = 0
	
	self._economyPower  = -1
	self._militaryPower = -1
	self._traitPower    = 0
	
	self._canBuildConstructions = nil
	self._canRecruitTroops = nil
end

function City:SaveData()
	self.size = MathUtility_FindEnumKey( CitySize, self.size )

	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	Data_OutputValue( "id", self )
	Data_OutputValue( "name", self )
	
	Data_OutputTable( "position", self )
	Data_OutputValue( "population", self )
	
	Data_OutputValue( "money", self )
	Data_OutputValue( "food", self )
	
	Data_OutputValue( "size", self )	
	Data_OutputValue( "agriculture", self )
	Data_OutputValue( "economy", self )
	Data_OutputValue( "production", self )
	
	Data_OutputValue( "cultrueCircle", self )
	Data_OutputValue( "security", self )
	Data_OutputValue( "politicalPoint", self )
	
	Data_OutputValue( "instruction", self )
	
	Data_OutputTable( "adjacentCities", self, "id" )

	Data_OutputTable( "tags", self )
	Data_OutputTable( "traits", self )
	
	Data_OutputTable( "charas", self, "id" )
	Data_OutputTable( "troops", self, "id" )
	Data_OutputTable( "corps", self, "id" )
	Data_OutputTable( "constrs", self, "id" )
	Data_OutputTable( "resources", self, "id" )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
	
	self.size = CitySize[self.size]
end

function City:ConvertID2Data()
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
			print( "Add missing encampment data for troop" )
			troop.location   = self.id
			troop.encampment = self.id
		end
		table.insert( troops, troop )
	end
	self.troops = troops
	
	local constrs = {}
	for k, id in ipairs( self.constrs ) do
		table.insert( constrs, g_constrTableMng:GetData( id ) )
	end
	self.constrs = constrs
	
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
	
	local resources = {}
	for k, res in ipairs( self.resources ) do
		local res = g_resourceTableMng:GetData( res )
		table.insert( resources, res )
	end
	self.resources = resources
	
	self:InitPlots( self.plots, true )
	
	--[[
	local resources = {}
	for k, id in ipairs( self.resources ) do
		table.insert( resources, g_constrTableMng:GetData( id ) )
	end
	self.resources = resources
	]]
end

function City:InitPlots( plotDatas, reset )
	self.plots = plotDatas
	
	if reset then
		self.maxAgriculture = CityParams[self.size].STANDARD_AGRICULTURE
		self.maxEconomy     = CityParams[self.size].STANDARD_ECONOMY
		self.maxProduction  = CityParams[self.size].STANDARD_PRODUCTION
		local plots = {}
		--print( self.name, plotDatas, self.plots )
		for k, pos in pairs( self.plots ) do
			local plot = g_plotMap:GetPlot( pos.x, pos.y )
			table.insert( plots, plot )
			--calculate real arg/eco/prod
			if plot and plot.table then
				self.maxAgriculture = self.maxAgriculture + plot.table:GetTraitValue( PlotTraitType.AGRICULTURE )
				self.maxEconomy     = self.maxEconomy + plot.table:GetTraitValue( PlotTraitType.ECONOMIC )
				self.maxProduction  = self.maxProduction + plot.table:GetTraitValue( PlotTraitType.PRODUCTION )
			end		
		end
		if typeof( self.agriculture ) == "string" then
			local str = string.gsub( self.agriculture, "%%", "" )
			self.agriculture = math.ceil( self.maxAgriculture * tonumber( str ) * 0.01 )
		end
		if typeof( self.economy ) == "string" then 
			local str = string.gsub( self.economy, "%%", "" )
			self.economy = math.ceil( self.maxEconomy * tonumber( str ) * 0.01 )
		end
		if typeof( self.production ) == "string" then 
			local str = string.gsub( self.production, "%%", "" )
			self.production = math.ceil( self.maxProduction * tonumber( str ) * 0.01 )
		end
		self.plots = plots
		print( self.name .. " plot="..#self.plots.." agr="..self.maxAgriculture.. " eco="..self.maxEconomy.. " pro="..self.maxProduction )
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

function City:IsBorder()
	return self:GetTag( CityTag.BORDER ) ~= nil
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

function City:GetPosition()
	return self.position
end

function City:GetAdjacentGroupMilitaryPowerList()
	local list = {}
	local group = self:GetGroup()
	for k, city in ipairs( self.adjacentCities ) do 
		local otherGroup = city:GetGroup()
		if otherGroup and otherGroup ~= group then
			if list[otherGroup.id] then
				list[otherGroup.id] = list[otherGroup.id] + city:GetMilitaryPower()
			else
				list[otherGroup.id] = city:GetMilitaryPower()
			end
		end
	end
	return list
end

function City:GetAdjacentHostileCityList()
	local list = {}
	local group = self:GetGroup()
	for k, city in ipairs( self.adjacentCities ) do 
		local otherGroup = city:GetGroup()
		if otherGroup ~= group then			
			if group:IsHostility( otherGroup ) then
				table.insert( list, city )
			end
		end
	end
	return list
end

function City:GetAdjacentBelligerentCityList()
	local list = {}
	local group = self:GetGroup()
	for k, city in ipairs( self.adjacentCities ) do
		local otherGroup = city:GetGroup()
		if otherGroup and otherGroup ~= group then
			if group:IsBelligerent( otherGroup ) then
				table.insert( list, city )
			end
		end
	end
	return list
end

-- character who can attend meeting
function City:GetNumOfIdleChara()
	local count = 0
	for k, chara in ipairs( self.charas ) do
		if chara:IsStayCity( self ) then
			count = count + 1
		end
	end
	return count 
end

function City:GetNumOfFreeChara()
	local count = 0
	for k, chara in ipairs( self.charas ) do
		--print( "chara=", chara.name, chara:IsLeadTroop(), chara:IsStayCity( self ), chara:IsImportant() )
		if chara:IsFree() then
			count = count + 1
		end
	end
	return count
end

function City:GetFreeCharaList()
	local list = {}
	for k, chara in ipairs( self.charas ) do
		if not chara:IsLeadTroop() and chara:IsStayCity( self ) and not chara:IsImportant() then
			table.insert( list, chara )
		end
	end
	return list
end

function City:GetIdleCorpsList()
	local list = {}
	for k, corps in ipairs( self.corps ) do
		if corps:IsStayCity( self ) then
			table.insert( list, corps )
		end
	end
	return list
end

-- Idle corps means Staying in city
function City:GetNumOfIdleCorps()
	local count = 0
	for k, corps in ipairs( self.corps ) do
		if not corps:IsStayCity( self ) then
			count = count + 1
		end
	end
	return count
end

function City:GetNumOfVacancyCorps()
	local count = 0
	for k, corps in ipairs( self.corps ) do
		if corps:IsStayCity( self ) and corps:GetVacancyNumber() > 0 then
			count = count + 1
		end
	end
	return count
end
function City:GetVacancyCorpsList()
	local list = {}
	for k, corps in ipairs( self.corps ) do
		if corps:IsStayCity( self ) and corps:GetVacancyNumber() > 0 then
			table.insert( list, corps )
		end
	end
	return list
end

function City:GetNumOfNonLeaderTroop()
	local count = 0
	for k, troop in ipairs( self.troops ) do
		if ( not troop:GetCorps() or troop:GetCorps():IsStayCity( self ) ) and not troop:GetLeader() then
			count = count + 1
		end
	end
	return count
end
function City:GetNonLeaderTroopList()
	local list = {}
	for k, troop in ipairs( self.troops ) do
		if ( not troop:GetCorps() or troop:GetCorps():IsStayCity( self ) ) and not troop:GetLeader() then
			table.insert( list, troop )
		end
	end
	return list
end

function City:GetNumOfNonCorpsTroop()
	local count = 0
	for k, troop in ipairs( self.troops ) do
		if not troop:GetCorps() then
			count = count + 1
		end
	end
	return count
end
function City:GetNonCorpsTroopList()
	local list = {}
	for k, troop in ipairs( self.troops ) do
		if not troop:GetCorps() then
			table.insert( list, troop )
		end
	end
	return list
end

function City:GetMaxTraitPower()
	if self._traitPower > 0 then return self._traitPower end
	
	local power = 0
	for k, v in ipairs( self.traits ) do
		if power < v.value then power = v.value end
	end	
	self._traitPower = power
	return self._traitPower
end

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
	return CityParams[self.size].MIN_POPULATION
end

function City:GetFormulaPopuplation()
	return self.population > 0 and self.population or CityParams[self.size].MAX_POPULATION
end

function City:GetSafetyMilitaryPower()
	local reqPower = self:GetFormulaPopuplation() * CityParams[self.size].SAFETY_MILITARY_MODULUS
	return reqPower
end

function City:GetSecurityMilitaryPower()
	local reqPower = self:GetFormulaPopuplation() * CityParams[self.size].SECURITY_MILITARY_MODULUS	
	return reqPower
end

function City:GetBattlefrontMilitaryPower()
	local reqPower = self:GetFormulaPopuplation() * CityParams[self.size].BATTLEFRONT_MILITARY_MODULUS
	return reqPower
end

function City:GetSupplyModulus()
	local standard = CityParams.SUPPLY.SUPPLY_PER_MODULUS_UNIT
	local modulus = 0
	local modulusNum = 0
	for k, resource in ipairs( self.resources ) do
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
	if modulus == 0 then
		modulus = 1
	else
		modulus = modulus / modulusNum
	end
	--print( "supply=", standard, modulus, modulusNum )
	return math.floor( standard * modulus )
end

function City:GetHarvestGrain()
	return math.ceil( self.agriculture * self:GetSupplyModulus() + CityParams.SUPPLY.SUPPLY_POPULATION_MODULUS * self.population )
end

function City:GetSupply()
	return math.ceil( self.agriculture * self:GetSupplyModulus() + CityParams.SUPPLY.SUPPLY_POPULATION_MODULUS * self.population ) - self.population
end

function City:GetMaxSupply()
	return math.ceil( self.maxAgriculture * self:GetSupplyModulus() + CityParams.SUPPLY.SUPPLY_POPULATION_MODULUS * self.population ) - self.population
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
	return Helper_GetTag( self.tags, tagType )
end

function City:AppendTag( tagType, value, range )
	Helper_AppendTag( self.tags, tagType, value, range )
end

function City:RemoveTag( tagType, value )
	Helper_RemoveTag( self.tags, tagType, value )
end

------------------------------------------

function City:CanDispatch()
	return not self:IsInSiege()
end

function City:CanRecruit()
	return self:GetRecruitList() and #self._canRecruitTroops > 0 and not self:IsInSiege() 
end

function City:CanBuild()
	return self:GetBuildList() and #self._canBuildConstructions > 0 and not self:IsInSiege() 
end

-- Check city is not building any construction or recruit any troop
function City:CanInvest()
	return not self:IsInSiege() and self:GetGroup().money >= QueryInvestNeedMoney( self )
end

function City:CanLevyTax()
	return not self:IsInSiege()
end

function City:CanRecruitTroop( troop )
	if troop.prerequisites.constrs then
		for k, constr in ipairs( troop.prerequisites.constrs ) do
			if not MathUtility_IndexOf( self.constrs, constr, "id" ) then
				return false
			end
		end
	end
	
	if troop.prerequisites.money then
		if self._group:GetMoney() < troop.prerequisites.money then
			return false
		end
	end
	
	return true
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

function City:CanEstablishCorps()
	--number of corps is less than limit
	if #self.corps >= math.floor( self.size / 2 ) then return false end
	
	--has enough troop not in the crops
	return self:GetNumOfNonCorpsTroop() >= CorpsParams.NUMBER_OF_TROOP_TO_ESTALIBSH
end

function City:CanReinforceCorps()
	--print( "reinforce", self.name, #self.corps, #self.troops, self:GetNumOfVacancyCorps(), self:GetNumOfNonCorpsTroop() )
	return self:GetNumOfVacancyCorps() > 0 and self:GetNumOfNonCorpsTroop() > 0
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

function City:DumpResourceDetail( indent )
	if #self.resources == 0 then return end
	local content = indent .. "    "
	for k, resource in ipairs( self.resources ) do
		content = content .. ( k > 1 and "," or "" ) .. resource.name
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
	if not indent then indent = "" end	
	print( '>>>>>>>>>>>  City >>>>>>>>>>>>>>>>>' )
	print( indent .. '[City] #' .. self.id .. ' Name=' .. self.name )
	self:DumpAdjacentDetail( indent )
	print( indent .. "Population", self.population )	
	print( indent .. 'Agri+Ecom+Prod ', self.agriculture .. "/" .. self.maxAgriculture .. " " .. self.economy .. "/" .. self.maxEconomy .. " " .. self.production .. "/" .. self.maxProduction )
	print( indent .. 'Secu / Popu    ', self.security .. ' / ' .. self.population )
	print( indent .. 'Supply/Harvest ', self:GetSupply() .. ' / ' .. self:GetHarvestGrain() )
	print( indent .. 'Money / Food   ', self.money .. ' / ' .. self.food )
	print( indent .. 'Leader         ', ( self.leader and self.leader.name or "" ) )
	print( indent .. 'Charas         ', #self.charas )
	self:DumpCharaDetail( indent )
	print( indent .. 'Troops+Corps   ', #self.troops .. '+' .. #self.corps )
	self:DumpTroopDetail( indent )
	print( indent .. 'Construction   ', #self.constrs )
	self:DumpConstructionDetail( indent )
	print( indent .. 'Resources      ', #self.resources )	
	self:DumpResourceDetail( indent )
	print( indent .. 'Plots          ', #self.plots )	
	self:DumpPlotsDetail( indent )
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

function City:Invest()
	Debug_Normal( NameIDToString( self ) .. " develop by investment" )
	local agrDelta = CalcInvestBonusValue( self.agriculture, self.maxAgriculture )
	local ecoDelta = CalcInvestBonusValue( self.economy, self.maxEconomy )
	local proDelta = CalcInvestBonusValue( self.production, self.maxProduction )
	--Debug_Normal( self.agriculture .. "/" .. self.maxAgriculture .. " +" .. agrDelta )
	--Debug_Normal( self.economy .. "/" .. self.maxEconomy .. " +" .. ecoDelta )
	--Debug_Normal( self.production .. "/" .. self.maxProduction .. " +" .. proDelta )
	self.agriculture = MathUtility_Clamp( self.agriculture + agrDelta, 0, self.maxAgriculture )
	self.economy = MathUtility_Clamp( self.economy + ecoDelta, 0, self.maxEconomy )
	self.production = MathUtility_Clamp( self.production + proDelta, 0, self.maxProduction )	
end

function City:Harvest()
	--Harvest
	local harvest = self:GetSupply()
	if harvest > 0 then
		self.food = self.food + harvest
		if not self:GetGroup() then
			if self.food > self.population then
				self.food = self.population
			end
		end
		print( "Harves food", harvest, self.food, self.name )
	end
end

function City:ConsumeFood()
	--Consume
	local foodConsume = self:GetMilitaryPower()	
	self.food = self.food - foodConsume
	print( "Consume food", foodConsume, self.food, self.name )
	if self.food < 0 then
		self:AppendTag( CityTag.STARVATION, 1, CityParams.MAX_TRAIT_VALUE["STARVATION"] )
	else
		self:RemoveTag( CityTag.STARVATION, CityParams.MAX_TRAIT_VALUE["STARVATION"] )
	end
end

function City:LevyTax( income )
	if self:GetGroup() then
		local reserveMoney = math.floor( income * CityParams.CITY_TAX_RESERVE_RATE )
		self.money = self.money + reserveMoney		
		local turnOverMoney = income - reserveMoney
		if turnOverMoney then
			if self:GetGroup():GetCapital() == self then
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
	--InputUtility_Pause( "update city=" .. self.name .. " " .. #self.tags )

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

	if Helper_IsHarvestTime() then
		self:Harvest()
	end
	self:ConsumeFood()
	
	--Levy Tax
	if Helper_IsLevyTaxTime() then
		local income = self:GetIncome()
		self:LevyTax( income )
	end
	
	--Adjacent	
	for k, otherCity in ipairs( self.adjacentCities ) do		
		if self._group and otherCity._group ~= self._group then
			self:AppendTag( CityTag.BORDER, 1, CityParams.MAX_TRAIT_VALUE["BORDER"] )
			if otherCity._group and self._group:IsHostility( otherCity._group ) then
				self:AppendTag( CityTag.BATTLEFRONT, 1, CityParams.MAX_TRAIT_VALUE["BATTLEFRONT"] )
			end
		end
	end
	
	--Temp data
	self:UpdateDynamicData()
end