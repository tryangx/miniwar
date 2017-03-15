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
	
	ATTACK_CITY        = 140,
	EXPEDITION         = 141,
	CONTROL_PLOT       = 142,
	DISPATCH_CORPS     = 143,
	
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
	NONE      = 0,
	EXECUTING = 1,	
	SUCCESSED = 2,		
	FAILED    = 3,	
	SUSPENDED = 4,
}

TaskContribution =
{
	NONE    = 0,
	FEW     = 0.001,
	LITTLE  = 0.002,
	LESS    = 0.005,
	NORMAL  = 0.01,
	MORE    = 0.02,
	MASSIVE = 0.03,
	HUGE    = 0.05,
}

Task = class()

function Task:__init()
	self.id          = 0	
	self.desc        = nil	
	self.type        = TaskType.NONE
	self.category    = TaskCategory.NORMAL
	self.status      = TaskStatus.NONE
	self.actor       = nil
	self.contributor = nil
	self.target      = nil
	self.destination = nil
	self.remain      = nil
	self.progress    = nil
	self.datas       = nil
	self.begDate     = nil
	self.endDate     = nil
end

function Task:Load( data )
	
end

function Task:Save()
end

function Task:CreateDesc()
	local content = "id"..self.id .. " "
	content = content .. MathUtility_FindEnumName( TaskType, self.type )
	content = content .. " " .. NameIDToString( self.actor )
	content = content .. "-" .. ( self.actor:GetGroup() and self.actor:GetGroup().name or "" )
	content = content .. " loc=" .. self.actor:GetLocation().name
	content = content .. " dst=" .. NameIDToString( self.destination )
	content = content .. " tar=" .. ( self.target and self.target.name or "" )
	content = content .. " end=" .. g_calendar:CreateDateDescByValue( self.endDate, true, true )
	content = content .. " use=" .. self.progress
	content = content .. " rst=" .. MathUtility_FindEnumName( TaskStatus, self.status )
	return content
end

function Task:IsFinished()
	if self.status ~= TaskStatus.SUCCESSED and self.status ~= TaskStatus.FAILED then
		return false
	end
	return self.remain == 0
end

function Task:Reward( contributor, contribution )
	contribution = contribution or TaskContribution.NONE
	if contribution ~= TaskContribution.NONE and contributor then
		contributor:Contribute( math.ceil( CharacterParams.ATTRIBUTE.MAX_CONTRIBUTION * contribution ) )
		contributor = nil
	end
end

function Task:MoveOn()
	if not self.path then
		--InputUtility_Pause( self.actor.name, self.actor:GetLocation().name )
	else
		local location = self.path[1]		
		if #self.path <= 1 then			
			self.path = nil
			self.actor:MoveToLocation( location )
			self.remain = 0			
		else
			table.remove( self.path, 1 )
			self.actor:MoveToLocation( location )
			local destination = self.path[1]
			self.remain = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), destination )
		end
	end
end

function Task:GotoDestination( destination )
	local location = self.actor:GetLocation()
	if location == destination then return end	
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
	self.remain = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), destination )
end

function Task:BackHome()	
	if not self.actor:GetGroup() or self.actor:GetGroup():IsFallen() then
		--InputUtility_Pause( self.actor.name .. " home is fallen" )
		return
	end
	--Back home
	self:GotoDestination( self.actor:GetHome() )
end

function Task:Suspend()
	self.status = TaskStatus.SUSPENDED
end

function Task:Succeed( contribution )
	self.status = TaskStatus.SUCCESSED	
	self:Reward( self.contributor, contribution )
	self:BackHome()
end

function Task:Finish( contribution )
	self.status = TaskStatus.SUCCESSED	
	self:Reward( self.contributor, contribution )
end

function Task:Terminate( reason )
	print( self:CreateDesc() .. " Terminate!!! Reason=", reason )--( reason and reason or "none" ) )
	self.status = TaskStatus.FAILED
	self.remain = 0
end

function Task:Fail()
	self.status = TaskStatus.FAILED
	
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
		end
	end
	if success then
		self:Succeed( TaskContribution.NORMAL )
	else
		self:Fail()
	end
end

