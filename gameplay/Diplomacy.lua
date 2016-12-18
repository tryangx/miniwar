--[[
	Relationship will change by the trait / circumstance / event with time passed.

	1. Goal Affect
	
	2. Power Affect
		
	3. Event Affect
	
	4. 
]]

Diplomacy = class()

function Diplomacy:Update()
	self:UpdateGoalAffect()
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
				elseif value < 0 then
					relation:Deteriorate( value * GroupRelationParam.EVALUATION_RANGE )
				end
				print( "goal " .. source.name .. "+" .. sourceGoal .. " vs " .. target.name .. "+" .. targetGoal )
			end
		end
	end )
	InputUtility_Pause( "" )
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