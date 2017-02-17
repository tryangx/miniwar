Group = class()

function Group:__init()
	self.proposals = {}
end

function Group:Generate( data )
	self:Load( data )
	self:ConvertID2Data()
end

function Group:Load( data )
	self.id        = data.id
	
	self.name      = data.name
	
	--------------------------------------
	-- Basic	
	
	-- Government type
	self.government = data.government or GroupGovernment.KINGDOM
	
	-- Winning Condition
	self.goals     = MathUtility_Copy( data.goals )	
	
	-- Determine AI tendency affect internal affairs, diplomacy, military
	self.tendency  = data.tendency or GroupTendency.RATIONAL	
	
	---------------------------------------
	-- 
	-- Leader id 
	self.leader     = data.leader or 0
		
	-- capital id
	self.capital   = data.capital or 0	
	
	---------------------------------------
	-- Diplomacy Relative	
	-- Diplomatic Relation
	self.relations = MathUtility_Copy( data.relations )
	
	--Diplomacy Tag
	--  Like militant, betrayer etc
	self.tags      = MathUtility_Copy( data.tags )
	
	--------------------------------------
	-- Asset Data
	--Use to produce / recruit / research / invest
	self.money     = data.money or 0

	--Measure the group how powerful is
	--It determines how many cities it can control
	self.autority  = data.authority or 0
		
	--------------------------------------
	-- Ability Data	
		
	--Determine how many time need to RESEARCH
	self.researchAbility  = data.researchAbility or 0	
	
	--------------------------------------
	-- Additional Data	
	self.cities    = MathUtility_Copy( data.cities )
	
	self.corps     = MathUtility_Copy( data.corps )
	
	self.troops    = MathUtility_Copy( data.troops )
	
	self.charas    = MathUtility_Copy( data.charas )
	
	self.techs     = MathUtility_Copy( data.techs )

	self.policies  = MathUtility_Copy( data.policies )
	
	-- should abandon
	self.formations = MathUtility_Copy( data.formations )	

	--------------------------------------
	-- Dynamic Data
		
	--Tech
	self.researchPoints = 0
	self.researchTechId = 0
		
	--Diplomatic
	self.diplomaticTargetId = 0
	self.diplomaticMethod   = 0
	
		--Military
	self.militaryTargetId = 0
	self.militaryMoved    = 0
	
	--------------------------------------
	-- Test Data
	self.power = data.power or nil
	
	--------------------------------------
	-- Running Data
	
	self._politicalPower = -1
	
	self._militaryPower = -1
	
	--Determine how many money increase every turn
	--Convert into money simply
	self._income    = 100
	
	--Maintain troops
	self._consume   = 0
	
	self._supply    = 0
	
	-------------------------------------
	
	self._canResearchTechs = nil
	
	self._canRecruitTroops = nil
	
	self._canBuildConstructions = nil
	
	self._adjacentGroups = nil
	
	self._belligerentRelations = nil
	self._hostilityRelations = nil
end

function Group:SaveData()
	for k, goal in ipairs( self.goals ) do
		goal.type = MathUtility_FindEnumKey( GroupGoal, goal.type )
	end
	
	for k, tag in ipairs( self.tags ) do
		tag.type = MathUtility_FindEnumKey( GroupGoal, tag.type )
	end

	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	Data_OutputValue( "id", self )
	Data_OutputValue( "name", self )	
	
	Data_OutputValue( "capital", self, "id" )
	Data_OutputValue( "leader", self, "id" )
	
	Data_OutputValue( "money", self )
	Data_OutputValue( "researchAbility", self )
	
	Data_OutputValue( "government", self )

	Data_OutputTable( "relations", self, "id" )
	Data_OutputTable( "tags", self )
	
	Data_OutputTable( "cities", self, "id" )
	Data_OutputTable( "corps", self, "id" )
	Data_OutputTable( "troops", self, "id" )
	Data_OutputTable( "charas", self, "id" )
	Data_OutputTable( "techs", self, "id" )
	Data_OutputTable( "formations", self, "id" )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
	
	for k, goal in ipairs( self.goals ) do
		goal.type = GroupGoal[goal.type]
	end
	
	for k, tag in ipairs( self.tags ) do
		tag.type = GroupTag[tag.type]
	end
end

