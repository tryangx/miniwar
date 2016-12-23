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

function Diplomacy:Update()
	self:Dump()
	self:UpdateGoalAffect()
	self:UpdateRelation()
end

function Diplomacy:GetRelation( id )
	--to refactor
end

function Diplomacy:UpdateRelation()
	g_groupRelationDataMng:Foreach( function ( relation )
		if relation.type == GroupRelationType.ALLIANCE then
			local trait = relation:GetTrait( GroupRelationTrait.ALLIANCE_TIME_REMAINS )
			if trait then				
				if trait.value > passDay then
					trait.value = trait.value - passDay
					return
				end
			end
			relation:EndAlliance()
		elseif relation.type == GroupRelationType.TRUCE then
			local trait = relation:GetTrait( GroupRelationTrait.TRUCE_TIME_REMAINS )
			if trait then				
				if trait.value > passDay then
					trait.value = trait.value - passDay
					return
				end
			end
			relation:EndTruce()
		end
	end )
end

function Diplomacy:UpdateGoalAffect()
	function GetGroupGoal( group )
		if group:HasGoal( GroupGoal.SURVIVAL_BEG, GroupGoal.SURVIVAL_END ) then return "SURVIVAL_GOAL" end
		if group:HasGoal( GroupGoal.DOMINATION_BEG, GroupGoal.DOMINATION_END ) then return "DOMINATION_GOAL" end
		if group:HasGoal( GroupGoal.LEADING_GOAL_BEG, GroupGoal.LEADING_GOAL_END ) then return "LEADING_GOAL" end
		return "NONE"
	end
	g_groupRelationDataMng:Foreach( function ( relation )
		local source = relation._sourceGroup
		local target = relation._targetGroup
		if source and target then
			local sourceGoal = GetGroupGoal( source )
			local targetGoal = GetGroupGoal( target )
			if sourceGoal and targetGoal then				
				local value = GroupGoalDiplomacyEffect[sourceGoal][targetGoal]
				if value > 0 then
					relation:Improve( value * GroupRelationParam.EVALUATION_RANGE )
					--print( "improve", source.name, target.name )
				elseif value < 0 then
					relation:Deteriorate( math.abs( value ) * GroupRelationParam.EVALUATION_RANGE )
					--print( "deteriorate", source.name, target.name )
				end
				--print( "goal " .. source.name .. "+" .. sourceGoal .. " vs " .. target.name .. "+" .. targetGoal )
			end
		end
	end )
	--InputUtility_Pause( "" )
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