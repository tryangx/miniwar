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
	self.encampment = data.encampment or 0		
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
	Data_OutputValue( "encampment", self, "id" )
	Data_OutputValue( "location", self, "id" )
	Data_OutputValue( "leader", self, "id", 0 )
	
	Data_OutputTable( "troops", self, "id" )
	
	Data_OutputTable( "tags", self )
	
	Data_OutputValue( "formation", self, "id" )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
end


function Corps:ConvertID2Data()
	--print( "Convert corps", self.name, #self.troops )
	local troops = {}
	for k, id in ipairs( self.troops ) do
		local troop = g_troopDataMng:GetData( id )
		table.insert( troops, troop )
		if troop.corps == 0 then
			--print( "!!! Fix troop corps error" )
			troop.corps = self.id
		end
		if troop.corps ~= self and troop.corps ~= self.id then
			--print( "!!! Fix troop corps error 2" )
			troop.corps = self.id
		end
		if troop.encampment == 0 then
			--print( "!!! Fix troop corps encampment error" )
			troop.encampment = self.encampment
		end
	end
	self.troops    = troops
	
	self.leader     = g_charaDataMng:GetData( self.leader )	
	self.encampment = g_cityDataMng:GetData( self.encampment )	
	self.location   = g_cityDataMng:GetData( self.location )
	
	self.formation = g_formationTableMng:GetData( self.formation )
end

function Corps:Dump( indent )
	if not indent then indent = "" end
	local content = indent .. "Corps=".. self.name .." Stay=".. self.location.name .. " LD=" .. ( self.leader and self.leader.name or "" ) .. "# "
	for k2, troop in ipairs( self.troops ) do
		content = content .. troop.name .. "+"..troop.number..","
	end
	print( content )
end

------------------------------------------

function Corps:AddTroop( troop )
	table.insert( self.troops, troop )
	
	troop:AddToCorps( self )
	
	if not self.name then 
		self.name = troop.name
	end
end

function Corps:RemoveTroop( troop )
	MathUtility_Remove( self.troops, troop )
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

function Corps:GetEncampment()
	return self.encampment
end

function Corps:GetLocation()
	return self.location
end

function Corps:GetGroup()
	return self._group
end

function Corps:GetPower()
	if self._power and self._power ~= 0 then return self._power end
	self._power = 0
	for k, troop in ipairs( self.troops ) do
		self._power = self._power + troop.number
	end
	return self._power
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
	print( "midFatigue=", midFatigue )
	return midFatigue
end

function Corps:GetVacancyNumber()
	--print( "check vacancy", CorpsParams.NUMBER_OF_TROOP_MAXIMUM, #self.troops )
	return math.max( 0, CorpsParams.NUMBER_OF_TROOP_MAXIMUM - #self.troops )
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

function Corps:IsStayCity( city )
	--print( "check stay", self.location.name, city.name )
	return self.location == city
end

function Corps:IsPreparedToAttack()
	local rate = 0.6
	for k, troop in ipairs( self.troops ) do
		if troop.number < troop.maxNumber * rate then 
			--InputUtility_Pause( "number not enough", troop.number, troop.maxNumber )
			return false
		end
		if troop.morale < troop.maxMorale * rate then
			return false
		end
	end
	return true
end

function Corps:IsUnderstaffed()
	local rate = 0.8
	for k, troop in ipairs( self.troops ) do
		if troop.number < troop.maxNumber * 0.8 then
			return true
		end
	end
	return false
end

function Corps:IsUntrained()
	return self:GetTrainingEval() < TroopParams.TRAINING.UNTRAINED_VALUE
end

------------------------------------------
-- Operation

function Corps:MoveToLocation( location )
	--print( "move to location", location.name )
	self.location = location	
	for k, troop in ipairs( self.troops ) do
		local leader = troop:GetLeader()
		if leader then leader:MoveToLocation( location ) end
	end
end

function Corps:DispatchToCity( city )
	self.encampment = city
	
	Debug_Normal( "Corps [".. self.name.. "] set up an encampment in [".. city.name .. "]" )
end

function Corps:Lead( chara )
	self.leader = chara
	
	--InputUtility_Pause( "Corps [".. self.name.. "] lead by [".. chara.name .. "]" )
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
		print( "reduce teamwork", loseTeamwork, teamWork.value )
		Helper_RemoveVarb( self.tags, CorpsTag.TEAMWORK, loseTeamwork )
	end
end