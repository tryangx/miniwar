function Proposal_CreateDesc( proposal, needDate )
	local content = ""
	--Tech
	if proposal.type == CharacterProposal.TECH_RESEARCH then
		content = "Research [" .. NameIDToString( proposal.target ) .. "]"

	--Diplomacy Relative
	elseif proposal.type == CharacterProposal.FRIENDLY_DIPLOMACY then
		content = "Friendly with [" .. NameIDToString( proposal.target ) .. "]("..proposal.target:GetPower()..")"  .. " Prob=" .. proposal.prob
	elseif proposal.type == CharacterProposal.THREATEN_DIPLOMACY then
		content = "Threaten with [" .. NameIDToString( proposal.target ) .. "]("..proposal.target:GetPower()..")"  .. " Prob=" .. proposal.prob
	elseif proposal.type == CharacterProposal.ALLY_DIPLOMACY then
		content = "Ally with [" .. NameIDToString( proposal.target ) .. "]("..proposal.target:GetPower()..")"  .. " Prob=" .. proposal.prob
	elseif proposal.type == CharacterProposal.MAKE_PEACE_DIPLOMACY then
		content = "Make peace with [" .. NameIDToString( proposal.target ) .. "]("..proposal.target:GetPower()..")"  .. " Prob=" .. proposal.prob
	elseif proposal.type == CharacterProposal.DECLARE_WAR_DIPLOMACY then
		content = "Declare war to [" .. NameIDToString( proposal.target ) .. "]("..proposal.target:GetPower()..")"  .. " Prob=" .. proposal.prob
	elseif proposal.type == CharacterProposal.BREAK_CONTRACT_DIPLOMACY then
		content = "Break contract with [" .. NameIDToString( proposal.target ) .. "]("..proposal.target:GetPower()..")"  .. " Prob=" .. proposal.prob
	elseif proposal.type == CharacterProposal.SURRENDER_DIPLOMACY then
		content = "Surrender to [" .. NameIDToString( proposal.target ) .. "]("..proposal.target:GetPower()..")"  .. " Prob=" .. proposal.prob
	
	--Internal affairs
	elseif proposal.type == CharacterProposal.CITY_INVEST then
		content = "Invest " .. " in ["..NameIDToString( proposal.target ).."]" 
	elseif proposal.type == CharacterProposal.CITY_FARM then
		content = "Farm " .. " in ["..NameIDToString( proposal.target ).."]" 
	elseif proposal.type == CharacterProposal.CITY_PATROL then
		content = "Patrol " .. " in ["..NameIDToString( proposal.target ).."]" 
	elseif proposal.type == CharacterProposal.CITY_LEVY_TAX then
		content = "Collect Tax" .. " in ["..NameIDToString( proposal.target ).."]" 
	elseif proposal.type == CharacterProposal.CITY_BUILD then	
		content = "Build [" .. proposal.data.name .. "]" .. " in ["..NameIDToString( proposal.target ).."]" 
	elseif proposal.type == CharacterProposal.CITY_INSTRUCT then
		content = "Instruct [" .. NameIDToString( proposal.target ) .. "]" .. " to [".. MathUtility_FindEnumName( CityInstruction, proposal.data ) .."]" 
		
	--Human resource
	elseif proposal.type == CharacterProposal.HR_DISPATCH then
		content = "Dispatch [" .. NameIDToString( proposal.target ) .. "] to [".. proposal.data.name .. "]" 
	elseif proposal.type == CharacterProposal.HR_CALL then
		content = "Call [" .. NameIDToString( proposal.target ) .. "] to [".. proposal.data.name .. "]" 
	elseif proposal.type == CharacterProposal.HR_HIRE then
		content = "Hire [" .. NameIDToString( proposal.target ) .. "] in [".. proposal.data.name .. "]" 
	elseif proposal.type == CharacterProposal.HR_EXILE then
		content = "Exile [" .. NameIDToString( proposal.target ) .. "] in [".. proposal.data.name .. "]" 
	elseif proposal.type == CharacterProposal.HR_PROMOTE then
		content = "Promote [" .. NameIDToString( proposal.target ) .. "] in [".. proposal.data.name .. "]" 
	elseif proposal.type == CharacterProposal.HR_LOOKFORTALENT then
		content = "Look for Talent in [".. proposal.data.name .. "]" 
		
		
	--War preparedness
	elseif proposal.type == CharacterProposal.ESTABLISH_CORPS then
		content = "Establish Corps " .. " in ["..proposal.data.name.."]" 	
	elseif proposal.type == CharacterProposal.LEAD_TROOP then
		content = "Lead [" .. NameIDToString( proposal.target ) .. "] with [".. proposal.data.name .. "]" 
	elseif proposal.type == CharacterProposal.RECRUIT_TROOP then
		content = "Recruit [".. NameIDToString( proposal.target ) .. "]" .. " in ["..proposal.data.name.."]" .. proposal.data:GetPower()
	elseif proposal.type == CharacterProposal.REINFORCE_CORPS then
		content = "Reinforce Corps [".. NameIDToString( proposal.target ) .. "]" 
	elseif proposal.type == CharacterProposal.TRAIN_CORPS then
		content = "Train Corps [".. NameIDToString( proposal.target ) .. "]" 
	elseif proposal.type == CharacterProposal.REGROUP_CORPS then
		local troopName = ""
		for k, troop in ipairs( proposal.target ) do
			troopName = troopName .. NameIDToString( troop ) .. " "
		end
		content = "Regroup Corps [".. NameIDToString( proposal.data ) .. "]" .. " with [".. troopName .."]" 

		
	--Military
	elseif proposal.type == CharacterProposal.HARASS_CITY then
		content = "Send [" .. NameIDToString( proposal.data ) .. "]"..proposal.data:GetPower().." Harass [".. NameIDToString( proposal.target ) .. "]"
	elseif proposal.type == CharacterProposal.EXPEDITION then
		content = "Send [" .. NameIDToString( proposal.data ) .. "] Go on expedition to [".. NameIDToString( proposal.target ) .. "] " 		
	elseif proposal.type == CharacterProposal.DISPATCH_CORPS then
		content = "Dispatch Corps [".. NameIDToString( proposal.data ) .. "]"..proposal.target:GetPower().." to ["..proposal.target.name.."]" 
	elseif proposal.type == CharacterProposal.CONTROL_PLOT then
		content = "Send [" .. NameIDToString( proposal.data ) .. "] Control "
	elseif proposal.type == CharacterProposal.SIEGE_CITY then
		local corpsName = ""
		for k, corps in ipairs( proposal.data ) do
			corpsName = corpsName .. NameIDToString( corps ) .. " "
		end
		content = "Send [" .. corpsName .. "] Siege City [".. NameIDToString( proposal.target ) .. "]"
	elseif proposal.type == CharacterProposal.DEFEND_CITY then
		local corpsName = ""
		for k, corps in ipairs( proposal.data ) do
			corpsName = corpsName .. NameIDToString( corps ) .. " "
		end
		content = "Send [" .. corpsName .. "] Defend City [".. NameIDToString( proposal.target ) .. "]"
	elseif proposal.type == CharacterProposal.MEET_ATTACK then
		content = "Send [" .. NameIDToString( proposal.data ) .. "] Meet Attack "
	elseif proposal.type == CharacterProposal.DISPATCH_TROOPS  then
		local troopName = ""
		for k, troop in ipairs( proposal.data ) do
			troopName = troopName .. NameIDToString( troop ) .. " "
		end
		content = "Dispatch Troop [" .. troopName .. "] move to ["..proposal.target.name.."]" 
	
	else
		content = "unknown " .. MathUtility_FindEnumName( CharacterProposal, proposal.type )	
	end
	
	content = content .. " By [" .. proposal.proposer.name .. "]" .. " At [" .. proposal.proposer:GetLocation().name .. "]"
	
	if needDate then content = content .. " date=" .. g_calendar:CreateCurrentDateDesc( true, true )	 end
	
	return content
end

function Proposal_DiscussCityAffairs( chara, data )
	g_charaAI:SetType( CharacterAICategory.CITY_DISCUSS_PROPOSAL )
	g_charaAI:SetBlackboard( data )
	g_charaAI:SetActor( chara )
	g_charaAI:Run()
end

function Proposal_Choice( chara, proposals )
	g_charaAI:SetActor( chara )
	g_charaAI:SetType( CharacterAICategory.AI_CHOICE_PROPOSAL )
	g_charaAI:SetBlackboard( { proposals = proposals } )
	g_charaAI:Run()
end

--Leader & None-Leader submit proposal
function Proposal_Submit( chara, data )
	g_charaAI:SetType( CharacterAICategory.AI_SUBMIT_PROPOSAL )
	g_charaAI:SetActor( chara )
	g_charaAI:SetBlackboard( data )
	g_charaAI:Run()
end