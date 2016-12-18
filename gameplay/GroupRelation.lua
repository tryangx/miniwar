local debugProb = nil

GroupRelation = class()

function GroupRelation:__init()
	self.id         = 0
	self.sid        = 0
	self.tid        = 0
	self.type       = GroupRelationType.NEUTRAL
	self.evaluation = 0
	self.balance    = 0
	self.traits     = {}
end

function GroupRelation:Load( data )
	self.id             = data.id or 0	
	self.sid            = data.sid or 0	
	self.tid            = data.tid or 0	
	self.type           = GroupRelationType[data.type]	
	self.evaluation     = data.evaluation or 0	
	self.balance        = data.balance or 0	
	self.traits         = MathUtility_Copy( data.traits )
end

function GroupRelation:SaveData( data )
	for k, trait in ipairs( self.traits ) do
		trait.type = MathUtility_FindEnumKey( GroupRelationTrait, trait.type )
	end
	Data_OutputBegin( self.id )
	Data_IncIndent( 1 )
	Data_OutputValue( "id", self )
	Data_OutputValue( "sid", self )
	Data_OutputValue( "tid", self )
	Data_OutputValue( "type", MathUtility_FindEnumKey( GroupRelationType, self.type ) )
	Data_OutputValue( "evaluation", self )	
	Data_OutputValue( "balance", self )	
	Data_OutputTable( "traits", self )	
	Data_IncIndent( -1 )
	Data_OutputEnd()
	
	self:ConvertID2Data()
end

function GroupRelation:ConvertID2Data()
	for k, trait in ipairs( self.traits ) do
		trait.type = GroupRelationTrait[trait.type]
	end	
	self._sourceGroup = g_groupDataMng:GetData( self.sid )
	self._targetGroup = g_groupDataMng:GetData( self.tid )	
	self.balance = self:CalcBalance()
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

function GroupRelation:GetTrait( traitType, groupId1, groupId2 )
	for k, trait in ipairs( self.traits ) do
		if trait.type == traitType and ( trait.id == 0 or trait.id == groupId1 or trait.id == groupId2 ) then
			return trait
		end
	end
	return nil
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

function GroupRelation:IsBelligerent()
	return self.type == GroupRelationType.BELLIGERENT
end

function GroupRelation:IsDependency( suzerainId )
	return ( self.type == GroupRelationType.VASSAL or self.type == GroupRelationType.DEPENDENCE ) and ( not suzerainId or relation.sid == suzerainId )
end

-----------------------------------------

local function CalcPowerProb( group, target )
	local pow1 = group:GetPower()
	local pow2 = target:GetPower()
	local supply1 = group:GetMaxSupply()
	local supply2 = target:GetMaxSupply()
	local ret1 = ( pow1 + pow2 == 0 ) and 0 or ( pow1 - pow2 ) / ( pow1 + pow2 )
	local ret2 = ( supply1 + supply2 == 0 ) and 0 or ( supply1 - supply2 ) / ( supply1 + supply2 )
	return ( ret1 + ret2 ) * 0.5
end

local function GetDiplomacyMethodValue( action, relationType )
	local params = GroupRelationParam.METHOD_MOD[action]
	if not params then return 0 end
	return params[relationType] or 0 
end

local function Debug( ... )
	if debugProb then
		print( ... )
	end
end

