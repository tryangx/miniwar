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
	
	-- Traits
	--   Like skill
	self.traits   = MathUtility_Copy( data.traits )
	
	-- Stamina
	--   Allow character to do action
	--   Low stamina may caused disease
	--   It'll increase after rest
	self.stamina = data.stamina or CharacterParams.STAMINA.STANDARD_STAMINA
	
	-- Satisfaction
	--   Low satisfaction will lead to betray or leave
	--   Determines the Ability Potential
	--   Always 
	self.satisfaction = data.satisfaction or 0
	
	-- Contribution
	--   Determine how hard the character works and contribute to the group	
	self.contribution = data.contribution or 0
	
	-- Trust
	--   Determine how close to the leader of the Group
	--   High value means more probability of successful
	--   Low value means betray or leave or punish
	self.trust        = data.trust or 0
	
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
	
	------------------------------------
	-- Dynamic Data
		
	self._group   = nil
	
	self._troop   = nil
		
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
end

function Character:Dump( indent )
	if not indent then indent = "" end
	local content = indent .. "Chara [".. self.name .. "] Stay [".. self.location.name .. "] st=" .. self.stamina .. " job=" .. MathUtility_FindEnumName( CharacterJob, self.job ) .. " Task=" .. ( g_taskMng:GetTaskByActor( self ) and "True" or "False" )
	print( content )
end

----------------------------------
-- Getter

function Character:IsAlive()
	return self.status ~= Characterstatus.DEAD
end

function Character:IsGroupLeader()
	return self._group:GetLeader() == self
end

function Character:IsAtHome()
	return self.location == self.home
end

function Character:IsStayCity( city )
	return self.location == city
end

function Character:IsLeadTroop()
	return self._troop ~= nil
end

-- Job Relative
function Character:IsImportant()
	return self.job >= CharacterJob.IMPORTANT_JOB
end
function Character:IsOfficer()
	return self.job == CharacterJob.OFFICER 
		or self.job == CharacterJob.DIPLOMATIC
		or self.job == CharacterJob.CABINET_MINISTER
		or self.job == CharacterJob.MAYOR
		or self.job == CharacterJob.PREMIER
end
function Character:IsMilitaryOfficer()
	return self.job == CharacterJob.MILITARY_OFFICER 
		or self.job == CharacterJob.GENERAL 
		or self.job == CharacterJob.CAPTAIN 
		or self.job == CharacterJob.MARSHAL
		or self.job == CharacterJob.ADMIRAL
end
function Character:IsDiplomatic()
	return self.job == CharacterJob.DIPLOMATIC
end


----------------------------------
-- Getter

function Character:GetGroup()
	return self._group
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
	--print( NameIDToString( self ) .. " Choice " .. MathUtility_FindEnumName( CharacterAction, action ) )
end

function Character:Contribute( contribution )
	self.contribution = MathUtility_Clamp( self.contribution + contribution, 0, CharacterParams.CONTRIBUTION.MAX_CONTRIBUTION )
	Debug_Normal( "["..self.name.."] contribute " .. contribution .. " to " .. self.contribution )
end

----------------------------------
-- Operation

function Character:MoveToLocation( location )
	self.location = location
end

function Character:LeadTroop( troop )
	self._troop = troop	
	
	troop:Lead( self )
	
	if troop:GetCorps() and not troop:GetCorps():GetLeader() then
		troop:GetCorps():Lead( self )
	end
end

function Character:JoinGroup( group )
	self._group = group
end

-- When the group which character works in is fallen,
function Character:Out()
	self._group = nil	
	self.status = CharacterStatus.OUT
	self.job = CharacterJob.NONE
end

function Character:Leave()
	self._group = nil
	self.status = CharacterStatus.LEAVE
	self.job = CharacterJob.NONE
end

function Character:Die()
	self._group = nil
	self.status = CharacterStatus.DEAD
	self.job = CharacterJob.NONE
end

----------------------------------------
-- Meeting Relative

function Character:GetProposal()
	return self._submitProposal
end

function Character:CanSubmitProposal()
	return self._hasSubmitProposal ~= true and self.stamina > CharacterParams.STAMINA["SUBMIT_PROPOSAL"] and not g_taskMng:GetTaskByActor( self )
end

function Character:CanAcceptProposal()
	return self.stamina > CharacterParams.STAMINA["ACCEPT_PROPOSAL"]
end

function Character:CanLead()
	return not self:IsLeadTroop() and self:IsAtHome()
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
	return not self:IsLeadTroop() and not self:IsImportant() and self:IsAtHome() and not g_taskMng:GetTaskByActor( self )
end

function Character:SubmitProposal( proposal )	
	self._submitProposal = proposal
	if proposal.type <= CharacterProposal.PROPOSAL_COMMAND or proposal.type == CharacterProposal.PLAYER_GIVEUP_PROPOSAL then
		--print( self.name, "submit ", proposal.type, MathUtility_FindEnumName( CharacterProposal, proposal.type ) )
		self._hasSubmitProposal = true
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

function Character:Update()
	self:ClearProposal()
	
	local restoreStamina = CharacterParams.STAMINA.STANDARD_STAMINA * CharacterParams.STAMINA.RESTORE_STAMINA_RATE
	self.stamina = MathUtility_Clamp( math.ceil( self.stamina + restoreStamina ), 0, CharacterParams.STAMINA.STANDARD_STAMINA )
end

----------------------------------
-- Combat

function Character:QueryTrait( effect, params )	
	for k, trait in ipairs( self.traits ) do
		local data = trait:GetEffect( effect, params )
		if data then 
			--print( "query trait", effect, data.value )
			return data
		end
	end
	return nil
end