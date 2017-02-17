--local watchTaskType = 122
local focusTaskType --= 205

TaskType =
{
	NONE               = 0,
	
	--------------------
	--Affais
	GROUP_AFFAIS_TASK  = 100,
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
	
	RECRUIT_TROOP      = 130,
	LEAD_TROOP         = 131,
	ESTABLISH_CORPS    = 132,
	DISPATCH_CORPS     = 133,
	REINFORCE_CORPS    = 134,
	REGROUP_CORPS      = 135,
	TRAIN_CORPS        = 136,
	CONSCRIPT_TROOP    = 137,
	
	ATTACK_CITY        = 140,
	EXPEDITION         = 141,
	
	--------------------
	--Diplomacy
	DIPLOMACY_TASK    = 200,

	FRIENDLY_DIPLOMACY       = 201,
	THREATEN_DIPLOMACY       = 202,
	ALLY_DIPLOMACY           = 203,
	MAKE_PEACE_DIPLOMACY     = 204,
	DECLARE_WAR_DIPLOMACY    = 205,
	BREAK_CONTRACT_DIPLOMACY = 206,
	SURRENDER_DIPLOMACY      = 207,

	--------------------
	--Personal
	PERSONAL_TASK     = 300,
	
	BACK_HOME         = 301,
	BACK_ENCAMPMENT   = 302,
	MOVETO            = 303,
}

