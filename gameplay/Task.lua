local watchTaskType = "REINFORCE_CORPS"

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

function Task:BackHome()
	--Back home
	if self.type == TaskType.ATTACK_CITY or self.type == TaskType.EXPEDITION or self.type == TaskType.BACK_ENCAMPMENT then		
		if self.actor:GetLocation() ~= self.actor:GetEncampment() then
			self.remain = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.actor:GetEncampment() )			
		end
		--print( MathUtility_FindEnumName( TaskType, self.type ), " NeedBackHome", self.target:GetLocation(), self.target:GetEncampment(), self.remain )
	else
		if self.actor:GetLocation() ~= self.actor:GetHome() then
			self.remain = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.actor:GetHome() )
		end
		--print( MathUtility_FindEnumName( TaskType, self.type ), "NeedBackHome", self.actor:GetLocation(), self.actor:GetHome(), self.remain )
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

function Task:Fail()
	self.status = TaskStatus.FAILED
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
		print( "Update task=" .. self.id .. " type="..MathUtility_FindEnumName( TaskType, self.type ), " remain=", self.remain, elapsed )
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
		local home = nil
		if self.type == TaskType.ATTACK_CITY or self.type == TaskType.EXPEDITION or self.type == TaskType.BACK_ENCAMPMENT then		
			home = self.actor:GetEncampment()
		else
			home = self.actor:GetHome()
		end
		--InputUtility_Pause( self.actor.name .. " back home " .. home.name )
		self.actor:MoveToLocation( home )
		return
	end
	
	if self.type == watchTaskType then
		print( "Do task=" .. self.id .. " type="..MathUtility_FindEnumName( TaskType, self.type ), " remain=".. self.remain, " status=" .. MathUtility_FindEnumName( TaskStatus, self.status ) )
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
		CorpsReinforce( self.target )
		self:Succeed( TaskContribution.FEW )		
	elseif self.type == TaskType.REGROUP_CORPS then
		CorpsRegroup( self.target, self.datas )
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
		CharaMoveToLocation( self.actor, self.destination )
		self:Finish( TaskContribution.NONE )
	elseif self.type == TaskType.BACK_ENCAMPMENT then
		CorpsMoveToLocation( self.actor, self.destination )
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
end