----------------------------------------------
-- Convert Id to Data
----------------------------------------------
function Group:ConvertID2Data()
	--convert goal type from string to id
	for k, goal in ipairs( self.goals ) do
		goal.type = GroupGoal[goal.type]
	end
	
	for k, tag in ipairs( self.tags ) do
		tag.type = GroupTag[tag.type]
	end

	self.capital = g_cityDataMng:GetData( self.capital )
	--ShowText( "Set Capital", self.capital, self.capital.name )
	
	local relations = {}
	for k, id in ipairs( self.relations ) do
		local relation = g_diplomacy:GetRelation( id )
		if not relation then
			Debug_Assert( nil, "Invalid relation data=" .. id )
		end
		if relation.sid ~= self.id and relation.tid ~= self.id then
			Debug_Assert( nil, "Wrong group relation data=" .. id ..",".. relation.sid ..",".. relation.tid ..",".. self.id )
		else
			table.insert( relations, relation )
		end		
	end
	self.relations = relations	

	local cities = {}
	for k, id in ipairs( self.cities ) do	
		local city = g_cityDataMng:GetData( id )
		--ShowText( "set city group", city.id, city.name )
		if not city then Debug_Error( "Invalid city" .. id ) end		
		city._group = self		
		table.insert( cities, city )
	end
	self.cities = cities
	
	local corpsList = {}
	for k, id in ipairs( self.corps ) do
		local corps = g_corpsDataMng:GetData( id )
		if not corps:GetEncampment() then
			ShowText( "!!! No corps encampment data" )
		else
			local encampment = corps:GetEncampment()
			if typeof( encampment ) == "number" then
				encampment = g_cityDataMng:GetData( encampment )
			end
			if not encampment or not MathUtility_IndexOf( encampment.corps, corps.id ) then
				ShowText( "!!! Invalid corps encampment data", encampment.name, corps.id )
			end
		end
		corps._group = self
		table.insert( corpsList, corps )
	end
	self.corps = corpsList
	
	local troops = {}
	for k, id in ipairs( self.troops ) do		
		table.insert( troops, g_troopDataMng:GetData( id ) )
		--ShowText( g_troopDataMng:GetData( id ).name, g_troopDataMng:GetData( id ).number )
	end
	self.troops = troops
	
	-- should check troop in corps
	for k, corps in ipairs( self.corps ) do
		for k, id in ipairs( corps.troops ) do
			if not MathUtility_IndexOf( self.troops, id, "id" ) then
				--ShowText( g_troopDataMng:GetData( id ), g_troopDataMng:GetData( id ).name, g_troopDataMng:GetData( id ).number )				
				table.insert( self.troops, g_troopDataMng:GetData( id ) )
			end
		end
	end
	
	local charas = {}
	for k, id in ipairs( self.charas ) do
		local chara = g_charaDataMng:GetData( id )
		if not chara then
			Debug_Error( "Chara is invalid [" .. id .. "]" )
		else
			chara._group = self
			table.insert( charas, chara )
		end
	end
	self.charas = charas
	
	local temp = g_charaDataMng:GetData( self.leader ) 	
	if not self.leader or ( temp:GetGroup() and temp:GetGroup() ~= self ) then
		Debug_Assert( nil, "Group leader data " .. self.leader )
	else
		self.leader = temp
	end
	
	local techs = {}
	for k, id in ipairs( self.techs ) do
		table.insert( techs, g_techTableMng:GetData( id ) )
	end
	self.techs = techs
	
	local formations = {}
	for k, id in ipairs( self.formations ) do
		table.insert( formations, g_formationTableMng:GetData( id ) )
	end
	self.formations = formations
end

function Group:Init()
	self:UpdateDynamicData()	
end

----------------------------------------------
-- Update Dynamic Data 
----------------------------------------------
function Group:UpdateDynamicData()
	--validate data
	self:GetMilitaryPower()
	
	--recruit/build/research list
	self:UpdateRecruitList()	
	self:UpdateBuildList()
	self:UpdateResearchList()
end