TaskCategory =
{
	NORMAL            = 1,
	CITY_AFFAIRS      = 2,
	CORPS_AFFAIRS     = 3,
	HR_AFFAIRS        = 4,
	DIPLOMACY_AFFAIRS = 5,
	MILITARY_AFFAIRS  = 6,
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
	local content = ""
	content = content .. MathUtility_FindEnumName( TaskType, self.type )
	content = content .. " " .. self.actor.name
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
		contributor:Contribute( math.ceil( CharacterParams.CONTRIBUTION.MAX_CONTRIBUTION * contribution ) )
		contributor = nil
	end
end

function Task:MoveOn()
	if not self.path then
		--print( self:CreateDesc() )
		--InputUtility_Pause( self.actor.name, self.actor:GetLocation().name )
	else
		local location = self.path[1]		
		if #self.path <= 1 then			
			self.path = nil
			self.actor:MoveToLocation( location )
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
	print( self.actor.name, MathUtility_FindEnumName( TaskType, self.type ) )
	if not location:IsAdjacentLocation( destination ) then
		--find way to destination
		self.path = Helper_FindPathBetweenCity( location, destination )
		destination = self.path[1]
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
	if self.type == TaskType.ATTACK_CITY or self.type == TaskType.EXPEDITION or self.type == TaskType.BACK_ENCAMPMENT then		
		self:GotoDestination( self.actor:GetEncampment() )
	else
		self:GotoDestination( self.actor:GetHome() )
	end
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

function Task:Terminate()
	self.status = TaskStatus.FAILED
	self.remain = 0
end

function Task:Fail()
	self.status = TaskStatus.FAILED
	
	if self.type == TaskType.RECRUIT_TROOP then
		self.destination:CancelRecruit( self.datas.maxNumber * GroupParams.RECRUIT.NUMBER_STANDARD_MODULUS )
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
	--Group Fall
	--print( self.id, self.type, self.actor.name )
	if not self.actor:GetGroup() then
		self:Fail()
		return
	end
	
	if self.status == TaskStatus.SUSPENDED then return end

	local elapsed = elapsedTime
	if self.type == TaskType.TECH_RESEARCH then
		elapsed = math.ceil( self.actor:GetGroup().researchAbility * elapsedTime / GlobalConst.UNIT_TIME )
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
				self.destination = self.target:GetCapital()
				self.remain = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
				InputUtility_Wait( "Capital changed" )
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
		CharaDispatch( self.target, self.destination )
		self:Succeed( TaskContribution.LITTLE )
	elseif self.type == TaskType.HR_CALL then		
		CharaCall( self.target, self.destination )
		self:Succeed( TaskContribution.LITTLE )
	elseif self.type == TaskType.HR_HIRE then
		if CharaHire( self.target, self.destination ) then
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
	elseif self.type == TaskType.DISPATCH_CORPS then
		CorpsDispatchToCity( self.target, self.destination )
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
	elseif self.type == TaskType.BACK_HOME then
		CharaMoveToLocation( self.target, self.destination )
		self:Finish( TaskContribution.NONE )
	elseif self.type == TaskType.BACK_ENCAMPMENT then
		CorpsMoveToLocation( self.target, self.destination )
		self:Finish( TaskContribution.NONE )
	elseif self.type == TaskType.MOVETO then
		CorpsMoveToLocation( self.target, self.destination )
		self:Finish( TaskContribution.NONE )
	end	
end

function Task:IssueBack( taskType, target, home )
	self.actor    = target
	self.type     = taskType
	self.destination = home
	self.target   = target
	self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	self.progress = 0
	self.begDate  = g_calendar:GetDateValue()
	
	--print( "issue task=" ..self.id, " type=" .. MathUtility_FindEnumName( TaskType, self.type ), " actor=" .. NameIDToString( self.actor ) .. " tar=" .. ( self.target and self.target.name or "" ) .. " remain=" .. self.remain .. " loc="..( self.destination and self.destination.name or "" ) )	
end

function Task:IssueByProposal( proposal )
	if not proposal then
		Debug_Assert( nil, "Invalid proposal" )
		return
	end
	
	self.actor       = proposal.proposer
	self.contributor = nil
	self.status      = TaskStatus.EXECUTING
	self.progress    = 0
	self.begDate = g_calendar:GetDateValue()

	--Tech
	if proposal.type == CharacterProposal.TECH_RESEARCH then
		self.type   = TaskType.TECH_RESEARCH		
		self.target = proposal.target
		self.destination = self.actor:GetGroup():GetCapital()
		self.remain = self.target.prerequisites.points
		self.contributor = self.actor
	--City Affairs
	elseif proposal.type == CharacterProposal.CITY_BUILD then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_BUILD
		self.destination = proposal.target
		self.target   = proposal.data
		self.remain   = self.target.prerequisites.points
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
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_DISPATCH
		self.actor    = proposal.target
		self.destination = proposal.data
		self.target   = proposal.target
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_CALL then
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_CALL
		self.actor    = proposal.target
		self.destination = proposal.data
		self.target   = proposal.target
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_HIRE then
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_HIRE
		self.destination = proposal.data
		self.target   = proposal.target
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_EXILE then
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_EXILE
		self.target   = proposal.target
		self.destination = proposal.data
		self.remain   = GlobalConst.UNIT_TIME
	elseif proposal.type == CharacterProposal.HR_PROMOTE then
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_PROMOTE
		self.target   = proposal.target
		self.destination = proposal.data
		self.remain   = GlobalConst.UNIT_TIME
		
	--War preparedness	
	elseif proposal.type == CharacterProposal.RECRUIT_TROOP then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.RECRUIT_TROOP
		self.datas    = proposal.target
		self.destination = proposal.data
		self.remain   = self.datas.prerequisites.points or 0
		self.contributor = self.actor
		self.destination:PrepareRecruit( self.datas.maxNumber * GroupParams.RECRUIT.NUMBER_STANDARD_MODULUS )
	elseif proposal.type == CharacterProposal.LEAD_TROOP then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.LEAD_TROOP
		self.actor    = proposal.data
		self.target   = proposal.target
		self.destination = proposal.data:GetLocation()
		self.remain   = GlobalConst.UNIT_TIME
		
	elseif proposal.type == CharacterProposal.ESTABLISH_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.ESTABLISH_CORPS
		self.target   = proposal.target
		self.destination = proposal.data
		self.remain   = GlobalConst.UNIT_TIME
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.DISPATCH_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.DISPATCH_CORPS
		self.target   = proposal.target
		self.destination = proposal.data
		self.remain   = CalcSpendTimeOnRoad( self.target:GetLocation(), self.destination )
		self.contributor = self.target:GetLeader()
	elseif proposal.type == CharacterProposal.REINFORCE_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.REINFORCE_CORPS
		self.target   = proposal.target
		self.destination = proposal.target:GetLocation()
		self.datas    = self.target:GetUnderstaffedNumber()
		self.remain   = GlobalConst.UNIT_TIME * math.ceil( self.target:GetNumOfTroop() * 0.3 )
		self.contributor = self.target:GetLeader()
		self.destination:PrepareRecruit( self.datas )
	elseif proposal.type == CharacterProposal.TRAIN_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.TRAIN_CORPS
		self.target   = proposal.target
		self.destination = proposal.target:GetLocation()
		self.remain   = GlobalConst.UNIT_TIME * ( math.ceil( proposal.target:GetNumOfTroop() * 0.5 + CorpsParams.TRAIN_CORPS_MINIMUM_UNITTIME ) )
		self.contributor = self.target:GetLeader()		
	elseif proposal.type == CharacterProposal.REGROUP_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
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
		self.actor    = proposal.data
		self.target   = proposal.target
		self.destination = proposal.target
		self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.EXPEDITION then
		self.category = TaskCategory.MILITARY_AFFAIRS
		self.type     = TaskType.EXPEDITION
		self.actor    = proposal.data
		self.target   = proposal.target
		self.destination = proposal.target
		self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	
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
	elseif proposal.type == CharacterProposal.BACK_HOME then
		self.type    	 = TaskType.BACK_HOME
		self.destination = proposal.target
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.BACK_ENCAMPMENT then
		self.type     	= TaskType.BACK_ENCAMPMENT
		self.actor       = proposal.target
		self.destination = proposal.data
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.MOVETO then
		self.type    	 = TaskType.MOVETO
		self.destination = proposal.target
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	else
		ShowText( "Unprocessed proposal type=", proposal.type )
		self.status = TaskStatus.SUSPENDED
		return
	end
		
	--if not self.type then InputUtility_Pause( "task " .. MathUtility_FindEnumName( CharacterProposal, proposal.type ) .. " " .. self.id ) end
	
	--print( "issue task=" ..self.id, " type=" .. MathUtility_FindEnumName( TaskType, self.type ), " actor=" .. NameIDToString( self.actor ) .. " tar=" .. ( self.target and self.target.name or "" ) .. " remain=" .. self.remain .. " loc="..( self.destination and self.destination.name or "" ) )	
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
	if not task.destination then
		InputUtility_Pause( MathUtility_FindEnumName( TaskType, task.type ) )
	end
	local content = task.id .. ">>>" .. MathUtility_FindEnumName( TaskType, task.type ) .. " 	actor=" .. NameIDToString( task.actor ) .. " loc=" .. ( task.destination and task.destination.name or "" ).. " sta=" .. MathUtility_FindEnumName( TaskStatus, task.status ) .. " remain=" .. task.remain
	return content
end

function TaskManager:Dump()
	ShowText( ">>>>>>>>>>>>>>>>>Task Statistic" )
	ShowText( "Active Task=" .. #self.taskList )
	for k, task in ipairs( self.taskList ) do
		ShowText( self:CreateTaskDesc( task ) )
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
function TaskManager:GetTaskByActor( actor )
	return self.actorTaskList[actor]
end

-- Check target is involved in any task
-- Maybe submit same proposal with same target, like hire same character and start diplomacy with same group, etc.
function TaskManager:GetTaskByTarget( target )
	--[[
	for k, task in pairs( self.targetTaskList ) do
		if task.target == target then
			return true
		end
	end
	return false
	]]
	return self.targetTaskList[target] ~= nil
end

function TaskManager:CreateTask( actor )
	local findTask = self:GetTaskByActor( actor )
	if findTask then
		--ShowText( self:CreateTaskDesc( findTask ) )
		ShowText( NameIDToString( findTask.actor ) .. " is executing task ["..findTask.id.."] now.", "next" )
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
		task:IssueBack( TaskType.BACK_HOME, actor, actor:GetHome() )
		self.actorTaskList[task.actor] = task
	end
end

function TaskManager:IssueTaskCorpsBackEncampment( actor )
	local task = self:CreateTask( actor )
	if task then
		task:IssueBack( TaskType.BACK_ENCAMPMENT, actor, actor:GetEncampment() )
		self.actorTaskList[task.actor] = task
	end
end

function TaskManager:IssueTaskTroopBackEncampment( actor )
	local task = self:CreateTask( actor )
	if task then	
		task:IssueBack( TaskType.BACK_ENCAMPMENT, actor, actor:GetEncampment() )
		self.actorTaskList[task.actor] = task
	end
end

function TaskManager:IssueTaskByProposal( proposal )
	local newId = self.taskAllocateId + 1
	local task = Task()
	task.id = newId
	task:IssueByProposal( proposal )

	--Check duplicate task
	local findTask = self:GetTaskByActor( task.actor )
	if findTask then
		--ShowText( self:CreateTaskDesc( findTask ) )
		ShowText( NameIDToString( task.actor ).." is executing task ["..findTask.id.."] now." )
		return
	end

	self.taskAllocateId = newId
	
	if proposal.type > CharacterProposal.AFFAIRS_PROPOSAL then task:Reward( proposal.proposer, TaskContribution.FEW ) end
	
	table.insert( self.taskList, task )
	self.actorTaskList[task.actor] = task
	--add actor
	if task.category == TaskCategory.MILITARY_AFFAIRS then
		self.actorTaskList[task.actor] = task
	elseif task.category == TaskCategory.CORPS_AFFAIRS then
		if typeof( task.target ) == "table" then
			for k, singleTarget in ipairs( task.target ) do				
				self.actorTaskList[singleTarget] = task
				--print( "Add task target", singleTarget.id, self.actorTaskList[singleTarget] )
			end
		elseif task.target then
			self.actorTaskList[task.target] = task
		end
	end
	--add target
	if task.category == TaskCategory.HR_AFFAIRS then
		self.targetTaskList[task.target] = task
		--table.insert( self.targetTaskList, task.target )
	elseif task.category == TaskCategory.DIPLOMACY_AFFAIRS then
		--InputUtility_Pause( "add tar", task.target.name )
		self.targetTaskList[task.target] = task
		--table.insert( self.targetTaskList, task.target )
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

function TaskManager:TerminateTask( actor )
	local task = self:GetTaskByActor( actor )
	if task then
		task:Terminate()
	end
end

function TaskManager:TerminateTaskFromGroup( group ) 
	for k, task in pairs( self.taskList ) do
		if task.actor:GetGroup() ~= group then
			g_statistic:CancelTask( "Cancel group -- " .. task:CreateDesc() )
			task:Terminate()
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

function TaskManager:Update( elapsedTime )
	local removeList = {}
	for k, task in ipairs( self.taskList ) do
		task:Update( elapsedTime )
		if task:IsFinished() then
			table.insert( removeList, task )
		end
	end
	
	for k, task in ipairs( removeList ) do
		function TaskBrief( task )
			local content = NameIDToString( task.actor ) .. " Finished id=" .. task.id .. " " .. MathUtility_FindEnumName( TaskType, task.type ) .. " In [" .. ( task.destination and task.destination.name or "" ) .. "] Beg=" .. g_calendar:CreateDateDescByValue( task.begDate, true, true ) .. " End="..g_calendar:CreateDateDescByValue( task.endDate, true, true ) .. " Use=" .. task.progress
			ShowText( content )
		end
		TaskBrief( task )
		table.insert( self.removeList, task )--{ type=task.type } )
		self.actorTaskList[task.actor] = nil
		
		--remove actor
		if task.category == TaskCategory.MILITARY_AFFAIRS then
			self.actorTaskList[task.actor] = nil
		elseif task.category == TaskCategory.CORPS_AFFAIRS then
			if typeof( task.target ) == "table" then
				for k, singleTarget in ipairs( task.target ) do
					self.actorTaskList[singleTarget] = nil
				end
			elseif task.target then
				self.actorTaskList[task.target] = nil
			end
		end
		--remove target list
		if task.category == TaskCategory.HR_AFFAIRS or task.category == TaskCategory.DIPLOMACY_AFFAIRS  then
			self.targetTaskList[task.target] = nil
			--[[
			for k, targetTask in pairs( self.targetTaskList ) do
				if targetTask.actor == task.actor then
					self.targetTaskList[k] = nil
					break
				end
			end
			]]
		end
		--self.taskList[k] = nil
		MathUtility_Remove( self.taskList, task.id, "id" )
	end

	self:Dump()
	
	--if #removeList > 0 then InputUtility_Pause( "" ) end
	
	removeList = nil
end

function TaskManager:IsTaskConflictWithCity( taskType, city )
	for k, task in ipairs( self.taskList ) do
		if task.destination == city and ( not taskType or task.type == taskType ) then
			--InputUtility_Pause( "conflict task", city.name, MathUtility_FindEnumName( TaskType, task.type ) )
			return true
		end
	end
	--ShowText( "not conflict", MathUtility_FindEnumName( TaskType, taskType ), city and city.name or "" )
	return false
end

function TaskManager:IsTaskConflictWithTarget( category, target )
	for k, task in ipairs( self.taskList ) do
		if task.target == target and task.category == category then
			--InputUtility_Pause( "conflict task", target.name, MathUtility_FindEnumName( TaskCategory, task.category ) )
			return true
		end
	end
	--print( "not conflict", MathUtility_FindEnumName( TaskCategory, category ), target and target.name or "" )
	return false
end

function TaskManager:IsExclusive( proposal )
	if proposal.type == CharacterProposal.TECH_RESEARCH and self:IsTaskConflictWithCity( TaskType.TECH_RESEARCH, nil ) then return false
	elseif proposal.type == CharacterProposal.CITY_BUILD and self:IsTaskConflictWithCity( TaskType.CITY_BUILD, proposal.target ) then return false
	elseif proposal.type == CharacterProposal.CITY_FARM and self:IsTaskConflictWithCity( TaskType.CITY_FARM, proposal.target ) then return false
	elseif proposal.type == CharacterProposal.CITY_INVEST and self:IsTaskConflictWithCity( TaskType.CITY_INVEST, proposal.target ) then return false
	elseif proposal.type == CharacterProposal.CITY_LEVY_TAX and self:IsTaskConflictWithCity( TaskType.CITY_LEVY_TAX, proposal.target ) then return false
	elseif proposal.type == CharacterProposal.CITY_INSTRUCT and self:IsTaskConflictWithCity( TaskType.CITY_INSTRUCT, proposal.target ) then return false
	elseif proposal.type == CharacterProposal.CITY_PATROL and self:IsTaskConflictWithCity( TaskType.CITY_PATROL, proposal.target ) then return false
	elseif proposal.type == CharacterProposal.ESTABLISH_CORPS and self:IsTaskConflictWithCity( TaskType.ESTABLISH_CORPS, proposal.data ) then return false
	elseif proposal.type == CharacterProposal.RECRUIT_TROOP and self:IsTaskConflictWithCity( TaskType.RECRUIT_TROOP, proposal.data ) then return false	
	end
	return not self:HasConflictTask( proposal.type, proposal.target, proposal.data )
end

function TaskManager:HasConflictTask( type, target, data )
	local taskType, city
	if type == CharacterProposal.TECH_RESEARCH then
		taskType = TaskType.TECH_RESEARCH	
	elseif type == CharacterProposal.CITY_INVEST then
		taskType = TaskType.CITY_INVEST
		city     = target
	elseif type == CharacterProposal.CITY_FARM then
		taskType = TaskType.CITY_FARM
		city     = target
	elseif type == CharacterProposal.CITY_LEVY_TAX then
		taskType = TaskType.CITY_LEVY_TAX
		city     = target
	elseif type == CharacterProposal.CITY_BUILD then
		taskType = TaskType.CITY_BUILD
		city     = target
	elseif type == CharacterProposal.CITY_INSTRUCT then
		taskType = TaskType.CITY_INSTRUCT
		city     = target
	elseif type == CharacterProposal.CITY_PATROL then
		taskType = TaskType.CITY_PATROL
		city     = target	
	elseif type == CharacterProposal.RECRUIT_TROOP then
		taskType = TaskType.RECRUIT_TROOP		
		city     = data
	elseif type == CharacterProposal.CONSCRIPT_TROOP then
		taskType = TaskType.CONSCRIPT_TROOP
		city     = data
	elseif type == CharacterProposal.ESTABLISH_CORPS then									
		taskType = TaskType.ESTABLISH_CORPS
		city     = data
		if target then
			for k, troop in ipairs( target ) do
				InputUtility_Pause( troop.name, troop.corps )
				if self:GetTaskByActor( troop ) or troop:GetCorps() then
					return true
				end
			end
		end
		
	elseif type == CharacterProposal.REGROUP_CORPS then		
		for k, troop in ipairs( target ) do
			if self:GetTaskByActor( troop ) then
				return true
			end
		end
		
	elseif type >= CharacterProposal.HR_AFFAIRS and type <= CharacterProposal.HR_AFFAIRS_END then
		if self:IsTaskConflictWithTarget( TaskCategory.HR_AFFAIRS, target ) then return true end
		if not self:GetTaskByActor( target ) then
			--InputUtility_Pause( target.name .. "is executing task" )
			return true
		end
	
	elseif type >= CharacterProposal.DIPLOMACY_AFFAIRS and type <= CharacterProposal.DIPLOMACY_AFFAIRS_END then
		--Only send one diplomatic to a group		
		return self:IsTaskConflictWithTarget( TaskCategory.DIPLOMACY_AFFAIRS, target )
	
	elseif type >= CharacterProposal.ATTACK_CITY and type <= CharacterProposal.EXPEDITION then
		for k, task in ipairs( self.taskList ) do
			if task.category == TaskCategory.MILITARY_AFFAIRS then
				return task.actor == target
			end
		end
		return false
		
	elseif type >= CharacterProposal.WAR_PREPAREDNESS_AFFAIRS and type <= CharacterProposal.WAR_PREPAREDNESS_AFFAIRS_END then
		for k, task in ipairs( self.taskList ) do			
			if task.category == TaskCategory.CORPS_AFFAIRS then
				if task.type == TaskType.LEAD_TROOP then
					return task.target == target or task.actor == data
				elseif task.type == TaskType.DISPATCH_CORPS then
					return task.target == target
				elseif task.type == TaskType.REINFORCE_CORPS then
					return task.target == target
				elseif task.type == TaskType.TRAIN_CORPS then
					return task.target == target
				end
				return true
			end
		end
		return false
		
	end	
	if taskType and self:IsTaskConflictWithCity( taskType, city ) then
		--InputUtility_Pause( "conflict " .. MathUtility_FindEnumName( TaskType, taskType ) .. " " .. city.name )
		return true
	end
	return false
end