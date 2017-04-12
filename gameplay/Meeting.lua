--[[
	
	Group Meeting Flow
	
		Tech / Political
		Diplomacy	
		Capital ( capital )( invest / build / collect tax / order other city )
		Chara( dispatch / call / lead )
		War Preparedness( recruit troop / establish corps )
		Military( attack / garrison )
		
	
	City Meeting Flow
	
	
	Corps Meeting Flow

]]

MeetingType = 
{
	GROUP         = 1,	
	CITY          = 2,
	GROUP_DISCUSS = 3,
	CITY_DISCUSS  = 4,
}

MeetingStatus = 
{
	START = 0,	
	MAKE_CHOICE   = 1,
	COLLECT_PROPOSAL = 2,	
	SUBMIT_PROPOSAL  = 3,	
	EXECUTE_PROPOSAL = 4,	
	SELECT_PROPOSAL  = 5,	
	CONFIRM_PROPOSAL = 6,	
	SUBMENU          = 7,	
	FINISH_PROPOSAL  = 8,
	END_TOPIC        = 9,
	END_MEETING      = 10,
}

MeetingFlow =
{
	NONE             = 0,
	
	GROUP_DISCUSS_FLOW     = 10,
	GROUP_DISCUSS_FLOW_END = 11,
	
	CITY_DISCUSS_FLOW     = 20,
	CITY_DISCUSS_FLOW_END = 21,
		
	TECH_FLOW             = 31,
	DIPLOMACY_FLOW        = 32,
	INSTRUCT_FLOW         = 33,
	HUMAN_RESOURCE_FLOW   = 34,
	CITY_AFFAIRS_FLOW     = 35,
	WAR_PREPAREDNESS_FLOW = 36,	
	MILITARY_FLOW         = 37,
	END                   = 38,
}

MeetingSubFlow = 
{
	NONE  = 0,
	
	ACTIVATE = 1,
	
	SUB_DIPLOMACY_AFFAIRS  = 10,
	
	SUB_TECH_RESEARCH    = 11,
	
	SUB_CITY_INSTRUCT    = 20,
	
	SUB_CITY_BUILD       = 30,
	SUB_CITY_INVEST      = 31,
	SUB_CITY_LEVY_TAX    = 32,
	SUB_CITY_FARM        = 33,
	SUB_CITY_PATROL      = 34,
	
	SUB_HR_DISPATCH      = 41,	
	SUB_HR_CALL          = 42,
	SUB_HR_HIRE          = 43,
	SUB_HR_EXILE	     = 44,
	SUB_HR_PROMOTE       = 45,
	SUB_HR_BONUS         = 46,
	SUB_HR_LOOKFORTALENT = 47,
	
	SUB_RECRUIT_TROOP    = 51,
	SUB_LEAD_TROOP       = 52,
	SUB_ESTABLISH_CORPS  = 53,	
	SUB_REINFORCE_CORPS  = 54,	
	SUB_REGROUP_CORPS    = 55,
	SUB_TRAIN_CORPS      = 56,
	SUB_CONSCRIPT_TROOP  = 57,
	
	SUB_ATTACK_CITY      = 61,
	SUB_EXPEDITION       = 62,
	SUB_CONTROL_PLOT     = 63,
	SUB_DISPATCH_CORPS   = 64,
	SUB_SIEGE_CITY       = 65,
	SUB_MEET_ATTACK      = 66,
	SUB_DISPATCH_TROOPS  = 67,
}

Meeting = class()

function Meeting:__init()	
	self._game     = nil
	self._group    = nil
	self._city     = nil
	self._target   = nil
	self._chara    = nil
	
	self.flow      = MeetingFlow.NONE
	self.subFlow   = MeetingSubFlow.NONE
end

---------------------------------------
-- Common Flow

function Meeting:ReselectProposal( chara )
	if self._game:IsPlayer( chara ) then
		self.collectProposals = {}
		if self._leader:CanAcceptProposal() then
			for k, chara in ipairs( self._participants ) do			
				if chara:GetProposal() then
					table.insert( self.collectProposals, chara:GetProposal() )
				end
			end
		end		
	end
end

function Meeting:SelectProposalFlow( chara )
	if self._game:IsPlayer( chara ) then
		if self._entrust then
			self._chara:SubmitProposal( { type = CharacterProposal.PLAYER_ENTRUST_PROPOSAL, proposer = self._chara } )
			self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
			return
		end
	
		--ShowText( "Player select proposals" )
		self.collectProposals = {}
		local menus = {}
		local index = 1
		if self._leader:CanAcceptProposal() then
			for k, chara in ipairs( self._participants ) do			
				if chara:GetProposal() then
					local proposal = chara:GetProposal()					
					if self:IsProposalFeasible( proposal ) then
						Proposal_CreateDesc( proposal )
						proposal.c = index
						proposal.fn = function ( proposal )
							self._proposal = proposal
							self:UpdateStatus( MeetingStatus.CONFIRM_PROPOSAL )
						end
						table.insert( menus, proposal )
						table.insert( self.collectProposals, proposal )
						index = index + 1
					end
				end
			end
		end
		
		self._leader:ClearProposal()
		if self._leader:CanSubmitProposal() then
			table.insert( menus, { c = index, content = "Submit My Proposal", fn = function ()
				self._leader:SubmitProposal( { type = CharacterProposal.PLAYER_EXECUTE_PROPOSAL, proposer = self._leader } )
				self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
			end } )
			index = index + 1
		end
		
		table.insert( menus, { c = index, content = "Entrust", fn = function ()
			self._entrust = true
			self._chara:SubmitProposal( { type = CharacterProposal.PLAYER_ENTRUST_PROPOSAL, proposer =self._chara } )
			self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
		end } )
		index = index + 1
		
		if self.flow == MeetingFlow.GROUP_DISCUSS_FLOW or self.flow == MeetingFlow.CITY_DISCUSS_FLOW then
			table.insert( menus, { c = index, content = "End Meeting", fn = function ()
				self:UpdateStatus( MeetingStatus.END_MEETING )
			end } )
			index = index + 1
		else
			table.insert( menus, { c = index, content = "Next Topic", fn = function () 			
				self:UpdateStatus( MeetingStatus.END_TOPIC )
			end } )
			index = index + 1
		end
		g_menu:PopupMenu( menus, self.title )
	else
		--AI is leader
		local proposals = {}
		for k, chara in ipairs( self._participants ) do
			local proposal = chara:GetProposal()
			if proposal then
				if proposal.type <= CharacterProposal.PROPOSAL_COMMAND then
					table.insert( proposals, proposal )
				end
			end
		end
				
		if #proposals == 0 then
			chara:ClearProposal()
			if chara:CanSubmitProposal() then
				chara:SubmitProposal( { type = CharacterProposal.AI_SUBMIT_PROPOSAL, proposer =chara } )
				self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
			else
				--no proposal, skip this topic
				self:UpdateStatus( MeetingStatus.END_TOPIC )
			end
		else
			Proposal_Choice( self._leader, proposals )
			self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
		end
	end
end