function Task:Update( elapsedTime )
	if not elapsedTime then elapsedTime = 0 end

	--Group Fall
	--print( self.id, self.actor.name, MathUtility_FindEnumName( TaskType, self.type ) )
	if not self.actor:GetGroup() then
		self:Fail()
		return
	end
	
	if self.status == TaskStatus.SUSPENDED then return end

	local elapsed = elapsedTime
	if self.type == TaskType.TECH_RESEARCH then
		elapsed = math.ceil( self.actor:GetGroup():GetResearchAbility() * elapsedTime / GlobalConst.UNIT_TIME )
	elseif self.type == TaskType.CITY_BUILD then
		elapsed = math.ceil( self.destination.production * elapsedTime / GlobalConst.UNIT_TIME )
	elseif self.type == TaskType.RECRUIT_TROOP then
		elapsed = math.ceil( self.destination.production * elapsedTime / GlobalConst.UNIT_TIME )
	end

	if self.type == watchTaskType then
		ShowText( "Update task=" .. self.id .. " type="..MathUtility_FindEnumName( TaskType, self.type ), " remain=", self.remain, elapsed )
	end
	
	if self.category == TaskCategory.CITY_AFFAIRS then
		if self.destination:IsInSiege() then return end
	else
		if not self.destination then
			InputUtility_Pause( self:CreateDesc() )
		elseif self.destination:IsInSiege() then
			if not self.destination:IsNeutral() and not g_warfare:IsLocationUnderAttackBy( self.destination, self.actor:GetGroup() ) then
				print( "task suspend", self:CreateDesc(), self.destination.name .. " is in siege" )
				return
			end
		end
	end
	
	if self.remain > elapsed then
		self.progress = self.progress + elapsed	
		self.remain = self.remain - elapsed
		
		if self.type == TaskType.FRIENDLY_DIPLOMACY 
		or self.type == TaskType.THREATEN_DIPLOMACY
		or self.type == TaskType.ALLY_DIPLOMACY
		or self.type == TaskType.MAKE_PEACE_DIPLOMACY
		or self.type == TaskType.DECLARE_WAR_DIPLOMACY
		or self.type == TaskType.BREAK_CONTRACT_DIPLOMACY
		or self.type == TaskType.SURRENDER_DIPLOMACY then	        
			if self.destination ~= self.target:GetCapital() then
				local oldDestination = self.destination
				self.destination = self.target:GetCapital()
				self.remain = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
				if self.target:IsFallen() then
					self:Fail()
					--InputUtility_Pause( self.target.name, " capital not exist" )
				else
					InputUtility_Pause( "Capital changed from" .. oldDestination.name .. "->" .. self.destination.name )
				end
			end
		end
		return
	end

	self.remain   = 0
	self.progress = self.progress + self.remain
	self.endDate  = g_calendar:GetDateValue()
	
	if self.status == TaskStatus.SUCCESSED or self.status == TaskStatus.FAILED then		
		self:MoveOn()
		return
	end
	
	if self.type == watchTaskType then		
		InputUtility_Pause( "Do task=" .. self.id .. " type="..MathUtility_FindEnumName( TaskType, self.type ), " tar=" .. self.target.name, " loc=" .. self.destination.name, " actor=".. self.actor.name )
	end
	
	if self.type == TaskType.TECH_RESEARCH then
		InventTech( self.actor:GetGroup(), self.target )
		self:Succeed( TaskContribution.NORMAL )
	elseif self.type == TaskType.CITY_BUILD then
		CityBuildConstruction( self.destination, self.target )
		self:Succeed( TaskContribution.NORMAL )
	elseif self.type == TaskType.CITY_INVEST then
		CityInvest( self.destination )
		self:Succeed( TaskContribution.NORMAL )
	elseif self.type == TaskType.CITY_FARM then
		CityFarm( self.destination )
		self:Succeed( TaskContribution.NORMAL )
	elseif self.type == TaskType.CITY_PATROL then
		CityPatrol( self.destination )
		self:Succeed( TaskContribution.NORMAL )
	elseif self.type == TaskType.CITY_LEVY_TAX then
		CityLevyTax( self.destination )
		self:Succeed( TaskContribution.NORMAL )	
	elseif self.type == TaskType.CITY_INSTRUCT then
		CityInstruct( self.destination, self.datas )
		self:Succeed( TaskContribution.NORMAL )
	
	elseif self.type == TaskType.HR_DISPATCH then
		CharaDispatchToCity( self.target, self.destination )
		self:Succeed( TaskContribution.LITTLE )
	elseif self.type == TaskType.HR_CALL then		
		CharaDispatchToCity( self.target, self.destination )
		self:Succeed( TaskContribution.LITTLE )
	elseif self.type == TaskType.HR_HIRE then
		if CharaHired( self.target, self.destination ) then
			self:Succeed( TaskContribution.LESS )
		else
			self:Fail()
		end
	elseif self.type == TaskType.HR_EXILE then
		CharaExile( self.target, self.destination )
		self:Succeed( TaskContribution.FEW )
	elseif self.type == TaskType.HR_PROMOTE then
		CharaPromote( self.target, self.destination )
		self:Succeed( TaskContribution.FEW )
	elseif self.type == TaskType.HR_LOOKFORTALENT then
		if CharaLookforTalent( self.destination ) then
			self:Succeed( TaskContribution.NORMAL )
		else
			self:Fail( TaskContribution.FEW )
		end
		
		
	elseif self.type == TaskType.RECRUIT_TROOP then
		CityRecruitTroop( self.destination, self.datas )
		self:Succeed( TaskContribution.NORMAL )
	elseif self.type == TaskType.LEAD_TROOP then
		CharaLeadTroop( self.actor, self.target )
		self:Succeed( TaskContribution.FEW )
	elseif self.type == TaskType.ESTABLISH_CORPS then
		if self.target then
			CharaEstablishCorpsByTroop( self.destination, self.target )
		else
			CharaEstablishCorps( self.destination )
		end
		self:Succeed( TaskContribution.LITTLE )	
	elseif self.type == TaskType.REINFORCE_CORPS then
		CorpsReinforce( self.target, self.datas )
		self:Succeed( TaskContribution.FEW )		
	elseif self.type == TaskType.REGROUP_CORPS then
		CorpsRegroup( self.datas, self.target )
		self:Succeed( TaskContribution.FEW )
	elseif self.type == TaskType.TRAIN_CORPS then
		CorpsTrain( self.target, self.datas )
		self:Succeed( TaskContribution.FEW )
		
	elseif self.type == TaskType.ATTACK_CITY then
		CorpsAttack( self.actor, self.destination )		
		self:Suspend()
	elseif self.type == TaskType.EXPEDITION then
		CorpsAttack( self.actor, self.destination )
		self:Suspend()
	elseif self.type == TaskType.DISPATCH_CORPS then
		CorpsDispatchToCity( self.actor, self.destination, true )
		self:Succeed( TaskContribution.LITTLE )	
		
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
		CharaMoveToLocation( self.target, self.destination )
		self:Finish( TaskContribution.NONE )
	elseif self.type == TaskType.CORPS_MOVETO then
		CorpsMoveToLocation( self.target, self.destination, true )
		self:Finish( TaskContribution.NONE )
	elseif self.type == TaskType.TROOP_MOVETO then
		TroopMoveToLocation( self.target, self.destination )
		self:Finish( TaskContribution.NONE )
	end	
