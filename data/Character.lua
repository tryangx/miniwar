-----------------------------------
-- Character Category
-- 		Officer
--		General
--      Diplomatic
--		Universality
--
--
--
--

Character = class()

function Character:Load( data )
	self.id = data.id or 0
		
	self.name = data.name or ""
	
	self.birth = data.birth or 1
	
	self.life  = data.life or 0
	
	self.age = g_calendar:CalcDiffYear( self.birth, nil, nil, self.birth < 0 and true or false )
	
	self.type = Character.HISTRORIC
	
	-- Current ability
	--   Condition to enable the character's trait
	--     e.g. when ca reach 200, all trait of this character will enabled
	self.ca = data.ca or 0
	
	-- Ability Potential
	--   Determines character's maximum power
	--   Always a way to evaluate the character
	--   Only change by event
	--   Satisfaction will affect this value
	--     e.g. when satisfaction plus 10 to 90 and reach 100, ap will increase 5pt. 
	--     e.g. when satisfaction subtract 5 from 200 and equal 195, ap will decrease 10pt.
	self.ap = data.ap or 0
	
	--InputUtility_Pause( self.name, self.ca, self.ap )
	
	-- Stamina
	--   Allow character to do action
	--   Low stamina may caused disease
	--   Increase after time elapsed
	self.stamina = data.stamina or CharacterParams.STAMINA.STANDARD_STAMINA
	
	-- Satisfaction
	--   Will always decrease
	--   Increase after finish task, no matter success or failed
	--   Increase after finish event
	self.satisfaction = data.satisfaction or 100
	
	-- Contribution
	--   Determine how hard the character works and contribute to the group	
	self.contribution = data.contribution or 0

	-- Trust
	--   Determine how close to the leader of the Group
	--   Low value means betray or leave or punish
	self.trust        = data.trust or 0

	-- Traits
	--   Like skill
	self.traits   = MathUtility_Copy( data.traits )
	
	------------------------------------
	
	--Officer / Military Officer etc
	self.job      = CharacterJob[data.job] or CharacterJob.OFFICER
	
	--normal / out / not appear / leave / dead
	self.status   = CharacterStatus[data.status] or CharacterStatus.NORMAL
	
	--Current location( city )
	self.location = data.location or 0		
	
	--Stay location( city )
	self.home     = data.home or 0
	
	------------------------------------
	
	self.action   = data.action or CharacterAction.NONE
	
	self.troop    = data.troop or nil
	self.group    = data.group or nil
	
	------------------------------------
	-- Dynamic Data	
	self._corps   = nil	
	self._submitProposal = nil
end

function Character:SaveData()
	self.job = MathUtility_FindEnumKey( CharacterJob, self.job )
	self.status = MathUtility_FindEnumKey( CharacterStatus, self.status )

	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	Data_OutputValue( "id", self )
	Data_OutputValue( "name", self )	
		
	Data_OutputValue( "ca", self )
	Data_OutputValue( "ap", self )
	Data_OutputTable( "traits", self, "id" )
	
	Data_OutputValue( "stamina", self )
	Data_OutputValue( "satisfaction", self )
	
	Data_OutputValue( "contribution", self )
	Data_OutputValue( "trust", self )
	
	Data_OutputValue( "job", self )	
	Data_OutputValue( "status", self )
	Data_OutputValue( "action", self )
	Data_OutputValue( "location", self, "id" )
	
	Data_OutputValue( "troop", self, "id" )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
	
	self.job = CharacterJob[self.job]
	self.status = CharacterStatus[self.status]
end

function Character:ConvertID2Data()
	self.location = g_cityDataMng:GetData( self.location )
	self.home     = self.home == 0 and self.location or g_cityDataMng:GetData( self.home )
	
	local traits = {}
	for k, id in pairs( self.traits ) do
		local trait = g_traitTableMng:GetData( id )
		if trait then
			table.insert( traits, trait )
		else
			Debug_Assert( nil, "Invalid trait=" .. id .. " in " .. self.name )
		end
	end
	self.traits = traits
	
	self.troop = g_troopDataMng:GetData( self.troop )
end

function Character:CreateBrief()
	local content = NameIDToString( self ) .. " loc=" .. self.location.name .. " stu=" .. MathUtility_FindEnumName( CharacterStatus, self.status ), "task=" .. ( g_taskMng:GetTaskByActor( self ) and "busy" or "idle" ), " troop=" .. ( self:GetTroop() and self:GetTroop().name or "" )
	return content
end

