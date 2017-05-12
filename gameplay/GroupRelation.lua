local debugChange = true
local watchAction = nil--"DECLARE_WAR"--= "SEPARATE"--= "THREATEN" --= "MAKE_PEACE" --= "DECLARE_WAR"--= "MAKE_PEACE"--= "SURRENDERER"
local watchGroup = nil

local function CalcNativePowerProb( group, target )
	local pow1 = math.max( 0, group:GetPower() - group:GetDependencePower() )
	local pow2 = target:GetPower()
	local ret1 = ( pow1 + pow2 == 0 ) and 0 or ( pow1 - pow2 ) / ( pow1 + pow2 )
	return ret1 * 0.5
end

local function CalcPowerProb( group, target )
	local pow1 = group:GetPower()
	local pow2 = target:GetPower()
	local ret1 = ( pow1 + pow2 == 0 ) and 0 or ( pow1 - pow2 ) / ( pow1 + pow2 )
	return ret1 * 0.5
end

local function CalcPowerPenaltyProb( group, target )
	local pow1 = group:GetPower()
	local pow2 = target:GetPower()
	local ret1 = ( pow1 + pow2 == 0 ) and 0 or ( pow2 - pow1 ) / pow2
	return ret1
end

local function GetDiplomacyMethodValue( action, relationType )
	local params = GroupRelationParam.METHOD_MOD[action]
	if not params then return 0 end
	return params[relationType] or 0 
end

GroupRelation = class()

function GroupRelation:__init()
	self.id           = 0
	self.sid          = 0
	self.tid          = 0
	self.type         = GroupRelationType.NEUTRAL
	--Measure tendency to Good or bad
	self.evaluation   = 0
	--Measure the (military)power balance between two groups
	self.powerBalance = 0
	--Measure the profit taken from target to source
	self.profit       = 0
	--Contract and sth.
	self.details      = {}
	
	self.records      = {}
end

function GroupRelation:Load( data )
	self.id             = data.id or 0	
	self.sid            = data.sid or 0	
	self.tid            = data.tid or 0	
	self.type           = GroupRelationType[data.type]	
	self.evaluation     = data.evaluation or 0	
	self.powerBalance   = data.powerBalance or 0	
	self.profit         = data.profit or 0
	self.details        = MathUtility_Copy( data.details )
end

function GroupRelation:SaveData( data )
	for k, detail in ipairs( self.details ) do
		detail.type = MathUtility_FindEnumKey( GroupRelationDetail, detail.type )
	end
	Data_OutputBegin( self.id )
	Data_IncIndent( 1 )
	Data_OutputValue( "id", self )
	Data_OutputValue( "sid", self )
	Data_OutputValue( "tid", self )
	Data_OutputValue( "type", MathUtility_FindEnumKey( GroupRelationType, self.type ) )
	Data_OutputValue( "evaluation", self )	
	Data_OutputValue( "powerBalance", self )	
	Data_OutputValue( "balance", self )
	Data_OutputValue( "profit", self )
	Data_OutputTable( "details", self )
	Data_IncIndent( -1 )
	Data_OutputEnd()
	
	self:ConvertID2Data()
end

function GroupRelation:ConvertID2Data()
	for k, detail in ipairs( self.details ) do
		detail.type = GroupRelationDetail[detail.type]
	end	
	self._sourceGroup = g_groupDataMng:GetData( self.sid )
	self._targetGroup = g_groupDataMng:GetData( self.tid )	
	self.powerBalance = self:CalcBalance()
end

function GroupRelation:Record( desc, actor )
	desc = desc .. " " .. ( actor and actor.name or "" ) .. " type=" .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " ev=" .. self.evaluation .. " pow1="..self._sourceGroup:GetPower() .. " pow2="..self._targetGroup:GetPower() .. " " .. g_calendar:CreateCurrentDateDesc( true, true )
	table.insert( self.records, desc )
end

function GroupRelation:Dump()
	print( self._sourceGroup.name, self._targetGroup.name, " type=" .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " ev=" .. self.evaluation )
end

function GroupRelation:DumpDetail()
	for k, detail in ipairs( self.details ) do
		ShowText( MathUtility_FindEnumName( GroupRelationDetail, detail.type ), detail.value )
	end
end

function GroupRelation:watchProb( action, name, ... )
	if watchAction == action then 
		if not watchGroup or watchGroup == self.sid or watchGroup == self.tid then			
			print( action .. " " .. name .. "=" .. ... )
		end
	end
end

function GroupRelation:GetOppGroup( id )
	local ret = id == self.sid and self._targetGroup or self._sourceGroup
	if ret and ret.id == id then return nil end
	return ret
end

function GroupRelation:CalcBalance()
	local pow1 = self._sourceGroup and self._sourceGroup:GetPower() or 0
	local pow2 = self._targetGroup and self._targetGroup:GetPower() or 0
	local total = pow1 + pow2
	local balance = total ~= 0 and ( pow1 - pow2 ) / total or 0
	return balance
