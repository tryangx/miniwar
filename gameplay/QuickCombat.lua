-------------------------
-- Quick Combat
--
--
-- 1. Combat will lasts few turns, which determined by the g_season, g_climate and weather
-- 2. Only one side will act in one turn, which determined by Troop Classified, Military Power, Leadership, Sequence and etc.
-- 3. Every turn will result a score evaluate which side wins or draw.
-- 4. Combat will elapsed until one side wins the combat that means they got strategic winning score, even the siege combat is the same.
--                  Initial    Control     Outflank   Suppression    Charge   Siege
-- Infantry                      +3                                            30%
-- Archer           All+3        +1                       +3                   30%
-- Cavalry          All+1        +1           +2          +1                   30%
-- Siege Combat     Siege+2                                                    150%
--
-- Initial
--   The side with higher Initial Value will attack at first, also with a damage bonus
--
--
-- Control
--   Control Value will determins probability which sid act in this turn
--
-- Outflank
--   Outflank Value will always bonus to damage in Field Combat
--
-- Charge
--   High Value will attack at first, also with a damage bonus
--
-- Siege
--   Siege Value will multiple the damage deals to the City Defence
--
-- Suppression
--   Suppression Value 
--
--
--
-- Field Combat Procedure
-- Old version
-- 1. Archer Shoot
-- 2. Cavalry Charge/Shoot 1
-- 2.1 Archer Shoot 2 ( Trigger by Skill )
-- 3. Footman Foward
-- 3.1 Cavalry Charge/Shoot 2 ( Trigger by Skill )
-- 3.2 Archer Shoot 3 ( Trigger by Skill )
-- 4. Footman Melee Fight 1
-- 4.1 Cavalry Charge/Shoot 3 ( Trigger by Skill )
-- 5. Footman Melee Fight 2
-- 6. Footman Melee Pursue
-- New version
-- 1. Shoot Round   -- Actor[ All archer ]  Target [ Charge Line / Front Line / Back Line ]
-- 2. Charge Round  -- Actor[ All Cavalry ] Target [ Charge Line / Front Line / Back ]
-- 3. Forward Round -- Actor [ All footman / All archer ]
-- 4. Fight Round   -- Actor[ All footman / All cavalry / All archer ] Target [ Charge Line / Front Line / Back Line ]
-- 5. Pursue Round  -- Actor[ All cavalry / All footman / All archer ] Target [ Charge Line / Front Line / Back Line ]
--
-- 
-- Siege Combat[Storm]
-- 1. Siege Weapon Shoot
-- 2. Archer Shoot
-- 3. Siege Weapon Charge
-- 4. Footman / Cavalry Charge
--
--
-- Siege Combat[Besiege]
-- 1. Siege Weapon Shoot
--
--

CombatStatus = 
{
	GATE_BROKEN   = 1,	
	WALL_BROKEN   = 2,	
	TOWER_BROKEN  = 3,	
	SIDE_FLEE     = 4,
}

CombatAttitude = 
{
	--Probing Combat
	[0] =
	{
		RETREAT_PROBABILITY            = 6000,
		RETREAT_MORALE                 = 40,
		RETREAT_CASUALTY_RATE          = 0.6,
		GARRISON_RETREAT_PROBABILITY   = 5000,
		GARRISON_RETREAT_MORALE_RATE   = 0.5,
		GARRISON_RETREAT_CASUALTY_RATE = 0.5,		
		FLEE_MORALE_RATE    = 0.3,		
	},	
	
	--Conventional Combat
	[1] =
	{
		RETREAT_PROBABILITY            = 5000,
		RETREAT_MORALE                 = 25,
		RETREAT_CASUALTY_RATE          = 0.5,
		GARRISON_RETREAT_PROBABILITY   = 5000,
		GARRISON_RETREAT_MORALE_RATE   = 0.4,
		GARRISON_RETREAT_CASUALTY_RATE = 0.4,
		FLEE_MORALE_RATE    = 0.2,	
	},
	
	--Desperate Combat
	[2] =
	{
		RETREAT_PROBABILITY            = 5000,
		RETREAT_MORALE                 = 10,
		RETREAT_CASUALTY_RATE          = 0.3,
		GARRISON_RETREAT_PROBABILITY   = 5000,
		GARRISON_RETREAT_MORALE_RATE   = 0.2,
		GARRISON_RETREAT_CASUALTY_RATE = 0.2,
		FLEE_MORALE_RATE    = 0.1,	
	},
}