-- Collect inferior's proposal
function Meeting:CollectProposalFlow( chara )
	if self.flow == MeetingFlow.CITY_DISCUSS_FLOW then
		self._chara = self._leader
		for k, chara in ipairs( self._participants ) do		
			if chara:CanSubmitProposal() then						
				if self._game:IsPlayer( chara ) then
					self._chara = chara
					submitProposal = true
				else
					Proposal_DiscussCityAffairs( chara, { city = self._city } )
					if chara:GetProposal() and not self._game:IsPlayer( self._leader ) then					
						ShowText( "###" .. chara.name .. " " .. Proposal_CreateDesc( chara:GetProposal() ) )
					end
				end
			end
		end
		if submitProposal then
			self:UpdateStatus( MeetingStatus.SUBMIT_PROPOSAL )
		else
			self:UpdateStatus( MeetingStatus.SELECT_PROPOSAL )
		end
		return
	end
	--InputUtility_Pause( "collect proposal" )
	--Old version
	if self.flow == MeetingFlow.TECH_FLOW then	
		g_charaAI:SetType( CharacterAICategory.TECH_PROPOSAL )
	elseif self.flow == MeetingFlow.DIPLOMACY_FLOW then
		g_charaAI:SetType( CharacterAICategory.DIPLOMACY_PROPOSAL )
	elseif self.flow == MeetingFlow.CITY_AFFAIRS_FLOW_FLOW then
		g_charaAI:SetType( CharacterAICategory.CITY_DEVELOP_PROPOSAL )
		g_charaAI:SetBlackboard( { city = self._city } )
	elseif self.flow == MeetingFlow.HUMAN_RESOURCE_FLOW then	
		g_charaAI:SetType( CharacterAICategory.CITY_HR_PROPOSAL )
		g_charaAI:SetBlackboard( { city = self._city } )
	elseif self.flow == MeetingFlow.WAR_PREPAREDNESS_FLOW then
		g_charaAI:SetType( CharacterAICategory.WAR_PREPAREDNESS_PROPOSAL )
		g_charaAI:SetBlackboard( { city = self._city } )
	elseif self.flow == MeetingFlow.MILITARY_FLOW then
		g_charaAI:SetType( CharacterAICategory.MILITARY_PROPOSAL )
		g_charaAI:SetBlackboard( { city = self._city } )
		
	elseif self.flow == MeetingFlow.GROUP_DISCUSS_FLOW then		
		g_charaAI:SetType( CharacterAICategory.GROUP_DISCUSS_PROPOSAL )
		g_charaAI:SetBlackboard( { city = self._city } )
	
	elseif self.flow == MeetingFlow.CITY_DISCUSS_FLOW then
		g_charaAI:SetType( CharacterAICategory.CITY_DISCUSS_PROPOSAL )
		g_charaAI:SetBlackboard( { city = self._city } )
	
	end
	
	self._chara = self._leader
	local submitProposal = false
	for k, chara in ipairs( self._participants ) do		
		if chara:CanSubmitProposal() then						
			if self._game:IsPlayer( chara ) then
				self._chara = chara
				submitProposal = true
			else
				g_charaAI:SetActor( chara )
				g_charaAI:Run()
				if chara:GetProposal() and not self._game:IsPlayer( self._leader ) then					
					ShowText( "###" .. chara.name, Proposal_CreateDesc( chara:GetProposal() ) )
				end
			end
		end
	end
	
	--InputUtility_Pause()
	--ShowText( "===Collect proposals", submitProposal )
	if submitProposal then
		self:UpdateStatus( MeetingStatus.SUBMIT_PROPOSAL )
	else
		self:UpdateStatus( MeetingStatus.SELECT_PROPOSAL )
	end
end

function Meeting:MakeChoiceFlow( chara )
	local proposal = chara:GetProposal()
	if not proposal then 
		ShowText( "Skip topic" )
		self:UpdateStatus( MeetingStatus.END_TOPIC )
		return
	end
	--ShowText( "Make choice flow", MathUtility_FindEnumName( CharacterProposal, proposal.type ) )
	if proposal.type == CharacterProposal.AI_COLLECT_PROPOSAL then			
		self:UpdateStatus( MeetingStatus.COLLECT_PROPOSAL )						
	elseif proposal.type == CharacterProposal.AI_SUBMIT_PROPOSAL then
		self._chara = self._leader
		self:UpdateStatus( MeetingStatus.SUBMIT_PROPOSAL )
		
	elseif proposal.type == CharacterProposal.PLAYER_EXECUTE_PROPOSAL then
		self:UpdateStatus( MeetingStatus.EXECUTE_PROPOSAL )
	elseif proposal.type == CharacterProposal.PLAYER_GIVEUP_PROPOSAL then
		if chara == self._leader then
			self:UpdateStatus( MeetingStatus.END_MEETING )			
		else
			self:UpdateStatus( MeetingStatus.SELECT_PROPOSAL )
		end
	elseif proposal.type == CharacterProposal.PLAYER_ENTRUST_PROPOSAL then
		Proposal_Choice( chara, self.collectProposals )
		self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
		
	elseif proposal.type == CharacterProposal.AI_CHOICE_PROPOSAL then
		self._proposal = proposal.proposal
		self:UpdateStatus( MeetingStatus.CONFIRM_PROPOSAL )	
	elseif proposal.type == CharacterProposal.NEXT_TOPIC then
		self:UpdateStatus( MeetingStatus.END_TOPIC )	
	end
end