end

function Task:DumpIssue()
	if not focusTaskType or focusTaskType == self.type then
		if not self.actor then
			InputUtility_Pause( "?issue task=" ..self.id, " type=" .. MathUtility_FindEnumName( TaskType, self.type ) )
		end
		--print( "issue task=" ..self.id, " type=" .. MathUtility_FindEnumName( TaskType, self.type ), " actor=" .. NameIDToString( self.actor ) .. " tar=" .. ( self.target and self.target.name or "" ) .. " loc=" .. ( self.actor:GetLocation() and self.actor:GetLocation().name or "" ) .. " remain=" .. self.remain .. " dest="..( self.destination and self.destination.name or "" ) .. " proposer=" .. ( self.proposer and self.proposer.name or "" ) )
	end
end

function Task:IssueBack( taskType, actor, home )
	self.actor    = actor
	self.type     = taskType
	self.destination = home
	self.target   = actor
	self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	self.progress = 0
	self.begDate  = g_calendar:GetDateValue()
	self.status   = TaskStatus.EXECUTING
	self:DumpIssue()
end

function Task:IssueByProposal( proposal )
	if not proposal then
		Debug_Assert( nil, "Invalid proposal" )
		return
	end
	
	self.actor       = proposal.actor
	self.contributor = nil
	self.status      = TaskStatus.EXECUTING
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
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_LOOKFORTALENT
		self.destination = proposal.data
		self.remain   = CalcLookforTalentTime( self.destination )
		
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
		self.remain   = GlobalConst.UNIT_TIME
		
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
	elseif proposal.type == CharacterProposal.ATTACK_CITY then
		self.category = TaskCategory.MILITARY_AFFAIRS
		self.type     = TaskType.ATTACK_CITY
		self.target   = proposal.target
		self.destination = proposal.target
		self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )		
	elseif proposal.type == CharacterProposal.EXPEDITION then
		self.category = TaskCategory.MILITARY_AFFAIRS
		self.type     = TaskType.EXPEDITION
		self.target   = proposal.target
		self.destination = proposal.target
		self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.DISPATCH_CORPS then
		self.category = TaskCategory.MILITARY_AFFAIRS
		self.type     = TaskType.DISPATCH_CORPS
		self.destination = proposal.target
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
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
	
	self:DumpIssue()
	
	if self.category == TaskCategory.MILITARY_AFFAIRS then
		CorpsLeaveCity( self.actor, "military affair=" .. MathUtility_FindEnumName( TaskType, self.type ) )
	elseif self.category == TaskCategory.DIPLOMACY_AFFAIRS then
		if self.actor:GetTroop() then
			print( self.actor.name, " cann't leave to do diplomacy" )
		else
			CharaLeaveCity( self.actor, "diplomacy affairs" )
		end
	elseif self.type == TaskType.CHARA_BACKHOME then
		CharaLeaveCity( self.actor, "back home " .. self.type .. "+" .. self.id )
	elseif self.type == TaskType.HR_DISPATCH
		or self.type == TaskType.HR_CALL then
		CharaLeaveCity( self.actor, "call/dispatch " .. self.type .. "+" .. self.id )
	elseif self.type == TaskType.CORPS_MOVETO then
		InputUtility_Pause( "1" )
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

	self.actorTaskList = {}
	self.targetTaskList = {}
	self.removeList = {}
