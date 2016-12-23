Group = class()

function Group:__init()
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
		
	--Every Turn
	--Max order number simply equals 1 + sqrt( politicalPower )	
	self._orderNumber    = 0
	self._maxOrderNumber = 0
	
	self._politicalPower = 0
	
	self._economyPower  = 0
	
	self._militaryPower = 0
	
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
	--print( "Set Capital", self.capital, self.capital.name )
	
	local relations = {}
	for k, id in ipairs( self.relations ) do
		local relation = g_groupRelationDataMng:GetData( id )
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
		--print( "set city group", city.id, city.name )
		if not city then Debug_Error( "Invalid city" .. id ) end		
		city._group = self		
		table.insert( cities, city )
	end
	self.cities = cities
	
	local corpsList = {}
	for k, id in ipairs( self.corps ) do
		local corps = g_corpsDataMng:GetData( id )
		if not corps:GetEncampment() then
			print( "!!! No corps encampment data" )
		else
			local encampment = corps:GetEncampment()
			if typeof( encampment ) == "number" then
				encampment = g_cityDataMng:GetData( encampment )
			end
			if not MathUtility_IndexOf( encampment.corps, corps.id ) then
				print( "!!! Invalid corps encampment data", encampment.name, corps.id )
			end
		end
		corps._group = self
		table.insert( corpsList, corps )
	end
	self.corps = corpsList
	
	local troops = {}
	for k, id in ipairs( self.troops ) do		
		table.insert( troops, g_troopDataMng:GetData( id ) )
		--print( g_troopDataMng:GetData( id ).name, g_troopDataMng:GetData( id ).number )
	end
	self.troops = troops
	
	-- should check troop in corps
	for k, corps in ipairs( self.corps ) do
		for k, id in ipairs( corps.troops ) do
			if not MathUtility_IndexOf( self.troops, id, "id" ) then
				--print( g_troopDataMng:GetData( id ), g_troopDataMng:GetData( id ).name, g_troopDataMng:GetData( id ).number )				
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
	self._economyPower = 0
	for k, city in ipairs( self.cities ) do
		self._economyPower = self._economyPower + city.economy
	end
	
	self._militaryPower = 0
	for k, troop in ipairs( self.troops ) do
		self._militaryPower = self._militaryPower + troop.number
	end	
	
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
function Group:GetTerritoryRate()
	local cityCount = #self.cities
	for k, relation in ipairs( self.relations ) do
		if relation.sid == self.id then
			if relation.type == GroupRelationType.VASSAL then
				local target = g_groupDataMng:GetData( relation.tid )
				if target then
					cityCount = cityCount + #target.cities
				end
				elseif relation.type == GroupRelationType.DEPENDENCE then
				local target = g_groupDataMng:GetData( relation.tid )
				if target then
					cityCount = cityCount + #target.cities
				end
			end
		end
	end
	return cityCount, math.floor( cityCount * 100 / g_cityDataMng:GetCount() )