CombatParams = 
{
	DEFAULT_ELAPSED_TIME     = 60,
	
	-----------------------
	-- Damage Calculation
	-----------------------
	NUMBER_BONUS_TO_DAMAGE_MIN_FACTOR    = 0.1,
	NUMBER_BONUS_TO_DAMAGE_MAX_FACTOR    = 2.5,
	TRAINING_BONUS_TO_DAMAGE_MIN_FACTOR  = 10,
	TRAINING_BONUS_TO_DAMAGE_MAX_FACTOR  = 250,

	-----------------------
	-- Score
	-----------------------
	SCORE_GAP_WITH_BRILLIANTLY_VICTORY   = 150,
	SCORE_GAP_WITH_STRATEGIC_VICTORY     = 80,
	SCORE_GAP_WITH_TACTICAL_VICTORY      = 40,
	
	DAMAGE_SCORE = 
	{
		{ rate = 0.05, score = 2,   morale = 3 },
		{ rate = 0.1,  score = 5,   morale = 6 },
		{ rate = 0.2,  score = 10,  morale = 12 },
		{ rate = 0.3,  score = 15,  morale = 18 },
		{ rate = 0.5,  score = 25,  morale = 30 },
		{ rate = 0.8,  score = 40,  morale = 50 },
		{ rate = 1,    score = 60,  morale = 70 },
		{ rate = 2,    score = 100, morale = 120 },
	},
}

CombatRound = 
{
	PREPARE_ROUND = 0,
	SHOOT_ROUND   = 1,
	CHARGE_ROUND  = 2,
	FORWARD_ROUND = 3,
	FIGHT_ROUND   = 4,
	PURSUE_ROUND  = 5,
	END_ROUND     = 6,
}

--------------------------------------------

Combat = class()

function Combat:__init()
	self.time  = 0
	
	self.day   = 0
	self.stage = 0
	
	self.result = CombatResult.DRAW
		
	self.corps = {}	
	self.troops = {}
	
	self.status = {}
	self.sideOptions = {}
end

local logUtility = LogUtility( "qcombat.log", LogFileMode.WRITE_MANUAL, LogPrinterMode.ON, LogWarningLevel.DEBUG )

function Combat:Log( content )
	logUtility:WriteLog( content, LogWarningLevel.NORMAL )
end

function Combat:FlushLog()
	logUtility:Flush()
end