end

function TaskManager:Clear()
	self.taskAllocateId = 1
	self.taskList = {}
	
	self.actorTaskList = {}
	self.targetTaskList = {}
	
	self.removeList = {}
end

function TaskManager:CreateTaskDesc( task )
	if not task.destination then print( MathUtility_FindEnumName( TaskType, task.type ) .. " has no destination" ) end
	local content = task.id .. ">>>" .. MathUtility_FindEnumName( TaskType, task.type ) .. " 	actor=" .. NameIDToString( task.actor ) .. " loc=" .. ( task.destination and task.destination.name or "" ).. " sta=" .. MathUtility_FindEnumName( TaskStatus, task.status ) .. " remain=" .. task.remain
	return content
end

function TaskManager:Dump()
	ShowText( ">>>>>>>>>>>>>>>>>Task Statistic" )
	ShowText( "Active Task=" .. #self.taskList )
	for k, task in ipairs( self.taskList ) do
		ShowText( task:CreateDesc() )--self:CreateTaskDesc( task ) )
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

-- Check actor is executing any task
function TaskManager:GetTaskByActors( actor )
	if typeof( actor ) == "table" then
		for k, v in ipairs( actor ) do
			local ret = self.actorTaskList[v]
			if ret then return ret end
		end
	end
	return nil
end
function TaskManager:GetTaskByActor( actor )
	return self.actorTaskList[actor]
end

function TaskManager:AddActorData( actor, task )
	local existTask = self.actorTaskList[actor]
	if existTask then
		print( "---------" )
		print( existTask:CreateDesc() )
		print( task:CreateDesc() )
		InputUtility_Pause( "exist task" )
	end
	if typeof( actor ) == "table" then
		for k, v in ipairs( actor ) do
			self.actorTaskList[v] = task
		end
	elseif actor then
		self.actorTaskList[actor] = task
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
		InputUtility_Pause( "No task with target=", NameIDToString( target ), task:CreateDesc() )
	else
		--print( "remove target", NameIDToString( target ) )
	end
end

function TaskManager:DumpTargetData( target )
	local taskList = self.targetTaskList[target]
	if not taskList then return end
	print( "Dump target data" )
	for k, task in pairs( taskList ) do
		print( task:CreateDesc() )
	end
end

