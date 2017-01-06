Warfare = class()

function Warfare:__init()
	self.plans = {}
end

--Add siege
function Warfare:AddWarfarePlan( corps, city )
	local id = MathUtility_IndexOf( self.plans, city, "from" )
	if id then
		-- field combat
		local plan = self.plans[id]
		local from = plan.from
		local to   = city
		local attacker = plan.corps
		local defender = corps
		self.plans[id] = nil
		table.insert( self.plans, { from = from, to = to, attacker = attacker, defender = defender, siege = false } )
		InputUtility_Pause( "Add plan" )
	else
		InputUtility_Pause( "Add siege plan" )		
		table.insert( self.plans, { from = corps.location, to = city, corps = corps, siege = true } )
	end	
end

function Warfare:Update( elapasedTime )
	-- process all plans
	for k, plan in pairs( self.plans ) do
		if plan.siege == true then
			self:AddSiegeCombat( plan.corps, plan.to )
		else
			self:AddFieldCombat( plan.attacker, plan.defender )
		end
	end
	
	self:RunOneDay()
	
	self.plans = {}
end

function Warfare:AddFieldCombat( attacker, defender )
	combat = g_combatDataMng:NewData()
	
	--use current date?
	g_season:SetDate( g_calendar.month, g_calendar.day )
	
	combat:SetType( CombatType.FIELD_COMBAT )
	combat:SetBattlefield( 1 )
	combat:SetClimate( 1 )
	combat:SetGroup( CombatSide.ATTACKER, attacker:GetGroup() )
	combat:SetGroup( CombatSide.DEFENDER, defender:GetGroup() )
	combat:SetSide( CombatSide.ATTACKER, { purpose=CombatPurpose.CONVENTIONAL } )
	combat:SetSide( CombatSide.DEFENDER, { purpose=CombatPurpose.CONVENTIONAL } )	
	
	-- trop sequence
	combat:AddCorpsToSide( CombatSide.ATTACKER, attacker )	
	combat:AddCorpsToSide( CombatSide.DEFENDER, defender )
		
	combat:Preprocess()
end


function Warfare:AddSiegeCombat( corps, city )	
	combat = g_combatDataMng:NewData()
	
	--use current date?
	g_season:SetDate( g_calendar.month, g_calendar.day )
	
	combat:SetType( CombatType.SIEGE_COMBAT )
	combat:SetLocation( city.id )
	combat:SetBattlefield( 1 )
	combat:SetClimate( 1 )
	combat:SetGroup( CombatSide.ATTACKER, corps:GetGroup() )
	combat:SetGroup( CombatSide.DEFENDER, city:GetGroup() )
	combat:SetSide( CombatSide.ATTACKER, { purpose=CombatPurpose.CONVENTIONAL } )
	combat:SetSide( CombatSide.DEFENDER, { purpose=CombatPurpose.CONVENTIONAL } )	
	
	-- troop sequence
	combat:AddCorpsToSide( CombatSide.ATTACKER, corps )
	for k, defender in ipairs( city.corps ) do
		if defender:GetLocation() == city then
			combat:AddCorpsToSide( CombatSide.DEFENDER, defender )
		end
	end
	for k, defender in ipairs( city.troops ) do
		if not defender:GetCorps() and defender:GetLocation() == city then
			combat:AddTroopToSide( CombatSide.DEFENDER, defender )
		end
	end
	
	--add wall
	combat:AddTroopToSide( CombatSide.DEFENDER, g_troopDataMng:GetData( 100 ) )	
	--add gate
	combat:AddTroopToSide( CombatSide.DEFENDER, g_troopDataMng:GetData( 200 ) )
	--add tower
	combat:AddTroopToSide( CombatSide.DEFENDER, g_troopDataMng:GetData( 210 ) )
	
	combat:Preprocess()
	
	InputUtility_Pause( "combat occur" )
end

--Add skirmish
--[[
function Warfare:AddSkirmish( corps, field )	
end
]]

function Warfare:Test( atks, defs )
	combat = g_combatDataMng:NewData()
	
	--use current date?
	g_season:SetDate( g_calendar.month, g_calendar.day )
	
	--now only support city, extend to field in the future
	--combat:SetType( CombatType.SIEGE_COMBAT )
	combat:SetType( CombatType.FIELD_COMBAT )
	combat:SetLocation( 10 )
	combat:SetBattlefield( 3 )
	combat:SetClimate( 1 )
	combat:SetGroup( CombatSide.ATTACKER, atks:GetGroup() )
	combat:SetGroup( CombatSide.DEFENDER, defs:GetGroup() )
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
		--add militia
		combat:AddTroopToSide( CombatSide.DEFENDER, g_troopDataMng:GetData( 500 ) )	
	end
	
	combat:Preprocess()
	
	--print( "testCombat", combat.id )
end

function Warfare:ProcessCombatResult( combat )
	-- Determine the ownership of the city if it's a siege combat
	if combat.type == CombatType.SIEGE_COMBAT then		
		local winner = combat:GetWinner()
		if winner == CombatSide.ATTACKER then
			local group = combat:GetSideGroup( CombatSide.ATTACKER )
			if group then
				group:CaptureCity( combat )
			end
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
		InputUtility_Pause( "combat exist", g_combatDataMng:GetCount() )
	end
	--print( "Combat Left " .. #g_combatDataMng.datas .. "/" .. g_combatDataMng.count )
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
			self:ProcessCombatResult( combat )
			InputUtility_Pause( "!!!!!!!!!!!!!!!! Remove Combat", "end combat" )
			return true
		end
		return false
	end )
end