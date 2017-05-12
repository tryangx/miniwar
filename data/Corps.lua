Corps = class()

function Corps:__init()
	self.troops = {}
end

function Corps:Generate( data )
	self.name = ""
	self:Load( data )
	self:ConvertID2Data()
end

function Corps:Load( data )
	self.id = data.id or 0	
	self.name = data.name or ""		
	------------------------------			
	self.home = data.home or 0		
	self.location   = data.location or 0	
	self.leader     = data.leader or 0	
	------------------------------	
	self.troops = MathUtility_Copy( data.troops )	
	------------------------------
	self.tags    = MathUtility_Copy( data.tags )
	------------------------------
	-- may be abandaned
	self.formation = data.formation or 0		
	------------------------------
	-- Dynamic Data	
	self._power    = 0
	-- stealthy evaluation, 
	self._size     = 0
end

function Corps:SaveData()
	--MathUtility_Dump( self )
	
	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	Data_OutputValue( "id", self )
	Data_OutputValue( "name", self )
	Data_OutputValue( "home", self, "id" )
	Data_OutputValue( "location", self, "id" )
	Data_OutputValue( "leader", self, "id", 0 )
	
	Data_OutputTable( "troops", self, "id" )
	
	Data_OutputTable( "tags", self )
	
	Data_OutputValue( "formation", self, "id" )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
end