function TaskManager:CreateTask( actor )
	local findTask = self:GetTaskByActor( actor )
	if findTask then
		print( findTask:CreateDesc() )
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
		task:IssueBack( TaskType.CHARA_BACKHOME, actor, actor:GetHome() )
		self:AddActorData( task.actor, task )
	end
end

function TaskManager:IssueTaskBackEncampment( actor )
	local task = self:CreateTask( actor )
	if task then
		task:IssueBack( TaskType.CORPS_MOVETO, actor, actor:GetHome() )
		self:AddActorData( task.actor, task )
	end
end

function TaskManager:IssueTaskTroopMoveTo( actor )
	local task = self:CreateTask( actor )
	if task then
		task:IssueBack( TaskType.TROOP_MOVETO, actor, actor:GetHome() )
		self:AddActorData( task.actor, task )
	end
end
function TaskManager:IssueTaskByProposal( proposal )	
	local newId = self.taskAllocateId + 1
	local task = Task()
	task.id = newId
	task:IssueByProposal( proposal )
	
	if self:HasConflictProposal( proposal ) then
		print( "Conflict task", task:CreateDesc() )
		quickSimulate = false
		self:Dump()
		k.p = 1
		return
	end

	self.taskAllocateId = newId	
	if proposal.type > CharacterProposal.AFFAIRS_PROPOSAL then
		task:Reward( proposal.proposer, TaskContribution.FEW )
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
			--InputUtility_Pause( "est", task.destination.name )
			self:AddActorData( task.target, task )
			self:AddTargetData( task.destination, task )
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
		elseif task.type == TaskType.HR_CALL then
		elseif task.type == TaskType.HR_HIRE then
			self:AddTargetData( task.target, task )
		elseif task.type == TaskType.HR_EXILE then
		elseif task.type == TaskType.HR_PROMOTE then
		elseif task.type == TaskType.HR_BONUS then
		elseif task.type == TaskType.HR_LOOKFORTALENT then
	    end
	elseif task.category == TaskCategory.DIPLOMACY_AFFAIRS then
		self:AddTargetData( task.target, task )
	elseif task.category == TaskCategory.MILITARY_AFFAIRS then
		--self:AddTargetData( task.target, task )
	elseif task.category == TaskCategory.TECH_AFFAIRS then
		self:AddTargetData( task.datas, task )
	end
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
			g_statistic:CancelTask( "Cancel group -- " .. task:CreateDesc() .. " by ["..reason.."]")
			self:TerminateTask( task, reason )
		end
	end
end

--Cancel the same task from other group, just like
function TaskManager:CancelTaskFromOtherGroup( group, taskType, target )	
	for k, task in pairs( self.taskList ) do
		--ShowText( MathUtility_FindEnumName( TaskType, task.type ), task.target.name, target.name, task.actor:GetGroup().name, group.name )
		if task.type == taskType and task.target == target and task.actor:GetGroup() ~= group then		
			g_statistic:CancelTask( "Cancel conflict -- " .. task:CreateDesc() )
			ShowText( "start cancel " .. MathUtility_FindEnumName( TaskType, taskType ) )
			task:Fail()
		end
	end
end

function TaskManager:EndTask( task )
	function TaskBrief( task )
		local content = NameIDToString( task.actor ) .. " Finished id=" .. task.id .. " " .. MathUtility_FindEnumName( TaskType, task.type ) .. " In [" .. ( task.destination and task.destination.name or "" ) .. "] Beg=" .. g_calendar:CreateDateDescByValue( task.begDate, true, true ) .. " End="..g_calendar:CreateDateDescByValue( task.endDate, true, true ) .. " Use=" .. task.progress
		print( content )
	end
	
	if task.type == TaskType.DISPATCH_CORPS then
		g_statistic:FocusTask( task:CreateDesc() )
	end
	
	--TaskBrief( task )	
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
			self:RemoveActorData( task.target, task )
			self:RemoveTargetData( task.destination, task )
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
		elseif task.type == TaskType.HR_CALL then
		elseif task.type == TaskType.HR_HIRE then			
			self:RemoveTargetData( task.target, task )
		elseif task.type == TaskType.HR_EXILE then
		elseif task.type == TaskType.HR_PROMOTE then
		elseif task.type == TaskType.HR_BONUS then
		elseif task.type == TaskType.HR_LOOKFORTALENT then
	    end
	elseif task.category == TaskCategory.DIPLOMACY_AFFAIRS then
		self:RemoveTargetData( task.target, task )
	elseif task.category == TaskCategory.MILITARY_AFFAIRS then
		--self:RemoveTargetData( task.target, task )
	elseif task.category == TaskCategory.TECH_AFFAIRS then
		self:RemoveTargetData( task.datas, task )
	end
	
	--self.taskList[k] = nil
	MathUtility_Remove( self.taskList, task.id, "id" )