end

---------------------------

-- ( will been discarded )
-- Return hostility evaluation
-- Higher value means more threaten
function GroupRelation:GetHostilityEvaluation()	
	if self.type == GroupRelationType.ALLIANCE then 
		return 50   + self.evaluation
	elseif self.type == GroupRelationType.FRIEND then
		return 100 + self.evaluation
	elseif self.type == GroupRelationType.NEUTRAL then
		return 200 + self.evaluation
	elseif self.type == GroupRelationType.HOSTILITY	then
		return 300 + self.evaluation
	elseif self.type == GroupRelationType.TRUCE then
		return 400 + self.evaluation	
	elseif self.type == GroupRelationType.BELLIGERENT then
		return 500 + self.evaluation
	elseif self.type == GroupRelationType.OLDENEMY then
		return 600 + self.evaluation
	end
	return 0
end

-- ( will been discarded )
function GroupRelation:GetFriendshipEvaluation()	
	if self.type == GroupRelationType.ALLIANCE then 
		return 700 + self.evaluation
	elseif self.type == GroupRelationType.FRIEND then
		return 500 + self.evaluation
	elseif self.type == GroupRelationType.NEUTRAL then	
		return 400 + self.evaluation
	elseif self.type == GroupRelationType.HOSTILITY	then
		return 300 + self.evaluation
	elseif self.type == GroupRelationType.TRUCE then
		return 200 + self.evaluation	
	elseif self.type == GroupRelationType.BELLIGERENT then
		return 100 + self.evaluation
	elseif self.type == GroupRelationType.OLDENEMY then
		return 0   + self.evaluation
	end
	return 0
end

function GroupRelation:GetDetail( detailType, groupId1, groupId2 )
	return Helper_GetRelation( self.details, detailType, groupId1, groupId2 )
end

function GroupRelation:AppendDetail( detailType, groupId, value, range )
	Helper_AppendRelation( self.details, detailType, groupId, value, range )
end

function GroupRelation:RemoveDetail( detailType, groupId, value )
	Helper_RemoveRelation( self.details, detailType, groupId, value )
end

-- At war or in truce
function GroupRelation:IsEnemy()
	if self.type == GroupRelationType.BELLIGERENT
	or self.type == GroupRelationType.TRUCE then
		return true
	end
	return false
end

function GroupRelation:IsHostility()
	if self.type == GroupRelationType.BELLIGERENT
	or self.type == GroupRelationType.ENEMY
	or self.type == GroupRelationType.TRUCE
	or self.type == GroupRelationType.HOSTILITY then
		return true
	end
	return false
end

function GroupRelation:IsFriend()
	if self.type == GroupRelationType.VASSAL 
	or self.type == GroupRelationType.DEPENDENCE
	or self.type == GroupRelationType.ALLIANCE	
	or self.type == GroupRelationType.FRIEND then	
		return true
	end
	return false
end

function GroupRelation:IsAllyOrDependence()
	if self.type == GroupRelationType.VASSAL 
	or self.type == GroupRelationType.DEPENDENCE
	or self.type == GroupRelationType.ALLIANCE then	
		return true
	end
	return false
end

function GroupRelation:IsBelligerent()
	return self.type == GroupRelationType.BELLIGERENT
end

function GroupRelation:IsDependency( suzerainId )
	return ( self.type == GroupRelationType.VASSAL or self.type == GroupRelationType.DEPENDENCE ) and ( not suzerainId or relation.sid == suzerainId )
end

-----------------------------------------