function GroupRelation:GetDiplomacyMethodProbMod( action, group, target )
	local params = GroupRelationParam.METHOD_MOD[action]
	if not params then return 0 end
	local value = 0
	
	--Trait
	local traitParams = params["TRAIT_MODULUS"]
	if traitParams then
		for k, trait in ipairs( self.traits ) do
			local keyName = MathUtility_FindEnumKey( GroupRelationTrait, trait.type )
			local delta = traitParams[keyName]
			if delta then
				Debug( "Trait modulus=", trait.value )
				value = value + delta * trait.value
			end
		end
	end
	
	--Tag
	function GetTagProb( data, params )
		local ret = 0
		for k, tag in ipairs( data.tags ) do
			local keyName = MathUtility_FindEnumKey( GroupTag, tag.type )
			local delta = params[keyName]
			if delta then
				Debug( "Tag modulus=", tag.value )
				ret = ret + delta * tag.value
			end
		end
		return ret
	end
	local selfTagParams = params["SELF_TAG_MODULUS"]
	local targetTagParams = params["TARGET_TAG_MODULUS"]
	if selfTagParams then value = value + GetTagProb( group, selfTagParams ) end
	if targetTagParams then value = value + GetTagProb( group, targetTagParams ) end

	--Distance
	if not group:IsAdjacentGroup( target.id ) then
		local delta = params["DISTANCE"]
		if delta and delta ~= 0 then
			Debug( "distance modulus=", delta )
			value = value + delta
		end
	end
	
	--Goals	
	function GetGoalProb( data, params )
		local ret = 0
		for k, goal in ipairs( data.goals ) do
			local delta
			if goal.type == GroupGoal.INDEPENDENT then
				delta = params["INDEPENDENT"]
			elseif goal.type >= GroupGoal.SURVIVAL_BEG and goal.type <= GroupGoal.SURVIVAL_END then
				delta = params["SURVIVAL"]
			elseif goal.type >= GroupGoal.DOMINATION_BEG and goal.type <= GroupGoal.DOMINATION_END then
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
		Debug( "self goal mod=", GetGoalProb( group, selfParams ) )
		value = value + GetGoalProb( group, selfParams )
	end
	if targetParams then
		Debug( "target goal mod=", GetGoalProb( group, selfParams ) )
		value = value + GetGoalProb( target, targetParams )
	end
	
	--Dependency
	if params["SELF_IS_DEPENDENCY"] then
		if group:IsDependence() then
			Debug( "self dep mod=", params["SELF_IS_DEPENDENCY"] )
			value = value + params["SELF_IS_DEPENDENCY"]
		end
	end
	if params["SELF_IS_VASSAL"] then
		if group:IsVassal() then
			Debug( "self vassal mod=", params["SELF_IS_VASSAL"] )
			value = value + params["SELF_IS_VASSAL"]
		end
	end
	
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
		Debug( "same enemy mod=", number * params["SAME_ENEMY"] )
		value = value + number * params["SAME_ENEMY"]
	end
	
	if ( params["TARGET_MULTIPLE_FRONTS"] and params["TARGET_MULTIPLE_FRONTS"] ~= 0 ) or ( params["FRIEND_BELLIGERENT"] and params["FRIEND_BELLIGERENT"] ~= 0 ) then
		if not targetEnemyRelations or not targetFriendFronts then
			targetEnemyRelations, targetFriendFronts = target:GetBelligerentStatus( group )
		end
		if params["TARGET_MULTIPLE_FRONTS"] then
			Debug( "target mul-fronts mod=", #targetEnemyRelations * params["TARGET_MULTIPLE_FRONTS"] )
			value = value + #targetEnemyRelations * params["TARGET_MULTIPLE_FRONTS"]
		end
		if params["FRIEND_BELLIGERENT"] then
			Debug( "friend mul-fronts mod=", targetFriendFronts * params["FRIEND_BELLIGERENT"] )
			value = value + targetFriendFronts * params["FRIEND_BELLIGERENT"]
		end
	end
	
	if params["SELF_MULTIPLE_FRONTS"] and params["SELF_MULTIPLE_FRONTS"] ~= 0 then
		if not groupEnemyRelations or not groupFriendFronts then
			groupEnemyRelations, groupFriendFronts = group:GetBelligerentStatus( nil )
		end		
		if params["SELF_MULTIPLE_FRONTS"] then
			Debug( "self mul-fronts mod=", #groupEnemyRelations * params["SELF_MULTIPLE_FRONTS"] )
			value = value + #groupEnemyRelations * params["SELF_MULTIPLE_FRONTS"]
		end
	end	
	
	return value
end

function GroupRelation:GetDipomacyMethodProb( action, group, target )
	local value = GetDiplomacyMethodValue( action, self.type )	
	value = value + self:GetDiplomacyMethodProbMod( action, group, target )
	local prob1 = math.max( 0, value * GroupRelationParam.EVALUATION_RANGE ) + self.evaluation
	local prob2 = math.floor( CalcPowerProb( group, target ) * GroupRelationParam.METHOD_MOD[action].POWER_MODULUS )
	if debugProb then
		--print( "prob=", prob1, prob2 )
	end
	return prob1 + prob2
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
	prob = prob - GroupRelationParam.MAKE_PEACE_DAYS_STANDARD		
	local trait = self:GetTrait( GroupRelationTrait.BELLIGERENT_DURATION )	
	if trait then
		prob = prob + trait.value * GroupRelationParam.MAKE_PEACE_DAYS_POW_MODULUS
	end	
	return prob
end

function GroupRelation:EvalThreatenProb( chara, group, target )
	return self:GetDipomacyMethodProb( "THREATEN", group, target )
end

function GroupRelation:EvalSurrenderProb( chara, group, target )
	return self:GetDipomacyMethodProb( "SURRENDER", group, target )
end

function GroupRelation:EvalDeclareWarProb( chara, group, target )
	local action = "DECLARE_WAR"
	local prob = self:GetDipomacyMethodProb( action, group, target )
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
		or self:GetTrait( GroupRelationTrait.OLD_ENEMY, group.id, target.id )
		or self.evaluation >= GroupRelationParam.EVALUATION_RANGE * 0.9 then
			return false
		end
	elseif method == DiplomacyMethod.THREATEN then
		if group:IsDependence()
		or group:IsVassal()
		or self:GetTrait( GroupRelationTrait.OLD_ENEMY, group.id, target.id ) then
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
		and not self:GetTrait( GroupRelationTrait.OLD_ENEMY, group.id, targetId ) then
			return true
		end
		return false
	elseif method == DiplomacyMethod.DECLARE_WAR then
		if group:IsVassal()
		or self.type == GroupRelationType.BELLIGERENT
		or self.type == GroupRelationType.TRUCE
		or self.type == GroupRelationType.ALLIANCE
		or self.type == GroupRelationType.DEPENDENCE
		or self.type == GroupRelationType.VASSAL then
			return false
		end
	elseif method == DiplomacyMethod.MAKE_PEACE then
		if self.type == GroupRelationType.BELLIGERENT then
			return true
		end
		return false
	elseif method == DiplomacyMethod.BREAK_CONTRACT then
		if self.type == GroupRelationType.BELLIGERENT
		or self.type == GroupRelationType.ENEMY
		or self.type == GroupRelationType.HOSTILITY
		or self.type == GroupRelationType.NEUTRAL		
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
		self.value = GroupRelationParam.STANDARD_EVALUATION
		self:RemoveTrait( GroupRelationTrait.HOSTILITY, 1 )
		Debug_Normal( "[DIPLOMACY] " .. "Improve relation type=" .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
	else
		Debug_Normal( "[DIPLOMACY] " .. "Improve relation evaluation=" .. self.evaluation )
	end
end

function GroupRelation:Deteriorate( delta )
	self.evaluation = MathUtility_Clamp( self.evaluation - delta, GroupRelationParam.MIN_EVALUATION, GroupRelationParam.MAX_EVALUATION )
	if self.evaluation <= GroupRelationParam.MIN_EVALUATION then
		if self.type == GroupRelationType.NEUTRAL then
			self.type = GroupRelationType.HOSTILITY
		elseif self.type == GroupRelationType.FRIEND then
			self.type = GroupRelationType.NEUTRAL
		end
		self.value = GroupRelationParam.STANDARD_EVALUATION
		Debug_Normal( "[DIPLOMACY] " .. "Deteriorate relation type=" .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
	else
		Debug_Normal( "[DIPLOMACY] " .. "Deteriorate relation evaluation=" .. self.evaluation )
	end
end

function GroupRelation:Threaten( group, chara )	
	local target = self:GetOppGroup( group.id )
	local prob = self:EvalThreatenProb( chara, group, target )
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Threaten" )
	if value <= prob then
		local relationType = GroupRelationType.DEPENDENCE
		if self.type == GroupRelationType.DEPENDENCE then
			relationType = GroupRelationType.VASSAL
		end
		self.sid = group.id
		self.tid = target.id
		self._sourceGroup = g_groupDataMng:GetData( self.sid )
		self._targetGroup = g_groupDataMng:GetData( self.tid )
		self.type = relationType
		self.evaluation = math.floor( self.evaluation * 0.5 )
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " threaten " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
	else	
		if self.type == GroupRelationType.HOSTILITY then		
			self:AppendTrait( GroupRelationTrait.CASUS_BELLI, group.id, 3, GroupRelationParam.MAX_TRAIT_VALUE[GroupRelationTrait.CASUS_BELLI] )
		elseif self.type == GroupRelationType.NEUTRAL then
			self:AppendTrait( GroupRelationTrait.CASUS_BELLI, group.id, 2, GroupRelationParam.MAX_TRAIT_VALUE[GroupRelationTrait.CASUS_BELLI] )
		elseif self.type == GroupRelationType.FRIEND then
			self:AppendTrait( GroupRelationTrait.CASUS_BELLI, group.id, 1, GroupRelationParam.MAX_TRAIT_VALUE[GroupRelationTrait.CASUS_BELLI] )
		end
		self:Deteriorate( GroupRelationParam.EVALUATION_RANGE * GroupRelationParam.THREATEN_DETERIORATE_RATIO )
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to threaten " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )
	end	
end

function GroupRelation:Ally( group, chara )	
	local target = self:GetOppGroup( group.id )
	local prob = self:EvalAllyProb( chara, group, target )
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Ally" )
	if value <= prob then
		self.type = GroupRelationType.ALLIANCE		
		self.evaluation = math.floor( self.evaluation * 0.5 )
		self:AppendTrait( GroupRelationTrait.ALLIANCE_TIME_REMAINS, GroupRelationParam.DEFAULT_ALLIANCE_DAY )
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " ally relationship with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
	else
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to ally with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )
	end
end

function GroupRelation:MakePeace( group, chara )
	local target = self:GetOppGroup( group.id )
	local prob = self:EvalMakePeaceProb( chara, group, target )
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Make peace" )
	if value <= prob then
		self.type = GroupRelationType.TRUCE
		self:AppendTrait( GroupRelationTrait.TRUCE_TIME_REMAINS, GroupRelationParam.DEFAULT_TRUCE_DAY )
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " make peace with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
	else
		self:AppendTrait( GroupRelationTrait.DECLINATURE, group.id, 1, GroupRelationParam.MAX_TRAIT_VALUE[GroupRelationTrait.DECLINATURE] )
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to make peace with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )
	end
end

function GroupRelation:EndTruce()
	if self.type == GroupRelationType.TRUCE then
		self.type = GroupRelationType.ENEMY
	end
end

function GroupRelation:EndAlliance()
	if self.type == GroupRelationType.ALLIANCE then
		self.type = GroupRelationType.FRIEND
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
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " surrender to " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. value .. "/" .. prob )
	else
		self:AppendTrait( GroupRelationTrait.DECLINATURE, group.id, 1, GroupRelationParam.MAX_TRAIT_VALUE[GroupRelationTrait.DECLINATURE] )
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to surrender to " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )
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
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " improve relationship with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) )
	else
		self:AppendTrait( GroupRelationTrait.DECLINATURE, group.id, 1, GroupRelationParam.MAX_TRAIT_VALUE[GroupRelationTrait.DECLINATURE] )
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " failed to improve relationship with " .. NameIDToString( target ) .. "("..target:GetPower()..")" .. " in " .. MathUtility_FindEnumName( GroupRelationType, self.type ) .. " prob=" .. prob )
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
		return
	end
	self:AppendTrait( GroupRelationTrait.BETRAYER, group.id, value, GroupRelationParam.MAX_TRAIT_VALUE[GroupRelationTrait.BETRAYER] )
	target:AppendTag( GroupTag.BETRAYER, value, GroupRelationParam.MAX_TAG_VALUE[GroupTag.BETRAYER] )
	self.evaluation = GroupRelationParam.MIN_EVALUATION
	Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " break contract with " .. NameIDToString( target ) .. "("..target:GetPower()..")" )