function Task:IssueByProposal( proposal )
	if not proposal then
		Debug_Assert( nil, "Invalid proposal" )
		return
	end
	
	self.actor       = proposal.chara
	self.contributor = nil
	self.status      = TaskStatus.EXECUTING
	self.progress    = 0
	self.begDate = g_calendar:GetDateValue()

	--Tech
	if proposal.type == CharacterProposal.TECH_RESEARCH then
		self.type   = TaskType.TECH_RESEARCH		
		self.target = proposal.tech
		self.destination = nil--self.actor:GetLocation()
		self.remain = self.target.prerequisites.points
		self.contributor = self.actor
	--City Affairs
	elseif proposal.type == CharacterProposal.CITY_INVEST then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_INVEST
		self.destination = proposal.city
		self.remain   = GlobalConst.UNIT_TIME * 1--self.destination.level
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_FARM then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_FARM
		self.destination = proposal.city
		self.remain   = GlobalConst.UNIT_TIME * 1--self.destination.level
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_PATROL then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_PATROL
		self.destination = proposal.city
		self.remain   =  GlobalConst.UNIT_TIME * 1--self.destination.level
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_LEVY_TAX then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_LEVY_TAX
		self.destination = proposal.city
		self.remain   = self.destination.level * GlobalConst.UNIT_TIME
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_BUILD then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_BUILD
		self.destination = proposal.city
		self.target   = proposal.constr
		self.remain   = proposal.constr.prerequisites.points
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.CITY_INSTRUCT then
		self.category = TaskCategory.CITY_AFFAIRS
		self.type     = TaskType.CITY_INSTRUCT
		self.destination = proposal.city
		self.datas    = proposal.instruction
		self.remain   = GlobalConst.UNIT_TIME
		
	--Human reousrce
	elseif proposal.type == CharacterProposal.HR_DISPATCH then		
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_DISPATCH
		self.actor    = proposal.targetChara
		self.destination = proposal.targetCity
		self.target   = proposal.targetChara
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_CALL then
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_CALL
		self.actor    = proposal.targetChara
		self.destination = proposal.targetCity
		self.target   = proposal.targetChara
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_HIRE then
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_HIRE
		self.destination = proposal.targetCity
		self.target   = proposal.targetChara
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.HR_EXILE then
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_EXILE
		self.target   = proposal.targetChara
		self.destination = proposal.targetCity
		self.remain   = GlobalConst.UNIT_TIME
	elseif proposal.type == CharacterProposal.HR_PROMOTE then
		self.category = TaskCategory.HR_AFFAIRS
		self.type     = TaskType.HR_PROMOTE
		self.target   = proposal.targetChara
		self.destination = proposal.targetCity
		self.remain   = GlobalConst.UNIT_TIME
		
	--War preparedness	
	elseif proposal.type == CharacterProposal.RECRUIT_TROOP then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.RECRUIT_TROOP
		self.datas    = proposal.troop
		self.destination = proposal.city
		self.remain   = self.datas.prerequisites.points or 0
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.LEAD_TROOP then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.LEAD_TROOP
		self.actor    = proposal.targetChara
		self.target   = proposal.targetTroop
		self.destination = proposal.targetChara:GetLocation()
		self.remain   = GlobalConst.UNIT_TIME
		
	elseif proposal.type == CharacterProposal.ESTABLISH_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.ESTABLISH_CORPS
		self.target   = proposal.troopList
		self.destination = proposal.city
		self.remain   = GlobalConst.UNIT_TIME
		self.contributor = self.actor
	elseif proposal.type == CharacterProposal.DISPATCH_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.DISPATCH_CORPS
		self.target   = proposal.corps
		self.destination = proposal.city
		self.remain   = CalcSpendTimeOnRoad( self.target:GetLocation(), self.destination )
		self.contributor = self.target:GetLeader()
	elseif proposal.type == CharacterProposal.REINFORCE_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.REINFORCE_CORPS
		self.target   = proposal.corps
		self.destination = proposal.corps:GetLocation()
		local number, totalNumber = self.target:GetNumberStatus()
		self.remain   = math.ceil( GlobalConst.UNIT_TIME * ( 1 - number / totalNumber ) * CorpsParams.REINFORCE_NEED_TIME )
		self.contributor = self.target:GetLeader()
	elseif proposal.type == CharacterProposal.TRAIN_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.TRAIN_CORPS
		self.target   = proposal.corps
		self.destination = proposal.corps:GetLocation()
		local number, totalNumber = self.target:GetNumberStatus()
		self.remain   = GlobalConst.UNIT_TIME * 1-- proposal.corps.troops
		self.contributor = self.target:GetLeader()		
	elseif proposal.type == CharacterProposal.REGROUP_CORPS then
		self.category = TaskCategory.CORPS_AFFAIRS
		self.type     = TaskType.REGROUP_CORPS
		self.target   = proposal.corps
		self.destination = proposal.corps:GetLocation()
		self.remain   = GlobalConst.UNIT_TIME
		self.datas    = proposal.troops
		self.contributor = self.target:GetLeader()
		
	--Military
	elseif proposal.type == CharacterProposal.ATTACK_CITY then
		self.category = TaskCategory.MILITARY_AFFAIRS
		self.type     = TaskType.ATTACK_CITY
		self.actor    = proposal.targetCorps
		self.target   = proposal.targetCity--proposal.targetCorps
		self.destination = proposal.targetCity
		self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.EXPEDITION then
		self.category = TaskCategory.MILITARY_AFFAIRS
		self.type     = TaskType.EXPEDITION
		self.actor    = proposal.targetCorps
		self.target   = proposal.targetCity--proposal.targetCorps
		self.destination = proposal.targetCity
		self.remain   = CalcCorpsSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	
	--Diplomacy
	elseif proposal.type == CharacterProposal.FRIENDLY_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.FRIENDLY_DIPLOMACY
		self.target   = proposal.group
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.THREATEN_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.THREATEN_DIPLOMACY
		self.target   = proposal.group
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.ALLY_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.ALLY_DIPLOMACY
		self.target   = proposal.group
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.MAKE_PEACE_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.MAKE_PEACE_DIPLOMACY
		self.target   = proposal.group
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.DECLARE_WAR_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.DECLARE_WAR_DIPLOMACY
		self.target   = proposal.group
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.BREAK_CONTRACT_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.BREAK_CONTRACT_DIPLOMACY
		self.target   = proposal.group
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.SURRENDER_DIPLOMACY then
		self.category = TaskCategory.DIPLOMACY_AFFAIRS
		self.type     = TaskType.SURRENDER_DIPLOMACY
		self.target   = proposal.group
		self.destination = self.target:GetCapital()
		self.remain   = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )

	--Personal
	elseif proposal.type == CharacterProposal.BACK_HOME then
		self.type     = TaskType.BACK_HOME
		self.destination = proposal.home
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.BACK_ENCAMPMENT then
		self.type     = TaskType.BACK_ENCAMPMENT
		self.actor       = proposal.corps
		self.destination = proposal.encampment
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	elseif proposal.type == CharacterProposal.MOVETO then
		self.type     = TaskType.MOVETO
		self.destination = proposal.city
		self.remain      = CalcSpendTimeOnRoad( self.actor:GetLocation(), self.destination )
	else
		print( "Unprocessed proposal type=", proposal.type )
		self.status = TaskStatus.SUSPENDED
		return
	end
		
	--if not self.type then InputUtility_Pause( "task " .. MathUtility_FindEnumName( CharacterProposal, proposal.type ) .. " " .. self.id ) end
	
	print( "issue task=" ..self.id, " type=" .. MathUtility_FindEnumName( TaskType, self.type ), " actor=" .. NameIDToString( self.actor ) .. " tar=" .. ( self.target and self.target.name or "" ) .. " remain=" .. self.remain .. " loc="..( self.destination and self.destination.name or "" ) )
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
	local content = task.id .. ">>>" .. MathUtility_FindEnumName( TaskType, task.type ) .. " 	actor=" .. NameIDToString( task.actor ) .. " loc=" .. task.destination.name .. " sta=" .. MathUtility_FindEnumName( TaskStatus, task.status ) .. " remain=" .. task.remain
	return content