function GroupRelation:GetDiplomacyMethodProbMod( action, group, target )
	local params = GroupRelationParam.METHOD_MOD[action]
	if not params then return 0 end
	local value = 0
	
	--Detail
	local detailParams = params["DETAIL_MODULUS"]
	if detailParams then
		for k, detail in ipairs( self.details ) do
			local keyName = MathUtility_FindEnumKey( GroupRelationDetail, detail.type )
			local delta = detailParams[keyName]
			if delta then
				self:watchProb( action, "detail_modulus", keyName, detail.value, delta )
				value = value + delta * detail.value
			end
		end
	end
	
	self:watchProb( action, "value_detail", value )
	
	--Tag
	function GetTagProb( data, params )
		local ret = 0
		for k, tag in ipairs( data.tags ) do
			local keyName = MathUtility_FindEnumKey( GroupTag, tag.type )
			local delta = params[keyName]
			if delta then
				self:watchProb( action, "tag_modulus", keyName, tag.value, delta )
				ret = ret + delta * tag.value
			end
		end
		return ret
	end
	local selfTagParams = params["SELF_TAG_MODULUS"]
	local targetTagParams = params["TARGET_TAG_MODULUS"]
	if selfTagParams then value = value + GetTagProb( group, selfTagParams ) end
	if targetTagParams then value = value + GetTagProb( group, targetTagParams ) end
	
	self:watchProb( action, "value_tag", value )

	--Distance
	if not group:IsAdjacentGroup( target ) then
		local delta = params["DISTANCE"]
		if delta and delta ~= 0 then
			self:watchProb( action, "distance_modulus", value, delta )
			value = value + delta
		end
	end
	
	self:watchProb( action, "value_dis", value )
	
	--[[
	--Goals	
	function GetGoalProb( data, params )
		local ret = 0
		for k, goal in ipairs( data.goals ) do
			local delta
			if goal.type == GroupGoal.INDEPENDENT then
				delta = params["INDEPENDENT"]
			elseif goal.type >= GroupGoal.SURVIVAL_GOAL_BEG and goal.type <= GroupGoal.SURVIVAL_GOAL_END then
				delta = params["SURVIVAL"]
			elseif goal.type >= GroupGoal.DOMINATION_GOAL_BEG and goal.type <= GroupGoal.DOMINATION_GOAL_END then
				delta = params["DOMINATION"]
			elseif goal.type >= GroupGoal.LEADING_GOAL_BEG and goal.type <= GroupGoal.LEADING_GOAL_END then
				delta = params["LEADING"]
			end			
			if delta then ret = ret + delta end
		end
		return ret
	end
	local selfParams = params["SELF_GOALS"]
	local targetParams = params["TARGET_GOALS"]
	if selfParams then
		self:watchProb( action, "self goal mod", GetGoalProb( group, selfParams ) )
		value = value + GetGoalProb( group, selfParams )
	end
	if targetParams then
		self:watchProb( action, "target goal mod", GetGoalProb( group, selfParams ) )
		value = value + GetGoalProb( target, targetParams )
	end
	self:watchProb( action, "value_goals", value )
	--]]
	
	--Dependency
	if params["SELF_IS_DEPENDENCY"] then
		if group:IsDependence() then
			self:watchProb( action,  "self dep mod", params["SELF_IS_DEPENDENCY"] )
			value = value + params["SELF_IS_DEPENDENCY"]
		end
	end
	if params["SELF_IS_VASSAL"] then
		if group:IsVassal() then
			self:watchProb( action,  "self vassal mod", params["SELF_IS_VASSAL"] )
			value = value + params["SELF_IS_VASSAL"]
		end
	end
	self:watchProb( action, "value_depen", value )
	
	local groupEnemyRelations, groupFriendFronts = nil, nil
	local targetEnemyRelations, targetFriendFronts = nil, nil
	
	--belligerent
	if params["SAME_ENEMY"] and params["SAME_ENEMY"] ~= 0 then
		groupEnemyRelations, groupFriendFronts = group:GetBelligerentStatus( nil )
		targetEnemyRelations, targetFriendFronts = target:GetBelligerentStatus( group )
		local number = 0
		for k1, relation1 in ipairs( groupEnemyRelations ) do
			if MathUtility_FindData( targetEnemyRelations, relation1.sid == group.id and relation1.tid or relation1.sid, "sid" )
			or MathUtility_FindData( targetEnemyRelations, relation1.sid == group.id and relation1.tid or relation1.sid, "tid" ) then
				number = number + 1
			end
		end
		self:watchProb( action,  "same enemy mod", number * params["SAME_ENEMY"] )
		value = value + number * params["SAME_ENEMY"]
	end
	
	self:watchProb( action, "value_belli", value )
	
	if ( params["TARGET_MULTIPLE_FRONTS"] and params["TARGET_MULTIPLE_FRONTS"] ~= 0 ) or ( params["FRIEND_BELLIGERENT"] and params["FRIEND_BELLIGERENT"] ~= 0 ) then
		if not targetEnemyRelations or not targetFriendFronts then
			targetEnemyRelations, targetFriendFronts = target:GetBelligerentStatus( group )
		end
		if params["TARGET_MULTIPLE_FRONTS"] then
			--[[
			if watchAction == action then			
				print( "enemy multiple fronts=" .. #targetEnemyRelations )
				for k, relation in ipairs( targetEnemyRelations ) do
					relation:Dump()
				end
			end
			]]
			self:watchProb( action,  "target mul-fronts mod", #targetEnemyRelations * params["TARGET_MULTIPLE_FRONTS"] )
			value = value + #targetEnemyRelations * params["TARGET_MULTIPLE_FRONTS"]
		end
		if params["FRIEND_BELLIGERENT"] then
			self:watchProb( action,  "friend mul-fronts mod", targetFriendFronts * params["FRIEND_BELLIGERENT"] )
			value = value + targetFriendFronts * params["FRIEND_BELLIGERENT"]
		end
	end
	
	self:watchProb( action, "value_fronts", value )
	
	if params["SELF_MULTIPLE_FRONTS"] and params["SELF_MULTIPLE_FRONTS"] ~= 0 then
		if not groupEnemyRelations or not groupFriendFronts then
			groupEnemyRelations, groupFriendFronts = group:GetBelligerentStatus( nil )
		end		
		if params["SELF_MULTIPLE_FRONTS"] then
			local modify = MathUtility_Clamp( #groupEnemyRelations * params["SELF_MULTIPLE_FRONTS"], 0, GroupRelationParam.METHOD_MOD.MAX_SINGLE_MOD )
			self:watchProb( action,  "self mul-fronts mod", modify )			
			value = value + modify
		end
	end
	
	self:watchProb( action, "value_selfronts", value )
	
	return value
end

function GroupRelation:GetDipomacyMethodProb( action, group, target )
	local value1 = GetDiplomacyMethodValue( action, self.type )	
	self:watchProb( action, "*relation mod", value1 )
	local value2 = self:GetDiplomacyMethodProbMod( action, group, target )	
	self:watchProb( action, "*other mod", value2 )
	local basePart = ( value1 + math.max( 0, value2 ) ) * GroupRelationParam.EVALUATION_RANGE + self.evaluation
	local powerPart = 0
	if GroupRelationParam.METHOD_MOD[action].POWER_PENALTY_MODULUS then		
		local penalty = math.floor( CalcPowerPenaltyProb( group, target ) * GroupRelationParam.METHOD_MOD[action].POWER_PENALTY_MODULUS )
		powerPart = powerPart - ( penalty > 0 and penalty or 0 )
		--if penalty > 0 then InputUtility_Pause( "penalty=" .. penalty ) end
	end
	if GroupRelationParam.METHOD_MOD[action].POWER_MODULUS then
		powerPart = powerPart + math.floor( CalcPowerProb( group, target ) * GroupRelationParam.METHOD_MOD[action].POWER_MODULUS )
	end
	if GroupRelationParam.METHOD_MOD[action].NATIVE_POWER_MODULUS then
		powerPart = powerPart + math.floor( CalcNativePowerProb( group, target ) * GroupRelationParam.METHOD_MOD[action].NATIVE_POWER_MODULUS )
	end
	local total = basePart + powerPart
	self:watchProb( action, "*base prob", basePart )
	self:watchProb( action, "*power mod", powerPart )
	self:watchProb( action, "*total", total )
	if action == watchAction then--and total >= 5000 then 	
		print( group.name .."+"..group:GetPower(), target.name.."+"..target:GetPower() .. " ->".. MathUtility_FindEnumName( GroupRelationType, self.type ) )
		--if self.type == GroupRelationType.DEPENDENCE then
			InputUtility_Pause( group.name .. " want to " .. action .. " " .. self:GetOppGroup( group.id ).name )
		--end
	end
	return total
end

function GroupRelation:EvalFriendlyProb( chara, group, target )
	local totalNum, numOfFriend = group:GetBelligerentStatus( target )
	if numOfFriend and numOfFriend > 0 then return 0 end	
	local prob = self:GetDipomacyMethodProb( "FRIENDLY", group, target )	
	return prob
end

function GroupRelation:EvalAllyProb( chara, group, target )
	local totalNum, numOfFriend = group:GetBelligerentStatus( target )
	if numOfFriend and numOfFriend > 0 then return 0 end	
	local prob = self:GetDipomacyMethodProb( "ALLY", group, target )
	return prob
end

function GroupRelation:EvalMakePeaceProb( chara, group, target )
	local prob = self:GetDipomacyMethodProb( "MAKE_PEACE", group, target )	
	local mod = 0
	local detail = self:GetDetail( GroupRelationDetail.BELLIGERENT_DURATION )	
	if detail then
		mod = mod + detail.value * GroupRelationParam.MAKE_PEACE_DAYS_POW_MODULUS
	end
	detail = self:GetDetail( GroupRelationDetail.WAR_DECLARER, group.id )
	if detail then
		mod = mod + GroupRelationParam.MAKE_PEACE_DECLARER_PENALTY
	end
	mod = mod + GroupRelationParam.MAKE_PEACE_DAYS_PROB_MOD
	self:watchProb( "MAKE_PEACE", "mod", mod )
	local profit = group.id == self.sid and self.profit or -self.profit
	local profitMod = GroupRelationParam.MAKE_PEACE_PROFIT_MODULUS * ( profit - GroupRelationParam.MAKE_PEACE_PROFIT_NEED )
	--InputUtility_Pause( "profit mod=" .. profitMod )
	return prob + mod + profitMod
end

function GroupRelation:EvalThreatenProb( chara, group, target )
	local prob = self:GetDipomacyMethodProb( "THREATEN", group, target )
	local pow1 = group:GetPower()
	local pow2 = target:GetPower()
	if nil and prob > 5000 and pow1 < pow2 then
		watchAction = "THREATEN"
		prob = self:GetDipomacyMethodProb( "THREATEN", group, target )
		InputUtility_Pause( group.name .. "+" .. pow1 .. "->" .. target.name .. "+" .. pow2 .. "=" .. prob )
	end
	return prob
end

function GroupRelation:EvalSurrenderProb( chara, group, target )
	return self:GetDipomacyMethodProb( "SURRENDER", group, target )
end

function GroupRelation:EvalDeclareWarProb( chara, group, target )
	local prob = self:GetDipomacyMethodProb( "DECLARE_WAR", group, target )
	--profit mod
	local mod = 0
	local detail = self:GetDetail( GroupRelationDetail.TRUCE_TIME_DURATION )
	if detail then
		mod = mod + detail.value * GroupRelationParam.MAKE_PEACE_DAYS_POW_MODULUS
	end
	local profit = group.id == self.sid and self.profit or -self.profit
	local profitMod = math.max( 0, GroupRelationParam.DECLARE_WAR_PROFIT_MODULUS * ( GroupRelationParam.DECLARE_WAR_PROFIT_NEED - profit ) )
	prob = prob + mod + profitMod
	return prob
end

function GroupRelation:EvalBreakContractProb( chara, group, target )
	local action
	if self:IsDependency() and self.tid == group.id then
		action = "SEPARATE"
	else
		action = "BREAK_CONTRACT"
	end	
	local prob = self:GetDipomacyMethodProb( action, group, target )
	return prob
end

function GroupRelation:IsMethodValid( method, group, target )
	if not target then return false end
	if method == DiplomacyMethod.FRIENDLY then
		if group:IsVassal()
		or self.type == GroupRelationType.BELLIGERENT
		or self.type == GroupRelationType.TRUCE
		or self:GetDetail( GroupRelationDetail.OLD_ENEMY, group.id, target.id )
		or self.evaluation >= GroupRelationParam.MAX_EVALUATION * 0.8 then
			return false
		end
	elseif method == DiplomacyMethod.THREATEN then
		if target:IsVassal()
		or group:IsDependence()
		or group:IsVassal()
		or self:GetDetail( GroupRelationDetail.OLD_ENEMY, group.id, target.id ) then
			return false
		end
		if self.type == GroupRelationType.BELLIGERENT
		or self.type == GroupRelationType.TRUCE
		or self.type == GroupRelationType.ALLIANCE
		or self.type == GroupRelationType.VASSAL then
			return false
		end
	elseif method == DiplomacyMethod.ALLY then
		if self.type == GroupRelationType.FRIEND
		and not self:GetDetail( GroupRelationDetail.OLD_ENEMY, group.id, targetId ) then
			return true
		end
		return false
	elseif method == DiplomacyMethod.DECLARE_WAR then
		if group:IsVassal()
		or self.type == GroupRelationType.BELLIGERENT
		or self.type == GroupRelationType.TRUCE
		or self.type == GroupRelationType.ALLIANCE
		or self.type == GroupRelationType.DEPENDENCE
		or self.type == GroupRelationType.VASSAL
		or #group.corps <= QueryGroupNeedCorpsForWar( group ) then			
			return false
		end	
		--InputUtility_Pause( "group=" .. #group.corps .. " need=" .. QueryGroupNeedCorpsForWar( group ) .. " " .. group.name )
	elseif method == DiplomacyMethod.MAKE_PEACE then		
		if self.type == GroupRelationType.BELLIGERENT then
			local detail = self:GetDetail( GroupRelationDetail.BELLIGERENT_DURATION )
			--InputUtility_Pause( "bel " .. detail.value .. "+" .. GroupRelationParam.MAKE_PEACE_BELLIGERENT_TIME )
			if detail and detail.value >= GroupRelationParam.MAKE_PEACE_BELLIGERENT_TIME then
				return false--true
			end
		end		
		return false
	elseif method == DiplomacyMethod.BREAK_CONTRACT then
		if self.type == GroupRelationType.BELLIGERENT
		or self.type == GroupRelationType.ENEMY
		or self.type == GroupRelationType.HOSTILITY
		or self.type == GroupRelationType.NEUTRAL
		or self.type == GroupRelationType.TRUCE
		or self.type == GroupRelationType.FRIEND then
			return false
		end
		if ( self.type == GroupRelationType.DEPENDENCE or self.type == GroupRelationType.VASSAL ) and self.sid == group.id then
			return false
		end
		
	elseif method == DiplomacyMethod.SURRENDER then
		if not group:IsIndependence()
		or self.type == GroupRelationType.ALLIANCE
		or self.type == GroupRelationType.VASSAL
		or ( self.type == GroupRelationType.DEPENDENCE and self.sid == group.id ) then
			return false
		end
	end
	return target
end

function GroupRelation:DebugImportantRelationChanged( content )
	content = "[DIPLOMACY] " .. ( self._sourceGroup and self._sourceGroup.name or self.sid ) .. "/" .. ( self._targetGroup and self._targetGroup.name or self.tid ) .. " " .. content
	Debug_Normal( content )
	if debugChange then InputUtility_Pause( "" ) end
end

function GroupRelation:DebugRelationChanged( content )
	content = "[DIPLOMACY] " .. ( self._sourceGroup and self._sourceGroup.name or self.sid ) .. "/" .. ( self._targetGroup and self._targetGroup.name or self.tid ) .. " " .. content
	Debug_Normal( content )
	--if debugChange then InputUtility_Pause( "" ) end
end

function GroupRelation:Improve( delta )
	self.evaluation = MathUtility_Clamp( self.evaluation + delta, GroupRelationParam.MIN_EVALUATION, GroupRelationParam.MAX_EVALUATION )
	if self.evaluation >= GroupRelationParam.MAX_EVALUATION then	
		if self.type == GroupRelationType.NEUTRAL then
			self.type = GroupRelationType.FRIEND
		elseif self.type == GroupRelationType.HOSTILITY then
			self.type = GroupRelationType.NEUTRAL
		elseif self.type == GroupRelationType.ENEMY then
			self.type = GroupRelationType.HOSTILITY			
		else
			return
		end
		self.value = GroupRelationParam.MIN_EVALUATION
		self:RemoveDetail( GroupRelationDetail.HOSTILITY, 1 )
		ShowText( "improve", delta )
		self:DebugRelationChanged( " Improve relation type=" .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
	else
		--Debug_Normal( "[DIPLOMACY] " .. self._sourceGroup.name .. "/" .. self._targetGroup.name  .. " Improve relation evaluation=" .. self.evaluation )
	end
	return true
end

function GroupRelation:Deteriorate( delta )
	self.evaluation = MathUtility_Clamp( self.evaluation - delta, GroupRelationParam.MIN_EVALUATION, GroupRelationParam.MAX_EVALUATION )
	if self.evaluation <= GroupRelationParam.MIN_EVALUATION then
		if self.type == GroupRelationType.FRIEND then
			self.type = GroupRelationType.NEUTRAL
		elseif self.type == GroupRelationType.NEUTRAL then
			self.type = GroupRelationType.HOSTILITY		
		else
			return
		end
		self.value = GroupRelationParam.MAX_EVALUATION		
		self:DebugRelationChanged( " Deteriorate relation type=" .. MathUtility_FindEnumName( GroupRelationType, self.type ) )		
	else
		--Debug_Normal( "[DIPLOMACY] " .. self._sourceGroup.name .. "/" .. self._targetGroup.name  .. " Deteriorate relation evaluation=" .. self.evaluation )
	end
	return true
end

function GroupRelation:Threaten( group, chara )	
	local target = self:GetOppGroup( group.id )
	local prob = self:EvalThreatenProb( chara, group, target )
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Threaten" )
	if value <= prob then
		local relationType = GroupRelationType.DEPENDENCE
		if self.type == GroupRelationType.DEPENDENCE then relationType = GroupRelationType.VASSAL end
		self.sid = group.id
		self.tid = target.id
		self._sourceGroup = g_groupDataMng:GetData( self.sid )
		self._targetGroup = g_groupDataMng:GetData( self.tid )
		self.type = relationType
		self.evaluation = math.floor( self.evaluation * 0.5 )
		self.profit = -self.profit
		self:DebugRelationChanged( NameIDToString( group ) .. "("..group:GetPower()..")" .. " threaten " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) )		
		self:Record( "Threaten", group )
		return true
	else	
		if self.type == GroupRelationType.HOSTILITY then		
			self:AppendDetail( GroupRelationDetail.CASUS_BELLI, group.id, 3, GroupRelationParam.MAX_DETAIL_VALUE[GroupRelationDetail.CASUS_BELLI] )
		elseif self.type == GroupRelationType.NEUTRAL then
			self:AppendDetail( GroupRelationDetail.CASUS_BELLI, group.id, 2, GroupRelationParam.MAX_DETAIL_VALUE[GroupRelationDetail.CASUS_BELLI] )
		elseif self.type == GroupRelationType.FRIEND then
			self:AppendDetail( GroupRelationDetail.CASUS_BELLI, group.id, 1, GroupRelationParam.MAX_DETAIL_VALUE[GroupRelationDetail.CASUS_BELLI] )
		end
		self:Deteriorate( GroupRelationParam.EVALUATION_RANGE * GroupRelationParam.THREATEN_DETERIORATE_RATIO )
		Debug_Normal( "[DIPLOMACY] " .. self._sourceGroup.name .. "/" .. self._targetGroup.name  .. " " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to threaten " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )
	end
end

function GroupRelation:Ally( group, chara )	
	local target = self:GetOppGroup( group.id )
	local prob = self:EvalAllyProb( chara, group, target )
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Ally" )
	if value <= prob then
		self.type = GroupRelationType.ALLIANCE		
		self.evaluation = math.floor( self.evaluation * 0.5 )
		self:AppendDetail( GroupRelationDetail.ALLIANCE_TIME_REMAINS, nil, GroupRelationParam.DEFAULT_ALLIANCE_DAY )
		self:DebugRelationChanged( NameIDToString( group ) .. "("..group:GetPower()..")" .. " ally relationship with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) )		
		self:Record( "Ally", group )
		return true
	else
		Debug_Normal( "[DIPLOMACY] " .. self._sourceGroup.name .. "/" .. self._targetGroup.name  .. " ".. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to ally with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )		
	end
end

function GroupRelation:MakePeace( group, chara )
	local target = self:GetOppGroup( group.id )
	local prob = self:EvalMakePeaceProb( chara, group, target )
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Make peace" )
	if value <= prob then
		self.type = GroupRelationType.TRUCE
		self:RemoveDetail( GroupRelationDetail.TRUCE_TIME_DURATION, nil )
		self:AppendDetail( GroupRelationDetail.TRUCE_TIME_REMAINS, nil, GroupRelationParam.DEFAULT_TRUCE_DAY )
		self:DebugRelationChanged( NameIDToString( group ) .. "("..group:GetPower()..")" .. " make peace with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
		self:Record( "Make peace", group )
		return true
	else
		self:AppendDetail( GroupRelationDetail.DECLINATURE, group.id, 1, GroupRelationParam.MAX_DETAIL_VALUE[GroupRelationDetail.DECLINATURE] )
		Debug_Normal( "[DIPLOMACY] " .. self._sourceGroup.name .. "/" .. self._targetGroup.name  .. " ".. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to make peace with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )		
	end
end

function GroupRelation:EndTruce()
	if self.type == GroupRelationType.TRUCE then
		self.type = GroupRelationType.ENEMY
		self:Record( "End truce", group )
	end
end

function GroupRelation:EndAlliance()
	if self.type == GroupRelationType.ALLIANCE then
		self.type = GroupRelationType.FRIEND
		self:Record( "End alliance", group )
	end
end

function GroupRelation:Surrender( group, char )
	local target = self:GetOppGroup( group.id )
	local prob = self:EvalSurrenderProb( chara, group, target )
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Make peace" )
	if value <= prob then
		if self.type == GroupRelationType.BELLIGERENT	
		or self.type == GroupRelationType.ENEMY
		or self.type == GroupRelationType.TRUCE
		or self.type == GroupRelationType.HOSTILITY
		or self.type == GroupRelationType.NEUTRAL
		or self.type == GroupRelationType.FRIEND then
			self.type = GroupRelationType.DEPENDENCE
		elseif self.type == GroupRelationType.DEPENDENCE and self.tid == groupId then	
			self.type = GroupRelationType.VASSAL
			self.evaluation = math.floor( self.evaluation * 0.5 )
		end
		self:DebugRelationChanged( NameIDToString( group ) .. "("..group:GetPower()..")" .. " surrender to " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. value .. "/" .. prob )
		self:Record( "Surrender", group )
		return true
	else
		self:AppendDetail( GroupRelationDetail.DECLINATURE, group.id, 1, GroupRelationParam.MAX_DETAIL_VALUE[GroupRelationDetail.DECLINATURE] )
		Debug_Normal( "[DIPLOMACY] " .. self._sourceGroup.name .. "/" .. self._targetGroup.name  .. " ".. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to surrender to " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )
	end
end

function GroupRelation:Friendly( group, chara )
	local target = self:GetOppGroup( group.id )
	local prob = self:EvalFriendlyProb( chara, group, target )
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Friendly" )
	if value <= prob then
		local improve = GroupRelationParam.FRIENDLY_IMPROVE
		if chara then
			local trait = chara:QueryTrait( TraitEffectType.DIPLOMACY_FRIENDLY_BONUS )			
			if trait then
				improve = improve + trait.value
			end
		end
		self:Improve( improve )
		self:DebugRelationChanged( NameIDToString( group ) .. "("..group:GetPower()..")" .. " improve relationship with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
		self:Record( "Friendly", group )
		return true
	else
		self:AppendDetail( GroupRelationDetail.DECLINATURE, group.id, 1, GroupRelationParam.MAX_DETAIL_VALUE[GroupRelationDetail.DECLINATURE] )
		Debug_Normal( "[DIPLOMACY] " .. self._sourceGroup.name .. "/" .. self._targetGroup.name  .. " ".. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to improve relationship with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )
	end
end

function GroupRelation:BreakContract( group, chara )	
	local target = self:GetOppGroup( group.id )
	local value = 0
	if self.type == GroupRelationType.TRUCE then
		self.type = GroupRelationType.BELLIGERENT
		value = 3
	elseif self.type == GroupRelationType.ALLIANCE then
		self.type = GroupRelationType.NEUTRAL
		value = 2
	elseif self.type == GroupRelationType.DEPENDENCE then
		self.type = GroupRelationType.FRIEND
		value = 1
	elseif self.type == GroupRelationType.VASSAL then
		self.type = GroupRelationType.FRIEND
		value = 1
	else
		return false
	end
	self:AppendDetail( GroupRelationDetail.BETRAYER, group.id, value, GroupRelationParam.MAX_DETAIL_VALUE[GroupRelationDetail.BETRAYER] )
	target:AppendAsset( GroupTag.BETRAYER, value, GroupRelationParam.MAX_TAG_VALUE[GroupTag.BETRAYER] )
	self.evaluation = GroupRelationParam.MIN_EVALUATION
	self:DebugRelationChanged( NameIDToString( group ) .. "("..group:GetPower()..")" .. " break contract with " .. NameIDToString( target ) .. "("..target:GetPower()..")" )
	self:Record( "Breakcontract", group )
	return true
end

function GroupRelation:DeclareWar( group, chara )
	local target = self:GetOppGroup( group.id )
	if not target then
		ShowText( "Target ["..( group.id == self.sid and self.tid or self.sid ) .. "] isn't exist, cann't declare war" )
		return
	end
	if self.type == GroupRelationType.ALLIANCE then
		--dismiss alliance contract
		self.type = GroupRelationType.NEUTRAL
		self.evaluation = self.evaluation * 0.5
		self:AppendDetail( GroupRelationDetail.HOSTILITY, nil, 1 )
		--self:DebugImportantRelationChanged( NameIDToString( group ) .. "("..group:GetPower()..")" .. " dismiss alliance with " .. NameIDToString( target ) .. "("..target:GetPower()..")" )
		return true
	end
	local value = 0
	if self.type == GroupRelationType.ENEMY then
		value = 1
	elseif self.type == GroupRelationType.HOSTILITY then
		value = 2
	elseif self.type == GroupRelationType.NEUTRAL then
		value = 3
	elseif self.type == GroupRelationType.FRIEND then		
		value = 5
	else
		return false
	end	
	local detail = self:GetDetail( GroupRelationDetail.CASUS_BELLI )
	if detail then
		value = value - detail.value
		self:RemoveDetail( GroupRelationDetail.CASUS_BELLI, detail.value )
	end
	if value > 0 then
		group:AppendAsset( GroupTag.MILITANT, value, GroupRelationParam.MAX_TAG_VALUE[GroupTag.MILITANT] )
	end
	self:AppendDetail( GroupRelationDetail.WAR_DECLARER, group.id, 1 )
	self:AppendDetail( GroupRelationDetail.HOSTILITY, nil, 1 )
	self.type = GroupRelationType.BELLIGERENT
	self.evaluation = GroupRelationParam.MIN_EVALUATION
	--self:DebugImportantRelationChanged( NameIDToString( group ) .. "("..group:GetPower()..")" .. " declare war at " .. NameIDToString( target ) .. "("..target:GetPower()..")" )
	self:Record( "Declare war", group )
	
	--check alliance
	for k, relation in ipairs( target.relations ) do
		if relation.type == GroupRelationType.ALLIANCE then
			local relation2 = group:GetGroupRelation( relation.sid == target.id and relation.tid or relation.sid )
			relation2:DeclareWar( group, nil )
		elseif relation:IsDependency() then
			local relation2 = group:GetGroupRelation( relation.sid == target.id and relation.tid or relation.sid )
			relation2:DeclareWar( group, nil )
		end		
	end
	
	return true
end

function GroupRelation:ExecuteMethod( method, group, chara )
	--	 "execute diplomacy method", MathUtility_FindEnumName( DiplomacyMethod, method ) )
	if method == DiplomacyMethod.NONE then
		return self:Deteriorate( GroupRelationParam.LEAVE_DETERIORATE )
	elseif method == DiplomacyMethod.FRIENDLY then	
		return self:Friendly( group, chara )
	elseif method == DiplomacyMethod.THREATEN then
		return self:Threaten( group, chara )
	elseif method == DiplomacyMethod.ALLY then
		return self:Ally( group, chara )
	elseif method == DiplomacyMethod.DECLARE_WAR then
		return self:DeclareWar( group, chara )
	elseif method == DiplomacyMethod.MAKE_PEACE then
		return self:MakePeace( group, chara )
	elseif method == DiplomacyMethod.BREAK_CONTRACT then
		return self:BreakContract( group, chara )
	elseif method == DiplomacyMethod.SURRENDER then
		return self:Surrender( group, chara )
	end
	return false
end

function GroupRelation:GainProfit( group, profit )
	if group.id == self.sid then
		self.profit = self.profit + profit
	elseif group.id == self.tid then
		self.profit = self.profit - profit
	end
	--print( "profit=" .. self.profit .. " " .. profit )
end