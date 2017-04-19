function GetGroupShortTermGoal( group, type )
	if not group then return nil end
	for k, existGoal in ipairs( group.goals ) do
		if existGoal.type >= GroupGoal.SHORT_TERM_GOAL and ( not type or type == existGoal.type ) then
			return existGoal
		end
	end
	return nil
end

function GetGroupShortTermGoalWithCity( group, tarCity )	
	local goal = GetGroupShortTermGoal( group )
	if not goal then return false end
	if goal.type ~= GroupGoal.OCCUPY_CITY then return false end
	if goal.target ~= tarCity.id then return false end
	return true
end

function SetGroupShortTermGoal( group, data )
	if GetGroupShortTermGoal( group ) then return end

	local goal    = {}
	goal.type     = data.type
	goal.target   = data.target
	goal.timeout  = data.timeout
	goal.duration = data.duration

	--print( "goal=", goal.timeout, goal.duration )

	goal.time = g_calendar:GetDateValue()
	table.insert( group.goals, goal )

	g_statistic:TrackGroup( NameIDToString( group ) .. "set goal="..CreateGoalDesc( goal ), group )
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
		MathUtility_Remove( group.goals, shortTermGoal )
		group:RemoveAsset( GroupTag.REPUTATION, 10 )
		--g_statistic:TrackGroup( NameIDToString( group ) .. "cancel goal="..CreateGoalDesc( shortTermGoal ), group )
	end
end

local function AchievedGroupShortTermGoal( group, goal )
	--Bonus
	group:AppendAsset( GroupTag.REPUTATION, 10 )	
	--Character Loyality
	
	--Clear Data
	MathUtility_Remove( group.goals, goal )

	g_statistic:TrackGroup( NameIDToString( group ) .. " achieve goal="..CreateGoalDesc( goal ), group )
end

local function MeetGroupFinalGoal( group, goal, curDate, achieved )	
	if achieved then
		if not goal.time or goal.time == 0 then
			goal.time = curDate
		elseif goal.duration then
 			return g_calendar:CalcDiffDayByDate( goal.time ) >= goal.duration
		elseif goal.timeout then
			return g_calendar:CalcDiffDayByDate( goal.time ) < goal.timeout
		end
	elseif goal.duration then
		goal.time = nil
	end
	return false
end

local function MeetGroupShortTermGoal( group, goal, curDate, achieved )
	if achieved then
		if not goal.time or goal.time == 0 then
			goal.time = curDate
		elseif goal.duration then
			if g_calendar:CalcDiffDayByDate( goal.time ) >= goal.duration then
				AchievedGroupShortTermGoal( group, goal )
			end
		elseif goal.timeout then			
 			if g_calendar:CalcDiffDayByDate( goal.time ) < goal.timeout then
 				AchievedGroupShortTermGoal( group, goal )
 			end
		end
	else
		if g_calendar:CalcDiffDayByDate( goal.time ) >= ( goal.timeout or 360 ) then
			--print( "need cancel", g_calendar:CalcDiffDayByDate( goal.time ), goal.timeout )
			CancelGroupShortTermGoal( group )
		end
		if goal.duration then
			goal.time = nil
		end
	end
end

---------------------------

function HaveAchievedGroupFinalGoal( group )	
	--if 1 then return false end
	--if #group.goals == 0 then return #group.cities == g_cityDataMng:GetCount() end	
	local AchievedFinalGoal = false
	local curDate = g_calendar:GetDateValue()
	for k, goal in ipairs( group.goals ) do		
		--Final goal
		if goal.type == GroupGoal.DOMINATION_TERRIORITY then
			local number, rate = group:GetTerritoryRate()			
			AchievedFinalGoal = MeetGroupFinalGoal( group, goal, curDate, rate >= goal.target )
			if AchievedFinalGoal then
				InputUtility_Pause( group.name .. " DOMINATION_TERRIORITY=" .. number .. "+" .. rate .. "%", " Goal=" .. ( goal.target or 0 ) .. "+" .. ( goal.rate or 0 ) .. "%" )
			end
			
		elseif goal.type == GroupGoal.DOMINATION_CITY then
			local number, rate = group:GetTerritoryRate()			
			AchievedFinalGoal = MeetGroupFinalGoal( group, goal, curDate, number >= goal.target )
			if AchievedFinalGoal then
				InputUtility_Pause( group.name .. " DOMINATION_CITY=" .. number .. "+" .. rate .. "%", " Goal=" .. ( goal.target or 0 ) .. "+" .. ( goal.rate or 0 ) .. "%" )
			end
			
		elseif goal.type == GroupGoal.POWER_LEADING then
			local power, rate = group:GetDominationRate()			
			AchievedFinalGoal = MeetGroupFinalGoal( group, goal, curDate, rate >= goal.target )
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

		elseif goal.type == GroupGoal.DEFEND_CITY then
			MeetGroupShortTermGoal( group, goal, curDate, group:IsOwnCity( goal.target ) )

		end
	end
	return AchievedFinalGoal
end

function CreateGoalDesc( goal )
	local content = ""
	content = content .. MathUtility_FindEnumName( GroupGoal, goal.type )
	content = content .. " Tar=" .. goal.target

	if goal.type == GroupGoal.DOMINATION_TERRIORITY then		
	elseif goal.type == GroupGoal.DOMINATION_CITY then
	elseif goal.type == GroupGoal.POWER_LEADING then	
	--------------------------
	-- Short term goal
	elseif goal.type == GroupGoal.SHORT_TERM_GOAL then
	--
	elseif goal.type == GroupGoal.SURVIVIVAL then
	--
	elseif goal.type == GroupGoal.INDEPENDENCE then
	--Control special city
	elseif goal.type == GroupGoal.OCCUPY_CITY then
		local city = g_cityDataMng:GetData( goal.target )
		content = content .. NameIDToString( city ) .. "=" .. ( city:GetGroup() and city:GetGroup().name or "NEUTRAL" )
	elseif goal.type == GroupGoal.DEFEND_CITY then
		local city = g_cityDataMng:GetData( goal.target )
		content = content .. NameIDToString( city ) .. "=" .. ( city:GetGroup() and city:GetGroup().name or "NEUTRAL" )
	end	
	
	if goal.timeout then
		content = content .. " TimeOut=" .. goal.timeout
	end
	if goal.duration then
		content = content .. " Duration=" .. goal.duration
	end
	return content
end
