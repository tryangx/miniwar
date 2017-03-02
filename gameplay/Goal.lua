local function AchievedGroupShortTermGoal( group, goal )
	--Bonus
	group:AppendAsset( GroupTag.REPUTATION, 10 )
	--Character Loyality
	
	MathUtility_Remove( group.goals, goal )
end

local function MeetGroupFinalGoal( group, goal, curDate, value )
	if value >= goal.target then
		if not goal.time or goal.time == 0 then
			goal.time = curDate
		elseif not goal.duration or g_calendar:CalcDiffDay( goal.time ) >= goal.duration then
			return true
		end
	else
		goal.time = nil
	end
	return false
end

local function MeetGroupShortTermGoal( group, goal, curDate, achieved )
	if achieved then
		if not goal.time or goal.time == 0 then
			goal.time = curDate
		elseif not goal.duration or g_calendar:CalcDiffDay( goal.time ) > goal.target then
			AchievedGroupShortTermGoal( group, goal )
		end
	else
		goal.time = nil
	end
end

---------------------------


function SetGroupShortTermGoal( group, goal )
	local goalList = {}
	for k, goal in ipairs( group.goals ) do
		if goal.type < GroupGoal.SHORT_TERM_GOAL then
			table.insert( goalList, goal )
		end
	end
	goal.time = g_calendar:GetDateValue()
	table.insert( goalList, goal )
end

function CancelGroupShortTermGoal( group )
	local shortTermGoal = nil
	for k, goal in ipairs( group.goals ) do
		if goal.type >= GroupGoal.SHORT_TERM_GOAL then
			shortTermGoal = goal
			break
		end
	end
	if shortTermGoal then
		--decrease reputation 10
		group:RemoveAsset( GroupTag.REPUTATION, 10 )
	end
end

function HaveAchievedGroupFinalGoal( group )	
	--if 1 then return false end
	--if #group.goals == 0 then return #group.cities == g_cityDataMng:GetCount() end	
	local AchievedFinalGoal = false
	local curDate = g_calendar:GetDateValue()
	for k, goal in ipairs( group.goals ) do		
		--Final goal
		if goal.type == GroupGoal.DOMINATION_TERRIORITY then
			local number, rate = group:GetTerritoryRate()			
			AchievedFinalGoal = MeetGroupFinalGoal( group, goal, curDate, rate )
			if AchievedFinalGoal then
				InputUtility_Pause( group.name .. " DOMINATION_TERRIORITY=" .. number .. "+" .. rate .. "%", " Goal=" .. ( goal.target or 0 ) .. "+" .. ( goal.rate or 0 ) .. "%" )
			end
			
		elseif goal.type == GroupGoal.DOMINATION_CITY then
			local number, rate = group:GetTerritoryRate()			
			AchievedFinalGoal = MeetGroupFinalGoal( group, goal, curDate, number )
			if AchievedFinalGoal then
				InputUtility_Pause( group.name .. " DOMINATION_CITY=" .. number .. "+" .. rate .. "%", " Goal=" .. ( goal.target or 0 ) .. "+" .. ( goal.rate or 0 ) .. "%" )
			end
			
		elseif goal.type == GroupGoal.POWER_LEADING then
			local power, rate = group:GetDominationRate()			
			AchievedFinalGoal = MeetGroupFinalGoal( group, goal, curDate, rate )
			if AchievedFinalGoal then
				InputUtility_Pause( group.name .. " POWER_LEADING=" .. power .. "+" .. rate .. "%" .. " Goal=" .. ( goal.target or 0 ) .. "+" .. ( goal.rate or 0 ) .. "%" )
			end
		
		--Short term goal
		elseif goal.type == GroupGoal.SURVIVIVAL then
			MeetGroupShortTermGoal( group, goal, curDate, not group:IsFallen() )
		elseif goal.type == GroupGoal.INDEPENDENCE then
			MeetGroupShortTermGoal( group, goal, curDate, group:IsDependence() )
		elseif goal.type == GroupGoal.OCCUPY_CITY then
			MeetGroupShortTermGoal( group, goal, curDate, group:IsOwnCity( goal.target ) )		
		end
	--[[
		if goal.type == GroupGoal.SURVIVE then
			if not goal.startTime then
				goal.startTime = g_calendar:GetDateValue()
				return false
			elseif not goal.value or g_calendar:CalcDiffDay( goal.startTime ) < goal.value then
				return false
			end
			return false
		elseif goal.type == GroupGoal.INDEPENDENT then
			if not goal.startTime or self:IsDependence() then
				goal.startTime = g_calendar:GetDateValue()
				return false
			elseif not goal.value or g_calendar:CalcDiffDay( goal.startTime ) < goal.value then
				return false
			end
			return false
			
		--Domination
		elseif goal.type == GroupGoal.OCCUPY then
			if not goal.value or not self:IsOwnCity( goal.value ) then return false end			
		elseif goal.type == GroupGoal.CONQUER then
			
		
		--Leading
		elseif goal.type == GroupGoal.MILITARY_POWER then
			local power, rate = self:GetDominationRate()
			ShowText( group.name .. " domination=" .. power .. "+" .. rate .. "%" .. " Goal=" .. ( goal.value or 0 ) .. "+" .. ( goal.rate or 0 ) .. "%" )
			if not goal.value or not goal.rate or power < goal.value or rate < goal.rate then return false end
		end
		ShowText( "match goal=".. MathUtility_FindEnumName( GroupGoal, goal.type ) )
		]]
	end
	return AchievedFinalGoal
end