end

function GroupRelation:DeclareWar( group, chara )
	local target = self:GetOppGroup( group.id )
	if self.type == GroupRelationType.ALLIANCE then
		--dismiss alliance contract
		self.type = GroupRelationType.NEUTRAL
		self.evaluation = self.evaluation * 0.5
		self:AppendTrait( GroupRelationTrait.HOSTILITY, 1 )
		Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " dismiss alliance with " .. NameIDToString( target ) .. "("..target:GetPower()..")" )
		return
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
		return
	end	
	local trait = self:GetTrait( GroupRelationTrait.CASUS_BELLI )
	if trait then
		value = value - trait.value
		trait.value = 0
	end
	if value > 0 then
		group:AppendTag( GroupTag.MILITANT, value, GroupRelationParam.MAX_TAG_VALUE[GroupTag.MILITANT] )
	end
	self:AppendTrait( GroupRelationTrait.HOSTILITY, 1 )
	self.type = GroupRelationType.BELLIGERENT
	self.evaluation = GroupRelationParam.MIN_EVALUATION
	Debug_Normal( "[DIPLOMACY] " .. NameIDToString( group ) .. "("..group:GetPower()..")" .. " declare war at " .. NameIDToString( target ) .. "("..target:GetPower()..")" )
	
	--check alliance
	for k, relation in ipairs( target.relations ) do
		if relation.type == GroupRelationType.ALLIANCE then
			local relation2 = group:GetGroupRelation( relation.sid == target.id and relation.tid or relation.sid )
			--no diplomatic
			relation2:DeclareWar( group, nil )
		elseif relation:IsDependency() then
			local relation2 = group:GetGroupRelation( relation.sid == target.id and relation.tid or relation.sid )
			relation2:DeclareWar( group, nil )
		end
		
	end