function Meeting:ConfirmProposalFlow( proposal )	
	--ShowText( "confirm proposal", MathUtility_FindEnumName( MeetingFlow, self.flow ), MathUtility_FindEnumName( MeetingSubFlow, self.subFlow ), proposal and MathUtility_FindEnumName( CharacterProposal, proposal.type ) or "-" )
	if not proposal or proposal.type == CharacterProposal.PLAYER_GIVEUP_PROPOSAL then		
		if ( self.type == MeetingType.GROUP_DISCUSS or self.type == MeetingType.CITY_DISCUSS ) then
			--ShowText( "Player didn't submit any proposal ", self._chara.name, self._leader.name )
			if self._chara == self._leader or self._game:IsPlayer( self._leader ) then
				self:UpdateStatus( MeetingStatus.END_MEETING )
				return
			end
		end
		self:UpdateStatus( MeetingStatus.SELECT_PROPOSAL )
		return
	end
	if self.flow == MeetingFlow.GROUP_DISCUSS_FLOW or self.flow == MeetingFlow.CITY_DISCUSS_FLOW then
		if proposal.type >= CharacterProposal.INSTRUCT_AFFAIRS and proposal.type <= CharacterProposal.INSTRUCT_AFFAIRS_END then
			self.flow = MeetingFlow.INSTRUCT_FLOW
		elseif proposal.type >= CharacterProposal.TECH_AFFAIRS and proposal.type <= CharacterProposal.TECH_AFFAIRS_END then
			self.flow = MeetingFlow.TECH_FLOW
		elseif proposal.type >= CharacterProposal.DIPLOMACY_AFFAIRS and proposal.type <= CharacterProposal.DIPLOMACY_AFFAIRS_END then
			self.flow = MeetingFlow.DIPLOMACY_FLOW
		elseif proposal.type >= CharacterProposal.CITY_AFFAIRS and proposal.type <= CharacterProposal.CITY_AFFAIRS_END then			
			self.flow = MeetingFlow.CITY_AFFAIRS_FLOW
		elseif proposal.type >= CharacterProposal.HR_AFFAIRS and proposal.type <= CharacterProposal.HR_AFFAIRS_END then
			self.flow = MeetingFlow.HUMAN_RESOURCE_FLOW
		elseif proposal.type >= CharacterProposal.WAR_PREPAREDNESS_AFFAIRS and proposal.type <= CharacterProposal.WAR_PREPAREDNESS_AFFAIRS_END then			
			self.flow = MeetingFlow.WAR_PREPAREDNESS_FLOW
		elseif proposal.type >= CharacterProposal.MILITARY_AFFAIRS and proposal.type <= CharacterProposal.MILITARY_AFFAIRS_END then			
			self.flow = MeetingFlow.MILITARY_FLOW
		elseif proposal.type >= CharacterProposal.PROPOSAL_COMMAND and proposal.type <= CharacterProposal.PLAYER_EXECUTE_PROPOSAL then			
			ShowText( "selfflow=", self.flow, proposal.type )
			self._chara = self._leader
			self:UpdateStatus( MeetingStatus.SUBMIT_PROPOSAL )
		else
			ShowText( "selfflow=", self.flow, proposal.type )
			return
		end
		--ShowText( "selfflow=", self.flow, proposal.type )	
		self:ConfirmProposalFlow( proposal )
		return	
	
	else
		if self.subFlow == MeetingSubFlow.ACTIVATE then
			self.subFlow = MeetingSubFlow["SUB_" .. MathUtility_FindEnumKey( CharacterProposal, proposal.type )]
			--ShowText( "subflow=" .. MathUtility_FindEnumName( MeetingSubFlow, self.subFlow ), self.subFlow, proposal.type, MathUtility_FindEnumKey( CharacterProposal, proposal.type )  )			
		else			
			--multiple actor
			if proposal.type == CharacterProposal.DISPATCH_TROOPS then
				--InputUtility_Pause( "!!!Issue Multiple" .. Proposal_CreateDesc( proposal ) .. " by " .. proposal.proposer.name )
				local IssueProposal = MathUtility_Copy( proposal )
				for k, troop in ipairs( proposal.data ) do					
					proposal.actor = troop
					g_taskMng:IssueTaskByProposal( proposal )
				end
			elseif proposal.type == CharacterProposal.SIEGE_CITY then
				ShowDebug( "!!!Issue Multiple" .. Proposal_CreateDesc( proposal ) .. " by " .. proposal.proposer.name )
				local IssueProposal = MathUtility_Copy( proposal )
				for k, corps in ipairs( proposal.data ) do					
					proposal.actor = corps
					g_taskMng:IssueTaskByProposal( proposal )
				end
			else
				g_taskMng:IssueTaskByProposal( proposal )
			end			
		end
	end

	if self.subFlow ~= MeetingSubFlow.NONE then	
		self:UpdateStatus( MeetingStatus.SUBMENU )
	else
		if proposal.type < CharacterProposal.PROPOSAL_COMMAND then
			if self._leader ~= proposal.proposer then
				proposal.proposer:ProposalAccepted()
				self._leader:AcceptProposal()
				--ShowDebug( "["..self._leader.name.."] accept proposal by [".. proposal.proposer.name .."] " .. Proposal_CreateDesc( proposal ) )
			else
				self._leader:ProposalAccepted()
				--ShowDebug( "["..self._leader.name.."] made proposal " .. Proposal_CreateDesc( proposal ) )
			end
			self.acceptProposals = self.acceptProposals + 1
			if self.collectProposals then self:ReselectProposal( self._leader ) end
		else
			--ShowText( "No proposal made", MathUtility_FindEnumName( CharacterProposal, proposal.type ) )
		end
		self:UpdateStatus( MeetingStatus.END_PROPOSAL )
	end
end

