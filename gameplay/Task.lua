--[[

]]

--local watchTaskType = 122
local focusTaskType = nil-- 143

local TIMEOUT = 180

TaskType =
{
	NONE               = 0,
	
	--------------------
	--Affais
	GROUP_AFFAIS_TASK  = 100, --placeholder
	
	TECH_RESEARCH      = 101,
	
	CITY_INVEST        = 110,
	CITY_LEVY_TAX      = 111,
	CITY_BUILD         = 112,
	CITY_INSTRUCT      = 113,
	CITY_FARM          = 114,
	CITY_PATROL        = 115,
	
	HR_DISPATCH        = 120,
	HR_CALL            = 121,
	HR_HIRE            = 122,
	HR_EXILE           = 123,
	HR_PROMOTE         = 124,
	HR_LOOKFORTALENT   = 127,
	
	RECRUIT_TROOP      = 130,
	LEAD_TROOP         = 131,
	ESTABLISH_CORPS    = 132,	
	REINFORCE_CORPS    = 133,
	REGROUP_CORPS      = 134,
	TRAIN_CORPS        = 135,
	CONSCRIPT_TROOP    = 136,
	
	HARASS_CITY        = 140,
	EXPEDITION         = 141,
	CONTROL_PLOT       = 142,
	DISPATCH_CORPS     = 143,
	SIEGE_CITY         = 144,
	MEET_ATTACK        = 145,
	DISPATCH_TROOPS    = 146,
	DEFEND_CITY        = 147,
	
	--------------------
	--Diplomacy
	DIPLOMACY_AFFAIRS        = 200, --placeholder

	FRIENDLY_DIPLOMACY       = 201,
	THREATEN_DIPLOMACY       = 202,
	ALLY_DIPLOMACY           = 203,
	MAKE_PEACE_DIPLOMACY     = 204,
	DECLARE_WAR_DIPLOMACY    = 205,
	BREAK_CONTRACT_DIPLOMACY = 206,
	SURRENDER_DIPLOMACY      = 207,

	--------------------
	--Personal
	PERSONAL_TASK     = 300, --placeholder
	
	CHARA_BACKHOME    = 301,
	CORPS_MOVETO      = 302,
	TROOP_MOVETO      = 303,
}

TaskCategory =
{
	NORMAL                   = 0,
	MOVING                   = 1,
	CITY_AFFAIRS             = 2,
	WARPAREPAREDNESS_AFFAIRS = 3,
	HR_AFFAIRS               = 4,
	DIPLOMACY_AFFAIRS        = 5,
	MILITARY_AFFAIRS         = 6,
	TECH_AFFAIRS             = 7,
}

TaskStatus = 
{
	NONE        = 0,
	--1st stage, means task is started
	INITIAL   	= 1,
	--2nd stage, means to 
	PREPARED    = 2,
	--3rd stage, means actor is moving to destination
	MOVING      = 3,
	--4th stage, means actor is executing, need time to finish
	EXECUTING   = 4,

	--Task End Status
	SUCCESSED 	= 10,
	FAILED   	= 11,
	SUSPENDED 	= 12,
}

Task = class()

function Task:__init()
	self.id          = 0	
	self.desc        = nil	
	self.type        = TaskType.NONE
	self.category    = TaskCategory.NORMAL
	self.status      = TaskStatus.NONE

	self.contributor = nil
	self.actor       = nil
	self.target      = nil
	self.destination = nil	
	self.datas       = nil

	--Time & Duration
	self.remain      = nil
	self.progress    = nil

	--Date
	self.begDate     = nil
	self.endDate     = nil
end

function Task:Load( data )
end

function Task:Save()
end

function Task:CreateShortBreif()
	local content = "id="..self.id .. " "
	content = content .. MathUtility_FindEnumName( TaskType, self.type )
	content = content .. " act=" .. NameIDToString( self.actor )
	content = content .. " dst=" .. NameIDToString( self.destination )
	content = content .. " tar=" .. NameIDToString( self.target )
	return content
end

function Task:CreateBrief()
	local content = "id="..self.id .. " "
	content = content .. MathUtility_FindEnumName( TaskType, self.type )
	content = content .. " " .. NameIDToString( self.actor )
	content = content .. "-" .. ( self.actor:GetGroup() and self.actor:GetGroup().name or "" )
	content = content .. " loc=" .. self.actor:GetLocation().name
	content = content .. " dst=" .. NameIDToString( self.destination )
	content = content .. " tar=" .. NameIDToString( self.target )
	content = content .. " beg=" .. g_calendar:CreateDateDescByValue( self.begDate, true, true )
	content = content .. " end=" .. g_calendar:CreateDateDescByValue( self.endDate, true, true )
	content = content .. " use=" .. self.progress
	content = content .. " rst=" .. MathUtility_FindEnumName( TaskStatus, self.status )
	content = content .. " rem=" .. self.remain
	return content
end

function Task:IsFinished()
	if self.status ~= TaskStatus.SUCCESSED and self.status ~= TaskStatus.FAILED then
		return false
	end
	return self.remain == 0
end

function Task:IsInvasionTask()
	return self.type == TaskType.SIEGE_CITY or self.type == TaskType.HARASS_CITY or self.type == TaskType.EXPEDITION
end

function Task:IsDefendTask()
	return self.type == TaskType.DEFEND_CITY
end

function Task:Reward( contributor, contribution )
	if contributor then
		contributor:Contribute( math.ceil( CharacterParams.ATTRIBUTE.MAX_CONTRIBUTION * ( contribution or ContributionModulus.NONE ) ) )
	end
end

function Task:MoveOn()
	if not self.path then
		--InputUtility_Pause( self.actor.name, self.actor:GetLocation().name )
		return
	end

	local location = self.path[1]		
	if #self.path <= 1 then
		self.path = nil
		self.remain = 0
		self.actor:MoveToLocation( location )
		if self.status == TaskStatus.MOVING then
			self.status = TaskStatus.PREPARED
		end
	else
		--self.actor:MoveToLocation( location )		
		--self.actor:MoveOn()
		self.actor.location = location
		table.remove( self.path, 1 )
		self.remain = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.path[1] )
		self.status = TaskStatus.MOVING
	end
end