end

function TaskManager:Dump()
	print( ">>>>>>>>>>>>>>>>>Task Statistic" )
	print( "Active Task=" .. #self.taskList )
	for k, task in ipairs( self.taskList ) do
		print( self:CreateTaskDesc( task ) )
	end
	print( "----------------")	
	--[[
	local typeList = {}
	for k, task in ipairs( self.removeList ) do
		if not typeList[task.type] then typeList[task.type] = 1
		else typeList[task.type] = typeList[task.type] + 1 end	
	end
	for k, task in pairs( self.actorTaskList ) do
		print( task.id, task.type, k.name, k.id )
	end
	]]	
	print( "<<<<<<<<<<<<<<<<" )
end

function TaskManager:DumpResult()	
	for k, task in ipairs( self.removeList ) do
		print( task.id .. ">>>" .. MathUtility_FindEnumName( TaskType, task.type ) .. " 	actor=" .. NameIDToString( task.actor ) .. " loc=" .. ( task.destination and task.destination.name or "" ), " end=" .. g_calendar:CreateDateDescByValue( task.endDate, true, true ) .. " Use=" .. task.progress .. " result=" .. MathUtility_FindEnumName( TaskStatus, task.status ) )
	end
	local typeList = {}
	for k, task in ipairs( self.removeList ) do
		if not typeList[task.type] then typeList[task.type] = 1
		else typeList[task.type] = typeList[task.type] + 1 end	
	end
	for type, number in pairs( typeList ) do
		print( MathUtility_FindEnumName( TaskType, type ) .. " Times=" .. number )
	end
	self:Dump()
end

function TaskManager:Load()

end

function TaskManager:Save()

end

function TaskManager:GetTaskByActor( actor )
	return self.actorTaskList[actor]
end

function TaskManager:GetTaskByTarget( target )
	for k, task in pairs( self.targetTaskList ) do
		print( "Comp", task.target.name, target.name )
		if task.target == target then
			return true
		end
	end
	return false
end

--[[
function TaskManager:CreateTask( actor )
	local findTask = self:GetTaskByActor( actor )
	if findTask then
		--print( self:CreateTaskDesc( findTask ) )
		print( NameIDToString( task.actor ) .. " is executing task ["..findTask.id.."] now.", "next" )
		return
	end
	
	self.taskAllocateId = self.taskAllocateId + 1
	
	local task = Task()
	task.id = self.taskAllocateId
	table.insert( self.taskList, task )
	return task
end
]]

function TaskManager:IssueTaskByProposal( proposal )
	local newId = self.taskAllocateId + 1
	local task = Task()
	task.id = newId
	task:IssueByProposal( proposal )

	--Check duplicate task
	local findTask = self:GetTaskByActor( task.actor )
	if findTask then
		--print( self:CreateTaskDesc( findTask ) )
		print( NameIDToString( task.actor ).." is executing task ["..findTask.id.."] now." )
		return
	end

	self.taskAllocateId = newId
	
	if proposal.type > CharacterProposal.AFFAIRS_PROPOSAL then
		task:Reward( proposal.chara, TaskContribution.FEW )
	end
	
	table.insert( self.taskList, task )
	self.actorTaskList[task.actor] = task
	--add target
	if task.category == TaskCategory.CORPS_AFFAIRS or task.category == TaskCategory.MILITARY_AFFAIRS then
		if typeof( task.target ) == "table" then
			for k, singleTarget in ipairs( task.target ) do
				self.actorTaskList[singleTarget] = task
			end
		elseif task.target then
			self.actorTaskList[task.target] = task
		end
	end
	if task.category == TaskCategory.HR_AFFAIRS or task.category == TaskCategory.DIPLOMACY_AFFAIRS then
		table.insert( self.targetTaskList, task )
	end
end

function TaskManager:CancelTask( group, taskType, target )
	for k, task in ipairs( self.taskList ) do
		if task.type == taskType and task.target == target and task.actor:GetGroup() ~= group then
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
			print( content )
		end
		TaskBrief( task )
		table.insert( self.removeList, task )--{ type=task.type } )
		self.actorTaskList[task.actor] = nil
		
		--remove target
		if task.category == TaskCategory.CORPS_AFFAIRS or task.category == TaskCategory.MILITARY_AFFAIRS then
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
			for k, targetTask in pairs( self.targetTaskList ) do
				if targetTask.actor == task.actor then
					self.targetTaskList[k] = nil
					break
				end
			end
		end
		MathUtility_Remove( self.taskList, task.id, "id" )
	end

	self:Dump()
	
	--if #removeList > 0 then InputUtility_Pause( "" ) end
	
	removeList = nil
