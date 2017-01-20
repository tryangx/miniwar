--[[
	Relationship will change by the trait / circumstance / event with time passed.

	1. Goal Affect
	
	2. Power Affect
		
	3. Event Affect
	
	4. 
]]

Diplomacy = class()

function Diplomacy:__init()
	self.mng = nil
end

function Diplomacy:DumpResult()
	g_groupRelationDataMng:Foreach( function ( relation )
		local source = relation._sourceGroup
		local target = relation._targetGroup
		if source and target then
			ShowText( source.name .. "--" .. target.name .. " " .. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " ev=" .. relation.evaluation )
			for k, record in ipairs( relation.records ) do
				ShowText( "", record )
			end
		end
	end )
end

function Diplomacy:Dump()
	--if 1 then return end
	g_groupRelationDataMng:Foreach( function ( relation )
		local source = relation._sourceGroup
		local target = relation._targetGroup
		if source and target then
			ShowText( source.name .. "--" .. target.name .. " " .. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " ev=" .. relation.evaluation )
		end
	end )
end

function Diplomacy:GetGroupGoal( group )
	if group:HasGoal( GroupGoal.SURVIVAL_GOAL_BEG, GroupGoal.SURVIVAL_GOAL_END ) then return "SURVIVAL_GOAL" end
	if group:HasGoal( GroupGoal.DOMINATION_GOAL_BEG, GroupGoal.DOMINATION_GOAL_END ) then return "DOMINATION_GOAL" end
	if group:HasGoal( GroupGoal.LEADING_GOAL_BEG, GroupGoal.LEADING_GOAL_END ) then return "LEADING_GOAL" end
	return "NONE"
end

function Diplomacy:UpdateAffect( elapsedTime, relation )
	local source = relation._sourceGroup
	local target = relation._targetGroup
	if source and target then
		local value = 0
		--[[
		--Adjacent Group affect by Goals
		if source:IsAdjacentGroup( target ) then
			local sourceGoal = self:GetGroupGoal( source )
			local targetGoal = self:GetGroupGoal( target )
			if sourceGoal and targetGoal then
				value = value + GroupGoalDiplomacyEffect[sourceGoal][targetGoal] * GroupRelationParam.EVALUATION_RANGE
				--InputUtility_Pause( "goal " .. source.name .. "+" .. sourceGoal .. " vs " .. target.name .. "+" .. targetGoal )
			end
		end
		]]
		--Current relation affect
		
		local powerBalance = relation:CalcBalance()
		local gap = math.abs( powerBalance - relation.powerBalance )
		if gap > 0 then
			gap = MathUtility_Clamp( gap * 0.8, 0, 0.2 )
			--print( powerBalance, relation.powerBalance )
			--print( source.name .. " vs " .. target.name, "powerBalance=", gap,  math.ceil( gap * GroupRelationParam.EVALUATION_RANGE ) )
			--InputUtility_Pause()
		end
		relation.powerBalance = powerBalance
		value = value - math.ceil( gap * GroupRelationParam.EVALUATION_RANGE )
		
		value = value + GroupRelationDiplomacyEffect[relation.type] * GroupRelationParam.EVALUATION_RANGE		
		
		if value > 0 then
			relation:Improve( value )
			--ShowText( "improve", source.name, target.name )
		elseif value < 0 then
			--in order to accelerate gamespeed
			--[[
			if g_statistic.numOfIndependenceGroup < 2 then
				value = value * 8
			elseif g_statistic.numOfIndependenceGroup < 4 then
				value = value * 4
			elseif g_statistic.numOfIndependenceGroup < 8 then
				value = value * 3
			end
			]]
			relation:Deteriorate( math.abs( value ) )
			--ShowText( "deteriorate", source.name, target.name )
		end
		--print( source.name .." v " .. target.name .. " " .. ( value > 0 and "+" .. value or value ) .. ">>>" .. relation.evaluation, GroupRelationDiplomacyEffect[relation.type], MathUtility_FindEnumName( GroupRelationType, relation.type ) )
	end
end

function Diplomacy:UpdateContract( elapsedTime, relation )
	if relation.type == GroupRelationType.ALLIANCE then
		local detail = relation:GetDetail( GroupRelationDetail.ALLIANCE_TIME_REMAINS )
		if detail then
			if detail.value > elapsedTime then
				detail.value = detail.value - elapsedTime
				return
			end
		end
		relation:EndAlliance()
	elseif relation.type == GroupRelationType.TRUCE then		
		local detail = relation:GetDetail( GroupRelationDetail.TRUCE_TIME_REMAINS )
		if detail then
			if detail.value > elapsedTime then
				detail.value = detail.value - elapsedTime
				return
			end
		end		
		relation:EndTruce()
	elseif relation.type == GroupRelationType.BELLIGERENT then		
		relation:AppendDetail( GroupRelationDetail.BELLIGERENT_DURATION, nil, elapsedTime )
	end	
end

function Diplomacy:Update( elapsedTime )
	self:Dump()
	g_groupRelationDataMng:Foreach( function ( relation )
		self:UpdateContract( elapsedTime, relation )		
		self:UpdateAffect( elapsedTime, relation )
	end )
	--InputUtility_Pause()
end

function Diplomacy:GetRelation( id )
	return g_groupRelationDataMng:GetData( id )
end

function Diplomacy:CreateRelation( sid, tid )
	local relation = g_groupRelationDataMng:NewData()
	relation.sid = self.id
	relation.tid = id
	relation:ConvertID2Data()
	return relation
end

function Diplomacy:UpdateEventAffect()

end

function Diplomacy:RemoveGroupRelation( group )
	local removeList = {}
	g_groupRelationDataMng:RemoveDataByCondition( function ( relation )
		return relation.sid == group.id or relation.tid == group.id
	end )
end