function Corps:ConvertID2Data()
	--ShowText( "Convert corps", self.name, #self.troops )
	local troops = {}
	for k, id in ipairs( self.troops ) do
		local troop = g_troopDataMng:GetData( id )
		table.insert( troops, troop )
		if troop.corps == 0 then
			--ShowText( "!!! Fix troop corps error" )
			troop.corps = self.id
		end
		if troop.corps ~= self and troop.corps ~= self.id then
			--ShowText( "!!! Fix troop corps error 2" )
			troop.corps = self.id
		end
		if troop.home == 0 then
			--ShowText( "!!! Fix troop corps home error" )
			troop.home = self.home
		end
	end
	self.troops    = troops
	
	self.leader     = g_charaDataMng:GetData( self.leader )	
	self.home		= g_cityDataMng:GetData( self.home )	
	self.location   = g_cityDataMng:GetData( self.location )
	
	self.formation = g_formationTableMng:GetData( self.formation )
end

function Corps:CreateBrief()
	local content = "Corps=".. NameIDToString( self ).." Stay=".. NameIDToString( self.location ) .."/"..self.home.name
	content = content .. " LD=" .. ( self.leader and self.leader.name or "" ) .. " num=" .. #self.troops .. " pow=" .. self:GetPower()
	local task = g_taskMng:GetTaskByActor( self )
	if task then
		content = content .. " TASK=" .. task:CreateDesc()
	end
	if self:IsPreparedToAttack() then
		content = content .. " PREPARED"
	else
		content = content .. " IDLE"
	end
	return content
end

function Corps:Dump( indent )
	if not indent then indent = "" end
	local content = indent .. "Corps=".. NameIDToString( self ).." Stay=".. self.location.name .. " LD=" .. ( self.leader and self.leader.name or "" ) .. " num=" .. #self.troops .. ">>>"	
	ShowText( content )
	for k2, troop in ipairs( self.troops ) do
		content = NameIDToString( troop ) .. "+"..troop.number.."+"..troop.morale..","..( troop:GetLeader() and troop:GetLeader().name or "NO-LD" )
		ShowText( "	" .. content )
	end
end

------------------------------------------

function Corps:AddTroop( troop )
	table.insert( self.troops, troop )
	
	troop:JoinCorps( self )
	
	if #self.troops == 1 then
		self:RefreshName()		
	end	
	if not self.leader and troop:GetLeader() then
		self.leader = troop:GetLeader()
	end

	--ShowText( "add troop " .. NameIDToString( troop ) .. " to corps=" .. NameIDToString( self ) )
end

function Corps:RemoveTroop( troop )
	MathUtility_Remove( self.troops, troop )
end

function Corps:VoteLeader()
	--find new leader
	local reference = nil
	for k, troop in ipairs( self.troops ) do
		local leader = troop:GetLeader()
		if leader then
			if not reference or chara:IsMoreImportant( reference ) then
				reference = chara
			end
		end
	end
	return reference
end

function Corps:RefreshName()
	local oldName = self.name
	self.name = self.troops[1] and self.troops[1].name or ""
	for k, troop in ipairs( self.troops ) do
		if troop:GetLeader() == self.leader then			
			self.name = troop.name
			break
		end
	end
	self.name = self.name .. "-" .. "corps"
	--if oldName then print( "corps rename="..oldName.."->".. self.name ) end
	if not self.troops[1] then k.p = 1 end
end

function Corps:GetAsset( tagType )
	return Helper_GetVarb( self.tags, tagType )
end

function Corps:AppendAsset( tagType, value, range )
	Helper_AppendVarb( self.tags, tagType, value, range )
end

function Corps:RemoveAsset( tagType, value )
	Helper_RemoveVarb( self.tags, tagType, value )
end

------------------------------------------

function Corps:Update()
end

------------------------------------------
-- Iteration Interface

function Corps:ForeachTroop( fn )
	for k, troop in ipairs( self.troops ) do
		fn( troop )
	end
end

------------------------------------------
-- Getter

function Corps:GetLeader()
	return self.leader
end

function Corps:GetHome()
	return self.home
end

function Corps:GetLocation()
	return self.location
end

function Corps:GetGroup()
	return self.group
end

function Corps:GetPower()
	if self._power and self._power ~= 0 then return self._power end
	self._power = 0
	for k, troop in ipairs( self.troops ) do
		self._power = self._power + troop.number
	end
	return self._power
end

function Corps:GetNumOfTroop()
	return #self.troops
end

function Corps:GetNumberStatus()
	local number, totalNumber = 0, 0
	for k, troop in ipairs( self.troops ) do
		totalNumber = totalNumber + troop.maxNumber
		number = number + troop.number
	end
	return number, totalNumber
end

function Corps:GetMedianFatigue()
	local midFatigue = MathUtility_FindMedian( self.troops, "fatigue" )
	ShowText( "midFatigue=", midFatigue )
	return midFatigue
end

function Corps:GetVacancyNumber()
	return math.max( 0, QueryCorpsTroopLimit( self ) - #self.troops )
end

function Corps:GetTrainingEval()
	local training = 0
	for k, troop in ipairs( self.troops ) do
		local tag = troop:GetAsset( TroopTag.TRAINING )		
		training = training + ( tag and tag.value or 0 )
	end
	training = math.floor( training / #self.troops )
	return training
end

function Corps:IsNoneTask()
	if g_taskMng:GetTaskByActor( self ) then return false end
	for k, troop in ipairs( self.troops ) do
		if g_taskMng:GetTaskByActor( troop ) then return false end
		local task = g_taskMng:GetTaskByActor( troop:GetLeader() )
		if troop:GetLeader() and g_taskMng:GetTaskByActor( troop:GetLeader() ) then return false end
		--ShowText( "check troop nonetask" .. NameIDToString( troop ), NameIDToString( troop:GetLeader() ), task )
	end
	--ShowText( "check corps nonetask" .. NameIDToString( self ), #self.troops )
	return true
end

function Corps:IsAtHome()
	return self.location == self.home and not g_movingActorMng:HasActor( MovingActorType.CORPS, self )
end

function Corps:IsStayCity( city )
	--ShowText( "check stay", self.location.name, city.name )
	return self.location == city
end

function Corps:IsPreparedToAttack()
	local rate = 0.6
	local curNumber, maxNumber = 0, 0
	local curMorale, maxMorale = 0, 0
	for k, troop in ipairs( self.troops ) do
		curNumber = curNumber + troop.number
		maxNumber = maxNumber + troop.maxNumber
		curMorale = curMorale + troop.morale
		maxMorale = maxMorale + troop.maxMorale
		--[[
		if troop.number < troop.maxNumber * rate then 			
			if self.home.id == 801 then InputUtility_Pause( "number not enough", troop.number, troop.maxNumber ) end
			return false
		end
		if troop.morale < troop.maxMorale * rate then
			if self.home.id == 801 then InputUtility_Pause( "morale not enough", troop.morale, troop.maxMorale ) end
			return false
		end
		]]
	end
	if curNumber < maxNumber * rate or curMorale < maxMorale * rate then
		--InputUtility_Pause( "morale or number not enough", curNumber, maxNumber * rate, curMorale, maxMorale * rate )
		return false
	end
	return true
end

function Corps:IsUnderstaffed()
	for k, troop in ipairs( self.troops ) do
		if troop.number < troop.maxNumber then
			return true
		end
	end
	return false
end

function Corps:GetUnderstaffedNumber()
	local understaffed = 0
	for k, troop in ipairs( self.troops ) do
		if troop.number < troop.maxNumber then
			understaffed = understaffed + troop.maxNumber - troop.number
		end
	end
	return understaffed
end

function Corps:IsUntrained()
	local number = 0
	for k, troop in ipairs( self.troops ) do
		local tag = troop:GetAsset( TroopTag.TRAINING )		
		local value = tag and tag.value or 0
		local maxValue = math.min( troop.level, TroopParams.MAX_LEVEL ) * TroopParams.TRAINING.TRAINING_PER_LEVEL		
		if value < maxValue then
			number = number + 1
		end
	end
	return number > math.floor( #self.troops * 0.5 )
end

------------------------------------------
-- Operation

function  Corps:MoveOn( reason )
	g_movingActorMng:AddActor( MovingActorType.CORPS, self, { reason = reason } )
end

function Corps:MoveToLocation( location )
	ShowText( NameIDToString( self ) .. " move to location", location.name )
	self.location = location
	if not location then print( NameIDToString( self ) ) k.p = 1 end
	g_movingActorMng:RemoveActor( MovingActorType.CORPS, self )
end

function Corps:LeadByChara( chara )
	self.leader = chara	
	--InputUtility_Pause( "Corps [".. NameIDToString( self ) .. "] lead by [".. ( chara and chara.name or "" ).. "]" )
end

function Corps:Reinforce( reinforcement )
	local number, totalNumber = self:GetNumberStatus()
	local leftSoldier = reinforcement
	for k, troop in ipairs( self.troops ) do
		if leftSoldier <= 0 then
			break
		else
			local needSoldier = troop.maxNumber - troop.number
			if needSoldier <= leftSoldier then
				troop.number = troop.maxNumber
				leftSoldier = leftSoldier - needSoldier
			else
				troop.number = troop.number + leftSoldier
				leftSoldier = 0
				InputUtility_Pause( "add " .. leftSoldier .. " to " .. troop.name .. "," .. troop.number )
			end
		end
	end
	local teamWorkTag = Helper_GetVarb( self.tags, CorpsTag.TEAMWORK )
	if teamWorkTag then
		local loseTeamwork = math.ceil( teamWork.value * reinforcement / ( reinforcement + totalNumber ) )
		ShowText( "reduce teamwork", loseTeamwork, teamWork.value )
		Helper_RemoveVarb( self.tags, CorpsTag.TEAMWORK, loseTeamwork )
	end
end

function Corps:JoinGroup( group )
	self.group = group
end

function Corps:JoinCity( city, includeAll )
	if city and city:GetGroup() ~= self:GetGroup() then
		InputUtility_Pause( city.name .. "["..city:GetGroup().name.."] is not ", self:GetGroup().name )
		k.p = 1
	end
	self.home = city
	if includeAll then
		for k, troop in ipairs( self.troops ) do
			troop:JoinCity( city, includeAll )
		end
	end
end

---------------------------------------

function Corps:EvaluateCombatPower( combatPowerType )
	if combatPowerType == CombatPower.MELEE then

	elseif combatPowerType == CombatPower.SHOOT then
	elseif combatPowerType == CombatPower.SIEGE then
	end
	return 0
end