end

function TaskManager:IsTaskConflict( taskType, city )
	for k, task in ipairs( self.taskList ) do
		if task.destination == city and task.type == taskType then
			--InputUtility_Pause( "conflict task", city.name, MathUtility_FindEnumName( TaskType, task.type ) )
			return true
		end
	end
	--print( "not conflict", MathUtility_FindEnumName( TaskType, taskType ), city and city.name or "" )
	return false
end

function TaskManager:HasSimilarTaskByProposal( proposal )
	local taskType
	--Below the number of same task is limit to one in a city
	if proposal.type == CharacterProposal.TECH_RESEARCH then
		taskType = TaskType.TECH_RESEARCH
	elseif proposal.type == CharacterProposal.CITY_INVEST then
		taskType = TaskType.CITY_INVEST
	elseif proposal.type == CharacterProposal.CITY_FARM then
		taskType = TaskType.CITY_FARM
	elseif proposal.type == CharacterProposal.CITY_LEVY_TAX then
		taskType = TaskType.CITY_LEVY_TAX
	elseif proposal.type == CharacterProposal.CITY_BUILD then
		taskType = TaskType.CITY_BUILD
	elseif proposal.type == CharacterProposal.CITY_BUILD then
		taskType = TaskType.CITY_INSTRUCT
	elseif proposal.type == CharacterProposal.CITY_BUILD then
		taskType = TaskType.CITY_PATROL
	elseif proposal.type == CharacterProposal.RECRUIT_TROOP then
		taskType = TaskType.RECRUIT_TROOP
	elseif proposal.type == CharacterProposal.CONSCRIPT_TROOP then									
		taskType = TaskType.RECRUIT_TROOP
	elseif proposal.type == CharacterProposal.ESTABLISH_CORPS then									
		taskType = TaskType.ESTABLISH_CORPS
		
	elseif proposal.type >= CharacterProposal.HR_AFFAIRS and proposal.type <= CharacterProposal.HR_AFFAIRS_END then
		for k, task in ipairs( self.taskList ) do
			if task.category == TaskCategory.HR_AFFAIRS then			
				return task.target == proposal.targetChara
			end
		end
	
	elseif proposal.type >= CharacterProposal.DIPLOMACY_AFFAIRS and proposal.type <= CharacterProposal.DIPLOMACY_AFFAIRS_END then
		--Only send one diplomatic to a group
		for k, task in ipairs( self.taskList ) do
			if task.category == TaskCategory.DIPLOMACY_AFFAIRS and task.target == proposal.group then
				--InputUtility_Pause( "conflict task", MathUtility_FindEnumName( TaskType, task.type ) )
				return true
			end
		end
		return false
	
	elseif proposal.type >= CharacterProposal.ATTACK_CITY and proposal.type <= CharacterProposal.EXPEDITION then		
		for k, task in ipairs( self.taskList ) do
			if task.category == TaskCategory.MILITARY_AFFAIRS then				
				return task.actor == proposal.targetCorps
			end
		end
		return false
		
	elseif proposal.type >= CharacterProposal.WAR_PREPAREDNESS_AFFAIRS and proposal.type <= CharacterProposal.WAR_PREPAREDNESS_AFFAIRS_END then
		for k, task in ipairs( self.taskList ) do			
			if task.category == TaskCategory.CORPS_AFFAIRS then			
				if task.type == TaskType.LEAD_TROOP then
					return task.target == proposal.targetTroop
				elseif task.type == TaskType.DISPATCH_CORPS then
					return task.target == proposal.corps
				elseif task.type == TaskType.REINFORCE_CORPS then
					return task.target == proposal.corps
				elseif task.type == TaskType.REGROUP_CORPS then
					return task.target == proposal.corps
				elseif task.type == TaskType.TRAIN_CORPS then
					--print( MathUtility_FindEnumName( TaskCategory, task.category ), task.target.name, proposal.corps.name )
					return task.target == proposal.corps
				end
				return true
			end
		end
		return false
		
	end
	return taskType and self:IsTaskConflict( taskType, proposal.city )
end