Warfare = class()

function Warfare:__init()
	self.plans   = {}
	self.combats = {}
end

function Warfare:GetCombatByLocation( location )
	return self.combats[location]
end

function Warfare:IsLocationUnderAttackBy( location, atkGroup )
	local combat = self.combats[location]
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
function Warfare:AddWarfarePlan( corps, city, siege )
	local locationPlan = self.plans[city]
	if not locationPlan then
		locationPlan = { siege = true, plans = {} }
		self.plans[city] = locationPlan
	end
	
	if corps:GetGroup() == city:GetGroup() then
		--InputUtility_Pause( "No need to attack", corps.name, city.name )
		g_taskMng:TerminateTaskByActor( corps, "city already belong to us" )
		return
	end
	
	-- only support siege combat now
	local plan     = {}
	plan.from     = plan.from
	plan.to       = city
	plan.attacker = corps
	plan.defender = nil
	plan.siege    = true
	plan.field    = false	
	table.insert( locationPlan.plans, plan )
	
	--if city.id == 101 then quickSimulate = false InputUtility_Pause( "Add combat plan" ) end
end

function Warfare:Update( elapasedTime )
	--use current date?
	g_season:SetDate( g_calendar.month, g_calendar.day )
	
	-- process all plans
	for city, locationPlan in pairs( self.plans ) do
		if locationPlan.field == true then			
			for k, plan in ipairs( locationPlan.plans ) do
				self:AddFieldCombat( plan.attacker, plan.defender, nil )
			end
		else
			for k, plan in ipairs( locationPlan.plans ) do
				local existCombat = self:GetCombatByLocation( city )
				local attacker = existCombat and existCombat:GetSideGroup( CombatSide.ATTACKER ) or nil
				if existCombat then
					--[[
					quickSimulate = false
					existCombat:Dump()
					quickSimulate = true
					]]					
					--print( existCombat:CreateDesc() )
					--print( "existCombat=", existCombat.id )
					local reinforcer = plan.attacker:GetGroup()
					if reinforcer == attacker then
						print( "reinforcer="..reinforcer.name, "attacker="..attacker.name )
						--reinforce
						self:AddSiegeCombat( plan.attacker, plan.to, plan.siege, true )
					elseif reinforcer then
						local relation = attacker:GetGroupRelation( reinforcer.id )
						if relation:IsAllyOrDependence() then
							--ally reinforce
							print( "ally="..reinforcer.name, "attacker="..attacker.name )
							self:AddSiegeCombat( plan.attacker, plan.to, plan.siege )
						else
							--retreat
							g_taskMng:TerminateTaskByActor( plan.attacker, "attack target is in siege" )
						end
					end
				else
					self:AddSiegeCombat( plan.attacker, plan.to )
				end
			end
		end
	end	
	self:RunOneDay()	
	self.plans = {}
end

function Warfare:GetCombatInLocation( city )
	return city and self.combats[city] or nil
end

function Warfare:AddSiegeCombat( corps, city, isSiege )
	print( NameIDToString( corps ) .. " attack " .. city.name .. "@" .. ( city:GetGroup() and city:GetGroup().name or "Neutral" ) )
	city:AppendTag( CityTag.SIEGE, 1 )
	local combat = nil
	local findCombat = self:GetCombatInLocation( city )
	if not findCombat then
		combat = g_combatDataMng:NewData()
		combat:SetType( CombatType.SIEGE_COMBAT )
		combat:SetLocation( city.id )
		combat:SetBattlefield( 1 )
		combat:SetClimate( 1 )
		combat:SetGroup( CombatSide.ATTACKER, corps:GetGroup() )
		combat:SetGroup( CombatSide.DEFENDER, city:GetGroup() )
		combat:SetSide( CombatSide.ATTACKER, { purpose=CombatPurpose.CONVENTIONAL } )
		combat:SetSide( CombatSide.DEFENDER, { purpose=CombatPurpose.CONVENTIONAL } )	
		
		print( "combatid="..combat.id, corps:GetGroup().name, ( city:GetGroup() and city:GetGroup().name or "" ) )
		
		--not in corps	
		for k, defender in ipairs( city.troops ) do
			if not defender:GetCorps() and defender:IsAtHome() then
				--print( "Add troop", NameIDToString( defender ) )
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
		combat = findCombat

		combat:Reinforce()

		--adjust attitude
		combat:SetSide( CombatSide.ATTACKER, { purpose=CombatPurpose.CONVENTIONAL } )
	end
	
	-- troop sequence
	combat:AddCorpsToSide( CombatSide.ATTACKER, corps )	
	
	if findCombat then
		--quickSimulate = false
		findCombat:GetLocation():Dump()		
		print( "siege combat reinforce", findCombat.id, findCombat:GetLocation().name, "corps="..NameIDToString(corps) )
	else
		--quickSimulate = false				
		combat:GetLocation():Dump(nil, true)
		print( "siege combat occured", combat.id, combat:GetLocation().name, "corps="..NameIDToString(corps) )
	end
	
	self.combats[city] = combat
	combat:Dump()
	--InputUtility_Pause()