function Group:UpdateRecruitList()
	self._canRecruitTroops = {}
	g_troopTableMng:Foreach( function( troop )
		if troop.prerequisites.tech then
			if not MathUtility_IndexOf( self.techs, troop.prerequisites.tech, "id" ) then return end
		end
		table.insert( self._canRecruitTroops, troop )
	end )
	
	--Debug_Normal( "Group Recruit List " .. #self._canRecruitTroops )
end

function Group:UpdateBuildList()
	--can build list
	self._canBuildConstructions = {}
	g_constrTableMng:Foreach( function ( constr )		
		if constr.prerequisites.tech then
			if not MathUtility_IndexOf( self.techs, constr.prerequisites.tech, "id" ) then return end
		end
		table.insert( self._canBuildConstructions, constr )
	end )
	
	--Debug_Normal( "Group Build List " .. #self._canBuildConstructions )
end

function Group:UpdateResearchList()
	self._canResearchTechs = {}
	g_techTableMng:Foreach( function ( tech )
		if MathUtility_IndexOf( self.techs, tech.id, "id" ) then return end
		if tech.prerequisites.tech then
			if not MathUtility_IndexOf( self.techs, tech.prerequisites.tech, "id" ) then return end
		end
		table.insert( self._canResearchTechs, tech )
	end )
end

----------------------------------------------
--Goals Relative
function Group:GetPlotNumber()
	local number = 0
	for k, city in ipairs( self.cities ) do
		number = number + #city.plots
	end
	return number
end

function Group:GetTerritoryRate()
	local cityCount = #self.cities
	for k, relation in ipairs( self.relations ) do
		if relation.sid == self.id then
			if relation.type == GroupRelationType.VASSAL then
				local target = g_groupDataMng:GetData( relation.tid )
				if target then
					cityCount = cityCount + #target.cities
				end
			--[[
			elseif relation.type == GroupRelationType.DEPENDENCE then
				local target = g_groupDataMng:GetData( relation.tid )
				if target then
					cityCount = cityCount + #target.cities
				end
			]]
			end			
		end
	end
	return cityCount, math.floor( cityCount * 100 / g_cityDataMng:GetCount() )
end
function Group:GetDominationRate()	
	local totalPower = 0
	g_groupDataMng:Foreach( function ( data ) 
		if not data:IsFallen() then
			totalPower = totalPower + data:GetPower()
		end
	end )
	
	local power = self:GetPower()	
	for k, relation in ipairs( self.relations ) do
		if relation.sid == self.id then
			if relation.type == GroupRelationType.VASSAL then
				local target = g_groupDataMng:GetData( relation.tid )
				if target then
					power = power + target:GetPower()
				end
			--[[
			elseif relation.type == GroupRelationType.DEPENDENCE then
				local target = g_groupDataMng:GetData( relation.tid )
				if target then
					power = power + target:GetPower()
				end
			]]
			end
		end
	end
	
	return power, math.floor( power * 100 / totalPower )
end

----------------------------------------------
-- Data Interface
function Group:InvalidateData()
	self._militaryPower = -1
end

function Group:GetMilitaryPower()
	if self._militaryPower ~= -1 then return self._militaryPower end
	self._militaryPower = 0
	for k, troop in ipairs( self.troops ) do
		self._militaryPower = self._militaryPower + troop.number
	end
	--ShowText( self.name .." Getpower=",self._militaryPower)
	return self._militaryPower
end

function Group:GetPower()
	return self:GetMilitaryPower()
end

function Group:GetDependencePower()
	local power = 0
	for k, relation in ipairs( self.relations ) do
		if relation.sid == self.id and ( relation.type == GroupRelationType.DEPENDENCE or relation.type == GroupRelationType.VASSAL ) then
			local group = relation:GetOppGroup( relation.sid )
			power = power + group:GetPower()
		end
	end
	return power
end

function Group:GetPopulation()
	local population = 0
	for k, city in ipairs( self.cities ) do
		population = population + city.population
	end
	return population
end

--[[
function Group:GetSupply()
	local num = 0
	for k, city in ipairs( self.cities ) do
		num = city:GetSupply()
	end
	return num
end
function Group:GetMaxSupply()
	local num = 0
	for k, city in ipairs( self.cities ) do
		num = city:GetMaxSupply()
	end
	return num
end
]]

function Group:GetMoney()
	return self.money
end

function Group:GetCapital()
	return self.capital
end

function Group:GetLeader()
	return self.leader	
end

function Group:GetPolicyTendency( policy )
	local tendency = self.policies[policy]
	if tendency then return tendency.value end
	return 0
end

function Group:GetGroupRelation( id )
	if id == self.id then
		ShowText( "None relation to self", id )
		return nil
	end
	for k, relation in ipairs( self.relations ) do
		if relation.sid == id or relation.tid == id then
			return relation
		end
	end
	
	--find in target
	local target = g_groupDataMng:GetData( id )
	if target then
		for k, relation in ipairs( target.relations ) do
			if relation.sid == id or relation.tid == id then
				table.insert( self.relations, relation )
				return relation
			end
		end
	else
		return nil
	end
	
	Debug_Normal( "!!!Add new relation in [" .. self.name .. "," .. self.id .. "] with [" .. id .. "]" )
	
	local relation = g_diplomacy:CreateRelation( self.id, id )	
	table.insert( self.relations, relation )	
	table.insert( target.relations, relation )	
	return relation
end

function Group:GetAdjacentGroups()
	if self._adjacentGroups then return self._adjacentGroups end	
	self._adjacentGroups = {}
	for k, city in ipairs( self.cities ) do
		for k2, adjCity in ipairs( city.adjacentCities ) do
			if adjCity:GetGroup() and adjCity:GetGroup() ~= self then
				MathUtility_PushBack( self._adjacentGroups, adjCity:GetGroup() )
			end
		end
	end
	return self._adjacentGroups
end

function Group:IsAdjacentGroup( group )
	local list = self:GetAdjacentGroups()
	for k, group in ipairs( list ) do
		if group.id == group.id then
			return true
		end
	end
	return false
end

--[[
	Only independence groups
]]
function Group:GetBelligerentRelations()
	if self._belligerentRelations then return self._belligerentRelations end
	self._belligerentRelations = {}
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.BELLIGERENT then
			table.insert( self._belligerentRelations, relation )
		end
	end
	return self._belligerentRelations
end

function Group:GetHostilityRelations()
	if self._hostilityRelations then return self._hostilityRelations end
	self._hostilityRelations = {}
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.HOSTILITY or relation.type == GroupRelationType.ENEMY then
			local target = relation:GetOppGroup( self.id )
			if target then
				table.insert( self._hostilityRelations, relation )
			end
		end
	end
	return self._hostilityRelations
end

function Group:GetFriendRelations()
	if self._friendRelations then return self._friendRelations end
	self._friendRelations = {}
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.FRIEND then
			table.insert( self._friendRelations, relation )
		end
	end
	return self._friendRelations
end

function Group:GetDependencyRelations()
	if self._dependencyRelations then return self._dependencyRelations end
	self._dependencyRelations = {}
	for k, relation in ipairs( self.relations ) do
		if relation.sid == self.id and ( relation.type == GroupRelationType.DEPENDENCE or relation.type == GroupRelationType.VASSAL ) then
			table.insert( self._dependencyRelations, relation )
		end
	end
	return self._dependencyRelations
end

function Group:GetReachableBelligerentCityList()	
	local relations = self:GetDependencyRelations()
	return Helper_ListIf( relations, function ( relation ) 
		local dependencyGroup = g_groupDataMng:GetData( dependencyRelation.tid )
		if not dependencyGroup then return false end
		for k2, city in ipairs( dependencyGroup.cities ) do
			for k3, adjaCity in ipairs( city.adjacentCities ) do
				local target = adjCity:GetGroup()
				if target ~= self and target ~= dependencyGroup then
					local relation = self:GetGroupRelation( target.id )
					if relation.type == GroupRelationType.BELLIGERENT then
						return true
					end
				end
			end
		end
		return false
	end )
end

function Group:GetBelligerentGroupPower()
	local maxPower, minPower, totalPower, number = 0, 99999999, 0, 0
	for k, relation in ipairs( self.relations ) do
		local otherGroup = relation:GetOppGroup( self.id )
		if otherGroup then
			local otherPower = otherGroup:GetPower()
			if otherPower > maxPower then maxPower = otherPower end
			if otherPower < minPower then minPower = otherPower end
			totalPower = totalPower + otherPower
			number = number + 1
		end
	end
	return totalPower, maxPower, minPower, number
end

function Group:GetUnderstaffedCityList()
	return Helper_ListIf( self.cities, function ( city )
		return city:IsUnderstaffed()
	end )
end

---------------------------

function Group:IsFallen()
	return self.government == GroupGovernment.NONE
end

function Group:HasChara( chara )
	if not chara then return false end
	return MathUtility_IndexOf( self.charas, chara.id, "id" )
end

function Group:IsIndependence()
	for k, relation in ipairs( self.relations ) do
		if ( relation.type == GroupRelationType.VASSAL or relation.type == GroupRelationType.DEPENDENCE ) and relation.tid == self.id then
			return false
		end
	end
	return true
end

function Group:HasDependence()
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.DEPENDENCE and relation.sid == self.id then
			return true
		end
	end
	return false
end


function Group:IsDependence()
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.DEPENDENCE and relation.tid == self.id then
			return true
		end
	end
	return false
end


function Group:HasVassal()
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.VASSAL and relation.sid == self.id then
			return true
		end
	end
	return false
end

function Group:IsVassal()
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.VASSAL and relation.tid == self.id then
			return true
		end
	end
	return false
end

function Group:HasAlliance()
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.ALLIANCE then
			return true
		end
	end
	return false
end

function Group:IsHostility( target )
	local relation = self:GetGroupRelation( target.id )
	return relation and relation:IsHostility() or false
end

function Group:IsBelligerent( group )
	local relation = self:GetGroupRelation( group.id )
	return relation and relation:IsBelligerent() or false
end

function Group:IsEnemy( target )
	local relation = self:GetGroupRelation( target.id )
	return relation and relation:IsEnemy() or false
end

function Group:GetBelligerentStatus( friend )
	local enemyRelations = {}
	local numOfFriend = 0
	for k, relation in ipairs( self.relations ) do
		if relation.type == GroupRelationType.BELLIGERENT then
			table.insert( enemyRelations, relation )
			if friend then
				local otherId = relation.sid == self.id and relation.tid or relation.sid
				if otherId ~= friend.id then
					local relation2 = friend:GetGroupRelation( otherId )
					if relation2 and relation2:IsFriend() then
						numOfFriend = numOfFriend + 1
					end
				end
			end
		end
	end
	--ShowText( "ret", #enemyRelations, numOfFriend )
	return enemyRelations, numOfFriend
end

function Group:IsOwnCity( cityId )
	return MathUtility_IndexOf( self.cities, cityId, "id" )
end

function Group:HasGoal( goalType, goalEndType )
	if goalEndType then
		for k, goal in ipairs( self.goals ) do
			if goal.type >= goalType and goal.type <= goalEndType then
				return true
			end
		end
	else	
		for k, goal in ipairs( self.goals ) do
			if goal.type == goalType then
				return true
			end
		end
	end
	return false
end

function Group:CanResearch()
	if self.researchTechId ~= 0 then return false end
	if g_taskMng:IsTaskConflictWithCity( TaskType.TECH_RESEARCH, nil ) then return false end	
	return #self._canResearchTechs > 0
end



----------------------------------------------
-- Iteration Method

function Group:ForeachChara( fn )
	for k, chara in ipairs( self.charas ) do
		fn( chara )
	end
end

----------------------------------------------
-- Proposal Relative
----------------------------------------------

function Group:ExecuteProposal( desc )
	table.insert( self.proposals, desc )
end

function Group:StartDiplomacy( target, method )
	self.diplomaticTargetId = target.id
	self.diplomaticMethod   = method
	
	self.lastActionName = 'Diplomacy'
end

function Group:RecruitTroop( troop )
	--Debug_Normal( "Group " .. NameIDToString( self ) .. " Recruit Troop " .. NameIDToString( troop ) )
	table.insert( self.troops, troop )
end

function Group:EstablishCorps( corps )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Establish Corps " .. NameIDToString( group ) )
	table.insert( self.corps, corps )
end

function Group:LoseChara( chara )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Lose Chara " .. NameIDToString( chara ) )
	MathUtility_Remove( self.charas, chara.id, "id" )
end

function Group:LoseTroop( troop )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Lose troop " .. NameIDToString( troop ) )
	MathUtility_Remove( self.troops, troop.id, "id" )
end

function Group:LoseCorps( corps )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Lose corps " .. NameIDToString( corps ) )
	MathUtility_Remove( self.corps, corps.id, "id" )
end

function Group:LoseCity( city )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Lose city " .. NameIDToString( city ) )	
	MathUtility_Remove( self.cities, city.id, "id" )
	
	if #self.cities == 0 then
		self:Fall()
	end
end

function Group:AddChara( chara )
	table.insert( self.charas, chara)
end

function Group:AddTroop( troop )
	table.insert( self.troops, troop )
end

function Group:AddCorps( corps )
	table.insert( self.corps, corps )
end

function Group:AcceptSurrenderChara( chara, city )
	if not chara then return end
	
	local limit = QueryCityCharaLimit( city )
	if limit >= #city.charas then
		--cann't accept surrender chara, dismiss from troop
		CharaCapture( chara )
		chara:LeadTroop( nil )
		InputUtility_Pause( chara.name .. " is prisoner" )
		return
	end
	
	InputUtility_Pause( "Group " .. NameIDToString( self ) .. " Accept Surrender Chara " .. NameIDToString( chara ) )
	
	local group = chara:GetGroup()
	if group ~= self then
		group:LoseChara( chara )
	end
	
	--chara data
	chara:JoinGroup( self, city )
	--city data
	city:CharaLive( chara )
	--group data
	self:AddChara( chara )
end

function Group:AcceptSurrenderTroop( troop, city )
	InputUtility_Pause( "Group " .. NameIDToString( self ) .. " Accept Surrender troop " .. NameIDToString( troop ) )	

	local group = troop:GetEncampment() and troop:GetEncampment():GetGroup() or nil
	if group and group ~= self then
		group:LoseTroop( troop )
	end
	
	--chara leave
	self:AcceptSurrenderChara( chara, city )
	
	--troop data
	troop:JoinCity( city )
	--city data
	city:AddTroop( troop )
	--group data
	self:AddTroop( troop )
end

function Group:AcceptSurrenderCorps( corps, city )
	InputUtility_Pause( "Group " .. NameIDToString( self ) .. " Accept Surrender Corps " .. NameIDToString( corps ) )	
	
	local group = corps:GetEncampment() and corps:GetEncampment():GetGroup() or nil
	if group and group ~= self then
		group:LoseCorps( corps )
	end
	
	--all troops
	corps:ForeachTroop( function ( troop )	
		self:AcceptSurrenderTroop( troop )
	end )
	--corps data
	corps:JoinGroup( self, city )
	--city data
	city:AddCorps( corps )
	--group data
	self:AddCorps( corps )
end

function Group:SelectLeader( leader )
	self.leader = leader
end

function Group:VoteLeader( oldLeader )
	local index = Random_SyncGetRange( 1, #group.charas )
	group.leader = group.charas[index]
end
	
function Group:SelectCapital( capital )
	self.capital = capital
end

function Group:VoteCapital( oldCapital )
	local maxLv = 0
	local cities = nil
	for k, city in ipairs( self.cities ) do
		if city ~= oldCapital then
			if maxLv < city.level then
				cities = { city }
				maxLv = city.level
			elseif maxLv == city.level then
				table.insert( cities, city )
			end
		end
	end
	local index = Random_SyncGetRange( 1, #cities )
	local newCapital = cities[index]
	self.capital = newCapital
end

function Group:CaptureCorps( corps, prisonCity, isAcceptSurrender )
	if not isAcceptSurrender then
		local treate = self:GetPolicyTendency( PolicyType.TREAT_SURRENDER_SOLDIER )
		isAcceptSurrender = Random_SyncGetRange( 1, PolicyParams.RANGE ) < treate
	end
	if isAcceptSurrender then
		self:AcceptSurrenderCorps( corps, prisonCity )
	else
		local treateChara = self:GetPolicyTendency( PolicyType.TREAT_SURRENDER_CHARACTER )
		local isAcceptSurrenderChara = Random_SyncGetRange( 1, PolicyParams.RANGE ) < treateChara
		corps:Neutralize( not isAcceptSurrenderChara, true )
	end
end

function Group:CaptureTroop( troop, prisonCity, isAcceptSurrender )
	if not isAcceptSurrender then
		local treate = self:GetPolicyTendency( PolicyType.TREAT_SURRENDER_SOLDIER )
		isAcceptSurrender = Random_SyncGetRange( 1, PolicyParams.RANGE ) < treate
	end
	if isAcceptSurrender then
		--surrender
		self:AcceptSurrenderTroop( troop )
	else
		local treateChara = self:GetPolicyTendency( PolicyType.TREAT_SURRENDER_CHARACTER )
		local isAcceptSurrenderChara = Random_SyncGetRange( 1, PolicyParams.RANGE ) < treateChara
		troop:Neutralize( not isAcceptSurrenderChara, true )
	end
end

function Group:CaptureChara( chara, prisonCity )
	local isSurrender = Random_SyncGetRange( 1, PolicyParams.RANGE ) < chara.trust
	local treateChara = self:GetPolicyTendency( PolicyType.TREAT_SURRENDER_CHARACTER )
	local isAcceptSurrender = Random_SyncGetRange( 1, PolicyParams.RANGE ) < treateChara
	
	if isAcceptSurrender and isSurrender then
		self:AcceptSurrenderChara( chara )
	else
		CharaDie( chara )
	end
end

function Group:CaptureCity( combat )
	local city = combat:GetLocation()
	
	g_statistic:CityFall( city, self )
	--InputUtility_Pause( "Group " .. NameIDToString( self ) .. " Capture city " .. NameIDToString( city ) )
	
	--Remove city from original group
	local originalGroup = city:GetGroup()
	originalGroup:LoseCity( city )

	--Add city to owner group
	table.insert( self.cities, city )
	city:JoinGroup( self )

	local isGroupFallen = #self.cities == 0
	
	--Select new capital if necessary
	if not isGroupFallen and city:IsCapital() then
		--first select new capital
		originalGroup:VoteCapital( city )
	end
	
	--Corps from Original group
	-- 1. Retreat to the latest city
	-- 2. Surrender or eliminate by the attacker's strategy
	local adjaCities = {}
	if not isGroupFallen then
		city:ForeachAdjacentCity( function ( adjCity )
			if adjCity:IsBelongToGroup( originalGroup ) then
				table.insert( adjaCities, adjCity )
			end
		end )
	end
	local numberOfCity = #adjaCities
	if numberOfCity == 0 then
		--capture or fall
		local prisonCity = city		
		for k, corps in ipairs( city.corps ) do
			self:CaptureCorps( corps, prisonCity )
		end
		city.corps = {}
		
		for k, troop in ipairs( city.troops ) do
			if not troop:GetCorps() then
				self:CaptureTroop( troop, prisonCity )
			end
		end		
		city.troops = {}
		
		for k, chara in ipairs( city.charas ) do
			if chara:GetTroop() then
				self:CaptureChara( chara, prisonCity )
			end
		end
		city.charas = {}

		--InputUtility_Pause( city.name .. " from " .. originalGroup.name .. " Surrender to " .. self.name )		
	else
		for k, corps in ipairs( city.corps ) do
			if corps:GetLocation() == city then
				--in the city
				local index = Random_SyncGetRange( 1, numberOfCity )
				local retreatCity = adjaCities[index]
				corps:JoinCity( retreatCity )
				g_taskMng:IssueTaskCorpsBackEncampment( corps )
			else
				--!!! it's more complex than what I did now.
				--There're some many situation should consider about
				--1.encampment supply
				--2.attack failed
				local index = Random_SyncGetRange( 1, numberOfCity )
				local retreatCity = adjaCities[index]
				print( corps.name .. " need to retreat to " .. retreatCity.name )
				corps:JoinCity( retreatCity )
				local task = g_taskMng:GetTaskByActor( corps )
				if task then
					if task.type ~= TaskType.ATTACK_CITY and task.type ~= TaskType.EXPENDITION then
						task:Terminate()
					end
				else
					g_taskMng:IssueTaskCorpsBackEncampment( corps )
				end
			end
		end
		for k, troop in ipairs( city.troops ) do
			if not troop:GetCorps() then
				--in city
				local index = Random_SyncGetRange( 1, numberOfCity )
				local retreatCity = adjaCities[index]
				print( NameIDToString( troop ) .. " need to retreat to " .. retreatCity.name )
				--!!!should issue task
				troop:JoinCity( retreatCity )
				g_taskMng:IssueTaskTroopBackEncampment( troop )
			end
		end
		for k, chara in ipairs( city.charas ) do
			if not chara:GetTroop() then
				local index = Random_SyncGetRange( 1, numberOfCity )
				local retreatCity = adjaCities[index]
				chara:JoinCity( retreatCity )
				g_taskMng:IssueTaskCharaBackHome( chara )
			end
		end
		--InputUtility_Pause( city.name .. " from " .. originalGroup.name .. " Retreat to nearest city, attacked by " .. self.name )				
	end
	
	--Garrisson into the city
	for k, corps in ipairs( combat.corps ) do
		if corps:GetGroup() == self then
			corps:DispatchToCity( city )
			city:AddCorps( corps )
		end
	end
	
	--Whether group is dead
	if isGroupFallen then
		originalGroup:Fall()
	end
end

function Group:Fall()
	if self.government == GroupGovernment.GUERRILLA then
		--never fall
		return
	end	
	
	print( NameIDToString( self ) .. " is fallen" )
	
	self.government = GroupGovernment.NONE
	
	--characters out
	for k, chara in ipairs( self.charas ) do
		print( chara.name .. " group is fallen" )
		chara:Out()
	end
	--dismiss all troop and corps
	for k, troop in ipairs( self.troops ) do
		g_troopDataMng:RemoveData( troop.id )
	end
	self.troops = {}
	for k, corps in ipairs( self.corps ) do
		g_corpsDataMng:RemoveData( corps.id )
	end
	self.corps = {}
	--dismiss all relations
	for k, relation in ipairs( self.relations ) do
		local target = g_groupDataMng:GetData( relation.sid == self.id and relation.tid or relation.sid )
		if target then
			MathUtility_Remove( target.relations, relation.id, "id" )
		end
	end
	self.relations = {}
	
	--Remove task from group
	g_taskMng:TerminateTaskFromGroup( self )
	
	--Remove combat from group
	g_warfare:EndCombatByGroup( group )
	
	--remove group
	g_groupDataMng:RemoveData( self.id )
	
	print( "group fall=" .. self.name, "next" )
end

function Group:CharaJoin( chara )
	table.insert( self.charas, chara )
end

function Group:CharaOut( chara )
	if not MathUtility_Remove( self.charas, chara.id, "id" ) then
		ShowText( "Remove chara ["..chara.name.."] failed!" )
	end
end

function Group:ReceiveTax( tax, city )
	self.money = self.money + tax
	ShowText( "Receive tax=" .. tax .. " from=" .. city.name )
end

----------------------------------------------
-- End Command Relative
----------------------------------------------

function Group:DumpCityDetail()
	for k, city in ipairs( self.cities ) do
		city:DumpSimple( "    " )
	end
end

function Group:DumpCorpsDetail()
	for k, corps in ipairs( self.corps ) do
		corps:Dump( "    " )
	end	
end

function Group:DumpTroopDetail()
	for k, troop in ipairs( self.troops ) do
		troop:Dump( "    " )
	end	
end

function Group:DumpRelationDetail()
	for k, relation in ipairs( self.relations ) do
		local target = relation:GetOppGroup( self.id )
		if target and target ~= self then
			if ( relation.type == GroupRelationType.DEPENDENCE or relation.type == GroupRelationType.VASSAL ) and relation.sid == self.id then
				ShowText( "    " .. target.name .. " Pow=" .. target:GetPower() .. " +".. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " ev=" .. relation.evaluation )
			else
				ShowText( "    " .. target.name .. " Pow=" .. target:GetPower() .. " ".. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " ev=" .. relation.evaluation )
			end
		end
	end
end

function Group:DumpCharaDetail()
	for k, chara in ipairs( self.charas ) do
		chara:Dump( "    " )
	end
end

function Group:DumpDiplomacyMethod()
	ShowText( '' )
	ShowText( "--------" .. self.name .. " pow=" .. self:GetPower() )
	for method = DiplomacyMethod.FRIENDLY, DiplomacyMethod.METHOD_END - 1 do
		local content = nil
		for k, relation in ipairs( self.relations ) do
			local target = relation:GetOppGroup( self.id )			
			if target and relation:IsMethodValid( method, self, target ) then
				local prob = EvaluateDiplomacySuccessRate( method, relation, self, target )
				if not content then content = "" end				
				content = content .. " " .. target.name .. " prob=" .. prob --	.. "/" .. target:GetPower()
			end
		end
		if content then 
			ShowText( MathUtility_FindEnumName( DiplomacyMethod, method ) )
			ShowText( "  " .. content )
		end
	end
end

function Group:Dump()
	if 1 then return end
	ShowText( '>>>>>>>>>>>  Group >>>>>>>>>>>>>>>>>' )
	ShowText( '[Group] #' .. self.id .. ' Name=' .. self.name )
	ShowText( "Govement     =" .. MathUtility_FindEnumName( GroupGovernment, self.government ) )
	ShowText( "PoliticalPow =" .. self._politicalPower )
	ShowText( "Population   =" .. self:GetPopulation() )
	ShowText( "MilitaryPow  =" .. self._militaryPower )
	ShowText( "Pow          =" .. self:GetPower() )
	ShowText( "Money        =" .. self.money )
	ShowText( "City Num     =" .. #self.cities )
	self:DumpCityDetail()
	ShowText( "Corps Num    =" .. #self.corps )
	self:DumpCorpsDetail()
	ShowText( "Troop Num    =" .. #self.troops )
	self:DumpTroopDetail()
	ShowText( "Chara Num    =" .. #self.charas )
	self:DumpCharaDetail()
	ShowText( "Tech Num     =" .. #self.techs )
	ShowText( "Relation     =" .. #self.relations )
	--self:DumpRelationDetail()
	self:DumpDiplomacyMethod()
	ShowText( "<<<<<<<<<<< Group <<<<<<<<<<<<<<<<<<" )
end

---------------------------------------------
-- Operation Method
---------------------------------------------

function Group:InventTech( tech )
	table.insert( self.techs, tech )
	
	Debug_Normal( "["..self.name.."] finished research tech [".. tech.name .. "]" )
end

function Group:UpdateSituationTag( tagType, condition )
	if condition( self ) then
		--InputUtility_Pause( self.name .. " Set asset=" .. MathUtility_FindEnumName( GroupTag.SITUATION, tagType ) )
		self:SetAsset( tagType, 1 )
	else
		--InputUtility_Pause( self.name .. " Remove asset=" .. MathUtility_FindEnumName( GroupTag.SITUATION, tagType ) )
		self:RemoveAsset( tagType, -1 )
	end
end

function Group:Update()
	if self.leader == nil then
		self:VoteLeader()
	end

	self:InvalidateData()
	--[[
	-- Income
	for k, city in ipairs( self.cities ) do
		self.money = self.money + city:GetIncome()
	end
	]]
	self:UpdateSituationTag( GroupTag.SITUATION.AT_WAR, CheckGroupStuAtWar )
	self:UpdateSituationTag( GroupTag.SITUATION.MULTIPLE_FRONT, CheckGroupStuMultipleFronts )
	self:UpdateSituationTag( GroupTag.SITUATION.UNDEVELOPED, CheckGroupUndeveloped )
	self:UpdateSituationTag( GroupTag.SITUATION.WEAK, CheckGroupStuWeak )
	self:UpdateSituationTag( GroupTag.SITUATION.PRIMITIVE, CheckGroupStuPrimitive )
	self:UpdateSituationTag( GroupTag.SITUATION.UNDERSTAFFED, CheckGroupStuUnderstaff )
	self:UpdateSituationTag( GroupTag.SITUATION.AGGRESSIVE, CheckGroupStuAggressive )
	
	-- Update dynamic data, like military power evaluation
	self:UpdateDynamicData()
end

--------------------------------------
-- Tag

function Group:GetAsset( tagType )
	return Helper_GetVarb( self.tags, tagType )
end

function Group:SetAsset( tagType, value )
	Helper_SetVarb( self.tags, tagType, value )
end

function Group:AppendAsset( tagType, value, range )
	Helper_AppendVarb( self.tags, tagType, value, range )
end

function Group:RemoveAsset( tagType, value )
	Helper_RemoveVarb( self.tags, tagType, value )
end

--------------------------------------
-- Intelligence

function Group:GetGroupIntel( target, type )
	--to do
end