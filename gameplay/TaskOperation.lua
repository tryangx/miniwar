function GenerateTroop( id )
	local troop = g_troopDataMng:GenerateData( id, g_troopTableMng )
	troop.number  = troop.maxNumber
	return troop
end

function GenerateCorps( ids )
	local corps = g_corpsDataMng:NewData()
	g_corpsDataMng:SetData( corps.id, corps )

	for k, id in ipairs( ids ) do
		local troop = g_troopDataMng:GenerateData( id, g_troopTableMng )
		troop.number = troop.maxNumber
		corps:AddTroop( troop )
	end	

	return corps
end

--------------------------------------------
-- Capture Procedure

function AcceptSurrenderChara( group, chara, city )
	if not chara then return end
	local limit = QueryCityCharaLimit( city )
	if limit >= #city.charas then
		--cannot accept surrender chara, dismiss from troop
		--InputUtility_Pause( "cannot accept surrender "..chara.name..", "..city.name.." is full" )
		g_taskMng:TerminateTaskByActor( chara, "chara surrendered" )
		CharaLeadTroop( chara, nil )
		if chara:GetLocation() == city then
			CharaCaptured( chara )
		else
			chara:JoinCity( city:FindAdjacentCityByGroup( chara:GetGroup() ) )
			g_taskMng:IssueTaskCharaBackHome( chara )
		end
		return
	end	
	print( "Group " .. NameIDToString( group ) .. " Accept Surrender Chara=" .. NameIDToString( chara ) )
	CharaLeaveGroup( chara )
	CharaJoinGroup( chara, city )
end

function AcceptSurrenderTroop( group, troop, city )
	print( "Group " .. NameIDToString( group ) .. " Accept Surrender troop=" .. NameIDToString( troop ) .. "leader=" .. ( troop:GetLeader() and troop:GetLeader().name or "" ) )
	g_taskMng:TerminateTaskByActor( troop, "troop surrendered" )
	TroopLeaveGroup( troop )	
	--chara leave
	AcceptSurrenderChara( group, troop:GetLeader(), city )	
	TroopJoinGroup( troop, city, false )	
	troop:RefreshName()
end

function AcceptSurrenderCorps( group, corps, city )
	print( "Group " .. NameIDToString( group ) .. " Accept Surrender Corps " .. NameIDToString( corps ) )	
	g_taskMng:TerminateTaskByActor( corps, "corps surrendered" )
	CorpsLeaveGroup( corps )
	--all troops
	corps:ForeachTroop( function ( troop )
		AcceptSurrenderTroop( group, troop, city )
	end )
	CorpsJoinGroup( corps, city, false )
	corps:RefreshName()
end

function CaptureChara( group, chara, prisonCity )
	local isSurrender = Random_SyncGetRange( PolicyParams.MIN_PROB, PolicyParams.MAX_PROB ) < chara.trust
	local treateChara = group:GetPolicyTendency( PolicyType.TREAT_SURRENDER_CHARACTER )
	local isAcceptSurrender = Random_SyncGetRange( PolicyParams.MIN_PROB, PolicyParams.MAX_PROB ) < treateChara	
	if isAcceptSurrender and isSurrender then		
		AcceptSurrenderChara( group, chara, prisonCity )
	else
		print( "capture and killed chara=" .. chara.name )
		CharaDie( chara )
	end
end

function CaptureTroop( group, troop, prisonCity, isAcceptSurrender )
	if not isAcceptSurrender then
		local treate = group:GetPolicyTendency( PolicyType.TREAT_SURRENDER_SOLDIER )
		isAcceptSurrender = Random_SyncGetRange( PolicyParams.MIN_PROB, PolicyParams.MAX_PROB ) < treate
	end
	if isAcceptSurrender then
		--surrender
		AcceptSurrenderTroop( group, troop, prisonCity )
	else
		--kill
		local leader = troop:GetLeader()
		if leader then
			troop:LeadByChara( nil )
			CaptureChara( group, leader, prisonCity )
		end
		TroopNeutralize( troop )
	end
end

function CaptureCorps( group, corps, prisonCity )
	if not isAcceptSurrender then
		local treate = group:GetPolicyTendency( PolicyType.TREAT_SURRENDER_SOLDIER )
		isAcceptSurrender = Random_SyncGetRange( PolicyParams.MIN_PROB, PolicyParams.MAX_PROB ) < treate
	end
	if isAcceptSurrender then		
		AcceptSurrenderCorps( group, corps, prisonCity )
	else
		CorpsNeutralize( corps )
	end
end