end

function TaskManager:Update( elapsedTime )
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

	self:Dump()
	
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
		--if debug then print( task:CreateDesc() ) end
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
		--if debug then print( task:CreateDesc() ) end
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
	local ret = self:HasConflictTask( type, data, target, actor, group )
	return ret
end

function TaskManager:HasConflictTask( type, data, target, actor, group )
	local taskType = self:ConvertTaskType( type )
	
	if type >= CharacterProposal.TECH_AFFAIRS and type <= CharacterProposal.TECH_AFFAIRS_END then
		return self:GetTaskByActor( actor ) or self:HasConflictTarget( taskType, nil, data )
	
	--City Affairs
	elseif type >= CharacterProposal.CITY_AFFAIRS and type <= CharacterProposal.CITY_AFFAIRS_END then
		return self:GetTaskByActor( actor ) or self:HasConflictTarget( taskType, nil, data )
	
	--Human Affairs
	elseif type >= CharacterProposal.HR_AFFAIRS and type <= CharacterProposal.HR_AFFAIRS_END then		
		if self:GetTaskByActor( actor ) then return true end
		if taskType == TaskType.HR_DISPATCH 
			or taskType == TaskType.HR_CALL
			or taskType == TaskType.HR_EXILE
			or taskType == TaskType.HR_PROMOTE
			or taskType == TaskType.HR_BONUS then
			return self:GetTaskByActor( target )
		elseif taskType == TaskType.HR_HIRE then
			return self:HasConflictTarget( taskType, nil, target )
		elseif taskType == TaskType.HR_LOOKFORTALENT then
			return self:HasConflictTarget( taskType, nil, data )
	    end
		return false
	
	--Diplomacy Affairs
	elseif type >= CharacterProposal.DIPLOMACY_AFFAIRS and type <= CharacterProposal.DIPLOMACY_AFFAIRS_END then
		return self:GetTaskByActor( actor ) or self:HasConflictTargetByGroup( nil, TaskCategory.DIPLOMACY_AFFAIRS, target, group )
	
	--Military Affairs
	elseif type >= CharacterProposal.MILITARY_AFFAIRS and type <= CharacterProposal.MILITARY_AFFAIRS_END then
		return self:GetTaskByActor( data )
	
	--Warpareparedness Affairs
	elseif type == CharacterProposal.LEAD_TROOP then
		return self:GetTaskByActor( data ) or self:GetTaskByActor( target )
	elseif type == CharacterProposal.RECRUIT_TROOP then
		return self:GetTaskByActor( actor ) or self:HasConflictTarget( taskType, nil, data )
	elseif type == CharacterProposal.CONSCRIPT_TROOP then
		return self:GetTaskByActor( actor ) or self:HasConflictTarget( taskType, nil, data )
	elseif type == CharacterProposal.REINFORCE_CORPS then
		return self:GetTaskByActor( actor )
	elseif type == CharacterProposal.ESTABLISH_CORPS then
		return self:GetTaskByActor( actor ) or self:GetTaskByActors( target ) or self:HasConflictTarget( taskType, nil, data )
	elseif type == CharacterProposal.TRAIN_CORPS then
		return self:GetTaskByActor( actor ) or self:GetTaskByActor( target )
	elseif type == CharacterProposal.REGROUP_CORPS then
		for k, troop in ipairs( target ) do
			if troop:GetCorps() then
				print( NameIDToString( target ), " is in corps=", NameIDToString( target:GetCorps() ) )
				k.p = 1
			end
		end
		return self:GetTaskByActor( actor ) or self:GetTaskByActor( data ) or self:GetTaskByActors( target )
		
	else
		InputUtility_Pause( "Missing Task type=", MathUtility_FindEnumName( TaskType, taskType ), taskType, type )
	end
	
	return false
end