function Character:Dump( indent )
	if not indent then indent = "" end	
	local content = indent .. "Chara " .. NameIDToString( self )
	content = content .. " Stay=".. self.location.name .. " st=" .. self.stamina .. " job=" .. MathUtility_FindEnumName( CharacterJob, self.job )
	local task = g_taskMng:GetTaskByActor( self )
	if task then
		content = content .. " Task=" .. MathUtility_FindEnumName( TaskType, task.type )
	end
	if self.troop then
		content = content .. " Troop=" .. self.troop.name
	end
	content = content .. " sts=" .. MathUtility_FindEnumName( CharacterStatus, self.status )
	ShowText( content )
end

----------------------------------
-- Getter

function Character:HasPriviage( checkPriviage )
	local priviageData = CharacterParams.PRIVIAGE[self:GetJob()]
	if not priviageData then
		InputUtility_Pause( "no private", self:GetJob() )
		return false
	end
	--if params.affair == "MILITARY_AFFAIRS" then InputUtility_Pause( _chara.name .. " job=" .. MathUtility_FindEnumName( CharacterJob, _chara:GetJob() ) .. " have priviage " .. params.affair, priviage[params.affair] ) end
	if priviageData["ALL"] or priviageData[checkPriviage] then return true end
	--ShowText( _chara.name .. " job=" .. MathUtility_FindEnumName( CharacterJob, _chara:GetJob() ) .. " don't have priviage " .. params.affair, priviage[params.affair] )
	return false
end

function Character:IsLeaderJob()
	return self.job >= CharacterJob.LEADER_JOB
end
function Character:IsImportantJob()
	return self.job < CharacterJob.LEADER_JOB and self.job >= CharacterJob.IMPORTANT_JOB
end
function Character:IsHighRankJob()
	return self.job < CharacterJob.IMPORTANT_JOB and self.job >= CharacterJob.HIGH_RANK_JOB
end
function Character:IsLowRankJob()
	return self.job < CharacterJob.HIGH_RANK_JOB
end

function Character:IsMoreImportant( chara )
	if not char then return true end
	if self:GetJob() % 100 > chara:GetJob() % 100 then return true end
	if self.trust > reference.trust then return true end
	if self.contribution > reference.contribution  then return true end
	return false
end

function Character:IsInService()
	return self.status == CharacterStatus.NORMAL
end

function Character:IsAlive()
	return self.status ~= Characterstatus.DEAD
end

function Character:IsGroupLeader()
	return self.group and self.group:GetLeader() == self
end

function Character:IsCityLeader()
	return self.home and self.home:GetLeader() == self
end

function Character:IsNoneTask()
	return not g_taskMng:GetTaskByActor( self ) and ( not self.troop or self.troop:IsNoneTask() )
end

function Character:IsAtHome()
	return self.location == self.home and not g_movingActorMng:HasActor( MovingActorType.CHARACTER, self )
end

function Character:IsStayCity( city )
	return self.location == city
end

function Character:GetTroop()
	return self.troop
end

-- Job Relative
function Character:IsCivialOfficial()
	return self:HasPriviage( "CITY_AFFAIRS" )
end
function Character:IsMilitaryOfficer()
	return self:HasPriviage( "MILITARY_AFFAIRS" )
end
function Character:IsDiplomatic()
	return self.job == CharacterJob.DIPLOMATIC
end
function Character:IsFreeMilitaryOfficer()
	return not self:GetTroop() and self:IsAtHome() and self:IsMilitaryOfficer() and self:IsNoneTask()
end

----------------------------------
-- Getter

function Character:GetGroup()
	return self.group
end

function Character:GetHome()
	return self.home
end

function Character:GetLocation()
	return self.location
end

function Character:GetAction()
	return self.action
end

function Character:GetJob()
	return self.job
end

----------------------------------
-- Action

function Character:ChoiceAction( action )
	self.action = action
	--ShowText( NameIDToString( self ) .. " Choice " .. MathUtility_FindEnumName( CharacterAction, action ) )
end

function Character:Contribute( contribution )
	self.contribution = MathUtility_Clamp( self.contribution + contribution, 0, CharacterParams.ATTRIBUTE.MAX_CONTRIBUTION )
	Debug_Normal( "["..self.name.."] contribute " .. contribution .. " to " .. self.contribution )
end

----------------------------------
-- Operation

function Character:MoveToLocation( location )
	--print( NameIDToString( self ) .. " move from " .. ( self.location and self.location.name or "" ) .. "->" .. ( location and location.name or "" ) )
	self.location = location
	g_movingActorMng:RemoveActor( MovingActorType.CHARACTER, self )
end

function Character:LeadTroop( troop )
	self.troop = troop
end

function Character:JoinCity( city )
	if city and city:GetGroup() ~= self:GetGroup() then
		print( "Join", self.name, city:GetGroup(), self:GetGroup(), city.name )
		InputUtility_Pause( city.name .. "["..( city:GetGroup() and city:GetGroup().name or "" ).."] is not ", ( self:GetGroup() and self:GetGroup().name or "" ) )
		k.p = 1
	end
	self.home = city
	--print( NameIDToString( self ), "join=" .. ( city and city.name or "" ) )	