function Combat:Dump()
	--self:Log( NameIDToString( self:GetSideGroup( CombatSide.ATTACKER ) ) .. " vs " .. NameIDToString( self:GetSideGroup( CombatSide.DEFENDER ) ) .. ( self.type == CombatType.SIEGE_COMBAT and "[Siege]" or "" ) )
	self:Log( "Day     : ".. self.day )
	self:Log( "Time    : ".. math.ceil( self.time / 60 ) )
	self:Log( "Weather : ".. self.weatherTable.name .. "/" .. self.weatherDuration )
	self:Log( "Line    : ".. "Melee=" .. #self.meleeLine .. "," .. "Charge=" .. #self.chargeLine .. "," .. "Front=" .. #self.frontLine .. "," .. "Back=" .. #self.backLine .. "," .. "Defence=" .. #self.defenceLine )
	self:Log( "Round       : ".. MathUtility_FindEnumName( CombatRound, self.round ) )
	self:Log( "Score       : " .. self.atkScore .. "/" .. self.defScore )
	local atkNumber, defNumber = 0, 0
	function dumpTroop( troops )
		for k, troop in ipairs( troops ) do
			print( "	" .. troop.name .. " 	id=" .. troop.id .. " num=" .. troop.number .. " side=" .. MathUtility_FindEnumName( CombatSide, troop._combatSide ) .. " Line=" .. MathUtility_FindEnumName( TroopStartLine, troop._startLine ) .. " Mor=" .. troop.morale .. "/" .. troop.maxMorale )
			if troop:IsCombatUnit() then
				if troop._combatSide == CombatSide.ATTACKER then
					atkNumber = atkNumber + troop.number
				elseif troop._combatSide == CombatSide.DEFENDER then
					defNumber = defNumber + troop.number
				end
			end
		end
	end
	self:Log( "Attacker:" )
	dumpTroop( self.attackers )
	self:Log( "Defender:" )
	dumpTroop( self.defenders )
	self:Log( "Atk/Def     : ".. atkNumber .. "/" .. defNumber )
end

function Combat:DumpResult()
	local atkDeal, defDeal, atkKill, defKill = 0, 0, 0, 0
	self:Log( "Result : "..MathUtility_FindEnumName( CombatResult, self:GetResult() ) )	
	for k, troop in ipairs( self.troops ) do
		if troop:IsCombatUnit() then
			content = "[ "..troop.name.." ]("..troop.id..")"
			content = content .. " Deal/Suf=" .. troop._combatDealDamage .. "/" .. troop._combatSufferDamage
			content = content .. " Atk/Def=" .. troop._combatAttackTimes .. "/" .. troop._combatDefendTimes
			content = content .. " Kill=" .. #troop._combatKillList
			self:Log( content )
			if troop._combatSide == CombatSide.ATTACKER then
				atkDeal = atkDeal + troop._combatDealDamage
				atkKill = atkKill + #troop._combatKillList
			elseif troop._combatSide == CombatSide.DEFENDER then
				defDeal = defDeal + troop._combatDealDamage
				defKill = defKill + #troop._combatKillList
			end
		end
	end
	self:Log( "Atk Deal:" .. atkDeal )
	self:Log( "Atk Kill:" .. atkKill )
	self:Log( "Def Deal:" .. defDeal )
	self:Log( "Def kill:" .. defKill )
end

function Combat:AddTroopToSide( side, troop )
	if not troop then return end
	
	table.insert( self.troops, troop )
	
	troop:NewCombat()

	--init side
	troop._combatSide = side

	--init variables
	troop._armorWeight = 0
	for k, armor in pairs( troop.table.armors ) do
		troop._armorWeight = troop._armorWeight + armor.weight
	end
end

function Combat:AddCorpsToSide( side, corps )
	table.insert( self.corps, corps )

	for k, troop in ipairs( corps.troops ) do
		self:AddTroopToSide( side, troop )
	end
end

function Combat:SetType( combatType )
	self.type = combatType
end

function Combat:SetLocation( id )
	combat.location = g_cityDataMng:GetData( id )
	--print( "location", id, combat.location )
end

function Combat:SetSide( side, data )
	self.sideOptions[side] = data
end

function Combat:SetBattlefield( id )
	self.battlefield = g_battlefieldTableMng:GetData( id )
end

function Combat:SetClimate( id )
	self.g_climateId = id
	g_climate:SetClimate( id )
	g_climate:SetDistrict( self )
	g_climate:SetCurrentWeather( g_climate:GetCurrentWeather() )
end

function Combat:SetSide( side, data )
	self.sideOptions[side] = data
end

function Combat:Preprocess()
	if not self.battlefield then return end

	--start time
	self.time = ( self.battlefield.time + g_season:GetSeasonTable().dawnTime ) * 60
	self.startTime = self.time
	
	--day counter
	self.day = 0
	
	--variables
	self.result = CombatResult.DRAW
	self.round  = CombatRound.PREPARE_ROUND
	self.status = {}
	
	self.atkScore = 0
	self.defScore = 0	
end

function Combat:Embattle()
	self.frontLine   = {}	
	self.backLine    = {}
	self.defenceLine = {}
	self.chargeLine  = {}
	self.meleeLine   = {}
	self.attackers   = {}
	self.defenders   = {}
	for k, troop in ipairs( self.troops ) do
		if troop._combatSide == CombatSide.ATTACKER then
			table.insert( self.attackers, troop )
		elseif troop._combatSide == CombatSide.DEFENDER then
			table.insert( self.defenders, troop )
		end
		troop._startNumber = troop.number
		if self.type == CombatType.FIELD_COMBAT then
			troop._startLine = troop.table.startLine
			if troop.table.startLine == TroopStartLine.FRONT then			
				table.insert( self.frontLine, troop )
			elseif troop.table.startLine == TroopStartLine.BACK then
				table.insert( self.backLine, troop )
			elseif troop.table.startLine == TroopStartLine.DEFENCE then
				table.insert( self.defenceLine, troop )
			elseif troop.table.startLine == TroopStartLine.CHARGE then
				table.insert( self.chargeLine, troop )
			end
		else
			if troop.table.startLine == TroopStartLine.FRONT then				
				--[[
				if troop.table.category == TroopCategory.SIEGE_WEAPON then
					troop._startLine = TroopStartLine.CHARGE
					table.insert( self.charge, troop )
				else
					troop._startLine = TroopStartLine.FRONT
					table.insert( self.frontLine, troop )
				end
				]]
				troop._startLine = TroopStartLine.FRONT
				table.insert( self.frontLine, troop )
			elseif troop.table.startLine == TroopStartLine.BACK then
				troop._startLine = TroopStartLine.FRONT
				table.insert( self.frontLine, troop )
			elseif troop.table.startLine == TroopStartLine.DEFENCE then
				troop._startLine = TroopStartLine.DEFENCE
				table.insert( self.defenceLine, troop )
			elseif troop.table.startLine == TroopStartLine.CHARGE then
				troop._startLine = TroopStartLine.BACK
				table.insert( self.backLine, troop )
			end
			--print( "embattle siege", troop.name, MathUtility_FindEnumName( TroopStartLine, troop._startLine ) )
		end
	end
end

-------------------------------

function Combat:GetLocation()
	return self.location
end

function Combat:GetSideGroup( side )
	local sideCorps = side == CombatSide.ATTACKER and self.attackers or self.defenders
	if #sideCorps > 0 and sideCorps[1]:GetEncampment() then
		return sideCorps[1]:GetEncampment():GetGroup()
	end
	return nil
end

function Combat:GetPurpose( side )
	local purpose = CombatPurpose.CONVENTIONAL	
	if self.sideOptions[side] then
		purpose = self.sideOptions[side].purpose
	end
	return purpose
end

function Combat:GetAttitude( side )
	local purpose = CombatPurpose.CONVENTIONAL	
	if self.sideOptions[side] then
		purpose = self.sideOptions[side].purpose
	end
	return CombatAttitude[purpose]
end


function Combat:IsCombatEnd()
	return self.result > CombatResult.TACTICAL_LOSE or self.round >= CombatRound.END_ROUND
end

function Combat:IsEnd()
	return self:IsCombatEnd()
end

function Combat:GetSideStatus( side, includeWounded )
	local number, morale, fatigue, startNumber, maxNumber, count = 0, 0, 0, 0, 0, 0
	for k, target in ipairs( self.troops ) do
		if target._combatSide == side and target:IsInCombat() and target:IsCombatUnit() then
			count = count + 1
			number = number + target.number
			startNumber = startNumber + target._startNumber
			maxNumber = maxNumber + target.maxNumber
			morale = morale + target.morale
			fatigue = fatigue + target.fatigue
			if includeWounded then
				number = number + target.wounded
			end
		end
	end
	return number, count, count > 0 and math.floor( morale / count ) or 0, count > 0 and math.floor( fatigue / count ) or 0, startNumber, maxNumber
end

-------------------------------


function Combat:GetResult()
	local atkScore, defScore = self.atkScore, self.defScore
	if math.abs( atkScore - defScore ) >= CombatParams.SCORE_GAP_WITH_BRILLIANTLY_VICTORY then
		return atkScore > defScore and CombatResult.BRILLIANT_VICTORY or CombatResult.DISASTROUS_LOSE
	elseif math.abs( atkScore - defScore ) >= CombatParams.SCORE_GAP_WITH_STRATEGIC_VICTORY then		
		return atkScore > defScore and CombatResult.STRATEGIC_VICTORY or CombatResult.STRATEGIC_LOSE
	elseif math.abs( atkScore - defScore ) >= CombatParams.SCORE_GAP_WITH_TACTICAL_VICTORY then
		return atkScore > defScore and CombatResult.TACTICAL_VICTORY or CombatResult.TACTICAL_LOSE
	end
	return CombatResult.DRAW
end

function Combat:GetWinner()
	if self.result == CombatResult.DRAW then
		return CombatSide.NEUTRAL
	elseif self.result == CombatResult.STRATEGIC_LOSE or self.result == CombatResult.TACTICAL_LOSE or self.result == CombatResult.DISASTROUS_LOSE then
		return Combat.DEFENDER
	end
	return CombatSide.ATTACKER
end

function Combat:AddStatus( status )
	MathUtility_PushBack( self.status, status )
end

function Combat:RemoveStatus( status )
	MathUtility_Remove( self.status, status )
end

function Combat:HasStatus( status )
	return MathUtility_IndexOf( self.status, status )
end

-------------------------------

function Combat:NextDay()
	--start time
	self.time = ( self.battlefield.time + g_season:GetSeasonTable().dawnTime ) * 60
	self.startTime = self.time
	--day counter
	self.day = self.day + 1	
	self.round = CombatRound.PREPARE_ROUND	
	self.result = CombatResult.DRAW
	
	self:Embattle()
	
	if #self.defenders <= 0 then
		self.atkScore = CombatParams.SCORE_GAP_WITH_STRATEGIC_VICTORY
		self.defScore = 0		
	end
end

function Combat:RunOneDay()
	self:NextDay()
	repeat		
		self:Run()
	until self:IsEnd()
	
	print( "Combat=", self.id, " Result=", MathUtility_FindEnumName( CombatResult, self.result ) )
end

function Combat:Run()
	if not self.battlefield then
		self:Log( "Battlefield invalid" ) return
	end
	
	if self:IsEnd() then
		return
	end
	
	-- update elapsed
	self._elapsedTime = CombatParams.DEFAULT_ELAPSED_TIME
		
	-- update time( 24h, minute unit )
	local oldHour = math.ceil( self.time / 60 )
	self.time = self.time + self._elapsedTime		
	local minutesOfDay = 24 * 60
	if self.time > minutesOfDay then
		self.time = self.time - minutesOfDay
		self.day  = self.day + 1
	end
	local newHour = math.ceil( self.time / 60 )
	local hourAlter = newHour ~= oldHour
	
	-- update weather	
	if hourAlter then
		g_climate:SetDistrict( self )
		g_climate:Update()
	end
	
	self:Dump()
		
	InputUtility_Pause()
		
	if self.type == CombatType.FIELD_COMBAT then
		if self.round == CombatRound.PREPARE_ROUND then
			self.round = CombatRound.SHOOT_ROUND
		end
		if self.round == CombatRound.SHOOT_ROUND then
			self:Shoot()
		elseif self.round == CombatRound.CHARGE_ROUND then
			self:Charge()
		elseif self.round == CombatRound.FORWARD_ROUND then
			self:Forward()
		elseif self.round == CombatRound.FIGHT_ROUND then
			self:Fight()
		elseif self.round == CombatRound.PURSUE_ROUND then
			print( "purse ", self:HasStatus( CombatStatus.SIDE_FLEE ) )
			if self:HasStatus( CombatStatus.SIDE_FLEE ) then				
				self:Pursue()
			end
		end
		self.round = self.round + 1
	elseif self.type == CombatType.SIEGE_COMBAT then
		self:Batter()
		self:CityDefence()
		if self.round == CombatRound.PREPARE_ROUND then
			self.round = CombatRound.SHOOT_ROUND
		elseif self.round == CombatRound.SHOOT_ROUND then			
			self:Shoot()
			local purpose = self:GetPurpose( CombatSide.ATTACKER )
			if purpose == CombatPurpose.DESPERATE then
				self.round = CombatRound.FORWARD_ROUND
			elseif purpose == CombatPurpose.CONVENTIONAL then
				self.round = CombatRound.FORWARD_ROUND
			else
				self.round = CombatRound.END_ROUND
			end
		elseif self.round == CombatRound.FORWARD_ROUND then
			self:Forward()
			self:Fight()
			local purpose = self:GetPurpose( CombatSide.ATTACKER )
			if purpose == CombatPurpose.DESPERATE then
				self.round = CombatRound.FIGHT_ROUND
			else
				self.round = CombatRound.END_ROUND
			end
		elseif self.round == CombatRound.FIGHT_ROUND then
			self:Fight()
			self.round = CombatRound.END_ROUND
		elseif self.round == CombatRound.PURSUE_ROUND then
			self.round = CombatRound.END_ROUND
		end
	end
	
	self:NextTurn()
	
	self.result = self:GetResult()
	
	if self:IsCombatEnd() then
		self:End()
	end
end

function Combat:NextTurn()
	for k, troop in ipairs( self.troops ) do
		if troop:IsInCombat() then
			troop:NextCombatTurn()
		end
	end
	
	local atkNum, atkTroop, atkMorale, atkFatigue, atkStartNum, atkMaxNum = self:GetSideStatus( CombatSide.ATTACKER )
	local defNum, defTroop, defMorale, defFatigue, defStartNum, defMaxNum = self:GetSideStatus( CombatSide.DEFENDER )	
	if atkNum <= 0 or defNum <= 0 then
		self.atkScore = defNum == 0 and CombatParams.SCORE_GAP_WITH_BRILLIANTLY_VICTORY or 0
		self.defScore = atkNum == 0 and CombatParams.SCORE_GAP_WITH_BRILLIANTLY_VICTORY or 0
		self.round = CombatRound.END_ROUND
		return
	end
	if not self:HasStatus( CombatStatus.SIDE_FLEE ) then
		--side retreat
		local atkAttitude = self:GetAttitude( CombatSide.ATTACKER )
		local defAttitude = self:GetAttitude( CombatSide.ATTACKER )		
		if atkMorale < atkAttitude.RETREAT_MORALE then
			if Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Retreat Prob" ) <= atkAttitude.RETREAT_PROBABILITY then
				for _, troop in ipairs( self.troops ) do
					if troop:IsCombatUnit() and troop._combatSide == CombatSide.ATTACKER then
						troop:Flee()					
					end
				end
				print( "Attacker retreat" )
				self:AddStatus( CombatStatus.SIDE_FLEE )
				self.round = CombatRound.PURSUE_ROUND
			end
		end
		if self.type == CombatType.SIEGE_COMAT then
			if defNum / defMaxNum < ( 1 - defAttitude.GARRISON_RETREAT_CASUALTY_RATE ) then
				if Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Retreat prob" ) <= defAttitude.GARRISON_RETREAT_PROBABILITY then
					for _, troop in ipairs( self.troops ) do
						if troop:IsCombatUnit() and troop._combatSide == CombatSide.DEFENDER then
							troop:Flee()						
						end
					end
					print( "Garrison retreat" )
					self:AddStatus( CombatStatus.SIDE_FLEE )
					self.round = CombatRound.PURSUE_ROUND
				end
			end
		else
			if defMorale < defAttitude.RETREAT_MORALE then
				if Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Retreat Prob" ) <= defAttitude.RETREAT_PROBABILITY then
					for _, troop in ipairs( self.troops ) do
						if troop:IsCombatUnit() and troop._combatSide == CombatSide.DEFENDER then
							troop:Flee()
						end
					end
					print( "Defender retreat" )
					self:AddStatus( CombatStatus.SIDE_FLEE )
					self.round = CombatRound.PURSUE_ROUND
				end
			end
		end
	end
end

function Combat:FindTargetInLine( troop, line )
	local troops = {}
	local lineTroops = nil
	if line == TroopStartLine.FRONT then
		lineTroops = self.frontLine
	elseif line == TroopStartLine.BACK then	
		lineTroops = self.backLine
	elseif line == TroopStartLine.DEFENCE then		
		lineTroops = self.defenceLine
	elseif line == TroopStartLine.CHARGE then
		lineTroops = self.chargeLine
	elseif line == TroopStartLine.MELEE then
		lineTroops = self.meleeLine
	end	
	--print( "find line", MathUtility_FindEnumName( TroopStartLine, line ), lineTroops and #lineTroops or 0 )
	if not lineTroops then return nil end
	for k, target in ipairs( lineTroops ) do
		if target:IsInCombat() and target._combatSide ~= troop._combatSide then
			table.insert( troops, target)
		end
	end
	if #troops == 0 then return nil end
	local index = Random_SyncGetRange( 1, #troops, "Random Target" )
	--print( "total target=" .. #troops, #lineTroops, MathUtility_FindEnumName( TroopStartLine, line ), " index=", index )
	return troops[index]
end

function Combat:FindTarget( troop )
	local target = nil
	for line = TroopStartLine.MELEE, TroopStartLine.BACK, -1 do
		target = self:FindTargetInLine( troop, line )
		if target then break end 
	end
	--print( NameIDToString( troop ) .. " Find target=" .. ( target and target.name or "" ) )
	return target
end

function Combat:FindDefenceTarget( troop, params )
	local targetList = {}
	for _, target in ipairs( self.defenceLine ) do
		if target._combatSide ~= troop._combatSide then
			if ( params.isGate and target.table.category == TroopCategory.GATE )
			or ( params.isWall and target.table.category == TroopCategory.DEFENCE )
			or ( params.isTower and target.table.category == TroopCategory.TOWER )
			or target:IsDefence() then
				table.insert( targetList, target )
			end
		end
	end
	if #targetList == 0 then return nil end
	local index = Random_SyncGetRange( 1, #targetList, "Random Target" )
	return targetList[index]
end

function Combat:FindFledTarget( troop )
	local targetList = {}
	for _, target in ipairs( self.troops ) do
		if target:IsCombatUnit() and target._combatSide ~= troop._combatSide then
			if target:IsFled() then
				table.insert( targetList, target )
			end
		end
	end
	if #targetList == 0 then return nil end
	local index = Random_SyncGetRange( 1, #targetList, "Random Target" )
	return targetList[index]
end

function Combat:CalcDamage( troop, target, weapon, armor, params )
	local trainingRate = 100
	if params.isMelee then
		local range = Random_SyncGetRange( 1, math.abs( troop.training - target.training ), "Random Damage BonusRate" ) 
		range = troop.training > target.training and range or -range
		trainingRate = MathUtility_Clamp( 100 + range, CombatParams.TRAINING_BONUS_TO_DAMAGE_MIN_FACTOR, CombatParams.TRAINING_BONUS_TO_DAMAGE_MAX_FACTOR )
	end

	local number = troop.number
	if params.isMelee and troop.number ~= target.number then
		number = troop.number > target.number and math.floor( target.number * ( troop.number / target.number ) ^ 0.5 ) or math.floor( troop.number * ( target.number / troop.number ) ^ 0.5 )
		--print( "!!!!ismelee number", number )
	end
	local modNumber = math.floor( number < self.battlefield.width and number or self.battlefield.width + ( number - self.battlefield.width ) / 2 )
	
	local weaponRate = armor and math.max( 10, ( weapon.power - armor.protection ) ) / ( 100 + armor.protection ) or 1
	
	local dmg = modNumber * weaponRate * trainingRate * 0.0035
		
	--print( "    num=" .. modNumber, "weapon=" .. math.floor( weaponRate * 350 ) .. "("..weapon.power..","..armor.protection..")", "train=" .. trainingRate )
	
	local modulus = 1
	
	-- Critical
	if params.isMelee then
		local criticalProb = ( troop.morale - target.morale ) * 10000 / ( troop.morale + target.morale )
		if criticalProb > 0 and Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "critical prob" ) < criticalProb then dmg = dmg * 1.5 end
	end
	
	-- Damage Modification
	if params.isCounter then dmg = dmg * 0.65 end
	if params.isMissile and target._startLine == TroopStartLine.CHARGE then dmg = dmg * 0.65 print( "!!!!!!!!!!!!!!shoot moving" ) end	
	if target:IsAttacked() then dmg = dmg * MathUtility_Clamp( 1 - 0.35 * target:IsAttacked(), 0.2, 2 ) end
	if target:IsDefended() then dmg = dmg * MathUtility_Clamp( 1 + 0.35 * target:IsDefended(), 0.3, 2.5 ) end
	if troop._combatSide == CombatSide.ATTACKER and self.type == CombatType.SIEGE_COMBAT then dmg = dmg * 0.35 end
	if troop._combatSide == CombatSide.DEFENDER and self.type == CombatType.SIEGE_COMBAT then dmg = dmg * 0.5 end
	
	-- Trait
	
	
	-- Weather penalty
	if self.weatherTable then
		if params.isMelee and self.weatherTable.meleePenalty ~= 0 then
			local penaltyAdd = self:GetTraitValue( troop, TraitEffectType.WEATHER_MALADAPTION, 0 )
			local penaltyRdu = self:GetTraitValue( troop, TraitEffectType.WEATHER_ADAPTION, 0 )
			dmg = dmg * ( 100 - self.weatherTable.meleePenalty + penaltyAdd - penaltyRdu ) * 0.01
			--self:Log( "Weather Melee Penalty=" .. self.weatherTable.meleePenalty .. " dmg=" .. dmg )
		elseif params.isMissile and self.weatherTable.missilePenalty ~= 0 then
			local penaltyAdd = self:GetTraitValue( troop, TraitEffectType.WEATHER_MALADAPTION, 0 )
			local penaltyRdu = self:GetTraitValue( troop, TraitEffectType.WEATHER_ADAPTION, 0 )
			dmg = dmg * ( 100 - self.weatherTable.missilePenalty + penaltyAdd - penaltyRdu ) * 0.01
			--self:Log( "Weather Missile Penalty=" .. self.weatherTable.missilePenalty .. " dmg=" .. dmg )
		end
	end
	
	return math.floor( dmg )
end

function Combat:Retreat( target )
	target:Flee()
end

function Combat:Flee( target )
	target:Flee()
	
	if self.type == CombatType.FIELD_COMBAT or target._combatSide == CombatSide.ATTACKER then
		local totalNum, troop, troop, morale, fatigue, startNum, maxNum = self:GetSideStatus( target._combatSide )
		for k, troop in ipairs( self.troops ) do
			if troop:IsCombatUnit() and troop.id ~= target.id and troop._combatSide == target._combatSide then
				local rate = target.number * 100 / totalNum
				local delta = troop.level - target.level - rate
				if delta > 0 then
					target.morale = target.morale - delta
					if target.morale <= 0 then target.morale = 1 end
				end
			end
		end
	end
end

function Combat:LostMorale( target, morale )
	target.morale = target.morale - morale
	if target.morale <= 0 then
		target.morale = 0
		self:Flee( target )
	end
end

function Combat:Hit( troop, target, params )
	if not params then return end	
	if not troop:IsAlive() then return end
	
	local atkWeapon = nil
	if params.isMissile then atkWeapon = troop:GetFireWeapon()
	elseif params.isCharge then atkWeapon = troop:GetChargeWeapon()
	elseif params.isMelee then atkWeapon = troop:GetCloseWeapon()	
	elseif params.isTower then atkWeapon = troop:GetFireWeapon()
	elseif params.isSiege then atkWeapon = troop:GetSiegeWeapon()
	end
	if not atkWeapon then 
		print( NameIDToString( troop ) .. " don't have right weapon", params.isMissile, params.isCharge, params.isMelee, params.isCounter )
		return
	end
	local defArmor = target:GetDefendArmor( atkWeapon )
	local damage = self:CalcDamage( troop, target, atkWeapon, defArmor, params )
	
	--weapon & armor
	troop:UseWeapon( atkWeapon )
	target:UseArmor( defArmor )

	local oldNumber = target.number
	--damage	
	damage = target:SufferDamage( damage )
	troop:DealDamage( damage )
		
	--score
	if target:IsCombatUnit() then
		local rate = damage / oldNumber
		local score = 0
		for k, data in ipairs( CombatParams.DAMAGE_SCORE ) do
			if rate < data.rate then 
				--print( MathUtility_FindEnumName( CombatSide, troop._combatSide ) .. " score+", data.score, rate )
				score = data.score
				self:LostMorale( target, math.floor( target.morale * data.rate + data.morale ) )			
				break
			end
		end
		if troop._combatSide == CombatSide.ATTACKER then
			self.atkScore = self.atkScore + score
		else
			self.defScore = self.defScore + score
		end
	end
	
	if params.isCounter then
		print( NameIDToString( troop ) .. "use ["..atkWeapon.name.."] counter " .. NameIDToString( target ) .. " deal dmg=" .. damage )
	else
		print( NameIDToString( troop ) .. "use ["..atkWeapon.name.."] hit " .. NameIDToString( target ) .. " deal dmg=" .. damage )
	end		
	if not params.isCounter and not params.isPursue and ( params.isMelee or params.isCharge ) then
		if troop._startLine ~= TroopStartLine.CHARGE or target:IsAttacked() < 1 then
			self:Hit( target, troop, { isCounter = true, isMelee = true } )
		end
	end
end

-- 1. Shoot Round   -- Actor[ All archer ]  Target [ Charge Line / Front Line / Back Line ]
function Combat:Shoot()
	local lineTroops = MathUtility_Shuffle( self.troops, g_globalRandomizer )
	for k, troop in ipairs( lineTroops ) do
		if troop:IsInCombat() and troop:IsSiegeWeapon() and troop:CanFire() then
			local target = self:FindTarget( troop )
			if target then
				self:Hit( troop, target, { isMissile = true } )
			end
		end
	end
end

function Combat:Batter()
	if not self:HasStatus( CombatStatus.GATE_BROKEN ) then
		local lineTroops = MathUtility_Shuffle( self.frontLine, g_globalRandomizer )
		for k, troop in ipairs( lineTroops ) do			
			if troop:IsInCombat() and troop:IsSiegeWeapon() and troop:CanSiegeAttack() then
				local target = self:FindDefenceTarget( troop, { isGate = true } )
				if not target then
					--todo
					self:AddStatus( CombatStatus.GATE_BROKEN )
					return
				else
					self:Hit( troop, target, { isSiege = true } )
				end
			end
		end
	end
	if not self:HasStatus( CombatStatus.WALL_BROKEN ) or not self:HasStatus( CombatStatus.TOWER_BROKEN ) then
		local lineTroops = MathUtility_Shuffle( self.backLine, g_globalRandomizer )
		for k, troop in ipairs( lineTroops ) do
			if troop:IsInCombat() and troop:CanSiegeAttack() then
				local target = nil
				if not self:HasStatus( CombatStatus.WALL_BROKEN ) then
					target = self:FindDefenceTarget( troop, { isWall = true } )
					if not target then
						--todo
						self:AddStatus( CombatStatus.WALL_BROKEN )
						if self:HasStatus( CombatStatus.TOWER_BROKEN ) then
							return
						end
					else
						self:Hit( troop, target, { isSiege = true } )
					end
				end				
				if not target or not self:HasStatus( CombatStatus.TOWER_BROKEN ) then
					target = self:FindDefenceTarget( troop, { isTower = true } )
					if not target then
						--todo
						self:AddStatus( CombatStatus.TOWER_BROKEN )
						if self:HasStatus( CombatStatus.WALL_BROKEN ) then
							return
						end
					else
						self:Hit( troop, target, { isSiege = true } )
					end
				end
			end
		end
	end
end

-- 2. Charge Round  -- Actor[ All Cavalry ] Target [ Charge Line / Front Line / Back ]
function Combat:Charge()
	local lineTroops = MathUtility_Shuffle( self.chargeLine, g_globalRandomizer )
	for k, troop in ipairs( lineTroops ) do
		if troop:IsInCombat() and troop:CanCharge() then
			local target = self:FindTarget( troop )
			if target then
				self:Hit( troop, target, { isCharge = true } )
			end
		end
	end
end

-- 3. Forward Round -- Actor [ All footman / All archer ]
function Combat:Forward()
	local removes = {}
	for k, troop in ipairs( self.chargeLine ) do
		troop._startLine = TroopStartLine.MELEE
	end
	self.meleeLine = self.chargeLine
	self.chargeLine = {}

	for k, troop in ipairs( self.frontLine ) do
		if troop:IsInCombat() and troop:CanForward() then
			if self.type == CombatType.FIELD_COMBAT or troop._combatSide == CombatSide.DEFENDER or troop.table.category == TroopCategory.INFANTRY then
				troop._startLine = TroopStartLine.MELEE
				table.insert( self.meleeLine, troop )
				table.insert( removes, troop )
			end
		end
	end
	for k, target in ipairs( removes ) do
		MathUtility_Remove( self.frontLine, target )
	end	
	for k, troop in ipairs( self.backLine ) do
		if troop:IsInCombat() and troop:CanForward() and troop._combatSide == CombatSide.DEFENDER then
			troop._startLine = TroopStartLine.MELEE
			table.insert( self.meleeLine, troop )
			table.insert( removes, troop )
		end
	end
	for k, target in ipairs( removes ) do
		MathUtility_Remove( self.backLine, target )
	end
end

-- 4. Fight Round   -- Actor[ All footman / All cavalry / All archer ] Target [ Charge Line / Front Line / Back Line ]
function Combat:Fight()
	local lineTroops = MathUtility_Shuffle( self.meleeLine, g_globalRandomizer )
	for k, troop in ipairs( lineTroops ) do
		if troop:IsInCombat() then
			local target = self:FindTarget( troop )
			if target then
				self:Hit( troop, target, { isMelee = true } )
			end
		end
	end
end

-- 5. Pursue Round
function Combat:Pursue()
	local lineTroops = MathUtility_Shuffle( self.meleeLine, g_globalRandomizer )
	for k, troop in ipairs( lineTroops ) do				
		if troop.table.category == TroopCategory.CAVALRY and troop:IsInCombat() and not troop:IsFled() then			
			local target = self:FindFledTarget( troop )			
			if target then				
				self:Hit( troop, target, { isMelee = true, isPursue = true } )
			end
		end
	end
end

function Combat:CityDefence()
	for k, troop in ipairs( self.defenceLine ) do
		if troop.table.category == TroopCategory.TOWER then
			local target = self:FindTarget( troop )
			if target then
				self:Hit( troop, target, { isTower = true } )
			end
		end
	end
end

function Combat:End()
	--print( "combat end" )
	self:Dump()
	self:DumpResult()
end