function CaptureCity( group, city )
	g_statistic:CityFall( city, group )
	
	local originalGroup = city:GetGroup()	
	--print( "Group " .. NameIDToString( group ) .. "+chara=" .. #group.charas .. " Capture city " .. NameIDToString( city ) .. ( originalGroup and ( " oldgroup=" .. originalGroup.name.."+hascity="..#originalGroup.cities ) or "" ) )
	
	--[[
	quickSimulate = false
	group:Dump( true )
	originalGroup:Dump( true )
	city:Dump( nil, true )
	quickSimulate = true
	]]
	
	--Remove city from original group
	CityLeaveGroup( city )
	--Add city to owner group
	CityJoinGroup( city, group )

	if originalGroup then
		--Select new capital if necessary
		if city:IsCapital() then
			--first select new capital
			originalGroup:VoteCapital( city )
		end

		--Corps from Original group
		-- 1. Retreat to the latest city
		-- 2. Surrender or eliminate by the attacker's strategy	if 
		local adjaCities = {}
		if not isGroupFallen then
			city:ForeachAdjacentCity( function ( adjCity )
				if adjCity:GetGroup() == originalGroup then
					table.insert( adjaCities, adjCity )
				end
			end )
		end
		local corpsList  = MathUtility_Copy( city.corps )
		local troopsList = MathUtility_Filter( city.troops, function ( troop ) return not troop:GetCorps() end	)
		local charasList = MathUtility_Filter( city.charas, function( chara ) return not chara:GetTroop() end )
		local numberOfCity = #adjaCities
		if numberOfCity == 0 then
			print( "No adjacent city can retreat", #corpsList, #city.corps )
			--capture or fall
			local prisonCity = city		
			for k, corps in ipairs( corpsList ) do
				print( "captured corps=", NameIDToString(corps), corps:IsAtHome() )
				if corps:IsAtHome() then
					CaptureCorps( group, corps, prisonCity )
				else
					CorpsNeutralize( corps )
				end
			end

			--print( "time to capture isolation troop" )
			for k, troop in ipairs( troopsList ) do
				print( "capture troop", NameIDToString( troop ), troop:IsAtHome(), troop:GetLeader() and troop:GetLeader().name or "" )
				if troop:IsAtHome() then				
					CaptureTroop( group, troop, prisonCity )
				else
					TroopNeutralize( troop )
				end
			end
			
			--print( "time to capture isolation chara" )
			for k, chara in ipairs( charasList ) do
				--print( "capture chara", chara.name, chara:IsAtHome() )
				if chara:IsAtHome() then				
					CaptureChara( group, chara, prisonCity )
				else
					CharaLoseHome( chara )
				end
			end

			--InputUtility_Pause( city.name .. " from " .. originalGroup.name .. " Surrender to " .. group.name )
		else
			for k, corps in ipairs( corpsList ) do
				local index = Random_SyncGetRange( 1, numberOfCity )
				local retreatCity = adjaCities[index]
				--remove corps and troop from old city
				CorpsEsacpeToCity( corps, retreatCity )
			end
			for k, troop in ipairs( troopsList ) do
				--in city
				local index = Random_SyncGetRange( 1, numberOfCity )
				local retreatCity = adjaCities[index]
				print( NameIDToString( troop ) .. "@" .. troop:GetLocation().name .. " need to retreat to " .. retreatCity.name )
				--!!!should issue task
				TroopEscapeToCity( troop, retreatCity )
			end
			for k, chara in ipairs( charasList ) do
				local index = Random_SyncGetRange( 1, numberOfCity )
				local retreatCity = adjaCities[index]
				print( NameIDToString( chara) .. "@" .. chara:GetLocation().name .. " need to retreat to " .. retreatCity.name )
				CharaEscapeToCity( chara, retreatCity )
			end
			--InputUtility_Pause( city.name .. " from " .. originalGroup.name .. " Retreat to nearest city, attacked by " .. group.name )
		end

		local isGroupFallen = originalGroup:CheckIsFallen()	
		--Whether group is dead
		if isGroupFallen then
			originalGroup:Fall()
		else
			originalGroup:CheckLeader()
		end
	end
		
	--recover fallen group
	if #group.cities == 1 then
		for k, corps in ipairs( group.corps ) do
			if not corps:GetHome() then
				print( corps.name, "no home" )
				corps:JoinCity( city )
			end
		end
	end
	
	--InputUtility_Pause( NameIDToString(group), "chara2="..#group.charas )
end

-------------------------------------

function GroupResearch( group, tech )
	if not tech then ShowText( "tech is invalid" ) return end
	group.researchTechId = tech.id
	group.researchPoints = tech.points
	
	Debug_Normal( "Research " .. tech.name .. "[" ..tech.id .. "]" )
end

function GroupAttack( group, city, corps )
	--target is city	
	local corps = corps
	Order_Issue( corps, OrderType.ATTACK, { city = city } )
end

function GroupDispatch( group, chara, city )
	--[[
	for k, chara in ipairs(args.charaList ) do
		Order_Issue( chara, OrderType.DISPATCH, { city = city } )
	end
	]]
	Order_Issue( chara, OrderType.DISPATCH_CHARA, { city = city } )	
end

function InventTech( group, tech )
	group:InventTech( tech )
end

---------------------------------------------
--
-- City execution
--
---------------------------------------------
function CityJoinGroup( city, group )
	city:JoinGroup( group )
	group:AddCity( city )	
	--not include corps, troops, charas in the city
end

function CityLeaveGroup( city )
	local group = city:GetGroup()
	if group then group:RemoveCity( city ) end
end

--------------------------
-- Build in City
-- 
--
--------------------------
function CityBuildConstruction( city, construction )
	city:BuildConstruction( construction )			

	Debug_Normal( "Build [" .. construction.name .. "]("..construction.prerequisites.points..") in city [" .. city.name .. "]" )
end

--------------------------
-- Invest in City
-- 
--
--------------------------
function CityInvest( city )
	if not city:GetGroup() then Debug_Error( "City is not belong to any group" ) return end	
	city:Invest()
end

function CityFarm( city )
	if not city:GetGroup() then Debug_Error( "City is not belong to any group" ) return end
	city:Farm()
end

function CityLevyTax( city )
	if not city:GetGroup() then Debug_Error( "City is not belong to any group" ) return end
	local income = city:GetIncome()
	city:LevyTax( income )
end

function CityPatrol( city )
	if not city:GetGroup() then Debug_Error( "City is not belong to any group" ) return end
	city:Patrol()
end

--------------------------
-- Instruct City
-- 
--
--------------------------
function CityInstruct( city, instruction )
	city.instruction = instruction
end

--------------------------
-- Recruit in City
-- 
--
--------------------------
function CityRecruitTroop( city, troopData )
	local troop = g_troopDataMng:GenerateData( troopData.id, g_troopTableMng )
	troop.name    = ( city:GetGroup() and city:GetGroup().name .. "-" or "" ) .. troop.name
	troop.number  = QueryRecruitTroopNumber( troop )
	
	city:RecruitTroop( troop )	
	--maybe decrease at first
	city.population = city.population - troop.number
	
	--print( "Recruit troop " .. NameIDToString( troop ) .."] in city [" .. city.name .. "]" .. city.population .. "/" .. city:GetMilitaryService() )
end

function CityRecruit( city )
	if not city:GetGroup() then Debug_Error( "City is not belong to any group" ) return end
	
	local soldierNum = {}
	for cate = TroopCategory.CATEGORY_BEG, TroopCategory.CATEGORY_END do
		soldierNum[cate] = 0
	end
	
	local totalSoldier = 0
	for k, v in ipairs( city.troops ) do
		local cat = v.table.category		
		soldierNum[cat] = soldierNum[cat] + v.number
		totalSoldier = totalSoldier + v.number
	end
	
	local priorityList = {}
	for cate = TroopCategory.CATEGORY_BEG, TroopCategory.CATEGORY_END do
		local proportion
		if totalSoldier == 0 then
			proportion = 0
		else
			proportion = soldierNum[cate] * 100 / totalSoldier
		end
		--ShowText( Parameter.DEFAULT_TROOP_PROPORTION[cate], proportion, cate )
		local diff = Parameter.DEFAULT_TROOP_PROPORTION[cate] - proportion
		--descending
		MathUtility_Insert( priorityList, { cate = cate, diff = diff }, "diff", true )
	end

	local canRecruitTroops = {}
	--check tech requirement
	for k, v in ipairs( city:GetGroup()._canRecruitTroops ) do
		local enable = true
		
		--ShowText( "!!!!!!!!!!!!!", v.prerequisites.points )
		
		--check points validation
		if not v.prerequisites.points then enable = false end	
		
		--check construction requirement
		if enable and v.prerequisites.construction and not MathUtility_IndexOf( city.constrs, v.prerequisites.construction, "id" ) then enable = false end
		
		--check money requirement
		if enable and  v.prerequisites.money and v.prerequisites.money > city:GetGroup().money then enable = false end
		
		--check resource requirement
		if enable and  v.prerequisites.resource and not MathUtility_IndexOf( city.resource, v.prerequisites.resource, "id" ) then enable = false end		
				
		if enable then table.insert( canRecruitTroops, v ) end
	end
	
	--MathUtility_Dump( priorityList )
	
	for k1, prior in ipairs( priorityList ) do			
		for k2, troop in ipairs( canRecruitTroops ) do	
			--ShowText( troop.category, prior.cate, k1, k2 )
			if troop.category == prior.cate then
				CityRecruitTroop( city, troop )
				return
			end
		end
	end
	
	Debug_Normal( "Recruit troop failed!" )
end


--------------------------
-- in City
-- 
--
--------------------------
function CharaEstablishCorpsByTroop( city, idleTroopList )
	--local corps = Corps()
	--corps.id = g_corpsDataMng:AllocateId()		
	local corps = g_corpsDataMng:NewData()
	
	--put corps into data manager
	g_corpsDataMng:SetData( corps.id, corps )
	
	local idleTroopNum = #idleTroopList
	local troopNum = {}
	local movement = nil
	for k, troop in ipairs( idleTroopList ) do
		ShowText( "Add troop [".. NameIDToString( troop ) .."] to corps" )
		corps:AddTroop( troop )
		if not movement or movement > troop.movement then movement = troop.movement end
	end
	
	corps.location   = city
	corps.home       = city
	corps.formation  = formation
	corps.movement   = movement

	corps:JoinGroup( city:GetGroup() )

	--put corps into city
	city:EstablishCorps( corps )
end

function CharaEstablishCorps( city )
	if not city:GetGroup() then Debug_Error( "City is not belong to any group" ) return end

	--[[
	--find formation	
	local formation = city:GetGroup().formations[1]
	if not formation then
		--Debug_Error( "Group has none default corps formation" )
		--get default one
		formation = g_formationTableMng:GetData( 1 )
	end	
	if not formation then
		Debug_Error( "Damn it! Even default corps formation isn't exist!" )
	end
	]]
	
	local corps = Corps()
	corps.id = g_corpsDataMng:AllocateId()

	local idleTroopList = {}
	for k, troop in ipairs( city.troops ) do
		if not troop:GetCorps() and troop:IsAtHome() then
			ShowText( NameIDToString( troop ) )
			table.insert( idleTroopList, troop )
		end
	end
	local idleTroopNum = #idleTroopList
	local troopNum = {}
	for cate = TroopCategory.CATEGORY_BEG, TroopCategory.CATEGORY_END do
		troopNum[cate] = 0
	end
	local movement = nil
	for k, troop in ipairs( idleTroopList ) do
		if #corps.troops >= QueryCorpsTroopLimit( corps ) then break end
		corps:AddTroop( troop )
	end
	if #corps.troops == 0 and #idleTroopList > 0 then
		InputUtility_Pause( "establish".. NameIDToString( corps ), #corps.troops, #idleTroopList, #city.troops )
	end
	--[[
	local leftSlot = formation.maxTroop
	if leftSlot >= idleTroopNum then
		for k, troop in ipairs( idleTroopList ) do
			corps:AddTroop( troop )
			if troop.table then
				troopNum[troop.table.category] = troopNum[troop.table.category] + 1
				if not movement or movement > troop.movement then
					movement = troop.movement
				end
			end
		end
	else
		for k, troop in ipairs( idleTroopList ) do
			--ShowText( troopNum[troop.table.category], idleTroopNum, formation.troopProps[troop.table.category] )
			if troopNum[troop.table.category] < idleTroopNum * formation.troopProps[troop.table.category] then			
				corps:AddTroop( troop )
				troopNum[troop.table.category] = troopNum[troop.table.category] + 1
				leftSlot = leftSlot - 1
				if not movement or movement > troop.movement then
					movement = troop.movement
				end
			end
			if leftSlot <= 0 then break end
		end
	end
	]]
	corps.location   = city
	corps.home = city	
	--corps.formation  = formation
	corps.movement   = movement
	corps:JoinGroup( city:GetGroup() )
	
	--put corps into data manager
	g_corpsDataMng:SetData( corps.id, corps )
	
	--put corps into city
	city:EstablishCorps( corps )	
end

---------------------------------------------
--
-- Coprs execution
--
---------------------------------------------

--Quit from group, not belong to it.
function CorpsLeaveGroup( corps )
	local home = corps:GetHome()
	if home then home:RemoveCorps( corps ) end
	local group = corps:GetGroup()
	if group then group:RemoveCorps( corps ) end	
	corps:JoinGroup( nil )
	corps:JoinCity( nil )
end

function CorpsJoinGroup( corps, city, includeAll )
	local group = city:GetGroup()
	--corps data ( include troop data )
	corps:JoinGroup( group )
	corps:JoinCity( city )	
	--city data
	city:AddCorps( corps )	
	--group data
	if group then group:AddCorps( corps ) end
	
	--all troops
	if includeAll then
		for k, troop in ipairs( corps.troops ) do
			TroopLeaveGroup( troop )
			TroopJoinGroup( troop, city )
		end
	end
end

function CorpsRegroup( corps, troops )
	local content = ""
	for k, troop in ipairs( troops ) do
		corps:AddTroop( troop )
		content = content .. NameIDToString( troop ) .. " "
	end
	
	Debug_Normal( "Regroup ["..corps.name.."] with ["..content .."]" )
end
function CorpsReinforce( corps, militaryService )
	local city = corps:GetLocation()
	if not city then
		ShowText( a.b )
		return
	end	
	local number, totalNumber = corps:GetNumberStatus()
	local needPeople = totalNumber - number
	if city.population < needPeople then 
		ShowText( "Reinforce ["..corps.name.."] failed, not enough ["..needPeople .."/"..city.population.."]" )
		return
	end	
	local minPopulation = city:GetMinPopulation()
	local reinforcement = needPeople
	city:CancelRecruit( militaryService )
	city.population = city.population - reinforcement	
	corps:Reinforce( reinforcement )
	Debug_Normal( "Reinforce ["..corps.name.."] with soldier ["..reinforcement.."] from " .. totalNumber .. " to " .. totalNumber + reinforcement )
end

function CorpsTrain( corps )
	local oldValue = 0
	local training = 0
	for k, troop in ipairs( corps.troops ) do
		local tag = troop:GetAsset( TroopTag.TRAINING )
		local current = tag and tag.value or 0
		oldValue = oldValue + current
		local delta = MathUtility_Clamp( ( TroopTag.MAX_VALUE[TroopTag.TRAINING] - current ) * TroopParams.TRAINING.TRAIN_DIFF_MODULUS + TroopParams.TRAINING.TRAIN_STANDARD_VALUE, 0, TroopTag.MAX_VALUE[TroopTag.TRAINING] )
		training = training + current + delta
		troop:AppendAsset( TroopTag.TRAINING, delta, TroopTag.MAX_VALUE[TroopTag.TRAINING] )
		tag = troop:GetAsset( TroopTag.TRAINING )
	end
	oldValue = math.floor( oldValue / #corps.troops )
	training = math.floor( training / #corps.troops )
	Debug_Normal( "Train ["..corps.name.."] from " .. oldValue .. "->" .. training )
end

function CorpsAttack( corps, city )
	CorpsMoveToLocation( corps, city )
	g_warfare:AddWarfarePlan( corps, city )
end

function CorpsSiegeCity( corps, city, isSiege )	
	CorpsMoveToLocation( corps, city )
	g_warfare:AddWarfarePlan( corps, city, isSiege )
	--[[
	for k, corps in ipairs( corpsList ) do
		CorpsMoveToLocation( corps, city )
		g_warfare:AddWarfarePlan( corps, city, isSiege )
	end
	]]
end

function CorpsExpedition( corps, city )
	g_warfare:AddWarfarePlan( corps, city )	
	corps.location = city
	
	Debug_Normal( "["..corps.name.."] go expedition to ["..city.name.."]" )
end

function CorpsDispatchToCity( corps, city, includeAll )
	if city:GetGroup() ~= corps:GetGroup() then
		print( NameIDToString( corps ) .. " cannot moveto=".. city.name .. " belong=" .. ( city:GetGroup() and city:GetGroup().name or "<none>" ) .. " not=".. corps:GetGroup().name )		
		g_taskMng:TerminateTaskByActor( corps, "city not belongs to us" )
		g_taskMng:IssueTaskCorpsBackEncampment( corps )
		return
	end
	--print( NameIDToString( corps ), "dispatch to", city.name )
	local home = corps:GetHome()
	if home and home ~= city then
		home:Dump( nil, true )
		home:RemoveCorps( corps )
	end
	city:AddCorps( corps )
	corps:JoinCity( city )
	corps:MoveToLocation( city )
	if includeAll then
		for k, troop in ipairs( corps.troops ) do
			TroopDispatchToCity( troop, city, includeAll )
		end
	end
end


function CorpsMoveToLocation( corps, location )
	corps:MoveToLocation( location )
	for k, troop in ipairs( corps.troops ) do
		troop:MoveToLocation( location )
		local leader = troop:GetLeader()
		if leader then leader:MoveToLocation( location ) end
	end
end

function CorpsMoveToCity( corps, city )
	if city:GetGroup() ~= corps:GetGroup() then
		print( NameIDToString( corps ) .. " cannot moveto=".. city.name .. " belong=" .. ( city:GetGroup() and city:GetGroup().name or "<none>" ) .. " not=".. corps:GetGroup().name )
		g_taskMng:TerminateTaskByActor( corps, "city not belongs to us" )
		g_taskMng:IssueTaskTroopMoveTo( corps )
		return
	end
	CorpsMoveToLocation( corps, city )
end

---------------------------------------------
--
-- Troop execution
--
---------------------------------------------

--Leave group, not belong to it 
function TroopLeaveGroup( troop )	
	local home = troop:GetHome()	
	if home then home:RemoveTroop( troop ) end
	local group = troop:GetGroup()
	if group then group:RemoveTroop( troop ) end
	troop:JoinGroup( nil )
	troop:JoinCity( nil )
end

function TroopJoinGroup( troop, city, includeAll )
	local group = city:GetGroup()
	--troop data ( include chara data )
	troop:JoinGroup( group )
	troop:JoinCity( city )	
	--city data
	city:AddTroop( troop )	
	--group data
	if group then group:AddTroop( troop ) end
	
	if includeAll then
		local leader = troop:GetLeader()
		if leader then
			CharaLeaveGroup( leader )
			CharaJoinGroup( leader, city )
		end
	end
end

function TroopDispatchToCity( troop, city, includeAll )
	if city:GetGroup() ~= troop:GetGroup() then
		print( NameIDToString( troop ) .. " cannot moveto=".. city.name .. " belong=" .. ( city:GetGroup() and city:GetGroup().name or "<none>" ) .. " not=".. troop:GetGroup().name )
		g_taskMng:TerminateTaskByActor( troop, "city not belongs to us" )
		g_taskMng:IssueTaskTroopMoveTo( troop )
		return
	end

	local home = troop:GetHome()
	if home and home ~= city then home:RemoveTroop( troop ) end
	city:AddTroop( troop )
	troop:JoinCity( city )
	troop:MoveToLocation( city )
	
	if includeAll then
		CharaDispatchToCity( troop:GetLeader(), city )
	end
end

function TroopMoveToLocation( troop, location )
	troop:MoveToLocation( location )
	local leader = troop:GetLeader()
	if leader then
		leader:MoveToLocation( location )
	end
end

function TroopMoveToCity( troop, city )
	if city:GetGroup() ~= troop:GetGroup() then
		print( NameIDToString( troop ) .. " cannot moveto=".. city.name .. " belong=" .. ( city:GetGroup() and city:GetGroup().name or "<none>" ) .. " not=".. troop:GetGroup().name )
		g_taskMng:TerminateTaskByActor( troop, "city not belongs to us" )
		g_taskMng:IssueTaskTroopMoveTo( troop )
		return
	end
	TroopMoveToLocation( troop, city )
end

---------------------------------------------
--
-- Character execution
--
---------------------------------------------
function CharaLookforTalent( city )
	local chara = g_charaTemplate:GenerateChara( city )	
	CharaJoinGroup( chara, city )
	chara.job = CharacterJob.OFFICER	
	g_statistic:AddActivateChara( chara )
	--InputUtility_Pause( "look for talent=" .. chara.name .. " in " .. city.name .. "@" .. city:GetGroup().name )
	return true	
end

function CharaPromote( chara, city )
	
end

function CharaHired( chara, city )
	if chara:GetGroup() then
		InputUtility_Pause( NameIDToString( chara )  .. " already in group=" .. chara:GetGroup().name )
		return false
	end
	if chara:GetGroup() then CharaLeaveGroup( chara ) end
	--print( chara.name, "hired by ", city:GetGroup().name, city.name )
	CharaJoinGroup( chara, city )
	chara.job = CharacterJob.OFFICER	
	g_statistic:RemoveOutChara( chara )
	g_statistic:AddActivateChara( chara )
	--g_statistic:DumpCharaDetail()
	--InputUtility_Pause( "hired=" .. chara.name .. " in " .. city.name .. "@" .. city:GetGroup().name )
	return true
end

function CharaBackHome( chara )
	g_taskMng:IssueTaskCharaBackHome( chara )
end

function CharaOut( chara )
	CharaLeaveGroup( chara )
	chara:Out()
	g_taskMng:TerminateTaskByActor( chara, "chara out" )
	g_statistic:RemoveActivateChara( chara )
	g_statistic:AddOutChara( chara )
end

function CharaCaptured( chara )
	--leave and keep chara's data
	local group = chara:GetGroup()
	local city = chara:GetHome()
	CharaLeaveGroup( chara )
	chara:JoinGroup( group )
	chara:Captured()
	g_taskMng:TerminateTaskByActor( chara, "chara been captured" )
	g_statistic:RemoveActivateChara( chara )
	g_statistic:AddPrisonerChara( chara )
	--don't care about leader of group here
end

function CharaDie( chara )
	local group = chara:GetGroup()
	local city = chara:GetHome()
	CharaLeaveGroup( chara )
	chara:Die()
	g_taskMng:TerminateTaskByActor( chara, "chara died" )
	g_statistic:RemoveActivateChara( chara )
	g_statistic:AddOtherChara( chara )
	--don't care about leader of group here
end

function CharaExile( chara, city )
	CharaLeaveGroup( chara )
	chara:Out()
	g_taskMng:TerminateTaskByActor( chara, "chara been exiled" )
	g_statistic:RemoveActivateChara( chara )
	g_statistic:AddOutChara( chara )	
	--Should the character hate who exile him, to do
end

function CharaDispatchToCity( chara, city )	
	if not chara then return end

	if city:GetGroup() ~= chara:GetGroup() then
		print( NameIDToString( chara ) .. " cannot move to " .. city.name .. " belong=" .. ( city:GetGroup() and city:GetGroup().name or "<none>" ) .. " not="..chara:GetGroup().name )
		g_taskMng:TerminateTaskByActor( chara, "city not belongs to us" )
		g_taskMng:IssueTaskCharaBackHome( chara )
		return
	end
	local home = chara:GetHome()
	if home and home ~= city then home:RemoveChara( chara ) end
	city:AddChara( chara )
	chara:JoinCity( city )
	chara:MoveToLocation( city )
	--if chara.id == 312 then InputUtility_Pause( chara.name .. " disp to " .. city.name, "troop="..NameIDToString( chara.troop ) ) end
end

function CharaLeadTroop( chara, troop )
	if troop and chara.location ~= troop.location then
		InputUtility_Pause( chara.name .. " loc="..chara.location.name, " not in troop_loc="..troop.location.name, NameIDToString( troop ) )
		return
	end
	local oldTroop = chara:GetTroop()
	if oldTroop then
		oldTroop:LeadByChara( nil )
		local oldCoprs = oldTroop:GetCorps()
		if oldCoprs and oldCoprs:GetLeader() then
			if oldCoprs:GetLeader() == chara then
				oldCoprs:LeadByChara( nil )
			else
				InputUtility_Pause( "why leader wrong", NameIDToString( oldCoprs ), oldCoprs:GetLeader(), chara.name )
			end
		end
	end
	if troop then	
		troop:LeadByChara( chara )
		local corps = troop:GetCorps()
		if corps then
			local leader = corps:GetLeader() 
			if not leader or chara:IsMoreImportant( leader ) then
				corps:LeadByChara( chara )
			end
		end
	end
	chara:LeadTroop( troop )
	if nil and chara.id == 312 then		
		if troop.corps then
			print( "corps=", NameIDToString( troop.corps ), "loc="..troop.corps.location.name .."/" .. troop.corps.home.name )
		end
		InputUtility_Pause( chara.name, "lead", NameIDToString( troop ), "at="..chara.home.name .."/"..chara.location.name.."/"..troop.location.name )
	end
end

function CharaMoveToLocation( chara, location )
	chara:MoveToLocation( location )
end

function CharaMoveToCity( chara, city )
	if city:GetGroup() ~= chara:GetGroup() then
		print( NameIDToString( chara ) .. " cannot move to " .. city.name .. " belong=" .. ( city:GetGroup() and city:GetGroup().name or "<none>" ) .. " not="..chara:GetGroup().name )
		g_taskMng:TerminateTaskByActor( chara, "city not belongs to us" )
		g_taskMng:IssueTaskCharaBackHome( chara )
		return
	end
	CharaMoveToLocation( chara, city )
end

function CharaLeaveGroup( chara )
	local home = chara:GetHome()
	--InputUtility_Pause( chara.name, "level group, home=", home and home.name or "" )
	if home then home:RemoveChara( chara ) end
	local group = chara:GetGroup()
	if group then
		group:RemoveChara( chara )
		if group:GetLeader() == chara then
			group:CheckLeader()
		end
	end
	chara:JoinGroup( nil )
	chara:JoinCity( nil )
end

function CharaJoinGroup( chara, city )
	local group = city:GetGroup()
	chara:JoinGroup( group )
	chara:JoinCity( city )	
	--city data
	city:AddChara( chara )
	--group data
	if group then group:AddChara( chara ) end
end

function CharaJoinCity( chara, city )
	chara:JoinCity( city )
	city:AddChara( chara )
end

--------------------------

--Leave city to execute task
function CorpsLeaveCity( corps, reason )
	g_movingActorMng:AddActor( MovingActorType.CORPS, corps, { reason = reason } )
	for k, troop in ipairs( corps.troops ) do
		TroopLeaveCity( troop )
	end
end

function TroopLeaveCity( troop, reason )
	g_movingActorMng:AddActor( MovingActorType.TROOP, troop, { reason = reason } )
	if troop:GetLeader() then
		CharaLeaveCity( troop:GetLeader(), "troop leave" )
	end
end

function CharaLeaveCity( chara, reason )
	g_movingActorMng:AddActor( MovingActorType.CHARACTER, chara, { reason = reason } )
end

function CorpsEsacpeToCity( corps, city )
	local home = corps:GetHome()
	if home then
		home:RemoveCorps( corps )
		for k, troop in ipairs( corps.troops ) do
			home:RemoveTroop( troop )
			local leader = troop:GetLeader()
			if leader then
				--print( "escape debug:", leader.name, "home="..leader.home.name, "loc="..leader.location.name, "troophome="..troop.home.name, "corpshome="..home.name, "group="..leader.group.name )
				--print( "	", troop.name, troop.home.name )
				home:RemoveChara( leader )
			end
		end
	end
	
	corps:JoinCity( city )	
	city:AddCorps( corps )
	for k, troop in ipairs( corps.troops ) do
		troop:JoinCity( city )
		city:AddTroop( troop )
		local leader = troop:GetLeader()
		if leader then
			leader:JoinCity( city )
			city:AddChara( leader )
		end
	end
	
	if corps:GetLocation() == city then
		--in the city
		g_taskMng:TerminateTaskByActor( corps, "need to retreat" )
		g_taskMng:IssueTaskCorpsBackEncampment( corps )
	else
		--!!! it's more complex than what I did now.
		--There're some many situation should consider about
		--1.home supply
		--2.attack failed
		local task = g_taskMng:GetTaskByActor( corps )
		if task then
			if task.type ~= TaskType.ATTACK_CITY and task.type ~= TaskType.EXPENDITION then
				g_taskMng:TerminateTask( task, "home been captured" )
				g_taskMng:IssueTaskCorpsBackEncampment( corps )
			end
		else	
			g_taskMng:IssueTaskCorpsBackEncampment( corps )
		end				
	end
	ShowText( "Corps="..corps.name.."+"..#corps.troops .. " retreat to " .. city.name )
end

function TroopEscapeToCity( troop, city )
	local leader = troop:GetLeader()
	local home = troop:GetHome()
	if home then
		home:RemoveTroop( troop )		
		if leader then home:RemoveChara( leader ) end
	end
	troop:JoinCity( city )
	city:AddTroop( troop )
	if leader then
		leader:JoinCity( city )
		city:AddChara( leader )
	end
	
	g_taskMng:TerminateTaskByActor( troop, "need to retreat" )
	g_taskMng:IssueTaskTroopMoveTo( troop )
	ShowText( "Troop=" .. troop.name .. " retreat to " .. city.name )
end

function CharaEscapeToCity( chara, city )
	local home = chara:GetHome()
	if home then home:RemoveChara( chara ) end
	
	chara:JoinCity( city )
	city:AddChara( chara )
	
	g_taskMng:TerminateTaskByActor( chara, "	treat" )
	g_taskMng:IssueTaskCharaBackHome( chara )
	ShowText( "Chara=" .. chara.name .. " retreat to " .. city.name )
end

function CorpsNeutralize( corps, isCaptured )
	g_taskMng:TerminateTaskByActor( corps, "corps neutralized" )	
	for k, troop in ipairs( corps.troops ) do
		local leader = troop:GetLeader()
		TroopLeaveGroup( troop )
		g_troopDataMng:RemoveData( troop.id )		
		if leader then
			leader:LeadTroop( nil )			
			if isCaptured then
				CharaCaptured( leader )
			else
				local retreatCity = leader:GetGroup():GetCapital()
				if retreatCity:GetGroup() ~= leader:GetGroup() then
					--capital lost
					if #leader:GetGroup().cities ~= 0 then
						local index = Random_SyncGetRange( 1, #leader:GetGroup().cities )
						retreatCity = leader:GetGroup().cities[index]
					else
						--no city
						retreatCity = nil
					end
				end
				if retreatCity then
					CharaEscapeToCity( leader, retreatCity )
				else
					CharaOut( leader )
				end
			end
		end
	end
	
	CorpsLeaveGroup( corps )
	g_corpsDataMng:RemoveData( corps.id )
end

function TroopNeutralize( troop )
	print( troop.name, "neutralized" )
	g_taskMng:TerminateTaskByActor( troop, "troop neutralized" )
	
	local leader = troop:GetLeader()
	if leader then
		leader:LeadTroop( nil )		
		if leader:GetGroup() and leader:GetGroup():GetCapital() then
			CharaEscapeToCity( leader, leader:GetGroup():GetCapital() )
		else
			CharaOut( leader )
		end
	end
	
	TroopLeaveGroup( troop )
	g_troopDataMng:RemoveData( troop.id )
end

function TroopLoseGroup( chara )
	g_taskMng:TerminateTaskByActor( chara, "no way")
	
	local home = chara:GetHome()
	if home then home:RemoveChara( chara ) end

	local group = chara:GetGroup()
	if #group.cities > 0 then
		Helper_DumpList( originalGroup.cities )
		CharaJoinCity( chara, group:GetCapital() )
		g_taskMng:TerminateTaskByActor( chara, "no way" )
		g_taskMng:IssueTaskCharaBackHome( chara )
		InputUtility_Pause()
	else
		print( "chara no place to go, need to out" )
		CharaOut( chara )
	end				
end