function Task:GotoDestination( destination )
	local location = self.actor:GetLocation()
	if location == destination then
		local actor = g_movingActorMng:HasActor( MovingActorType.CORPS, self.actor )
		--ShowText( "goto destination="..location.name, NameIDToString( self.actor ), " actor=",actor )
		self.actor:MoveToLocation( destination )
		return false
	end
	if not location:IsAdjacentLocation( destination ) then
		self.path = Helper_FindPathBetweenCity( location, destination )
	else
		self.path = { destination }
	end
	if not location:IsAdjacentLocation( destination ) then
		--find way to destination
		--print( self.actor.name, self.actor:GetGroup().name, "goto", MathUtility_FindEnumName( TaskType, self.type ) .. " from " .. location.name .."->"..( destination and destination.name or "" ))
		self.path = Helper_FindPathBetweenCity( location, destination )
		if not self.path then
			InputUtility_Pause( "I don't like teleport, but better than crashed, cann't find path between", ( location and location.name or "unknown" ) .."->".. ( destination and destination.name or "unknown" ) )
			destination = self.actor:GetHome()
		else
			destination = self.path[1]
		end
	else
		self.path = { destination }
	end	
	--ShowText( "BACK HOME", NameIDToString( self.actor ), "goto=" .. destination.name )
	self.remain = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), destination )	
	return true
end

function Task:BackHome()	
	if not self.actor:GetGroup() or self.actor:GetGroup():IsFallen() then
		--InputUtility_Pause( self.actor.name .. " home is fallen" )
		return
	end	
	--Back home
	if self:GotoDestination( self.actor:GetHome() ) then
		self.actor:MoveOn()
	end
end

function Task:Suspend()
	self.status = TaskStatus.SUSPENDED
end

function Task:Continue()
	self.status = TaskStatus.INITIAL--PREPARED
	self:Update( 0 )
end

function Task:Succeed( contribution )
	self.endDate  = g_calendar:GetDateValue()
	self.status = TaskStatus.SUCCESSED	
	self:Reward( self.contributor, contribution )
	self:BackHome()
end

function Task:Finish( contribution )
	self.endDate  = g_calendar:GetDateValue()
	self.status = TaskStatus.SUCCESSED	
	self:Reward( self.contributor, contribution )
end

function Task:Terminate( reason )
	ShowText( self:CreateBrief() .. " Terminate!!! Reason=", reason )--( reason and reason or "none" ) )
	self.endDate  = g_calendar:GetDateValue()
	self.status = TaskStatus.FAILED
	self.remain = 0
end

function Task:Fail()	
	self.status = TaskStatus.FAILED
	self.remain = 0
	
	if self.type == TaskType.RECRUIT_TROOP then
		self.destination:CancelRecruit( QueryRecruitTroopNumber( self.datas ) )
	elseif  self.type == TaskType.REINFORCE_CORPS then
		self.destination:CancelRecruit( self.datas )
	end
	
	--no penalty now
	self:BackHome()
end

function Task:UpdateDiplomacy( method )
	local success = false
	if self.target then
		self.actor:MoveToLocation( self.destination )
		local relation = self.actor:GetGroup():GetGroupRelation( self.target.id )
		if relation then 
			success = true
			relation:ExecuteMethod( method, self.actor:GetGroup(), self.actor )
		else
			ShowText( "relation same" )
			InputUtility_Pause( self:CreateBrief() )			
		end
	end
	if success then
		self:Succeed( ContributionModulus.NORMAL )
	else
		self:Fail()
	end
end

