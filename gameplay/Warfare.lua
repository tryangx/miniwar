--[[
	When Field-Combat, Defender should retreat to city when intel about third-party corps attack the city.

]]

Warfare = class()

function Warfare:__init()
	self.plans   = {}
	self.siegeCombats = {}
	self.fieldCombats = {}
end

function Warfare:Dump()
	if g_combatDataMng:GetCount() > 0 then
		g_combatDataMng:Foreach( function ( combat )
			if not combat:IsCombatEnd() then
				combat:Brief()
			end
		end )
		--InputUtility_Pause( "combat exist", g_combatDataMng:GetCount() )
	end
	--ShowText( "Combat Left " .. #g_combatDataMng.datas .. "/" .. g_combatDataMng.count )
end

function Warfare:GetCombatCount()
	return g_combatDataMng:GetCount()
end

function Warfare:GetFieldCombat( location )	
	return self.fieldCombats[location]
end

function Warfare:GetSiegeCombat( location )	
	return self.siegeCombats[location]
end

function Warfare:GetCombatByLocation( location )	
	return self:GetSiegeCombat( location ) or self:GetFieldCombat( location )
end

function Warfare:IsLocationUnderAttackBy( location, atkGroup )
	local combat = self:GetCombatByLocation( location )
	if not combat then
		--InputUtility_Pause( "why no combat", location.name )
		return false
	end
	local combatAtkGroup = combat:GetSideGroup( CombatSide.ATTACKER )
	local ret = combatAtkGroup == atkGroup
	--if not ret then InputUtility_Pause( combatAtkGroup.name, atkGroup.name, "@" .. location.name, ( location:GetGroup() and location:GetGroup().name .. "" ) ) end
	return ret
end

--Add siege
function Warfare:AddPlan( corps, city )
	local locationPlan = self.plans[city]
	if not locationPlan then
		locationPlan = { siege = true, plans = {} }
		self.plans[city] = locationPlan
	end
	
	--No need to attack
	if corps:GetGroup() == city:GetGroup() then		
		g_taskMng:TerminateTaskByActor( corps, "city already belong to us" )
		g_taskMng:IssueTaskCorpsBackEncampment( corps )
		--InputUtility_Pause( NameIDToString( corps ), corps:GetHome().name, city.name )
		return
	end
	
	local plan     = {}
	plan.attacker = corps
	plan.defender = nil
	plan.siege    = true
	table.insert( locationPlan.plans, plan )

	ShowText( "Add Plan", NameIDToString( corps ), NameIDToString( city ) )
end

function Warfare:AddFieldCombatPlan( atkCorps, defCorpsList, location )
	local locationPlan = self.plans[location]
	if not locationPlan then
		locationPlan = { plans = {} }
		self.plans[location] = locationPlan
	end

	--No need to attack
	if atkCorps:GetGroup() == location:GetGroup() then		
		g_taskMng:TerminateTaskByActor( atkCorps, "city already belong to us" )
		g_taskMng:IssueTaskCorpsBackEncampment( atkCorps )
		--InputUtility_Pause( NameIDToString( atkCorps ), atkCorps:GetHome().name, city.name )
		return
	end

	ShowText( "Add field combat in=" .. NameIDToString( location ) .. " atkcorps=" .. atkCorps:CreateBrief() .. " deflist=" .. #defCorpsList )
	
	-- only support siege combat now
	local plan     = {}
	plan.attacker  = atkCorps
	plan.defender  = defCorpsList
	plan.siege     = false
	table.insert( locationPlan.plans, plan )
end

function Warfare:Update( elapasedTime )
	g_season:SetDate( g_calendar.month, g_calendar.day )
	
	-- process all plans
	for city, locationPlan in pairs( self.plans ) do		
		for k, plan in ipairs( locationPlan.plans ) do
			local existCombat = self:GetSiegeCombat( city )
			local attend = true
			if existCombat then
				--print( existCombat:CreateBrief() )
				local attacker = existCombat and existCombat:GetSideGroup( CombatSide.ATTACKER ) or nil
				local reinforcer = plan.attacker:GetGroup()
				--3rd party attack the city, we should check it is the ally
				if reinforcer and reinforcer ~= attacker then
					local relation = attacker:GetGroupRelation( reinforcer.id )
					if not relation:IsAllyOrDependence() then
						--retreat or wait?
						attend = false
						g_taskMng:TerminateTaskByActor( plan.attacker, "attack target is in siege by other group" )
					else
						--ally reinforce
						print( "ally="..reinforcer.name, "attacker="..attacker.name )
					end
				end
			end
			--ShowText( NameIDToString( plan.attacker ), " city=", city.name .. " combat=", existCombat, " attend=" .. ( attend and "true" or "false" ) )
			if attend then
				if plan.siege then
					self:AddSiegeCombat( plan.attacker, city )
				else
					self:AddFieldCombat( plan.attacker, plan.defender, city )
				end
			end
		end
	end

	for k = 1, elapasedTime do
		self:RunOneDay()
	end

	self.plans = {}
end

function Warfare:AddSiegeCombat( corps, city )
	city:AppendTag( CityTag.SIEGE, 1 )
	local combat = self:GetSiegeCombat( city )
	if not combat then
		combat = g_combatDataMng:NewData()
		combat:SetType( CombatType.SIEGE_COMBAT )
		combat:SetLocation( city )
		combat:SetBattlefield( 1 )
		combat:SetClimate( 1 )
		combat:SetGroup( CombatSide.ATTACKER, corps:GetGroup() )
		combat:SetGroup( CombatSide.DEFENDER, city:GetGroup() )
		combat:SetEndDay( 30 )
		ShowText( "combatid="..combat.id, corps:GetGroup().name, ( city:GetGroup() and city:GetGroup().name or "" ) )
		
		--not in corps	
		for k, defender in ipairs( city.troops ) do
			if not defender:GetCorps() and defender:IsAtHome() then
				g_taskMng:TerminateTaskByActor( defender, "home is under attack" )
				combat:AddTroopToSide( CombatSide.DEFENDER, defender )
			end
		end

		--in corps
		for k, defender in ipairs( city.corps ) do
			if defender:IsAtHome() then
				if defender:GetHome() ~= city then
					InputUtility_Pause( "oh my god", defender:GetHome().name, city.name )
				end
				--print( "Add corps", NameIDToString( defender ) )
				g_taskMng:TerminateTaskByActor( defender, "home is under attack" )					
				combat:AddCorpsToSide( CombatSide.DEFENDER, defender )
			end
		end
		
		function AddDefenderTroop( id, allocateNumber )
			local newTroop = GenerateTroop( id )
			if allocateNumber then
				if allocateNumber <= newTroop.maxNumber then
					newTroop.number = allocateNumber
				end
				allocateNumber = allocateNumber - newTroop.maxNumber
			end
			combat:AddTroopToSide( CombatSide.DEFENDER, newTroop )
			--InputUtility_Pause( "Add Guard", NameIDToString( newTroop ) )
			return allocateNumber
		end
		
		--add guards
		local troopIds = g_scenario:CallFunction( "QueryPlotGuardIds", #city.plots )
		local totalGuards = city.guards
		while totalGuards > 0 do
			local troopId = troopIds[Random_SyncGetRange( 1, #troopIds )]			
			totalGuards = AddDefenderTroop( troopId, totalGuards )
		end
		--add wall, gate, tower
		AddDefenderTroop( 100 )
		AddDefenderTroop( 200 )
		AddDefenderTroop( 210 )		

		combat:Init()
	else
		combat:Reinforce()
	end
	
	-- troop sequence
	combat:AddCorpsToSide( CombatSide.ATTACKER, corps )	
	
	self.siegeCombats[city] = combat
end

function Warfare:AddFieldCombat( attacker, defenderList, location )
	local combat = self:GetFieldCombat( location )
	--Need to process with skirmish
	if not combat then
		combat = g_combatDataMng:NewData()
		combat:SetType( CombatType.FIELD_COMBAT )
		combat:SetLocation( location )
		combat:SetBattlefield( 1 )
		combat:SetClimate( 1 )
		combat:SetGroup( CombatSide.ATTACKER, attacker:GetGroup() )	
		combat:SetEndDay( 30 )
		local defenderGroup = nil
		for k, defenderCorps in ipairs( defenderList ) do
			if not defenderGroup then defenderGroup = defenderCorps:GetGroup() end
			combat:AddCorpsToSide( CombatSide.DEFENDER, defenderCorps )
		end
		combat:SetGroup( CombatSide.DEFENDER, defenderGroup )
		combat:Init()
	else
		combat:Reinforce()
	end
	
	combat:AddCorpsToSide( CombatSide.ATTACKER, attacker )
	
	self.fieldCombats[location] = combat
end

--Add skirmish
--[[
function Warfare:AddSkirmish( corps, field )	
end
]]

function Warfare:Test( atks, defs )
	quickSimulate = false
	combat = g_combatDataMng:NewData()

	--now only support city, extend to field in the future
	--combat:SetType( CombatType.SIEGE_COMBAT )
	combat:SetType( CombatType.FIELD_COMBAT )
	combat:SetLocation(  g_cityDataMng:GetData( 10 ) )
	combat:SetBattlefield( 3 )
	combat:SetClimate( 1 )
	combat:SetGroup( CombatSide.ATTACKER, nil )
	combat:SetGroup( CombatSide.DEFENDER, nil )
	
	--add wall
	combat:AddTroopToSide( CombatSide.DEFENDER, g_troopDataMng:GetData( 100 ) )	
	--add gate
	combat:AddTroopToSide( CombatSide.DEFENDER, g_troopDataMng:GetData( 200 ) )
	--add tower
	combat:AddTroopToSide( CombatSide.DEFENDER, g_troopDataMng:GetData( 210 ) )
	
	--add attackers
	for k, c in ipairs( atks ) do
		combat:AddCorpsToSide( CombatSide.ATTACKER, c )
	end
	
	--add defenders
	for k, c in ipairs( defs ) do
		combat:AddCorpsToSide( CombatSide.DEFENDER, c )
	end	
	if #defs == 0 then
		--add militia, just for test
		combat:AddTroopToSide( CombatSide.DEFENDER, g_troopDataMng:GetData( 500 ) )	
	end

	combat:SetEndDay( 30 )
	
	combat:Init()
	
	--ShowText( "testCombat", combat.id )
end

function Warfare:ProcessCombatResult( combat )
	if not combat:GetLocation() then return end

	g_statistic:CombatOccured( combat:CreateBrief(), combat:GetLocation() )
	g_chronicle:RecordEvent( combat.type == CombatType.FIELD_COMBAT and HistroyEventType.FIELD_COMBAT_OCCURED or HistroyEventType.SIEGE_COMBAT_OCCURED, combat:CreateBrief(), combat.endDate )

	--combat:Dump()
	combat:EndCombat()

	--Calcuate winner profit, affect diplomacy
	local winner = combat:GetWinner()
	local atkGroup = combat:GetSideGroup( CombatSide.ATTACKER )
	local defGroup = combat:GetSideGroup( CombatSide.DEFENDER )		
	if defGroup then
		local relation = atkGroup:GetGroupRelation( defGroup.id )
		if relation then
			relation:GainProfit( atkGroup, combat.atkKill )
			relation:GainProfit( defGroup, combat.defKill )
		else
			--InputUtility_Pause( atkGroup.name, defGroup.name )
		end
	end

	ShowText( "CombatEnd=" .. combat.id, combat:GetLocation().name, NameIDToString( atkGroup ), MathUtility_FindEnumName( CombatResult, combat.result ) )

	if combat.type == CombatType.FIELD_COMBAT then
		--go back home
		combat:ForeachCorps( function ( corps )			
			local task = g_taskMng:GetTaskByActor( corps )
			if not task then return end
			ShowText( "winner=".. MathUtility_FindEnumName( CombatSide, winner ), "corps=" .. NameIDToString( corps:GetGroup() ) )
			if ( corps:GetGroup() == atkGroup and winner == CombatSide.ATTACKER )
				or ( corps:GetGroup() == defGroup and winner == CombatSide.DEFENDER ) then
				for k, troop in ipairs( corps.troops ) do
					if troop:GetLeader() then
						troop:GetLeader():Contribute( nil, ContributionModulus.NORMAL )
					end
				end
				if task:IsDefendTask() then
					ShowText( "success--", task:CreateBrief() )
					task:Succeed( ContributionModulus.NORMAL )
				else
					ShowText( "cointinue--", task:CreateBrief() )
					task:Continue()
				end				
			else
				ShowText( "fail--", task:CreateBrief() )
				task:Fail()
			end
			--[[
			if winner == CombatSide.ATTACKER then
				if task:IsInvasionTask() then
					task:Continue()
					ShowText( "cointinue--", task:CreateBrief() )
				end
				if task:IsDefendTask() then
					
				end
			elseif winner == CombatSide.DEFENDER then
				if task:IsInvasionTask() then
					ShowText( "fail--", task:CreateBrief() )
					task:Fail()
				end
				if task:IsDefendTask() then					
					task:Continue()
					ShowText( "cointinue--", task:CreateBrief() )
				end
			end
			]]
		end )
	elseif combat.type == CombatType.SIEGE_COMBAT then
		local city = combat:GetLocation()
		
		--remove guards first
		local deadGuard = 0
		for k, troop in ipairs( combat.troops ) do
			--if not troop:GetGroup() then
			if g_scenario:CallFunction( "IsPlotGuard", troop.tableId ) then
				InputUtility_Pause( "remove guard", NameIDToString( troop ) )
				deadGuard = deadGuard + troop.maxNumber - troop.number
				g_troopDataMng:RemoveData( troop.id )
			end
		end
		--InputUtility_Pause( city.name, "lose guard=" .. deadGuard.."/"..city.guards, "population="..city.population )
		city.guards = MathUtility_Clamp( city.guards - deadGuard, 0, city.guards )
		city:LosePopulation( deadGuard )	

		--Detail datas
	
		city:RemoveTag( CityTag.SIEGE )
		if winner == CombatSide.ATTACKER then
			-- Determine the ownership of the city if it's a siege combat
			local atkCorpsList = MathUtility_Filter( combat.corps, function ( corps ) return corps:GetGroup() == atkGroup end )
			
			--Capture city, capture corps, capture troops, capture chara
			CaptureCity( atkGroup, city )

			--Garrisson into the city
			for k, corps in ipairs( atkCorpsList ) do
				ShowText( NameIDToString( corps ) .. " belong " .. corps:GetGroup().name )
				CorpsDispatchToCity( corps, city, true )

				--reward
				for _, troop in ipairs( corps.troops ) do
					if troop:GetLeader() then
						troop:GetLeader():Contribute( nil, ContributionModulus.MORE )
					end
				end
			end

			--Vote Leader
			city:SelectLeader( city:VoteLeader() )

			--Finished Task
			--g_taskMng:FinishTask( atkGroup, TaskType.HARASS_CITY, combat:GetLocation() )
			g_taskMng:FinishTask( atkGroup, TaskType.SIEGE_CITY, combat:GetLocation() )
			g_taskMng:CancelTaskFromOtherGroup( atkGroup, TaskType.HARASS_CITY, combat:GetLocation() )
		else
			--Failed, corps need to go back home
			combat:ForeachCorps( function ( corps )	
				if corps:GetGroup() == combat:GetSideGroup( CombatSide.ATTACKER ) then
					local task = g_taskMng:GetTaskByActor( corps )
					if task then
						task:Fail()
					end
				end
			end )
		end
	end
	if combat.type == CombatType.FIELD_COBMAT then InputUtility_Pause( "end combat", combat:CreateBrief() ) end
end

function Warfare:EndCombat( combat )
	local location = combat:GetLocation()
	if location then
		if combat.type == CombatType.SIEGE_COMBAT then
			self.siegeCombats[location] = nil
		elseif combat.type == CombatType.FIELD_COMBAT then
			self.fieldCombats[location] = nil
		end
	end
	self:ProcessCombatResult( combat )	
end

--Use when group is fallen
function Warfare:EndCombatByGroup( group )
	g_combatDataMng:Foreach( function ( combat )
		local atkGroup = combat:GetSideGroup( CombatSide.ATTACKER )
		if atkGroup == group then
			self:EndCombat( combat )
		end
	end )
end

---------------------------------------

function Warfare:RunOneDay()
	self:Dump()

	g_combatDataMng:Foreach( function ( combat )
		if not combat:IsCombatEnd() then
			combat:RunOneDay()
		end
	end )
	g_combatDataMng:RemoveDataByCondition( function ( combat ) 
		if combat:IsCombatEnd() then			
			g_warfare:EndCombat( combat )
			return true
		end
		return false
	end )
end