-- As leader to submit personal proposal
function Meeting:SubmitProposalFlow( chara )	
	if self._game:IsPlayer( chara ) then
		if not chara:CanSubmitProposal() then return end
	
		local menus = {}
		local index = 1
		local nextStatus = MeetingStatus.CONFIRM_PROPOSAL
		
		function AddSubMenuItem( name, proposal )
			table.insert( menus, { c = index, content = name, fn = function()
				self.subFlow = MeetingSubFlow.ACTIVATE
				self._proposal = { type = proposal, proposer =chara }
				self:UpdateStatus( nextStatus )
			end } )
			index = index + 1
		end
		
		function AddMenuItem( name, flow, fn )
			table.insert( menus, { c = index, content = name, fn = function ()
				if fn then fn() end				
				self.flow = flow
				self:SubmitProposalFlow( chara )
			end } )
			index = index + 1
		end
		if self.flow == MeetingFlow.GROUP_DISCUSS_FLOW then
			AddMenuItem( "Tech", MeetingFlow.TECH_FLOW )
			AddMenuItem( "Diplomacy", MeetingFlow.DIPLOMACY_FLOW )
			AddMenuItem( "Instruct", MeetingFlow.INSTRUCT_FLOW )
			AddMenuItem( "City Affairs", MeetingFlow.CITY_AFFAIRS_FLOW )
			AddMenuItem( "Human Affairs", MeetingFlow.HUMAN_RESOURCE_FLOW )
			AddMenuItem( "War Preparedness", MeetingFlow.WAR_PREPAREDNESS_FLOW )
			AddMenuItem( "Military", MeetingFlow.MILITARY_FLOW )
			AddMenuItem( "Browse Information", MeetingFlow.GROUP_DISCUSS_FLOW, function ()
				ShowText( "dump" )
				self._group:Dump()
			end )
			AddMenuItem( "Entrust", MeetingFlow.GROUP_DISCUSS_FLOW, function ()
				self._entrust = true
				Proposal_Submit( chara, { city = self._city, flow = self.flow } )
				self:UpdateStatus( nextStatus )
			end )
			
		elseif self.flow == MeetingFlow.CITY_DISCUSS_FLOW then
			AddMenuItem( "City Affairs", MeetingFlow.CITY_AFFAIRS_FLOW )
			AddMenuItem( "Human Affairs", MeetingFlow.HUMAN_RESOURCE_FLOW )
			AddMenuItem( "War Preparedness Affairs", MeetingFlow.WAR_PREPAREDNESS_FLOW )
			
		elseif self.flow == MeetingFlow.TECH_FLOW then
			if self._group:CanResearch() then
				AddSubMenuItem( "Research", CharacterProposal.TECH_RESEARCH )
			end	
			
		elseif self.flow == MeetingFlow.DIPLOMACY_FLOW then
			local groups = {}
			g_groupDataMng:Foreach( function( group ) 
				if group ~= self._group then
					MathUtility_Insert( groups, { group = group, power = group:GetPower() }, "power" )
				end
			end )
			if #groups then
				for k, data in ipairs( groups ) do
					local relation = self._group:GetGroupRelation( data.group.id )
					AddSubMenuItem( data.group.name .. ",Pow=" .. data.power .. ",Type=" .. MathUtility_FindEnumName( GroupRelationType, relation.type ) .. "("..relation.evaluation..")", CharacterProposal.DIPLOMACY_AFFAIRS )
				end
			else
				ShowText( "No relations with other group" )
			end
			
		elseif self.flow == MeetingFlow.INSTRUCT_FLOW then
			if #self._group.cities > 0 then
				AddSubMenuItem( "Instruct City", CharacterProposal.CITY_INSTRUCT )
			end
			
		elseif self.flow == MeetingFlow.CITY_AFFAIRS_FLOW then
			if self._city:CanBuild() then			
				AddSubMenuItem( "Build Construction", CharacterProposal.CITY_BUILD )
			end
			if self._city:CanFarm() then
				AddSubMenuItem( "Farm City", CharacterProposal.CITY_FARM )
			end
			if self._city:CanInvest() then
				AddSubMenuItem( "Invest City", CharacterProposal.CITY_INVEST )
			end
			AddSubMenuItem( "Patrol", CharacterProposal.CITY_PATROL )
			AddSubMenuItem( "Collect Tax", CharacterProposal.CITY_LEVY_TAX )
			
		elseif self.flow == MeetingFlow.HUMAN_RESOURCE_FLOW then
			AddSubMenuItem( "Dispatch Character", CharacterProposal.HR_DISPATCH )
			AddSubMenuItem( "Call Character", CharacterProposal.HR_CALL )
			AddSubMenuItem( "Hire Character", CharacterProposal.HR_HIRE )
			AddSubMenuItem( "Exile Character", CharacterProposal.HR_EXILE )
			AddSubMenuItem( "Promote Character", CharacterProposal.HR_PROMOTE )
			
		elseif self.flow == MeetingFlow.WAR_PREPAREDNESS_FLOW then		
			if self._city:CanRecruit() then
				AddSubMenuItem( "Recruit Troop", CharacterProposal.RECRUIT_TROOP )
			end	
			AddSubMenuItem( "Lead Troop", CharacterProposal.LEAD_TROOP )
			local nonCorpsTroops = self._city:GetNumOfNonCorpsTroop()
			if self._city:CanEstablishCorps() then
				AddSubMenuItem( "Create Crops (" .. nonCorpsTroops .. " non-corps )", CharacterProposal.ESTABLISH_CORPS )
			end
			if self._city:CanReinforceCorps() then
				AddSubMenuItem( "Reinforce Crops", CharacterProposal.REINFORCE_CORPS )
			end
			if self._city:CanTrainCorps() then
				AddSubMenuItem( "Train Crops", CharacterProposal.TRAIN_CORPS )
			end
			if self._city:CanRegroupCorps() then
				AddSubMenuItem( "Regroup Crops", CharacterProposal.REGROUP_CORPS )
			end
			if self._city:CanDispatchCorps() then
				AddSubMenuItem( "Dispatch Crops", CharacterProposal.DISPATCH_CORPS )
			end			
			
		elseif self.flow == MeetingFlow.MILITARY_FLOW then
			if #self._city:GetAdjacentBelligerentCityList() > 0 then
				AddSubMenuItem( "Attack City", CharacterProposal.ATTACK_CITY )
			end
			if #self._group:GetReachableBelligerentCityList() > 0 then
				AddSubMenuItem( "Expedition", CharacterProposal.EXPEDITION )
			end
			if #menus == 0 then
				ShowText( "No enemy city in range" )
			end
		end
		
		if self.status == MeetingStatus.EXECUTE_PROPOSAL then
			if self.type == MeetingType.GROUP_DISCUSS or self.type == MeetingType.CITY_DISCUSS then
				if self.flow ~= MeetingFlow.GROUP_DISCUSS or self.flow ~= MeetingFlow.CITY_DISCUSS then
					table.insert( menus, { c = index, content = "Back", fn = function ()
						if self.type == MeetingType.GROUP_DISCUSS then
							self.flow = MeetingFlow.GROUP_DISCUSS_FLOW
						elseif self.type == MeetingType.CITY_DISCUSS then
							self.flow = MeetingFlow.CITY_DISCUSS_FLOW
						end
						self:UpdateStatus( MeetingStatus.EXECUTE_PROPOSAL )
					end	} )
					index = index + 1
				else				
					table.insert( menus, { c = index, content = "View proposal", fn = function ()
						if self.type == MeetingType.GROUP_DISCUSS then
							self.flow = MeetingFlow.GROUP_DISCUSS_FLOW
						elseif self.type == MeetingType.CITY_DISCUSS then
							self.flow = MeetingFlow.CITY_DISCUSS_FLOW
						end
						self.subFlow = MeetingSubFlow.NONE
						self:UpdateStatus( MeetingStatus.COLLECT_PROPOSAL )
					end	} )
					index = index + 1				
				end
				table.insert( menus, { c = index, content = "End Meeting", fn = function ()
					self:UpdateStatus( MeetingStatus.END_MEETING )
				end	} )
				index = index + 1
			else
				table.insert( menus, { c = index, content = "Next Topic", fn = function ()
					self:UpdateStatus( MeetingStatus.END_TOPIC )
				end	} )
				index = index + 1
			end
			g_menu:PopupMenu( menus, self.title .. " Execute Proposal" )

		elseif self.status == MeetingStatus.SUBMIT_PROPOSAL then
			table.insert( menus, { c = index, content = "No Proposal", fn = function ()
				self._chara:SubmitProposal( { type = CharacterProposal.PLAYER_GIVEUP_PROPOSAL, proposer = chara } )
				self:UpdateStatus( nextStatus )
			end } )
			index = index + 1
			g_menu:PopupMenu( menus, self.title .. " Submit Proposal" )
		end
	else
		if debugMeeting then InputUtility_Pause( "AI Leader Submit proposal" ) end
		chara:ClearProposal()
		Proposal_Submit( chara, { city = self._city, flow = self.flow } )
		self._proposal = chara:GetProposal()
		self:UpdateStatus( MeetingStatus.CONFIRM_PROPOSAL )
	end
end

function Meeting:NextFlow()
	self._proposal = nil	
	if self.type == MeetingType.GROUP or self.type == MeetingType.CITY then
		for k, chara in ipairs( self._participants ) do
			chara:ClearProposal()
		end
		self.flow = self.flow + 1
		--ShowText( "Flow=", MathUtility_FindEnumName( MeetingFlow, self.flow ) )
		if self.flow ~= MeetingFlow.END 
		and self.flow ~= MeetingFlow.GROUP_DISCUSS_FLOW_END
		and self.flow ~= MeetingFlow.CITY_DISCUSS_FLOW_END then
			self:UpdateStatus( MeetingStatus.START )
		end
	elseif self.type == MeetingType.GROUP_DISCUSS or self.type == MeetingType.CITY_DISCUSS then
		if self._leader.stamina >= CharacterParams.STAMINA["SUBMIT_PROPOSAL"]
		or self._leader.stamina >= CharacterParams.STAMINA["ACCEPT_PROPOSAL"] then			
			if self.type == MeetingType.GROUP_DISCUSS then
				self.flow = MeetingFlow.GROUP_DISCUSS_FLOW
			elseif self.type == MeetingType.CITY_DISCUSS then
				self.flow = MeetingFlow.CITY_DISCUSS_FLOW
			end	
			self:UpdateStatus( MeetingStatus.START )
		else
			--end meeting
		end
	end	
end