end
function Group:GetDominationRate()	
	local totalPower = 0
	g_groupDataMng:Foreach( function ( data ) 
		if not data:IsFallen() then
			print( "total plus", data.name, data:GetPower() )
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
			elseif relation.type == GroupRelationType.DEPENDENCE then
				local target = g_groupDataMng:GetData( relation.tid )
				if target then
					power = power + target:GetPower()
				end
			end
		end
	end
	
	return power, math.floor( power * 100 / totalPower )
end

----------------------------------------------
-- Data Interface
function Group:GetPower()
	--if self.power then return self.power end
	return self._militaryPower
end

function Group:GetMaxSupply()
	local num = 0
	for k, city in ipairs( self.cities ) do
		num = city:GetMaxSupply()
	end
	return num
end

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
		print( "None relation to self", id )
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
	
	local relation = g_groupRelationDataMng:NewData()
	relation.sid = self.id
	relation.tid = id
	relation:ConvertID2Data()
	table.insert( self.relations, relation )
	
	table.insert( target.relations, relation )
	
	return relation
end

function Group:GetAdjacentGroups()
	print( "Get adja group")
	if self._adjacentGroups then return self._adjacentGroups end	
	self._adjacentGroups = {}
	for k, city in ipairs( self.cities ) do
		for k2, adjCity in ipairs( city.adjacentCities ) do
			if adjCity:GetGroup() and adjCity:GetGroup() ~= self then
				print( "push adja", adjCity:GetGroup().name )
				MathUtility_PushBack( self._adjacentGroups, adjCity:GetGroup() )
			end
		end
	end
	return self._adjacentGroups
end

function Group:IsAdjacentGroup( groupId )
	local list = self:GetAdjacentGroups()
	for k, group in ipairs( list ) do
		if group.id == groupId then
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
	local adjaCities = {}
	local relations = self:GetDependencyRelations()
	for k, dependencyRelation in ipairs( relations ) do
		local dependencyGroup = g_groupDataMng:GetData( dependencyRelation.tid )
		if dependencyGroup then
			for k2, city in ipairs( dependencyGroup.cities ) do
				for k3, adjaCity in ipairs( city.adjacentCities ) do
					local target = adjCity:GetGroup()
					if target ~= self and target ~= dependencyGroup then
						local relation = self:GetGroupRelation( target.id )
						if relation.type == GroupRelationType.BELLIGERENT then
							table.insert( adjaCities, adjCity )
						end
					end
				end
			end
		end
	end
	return adjaCities
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
	if relation then return relation:IsHostility() end
	return false
end

function Group:IsEnemy( target )
	local relation = self:GetGroupRelation( target.id )
	if relation then return relation:IsEnemy() end
	return false
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
	--print( "ret", #enemyRelations, numOfFriend )
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

function Group:IsAchieveGoal()
	--print( "\nCheck Goals")
	if #self.goals == 0 then
		--default winner condition
		return #self.cities == g_cityDataMng:GetCount()
	end	
	for k, goal in ipairs( self.goals ) do
		if goal.type == GroupGoal.SURVIVE then
			if not goal.startTime then
				goal.startTime = g_calendar:GetDateValue()
				return false
			elseif not goal.value or g_calendar:CalcDiffByMonth( goal.startTime ) < goal.value then
				return false
			end
			
		elseif goal.type == GroupGoal.INDEPENDENT then
			if not goal.startTime or self:IsDependence() then
				goal.startTime = g_calendar:GetDateValue()
				return false
			elseif not goal.value or g_calendar:CalcDiffByMonth( goal.startTime ) < goal.value then
				return false
			end
			
		elseif goal.type == GroupGoal.OCCUPY then
			if not goal.value or not self:IsOwnCity( goal.value ) then return false end
			
		elseif goal.type == GroupGoal.CONQUER then
			local number, rate = self:GetTerritoryRate()
			print( self.name .. " conquer=" .. number .. "+" .. rate .. "%", " Goal=" .. ( goal.value or 0 ) .. "+" .. ( goal.rate or 0 ) .. "%" )
			if not goal.value or not goal.rate or number < goal.value or rate < goal.rate then return false end
			
		elseif goal.type == GroupGoal.MILITARY_POWER then
			local power, rate = self:GetDominationRate()
			print( self.name .. " domination=" .. power .. "+" .. rate .. "%" .. " Goal=" .. ( goal.value or 0 ) .. "+" .. ( goal.rate or 0 ) .. "%" )
			if not goal.value or not goal.rate or power < goal.value or rate < goal.rate then return false end
		end
	end
	Debug_Normal( "Group " .. NameIDToString( self ) .. " reach goal" )
	return true	
end

function Group:CanResearch()
	if self.researchTechId ~= 0 then return false end
	if g_taskMng:IsTaskConflict( TaskType.TECH_RESEARCH, nil ) then return false end	
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
-- Order Relative
----------------------------------------------

function Group:IsBelligerent( group )
	local relation = self:GetGroupRelation( group.id )
	return relation:IsBelligerent()
end

--[[
function Group:Attack( target )
	if target ~= nil then
		self.militaryTargetId = target.id
		self.militaryMoved    = self.military
		self.military         = 0
	end
	self.lastActionName = 'Attack'
end

function Group:Defend()
	if self.militaryTargetId == self.id then
		self.militaryMoved    = self.militaryMoved + self.military
	else
		self.militaryTargetId = self.id
		self.militaryMoved    = self.military		
	end
	self.military         = 0
	
	self.lastActionName = 'Defend'
end
]]

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
end

function Group:AcceptSurrenderChara( chara )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Accept Surrender Chara " .. NameIDToString( chara ) )
	table.insert( self.charas, chara )
end

function Group:AcceptSurrenderTroop( troop )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Accept Surrender troop " .. NameIDToString( troop ) )
	table.insert( self.troops, troop )
end

function Group:AcceptSurrenderCorps( corps )
	local pastGroup = corps:GetEncampment():GetGroup()
	corps:ForeachTroop( function ( troop )	
		local leader = troop:GetLeader()
		if leader then
			pastGroup:LoseChara( leader )
			self:AcceptSurrenderChara( chara )
		end
		
		pastGroup:LoseTroop( troop )
		self:AcceptSurrenderTroop( troop )		
	end )
	
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Accept Surrender Corps " .. NameIDToString( corps ) )	
	table.insert( self.corps, corps )
end

function Group:BuryCorps( corps )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Bury corps " .. NameIDToString( corps ) )	
	
	local pastGroup = corps:GetGroup():GetGroup()
	corps:ForeachTroop( function ( troop )
		local leader = troop:GetLeader()
		if leader then
			pastGroup:LoseChara( leader )
		end
		pastGroup:LoseTroop( troop )		
	end )
end

function Group:CaptureCity( combat )
	Debug_Normal( "Group " .. NameIDToString( self ) .. " Capture city " .. NameIDToString( city ) )	
	
	local city = combat:GetLocation()
	
	--Remove city from original group
	local originalGroup = city:GetGroup()
	originalGroup:LoseCity( city )

	--Add city to owner group
	table.insert( self.cities, city )
	city:JoinGroup( self )
	
	--Corps from Original group
	-- 1. Retreat to the latest city
	-- 2. Surrender or eliminate by the attacker's strategy
	local cities = {}
	city:ForeachAdjacentCity( function ( adjCity )
		if adjCity:IsBelongToGroup( originalGroup ) then
			table.insert( cities, adjCity )
		end
	end )
	local numberOfCity = #cities
	if numberOfCity == 0 then
		local tendency = self:GetPolicyTendency( PolicyType.TREAT_SURRENDER_SOLDIER )
		if tendency == TreatSurrednerSoldier.BURY_SURRENDER_SOLDIER then
			-- de-buff will support in the future
			for k, corps in ipairs( city.corps ) do
				self:BuryCorps( corps )
			end
		elseif tendency == TreatSurrednerSoldier.ACCEPT_SURRENDER_SOLDIER then			
			for k, corps in ipairs( city.corps ) do				
				self:AcceptSurrenderCorps( corps )
			end
		end
	else
		for k, corps in ipairs( city.corps ) do
			local city = cities[k % numberOfCity]
			CorpsDispatchToCity( corps, city )
		end
	end
	
	--Corps from Owner group
	for k, corps in ipairs( combat.corps ) do
		if corps:GetGroup() == self then
			--Remove from original encampment
			corps:GetEncampment():RemoveCorps( corps )
			
			--Add to capture city
			city:AddCorps( corps )
			
			corps:DispatchToCity( city )
		end
	end
	
	--Whether group is dead
	if #originalGroup.cities == 0 then
		originalGroup:Fall()
	end
end

function Group:Fall()
	if self.government == GroupGovernment.GUERRILLA then
		--never fall
		return
	end
	
	Debug_Normal( NameIDToString( self ) .. " is fallen" )
	
	self.government = GroupGovernment.NONE
	
	--characters out
	for k, chara in ipairs( self.charas ) do
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
	--remove group
	g_groupDataMng:RemoveData( self.id )
	
	print( "group fall=" .. self.name, "next" )
end

function Group:CharaJoin( chara )
	table.insert( self.charas, chara )
end

function Group:CharaLeave( chara )
	if not MathUtility_Remove( self.charas, chara.id, "id" ) then
		print( "Remove chara ["..chara.name.."] failed!" )
	end
end

function Group:ReceiveTax( tax, city )
	self.money = self.money + tax
	print( "Receive tax=" .. tax .. " from=" .. city.name )
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
				print( "    " .. target.name .. " Pow=" .. target:GetPower() .. " +".. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " ev=" .. relation.evaluation )
			else
				print( "    " .. target.name .. " Pow=" .. target:GetPower() .. " ".. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " ev=" .. relation.evaluation )
			end
			
			--[[
			for method = DiplomacyMethod.FRIENDLY, DiplomacyMethod.SURRENDER do
				if relation:IsMethodValid( method, self, target ) then
					local prob = EvaluateDiplomacy( method, relation, self, target )
					print( MathUtility_FindEnumName( DiplomacyMethod, method ) .. " prob=" .. prob )
				end
			end
			]]
		end
	end
end

function Group:DumpCharaDetail()
	for k, chara in ipairs( self.charas ) do
		chara:Dump( "    " )
	end
end

function Group:DumpDiplomacyMethod()
	print( '' )
	print( "--------" .. self.name .. " pow=" .. self:GetPower() )
	for method = DiplomacyMethod.FRIENDLY, DiplomacyMethod.SURRENDER do
		local content = nil
		for k, relation in ipairs( self.relations ) do
			local target = relation:GetOppGroup( self.id )			
			if target and relation:IsMethodValid( method, self, target ) then
				local prob = EvaluateDiplomacy( method, relation, self, target )
				if not content then content = "" end				
				content = content .. " " .. target.name .. " prob=" .. prob --	.. "/" .. target:GetPower()
			end
		end
		if content then 
			print( MathUtility_FindEnumName( DiplomacyMethod, method ) )
			print( "  " .. content )
		end
	end
end

function Group:Dump()
	print( '>>>>>>>>>>>  Group >>>>>>>>>>>>>>>>>' )
	print( '[Group] #' .. self.id .. ' Name=' .. self.name )
	print( "Govement     =" .. MathUtility_FindEnumName( GroupGovernment, self.government ) )
	print( "PoliticalPow =" .. self._politicalPower )
	print( "EconomyPow   =" .. self._economyPower )
	print( "MilitaryPow  =" .. self._militaryPower )
	print( "Pow          =" .. self:GetPower() )
	print( "Money        =" .. self.money )
	print( "Order        =" .. self._orderNumber )
	print( "City Num     =" .. #self.cities )
	self:DumpCityDetail()
	print( "Corps Num    =" .. #self.corps )
	self:DumpCorpsDetail()
	print( "Troop Num    =" .. #self.troops )
	self:DumpTroopDetail()
	print( "Chara Num    =" .. #self.charas )
	self:DumpCharaDetail()
	print( "Tech Num     =" .. #self.techs )
	print( "Relation     =" .. #self.relations )
	self:DumpRelationDetail()
	--[[
	for k, city in pairs( self.cities ) do
		print( "City =" .. city.name )
	end	
	]]
	print( "<<<<<<<<<<< Group <<<<<<<<<<<<<<<<<<" )
end

---------------------------------------------
-- Operation Method
---------------------------------------------

function Group:InventTech( tech )
	table.insert( self.techs, tech )
	
	Debug_Normal( "["..self.name.."] finished research tech [".. tech.name .. "]" )
end

function Group:Update()
	--[[
	-- Income
	for k, city in ipairs( self.cities ) do
		self.money = self.money + city:GetIncome()
	end
	]]
	
	-- Update dynamic data, like military power evaluation
	self:UpdateDynamicData()
end

--------------------------------------
-- Tag

function Group:GetTag( tagType )
	Helper_GetTag( self.tags, tagType )
end

function Group:AppendTag( tagType, value, range )
	Helper_AppendTag( self.tags, tagType, value, range )
end

function Group:RemoveTag( tagType, value )
	Helper_RemoveTag( self.tags, tagType, value )
end

--------------------------------------
-- Intelligence

function Group:GetGroupIntel( target, type )
	--to do
end