end

function Warfare:AddFieldCombat( attacker, defender, location )
	local combat = self:GetCombatInLocation( location )
	
	--Need to process with skirmish
	if not combat then
		combat = g_combatDataMng:NewData()
		combat:SetType( CombatType.FIELD_COMBAT )
		combat:SetBattlefield( 1 )
		combat:SetClimate( 1 )
		combat:SetGroup( CombatSide.ATTACKER, attacker:GetGroup() )
		combat:SetGroup( CombatSide.DEFENDER, defender:GetGroup() )
		combat:SetSide( CombatSide.ATTACKER, { purpose=CombatPurpose.CONVENTIONAL } )
		combat:SetSide( CombatSide.DEFENDER, { purpose=CombatPurpose.CONVENTIONAL } )
		combat:Init()
	end
	
	-- trop sequence
	combat:AddCorpsToSide( CombatSide.ATTACKER, attacker )	
	combat:AddCorpsToSide( CombatSide.DEFENDER, defender )
	
	self.combats[location] = combat
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
	combat:SetType( CombatType.SIEGE_COMBAT )
	--combat:SetType( CombatType.FIELD_COMBAT )
	combat:SetLocation( 10 )
	combat:SetBattlefield( 3 )
	combat:SetClimate( 1 )
	combat:SetGroup( CombatSide.ATTACKER, nil )
	combat:SetGroup( CombatSide.DEFENDER, nil )
	combat:SetSide( CombatSide.ATTACKER, { purpose=CombatPurpose.CONVENTIONAL } )--DESPERATE } )
	combat:SetSide( CombatSide.DEFENDER, { purpose=CombatPurpose.CONVENTIONAL } )	
	
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

	print( "CombatEnd=" .. combat.id, combat:GetLocation().name )

	g_statistic:CombatOccured( combat:CreateDesc(), combat:GetLocation() )

	--combat:Dump()
	combat:EndCombat()
	
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
	if combat.type == CombatType.SIEGE_COMBAT then
		city:RemoveTag( CityTag.SIEGE )
		if winner == CombatSide.ATTACKER then
			-- Determine the ownership of the city if it's a siege combat
			local atkCorpsList = MathUtility_Filter( combat.corps, function ( corps ) return corps:GetGroup() == atkGroup end	)
			CaptureCity( atkGroup, city )
			--Garrisson into the city
			for k, corps in ipairs( atkCorpsList ) do
				print( NameIDToString( corps ) .. " belong " .. corps:GetGroup().name )
				--print( NameIDToString( corps ), "garrison", city.name )
				CorpsDispatchToCity( corps, city, true )
			end
			--Vote Leader
			city:SelectLeader( city:VoteLeader() )
			g_taskMng:FinishTask( atkGroup, TaskType.ATTACK_CITY, combat:GetLocation() )
			g_taskMng:CancelTaskFromOtherGroup( atkGroup, TaskType.ATTACK_CITY, combat:GetLocation() )					
		else
			--go back home
			combat:ForeachCorps( function ( corps )	
				if corps:GetGroup() == combat:GetSideGroup( CombatSide.ATTACKER ) then
					local task = g_taskMng:GetTaskByActor( corps )
					if task then
						task:Fail()
					end
				end
			end )
		end
	elseif combat.type == CombatType.FIELD_COMBAT then
		--go back home
		combat:ForeachCorps( function ( corps )			
			local task = g_taskMng:GetTaskByActor( corps )
			if task then				
				task:Fail()				
			end
		end )
	end
end

function Warfare:EndCombat( combat )
	if combat:GetLocation() then self.combats[combat:GetLocation()] = nil end
	self:ProcessCombatResult( combat )	
end

--Use when group is fallen
function Warfare:EndCombatByGroup( group )
	for k, combat in ipairs( self.combats ) do
		local atkGroup = combat:GetSideGroup( CombatSide.ATTACKER )
		if atkGroup == group then
			self:EndCombat( combat )
		end
	end
end

---------------------------------------

-- Only for test now, support one hour mode
function Warfare:RunOneHour()	
	g_combatDataMng:Foreach( function ( combat )
		if not combat:IsEnd() then
			combat:Run()
		end
	end )
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