function Meeting:ProcessSubMenu()
	local _chara = self._game.player
	
	function SelectBuildConstruction( city )
		local sel = nil
		local menus = {}
		for k, constr in ipairs( city:GetBuildList() ) do
			table.insert( menus, { c = k, content = constr.name, fn = function()
				sel = constr
			end } )
		end
		g_menu:PopupMenu( menus, "Choose Construction" )
		return sel
	end
	
	function SelectNonCapitalCity( group )
		local sel = nil
		local index = 1
		local menus = {}
		for k, city in ipairs( group.cities ) do
			if city ~= group:GetCapital() then
				table.insert( menus, { c = index, content = city.name .. " @" .. MathUtility_FindEnumName( CityInstruction, city.instruction ), fn = function()
					sel = city
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose City" )
		return sel
	end
	
	function SelectCityInstruction()
		local sel = nil
		index = 1
		local menus = {}
		for k, instr in pairs( CityInstruction ) do
			table.insert( menus, { c = index.. "", content = k, fn = function()
				sel = instr
			end } )
			index = index + 1
		end
		g_menu:PopupMenu( menus, "Choose Instruction" )
		return sel
	end
	
	function SelectMultiCityTroops( city )
		local sels = {}
		local menus = {}
		local index = 1
		for k, troop in ipairs( city.troops ) do
			if not troop:GetCorps() then
				table.insert( menus, { c = index, content = troop.name, fn = function()
					if MathUtility_IndexOf( sels, troop ) then
						MathUtility_Remove( sels, troop )
					else
						table.insert( sels, troop )
					end
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMultiSelMenu( menus, "Choose Troops", 1 )
		return sels
	end
	
	function SelectCityRecruitTroop( city )
		local sel = nil
		local menus = {}
		for k, troop in ipairs( city:GetRecruitList() ) do
			table.insert( menus, { c = k, content = troop.name, data = troop, fn = function()				
				sel = troop
			end } )
		end
		g_menu:PopupMenu( menus, "Choose Troop" )
		return sel
	end
	
	function SelectCityVacancyCorps( city )
		local sel = nil
		local menus = {}
		for k, corps in ipairs( city:GetVacancyCorpsList() ) do
			table.insert( menus, { c = k, content = corps.name, data = corps, fn = function()
				sel = corps
			end } )
		end
		g_menu:PopupMenu( menus, "Choose Corps" )
		return sel
	end
	
	function SelectCityUnderstaffedCorps( city )
		local sel = nil
		local menus = {}
		for k, corps in ipairs( city:GetVacancyCorpsList() ) do
			table.insert( menus, { c = k, content = corps.name, data = corps, fn = function()
				sel = corps
			end } )
		end
		g_menu:PopupMenu( menus, "Choose Corps" )
		return sel	
	end
	
	function SelectCityUntraiedCorps( city )
		local sel = nil
		local menus = {}
		for k, corps in ipairs( city:GetUntrainedCorpsList() ) do
			table.insert( menus, { c = k, content = corps.name, data = corps, fn = function()
				sel = corps
			end } )
		end
		g_menu:PopupMenu( menus, "Choose Corps" )
		return sel
	end
	
	function SelectCityNonCorpsTroops( city )
		local sels = {}
		local menus = {}
		for k, troop in ipairs( city:GetNonCorpsTroopList() ) do
			table.insert( menus, { c = k, content = troop.name, data = troop, fn = function()				
				if MathUtility_IndexOf( SelectTroops, troop ) then
					MathUtility_Remove( SelectTroops, troop )
				else
					table.insert( sels, troop )
				end
			end } )
		end
		g_menu:PopupMultiSelMenu( menus, "Choose troops to regroup corps", 1 )
		return sels
	end
	
	function SelectCityIdleCorps( city )
		local sel = nil
		local menus = {}
		for k, corps in ipairs( city:GetIdleCorpsList() ) do
			table.insert( menus, { c = k, content = corps.name, data = corps, fn = function()
				sel = corps
			end } )
		end
		g_menu:PopupMenu( menus, "Choose Corps" )
		return sel
	end
	
	function SelectOtherCity( currentCity )
		local sel = nil
		local menus = {}
		local index = 1
		for k, city in ipairs( currentCity:GetGroup().cities ) do
			if city ~= currentCity then
				table.insert( menus, { c = index, content = city.name .. " @" .. MathUtility_FindEnumName( CityInstruction, city.instruction ), fn = function()
					sel = city
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose City" )
		return sel
	end
	
	function SelectFreeChara( city )
		local sel = nil
		local menus = {}
		local index = 1
		for k, chara in ipairs( city.charas ) do
			if chara:IsFree() then
				table.insert( menus, { c = index, content = chara.name .. "  "..MathUtility_FindEnumName( CharacterJob, chara.job), fn = function()
					sel = chara
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose Character" )
		return sel
	end
	
	function SelectDispatchTargetCity( currentCity )
		local sel = nil
		local menus = {}
		local index = 1
		for k, city in ipairs( currentCity:GetGroup().cities ) do
			if city ~= currentCity and city:CanDispatch() then
				table.insert( menus, { c = index, content = city.name, fn = function()
					sel = city
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose City" )
		return sel
	end
	
	function SelectOutCharaExistCities( group )
		local sels = nil
		local menus = {}
		local index = 1
		local cities = {}
		for k, chara in ipairs( g_statistic.outCharacterList ) do
			local city = chara:GetLocation()
			if city and city:GetGroup() == group then
				if cities[city.id] then
					cities[city.id].count = cities[city.id].count + 1
				else
					cities[city.id] = { city = city, count = 1 }
				end
			end
		end
		for k, data in pairs( cities ) do
			table.insert( menus, { c = index, content = data.city.name .. "+" .. data.count, fn = function()
				sel = data.city
			end } )
			index = index + 1
		end
		g_menu:PopupMenu( menus, "Choose City" )
		return sel
	end
	
	function SelectCityOutChara( city )
		local sel = nil
		local menus = {}
		local index = 1
		for k, chara in ipairs( g_statistic.outCharacterList ) do
			if chara:GetLocation() == city then
				table.insert( menus, { c = index, content = chara.name, fn = function()
					sel = chara
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose Chara" )
		return sel	
	end
	
	function SelectFreeCharaCity( currentCity )
		local sel = nil
		local menus = {}
		local index = 1
		for k, city in ipairs( currentCity:GetGroup().cities ) do
			local number = city:GetNumOfFreeChara()
			if city ~= currentCity and number > 0 then
				table.insert( menus, { c = index, content = city.name .. "("..number..")", fn = function()
					sel = city
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose City" )
		return sel
	end
	
	function SelectNotLeaderChara( city )
		local sel = nil
		local index = 1
		local menus = {}
		for k, chara in ipairs( city.charas ) do
			if chara:CanLead() then
				table.insert( menus, { c = index, content = chara.name .. "  "..MathUtility_FindEnumName( CharacterJob, chara.job), fn = function()
					sel = chara
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose Character" )
		return sel
	end
	
	function SelectNonLeaderTroop( city )
		local sel = nil
		local index = 1
		local menus = {}			
		for k, troop in ipairs( city.troops ) do
			if not troop:GetLeader() then
				table.insert( menus, { c = index, content = troop.name .. "+" .. troop.number, fn = function()
					sel = troop
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose Troop" )
		return sel
	end
	
	function SelectAdjacentEnemyCity( city )
		local sel = nil
		local menus = {}
		for k, city in ipairs( city:GetAdjacentBelligerentCityList() ) do
			table.insert( menus, { c = k, content = city.name, fn = function()
				sel = city
			end } )
		end
		g_menu:PopupMenu( menus, "Choose City" )
		return sel
	end
	
	function SelectCityIdleCorps( city )
		local sel = nil
		local menus = {}
		for k, corps in ipairs( city:GetIdleCorpsList() ) do
			table.insert( menus, { c = k  .. "", content = corps.name, fn = function()
				sel = corps
			end } )
		end
		g_menu:PopupMenu( menus, "Choose Corps" )
		return sel
	end
	
	function SelectDiplomacyMethod( relation, group, target )
		if not relation then return nil end	
		local sel = nil
		local menus = {}
		local index = 1
		--MathUtility_Dump( relation )
		for method = DiplomacyMethod.FRIENDLY, DiplomacyMethod.SURRENDER do
			if relation:IsMethodValid( method, group, target ) then
				local prob = EvaluateDiplomacySuccessRate( method, relation, group, target )
				table.insert( menus, { c = index, content = MathUtility_FindEnumName( DiplomacyMethod, method ) .. " Prob=" .. prob, fn = function()
					sel = method
				end } )
				index = index + 1
			end
		end
		--[[
		table.insert( menus, { c = index, content = "Back", fn = function()
			self._leader:ClearProposal()
			self._nextStatus = MeetingStatus.EXECUTE_PROPOSAL
		end } )
		]]
		g_menu:PopupMenu( menus, "Choose Corps" )
		return sel
	end
	
	function SelectResearchTech( group )
		local sel = nil
		local menus = {}
		for k, tech in ipairs( group._canResearchTechs ) do
			table.insert( menus, { c = k, content = "Research [" .. tech.name .. "]", fn = function ()
				sel = tech
			end } )
		end
		g_menu:PopupMenu( menus, "Choose Tech" )
		return sel
	end
	
	function SelectPromoteChara( group )
		local sel = nil
		local index = 1
		local menus = {}
		for k, chara in ipairs( group.charas ) do
			if #chara:GetPromoteList() > 0 then
				table.insert( menus, { c = index, content = chara.name.. "  "..MathUtility_FindEnumName( CharacterJob, chara.job), fn = function ()
					sel = chara
				end } )
				index = index + 1
			end
		end
		g_menu:PopupMenu( menus, "Choose Chara" )
		return sel
	end
	
	function SelectCharaPromotionJob( chara )
		local sel = nil
		local menus = {}
		local index = 1
		local list = chara:GetPromoteList()
		for k, job in ipairs( list ) do
			table.insert( menus, { c = k, content = MathUtility_FindEnumName( CharacterJob, job ), fn = function ()
				sel = job
			end } )			
		end
		g_menu:PopupMenu( menus, "Choose Job" )
		return sel
	end
	
	-----------------------------------
	
	_chara:ClearProposal()
	
	--Internal affairs
	if self.subFlow == MeetingSubFlow.SUB_CITY_BUILD then
		local SelectConstruction = SelectBuildConstruction( self._city )
		if SelectConstruction then
			_chara:SubmitProposal( { type = CharacterProposal.CITY_BUILD, target = self._city, data = SelectConstruction, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_CITY_INVEST then
		_chara:SubmitProposal( { type = CharacterProposal.CITY_INVEST, target = self._city, proposer =_chara, actor = _actor } )
	elseif self.subFlow == MeetingSubFlow.SUB_CITY_FARM then
		_chara:SubmitProposal( { type = CharacterProposal.CITY_FARM, target = self._city, proposer =_chara, actor = _actor } )
	elseif self.subFlow == MeetingSubFlow.SUB_CITY_PATROL then
		_chara:SubmitProposal( { type = CharacterProposal.CITY_PATROL, target = self._city, proposer =_chara, actor = _actor } )
	elseif self.subFlow == MeetingSubFlow.SUB_CITY_LEVY_TAX then
		_chara:SubmitProposal( { type = CharacterProposal.CITY_LEVY_TAX, target = self._city, proposer =_chara, actor = _actor } )
	elseif self.subFlow == MeetingSubFlow.SUB_CITY_INSTRUCT then
		local SelectCity = SelectNonCapitalCity( self._group )
		local SelectInstruction = SelectCityInstruction()
		if SelectCity and SelectInstruction ~= nil then
			_chara:SubmitProposal( { type = CharacterProposal.CITY_INSTRUCT, target = SelectCity, data = SelectInstruction, proposer =_chara, actor = _actor } )
		end
		
	--Human resource
	elseif self.subFlow == MeetingSubFlow.SUB_HR_DISPATCH then
		local SelectChara = SelectFreeChara( self._city )
		local SelectCity = SelectDispatchTargetCity( self._city )
		if SelectChara and SelectCity then
			_chara:SubmitProposal( { type = CharacterProposal.HR_DISPATCH, data = SelectCity, target = SelectChara, proposer = _chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_HR_CALL then
		local SelectCity = SelectFreeCharaCity( self._city )
		local SelectChara = SelectCity and SelectFreeChara( SelectCity ) or nil
		if SelectChara then
			_chara:SubmitProposal( { type = CharacterProposal.HR_CALL, data = self._city, target = SelectChara, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_HR_HIRE then
		local SelectCity = SelectOutCharaExistCities( self._group )
		local SelectChara = SelectCity and SelectCityOutChara( SelectCity ) or nil
		if SelectChara then
			local proposal = { type = CharacterProposal.HR_HIRE, data = SelectCity, target = SelectChara, proposer =_chara, actor = _actor }			
			_chara:SubmitProposal( proposal )
		end	
	elseif self.subFlow == MeetingSubFlow.SUB_HR_EXILE then
		local SelectCity = SelectFreeCharaCity( self._city )
		local SelectChara = SelectCity and SelectFreeChara( SelectCity ) or nil
		if SelectChara then
			local proposal = { type = CharacterProposal.HR_EXILE, data = SelectCity, target = SelectChara, proposer =_chara, actor = _actor }			
			_chara:SubmitProposal( proposal )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_HR_PROMOTE then
		local SelectChara = SelectPromoteChara( self._group )
		local SelectJob = SelectChara and SelectCharaPromotionJob( SelectChara ) or nil
		if SelectJob then
			_chara:SubmitProposal( { type = CharacterProposal.HR_PROMOTE, data = SelectCity, target = SelectChara, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_HR_LOOKFORTALENT then
		_chara:SubmitProposal( { type = CharacterProposal.HR_LOOKFORTALENT, data = SelectCity, proposer =_chara, actor = _actor } )
		
	
	--War preparedness
	elseif self.subFlow == MeetingSubFlow.SUB_ESTABLISH_CORPS then
		local SelectTroops = SelectMultiCityTroops( self._city )
		if #SelectTroops > 0 then
			_chara:SubmitProposal( { type = CharacterProposal.ESTABLISH_CORPS, data = SelectTroopsself._city, target = SelectTroops, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_RECRUIT_TROOP then
		--Select troop
		local SelectTroop = SelectCityRecruitTroop( self._city )		
		if SelectTroop then
			_chara:SubmitProposal( { type = CharacterProposal.RECRUIT_TROOP, data = self._city, target= SelectTroop, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_REGROUP_CORPS then
		local SelectCorps = SelectCityVacancyCorps( self._city )
		local SelectTroops = SelectCityNonCorpsTroops( self._city )		
		if SelectCorps and #SelectTroops > 0 then
			_chara:SubmitProposal( { type = CharacterProposal.REGROUP_CORPS, data = SelectCorps, target = SelectTroops, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_REINFORCE_CORPS then
		local SelectCorps = SelectCityUnderstaffedCorps( self._city )
		if SelectCorps and #SelectTroops > 0 then
			_chara:SubmitProposal( { type = CharacterProposal.REINFORCE_CORPS, target = SelectCorps, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_TRAIN_CORPS then
		local SelectCorps = SelectCityUntraiedCorps( self._city )
		if SelectCorps then
			_chara:SubmitProposal( { type = CharacterProposal.TRAIN_CORPS, target = SelectCorps, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_DISPATCH_CORPS then
		--Select corps
		local SelectCorps = SelectCityIdleCorps( self._city )		
		local SelectCity = SelectOtherCity( self._city )
		if SelectCorps and SelectCity then
			_chara:SubmitProposal( { type = CharacterProposal.DISPATCH_CORPS, data = SelectCorps, target = SelectCity, proposer =_chara, actor = _actor } )
		end
	elseif self.subFlow == MeetingSubFlow.SUB_LEAD_TROOP then
		local SelectChara = SelectNotLeaderChara( self._city )
		local SelectTroop = SelectChara and SelectNonLeaderTroop( self._city ) or nil
		if SelectTroop then
			_chara:SubmitProposal( { type = CharacterProposal.LEAD_TROOP, target = SelectTroop, data = SelectChara, proposer =_chara, actor = _actor } )
		end
		
	--Attack Sub Menu
	elseif self.subFlow == MeetingSubFlow.SUB_ATTACK_CITY or self.subFlow == MeetingSubFlow.SUB_EXPEDITION then
		local SelectCity = SelectAdjacentEnemyCity( self._city )
		local SelectCorps = SelectCity and SelectCityIdleCorps( sel._city ) or nil
		if SelectCorps then
			if self.subFlow == MeetingSubFlow.SUB_ATTACK_CITY then
				_chara:SubmitProposal( { type = CharacterProposal.ATTACK_CITY, target = SelectCity, data = SelectCorps, proposer =_chara, actor = _actor } )
			elseif self.subFlow == MeetingSubFlow.SUB_EXPEDITION then
				_chara:SubmitProposal( { type = CharacterProposal.EXPEDITION, target = SelectCity, data = SelectCorps, proposer =_chara, actor = _actor } )
			end
		end
	
	--Tech SubMenu
	elseif self.subFlow == MeetingSubFlow.SUB_TECH_RESEARCH then
		local SelectTech = SelectResearchTech( self._group )
		if SelectTech then
			_chara:SubmitProposal( { type = CharacterProposal.TECH_RESEARCH, data = _chara:GetGroup(), target = SelectTech, proposer =_chara, actor = _actor } )
		else
			ShowText( "No tech can research" )
		end
	
	--Diplomacy SubMenu
	elseif self.subFlow == MeetingSubFlow.SUB_DIPLOMACY_AFFAIRS then
		ShowText( "dip sub")
		local relation = self._group:GetGroupRelation( self._target.id )
		local SelectMethod = SelectDiplomacyMethod( relation, self._group, self._target )		
		if SelectMethod then
			local proposalType = CharacterProposal.DIPLOMACY_AFFAIRS
			if SelectMethod == DiplomacyMethod.FRIENDLY then
				proposalType = CharacterProposal.FRIENDLY_DIPLOMACY
			elseif SelectMethod == DiplomacyMethod.THREATEN then
				proposalType = CharacterProposal.THREATEN_DIPLOMACY
			elseif SelectMethod == DiplomacyMethod.ALLY then
				proposalType = CharacterProposal.ALLY_DIPLOMACY
			elseif SelectMethod == DiplomacyMethod.DECLARE_WAR then
				proposalType = CharacterProposal.DECLARE_WAR_DIPLOMACY
			elseif SelectMethod == DiplomacyMethod.MAKE_PEACE then
				proposalType = CharacterProposal.MAKE_PEACE_DIPLOMACY
			elseif SelectMethod == DiplomacyMethod.BREAK_CONTRACT then
				proposalType = CharacterProposal.BREAK_CONTRACT_DIPLOMACY
			elseif SelectMethod == DiplomacyMethod.SURRENDER then
				proposalType = CharacterProposal.SURRENDER_DIPLOMACY
			end
			_chara:SubmitProposal( { type = proposalType, target = self._target, proposer =_chara, actor = _actor } )
		end
	end
	
	--Finish sub flow
	self.subFlow = MeetingSubFlow.NONE
	if self._nextStatus then
		local status = self._nextStatus
		self._nextStatus = nil
		self:UpdateStatus( status )
	else
		if self.type == MeetingType.GROUP_DISCUSS or self.type == MeetingType.CITY_DISCUSS then
			self._proposal = _chara:GetProposal()
			if self._proposal then
				self:UpdateStatus( MeetingStatus.CONFIRM_PROPOSAL )
			else
				self:UpdateStatus( MeetingStatus.END_PROPOSAL )
			end
		else
			if self._game:IsPlayer( self._leader ) then			
				self:UpdateStatus( MeetingStatus.END_TOPIC )
			else
				self:UpdateStatus( MeetingStatus.SELECT_PROPOSAL )
			end
		end
	end
end

function Meeting:CanCollectProposal()
	for k, chara in ipairs( self._participants ) do
		if chara:CanSubmitProposal() then
			return true
		end
	end
	return false
end

function Meeting:StartTopic()	
	self.title = ""
	
	if self.flow == MeetingFlow.GROUP_DISCUSS_FLOW or self.flow == MeetingFlow.CITY_DISCUSS_FLOW then
		self.title = "Discuss"
		self.title = self.title .. " " .. ( self._game.player and self._game.player.name .. " st= ".. self._game.player.stamina or "" ) .. " col=" .. ( self._hasCollectProposal and "true" or "false" )		
		if self._hasCollectProposal == false then								
			self._hasCollectProposal = true
			self._leader:SubmitProposal( { type = CharacterProposal.AI_COLLECT_PROPOSAL, proposer =self._leader } )						
			self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
		else
			self:UpdateStatus( MeetingStatus.COLLECT_PROPOSAL )
		end
		return
	end
	
	--old version
	if self.flow == MeetingFlow.TECH_FLOW then
		self.title = "Technique"
	elseif self.flow == MeetingFlow.DIPLOMACY_FLOW then
		self.title = "Diplomacy"-- .. " pow=" .. self._group:GetPower()
		--self._group:DumpDiplomacyMethod()
	elseif self.flow == MeetingFlow.CITY_AFFAIRS_FLOW then
		--self._city:Dump()
		self.title = "City Affairs"		
	elseif self.flow == MeetingFlow.HUMAN_RESOURCE_FLOW then
		--self._city:Dump()
		self.title = "Human Resource"
	elseif self.flow == MeetingFlow.WAR_PREPAREDNESS_FLOW then
		--self._city:Dump()
		self.title = "War Preparedness"
	elseif self.flow == MeetingFlow.MILITARY_FLOW then
		--self._city:Dump()
		self.title = "Military Plan"
	end
	
	if self._game:IsPlayer( self._leader ) then
		--InputUtility_Pause( "!!!!!!!!!!!!!!!!!!!!!!!!!!!" )
		--leader
		self.title = self.title .. " " .. self._leader.name .. " st= ".. self._leader.stamina
		
		local menus = {}
		local index = 1
		
		if #self._participants > 0 and self:CanCollectProposal() then
			table.insert( menus, { c = index, content = "Collect Proposal", fn = function ()
				self._leader:SubmitProposal( { type = CharacterProposal.AI_COLLECT_PROPOSAL, proposer =self._leader } )			
				self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
			end } )
			index = index + 1
		end
		
		table.insert( menus, { c = index, content = "Submit My Proposal", fn = function ()
			self._leader:SubmitProposal( { type = CharacterProposal.PLAYER_EXECUTE_PROPOSAL, proposer = self._leader } )
			self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
		end } )
		index = index + 1
		
		table.insert( menus, { c = index, content = "Browse Information", fn = function ()
			self._group:Dump()
		end } )
		index = index + 1		
		
		if self.type == MeetingType.GROUP_DISCUSS or self.type == MeetingType.CITY_DISCUSS then
			table.insert( menus, { c = index, content = "End Meeting", fn = function ()
				self._leader:SubmitProposal( { type = CharacterProposal.END_MEETING, proposer = self._leader } )
				self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
			end } )
			index = index + 1
		else
			table.insert( menus, { c = index, content = "Next Topic", fn = function ()
				self._leader:SubmitProposal( { type = CharacterProposal.NEXT_TOPIC, proposer = self._leader } )
				self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
			end } )
			index = index + 1
		end

		g_menu:PopupMenu( menus, self.title )
	else
		InputUtility_Pause( "*** Start Topic [".. self.title .. "] " )
		Proposal_Submit( self._leader, { city = self._city, flow = self.flow } )
		self:UpdateStatus( MeetingStatus.MAKE_CHOICE )
	end
end

function Meeting:UpdateStatus( status )	
	--ShowText( "Current Status", MathUtility_FindEnumName( MeetingStatus, self.status ), MathUtility_FindEnumName( MeetingStatus, status ) )
	self.status = status
	if self.status == MeetingStatus.START then
		self:StartTopic()
	elseif self.status == MeetingStatus.MAKE_CHOICE then
		self:MakeChoiceFlow( self._leader )
	elseif self.status == MeetingStatus.COLLECT_PROPOSAL then
		self:CollectProposalFlow( self._leader )
	elseif self.status == MeetingStatus.SUBMIT_PROPOSAL then
		self:SubmitProposalFlow( self._chara )
	elseif self.status == MeetingStatus.EXECUTE_PROPOSAL then
		self:SubmitProposalFlow( self._leader )
	elseif self.status == MeetingStatus.SELECT_PROPOSAL then
		self:SelectProposalFlow( self._leader )
	elseif self.status == MeetingStatus.CONFIRM_PROPOSAL then
		self:ConfirmProposalFlow( self._proposal )
	elseif self.status == MeetingStatus.SUBMENU then
		self:ProcessSubMenu()
	elseif self.status == MeetingStatus.END_PROPOSAL then		
		if self.type == MeetingType.GROUP_DISCUSS or self.type == MeetingType.CITY_DISCUSS then	
			self:NextFlow()
		else
			self._leader:ClearProposal()
			self:UpdateStatus( MeetingStatus.EXECUTE_PROPOSAL )
		end		
	elseif self.status == MeetingStatus.END_TOPIC then		
		if self.type == MeetingType.GROUP_DISCUSS or self.type == MeetingType.CITY_DISCUSS then
			self:UpdateStatus( MeetingStatus.END_MEETING )
		else
			self:NextFlow()
		end		
	elseif self.status == MeetingStatus.END_MEETING then
	end
end

-----------------------------

function Meeting:HoldGroupMeeting( game, group )
	self.type = MeetingType.GROUP_DISCUSS
	self._game   = game
	self._group  = group
	self._city   = self._group:GetCapital()
	self._leader = self._group:GetLeader()
	self._chara  = nil
	self._proposal = nil
	self._hasCollectProposal = false
	self._entrust = false
	
	--[[
	if group:GetLeader():GetAction() ~= CharacterAction.ATTEND_MEETING then
		Debug_Normal( "Group " .. NameIDToString( group ) .. " won't hold meeting" )
		return
	end
	]]
	
	local charaList = {}
	if group:GetCapital() and group:GetCapital():GetGroup() == group then
		--ShowText( "check group", group.name, group:GetCapital().name, #group:GetCapital().charas )
		group:GetCapital():ForeachChara( function ( chara )	
			if chara:IsAtHome() and not chara:IsGroupLeader() and not g_taskMng:GetTaskByActor( chara ) then
				-- In further, we should consider about no presence by ill or other reason
				table.insert( charaList, chara )
			end
		end )
	else
		--guerrilla not support now
	end
	self._participants = charaList	
	MathUtility_Shuffle( charaList )
	group:Dump()
	group:GetCapital():Dump()
	if #charaList == 0 then
		--print( "GroupMeeting Attend=", #charaList, group.name )
	end
	--ShowText( "++++++++++ Group Meeting Start ++++++++++++++++" )	
	self.acceptProposals = 0
	self.flow = MeetingFlow.GROUP_DISCUSS_FLOW
	self:UpdateStatus( MeetingStatus.START )
	if self.acceptProposals == 0 then
		--	print( group.name .. " noproposal", #charaList, #group:GetCapital().charas )
		--self._group:AcceptProposal( group.name .. " No Proposal " .. g_calendar:CreateCurrentDateDesc() )
	end
	--ShowText( "++++++++++ Group Meeting End ++++++++++++++++" )
	--ShowText( "" )	
	if not self._game:IsPlayer( self._leader ) and self._game.player and self._game.player:GetGroup() == group then
		InputUtility_Pause()
	end
	self.collectProposals = {}
end

function Meeting:HoldCityMeeting( game, city )
	if city:IsInSiege() then
		g_statistic:AcceptProposal( "In Siege" .. g_calendar:CreateCurrentDateDesc( true ), city )
		return
	end

	self.type = MeetingType.CITY_DISCUSS
	self._game = game
	self._group  = city:GetGroup()
	self._city = city
	self._leader = city:GetLeader()
	self._chara  = nil
	self._proposal = nil
	self._hasCollectProposal = false
	self._entrust = false

	if #city.charas == 0 then
		g_statistic:AcceptProposal( "No Chara " .. g_calendar:CreateCurrentDateDesc( true ), city )
		return
	end

	local charaList = {}	
	for k, chara in ipairs( city.charas ) do
		if chara:IsAtHome() and chara ~= city:GetLeader() then
			--print( chara.name .. " attend" )
			table.insert( charaList, chara )
			if chara == city:GetLeader() then
				self._leader = chara
			end
		end
	end
	
	if not self._leader then
		--print( city.name .. " no leader="..#city.charas )
		g_statistic:AcceptProposal( "No Leader " .. g_calendar:CreateCurrentDateDesc( true ), city )
		return
	end
	
	--if not self._leader then self._leader = leader end
	self._participants = charaList
	if #self._participants == 0 then
		g_statistic:AcceptProposal( "No Participant " .. g_calendar:CreateCurrentDateDesc( true ), city )
		return
	end
	MathUtility_Shuffle( charaList )
	
	--city:Dump( nil, true )
	self.acceptProposals = 0
	--print( city.name .. " CityMeeting Attend=", #charaList )
	--ShowText( "++++++++++ City Meeting Start ++++++++++++++++" )
	self.flow = MeetingFlow.CITY_DISCUSS_FLOW
	self:UpdateStatus( MeetingStatus.START )
	if self.acceptProposals == 0 then
		--	print( group.name .. " noproposal", #charaList, #group:GetCapital().charas )
		local cityList = city:GetAdjacentBelligerentCityList()
		local corpsList = city:GetPreparedToAttackCorpsList()
		self._group:AcceptProposal( "[" .. city.name .. "] NoProposal " .. " chara=" .. #charaList .. " adjaBelli="..#cityList .. " readyCorp=" ..#corpsList  .. " " .. g_calendar:CreateCurrentDateDesc( true, true ) )
		g_statistic:AcceptProposal( "No proposal " .. g_calendar:CreateCurrentDateDesc( true ), city )
	end
	--ShowText( "++++++++++ City Meeting End ++++++++++++++++" )
	--ShowText( "" )
	if not self._game:IsPlayer( self._leader ) and self._game.player and city:GetGroup() == self._game.player:GetGroup() then
		InputUtility_Pause()
	end
	
	self.collectProposals = {}
end