function Task:Update( elapsedTime )
	if not elapsedTime then elapsedTime = 0 end

	--Group Fall	
	if not self.actor:GetGroup() then
		self:Fail()
		return
	end
	
	local elapsed = elapsedTime
	if self.type == TaskType.TECH_RESEARCH then
		elapsed = math.ceil( self.actor:GetGroup():GetResearchAbility() * elapsedTime / GlobalConst.UNIT_TIME )
	elseif self.type == TaskType.CITY_BUILD then
		elapsed = math.ceil( self.destination.production * elapsedTime / GlobalConst.UNIT_TIME )
	elseif self.type == TaskType.RECRUIT_TROOP then
		elapsed = math.ceil( self.destination.production * elapsedTime / GlobalConst.UNIT_TIME )
	end

	if self.status == TaskStatus.EXECUTING then
		return
	end

	if self.status == TaskStatus.SUSPENDED then
		if self.category == TaskCategory.CITY_AFFAIRS then
			if not self.destination:IsInSiege() then
				self.status = TaskStatus.PREPARED
			end
		elseif self.category == TaskCategory.MILITARY_AFFAIRS then
			if not self.destination:IsInSiege() then
				self.status = TaskStatus.PREPARED
			end
		else
			return
		end
	end

	if self.type == watchTaskType then ShowText( "Update task=" .. self.id .. " type="..MathUtility_FindEnumName( TaskType, self.type ), " remain=", self.remain, elapsed ) end

	--preprocess
	if self.status == TaskStatus.PREPARED then
		if self.category == TaskCategory.CITY_AFFAIRS then
			if self.destination:IsInSiege() then
				self:Suspend()
				return
			end
		elseif self.category == TaskCategory.MILITARY_AFFAIRS then
			if not self.destination then
				print( self:CreateBrief() )
			end
			if self.destination:IsInSiege() then
				if self.type == TaskType.DISPATCH_CORPS or self.type == TaskType.DISPATCH_TROOPS then
					--Retreat or field-combat?
					self:Fail()
				elseif not self.destination:IsNeutral() and not g_warfare:IsLocationUnderAttackBy( self.destination, self.actor:GetGroup() ) then
					--Wait until other group finish siege
					self:Suspend()
				end
				return
			end
		end
	end
	
	--predict whether target is invalid likes capital lost, etc.
	if self.remain > elapsed then
		self.progress = self.progress + elapsed	
		self.remain = self.remain - elapsed

		if self.category == TaskCategory.DIPLOMACY_AFFAIRS then
			if self.destination ~= self.target:GetCapital() then
				local oldDestination = self.destination
				self.destination = self.target:GetCapital()
				self.remain = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
				if self.target:IsFallen() then
					self:Fail()
					--InputUtility_Pause( self.target.name, " capital not exist" )
				else
					ShowText( "Capital changed from" .. oldDestination.name .. "->" .. self.destination.name )
				end
			end
		end
		return
	end

	self.remain   = 0
	self.progress = self.progress + self.remain

	--initial
	if self.status == TaskStatus.INITIAL then
		self.status = TaskStatus.PREPARED
		if self.type == TaskType.HARASS_CITY then
			self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		elseif self.type == TaskType.EXPEDITION then
			self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		elseif self.type == CharacterProposal.SIEGE_CITY then
			self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		end
		return
	end
	
	if self.status == TaskStatus.SUCCESSED or self.status == TaskStatus.FAILED or self.status == TaskStatus.MOVING then
		self:MoveOn()
		return
	end

	-- "self.status" equals "TaskStatus.PREPARED" now

	if self.type == watchTaskType then		
		InputUtility_Pause( "Do task=" .. self.id .. " type="..MathUtility_FindEnumName( TaskType, self.type ), " tar=" .. self.target.name, " loc=" .. self.destination.name, " actor=".. self.actor.name )
	end

	if self.type == TaskType.TECH_RESEARCH then
		InventTech( self.actor:GetGroup(), self.target )
		self:Succeed( ContributionModulus.NORMAL )
	elseif self.type == TaskType.CITY_BUILD then
		CityBuildConstruction( self.destination, self.target )
		self:Succeed( ContributionModulus.NORMAL )
	elseif self.type == TaskType.CITY_INVEST then
		CityInvest( self.destination )
		self:Succeed( ContributionModulus.NORMAL )
	elseif self.type == TaskType.CITY_FARM then
		CityFarm( self.destination )
		self:Succeed( ContributionModulus.NORMAL )
	elseif self.type == TaskType.CITY_PATROL then
		CityPatrol( self.destination )
		self:Succeed( ContributionModulus.NORMAL )
	elseif self.type == TaskType.CITY_LEVY_TAX then
		CityLevyTax( self.destination )
		self:Succeed( ContributionModulus.NORMAL )	
	elseif self.type == TaskType.CITY_INSTRUCT then
		CityInstruct( self.destination, self.datas )
		self:Succeed( ContributionModulus.NORMAL )
	
	elseif self.type == TaskType.HR_DISPATCH then
		CharaDispatchToCity( self.target, self.destination )
		self:Succeed( ContributionModulus.LITTLE )
	elseif self.type == TaskType.HR_CALL then		
		CharaDispatchToCity( self.target, self.destination )
		self:Succeed( ContributionModulus.LITTLE )
	elseif self.type == TaskType.HR_HIRE then
		if CharaHired( self.target, self.destination ) then
			self:Succeed( ContributionModulus.LESS )
		else
			self:Fail()
		end
	elseif self.type == TaskType.HR_EXILE then
		CharaExile( self.target, self.destination )
		self:Succeed( ContributionModulus.FEW )
	elseif self.type == TaskType.HR_PROMOTE then
		CharaPromote( self.target, self.destination )
		self:Succeed( ContributionModulus.FEW )
	elseif self.type == TaskType.HR_LOOKFORTALENT then
		if CharaLookforTalent( self.destination ) then
			self:Succeed( ContributionModulus.NORMAL )
		else
			self:Fail( ContributionModulus.FEW )
		end		
		
	elseif self.type == TaskType.RECRUIT_TROOP then
		CityRecruitTroop( self.destination, self.datas )
		self:Succeed( ContributionModulus.NORMAL )
	elseif self.type == TaskType.LEAD_TROOP then
		CharaLeadTroop( self.actor, self.target )
		self:Succeed( ContributionModulus.FEW )
	elseif self.type == TaskType.ESTABLISH_CORPS then
		if self.target then
			CharaEstablishCorpsByTroop( self.destination, self.target )
		else
			CharaEstablishCorps( self.destination )
		end
		self:Succeed( ContributionModulus.LITTLE )	
	elseif self.type == TaskType.REINFORCE_CORPS then
		CorpsReinforce( self.target, self.datas )
		self:Succeed( ContributionModulus.FEW )		
	elseif self.type == TaskType.REGROUP_CORPS then
		CorpsRegroup( self.datas, self.target )
		self:Succeed( ContributionModulus.FEW )
	elseif self.type == TaskType.TRAIN_CORPS then
		CorpsTrain( self.target, self.datas )
		self:Succeed( ContributionModulus.FEW )
		
	elseif self.type == TaskType.HARASS_CITY then
		--print( self.id, NameIDToString( self.actor ), "harass city=", self.destination.name )
		if CorpsInvade( self.actor, self.destination, false ) then
			self:Succeed( ContributionModulus.NORMAL )
		else
			self.status = TaskStatus.EXECUTING
		end
	elseif self.type == TaskType.EXPEDITION or self.type == TaskType.SIEGE_CITY then
		--print( self.id, NameIDToString( self.actor ), "siege city=", self.destination.name )
		CorpsInvade( self.actor, self.destination, true )
		self.status = TaskStatus.EXECUTING
	elseif self.type == TaskType.DEFEND_CITY then		
		self.status = TaskStatus.EXECUTING
	elseif self.type == TaskType.DISPATCH_CORPS then
--		g_statistic:TrackGroup( NameIDToString( self.actor ) .. " dispatch " .. NameIDToString( self.destination ) .. self.destination:DumpTagDetail( "" ), self.actor:GetGroup() )
		CorpsDispatchToCity( self.actor, self.destination, true )
		self:Succeed( ContributionModulus.LITTLE )		
	elseif self.type == TaskType.DISPATCH_TROOPS then
		g_statistic:TrackGroup( NameIDToString( self.actor ) .. " dispatch " .. NameIDToString( self.destination ) .. self.destination:DumpTagDetail( "" ), self.actor:GetGroup() )
--		TroopDispatchToCity( self.actor, self.destination, true )
		self:Succeed( ContributionModulus.LITTLE )
		
	--Diplomacy
	elseif self.type == TaskType.FRIENDLY_DIPLOMACY then
		self:UpdateDiplomacy( DiplomacyMethod.FRIENDLY )
	elseif self.type == TaskType.THREATEN_DIPLOMACY then
		self:UpdateDiplomacy( DiplomacyMethod.THREATEN )
	elseif self.type == TaskType.ALLY_DIPLOMACY then
		self:UpdateDiplomacy( DiplomacyMethod.ALLY )
	elseif self.type == TaskType.MAKE_PEACE_DIPLOMACY then
		self:UpdateDiplomacy( DiplomacyMethod.MAKE_PEACE )
	elseif self.type == TaskType.DECLARE_WAR_DIPLOMACY then
		self:UpdateDiplomacy( DiplomacyMethod.DECLARE_WAR )
	elseif self.type == TaskType.BREAK_CONTRACT_DIPLOMACY then	
		self:UpdateDiplomacy( DiplomacyMethod.BREAK_CONTRACT )
	elseif self.type == TaskType.SURRENDER_DIPLOMACY then
		self:UpdateDiplomacy( DiplomacyMethod.SURRENDER )
	
	--Personal
	elseif self.type == TaskType.CHARA_BACKHOME then
		CharaMoveToCity( self.target, self.destination )
		self:Finish( ContributionModulus.NONE )
	elseif self.type == TaskType.CORPS_MOVETO then
		CorpsMoveToCity( self.target, self.destination, true )
		self:Finish( ContributionModulus.NONE )
	elseif self.type == TaskType.TROOP_MOVETO then
		TroopMoveToCity( self.target, self.destination )
		self:Finish( ContributionModulus.NONE )
	end	
end

