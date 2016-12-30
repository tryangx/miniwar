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

function Diplomacy:Dump()
	g_groupRelationDataMng:Foreach( function ( relation )
		local source = relation._sourceGroup
		local target = relation._targetGroup
		if source and target then
			print( source.name .. "--" .. target.name .. " " .. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. " ev=" .. relation.evaluation )
		end
	end )
end

function Diplomacy:GetGroupGoal( group )
	if group:HasGoal( GroupGoal.SURVIVAL_BEG, GroupGoal.SURVIVAL_END ) then return "SURVIVAL_GOAL" end
	if group:HasGoal( GroupGoal.DOMINATION_BEG, GroupGoal.DOMINATION_END ) then return "DOMINATION_GOAL" end
	if group:HasGoal( GroupGoal.LEADING_GOAL_BEG, GroupGoal.LEADING_GOAL_END ) then return "LEADING_GOAL" end
	return "NONE"
end

function Diplomacy:UpdateContract( relation )
	if relation.type == GroupRelationType.ALLIANCE then
		local trait = relation:GetDetail( GroupRelationDetail.ALLIANCE_TIME_REMAINS )
		if trait then				
			if trait.value > passDay then
				trait.value = trait.value - passDay
				return
			end
		end
		relation:EndAlliance()
	elseif relation.type == GroupRelationType.TRUCE then
		local trait = relation:GetDetail( GroupRelationDetail.TRUCE_TIME_REMAINS )
		if trait then				
			if trait.value > passDay then
				trait.value = trait.value - passDay
				return
			end
		end
		relation:EndTruce()
	end
end

function Diplomacy:UpdateGoalAffect( relation )
	local source = relation._sourceGroup
	local target = relation._targetGroup
	if source and target then
		local sourceGoal = self:GetGroupGoal( source )
		local targetGoal = self:GetGroupGoal( target )
		if sourceGoal and targetGoal then
			local value = GroupGoalDiplomacyEffect[sourceGoal][targetGoal] * GroupRelationParam.EVALUATION_RANGE
			if value > 0 then
				relation:Improve( value )
				print( "improve", source.name, target.name )
			elseif value < 0 then
				--in order to accelerate gamespeed
				if g_numOfIndependenceGroup < 2 then
					value = value * 4
				elseif g_numOfIndependenceGroup < 4 then
					value = value * 2
				elseif g_numOfIndependenceGroup < 8 then
					value = value * 1.5
				end
				relation:Deteriorate( math.abs( value ) )
				print( "deteriorate", source.name, target.name )
			end
			--print( "goal " .. source.name .. "+" .. sourceGoal .. " vs " .. target.name .. "+" .. targetGoal )
		end
	end
end

function Diplomacy:Update()
	self:Dump()
	g_groupRelationDataMng:Foreach( function ( relation )
		self:UpdateContract( relation )
		self:UpdateGoalAffect( relation )
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

function Diplomacy:UpdatePowerAffect()
	g_groupRelationDataMng:Foreach( function ( relation )
		local balance = relation:CalcBalance()
		local gap = math.abs( balance - relation.balance )
		if gap ~= 0 then
			relation:Deteriorate( gap * GroupRelationParam.EVALUATION_RANGE )
		end
	end )
end

function Diplomacy:UpdateEventAffect()

end