end

function GroupRelation:ExecuteMethod( method, group, chara )
	--print( "execute diplomacy method", MathUtility_FindEnumName( DiplomacyMethod, method ) )
	if method == DiplomacyMethod.NONE then
		self:Deteriorate( GroupRelationParam.LEAVE_DETERIORATE )
	elseif method == DiplomacyMethod.FRIENDLY then	
		self:Friendly( group, chara )
	elseif method == DiplomacyMethod.THREATEN then
		self:Threaten( group, chara )
	elseif method == DiplomacyMethod.ALLY then
		self:Ally( group, chara )
	elseif method == DiplomacyMethod.DECLARE_WAR then
		self:DeclareWar( group, chara )
	elseif method == DiplomacyMethod.MAKE_PEACE then
		self:MakePeace( group, chara )
	elseif method == DiplomacyMethod.BREAK_CONTRACT then
		self:BreakContract( group, chara )
	elseif method == DiplomacyMethod.SURRENDER then
		self:Surrender( group, chara )
	end
end

function GroupRelation:RemoveTrait( traitType, groupId, value )
	for k, trait in ipairs( self.traits ) do
		if trait.type == traitType and ( not groupId or trait.groupId == 0 or trait.id == groupId ) then
			if value then
				if trait.value and trait.value > value then
					trait.value = trait.value - value
				else
					table.remove( self.traits, k )
				end
			end
			return
		end
	end
end

function GroupRelation:AppendTrait( traitType, groupId, value, range )
	for k, trait in ipairs( self.traits ) do
		if trait.type == traitType and ( not groupId or trait.groupId == 0 or trait.id == groupId ) then
			if value then
				if not range or trait.value <= range - value then
					trait.value = trait.value + value
				end
			end
			return
		end
	end
	table.insert( self.traits, { type = traitType, id = groupId or 0, value = value or 0 } )
end	