end

function Character:JoinGroup( group )
	if group and self.group and self.group ~= group then print( self.name .. "	join ", group.name ) end
	self.group = group
	--if self.id == 800 then InputUtility_Pause( "join", self.name, group and group.name or "" ) end
end

-- When the group which character works in is fallen,
function Character:Out()
	print( self.name, "chara out" )
	self.status = CharacterStatus.OUT
	self.job = CharacterJob.NONE
end

function Character:Leave()
	print( self.name, "chara leave")
	self.status = CharacterStatus.LEAVE
	self.job = CharacterJob.NONE
end

function Character:Die()
	print( self.name .. " die" )
	self.status = CharacterStatus.DEAD
	self.job = CharacterJob.NONE
end

function Character:Captured()
	print( self.name .. " captured" )
	self.status = CharacterStatus.PRISONER
end

----------------------------------------
-- Meeting Relative

function Character:GetProposal()
	return self._submitProposal
end

function Character:CanSubmitProposal()
	return self.stamina > CharacterParams.STAMINA["SUBMIT_PROPOSAL"] and self._hasSubmitProposal ~= true and self:IsNoneTask()
end

function Character:CanAssignProposal()
	return self.stamina > CharacterParams.STAMINA["ASSIGN_PROPOSAL"]
end

function Character:CanAcceptProposal()
	return self.stamina > CharacterParams.STAMINA["ACCEPT_PROPOSAL"]
end

function Character:CanExecuteProposal()
	return self.stamina > CharacterParams.STAMINA["EXECUTE_PROPOSAL"] and self:IsNoneTask()
end

function Character:CanLead()
	return not self:GetTroop() and self:IsAtHome()
end

function Character:GetPromoteList()
	local list = {}
	local jobParams = CharacterParams.JOB_PROMOTION[self:GetJob()]
	if not jobParams or not jobParams.promotions  then return list end
	for k, promotion in pairs( jobParams.promotions ) do		
		local newJob = CharacterJob[promotion.job]
		local params = CharacterParams.JOB_PROMOTION[newJob]
		if params then
			local canPromote = params.contribution and params.contribution <= self.contribution or true
			if canPromote and params.limit then
				local number = 0
				for k, chara in ipairs( self:GetGroup().charas ) do
					if chara:GetJob() == newJob then
						number = number + 1
					end
				end
				canPromote = number < params.limit
			end
			if canPromote then
				table.insert( list, newJob )
			end
		end
	end
	return list
end

function Character:IsFree()
	return not self:GetTroop() and self:IsAtHome() and self:IsNoneTask()
end

function Character:SubmitProposal( proposal )
	self._submitProposal = proposal
	if proposal.type <= CharacterProposal.PROPOSAL_COMMAND or proposal.type == CharacterProposal.PLAYER_GIVEUP_PROPOSAL then
		self._hasSubmitProposal = true
		local desc = Meeting:CreateProposalDesc( proposal, true, true )
		g_statistic:SubmitProposal( desc, self.home )
	end
end

function Character:AcceptProposal()
	self.stamina = self.stamina - CharacterParams.STAMINA["ACCEPT_PROPOSAL"]
	if self.stamina < 0 then self.stamina = 0 end
	self._submitProposal = nil
end

function Character:ProposalAccepted()
	--Debug_Normal( "["..self.name.."] proposal accepted" )	
	self.stamina = self.stamina - CharacterParams.STAMINA["SUBMIT_PROPOSAL"]
	if self.stamina < 0 then self.stamina = 0 end
	self._submitProposal = nil
end

function Character:ClearProposal()
	self._submitProposal = nil
	self._hasSubmitProposal = false
end

----------------------------------
-- Update

function Character:Update( elapsedTime )
	self:ClearProposal()	
	
	local restoreStamina = CharacterParams.STAMINA.STANDARD_STAMINA * CharacterParams.STAMINA.RESTORE_STAMINA_RATE
	self.stamina = MathUtility_Clamp( math.ceil( self.stamina + restoreStamina ), 0, CharacterParams.STAMINA.STANDARD_STAMINA )
	
	UpdateCharaGrowth( self )
end

----------------------------------
-- Combat

function Character:IsTraitEnable( index )
	local req = index * CharacterParams.TRAIT.TRAIT_REQUIREMENT_PER_SLOT 
	if self.ca >= req or self.satisfaction >= req or self.trust >= req then return true end
	return false
end

function Character:QueryTrait( effect, params )	
	for k, trait in ipairs( self.traits ) do
		if self:IsTraitEnable( k ) then
			local data = trait:GetEffect( effect, params )
			if data then 
				--ShowText( "query trait", effect, data.value )
				return data
			end
		end
	end
	return nil
end