function Task:DumpIssue()
	if self.type == TaskType.DISPATCH_CORPS 
		or self.type == TaskType.HR_DISPATCH 
		or self.type == TaskType.HR_HIRE
		or self.type == TaskType.HR_LOOKFORTALENT
		then
		--g_statistic:FocusTask( self:CreateBrief() )
	end
	if not focusTaskType or focusTaskType == self.type then
		ShowText( "issue task=" ..self.id, " type=" .. MathUtility_FindEnumName( TaskType, self.type ), " actor=" .. NameIDToString( self.actor ) .. " tar=" .. ( self.target and self.target.name or "" ) .. " loc=" .. ( self.actor:GetLocation() and self.actor:GetLocation().name or "" ) .. " remain=" .. self.remain .. " dest="..( self.destination and self.destination.name or "" ) .. " proposer=" .. ( self.proposer and self.proposer.name or "" ) )
	end
end

function Task:IssueMoveTask( taskType, actor, home )
	self.actor    = actor
	self.type     = taskType
	self.destination = home
	self.target   = actor
	self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	self.progress = 0
	self.begDate  = g_calendar:GetDateValue()
	self.status   = TaskStatus.PREPARED
	self:DumpIssue()
end

function Task:IssueByProposal( proposal )
	if not proposal then
		Debug_Assert( nil, "Invalid proposal" )
		return
	end
	
	self.actor       = proposal.actor
	self.contributor = nil
	self.status      = TaskStatus.PREPARED
	self.progress    = 0
	self.begDate     = g_calendar:GetDateValue()
	self.proposer    = proposal.proposer

	--Tech
	if proposal.type == CharacterProposal.TECH_RESEARCH then
		self.category    = TaskCategory.TECH_AFFAIRS
		self.type        = TaskType.TECH_RESEARCH		
		self.target      = proposal.target
		self.destination = self.actor:GetGroup():GetCapital()
		self.datas       = proposal.data
		self.remain      = self.target.prerequisites.points
		self.contributor = self.actor
		
	--City Affairs
	elseif proposal.type == CharacterProposal.CITY_BUILD then
		self.category    = TaskCategory.CITY_AFFAIRS
		self.type        = TaskType.CITY_BUILD
		self.destination = proposal.target
		self.target      = proposal.data
		self.remain      = self.target.prerequisites.points
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_INVEST then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_INVEST
		self.destination = proposal.target
		self.remain   = GlobalConst.UNIT_TIME * CalcSpendTimeOnCityAffairs( self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_FARM then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_FARM
		self.destination = proposal.target
		self.remain   = GlobalConst.UNIT_TIME * CalcSpendTimeOnCityAffairs( self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_PATROL then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_PATROL
		self.destination = proposal.target
		self.remain   =  GlobalConst.UNIT_TIME * CalcSpendTimeOnCityAffairs( self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_LEVY_TAX then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_LEVY_TAX
		self.destination = proposal.target
		self.remain   = GlobalConst.UNIT_TIME * CalcSpendTimeOnCityAffairs( self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_INSTRUCT then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_INSTRUCT
		self.destination = proposal.target
		self.datas    = proposal.data
		self.remain   = GlobalConst.UNIT_TIME
		
	--Human reousrce
	elseif proposal.type == CharacterProposal.HR_DISPATCH then		
		self.category    = TaskCategory.HR_AFFAIRS
		self.type        = TaskType.HR_DISPATCH
		self.destination = proposal.data
		self.target      = proposal.target
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_CALL then
		self.category    = TaskCategory.HR_AFFAIRS
		self.type        = TaskType.HR_CALL
		self.destination = proposal.data
		self.target      = proposal.target
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_HIRE then
		self.category    = TaskCategory.HR_AFFAIRS
		self.type        = TaskType.HR_HIRE
		self.destination = proposal.data
		self.target      = proposal.target
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_EXILE then
		self.category    = TaskCategory.HR_AFFAIRS
		self.type        = TaskType.HR_EXILE
		self.target      = proposal.target
		self.destination = proposal.data
		self.remain      = 0
	elseif proposal.type == CharacterProposal.HR_PROMOTE then
		self.category    = TaskCategory.HR_AFFAIRS
		self.type        = TaskType.HR_PROMOTE
		self.target      = proposal.target
		self.destination = proposal.data
		self.remain      = 0
	elseif proposal.type == CharacterProposal.HR_LOOKFORTALENT then
		self.category    = TaskCategory.HR_AFFAIRS
		self.type        = TaskType.HR_LOOKFORTALENT
		self.target      = proposal.data
		self.destination = proposal.data
		self.remain      = CalcLookforTalentTime( self.destination )
		
	--War preparedness	
	elseif proposal.type == CharacterProposal.RECRUIT_TROOP then
		self.category = TaskCategory.WARPAREPAREDNESS_AFFAIRS
		self.type     = TaskType.RECRUIT_TROOP
		self.datas    = proposal.target
		self.destination = proposal.data
		self.remain   = self.datas.prerequisites.points or 0
		self.contributor = self.actor
		self.destination:PrepareRecruit( QueryRecruitTroopNumber( self.datas ) )
	elseif proposal.type == CharacterProposal.LEAD_TROOP then
		self.category = TaskCategory.WARPAREPAREDNESS_AFFAIRS
		self.type     = TaskType.LEAD_TROOP
		self.target   = proposal.target
		self.destination = proposal.data:GetLocation()
		self.remain   = 0--GlobalConst.UNIT_TIME
		
	elseif proposal.type == CharacterProposal.ESTABLISH_CORPS then
		self.category = TaskCategory.WARPAREPAREDNESS_AFFAIRS
		self.type     = TaskType.ESTABLISH_CORPS
		self.target   = proposal.target
		self.destination = proposal.data
		self.remain   = GlobalConst.UNIT_TIME
		self.contributor = self.actor	
	elseif proposal.type == CharacterProposal.REINFORCE_CORPS then
		self.category = TaskCategory.WARPAREPAREDNESS_AFFAIRS
		self.type     = TaskType.REINFORCE_CORPS
		self.target   = proposal.target
		self.destination = proposal.target:GetLocation()
		self.datas    = self.target:GetUnderstaffedNumber()
		self.remain   = GlobalConst.UNIT_TIME * math.ceil( self.target:GetNumOfTroop() * 0.3 )
		self.contributor = self.target:GetLeader()
		self.destination:PrepareRecruit( self.datas )
	elseif proposal.type == CharacterProposal.TRAIN_CORPS then
		self.category = TaskCategory.WARPAREPAREDNESS_AFFAIRS
		self.type     = TaskType.TRAIN_CORPS
		self.target   = proposal.target
		self.destination = proposal.target:GetLocation()
		self.remain   = GlobalConst.UNIT_TIME * ( math.ceil( proposal.target:GetNumOfTroop() * 0.5 + CorpsParams.TRAIN_CORPS_MINIMUM_UNITTIME ) )
		self.contributor = self.target:GetLeader()		
	elseif proposal.type == CharacterProposal.REGROUP_CORPS then
		self.category = TaskCategory.WARPAREPAREDNESS_AFFAIRS
		self.type     = TaskType.REGROUP_CORPS
		self.target   = proposal.target
		self.datas    = proposal.data
		self.destination = self.datas:GetLocation()
		self.remain   = GlobalConst.UNIT_TIME		
		self.contributor = self.datas:GetLeader()
	
	--Military
	elseif proposal.type == CharacterProposal.HARASS_CITY then
		self.category    = TaskCategory.MILITARY_AFFAIRS
		self.type        = TaskType.HARASS_CITY
		self.target      = proposal.target
		self.destination = proposal.target
		self.remain      = CalcCorpsPrepareTime( self.actor )
		self.status      = TaskStatus.INITIAL
		--print( "attack", proposal.target.name, self.remain, self.id )
	elseif proposal.type == CharacterProposal.EXPEDITION then
		self.category    = TaskCategory.MILITARY_AFFAIRS
		self.type        = TaskType.EXPEDITION
		self.target      = proposal.target
		self.destination = proposal.target
		self.remain      = CalcCorpsPrepareTime( self.actor )
		self.status      = TaskStatus.INITIAL
	elseif proposal.type == CharacterProposal.SIEGE_CITY then
		self.category    = TaskCategory.MILITARY_AFFAIRS
		self.type        = TaskType.SIEGE_CITY
		self.target      = proposal.target
		self.datas       = proposal.data
		self.destination = proposal.target
		self.remain      = CalcCorpsPrepareTime( self.actor )
		self.status      = TaskStatus.INITIAL
		--print( "siege", self.remain, self.id, NameIDToString( self.destination ) )
	elseif proposal.type == CharacterProposal.DEFEND_CITY then
		self.category    = TaskCategory.MILITARY_AFFAIRS
		self.type        = TaskType.DEFEND_CITY
		self.target      = proposal.target
		self.datas       = proposal.data
		self.destination = proposal.target
		self.status      = TaskStatus.EXECUTING
		self.remain      = CalcCorpsPrepareTime( self.actor )
	elseif proposal.type == CharacterProposal.DISPATCH_CORPS then
		self.category    = TaskCategory.MILITARY_AFFAIRS
		self.type        = TaskType.DISPATCH_CORPS
		self.target      = proposal.target
		self.destination = proposal.target
		self.contributor = self.actor:GetLeader()
		self:GotoDestination( self.destination )
		--[[
		if self.actor:GetLocation():IsAdjacentLocation( self.destination ) then
			self.remain  = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		else
			self:GotoDestination( self.destination )
		end
		]]
	elseif proposal.type == CharacterProposal.DISPATCH_TROOPS then
		self.category    = TaskCategory.MILITARY_AFFAIRS
		self.type        = TaskType.DISPATCH_TROOPS
		self.target      = proposal.target
		self.datas       = proposal.data
		self.destination = proposal.target
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor:GetLeader()
		
	--Diplomacy
	elseif proposal.type == CharacterProposal.FRIENDLY_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.FRIENDLY_DIPLOMACY
		self.target   = proposal.target
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.THREATEN_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.THREATEN_DIPLOMACY
		self.target   = proposal.target
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.ALLY_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.ALLY_DIPLOMACY
		self.target   = proposal.target
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.MAKE_PEACE_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.MAKE_PEACE_DIPLOMACY
		self.target   = proposal.target
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.DECLARE_WAR_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.DECLARE_WAR_DIPLOMACY
		self.target   = proposal.target
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.BREAK_CONTRACT_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.BREAK_CONTRACT_DIPLOMACY
		self.target   = proposal.target
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.SURRENDER_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.SURRENDER_DIPLOMACY
		self.target   = proposal.target
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )

	--Personal
	elseif proposal.type == CharacterProposal.CHARA_BACKHOME then
		self.type    	 = TaskType.CHARA_BACKHOME
		self.destination = proposal.target
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.CORPS_MOVETO then
		self.type     	= TaskType.CORPS_MOVETO
		self.destination = proposal.data
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.TROOOP_MOVETO then
		self.type    	 = TaskType.TROOP_MOVETO
		self.destination = proposal.target
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	else
		ShowText( "Unprocessed proposal type=", proposal.type )
		self.status = TaskStatus.SUSPENDED
		return
	end

	if not self.remain then InputUtility_Pause( self:CreateBrief() ) end
	
	self:DumpIssue()
	
	if self.category == TaskCategory.MILITARY_AFFAIRS then
		if self.type == TaskType.DISPATCH_TROOPS then
			TroopLeaveCity( self.actor, "military affair=" .. MathUtility_FindEnumName( TaskType, self.type ) )
		elseif self.type == TaskType.SIEGE_CITY then			
			CorpsLeaveCity( self.actor, "military affair=" .. MathUtility_FindEnumName( TaskType, self.type ) )
			if not self.actor:GetHome():HasOutsideCorps() then InputUtility_Pause( "siege attack" ) end
		else
			CorpsLeaveCity( self.actor, "military affair=" .. MathUtility_FindEnumName( TaskType, self.type ) )
		end
	elseif self.category == TaskCategory.DIPLOMACY_AFFAIRS then
		if self.actor:GetTroop() then
			ShowText( self.actor.name, " cann't leave to do diplomacy" )
		else
			CharaLeaveCity( self.actor, "diplomacy affairs" )
		end

	elseif self.type == TaskType.LEAD_TROOP then
		self:Update( 0 )
	elseif self.type == TaskType.CHARA_BACKHOME then
		CharaLeaveCity( self.actor, "back home " .. self.type .. "+" .. self.id )
	elseif self.type == TaskType.HR_DISPATCH or self.type == TaskType.HR_CALL then
		if self.actor:GetTroop() then
			TroopLeaveCity( self.actor:GetTroop(), "chara call/dispatch " .. self.type .. "+" .. self.id )
		else
			CharaLeaveCity( self.actor, "call/dispatch " .. self.type .. "+" .. self.id )
		end
	elseif self.type == TaskType.CORPS_MOVETO then
		CorpsLeaveCity( self.actor, "dispatch corps" )
	elseif self.type == TaskType.TROOP_MOVETO then
		TroopLeaveCity( self.actor )
	end
end

------------------------------------------

TaskManager = class()

function TaskManager:__init()
	self.taskAllocateId = 0
	self.taskList = {}

	self.actorTaskList  = {}
	self.targetTaskList = {}	
	self.removeList     = {}
	self.intelTaskList  = {}
end

function TaskManager:Dump()
	ShowText( ">>>>>>>>>>>>>>>>>Task Statistic" )
	ShowText( "Active Task=" .. #self.taskList )
	for k, task in ipairs( self.taskList ) do
		ShowText( task:CreateBrief() )
	end
	ShowText( "----------------")
	--[[
	local typeList = {}
	for k, task in ipairs( self.removeList ) do
		if not typeList[task.type] then typeList[task.type] = 1
		else typeList[task.type] = typeList[task.type] + 1 end	
	end
	for k, task in pairs( self.actorTaskList ) do
		ShowText( task.id, task.type, k.name, k.id )
	end
	]]
	ShowText( "<<<<<<<<<<<<<<<<" )
end

function TaskManager:DumpResult()
	ShowText( ">>>>>>>>>>>>>>>>>Task Result" )
	ShowText( "Finished Task=" .. #self.removeList )
	for k, task in ipairs( self.removeList ) do
		if not focusTaskType or task.type == focusTaskType then
			ShowText( task.id .. ">>>" .. MathUtility_FindEnumName( TaskType, task.type ) .. " 	actor=" .. NameIDToString( task.actor ) .. " loc=" .. ( task.destination and task.destination.name or "" ), " end=" .. g_calendar:CreateDateDescByValue( task.endDate, true, true ) .. " Use=" .. task.progress .. " result=" .. MathUtility_FindEnumName( TaskStatus, task.status ) )
		end
	end
	local typeList = {}
	for k, task in ipairs( self.removeList ) do
		if not typeList[task.type] then typeList[task.type] = 1
		else typeList[task.type] = typeList[task.type] + 1 end	
	end
	for type, number in pairs( typeList ) do
		ShowText( MathUtility_FindEnumName( TaskType, type ) .. " Times=" .. number )
	end
	self:Dump()
end

function TaskManager:Load()

end

function TaskManager:Save()

end

function TaskManager:HasTask( actor )
	if not actor then return false end
	return not actor:IsNoneTask()
	--return self:GetTaskByActor( actor )
end

function TaskManager:GetIntelTaskList( destination )
	local list = {}
	for k, task in ipairs( self.intelTaskList ) do
		if task.destination == destination and not task:IsFinished() then
			table.insert( list, task )
		end
	end
	return list
end

-- Check actor is executing any task
function TaskManager:GetTaskByActor( actor )
	if not actor then return nil end
	return self.actorTaskList[actor]
end

-- Add actor data means the actor is executing task
function TaskManager:AddActorData( actor, task )
	local existTask = self.actorTaskList[actor]
	if existTask then
		print( "---------actor="..NameIDToString( actor ) )
		print( "Exist="..existTask:CreateBrief() )
		print( "Current="..task:CreateBrief() )
		InputUtility_Pause( "exist task" )
		k.p = 1
	end
	if typeof( actor ) == "table" then
		for k, v in ipairs( actor ) do
			self.actorTaskList[v] = task
		end
	elseif actor then
		self.actorTaskList[actor] = task
		--ShowText( "Add Actor Data="..NameIDToString( actor ) .. " Desc=" .. task:CreateBrief() )
	end
end
function TaskManager:RemoveActorData( actor, task )
	if typeof( actor ) == "table" then
		for k, v in ipairs( actor ) do
			self.actorTaskList[v] = nil
		end
	elseif actor then
		self.actorTaskList[actor] = nil
	end	
end

-- Check target is involved in any task
-- Maybe submit same proposal with same target, like hire same character and start diplomacy with same group, etc.
function TaskManager:GetTaskByTarget( target )
	if not target then return nil end
	local taskList = self.targetTaskList[target]
	if not taskList then return nil end
	return MathUtility_FindData( taskList, target )
end

function TaskManager:AddTargetData( target, task )
	if not target then return end
	local taskList = self.targetTaskList[target]
	if not taskList then
		taskList = {}
		self.targetTaskList[target] = taskList
	end
	--print( "add target", NameIDToString( target ), "task="..task.id, #taskList )
	table.insert( taskList, task )
end
function TaskManager:RemoveTargetData( target, task )
	if not target then return end
	local taskList = self.targetTaskList[target]
	if not taskList then return end	
	if not MathUtility_Remove( taskList, task ) then
		InputUtility_Pause( "No task with target=", NameIDToString( target ), task:CreateBrief() )
	else
		--print( "remove target", NameIDToString( target ) )
	end
end

function TaskManager:DumpTargetData( target )
	local taskList = self.targetTaskList[target]
	if not taskList then return end
	print( "Dump target data" )
	for k, task in pairs( taskList ) do
		print( task:CreateBrief() )
	end
end

function TaskManager:CreateTask( actor )
	local findTask = self:GetTaskByActor( actor )
	if findTask then
		print( findTask:CreateBrief() )
		InputUtility_Pause( NameIDToString( findTask.actor ) .. " is executing task ["..findTask.id.."] now.", "next" )
		k.f = 1
		return
	end
	
	self.taskAllocateId = self.taskAllocateId + 1
	
	local task = Task()
	task.id = self.taskAllocateId
	table.insert( self.taskList, task )	
	return task
end

function TaskManager:IssueTaskCharaBackHome( actor )
	local task = self:CreateTask( actor )
	if task then
		task:IssueMoveTask( TaskType.CHARA_BACKHOME, actor, actor:GetHome() )
		self:AddActorData( task.actor, task )
	end
end

function TaskManager:IssueTaskCorpsBackEncampment( actor )
	local task = self:CreateTask( actor )
	if task then
		task:IssueMoveTask( TaskType.CORPS_MOVETO, actor, actor:GetHome() )
		self:AddActorData( task.actor, task )
	end
end

function TaskManager:IssueTaskTroopMoveTo( actor )
	local task = self:CreateTask( actor )
	if task then
		task:IssueMoveTask( TaskType.TROOP_MOVETO, actor, actor:GetHome() )
		self:AddActorData( task.actor, task )
	end
end
function TaskManager:IssueTaskByProposal( proposal )
	local newId = self.taskAllocateId + 1
	local task = Task()
	task.id = newId
	task:IssueByProposal( proposal )

	if self:GetTaskByActor( proposal.actor ) then
	--if self:HasConflictProposal( proposal ) then
		print( "actor has task=", task:CreateBrief() )
		quickSimulate = false
		self:Dump()
		k.p = 1
		return
	end

	self.taskAllocateId = newId	
	if proposal.type > CharacterProposal.AFFAIRS_PROPOSAL then
		task:Reward( proposal.proposer, ContributionModulus.FEW )
	end

	table.insert( self.taskList, task )
			
	------------------------------
	-- Add conflict check data
	------------------------------
	self:AddActorData( task.actor, task )
	if task.category == TaskCategory.NORMAL then		
	elseif task.category == TaskCategory.MOVING then
	elseif task.category == TaskCategory.CITY_AFFAIRS then
		self:AddTargetData( task.destination, task )
	elseif task.category == TaskCategory.WARPAREPAREDNESS_AFFAIRS then
		if task.type == TaskType.RECRUIT_TROOP then
			self:AddTargetData( task.destination, task )
		elseif task.type == TaskType.LEAD_TROOP then
			self:AddActorData( task.target, task )
		elseif task.type == TaskType.ESTABLISH_CORPS then
			--InputUtility_Pause( "est", task.destination.name, task.target )
			--self:AddActorData( task.target, task )
			self:AddTargetData( task.destination, task )
			if task.target then
				for k, troop in ipairs( task.target ) do
					self:AddActorData( troop, task )
				end
			else
				for _, troop in ipairs( task.destination.troops ) do
					if troop:IsNoneTask() then
						self:AddActorData( troop, task )
					end
				end
			end
		elseif task.type == TaskType.REINFORCE_CORPS then
			self:AddActorData( task.target, task )
		elseif task.type == TaskType.REGROUP_CORPS then
			self:AddActorData( task.datas, task )
			self:AddActorData( task.target, task )
		elseif task.type == TaskType.TRAIN_CORPS then
			self:AddActorData( task.target, task )
		elseif task.type == TaskType.CONSCRIPT_TROOP then		
			self:AddTargetData( task.destination, task )
		end
	elseif task.category == TaskCategory.HR_AFFAIRS then
		if task.type == TaskType.HR_DISPATCH then
			if task.actor:GetTroop() then
				self:AddActorData( task.actor:GetTroop() )
			end
		elseif task.type == TaskType.HR_CALL then
		elseif task.type == TaskType.HR_HIRE then
			self:AddTargetData( task.target, task )
		elseif task.type == TaskType.HR_EXILE then
		elseif task.type == TaskType.HR_PROMOTE then
		elseif task.type == TaskType.HR_BONUS then
		elseif task.type == TaskType.HR_LOOKFORTALENT then
			self:AddTargetData( task.target, task )
	    end
	elseif task.category == TaskCategory.DIPLOMACY_AFFAIRS then
		self:AddTargetData( task.target, task )
	elseif task.category == TaskCategory.MILITARY_AFFAIRS then
		if task.type == TaskType.SIEGE_CITY or task.type == TaskType.DISPATCH_CORPS or task.type == TaskType.DEFEND_CITY then
			for k, troop in ipairs( task.actor.troops ) do
				self:AddActorData( troop, task )
				if troop:GetLeader() then
					self:AddActorData( troop:GetLeader(), task )
				end
			end
		elseif task.type == TaskType.DISPATCH_TROOPS then
			if task.actor:GetLeader() then
				self:AddActorData( task.actor:GetLeader(), task )
			end
		end
		if task:IsInvasionTask() or task:IsDefendTask() then
			table.insert( self.intelTaskList, task )
		end
	elseif task.category == TaskCategory.TECH_AFFAIRS then
		self:AddTargetData( task.datas, task )
	end
end

function TaskManager:EndTask( task )
	table.insert( self.removeList, task )--{ type=task.type } )	
	
	------------------------------
	-- Remove conflict check data
	------------------------------
	self:RemoveActorData( task.actor )
	if task.category == TaskCategory.NORMAL then
	elseif task.category == TaskCategory.MOVING then
	elseif task.category == TaskCategory.CITY_AFFAIRS then
		self:RemoveTargetData( task.destination, task )
	elseif task.category == TaskCategory.WARPAREPAREDNESS_AFFAIRS then
		if task.type == TaskType.RECRUIT_TROOP then
			self:RemoveTargetData( task.destination, task )
		elseif task.type == TaskType.LEAD_TROOP then		
			self:RemoveActorData( task.target, task )
		elseif task.type == TaskType.ESTABLISH_CORPS then
			self:RemoveTargetData( task.destination, task )
			--self:RemoveActorData( task.target, task )
			if task.target then
				for k, troop in ipairs( task.target ) do
					self:RemoveActorData( troop, task )
				end
			else
				for _, troop in ipairs( task.destination.troops ) do
					if self:GetTaskByActor( troop ) == task then
						self:RemoveActorData( troop, task )
					end
				end
			end
		elseif task.type == TaskType.REINFORCE_CORPS then
			self:RemoveActorData( task.target, task )
		elseif task.type == TaskType.REGROUP_CORPS then
			self:RemoveActorData( task.datas, task )
			self:RemoveActorData( task.target, task )
		elseif task.type == TaskType.TRAIN_CORPS then
			self:RemoveActorData( task.target, task )
		elseif task.type == TaskType.CONSCRIPT_TROOP then	
			self:RemoveTargetData( task.destination, task )
		end
	elseif task.category == TaskCategory.HR_AFFAIRS then
		if task.type == TaskType.HR_DISPATCH then
			if task.actor:GetTroop() then
				self:RemoveActorData( task.actor:GetTroop() )
			end
		elseif task.type == TaskType.HR_CALL then
		elseif task.type == TaskType.HR_HIRE then			
			self:RemoveTargetData( task.target, task )
		elseif task.type == TaskType.HR_EXILE then
		elseif task.type == TaskType.HR_PROMOTE then
		elseif task.type == TaskType.HR_BONUS then
		elseif task.type == TaskType.HR_LOOKFORTALENT then
			self:RemoveTargetData( task.target, task )
	    end
	elseif task.category == TaskCategory.DIPLOMACY_AFFAIRS then
		self:RemoveTargetData( task.target, task )
	elseif task.category == TaskCategory.MILITARY_AFFAIRS then
		if task.type == TaskType.SIEGE_CITY or task.type == TaskType.DISPATCH_CORPS or task.type == TaskType.DEFEND_CITY then
			for k, troop in ipairs( task.actor.troops ) do
				self:RemoveActorData( troop )
				if troop:GetLeader() then
					self:RemoveActorData( troop:GetLeader() )
				end
			end
		elseif task.type == TaskType.DISPATCH_TROOPS then
			if task.actor:GetLeader() then
				self:RemoveActorData( task.actor:GetLeader() )
			end
		end
	elseif task.category == TaskCategory.TECH_AFFAIRS then
		self:RemoveTargetData( task.datas, task )
	end
	
	MathUtility_Remove( self.taskList, task.id, "id" )
	MathUtility_Remove( self.intelTaskList, task.id, "id" )
end

function TaskManager:FinishTask( group, taskType, target )
	for k, task in pairs( self.taskList ) do
		--ShowText( MathUtility_FindEnumName( TaskType, task.type ), taskType, task.target.name, target.name, task.actor:GetGroup().name, group.name )
		if task.type == taskType and task.target == target and task.actor:GetGroup() == group then			
			task:Finish()
		end
	end
	--InputUtility_Pause( "start finsh")
end

function TaskManager:TerminateTask( task, reason )
	task:Terminate( reason )
	self:EndTask( task )
end

function TaskManager:TerminateTaskByActor( actor, reason )
	local task = self:GetTaskByActor( actor )
	if task then
		self:TerminateTask( task, reason )
	end
end

function TaskManager:TerminateTaskByGroup( group, reason ) 
	for k, task in pairs( self.taskList ) do
		if task.actor:GetGroup() == group then
			g_statistic:CancelTask( "Cancel group -- " .. task:CreateBrief() .. " by ["..reason.."]")
			self:TerminateTask( task, reason )
		end
	end
end

--Cancel the same task from other group, just like
function TaskManager:CancelTaskFromOtherGroup( group, taskType, target )	
	for k, task in pairs( self.taskList ) do
		--ShowText( MathUtility_FindEnumName( TaskType, task.type ), task.target.name, target.name, task.actor:GetGroup().name, group.name )
		if task.type == taskType and task.target == target and task.actor:GetGroup() ~= group then		
			g_statistic:CancelTask( "Cancel conflict -- " .. task:CreateBrief() )
			ShowText( "start cancel " .. MathUtility_FindEnumName( TaskType, taskType ) )
			task:Fail()
		end
	end
end

function TaskManager:Update( elapsedTime )
	table.sort( self.taskList, function ( left, right )
		if not left.remain then
			print( left:CreateBrief() )
		end
		if not right.remain then
			print( right:CreateBrief() )
		end
  		return left.remain < right.remain
  		end )
	local removeList = {}
	for k, task in ipairs( self.taskList ) do
		task:Update( elapsedTime )
		if task:IsFinished() then
			table.insert( removeList, task )
		end
	end
	
	for k, task in ipairs( removeList ) do
		self:EndTask( task )
	end

	--self:Dump()
	
	--if #removeList > 0 then InputUtility_Pause( "" ) end
	
	removeList = nil
end

function TaskManager:ConvertTaskType( type )
	local keyName = MathUtility_FindEnumKey( CharacterProposal, type )
	local taskType = TaskType[keyName]
	--InputUtility_Pause( MathUtility_FindEnumName( TaskType, taskType ), MathUtility_FindEnumName( CharacterProposal, proposal.type ) )
	return taskType
end

function TaskManager:HasConflictTarget( taskType, category, target, debug )
	local taskList = self.targetTaskList[target]
	if not taskList then return false end
	if not taskType and not category then return true end	
	for k, task in ipairs( taskList ) do
		--if debug then print( task:CreateBrief() ) end
		if task.type == taskType or task.category == category then
			return true
		end
	end
	--print( "no conflict")
	return false
end

function TaskManager:HasConflictTargetByGroup( taskType, category, target, group )
	local taskList = self.targetTaskList[target]
	if not taskList then return false end
	if not taskType and not category then return true end
	for k, task in ipairs( taskList ) do
		--if debug then print( task:CreateBrief() ) end
		if task.actor:GetGroup() == group then
			if task.type == taskType or task.category == category then
				--print( "has conflict with group " .. group.name )
				return true
			end
		end
	end
	--print( "no conflict")
	return false
end

function TaskManager:HasConflictProposalTarget( taskType, category, target )
	local taskType = self:ConvertTaskType( type )
	local ret = self:HasConflictTarget( taskType, category, target )
	return ret
end

function TaskManager:HasConflictProposal( proposal )
	local type, data, target, actor, group = proposal.type, proposal.data, proposal.target, proposal.actor, proposal.group	
	local taskType = self:ConvertTaskType( type )
	
	if type >= CharacterProposal.TECH_AFFAIRS and type <= CharacterProposal.TECH_AFFAIRS_END then
		return self:HasTask( actor ) or self:HasConflictTarget( taskType, nil, data )
	
	--City Affairs
	elseif type >= CharacterProposal.CITY_AFFAIRS and type <= CharacterProposal.CITY_AFFAIRS_END then
		
		return self:HasTask( actor ) or self:HasConflictTarget( taskType, nil, target )
	
	--Human Affairs
	elseif type >= CharacterProposal.HR_AFFAIRS and type <= CharacterProposal.HR_AFFAIRS_END then		
		if self:HasTask( actor ) then return true end
		if taskType == TaskType.HR_DISPATCH 
			or taskType == TaskType.HR_CALL
			or taskType == TaskType.HR_EXILE
			or taskType == TaskType.HR_PROMOTE
			or taskType == TaskType.HR_BONUS then
			return self:HasTask( target )
		elseif taskType == TaskType.HR_HIRE then
			return self:HasConflictTarget( taskType, nil, target )
		elseif taskType == TaskType.HR_LOOKFORTALENT then
			return self:HasConflictTarget( taskType, nil, data )
	    end
		return false
	
	--Diplomacy Affairs
	elseif type >= CharacterProposal.DIPLOMACY_AFFAIRS and type <= CharacterProposal.DIPLOMACY_AFFAIRS_END then
		return self:HasTask( actor ) or self:HasConflictTargetByGroup( nil, TaskCategory.DIPLOMACY_AFFAIRS, target, group )
	
	--Military Affairs
	elseif type >= CharacterProposal.MILITARY_AFFAIRS and type <= CharacterProposal.MILITARY_AFFAIRS_END then
		if taskType == TaskType.DISPATCH_TROOPS or taskType == TaskType.SIEGE_CITY or taskType == TaskType.DEFEND_CITY then
			for k, obj in ipairs( data ) do
				if self:HasTask( obj ) then
					return true
				end
			end
			return false
		end
		return self:HasTask( actor )
	
	--Warpareparedness Affairs
	elseif type == CharacterProposal.LEAD_TROOP then
		return self:HasTask( actor ) or self:HasTask( target )
	elseif type == CharacterProposal.RECRUIT_TROOP then
		return self:HasTask( actor ) or self:HasConflictTarget( taskType, nil, data )
	elseif type == CharacterProposal.CONSCRIPT_TROOP then
		return self:HasTask( actor ) or self:HasConflictTarget( taskType, nil, data )
	elseif type == CharacterProposal.REINFORCE_CORPS then
		return self:HasTask( actor )  or self:HasTask( target )
	elseif type == CharacterProposal.ESTABLISH_CORPS then
		local hasFreeTroop = false
		if target then
			for k, singleTar in ipairs( target ) do
				if self:HasTask( singleTar ) then return true end
			end
		else
			for k, troop in ipairs(  data.troops ) do
				if troop:IsNoneTask() then
					hasFreeTroop = true
					break
				end
			end
		end
		return not hasFreeTroop or self:HasTask( actor ) or self:HasConflictTarget( taskType, nil, data )
	elseif type == CharacterProposal.TRAIN_CORPS then
		return self:HasTask( actor ) or self:HasTask( target )
	elseif type == CharacterProposal.REGROUP_CORPS then
		for k, troop in ipairs( target ) do
			if self:HasTask( troop ) then return true end
		end
		--actor is character, data is corps, target is troops
		return self:HasTask( actor ) or self:HasTask( data )
		
	else
		InputUtility_Pause( "Missing Task type=", MathUtility_FindEnumName( TaskType, taskType ), taskType, type )
	end
	
	return false
end