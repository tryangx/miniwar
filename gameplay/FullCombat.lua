------------------------------
-- Blueprint
--
-- 
-- Combat Rhythm
--	More de-buff, like ??
--  Attack combat( every fight will result as advance or draw, so each troop will gain adv points, more adv points will bonus troop )
--  Less Troop Size will trigger more tactic, like ambush( extension )
--
--------------------------------
-- Rule Description
--
-- Morale Attribute
--	Affect attack action, low morale means need to reform
--  Easy to lose, hit, threaten, killed, fled, surrendered will lead to lose it
--  Hard to restore, normally restore during days, but encourage skill will help to recover
--
-- Fatigue Attribute
--	Affect the damage dealt or suffered
--  Easy to increase, move? attack will lead to increase it
--  Hard to reduce, only during preparation
--
-- Disguise
--	Affect the damage and combat event
--
--------------------------------
--
--	Finished Part
--
-- Combat Event
--
-- Field Combat process
--	1. Encourage
--  2. Charge
--  3. Shoot
--  4. Fight
--  5. Reform
--
-- Siege Combat process
--	1. Siege weapon attack
--  2. Siege weapon charge
--  3. Shoot
--  4. Footman Attack
--  5. Reform
--
--
--
--


CombatAction = 
{
    IDLE         = 0,
	REST         = 1,
	FIRE         = 2,
	ATTACK       = 3,	
	FORWARD      = 4,
	DEFEND       = 5,	
	-- trigger preparation skill
	PREPARE      = 6,	
	BACKWARD     = 8,
	FLEE         = 9,	
	HOLD         = 10,	
	TOWARD       = 11,	
	HEAL         = 12,	
	REFORM       = 13,	
	COOLDOWN     = 14,	
	SURRENDER    = 15,	
	RETREAT      = 16,
}

CombatPosition = 
{	
	ATTACKER_POS = 0,
	
	DEFENDER_POS = 1,
	
	ATTACKER_MOVE = 1,
	
	DEFENDER_MOVE = -1,
	
	TROOP_SIZE    = 10,

	TROOP_RADIUS  = 5,
}

CombatPhase = 
{
	PREPARATION  = 0,
	INCOMBAT     = 1,	
	NIGHTFALL    = 2,	
	MIDNIGHT     = 3,	
	DAWN         = 4,
}

CombatStage = 
{
	UPDATING      = 0,
	THINKING      = 1,	
	FIRST_ROUND   = 2,	
	SECOND_ROUND  = 3,	
	FINISH_ACTION = 4,
}

CombatAttitude = 
{
	--Probing Combat
	[0] =
	{
		--Retreat Condition
		--Dead Rate means the number died in this combat compare to the maximum number
		DEAD_RATE_TO_RETREAT       = 0.15,
	
		--Surrender Condition
		MORALE_RATE_TO_SURRENDER    = 0,
		ALIVE_RATE_TO_SURRENDER     = 0.2,
				
		--Reform Condition
		MORALE_RATE_TO_REFORM       = 0.8,
		ALIVE_RATE_TO_REFORM        = 0.8,
		
		--Flee Condition
		MORALE_RATE_TO_FLEE         = 0.2,
		ALIVE_RATE_TO_FLEE          = 0.6,
		
		--Sally Condition
		ENEMY_RATIO_TO_SALLY        = 0.6,
		SALLY_PROB_BASE             = 3000,
		
		--Rest Condition
		FATIGUE_TO_REST             = 60,
		
		--Probing attack won't attack
		SIEGE_ATTACK_AFTER_BROKE_WALL = true,
	},
	
	--Conventional Combat
	[1] =
	{
		--Retreat Condition
		DEAD_RATE_TO_RETREAT        = 0.4,
	
		--Surrender Condition
		MORALE_RATE_TO_SURRENDER    = 0,
		ALIVE_RATE_TO_SURRENDER     = 0.2,
		
		--Rest Condition
		FATIGUE_TO_REST             = 80,
		
		--Reform Condition
		MORALE_RATE_TO_REFORM       = 0.65,
		ALIVE_RATE_TO_REFORM        = 0.65,
		
		--Flee Condition
		MORALE_RATE_TO_FLEE         = 0.2,
		ALIVE_RATE_TO_FLEE          = 0.4,
		
		--Sally Condition
		ENEMY_RATIO_TO_SALLY        = 0.5,
		SALLY_PROB_BASE             = 3000,
		
		--Siege
		SIEGE_ATTACK_AFTER_BROKE_WALL = true,
	},
		
	--Desperate Combat
	[2] =
	{
		--Retreat Condition
		DEAD_RATE_TO_RETREAT        = 0.7,
		
		--Surrender Condition
		MORALE_RATE_TO_SURRENDER    = 0,
		ALIVE_RATE_TO_SURRENDER     = 0.1,
	
		--Rest Condition
		FATIGUE_TO_REST             = 100,
		
		--Reform Condition
		MORALE_RATE_TO_REFORM       = 0.4,		
		ALIVE_RATE_TO_REFORM        = 0.4,
		
		--Flee Condition
		MORALE_RATE_TO_FLEE         = 0.1,
		ALIVE_RATE_TO_FLEE          = 0.1,
	
		--Sally Condition
		ENEMY_RATIO_TO_SALLY        = 0.3,
		SALLY_PROB_BASE             = 2000,
		
		SIEGE_ATTACK_AFTER_BROKE_WALL = false,
	},
}

CombatParams = 
{
	-----------------------
	-- Time
	-----------------------
	-- every update 
	DEFAULT_ELAPSED_TIME     = 60,
	-- hold time
	HOLD_TIME                = 120,	
	-- buff time
	PERMANENT_BUFF_TIME      = -1,
	
	-----------------------
	-- Number
	-----------------------
	BLUFF_NUMBER_FACTOR      = 2,
	DECOY_NUMBER_FACTOR      = 2,
	
	-----------------------
	-- Movement
	-----------------------
	-- flee movement bonus
	FLEE_MOVEMENT_BONUS      = 2,	
	
	-----------------------
	-- fatigue
	-----------------------
	-- fatigue decreased unit per time( minute )
	FATIGUE_RECOVER_PER_TIME    = 0.1,
	FATIGUE_TO_MOVE_FACTOR      = 0.75,
	FATIGUE_TO_MOVE_BACK_FACTOR = 0,
	FATIGUE_TO_RIDE_FACTOR      = 0.25,
	FATIGUE_TO_ATTACK_FACTOR    = 1,
	FATIGUE_TO_DEFEND_FACTOR    = 0.5,
	REDUCE_FATIGUE_TO_PREPARATION_FACTOR = 0.35,
	
	-----------------------
	-- Wounded
	-----------------------
	MIN_WOUNDED_PERCENTAGE    = 50,
	MAX_WOUNDED_PERCENTAGE    = 80,
	
	-----------------------
	-- Heal
	-----------------------
	HEAL_WOUNDED_PERCENTAGE  = 25,
	HEAL_NUMBER_PERCENTAGE   = 5,
	
	-----------------------
	-- Damage Calculation
	-----------------------
	NUMBER_BONUS_TO_DAMAGE_MIN_FACTOR    = 0.1,
	NUMBER_BONUS_TO_DAMAGE_MAX_FACTOR    = 2.5,
	FATIGUE_PENALTY_TO_DAMAGE_MIN_FACTOR = 10,
	FATIGUE_PENALTY_TO_DAMAGE_MAX_FACTOR = 100,
	FLANK_BONUS_TO_DAMAGE_FACTOR         = 1.5,
	BLOCK_BONUS_TO_DAMAGE_FACTOR         = 0.6,
	COUNTER_BONUS_TO_DAMAGE_FACTOR       = 0.6,
	MOVING_BONUS_TO_DAMAGE_FACTOR        = 0.6,
	PURSUE_BONUS_TO_DAMAGE_FACTOR        = 1.5,
	DEFENCE_BONUS_TO_DAMAGE_FACTOR       = 1.5,
	CRITICAL_BONUS_TO_DAMAGE_FACTOR      = 1.5,
	CRITICAL_DAMAGE_CONDITION_MORALE_RATE  = 0.25,
	CRITICAL_DAMAGE_CONDITION_PROBABILITY  = 3500,
	
	-----------------------
	-- Morale relative
	-----------------------	
	-- Break gate morale de-buff
	BREAK_GATE_MAXMORALE_DEBUFF_FACTOR   = 0.5,
	BREAK_GATE_MAXMORALE_BONUS_FACTOR    = 0.3,
	BREAK_WALL_MAXMORALE_BONUS_FACTOR    = 0.3,
	
	-- Affect morale level reduction	
	MORALE_EFFECTION_REDUCTION_BY_LEVEL  = 0.5,	
	
	-- Restore morale
	RESTORE_MORALE_RATE_TO_PREPARATION_FACTOR = 0.3,	
	
	-- Affect morale been hit	
	MORALE_REDUCE_TO_HIT_MIN_FACTOR      = 0.5,
	MORALE_REDUCE_TO_HIT_MAX_FACTOR      = 2,	
	MORALE_EFFECTION_TO_BLOCK_FACTOR     = 0.5,
	MORALE_EFFECTION_TO_COUNTER_FACTOR   = 0.5,
	MORALE_EFFECTION_TO_CHARGE_FACTOR    = 2,
	MORALE_EFFECTION_TO_MISSILE_FACTOR   = 0.5,
	MORALE_EFFECTION_TO_FLANK_FACTOR     = 2,
	
	-----------------------
	-- Score
	-----------------------
	SCORE_GAP_TO_FLEE                    = 1,	
	SCORE_GAP_TO_SURRENDER               = 2,
	SCORE_GAP_WITH_STRATEGIC_VICTORY     = 1,
	SCORE_GAP_WITH_TACTICAL_VICTORY      = 0,
	
}

CombatSwitch = 
{
	--fatigue relative
	ENABLE_RESTORE_FATIGUE                   = false,
	ENABLE_MOVEMENT_FATIGUE                  = false,
	ENABLE_PREPARATION_PHASE_RESTORE_FATIGUE = true,
	
	--morale relative
	ENABLE_RESTORE_MORALE                    = true,
}

CombatBuff = 
{
	CHARGING        = 1,
	
	BLUFF           = 2,
	
	DECOY           = 3,
	
	STEALTH         = 4,
	
	DEFENCE_WORK    = 5,
}

CombatStatus = 
{
	GATE_BROKEN   = 1,
	
	WALL_BROKEN   = 2,
}

--------------------------------------------------

Combat = class()

function Combat:__init()
	self.time  = 0
	
	self.day   = 0
	
	self.result = CombatResult.DRAW
		
	self.corps = {}
	
	self.troops = {}
	
	self.status = {}
	
	self.sides = {}
	
	self.sideOptions = {}
end

-----------------------------------------------

function Combat:Load( data )
	self.id = data.id or 0
	
	self.type = data.type or CombatType.FIELD_COMBAT
	
	-- where is taken place, now only support city
	self.location = data.location or 0
	
	self.battlefield = data.battlefield or 0
	
	self.g_climateId   = data.g_climateId or 0

	self.corps = MathUtility_Copy( data.corps )
	
	self.troops = {}-- MathUtility_Copy( data.troops )
	
	self.phase = data.phase or CombatPhase.PREPARATION
	
	self.day = data.day or 0
	
	self.time  = data.time or 0
	
	self.weatherType = data.weatherType or WeatherType.SUNNY
	
	self.weatherDuration = data.weatherDuration or 0
	
	self.sides = MathUtility_Copy( data.sides )
	
	self.sideOptions = MathUtility_Copy( data.sideOptions )
end

function Combat:SaveData( data )
	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	
	Data_OutputValue( "id", self )
	Data_OutputValue( "type", self )
	Data_OutputValue( "location", self, "id", 0 )
	Data_OutputValue( "battlefield", self, "id" )	
	Data_OutputValue( "g_climateId", self )
			
	Data_OutputTable( "corps", self, "id" )
	Data_OutputTable( "troops", self, "id" )
	Data_OutputTable( "sideOptions", self )	
	Data_OutputTable( "sides", self )
		
	Data_OutputValue( "phase", self )
	Data_OutputValue( "day", self )
	Data_OutputValue( "time", self )
	Data_OutputValue( "weatherType", self )
	Data_OutputValue( "weatherDuration", self )
	
	Data_OutputTable( "status", self )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
end

function Combat:ConvertID2Data()	
	self.location    = g_cityDataMng:GetData( self.battlefield )
	self.battlefield = g_battlefieldTableMng:GetData( self.battlefield )
	
	self:SetClimate( self.g_climateId )

	local corps = {}
	for k, corpsId in ipairs( self.corps ) do		
		local corps = g_corpsDataMng:GetData( corpsId )
		local inx = MathUtility_IndexOf( self.sides, corps, "corps" )
		if inx then
			self:AddCorpsToSide( self.sides[inx].side, corps )
		end
	end
	self.corps = corps
end

-----------------------------------------------

local logUtility = LogUtility( "fcombat.log", LogWarningLevel.DEBUG, true )

function Combat:Log( content )
	logUtility:WriteLog( content )
end

function Combat:AddTroopToSide( side, troop )
	if not troop then return end
	
	self:Log( "["..troop.name.."] attend combat" )		
			
	--insert table
	table.insert( self.troops, troop )
	
	troop:NewCombat()
	
	-- init size
	if troop.table.radius == 0 then
		troop.table.radius = CombatPosition.TROOP_RADIUS
	end
	
	--init side
	troop._combatSide = side
			
	--init tactic
	if troop.tactic == CombatTactic.DEFAULT then
		if troop.table.category == TroopCategory.FOOTSOLDIER then
			troop.tactic = CombatTactic.ATTACK
		elseif troop.table.category == TroopCategory.ARTILLERY then
			troop.tactic = CombatTactic.FIRE
		elseif troop.table.category == TroopCategory.CAVALRY then
			troop.tactic = CombatTactic.ATTACK
		else
			troop.tactic = CombatTactic.ATTACK
		end
		--print( "tactic", troop.name, troop.tactic )
	end
	
	if self.type == CombatType.SIEGE_COMBAT and troop._combatSide == CombatSide.DEFENDER then
		troop.tactic = CombatTactic.DEFEND
	end
	
	--init variables
	troop._armorWeight = 0
	for k, armor in pairs( troop.table.armors ) do
		troop._armorWeight = troop._armorWeight + armor.weight
	end
end

function Combat:AddCorpsToSide( side, corps )
	table.insert( self.corps, corps )
		
	table.insert( self.sides, { corps = corps, side = side } )
	
	for k, troop in ipairs( corps.troops ) do
		--print( "add troop", troop )
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

function Combat:Init()
	if not self.battlefield then return end
	
	--init phase
	self.phase = CombatPhase.PREPARATION

	--start time
	self.time = ( self.battlefield.time + g_season:GetSeasonTable().dawnTime ) * 60
	self.startTime = self.time
	--day counter
	self.day = 0
	
	--variables
	self.result = CombatResult.DRAW
	self.status = {}
	
	--combat events
	combatEventTrigger:InitData()
	combatEventTrigger:SetCombatEventEnviroment( CombatEventEnviroment.RANDOMIZER, g_syncRandomizer )
	combatEventTrigger:SetCombatEventEnviroment( CombatEventEnviroment.COMBAT_POINTER, self )
	
	--embattle
	self:Embattle()
	
	self:DumpPhase()	
	self:DumpMap()	
end

--use for load
function Combat:Resume()
	for k, troop in ipairs( self.troops ) do
		troop:NewCombat()
	end

	--combat events
	combatEventTrigger:InitData()
	combatEventTrigger:SetCombatEventEnviroment( CombatEventEnviroment.RANDOMIZER, g_syncRandomizer )
	combatEventTrigger:SetCombatEventEnviroment( CombatEventEnviroment.COMBAT_POINTER, self )
end

function Combat:NextDay()
	self.phase = CombatPhase.PREPARATION
	
	--start time
	self.time = ( self.battlefield.time + g_season:GetSeasonTable().dawnTime ) * 60
	self.startTime = self.time
	--day counter
	self.day = self.day + 1
	
	self.result = CombatResult.DRAW	
	self:Embattle()
	
	--undefended
	if self.atkNumber <= 0 or self.defNumber <= 0 then
		
	end
	
	self:DumpPhase()
	self:DumpMap()
end

function Combat:EmbattleList( list, atkIndex, defIndex, xOffset, fillLine )
	if not fillLine then atkIndex, defIndex = math.ceil( atkIndex / self.battlefield.column ) * self.battlefield.column, math.ceil( defIndex / self.battlefield.column ) * self.battlefield.column end
	local column = self.battlefield.column
	local startY = math.ceil( column / 2 ) - 1
	for k, troop in ipairs( list ) do
		local line = 0
		if troop._combatSide == CombatSide.ATTACKER then
			troop._combatPosX = CombatPosition.ATTACKER_POS * self.battlefield.distance - math.floor( atkIndex / column ) * CombatPosition.TROOP_SIZE + xOffset + troop.table.radius
			line = atkIndex % column
			atkIndex = atkIndex + 1
		elseif troop._combatSide == CombatSide.DEFENDER then
			troop._combatPosX = CombatPosition.DEFENDER_POS * self.battlefield.distance + math.floor( defIndex / column ) * CombatPosition.TROOP_SIZE + xOffset - troop.table.radius
			line = defIndex % column
			defIndex = defIndex + 1
		end
		if column % 2 == 0 then
			troop._combatPosY = ( startY + ( line % 2 == 1 and 1 or -1 ) * math.ceil( line / 2 ) ) * CombatPosition.TROOP_SIZE
		else
			--print( line, ( line % 2 == 1 and -1 or 1 ), math.ceil( line / 2 ), ( startY + ( line % 2 == 1 and -1 or 1 ) * math.ceil( line / 2 ) ) )
			troop._combatPosY = ( startY + ( line % 2 == 1 and -1 or 1 ) * math.ceil( line / 2 ) ) * CombatPosition.TROOP_SIZE
		end
		troop._startNumber = troop.number + troop.wounded
		troop._startPosX = troop._combatPosX 
		troop._startPosY = troop._combatPosY
		troop._startLine = math.floor( atkIndex / self.battlefield.column )
					
		Debug_Log( "Embattle:", troop.name, troop._combatPosX, troop._combatPosY )
	end
	return atkIndex, defIndex
end

function Combat:Embattle()
	-- 1. Put defences
	-- 2. Put troop in front line
	-- 3. Put troop no specified
	-- 4. Put troop in back line	
	local defenceList  = {}
	local frontList    = {}
	local backList     = {}
	local otherList    = {}
	for k, troop in ipairs( self.troops ) do
		if troop:IsInCombat() then
			if troop:IsCombatUnit() then
				if troop.table.startLine == TroopStartLine.FRONT then
					table.insert( frontList, troop )
				elseif troop.table.startLine == TroopStartLine.BACK then
					table.insert( backList, troop )
				else
					table.insert( otherList, troop )
				end
			elseif troop.table.startLine == TroopStartLine.DEFENCE then
				table.insert( defenceList, troop )
			else				
			end
		end
	end

	local atkIndex = 0
	local defIndex = 0
	local defenceOffset = 0
	if self.type == CombatType.SIEGE_COMBAT then defenceOffset = CombatPosition.TROOP_RADIUS end
	atkIndex, defIndex = self:EmbattleList( defenceList, atkIndex, defIndex, 0 )
	atkIndex, defIndex = self:EmbattleList( frontList, atkIndex, defIndex, 0 )
	atkIndex, defIndex = self:EmbattleList( otherList, atkIndex, defIndex, 0, true )
	atkIndex, defIndex = self:EmbattleList( backList,  atkIndex, defIndex, 0 )
end

-------------------------------------
-- Helper Method

function Combat:IsTroopUnderProtection( troop )
	
end

function Combat:IsTroopMoving( troop )
	return troop._combatAction == CombatAction.FORWARD or troop.cobmatAction == CombatAction.TOWARD or troop._combatAction == CombatAction.FLEE or troop._combatAction == CombatAction.RETREAT or troop._combatAction == CombatAction.BACKWARD
end

function Combat:IsTroopAdjacent( troop, target )
	return math.abs( troop._combatPosY - target._combatPosY ) <= CombatPosition.TROOP_SIZE
end

function Combat:IsTroopsInRow( troop, target )
	return math.abs( troop._combatPosY - target._combatPosY ) <= CombatPosition.TROOP_RADIUS
end

function Combat:IsTroopInFlank( troop, target )
	local deltaY = math.abs( troop._combatPosY - target._combatPosY )
	local deltaX = math.abs( troop._combatPosX - target._combatPosX )
	--print( "flank,", deltaX, deltaY, deltaX <= CombatPosition.TROOP_RADIUS and deltaY <= CombatPosition.TROOP_SIZE and deltaY >= CombatPosition.TROOP_RADIUS )
	return deltaX <= CombatPosition.TROOP_RADIUS and deltaY <= CombatPosition.TROOP_SIZE and deltaY >= CombatPosition.TROOP_RADIUS
end

function Combat:IsExposed( troop )
	return troop:HasBuff( CombatBuff.STEALTH ) == 0 and troop.disguise == 0
end

function Combat:IsInFront( troop, target )
	if troop._combatSide == CombatSide.ATTACKER then
		--print( troop.name, target._combatPosX, troop._combatPosX )
		return target._combatPosX > troop._combatPosX
	elseif troop._combatSide == CombatSide.DEFENDER then
		--print( troop.name, target._combatPosX, troop._combatPosX )
		return target._combatPosX < troop._combatPosX
	end
	return false
end

function Combat:IsBehindDefence( troop )
	if troop._combatSide == CombatSide.DEFENDER then
		return troop._combatPosX >= troop._startPosX
	end
	return false
end

function Combat:CalcDistanceInRow( troop, target )
	return math.abs( troop._combatPosX - target._combatPosX )
end

function Combat:CalcDistance( troop, target )
	return math.abs( troop._combatPosX - target._combatPosX ) + math.abs( troop._combatPosY - target._combatPosY )
end

function Combat:FilterTroops( fn )
	local list = {}
	for k, troop in pairs( self.troops ) do
		if fn( troop ) then
			table.insert( list, troop )
		end
	end
	return list
end

function Combat:ForEachCorps( fn )
	for k, corps in pairs( self.corps ) do
		fn( corps )
	end
end

function Combat:ForEachTroop( fn )
	for k, troop in pairs( self.troops ) do
		fn( troop )
	end
end

function Combat:ForEachSideTroop( side, fn )
	for k, troop in pairs( self.troops ) do
		if troop._combatSide == side then fn( troop ) end
	end
end

---------------------------------------------
-- Data & Attributes Getter

function Combat:RandomRange( min, max, desc )
	return Random_SyncGetRange( min, max, desc )
end

function Combat:GetAttitude( side )
	local purpose = CombatPurpose.CONVENTIONAL	
	if self.sideOptions[side] then
		purpose = self.sideOptions[side].purpose	
	end
	return CombatAttitude[purpose]
end

function Combat:GetLeaderTraitValue( effect )
	for k, troop in ipairs( self.troops ) do
		if self:GetTraitValue( troop, effect ) then
			return troop
		end
	end
	return nil
end

function Combat:HasTraitValue( effect )
	for k, troop in ipairs( self.troops ) do
		if self:GetTraitValue( troop, effect ) then
			return troop
		end
	end
	return nil
end

function Combat:GetTraitValue( troop, effect, default )
	local condition = nil
	if effect == TraitEffectType.TROOP_MASTER 
		or effect == TraitEffectType.TROOP_RESIST then
		params = troop.table.category
	end
	local trait = troop:QueryTrait( effect, params )
	if not trait then return default end
	--check probability
	if trait.prob then
		if self:RandomRange( 1, RandomParams.MAX_PROBABILITY, "Trait Trigger Prob" ) > trait.prob then
			return default
		end
	end
	if trait.range then
		return self:RandomRange( 1, trait.range, "Trait Range" ) + trait.value
	end
	return trait.value
end

function Combat:GetAliveRatio( troop )
	return MathUtility_Clamp( ( troop.number + troop.wounded ) / troop.maxNumber, 0, 1 )
end

function Combat:GetTroopMaxMorale( troop )
	local maxMorale = troop.maxMorale
	if troop._combatSide == CombatSide.DEFENDER and self.type == CombatType.SIEGE_COMBAT and self.status[CombatStatus.GATE_BROKEN] == true then
		maxMorale = math.ceil( maxMorale * CombatParams.BREAK_GATE_MAXMORALE_DEBUFF_FACTOR )
	end
	return maxMorale
end

function Combat:GetMovement( troop )
	local move = troop.movement
	local moveAdd = self:GetTraitValue( troop, TraitEffectType.MOVEMENT_ADDITION, 0 )
	local moveRdu = self:GetTraitValue( troop, TraitEffectType.MOVEMENT_REDUCTION, 0 )
	if moveAdd ~= 0 or moveRdu ~= 0 then
		move = math.ceil( move * ( 100 + moveAdd + moveRdu ) * 0.01 )		
		self:Log( "Movement addition="..moveAdd..",reduction="..moveRdu )
	end
	if self.weatherTable and self.weatherTable.movePenalty > 0 then
		move = math.ceil( move * ( 100 - self.weatherTable.movePenalty ) * 0.01 )
		self:Log( "Bad weather, Movement penalty=".. self.weatherTable.movePenalty )
	end
	return move
end

function Combat:GetTroopNumber( troop )
	if troop:HasBuff( CombatBuff.BLUFF ) then
		return troop.number * CombatParams.BLUFF_NUMBER_FACTOR
	elseif troop:HasBuff( CombatBuff.DECOY ) then
		return troop.number * CombatParams.DECOY_NUMBER_FACTOR
	end
	return troop.number
end

---------------------------------------------
-- Target List

function Combat:GetTargetList( fn )
	local list = {}
	for k, troop in pairs( self.troops ) do
		if fn( troop ) then
			table.insert( list, troop )
		end
	end
	return list
end

function Combat:GetAliveTargetList( fn )
	local list = {}
	for k, troop in pairs( self.troops ) do
		if troop:IsCombatUnit() and troop:IsInCombat() and fn( troop ) then
			table.insert( list, troop )
		end
	end
	return list
end

function Combat:GetLocation()
	return self.location
end

function Combat:GetSideGroup( side )
	for k, data in ipairs( self.sides ) do
		if data.side == side then
			return data.corps:GetGroup()
		end
	end
	return nil
end

function Combat:GetOppSide( side )
	if side == CombatSide.ATTACKER then
		return CombatSide.DEFENDER
	elseif side == CombatSide.DEFENDER then
		return CombatSide.ATTACKER
	end
	return CombatSide.INVALID
end


function Combat:GetDefenceList( target )
	local list = {}
	for k, troop in pairs( self.troops ) do
		if troop:IsAlive() and troop:IsDefence() and troop._combatSide ~= target._combatSide then		
			table.insert( list, troop )
		end
	end
	return list
end

function Combat:GetGateList( target )
	local list = {}
	for k, troop in pairs( self.troops ) do
		if troop:IsAlive() and troop:IsGate() and troop._combatSide ~= target._combatSide then		
			table.insert( list, troop )
		end
	end
	return list
end

function Combat:GetDefenceTarget( target )
	local targetList = {}
	for k, troop in pairs( self.troops ) do
		if troop:IsAlive() and troop:IsDefence() and troop._combatSide ~= target._combatSide then
			table.insert( targetList, troop )
		end
	end
	if #targetList ~= 0 then
		target:ChooseTarget( targetList[1], "defence target" )
		return true
	end	
	target:ChooseTarget( nil, "defence target" )
	return false
end

function Combat:GetSiegeTarget( troop )
	if not troop:HasMissileWeapon() then
		local targetList = self:GetGateList( troop )
		if #targetList > 0 then		
			troop:ChooseTarget( targetList[1], "siege target" )
			return true
		end
	end
	return self:GetDefenceTarget( troop )
end

--[[
function Combat:GetFlankTarget( troop, isFriend )
	local targetList = {}	
	if isFriend then			
		for k, target in pairs( self.troops ) do
			if target:IsCombatUnit() and target:IsInCombat() and troop:IsFriend( target ) and self:IsTroopInFlank( troop, target ) then
				local distance = self:CalcDistanceInRow( troop, target )
				MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
			end
		end
	else	
		for k, target in pairs( self.troops ) do
			if target:IsCombatUnit() and target:IsInCombat() and troop:IsEnemy( target ) and self:IsTroopInFlank( troop, target ) then
				local distance = self:CalcDistanceInRow( troop, target )
				MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
			end
		end
	end		
	if #targetList ~= 0 then
		troop:ChooseTarget( targetList[1].troop, "flank target" )
		return true
	end
	troop:ChooseTarget( nil, "flank target" )
	return false
end
]]

function Combat:GetRangeTarget( troop )
	local targetList = {}	
	for k, target in pairs( self.troops ) do
		if target:IsCombatUnit() and troop._combatSide ~= target._combatSide and target:IsInCombat() and not self:IsExposed( target ) then
			if self:IsTroopsInRow( troop, target ) then
				local distance = self:CalcDistanceInRow( troop, target )
				if distance >= WeaponParams.LONG_RANGE_WEAPON_LENGTH + troop.table.radius + target.table.radius then
					MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
				end
			elseif self:IsTroopAdjacent( troop, target ) then
				local distance = self:CalcDistanceInRow( troop, target ) * 10
				if distance >= WeaponParams.LONG_RANGE_WEAPON_LENGTH + troop.table.radius + target.table.radius then
					MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
				end
			end
		end
	end
	if #targetList ~= 0 then
		troop:ChooseTarget( targetList[1].troop, "fire target" )
		return true
	end
	troop:ChooseTarget( nil, "fire target" )
	return false
end

-- Get front target in row
function Combat:GetFrontTarget( troop )
	local targetList = {}	
	for k, target in pairs( self.troops ) do
		if target:IsCombatUnit() and target:IsInCombat() and troop:IsEnemy( target ) and self:IsTroopsInRow( troop, target ) and self:IsInFront( troop, target ) and not self:IsExposed( target ) then
			local distance = self:CalcDistanceInRow( troop, target )
			MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
		end
	end
	if #targetList ~= 0 then
		troop:ChooseTarget( targetList[1].troop, "front target" )
		return true
	end
	troop:ChooseTarget( nil, "front target" )
	return false
end

function Combat:GetFrontFriendly( troop )
	local targetList = {}	
	for k, target in pairs( self.troops ) do
		if target:IsCombatUnit() and target:IsInCombat() and troop:IsFriend( target ) and self:IsTroopsInRow( troop, target ) and self:IsInFront( troop, target ) then								
			local distance = self:CalcDistanceInRow( troop, target )
			MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
		end
	end
	if #targetList ~= 0 then
		troop:ChooseTarget( targetList[1].troop, "front target" )
		return true
	end
	troop:ChooseTarget( nil, "front target" )
	return false
end

function Combat:GetFrontBarrier( troop )
	local targetList = {}	
	for k, target in pairs( self.troops ) do
		if target:IsInCombat() and troop:IsOther( target ) and self:IsInFront( troop, target ) and ( self:IsTroopsInRow( troop, target ) or not target:IsCombatUnit() ) then
			local distance = self:CalcDistanceInRow( troop, target )
			MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
		end
	end
	if #targetList ~= 0 then
		troop:ChooseTarget( targetList[1].troop, "front barrier" )
		return true
	end
	troop:ChooseTarget( nil, "front barrier" )
	return false
end

function Combat:GetBehindBarrier( troop )
	local targetList = {}	
	for k, target in pairs( self.troops ) do
		if target:IsInCombat() and troop:IsOther( target ) and self:IsTroopsInRow( troop, target ) and not self:IsInFront( troop, target ) then
			local distance = self:CalcDistanceInRow( troop, target )
			MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
		end
	end		
	if #targetList ~= 0 then
		troop:ChooseTarget( targetList[1].troop, "behind barrier" )
		return true
	end
	troop:ChooseTarget( nil, "behind barrier" )
	return false
end

-- Get nearest target ( maybe not in a row )
function Combat:GetNearestTarget( troop )
	local targetList = {}	
	for k, target in pairs( self.troops ) do
		if target:IsCombatUnit() and target:IsInCombat() and troop._combatSide ~= target._combatSide then
			local distance = self:CalcDistanceInRow( troop, target )
			MathUtility_Insert( targetList, { troop = target, distance = distance }, "distance" )
		end
	end
	
	if #targetList ~= 0 then
		troop:ChooseTarget( targetList[1].troop, "nearest target" )
		return true
	end
	troop:ChooseTarget( nil, "nearest target" )
	return false
end

-- get close target list, used for melee
function Combat:GetCloseTarget( troop )	
	local targetList = {}
	--print( "find close target", troop.name )
	if #targetList == 0 then
		targetList = self:GetAliveTargetList( function ( target )
			--print( "check "..target.name..",".. self:CalcDistanceInRow( troop, target ), WeaponParams.LONG_WEAPON_LENGTH + troop.table.radius + target.table.radius )
			return target:IsCombatUnit() and troop._combatSide ~= target._combatSide and self:IsTroopAdjacent( troop, target ) and self:CalcDistanceInRow( troop, target ) < WeaponParams.LONG_WEAPON_LENGTH + troop.table.radius + target.table.radius
		end )
	end
	if #targetList ~= 0 then
		troop:ChooseTarget( targetList[self:RandomRange( 1, #targetList, "Random Target" )], "close target" )
		return true
	end
	troop:ChooseTarget( nil, "close target" )
	return false
end

-- get adjacent target, becaused these is no enemy in the same row
function Combat:GetAdjacentTarget( troop )
	local targetList = {}
	if #targetList == 0 then
		targetList = self:GetAliveTargetList( function ( target )
			return target:IsCombatUnit() and troop._combatSide ~= target._combatSide and self:IsTroopAdjacent( troop, target )
		end )
	end
	if #targetList ~= 0 then		
		troop:ChooseTarget( targetList[self:RandomRange( 1, #targetList, "Random Target" )], "adjacent target" )
		return true
	end
	troop:ChooseTarget( nil, "adjacent target" )
	return false
end

function Combat:IsCombatEnd()
	return self.result > CombatResult.COMBAT_END_RESULT
end

function Combat:IsDayEnd()
	return self.phase == CombatPhase.MIDNIGHT
end

function Combat:IsEnd()
	return self:IsDayEnd() or self:IsCombatEnd()
end

-----------------------
-- Score Evaluation
--
-- Should be more complex than simply count the lines each taken
--
-----------------------
function Combat:CalcScore()
	local atkColumns = {}
	local defColumns = {}
	local atkNumber = 0
	local defNumber = 0
	for k, troop in pairs( self.troops ) do
		if troop:IsInCombat() then
			local column = math.floor( troop._combatPosY / CombatPosition.TROOP_SIZE )
			if troop._combatSide == CombatSide.ATTACKER then
				if atkColumns[column] then atkColumns[column] = 1 else atkColumns[column] = 1 end
				atkNumber = atkNumber + troop.number
			elseif troop._combatSide == CombatSide.DEFENDER then
				if defColumns[column] then defColumns[column] = 1 else defColumns[column] = 1 end
				defNumber = defNumber + troop.number
			end
		end
	end
	if atkNumber == 0 then return 0, CombatParams.SCORE_GAP_WITH_STRATEGIC_VICTORY end
	if defNumber == 0 then return CombatParams.SCORE_GAP_WITH_STRATEGIC_VICTORY, 0 end	
	local atkScore = 0
	local defScore = 0
	for i = 1, self.battlefield.column do		
		local score1 = atkColumns[i] or 0
		local score2 = defColumns[i] or 0
		--print( score1, score2 )
		if score1 > 0 and score2 == 0 then
			atkScore = atkScore + 1
		elseif score2 > 0 and score1 == 0 then
			defScore = defScore + 1
		end
	end
	--print( atkScore, defScore )
	return atkScore, defScore
end

function Combat:GetScoreGap( troop )
	local atkScore, defScore = self:CalcScore()
	if troop._combatSide == CombatSide.ATTACKER then
		return atkScore - defScore
	end
	return defScore - atkScore
end

function Combat:GetResult()
	local atkScore, defScore = self:CalcScore()	
	--print( "!!!!!!!!!!!!!!!!!!!!!!result score", atkScore, defScore )
	if atkScore >= defScore + CombatParams.SCORE_GAP_WITH_STRATEGIC_VICTORY then
		return CombatResult.STRATEGIC_VICTORY
	elseif atkScore >= defScore + CombatParams.SCORE_GAP_WITH_TACTICAL_VICTORY then
		return CombatResult.TACTICAL_VICTORY
	elseif atkScore + CombatParams.SCORE_GAP_WITH_STRATEGIC_VICTORY <= defScore then
		return CombatResult.STRATEGIC_LOSE
	elseif atkScore + CombatParams.SCORE_GAP_WITH_TACTICAL_VICTORY <= defScore then
		return CombatResult.TACTICAL_LOSE
	end
	return CombatResult.DRAW
end

function Combat:GetWinner()
	if self.result == CombatResult.DRAW then
		return CombatSide.NEUTRAL
	elseif self.result == CombatResult.STRATEGIC_LOSE or self.result == CombatResult.TACTICAL_LOSE then
		return Combat.DEFENDER
	end
	return CombatSide.ATTACKER
--[[
	local aliveTroops = {}
	aliveTroops[CombatSide.ATTACKER] = 0
	aliveTroops[CombatSide.DEFENDER] = 0
	for k, troop in pairs( self.troops ) do			
		if troop:IsInCombat() and troop:IsCombatUnit() then
			if aliveTroops[troop._combatSide] then
				aliveTroops[troop._combatSide] = aliveTroops[troop._combatSide] + 1
			else
				aliveTroops[troop._combatSide] = 1
			end
		end
	end
	if aliveTroops[CombatSide.ATTACKER] == 0 and aliveTroops[CombatSide.DEFENDER] ~= 0 then
		--print( "Defender is winner" )
		return CombatSide.DEFENDER
	end
	if aliveTroops[CombatSide.DEFENDER] == 0 and aliveTroops[CombatSide.ATTACKER] ~= 0 then
		--print( "Attacker is winner" )
		return CombatSide.ATTACKER
	end
	return CombatSide.NEUTRAL
--]]
end

function Combat:GetSideStatus( side, includeWounded )
	local number, morale, fatigue, startNumber, maxNumber, count = 0, 0, 0, 0, 0, 0
	self:ForEachTroop( function ( target )
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
			if target.number < 0 or target.wounded < 0 then
				print( "Warning !!!!!!!!!!!!!!!!!!!", target.number, target.wounded, target.name )
			end
		end
	end )
	return number, count, count > 0 and math.floor( morale / count ) or 0, count > 0 and math.floor( fatigue / count ) or 0, startNumber, maxNumber
end

---------------------------------------

function Combat:DumpPhase()	
	local atkNum, atkTroop, atkMorale, atkFatigue, atkStartNum, atkMaxNum = self:GetSideStatus( CombatSide.ATTACKER )
	local defNum, defTroop, defMorale, defFatigue, defStartNum, defMaxNum = self:GetSideStatus( CombatSide.DEFENDER )
	local totalAtkNum, atkTroop = self:GetSideStatus( CombatSide.ATTACKER, true )
	local totalDefNum, defTroop = self:GetSideStatus( CombatSide.DEFENDER, true )
	self:Log( "Combat Phase [".. self.phase .. "]" )
	self:Log( NameIDToString( self:GetSideGroup( CombatSide.ATTACKER ) ) .. " vs " .. NameIDToString( self:GetSideGroup( CombatSide.DEFENDER ) ) .. ( self.type == CombatType.SIEGE_COMBAT and "[Siege]" or "" ) )
	self:Log( "Day     : ".. self.day )
	self:Log( "Time    : ".. math.ceil( self.time / 60 ) )
	self:Log( "Turn    : ".. MathUtility_FindEnumName( CombatPhase, self.phase ) )
	self:Log( "Weather : ".. self.weatherTable.name .. "/" .. self.weatherDuration )
	self:Log( "Att Num : ".. atkNum .. "+"..totalAtkNum-atkNum.." *" .. atkTroop )
	self:Log( "Def Num : ".. defNum .. "+"..totalDefNum-defNum.." *" .. defTroop )
	local atkDie = atkMaxNum ~= 0 and math.floor( ( atkStartNum - atkNum ) * 100 / atkMaxNum ) or 0
	local defDie = defMaxNum ~= 0 and math.floor( ( defStartNum - defNum ) * 100 / defMaxNum ) or 0
	self:Log( "Atk Sta : ".. "Die=" .. atkDie .. " Mor=" .. atkMorale .. " Fat=" .. atkFatigue .. " Att=" .. MathUtility_FindEnumName( CombatPurpose, self.sideOptions[CombatSide.ATTACKER].purpose ) )
	self:Log( "Def Sta : ".. "Die=" .. defDie .. " Mor=" .. defMorale .. " Fat=" .. defFatigue .. " Att=" .. MathUtility_FindEnumName( CombatPurpose, self.sideOptions[CombatSide.DEFENDER].purpose ) )	
end

function Combat:DumpMap()		
	local map = {}
	local minX, maxX = 999, 0
	for k, troop in ipairs( self.troops ) do
		if troop:IsInCombat() then
			local yGrid = math.floor( troop._combatPosY / CombatPosition.TROOP_SIZE )
			if not map[yGrid] then
				map[yGrid] = {}
			end
			local xGrid = math.floor( troop._combatPosX / CombatPosition.TROOP_RADIUS )
			if map[yGrid][xGrid] then
				self:Log( "Collision in ["..xGrid * CombatPosition.TROOP_RADIUS.."]["..yGrid.."] with "..troop:GetNameDesc() .. troop:GetCoordinateDesc()..",".. map[yGrid][xGrid]:GetNameDesc() .. map[yGrid][xGrid]:GetCoordinateDesc())
			else
				map[yGrid][xGrid] = troop
				--print( "add", xGrid, yGrid, troop )
			end
			if xGrid < minX then minX = xGrid end
			if xGrid > maxX then maxX = xGrid end
		end
	end
	--print( "min,max", minX, maxX )
	local width  = maxX - minX
	local height = self.battlefield.column
	--coordinate
	local coorName = " "
	for x = minX, maxX do
		if x < 0 then
			coorName = coorName .. " " .. ( x * CombatPosition.TROOP_RADIUS ) .. " "
		elseif x < 10 then
			coorName = coorName .. " " .. ( x * CombatPosition.TROOP_RADIUS ) .. " "
		else
			coorName = coorName .. " " .. ( x * CombatPosition.TROOP_RADIUS ) .. " "
		end
	end
	self:Log( coorName )
	
	for y = 0, height - 1 do
		local content = y .. " "
		for x = minX, maxX do
			local troop = nil
			if map[y] then troop = map[y][x] end
			if troop then
				local id = " "
				if troop._combatSide == CombatSide.ATTACKER then
					id = "A"
				else
					id = "D"
				end
				if troop.table.category == TroopCategory.FOOTSOLDIER then
					id = id .. "F"
				elseif troop.table.category == TroopCategory.ARTILLERY then
					id = id .. "A"
				elseif troop.table.category == TroopCategory.CAVALRY then
					id = id .. "C"
				elseif troop.table.category == TroopCategory.DEFENCE then
					id = id .. "W"
				elseif troop.table.category == TroopCategory.GATE then
					id = id .. "G"
				elseif troop.table.category == TroopCategory.SIEGE_WEAPON then
					id = id .. "S"
				else
					id = troop.table.category
				end
				content = content .. id .. "  "
			else
				content = content .. "    "
			end
		end
		self:Log( content )
	end
end

function Combat:DumpTroop( troop )	
	self:Log( "========")
	if troop:IsInCombat() then
		local targetName = ""
		if troop._combatTarget then
			targetName = troop._combatTarget.name.."["..troop._combatTarget.id.."]("..troop._combatTarget._combatPosX..","..troop._combatTarget._combatPosY..")"
		end
		self:Log( "[ "..troop.name.." ]("..troop.id..") "..troop._combatPosX..","..troop._combatPosY.." "..MathUtility_FindEnumName( CombatAction, troop._combatAction ) .. "=" .. targetName )
		if troop:GetLeader() then
			self:Log( "Leader    : "..troop.leader.name )
		end
		self:Log( "Number    : "..troop.number.."+"..troop.wounded .. "/" .. troop.maxNumber .. "(" ..self:GetTroopNumber( troop ) .. ")" )
		--self:Log( "X,Y       : "..troop._combatPosX..","..troop._combatPosY.."("..math.ceil(troop._combatPosX/CombatPosition.TROOP_RADIUS)..","..math.ceil(troop._combatPosY/CombatPosition.TROOP_RADIUS)..")" )		
		self:Log( "Mor/Fat/CD: "..troop.morale.."/"..troop.fatigue.."/"..troop._combatCD )
		if troop._combatAction ~= nil then
		--self:Log( "Action : "..MathUtility_FindEnumName( CombatAction, troop._combatAction ) )
		end	
	else
		self:Log( "[ "..troop.name.." ] is neutralized" )
	end
end

function Combat:DumpResult()
	self:Log( "Result : "..MathUtility_FindEnumName( CombatResult, self:GetResult() ) )	
	for k, troop in ipairs( self.troops ) do
		self:Log( "[ "..troop.name.." ]("..troop.id..")" )
		self:Log( "Deal Dmg  :" .. troop._combatDealDamage )
		self:Log( "Suffer Dmg:" .. troop._combatSufferDamage )
		self:Log( "Atk Times :" .. troop._combatAttackTimes )
		self:Log( "Def Times :" .. troop._combatDefendTimes )
		self:Log( "Kill      :" .. #troop._combatKillList )
	end
end

---------------------------------------

function Combat:RunOneDay()
	self:NextDay()
	repeat		
		self:Run()
	until self:IsEnd()
	--print( "Combat=", self.id, " Phase=", self.phase, " Status=", MathUtility_FindEnumName( CombatResult, self.result ) )
end

function Combat:Run()
	if not self.battlefield then self:Log( "Battlefield invalid" ) return end
	
	if self:IsEnd() then return end
	
	self.stage = CombatStage.UPDATING
		
	combatEventTrigger:Trigger()

	-- update elapsed
	self._elapsedTime = CombatParams.DEFAULT_ELAPSED_TIME
	
	combatEventTrigger:UpdateCombatEventTime( self._elapsedTime )
		
	-- update time( 24h, minute unit )
	local oldHour = math.ceil( self.time / 60 )
	self.time = self.time + self._elapsedTime		
	local minutesOfDay = 24 * 60
	if self.time > minutesOfDay then
		self.phase = CombatPhase.MIDNIGHT
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
		
	-- update phase
	local duskTime = g_season:GetSeasonTable().duskTime * 60
	local dawnTime = g_season:GetSeasonTable().dawnTime * 60
	if self.phase == CombatPhase.PREPARATION then
		if CombatSwitch.ENABLE_PREPARATION_PHASE_RESTORE_FATIGUE == true then
			for k, troop in ipairs( self.troops ) do
				if troop:IsInCombat() and troop:IsCombatUnit() then
					self:Heal( troop )
					self:RestoreMorale( troop, math.ceil( self:GetTroopMaxMorale( troop ) * CombatParams.RESTORE_MORALE_RATE_TO_PREPARATION_FACTOR ), "preparation restore morale" )
					self:ReduceFatigue( troop, math.ceil( troop.fatigue * CombatParams.REDUCE_FATIGUE_TO_PREPARATION_FACTOR ), "preparation reduce fatigue" )
				end
			end
		end
		-- Defender active sally when it's siege attack
		if self.type == CombatType.SIEGE_COMBAT and self.phase == CombatPhase.PREPARATION then
			local atkNumber, atkTroop = self:GetSideStatus( CombatSide.ATTACKER )
			local defNumber, defTroop = self:GetSideStatus( CombatSide.DEFENDER )
			local ratio = atkNumber / ( atkNumber + defNumber )
			local attitude = self:GetAttitude( CombatSide.DEFENDER )
			if ratio < attitude.ENEMY_RATIO_TO_SALLY and self:RandomRange( 1, RandomParams.MAX_PROBABILITY, "Sally Prob" ) < attitude.SALLY_PROB_BASE + 10000 * ( attitude.ENEMY_RATIO_TO_SALLY - ratio ) then
				--self.defenderSally = true
			end
		end
		if self.time >= dawnTime then
			self.phase = CombatPhase.INCOMBAT
		end
	elseif self.phase == CombatPhase.INCOMBAT then
		if self.time >= duskTime then
			self.phase = CombatPhase.NIGHTFALL
		end
	elseif self.phase == CombatPhase.MIDNIGHT then
		if self.time < duskTime and self.time >= dawnTime then
			self:DumpResult()
			self.phase = CombatPhase.PREPARATION
		end
	end
	
	-- generate action list
	local actionList = {}
	for k, troop in ipairs( self.troops ) do
		if troop:IsInCombat()  then
			if troop:IsCombatUnit() then
				MathUtility_Insert( actionList, { troop=troop, priority=troop._startLine * 1000 - troop.movement }, "priority" )
			else
				self:DumpTroop( troop )
			end
		end
	end
	self._actionList = actionList
	
	-- update result
	self.result = self:GetResult()

	self.stage = CombatStage.THINKING
	
	-- select action
	for k, data in ipairs( actionList ) do
		local troop = data.troop
		if troop:IsInCombat() then			
			self:Cooldown( troop )
			troop:NextCombatTurn()	
			troop:UpdateBuff()			
			self:TroopThink( troop )
		end
	end
	
	-- Consider in Side Level	
	local atkNum, atkTroop, atkMorale, atkFatigue, atkStartNum, atkMaxNum = self:GetSideStatus( CombatSide.ATTACKER )
	local atkDeadRatio = ( atkStartNum - atkNum ) / atkMaxNum
	local atkAttitude = self:GetAttitude( CombatSide.ATTACKER )
	self._atkRetreat = atkDeadRatio > atkAttitude.DEAD_RATE_TO_RETREAT	
	
	-- Go round
	self.stage = CombatStage.FIRST_ROUND
		
	-- do first action
	for k, data in ipairs( actionList ) do
		local troop = data.troop
		if troop:IsInCombat() and not troop:IsActed() then			
			self:DumpTroop( troop )
			self:TroopDoAction( troop )
		end
	end
	
	self.stage = CombatStage.SECOND_ROUND
	
	-- do seconds action
	self:Log( "Second round" )	
	for k, data in ipairs( actionList ) do
		local troop = data.troop
		if troop:IsInCombat() and not troop:IsActed() then
			self:DumpTroop( troop )
			self:TroopDoAction( troop )
		end
	end	
	
	self.stage = CombatStage.FINISH_ACTION
	
	-- debug map
	self:DumpMap()
		
	-- debug phase
	self:DumpPhase()
end

function Combat:TroopThink( troop )
	if troop:IsDecided() then return end

	local attitude = self:GetAttitude( troop._combatSide )
	
	local aliveRatio = self:GetAliveRatio( troop )
	
	if troop._combatSide == CombatSide.ATTACKER and self._atkRetreat == true then
		--Retreat 
		troop._combatAction = CombatAction.RETREAT
		return
	end
	
	-- Surrender
	if aliveRatio <= attitude.ALIVE_RATE_TO_SURRENDER or troop.morale / troop.maxMorale <= attitude.MORALE_RATE_TO_SURRENDER then
		if self:GetScoreGap( troop ) > CombatParams.SCORE_GAP_TO_SURRENDER then
			print( "!!!!!!!!!!!!!!Surrender" )
			troop._combatAction = CombatAction.SURRENDER
			return
		end
	end
	
	-- Flee			
	if aliveRatio <= attitude.ALIVE_RATE_TO_FLEE or troop.morale / troop.maxMorale < attitude.MORALE_RATE_TO_FLEE then
		if self:GetScoreGap( troop ) > CombatParams.SCORE_GAP_TO_FLEE then
			if troop._combatSide == CombatSide.DEFENDER then
				troop._combatAction = CombatAction.IDLE
			else
				self:Log( "Flee occurred, ["..troop.name.."]("..troop.id..") alive="..aliveRatio..",morale="..troop.morale..",attitude="..attitude.ALIVE_RATE_TO_FLEE..","..attitude.MORALE_RATE_TO_FLEE )
				troop._combatAction = CombatAction.FLEE
			end
			return
		end
	end
	
	-- Reform
	local aliveRatio = troop.number / troop.maxNumber
	if aliveRatio <= attitude.ALIVE_RATE_TO_REFORM or troop.morale / troop.maxMorale < attitude.MORALE_RATE_TO_REFORM then
		if not self:GetCloseTarget( troop ) or self.type == CombatType.SIEGE_COMBAT or self.phase >= CombatPhase.NIGHTFALL then			
			troop._combatAction = CombatAction.REFORM
			return
		end
	end

	-- Rest
	if troop.fatigue >= attitude.FATIGUE_TO_REST then		
		self:Log( "["..troop.name.."]("..troop.id..") tired" )
		if self:GetCloseTarget( troop ) then
			troop._combatAction = CombatAction.DEFEND
		else
			troop._combatAction = CombatAction.REST
		end		
		return
	end	
	
	if troop._combatPurpose == CombatTroopPurpose.NONE then
		-- Phase process
		if self.phase == CombatPhase.PREPARATION then
			troop._combatAction = CombatAction.PREPARE
			return
		elseif self.phase == CombatPhase.NIGHTFALL or self.phase == CombatPhase.MIDNIGHT then
			local x, y = troop._startPosX, troop._startPosY
			if math.abs( troop._combatPosX - x ) > troop.table.radius then
				troop._combatAction = CombatAction.BACKWARD
			else
				troop._combatAction = CombatAction.REFORM
			end
			return
		elseif self.phase == CombatPhase.DAWN then
			troop._combatAction = CombatAction.PREPARE
			return
		elseif self.phase == CombatPhase.INCOMBAT then
			--continue
		end
	end
	
	-- Siege special
	if self.type == CombatType.SIEGE_COMBAT then
		--siege situation
		-- 1.gate is broken or wall is broken
		--   all troops can forward and attack
		-- 2.gate isn't broken or wall isn't broken
		--   footman, archer, siege weapon can forward and attack		
		if self.status[CombatStatus.GATE_BROKEN] ~= true or self.status[CombatStatus.WALL_BROKEN] ~= true then			
			if troop._combatSide == CombatSide.ATTACKER then
				if not troop:HasSiegeWeapon() and not troop:HasMissileWeapon() and not self:GetTraitValue( troop, TraitEffectType.SIEGE_ATTACK ) then
					--print( "no siege weapon", troop.name )
					troop._combatAction = CombatAction.DEFEND
					return
				elseif attitude.SIEGE_ATTACK_AFTER_BROKE_WALL == true and self.status[CombatStatus.WALL_BROKEN] ~= true and not troop:HasMissileWeapon() and troop._combatPurpose == CombatTroopPurpose.NONE then
					--print( "cann't siege attack", troop.name )
					troop._combatAction = CombatAction.DEFEND
					return
				end
			end
		end		
	end
	
	-- Tactic process
	--print( "tactic", troop.tactic, troop.name )
	if troop.tactic == CombatTactic.ATTACK then
		if troop:IsSiegeUnit() then
			if troop._combatSide == CombatSide.ATTACKER then
				if self:GetSiegeTarget( troop ) then
					troop._combatAction = CombatAction.FORWARD
				else
					troop._combatAction = CombatAction.DEFEND
				end
			else
				troop._combatAction = CombatAction.DEFEND
			end
		else
			if self:GetCloseTarget( troop ) then
				troop._combatAction = CombatAction.ATTACK
			elseif troop:IsSupport() and not self:GetFrontFriendly( troop ) then
				print( "is support" )
				troop._combatAction = CombatAction.DEFEND
			elseif self:GetFrontTarget( troop ) then
				troop._combatAction = CombatAction.FORWARD
			elseif self:GetAdjacentTarget( troop ) then
				troop._combatAction = CombatAction.TOWARD
			else
				--no enemy in the same or adjacent line
				print( "no enemy" )
				troop._combatAction = CombatAction.DEFEND
			end
		end
	elseif troop.tactic == CombatTactic.HOLD_ATTACK then
		if troop:IsSiegeUnit() then		
			if troop._combatSide == CombatSide.ATTACKER then
				if self.startTime + CombatParams.HOLD_TIME < self.time and self:GetSiegeTarget( troop ) then
					troop._combatAction = CombatAction.FORWARD
				else
					troop._combatAction = CombatAction.DEFEND
				end
			else
				troop._combatAction = CombatAction.DEFEND
			end
		else
			if self:GetCloseTarget( troop ) then
				troop._combatAction = CombatAction.ATTACK
			elseif self.startTime + CombatParams.HOLD_TIME < self.time then
				troop._combatAction = CombatAction.HOLD
			elseif troop:IsSupport() and not self:GetFrontFriendly( troop ) then
				troop._combatAction = CombatAction.DEFEND
			elseif self:GetFrontTarget( troop ) then
				troop._combatAction = CombatAction.FORWARD
			elseif self:GetAdjacentTarget( troop ) then
				troop._combatAction = CombatAction.TOWARD
			else
				troop._combatAction = CombatAction.DEFEND
			end
		end
	elseif troop.tactic == CombatTactic.FIRE then
		if troop:IsSiegeUnit() then
			troop._combatAction = CombatAction.DEFEND
		else
			if self:GetCloseTarget( troop ) then
				troop._combatAction = CombatAction.ATTACK
			elseif self:GetRangeTarget( troop ) then
				troop._combatAction = CombatAction.FIRE
			elseif self.type == CombatType.FIELD_COMBAT then			
				troop._combatAction = CombatAction.FORWARD
			end
		end
	elseif troop.tactic == CombatTactic.DEFEND then
		if troop:IsSiegeUnit() then
			troop._combatAction = CombatAction.DEFEND
		else
			if self:GetCloseTarget( troop ) then
				troop._combatAction = CombatAction.ATTACK
			elseif troop:GetRangeWeapon() and self:GetRangeTarget( troop ) then
				troop._combatAction = CombatAction.FIRE
			elseif troop._combatSide == CombatSide.DEFENDER and self.defenderSally == true then
				if troop:IsSupport() and not self:GetFrontFriendly( troop ) then
					troop._combatAction = CombatAction.DEFEND
				elseif self:GetFrontTarget( troop ) then
					troop._combatAction = CombatAction.FORWARD
				elseif self:GetAdjacentTarget( troop ) then
					troop._combatAction = CombatAction.TOWARD
				else
					troop._combatAction = CombatAction.DEFEND
				end
			else
				troop._combatAction = CombatAction.DEFEND
			end
		end
	end
	
	troop:Decide()
end

function Combat:TroopDoAction( troop )
	combatEventTrigger:SetCombatEventEnviroment( CombatEventEnviroment.TROOP_POINTER, troop )
	combatEventTrigger:Trigger()

	if troop._combatAction == CombatAction.REST then
		self:Rest( troop )
	elseif troop._combatAction == CombatAction.FIRE then
		if not self:Fire( troop, troop._combatTarget ) then
			-- siege combat, defender always garrison the city
			if troop._combatSide ~= CombatSide.DEFENDER or self.type == CombatType.FIELD_COMBAT then
				troop._combatAction = CombatAction.FORWARD
				return
			end
		end
	elseif troop._combatAction == CombatAction.ATTACK then
		if troop:HasBuff( CombatBuff.CHARGING ) then
			self:Charge( troop, troop._combatTarget )
		elseif troop:IsSiegeUnit() then
			self:SiegeAttack( troop, troop._combatTarget )
		else
			self:Fight( troop, troop._combatTarget )
		end
	elseif troop._combatAction == CombatAction.FORWARD then
		if self:Forward( troop, troop._combatTarget ) then
			troop._combatAction = CombatAction.ATTACK
			return
		end
	elseif troop._combatAction == CombatAction.DEFEND then
		self:Defend( troop )
	elseif troop._combatAction == CombatAction.PREPARE then	
		self:Prepare( troop )		
	elseif troop._combatAction == CombatAction.BACKWARD then
		self:Backward( troop )
	elseif troop._combatAction == CombatAction.FLEE then
		self:Flee( troop )
	elseif troop._combatAction == CombatAction.RETREAT then
		self:Retreat( troop )
	elseif troop._combatAction == CombatAction.HOLD then
	elseif troop._combatAction == CombatAction.TOWARD then
		if self:Toward( troop, troop._combatTarget ) then
			troop._combatAction = CombatAction.ATTACK
			return
		end
	elseif troop._combatAction == CombatAction.HEAL then
		self:Heal( troop )
	elseif troop._combatAction == CombatAction.REFORM then
		self:Reform( troop )
	elseif troop._combatAction == CombatAction.IDLE then
	elseif troop._combatAction == CombatAction.COOLDOWN then
	elseif troop._combatAction == CombatAction.SURRENDER then
		self:Surrender( troop )
	else
		self:Log( "!!!!!Invalid action=", troop._combatAction )
	end
	troop:Acted()
end

---------------------------------------
-- Logical Procedure
---------------------------------------

---------------------
-- Calculate Damage
--
-- Consider about few factors: ( still modify )
-- 1. Weapon
-- 2. Soldier Number
-- 3. Fatigue
-- 4. Training
--
function Combat:CalcDamage( troop, target, weapon, armor, isMelee, isMissile, isCharge )	
	local armorType  = ArmorType.NONE
	local protection = 0
	if armor then
		armorType  = ArmorType[armor.type]
		protection = armor.protection				
	end
	
	--print( armorType, weapon.damageType, weapon.name )	
	
	local dmgRate = DamageBonusTable[armorType][weapon.damageType]
	if not dmgRate then
		self:Log( "Damage type [" .. weapon.damageType .. "] Armor type [" .. armorType .. "] rate invalid" )
		dmgRate = 100
	end
	dmgRate = dmgRate * 0.01
	
	-- protection from armor	
	local protectionRate = ( 100 / ( 100 + protection ) )
	local defFatigue = MathUtility_Clamp( ValueRange.MAX_FATIGUE - target.fatigue, CombatParams.FATIGUE_PENALTY_TO_DAMAGE_MIN_FACTOR, CombatParams.FATIGUE_PENALTY_TO_DAMAGE_MAX_FACTOR )	
	local defFatigueRate = self:RandomRange( defFatigue, 100, "Random fatigue penalty" ) * 0.01
	protection = math.ceil( protection * defFatigueRate )	
	
	-- training bonus ( melee combat )
	local trainingRate = 1
	if isMelee then
		local traingTag1 = troop:GetAsset( TroopTag.TRAINING )
		local traingTag2 = target:GetAsset( TroopTag.TRAINING )
		local t1 = traingTag1 and traingTag1.value or 0
		local t2 = traingTag1 and traingTag1.value or 0
		local trainingRate = self:RandomRange( 1, math.abs( t1 - t2 ), "Random Damage BonusRate" )	
		if t1 > t2 then
			trainingRate = MathUtility_Clamp( 100 + trainingRate, 10, 250 )
		else
			trainingRate = MathUtility_Clamp( 100 - trainingRate, 10, 250 ) * 0.01
		end
	end
	
	-- number bonus
	local numberRate = 1
	if isMelee then
		--print( troop.number, target.number )
		local atkNumber = math.min( self:GetTroopNumber( troop ), self.battlefield.width )
		local defNumber = math.min( target.number, self.battlefield.width )	
		print( "Number rate", atkNumber, defNumber )
		numberRate = MathUtility_Clamp( ( atkNumber / defNumber ) ^ 0.5, CombatParams.NUMBER_BONUS_TO_DAMAGE_MIN_FACTOR, CombatParams.NUMBER_BONUS_TO_DAMAGE_MAX_FACTOR )
	end
	
	-- Fatigue penalty
	local fatigue = MathUtility_Clamp( ValueRange.MAX_FATIGUE - troop.fatigue, CombatParams.FATIGUE_PENALTY_TO_DAMAGE_MIN_FACTOR, CombatParams.FATIGUE_PENALTY_TO_DAMAGE_MAX_FACTOR )	
	local fatigueRate = self:RandomRange( fatigue, 100, "Random fatigue penalty" ) * 0.01
	
	-- Final damage	
	local dmg = weapon.power * dmgRate * protectionRate * trainingRate * numberRate * fatigueRate
	--local dmg = weapon.power * dmgRate * numberRate * fatigueRate * troop.number / protection
	self:Log( "Dmg="..math.ceil(dmg)..",Power=" .. weapon.power .. " dmgRate=" .. dmgRate .. " ProtectRate=" .. protectionRate .. " trainingRate=" .. trainingRate .. " numberRate=" .. numberRate .. " fatigueRate=" .. fatigueRate )	
	
	-- weather penalty
	if self.weatherTable then
		if isMelee and self.weatherTable.meleePenalty ~= 0 then
			local penaltyAdd = self:GetTraitValue( troop, TraitEffectType.WEATHER_MALADAPTION, 0 )
			local penaltyRdu = self:GetTraitValue( troop, TraitEffectType.WEATHER_ADAPTION, 0 )
			dmg = dmg * ( 100 - self.weatherTable.meleePenalty + penaltyAdd - penaltyRdu ) * 0.01
			self:Log( "Weather Melee Penalty=" .. self.weatherTable.meleePenalty .. " dmg=" .. dmg )
		elseif isMissile and self.weatherTable.missilePenalty ~= 0 then
			local penaltyAdd = self:GetTraitValue( troop, TraitEffectType.WEATHER_MALADAPTION, 0 )
			local penaltyRdu = self:GetTraitValue( troop, TraitEffectType.WEATHER_ADAPTION, 0 )
			dmg = dmg * ( 100 - self.weatherTable.missilePenalty + penaltyAdd - penaltyRdu ) * 0.01
			self:Log( "Weather Missile Penalty=" .. self.weatherTable.missilePenalty .. " dmg=" .. dmg )
		end
	end
		
	return math.floor( dmg )
end

--
-- flags: melee, missile, charge, block, counter, flank
--
function Combat:HitTarget( troop, target, weapon, armor, flags )
	if not weapon then
		--print( "weapon=", weapon, "armor=", armor, "invalid" )
		return false
	end
	
	if not target:IsAlive() then
		self:Log( "Target is neutralized" )
		return false
	end

	local damage = self:CalcDamage( troop, target, weapon, armor, flags.melee, flags.missile )

	-- Parry damage
	if flags.siege ~= true and flags.assult ~= true then
		-- Wall parry damage when it's missile or gate not broken
		if flags.missile == true or self.status[CombatStatus.GATE_BROKEN] ~= true then					
			--print( "check parry", flags.missile, self.status[CombatStatus.GATE_BROKEN], defender )
			if troop._combatSide == CombatSide.ATTACKER and self:IsBehindDefence( target ) and self:GetDefenceTarget( troop ) then
				local defender = troop._combatTarget
				local parryProp = self:GetTraitValue( defender, TraitEffectType.GUARDIAN_FORTIFIED, 0 )
				if parryProp > 0 then
					local parryDmg  = math.floor( parryProp * damage * 0.01 )
					defender:SufferDamage( parryDmg )
					damage = damage - parryDmg
					--self:Log( "["..defender.name.."] parry dmg="..parryDmg.." for ["..troop.name.."]" )
				end
			end
		elseif flags.melee == true and flags.charge == true and flags.block ~= true and flags.counter ~= true then
			-- Friendly parry damage	
			local guardianList = self:FilterTroops( function( friendly )
				return friendly._combatSide == troop._combatSide and self:GetTraitValue( friendly, TraitEffectType.GUARDIAN_FRIENDLY ) and not friendly:IsParried() and self:IsTroopAdjacent( trop, friendly )
			end )
			if #guardianList > 0 then
				local guardian = guardianList[self:RandomRange( 1, #guardianList, "Random Guardian" )]
				local parryProp = self:GetTraitValue( guardian, TraitEffectType.GUARDIAN_FRIENDLY, 0 )
				if parryProp > 0 then
					local parryDmg  = math.floor( parryProp * damage * 0.01 )				
					guardian:SufferDamage( parryDmg )
					damage = damage - parryDmg
					--self:Log( "["..guardian.name.."] parry dmg="..parryDmg.." for ["..troop.name.."]" )
				end
			end			
		end
	end
		
	-- Critical
	--print( "critical check", troop.morale / troop.maxMorale, target.morale / target.maxMorale )
	if ( troop.morale / troop.maxMorale ) - ( target.morale / target.maxMorale ) > CombatParams.CRITICAL_DAMAGE_CONDITION_MORALE_RATE then
		if self:RandomRange( 1, RandomParams.MAX_PROBABILITY, "Critical Probability" ) < CombatParams.CRITICAL_DAMAGE_CONDITION_PROBABILITY then
			flags.critical = true
			self:Log( "Critical Damage" )
		end
	end
	
	-- Situation Bonus
	if flags.critical   == true then damage = damage * CombatParams.CRITICAL_BONUS_TO_DAMAGE_FACTOR end
	if flags.block      == true then damage = damage * CombatParams.BLOCK_BONUS_TO_DAMAGE_FACTOR end
	if flags.counter    == true then damage = damage * CombatParams.COUNTER_BONUS_TO_DAMAGE_FACTOR  end
	if flags.moving	    == true then damage = damage * CombatParams.MOVING_BONUS_TO_DAMAGE_FACTOR end
	if flags.pursue     == true then damage = damage * CombatParams.PURSUE_BONUS_TO_DAMAGE_FACTOR end
	if flags.flank      == true then damage = damage * CombatParams.FLANK_BONUS_TO_DAMAGE_FACTOR end
	if flags.terrainAdv == true then damage = damage * CombatParams.DEFENCE_BONUS_TO_DAMAGE_FACTOR end
	
	--trait effect
	local damageAdd = self:GetTraitValue( troop,  TraitEffectType.DAMAGE_ADDITION, 0 )
	local damageRdu = self:GetTraitValue( target, TraitEffectType.DAMAGE_REDUCTION, 0 )
	local troopAdd  = self:GetTraitValue( troop,  TraitEffectType.TROOP_MASTER, 0 )
	local troopRdu  = self:GetTraitValue( target, TraitEffectType.TROOP_RESIST, 0 )
		
	if damageAdd ~= 0 or damageRdu ~= 0 or troopAdd ~= 0 or troopRdu ~= 0 then
		damage = math.ceil( damage * ( 100 + damageAdd - damageRdu + troopAdd - troopRdu ) * 0.01 )
		--self:Log( "DmgAdd="..damageAdd..",DmgRed="..damageRdu..",troopAdd="..troopAdd..",troopRdu="..troopRdu )
	else
		damage = math.ceil( damage )
	end
	
	local percentage = math.floor( damage * 100 / target.maxNumber )
	--print( "damage percentange", percentage, damage, target.number )
	
	self:Log( troop:GetNameDesc() .. " hit " .. target:GetNameDesc()  )

	if flags.block then
		percentage = percentage * CombatParams.MORALE_EFFECTION_TO_BLOCK_FACTOR
		--self:Log( "[" ..troop.name.. "] block [" .. target.name .. "]" )		
	elseif flags.counter then		
		percentage = percentage * CombatParams.MORALE_EFFECTION_TO_COUNTER_FACTOR
		--self:Log( "[" ..troop.name.. "] counter [" .. target.name .. "]" )		
	elseif flags.charge then
		percentage = percentage * CombatParams.MORALE_EFFECTION_TO_CHARGE_FACTOR
		--self:Log( "[" ..troop.name.. "] charge [" .. target.name .. "]" )		
	elseif flags.moving then
		--self:Log( "[" ..troop.name.. "] attack moving [" .. target.name .. "]" )		
	elseif flags.flee then
		--self:Log( "[" ..troop.name.. "] attack flee [" .. target.name .. "]" )		
	elseif flags.missile then
		percentage = percentage * CombatParams.MORALE_EFFECTION_TO_MISSILE_FACTOR
		--self:Log( "[" ..troop.name.. "] fire [" .. target.name .. "]" )
	elseif flags.flank then
		percentage = percentage * CombatParams.MORALE_EFFECTION_TO_FLANK_FACTOR
		--self:Log( "[" ..troop.name.. "] flank [" .. target.name .. "]" )
	else
		--self:Log( "[" ..troop.name.. "] attack [" .. target.name .. "]" )
	end	
	
	troop:UseWeapon( weapon )
	
	troop:DealDamage( damage )
	
	target:UseArmor( armor )
	
	target:SufferDamage( damage )	
	--Siege weapon or defence or gate won't generate wounded
	if target:IsCombatUnit() and not target:IsSiegeUnit() then
		local wounded = math.floor( damage * self:RandomRange( CombatParams.MIN_WOUNDED_PERCENTAGE, CombatParams.MAX_WOUNDED_PERCENTAGE, "Random Wounded" ) * 0.01 )
		target.wounded = target.wounded + wounded
		g_statistic:DieInCombat
	end
	
	-- Affect fatigue
	fatigue = math.ceil( weapon.weight * CombatParams.FATIGUE_TO_ATTACK_FACTOR )
	--print( "weapon weight=" .. weapon.weight )
	self:IncreaseFatigue( troop, fatigue, "use weapon" )
	
	if armor and flags.melee or flags.charge then
		if not target:IsDefended() then
			fatigue = math.ceil( armor.weight * CombatParams.FATIGUE_TO_DEFEND_FACTOR )
			if defFatigueAdd ~= 0 or defFatigueRdu ~= 0 then
				fatigue = math.ceil( fatigue * ( 100 + defFatigueAdd - defFatigueRdu ) * 0.01 )
			end
			self:IncreaseFatigue( target, fatigue, "use armor" )
		end
	end
	
	-- Affect morale
	self:LostMorale( target, self:RandomRange( math.ceil( percentage * CombatParams.MORALE_REDUCE_TO_HIT_MIN_FACTOR ), percentage * CombatParams.MORALE_REDUCE_TO_HIT_MAX_FACTOR, "Random Morale Reduce" ), "Hit" )
	
	return true
end

function Combat:RestoreFatigue( troop, ratio, description )
	if CombatSwitch.ENABLE_RESTORE_FATIGUE == true then		
		self:ReduceFatigue( troop, ratio and CombatParams.FATIGUE_RECOVER_PER_TIME * self._elapsedTime * ratio or CombatParams.FATIGUE_RECOVER_PER_TIME * self._elapsedTime, description )
	end
end

function Combat:ReduceFatigue( troop, fatigue, description )	
	--[[
	--trait affection
	local fatigueAdd = self:GetTraitValue( troop, TraitEffectType.SKILL_MASTER, 0 )
	local fatigueRdu = self:GetTraitValue( troop, TraitEffectType.SKILL_DULL, 0 )	
	if fatigueRdu ~= 0 or fatigueAdd ~= 0 then
		fatigue = math.ceil( fatigue * ( 100 + fatigueAdd - fatigueRdu ) * 0.01 )
	end
	]]
	if fatigue > 0 and troop:IsCombatUnit() then
		if troop.fatigue > fatigue then
			troop.fatigue = troop.fatigue - fatigue
		else
			troop.fatigue = 0
		end		
		self:Log( "["..troop.name.."]("..troop.id..") fatigue reduce [".. fatigue .."], now="..troop.fatigue..",for ["..description.."]" )
	end
end

function Combat:IncreaseFatigue( troop, fatigue, description )
	if fatigue > 0 and troop:IsCombatUnit() then
		--trait affection
		local fatigueRdu = self:GetTraitValue( troop, TraitEffectType.SKILL_MASTER, 0 )
		local fatigueAdd = self:GetTraitValue( troop, TraitEffectType.SKILL_DULL, 0 )	
		if fatigueRdu ~= 0 or fatigueAdd ~= 0 then
			fatigue = math.ceil( fatigue * ( 100 + fatigueAdd - fatigueRdu ) * 0.01 )
		end

		troop.fatigue = troop.fatigue + fatigue
		if troop.fatigue > ValueRange.MAX_FATIGUE then troop.fatigue = ValueRange.MAX_FATIGUE end
		self:Log( "["..troop.name.."]("..troop.id..") fatigue increase ["..fatigue .."], now="..troop.fatigue..", for ["..description.."]" )
	end
end

function Combat:RestoreMorale( troop, morale, description )
	if CombatSwitch.ENABLE_RESTORE_MORALE == false then
		return
	end
	if morale > 0 and troop:IsCombatUnit() then
		morale = math.ceil( morale )
		troop.morale = math.min( self:GetTroopMaxMorale( troop ), troop.morale + morale )
		self:Log( "["..troop.name.."]("..troop.id..") restore morale "..morale.." to "..troop.morale .. ", for ["..description.."]" )
	end
end

function Combat:EnourageMorale( troop, morale, description )
	if CombatSwitch.ENABLE_RESTORE_MORALE == false then
		return
	end
	if morale > 0 and troop:IsCombatUnit() then
		morale = math.ceil( morale )
		troop.morale = troop.morale + morale
		self:Log( "["..troop.name.."]("..troop.id..") encourage morale "..morale.." to "..troop.morale .. ", for ["..description.."]" )
	end
end

function Combat:LostMorale( troop, morale, description )
	--trait affection
	if morale > 0 and troop:IsCombatUnit() then
		local moraleRdu = self:GetTraitValue( troop, TraitEffectType.MORALE_ADDITION, 0 )
		local moraleAdd = self:GetTraitValue( troop, TraitEffectType.MORALE_REDUCTION, 0 )
		if moraleAdd ~= 0 or moraleRdu ~= 0 then
			morale = math.ceil( morale * ( 100 + moraleAdd - moraleRdu ) * 0.01 )
		else
			morale = math.ceil( morale )
		end
		if morale > troop.morale then
			troop.morale = 0
		else
			troop.morale = troop.morale - morale
		end
		self:Log( "["..troop.name.."]("..troop.id..") lost morale "..morale.." to "..troop.morale.." for "..description )
	end
end

function Combat:CheckWeaponRange( troop, target, weapon )
	if not troop or not target or not weapon then return end
	local distance = self:CalcDistanceInRow( troop, target )
	--self:Log( "Check From ["..troop.name.."]("..troop.id..") to [" .. target.name .. "], distance [".. distance .."] is in the range [".. weapon.range .."]" )
	if distance > weapon.range + troop.table.radius + target.table.radius then
		--self:Log( "From ["..troop.name.."]("..troop.id..") to [" .. target.name .. "], distance [".. distance .."] is out of weapon's range [".. weapon.range .."]" )
		return false
	end
	if not self:IsTroopAdjacent( troop, target ) then
		self:Log( "["..troop.name.."]("..troop.id..") is not adjacent to [" .. target.name .. "]" )
		return false
	end
	return true
end

function Combat:AffectSideMorale( troop, description )
	local totalNumber, count = self:GetSideStatus( troop._combatSide, true )
	local percentage
	if not troop:IsInCombat() then
		-- killed / fled / surrendered
		percentage = 100 / ( count + 1 )
		--print( "Affect morale", math.ceil( percentage ) )
	else
		percentage = ( troop.number + troop.wounded ) * 100 / totalNumber	
		--print( "Affect morale by number", math.ceil( percentage ) )
	end
	self:ForEachTroop( function ( target )
		if target:IsFriend( troop ) then
			self:LostMorale( target, target.lgevel >= troop.level and percentage * CombatParams.MORALE_EFFECTION_REDUCTION_BY_LEVEL or percentage, description )
		end
	end )
end

function Combat:EncourageSideMorale( troop, factor, description )
	self:ForEachTroop( function ( target )
		if troop:IsFriend( target ) then
			self:RestoreMorale( target, math.ceil( self:GetTroopMaxMorale( troop ) * factor ), description )
		end
	end )
end

function Combat:AddSideBuff( side, buffId, time )
	self:ForEachSideTroop( side, function ( target )		
		target:AddBuff( CombatBuff.BLUFF, time or CombatParams.PERMANENT_BUFF_TIME )
	end )
end

---------------------------------------
-- Action Method
---------------------------------------

function Combat:Prepare( troop, target )	
end

function Combat:Heal( troop )
	--heal wounded
	local heal = math.floor( troop.wounded * CombatParams.HEAL_WOUNDED_PERCENTAGE * 0.01 )
	local minNumber = math.floor( troop.number * CombatParams.HEAL_NUMBER_PERCENTAGE * 0.01 )
	if heal < minNumber then
		heal = minNumber
	end
	if heal > troop.wounded then
		heal = troop.wounded
	end
	if heal > 0 then 
		troop.number = troop.number + heal
		troop.wounded = troop.wounded - heal	
		self:Log( "["..troop.name.."]("..troop.id..") heal "..heal..", now is "..troop.number..",wounded="..troop.wounded )
	end	

	--fatigue
	self:RestoreFatigue( troop, nil, "heal" )
end

function Combat:Rest( troop )
	self:RestoreFatigue( troop, nil, "rest" )
end

function Combat:Cooldown( troop )
	if troop._combatCD > self._elapsedTime then
		--print( "Cooldown", troop.name, troop._combatCD, self._elapsedTime )
		troop._combatCD = troop._combatCD - self._elapsedTime
	else
		troop._combatCD = 0
	end
end

-- move to position directly, no collision
function Combat:MoveTo( troop, move, xPos, fatigueFactor )
	if math.abs( troop._combatPosX, xPos ) < move then
		troop:MoveTo( xPos, troop._combatPosY )
	elseif troop._combatPosX < xPos then
		troop:MoveTo( troop._combatPosX + move, troop._combatPosY )
	elseif troop._combatPosX > xPos then
		troop:MoveTo( troop._combatPosX - move, troop._combatPosY )
	end
	
	--fatigue to move
	if CombatSwitch.ENABLE_MOVEMENT_FATIGUE == true then
		if not fatigueFactor then fatigueFactor = CombatParams.FATIGUE_TO_MOVE_FACTOR end
		if troop.table.category ~= TroopCategory.CAVALRY then factor = CombatParams.FATIGUE_TO_RIDE_FACTOR end
		self:IncreaseFatigue( troop, math.ceil( troop:GetArmorWeight() * factor * fatigueFactor ), "move" )
	end
end

--check collision
function Combat:ApproachPos( troop, move, xPos )
	--print( "pos", troop._combatPosX, move, xPos )
	local collision = false
	if troop._combatSide == CombatSide.ATTACKER then
		local moveDelta = move * CombatPosition.ATTACKER_MOVE
		if math.abs( troop._combatPosX - xPos ) < math.abs( move ) + troop.table.radius then
			collision = true
			troop:MoveTo( xPos - troop.table.radius * CombatPosition.ATTACKER_MOVE )
			--print( "1", xPos, troop.table.radius )
		else
			troop:MoveTo( troop._combatPosX + moveDelta )
		end
	elseif troop._combatSide == CombatSide.DEFENDER then
		local moveDelta = move * CombatPosition.DEFENDER_MOVE
		if math.abs( troop._combatPosX - xPos ) < math.abs( move ) + troop.table.radius  then
			collision = true
			troop:MoveTo( xPos - troop.table.radius * CombatPosition.DEFENDER_MOVE )
			--print( "2", xPos, troop.table.radius )
		else
			troop:MoveTo( troop._combatPosX + moveDelta )
		end
	end
	
	--fatigue to move
	if CombatSwitch.ENABLE_MOVEMENT_FATIGUE == true then
		local factor = CombatParams.FATIGUE_TO_MOVE_FACTOR
		if troop.table.category ~= TroopCategory.CAVALRY then factor = CombatParams.FATIGUE_TO_RIDE_FACTOR end
		self:IncreaseFatigue( troop, math.ceil( troop:GetArmorWeight() * factor ), "move" )
	end
	
	return collision
end

function Combat:ApproachInTime( troop, move, moveTime )
	local xPos = 0
	if troop._combatSide == CombatSide.ATTACKER then
		--always move to right( now )
		xPos = troop._combatPosX + math.floor( move * moveTime * CombatPosition.ATTACKER_MOVE )		
	elseif troop._combatSide == CombatSide.DEFENDER then
		--always move to left( now )
		xPos = troop._combatPosX + math.floor( move * moveTime * CombatPosition.DEFENDER_MOVE )
	end
	--print( "approach time", troop._combatPosX, move, xPos )
	return self:ApproachPos( troop, move, xPos )
end

function Combat:ApproachTarget( troop, move, target )
	local xPos = target._combatPosX
	if troop._combatSide == CombatSide.ATTACKER then		
		if target._combatPosX > troop._combatPosX then
			--target is in the right side of the troop
			xPos = target._combatPosX - target.table.radius
		else
			--target is in the left side of the troop
			xPos = target._combatPosX + target.table.radius
		end
	elseif troop._combatSide == CombatSide.DEFENDER then
		if target._combatPosX < troop._combatPosX then
			--target is in the left side of the troop
			xPos = target._combatPosX + target.table.radius
		else
			--target is in the right side of the troop
			xPos = target._combatPosX + target.table.radius
		end
	end
	--print( "approach", troop._combatPosX, move, xPos )
	return self:ApproachPos( troop, move, xPos )
end

function Combat:SwapWithTarget( leftTroop, rightTroop )
	local left = leftTroop._combatPosX - leftTroop.table.radius
	local right = rightTroop._combatPosX + rightTroop.table.radius
	rightTroop._combatPosX = left + rightTroop.table.radius
	leftTroop._combatPosX = right - leftTroop.table.radius
	--print( "swap", leftTroop._combatPosX, rightTroop._combatPosX )
end

function Combat:Forward( troop, target )
	local ret = false
	
	if not target then
		self:Log( "Forward target isn't exist" )
		return ret
	end
		
	local move = self:GetMovement( troop )
	if move <= 0 then
		self:Log( "["..troop.name.."]("..troop.id..") cann't move" )
		return true
	end
	
	--Is there a wall?
	if self:GetFrontBarrier( troop ) then
		local barrier = troop._combatTarget
		if barrier ~= target then
			troop:ChooseTarget( target, "restore target" )
			if not self:IsTroopMoving( barrier ) or barrier:IsActed() then
				if barrier:IsCombatUnit() and barrier:IsFriend( troop ) and move >= self:CalcDistanceInRow( troop, barrier ) then
					--swap position					
					self:SwapWithTarget( troop, barrier )
					--print( "swap block", barrier.name, barrier._combatPosX, barrier._combatPosX, barrier._combatPosY )
					return true
				else
					--print( "Wall block", barrier.name, barrier._combatPosX, barrier._combatPosX, move, self:CalcDistanceInRow( troop, barrier ) )
					return self:ApproachTarget( troop, move, barrier )
				end
			end
			print( "reach wall", barrier.name, barrier._combatPosX, barrier._combatPosX )
			if barrier._combatSide == troop._combatSide then
				return self:ApproachTarget( troop, move, barrier )
			else
				local distance = self:CalcDistanceInRow( troop, target )
				local move2 = self:GetMovement( target )
				local moveTime = distance / ( move + move2 )
				if moveTime * 60 <= self._elapsedTime then
					return self:ApproachInTime( troop, move, moveTime )
				end
				return self:ApproachTarget( troop, move, barrier )
			end
		end
	end
	
	--restore
	troop:ChooseTarget( target, "restore target" )

	--Add charging buff
	if troop:GetChargeWeapon() then
		troop:AddBuff( CombatBuff.CHARGING, CombatParams.PERMANENT_BUFF_TIME )
	end
	
	--When opp is moving
	if target:IsMoved() or not self:IsTroopMoving( target ) then
		--print( "isMoved" )
		ret = self:ApproachTarget( troop, move, target )
	else
		--print( "notMoved" )
		local distance = self:CalcDistanceInRow( troop, target )
		local move2 = self:GetMovement( target )
		local moveTime = distance / ( move + move2 )
		if moveTime * 60 <= self._elapsedTime then
			--troop is close to target
			print( "close", moveTime, target.name, target._combatPosX )
			ret = self:ApproachInTime( troop, move, moveTime )
		else
			print( "faraway", troop._combatPosX + move )
			if troop._combatSide == CombatSide.ATTACKER then
				self:MoveTo( troop, move, troop._combatPosX + move )
			elseif troop._combatSide == CombatSide.DEFENDER then
				self:MoveTo( troop, move, troop._combatPosX - move )
			end
		end
	end	
	self:Log( "["..troop.name.."]("..troop.id..") is forward to ["..target.name.."]. Pos=" .. troop._combatPosX ..","..troop._combatPosY.."/"..move )
	--if ret then self:Log( "["..troop.name.."]("..troop.id..") will attack enemy next action" ) end
	return ret
end

function Combat:Toward( troop, target )
	local ret = false
	
	if not target then
		self:Log( "Toward target isn't exist" )
		return ret
	end

	local move = self:GetMovement( troop )
	if move <= 0 then
		self:Log( "["..troop.name.."]("..troop.id..") cann't move" )
		return true
	end

	--Is there a barrier?
	local barrier = nil
	local isFrontTarget = self:IsInFront( troop, target )
	if isFrontTarget then
		if self:GetFrontBarrier( troop ) then barrier = troop._combatTarget end
	else
		if self:GetBehindBarrier( troop ) then barrier = troop._combatTarget end
	end
	
	if barrier and barrier ~= target then
		--print( "Front Wall block", troop._combatPosX, troop._combatTarget._combatPosX )
		--return self:ApproachTarget( troop, move, troop._combatTarget )
		local barrier = troop._combatTarget
		troop:ChooseTarget( target, "restore target" )
		if not self:IsTroopMoving( barrier ) or barrier:IsActed() then
			--print( "Wall block", barrier.name, barrier._combatPosX, barrier._combatPosX )
			return self:ApproachTarget( troop, move, barrier )
		end
		--print( "reach wall", barrier.name, barrier._combatPosX, barrier._combatPosX )
		if barrier._combatSide == troop._combatSide then
			return self:ApproachTarget( troop, move, barrier )
		else
			local distance = self:CalcDistanceInRow( troop, target )
			local move2 = self:GetMovement( target )
			local moveTime = distance / ( move + move2 )
			if moveTime * 60 <= self._elapsedTime then
				return self:ApproachInTime( troop, move, moveTime )
			end
			return self:ApproachTarget( troop, move, barrier )
		end
	end
	
	--restore
	troop:ChooseTarget( target, "restore target" )
	
	--Add charging buff
	if troop:GetChargeWeapon() then
		troop:AddBuff( CombatBuff.CHARGING, CombatParams.PERMANENT_BUFF_TIME )
	end
	
	--When opp is moving
	if target:IsMoved() or not self:IsTroopMoving( target ) then
		--print( "isMoved" )
		ret = self:ApproachTarget( troop, move, target )
	else
		--print( "notMoved" )
		local distance = self:CalcDistanceInRow( troop, target )
		local move2 = self:GetMovement( target )
		local moveTime = distance / ( move + move2 )		
		--print( "close", moveTime, move, move2 )
		if moveTime * 60 <= self._elapsedTime then
			--troop is close to target			
			if isFrontTarget then
				--print( "front" )
				ret = self:ApproachInTime( troop, move, moveTime )
			else
				print( "behind target", moveTime )
				ret = self:ApproachInTime( troop, -move, moveTime )
			end
		else
			--print( "faraway", troop._combatPosX + move )
			if troop._combatSide == CombatSide.ATTACKER then
				self:MoveTo( troop, move, troop._combatPosX + move )
			elseif troop._combatSide == CombatSide.DEFENDER then
				self:MoveTo( troop, move, troop._combatPosX - move )
			end
		end
	end		
	
	self:Log( "["..troop.name.."]("..troop.id..") is toward ["..target.name.."]. Pos=" .. troop._combatPosX ..","..troop._combatPosY.."/"..move )
	--if ret then self:Log( "["..troop.name.."]("..troop.id..") will attack enemy next action" ) end
	return ret
end

function Combat:MoveBack( troop, moveBonus )
	if troop._combatSide == CombatSide.ATTACKER then
		if troop._combatPosX <= troop._startPosX then
			troop._combatPosX = troop._startPosX
			return
		end
	elseif troop._combatSide == CombatSide.ATTACKER then
		if troop._combatPosX >= troop._startPosX then
			troop._combatPosX = troop._startPosX
			return
		end
	end
	
	local move = self:GetMovement( troop ) * ( moveBonus or 1 )
	if move <= 0 then
		self:Log( "["..troop.name.."]("..troop.id..") cann't move" )
		return
	end
	self:MoveTo( troop, move, troop._startPosX, CombatParams.FATIGUE_TO_MOVE_BACK_FACTOR )
end

function Combat:Backward( troop )
	self:MoveBack( troop )
	
	self:Log( "["..troop.name.."]("..troop.id..") is backward. Pos=" .. troop._combatPosX ..","..troop._combatPosY )
end

function Combat:Reform( troop )
	self:MoveBack( troop )
	
	--self:Log( "["..troop.name.."]("..troop.id..") is reform. Num="..troop.number..",Pos=" .. troop._combatPosX ..","..troop._combatPosY )
	--simply stop everything
	if 1 then return end
	
	local x, y = troop._startPosX, troop._startPosY
	if math.abs( troop._combatPosX - x ) <= troop.table.radius then
		--self:Heal( troop )
		--self:RestoreFatigue( troop, nil, "reform" )
	end
end

function Combat:Flee( troop )
	self:MoveBack( troop, CombatParams.FLEE_MOVEMENT_BONUS )
	
	self:Log( "["..troop.name.."]("..troop.id..") is flee. Num="..troop.number..",Pos=" .. troop._combatPosX ..","..troop._combatPosY )
	
	local x, y = troop._startPosX, troop._startPosY
	if math.abs( troop._combatPosX - x ) <= troop.table.radius  then
		troop:Flee()
		self:AffectSideMorale( troop, "flee" )
	end
end

function Combat:Retreat( troop )
	self:MoveBack( troop, CombatParams.FLEE_MOVEMENT_BONUS )
	
	self:Log( "["..troop.name.."]("..troop.id..") is retreat. Num="..troop.number..",Pos=" .. troop._combatPosX ..","..troop._combatPosY )
	
	local x, y = troop._startPosX, troop._startPosY
	if math.abs( troop._combatPosX - x ) <= troop.table.radius  then
		troop:Flee()
	end
end

function Combat:Surrender( troop )
	self:Log( "["..troop.name.."]("..troop.id..") is surrender. Num="..troop.number )

	troop:Surrender()
	
	self:AffectSideMorale( troop, "Surrender" )
end

function Combat:Defend( troop )
	if math.abs( troop._combatPosX - troop._startPosX ) > 0 then
		if troop._combatSide == CombatSide.ATTACKER then
			self:MoveTo( troop, self:GetMovement( troop ), troop._startPosX, CombatParams.FATIGUE_TO_MOVE_BACK_FACTOR )
		elseif troop._combatSide == CombatSide.DEFENDER then
			self:MoveTo( troop, self:GetMovement( troop ), troop._startPosX, CombatParams.FATIGUE_TO_MOVE_BACK_FACTOR )
		end
	end
end

-- return means whether action is finished
function Combat:Fire( troop, target )
	--attacker attack
	local atkWeapon = troop:GetRangeWeapon()
	if not atkWeapon then self:Log( "No range weapon for shooting" ) return false end
	
	--out of range
	if not self:CheckWeaponRange( troop, target, atkWeapon ) then
		--Should forward in situation without melee troop
		return false
	end
		
	local defArmor = target:GetDefendArmor( atkWeapon )
	
	--hit
	local moving = target._combatAction == CombatAction.CHARGE
	local pursue = target._combatAction == CombatAction.FLEE
	local siege  = not target:IsCombatUnit()
	local terrainAdv = troop._combatSide == CombatSide.DEFENDER and self.status[CombatStatus.GATE_BROKEN] ~= true
	self:HitTarget( troop, target, atkWeapon, defArmor, { missile = true, moving = moving, pursue = pursue, siege = siege, terrainAdv = terrainAdv } )
	
	return true
end

--
-- return means whether action is finished
function Combat:Charge( troop, target )
	if not target:IsInCombat() then
		--find a new target
		if not self:GetCloseTarget( troop ) then
			self:Log( "Charging target is neutralize" )
			return
		end
	end
	
	--no charge weapon?
	local atkWeapon = troop:GetChargeWeapon()
	if not atkWeapon then self:Log( "No charge weapon in ["..troop.name.."]("..troop.id..") for charging" ) return false end
	
	--out of range
	if not self:CheckWeaponRange( troop, target, atkWeapon ) then return false end
	
	--remove buff
	troop:RemoveBuff( CombatBuff.CHARGING )
	
	--initiate attack
	local isBlock = false
	local defWeapon = target:GetLongWeapon()
	if defWeapon then
		--block charge
		isBlock = true
		local atkArmor = troop:GetDefendArmor( defWeapon )
				
		--hit
		if self:HitTarget( target, troop, defWeapon, atkArmor, { melee = true, block = true } ) then		
			if not troop:IsAlive() then
				target:Kill( troop )
				self:AffectSideMorale( troop, "Block Killed" )
				return true
			end
		end
		if not troop:IsAlive() then
			return true
		end
	end
	
	--flank attack
	local flank = self:IsTroopInFlank( troop, target )

	--hit target
	local defArmor = target:GetDefendArmor( atkWeapon )	
	if self:HitTarget( troop, target, atkWeapon, defArmor, { charge = true, flank = flank } ) then	
		--neutralize?
		if not target:IsAlive() then
			troop:Kill( target )
			self:AffectSideMorale( target, "Killed" )
		end
		if isBlock then return true end
	end
	
	--target is dead, no counter attack
	if not target:IsAlive() then
		return true
	end
	
	--is moving?
	if target._combatAction == CombatAction.CHARGE then
		self:Log( "["..target.name.."] can't counter caused it's moving" )
		return
	end
	
	--target counter attack
	defWeapon = target:GetCloseWeapon()
	if not defWeapon then self:Log( "No counter weapon in ["..target.name.."] for charging" ) return false end
	local atkArmor = troop:GetDefendArmor( defWeapon )
	self:HitTarget( target, troop, defWeapon, atkArmor, { melee = true, counter = true } )
	
	return true
end

--
-- return means whether action is finished
function Combat:Fight( troop, target )
	if not troop or not target then
		--self:Log( "Fight both side invalid" )
		return
	end
	
	-- Cool down
	if not troop:CanAct() then
		self:Log( troop:GetNameDesc() .. " Need cooldown" )
		return
	end
	
	local atkWeapon = troop:GetCloseWeapon()
	local defWeapon = target:GetCloseWeapon()
	--print( troop.name, target.name, atkWeapon, defWeapon )
	
	--if not atkWeapon or not defWeapon then self:Log( "No melee weapon for fight" ) return false end
	
	--out of range
	if not self:CheckWeaponRange( troop, target, atkWeapon ) and not self:CheckWeaponRange( target, troop, defWeapon ) then return false end
	
	local defArmor = target:GetDefendArmor( atkWeapon )	
	local atkArmor = troop:GetDefendArmor( defWeapon )
	
	--self:Log( "[" ..troop.name.. "] fight [" .. target.name .. "]" )
	
	local flank  = self:IsTroopInFlank( troop, target )
	local assult = troop:HasBuff( CombatBuff.STEALTH )
	
	if not target:IsAlive() then
		return true
	end
	
	--attacker hit defender	
	if self:HitTarget( troop, target, atkWeapon, defArmor, { melee = true, flank = flank, assult = assult } ) then
		--to kill?
		if not target:IsAlive() then
			troop:Kill( target )
			self:AffectSideMorale( target, "Killed" )
		end
	end
	
	--defender hit attacker
	local terrainAdv = target._combatSide == CombatSide.DEFENDER and self.status[CombatStatus.GATE_BROKEN] ~= true
	if self:HitTarget( target, troop, defWeapon, atkArmor, { melee = true, counter = true, terrainAdv = terrainAdv } ) then
		if not troop:IsAlive() then
			target:Kill( troop )
			self:AffectSideMorale( troop, "Killed" )
		end
	end
	
	return true
end

function Combat:SiegeAttack( troop, target )
	if target:IsCombatUnit() then
		self:Log( "Siege target is combat unit" )
		return false
	end
	
	if not troop:CanAct() then
		self:Log( troop:GetNameDesc() .. " Need cooldown" )
		return
	end

	local atkWeapon = troop:GetSiegeWeapon()
	
	if not atkWeapon then
		self:Log( "No siege weapon" )
		return false
	end
	
	--out of range
	if not self:CheckWeaponRange( troop, target, atkWeapon ) then return false end
	
	local defArmor = target:GetDefendArmor( atkWeapon )
	
	--self:Log( "[" ..troop.name.. "] siege attack [" .. target.name .. "]" )
	
	--attacker hit defender	
	if self:HitTarget( troop, target, atkWeapon, defArmor, { siege = true } ) then	
		--to kill?
		if not target:IsAlive() then
			troop:Kill( target )

			if target:IsDefence() then
				self:AffectSideMorale( target, "Our wall broken" )
				self:EncourageSideMorale( troop, CombatParams.BREAK_WALL_MAXMORALE_BONUS_FACTOR, "Broke enemy wall" )
				
				if #self:GetDefenceList( troop ) == 0 then
					self.status[CombatStatus.WALL_BROKEN] = true
					self:Log( "Break wall" )
				end
			elseif target:IsGate() then
				self:AffectSideMorale( target, "Our gate broken" )
				self:EncourageSideMorale( troop, CombatParams.BREAK_GATE_MAXMORALE_BONUS_FACTOR, "Broke enemy gate" )
				
				if #self:GetGateList( troop ) == 0 then
					self.status[CombatStatus.GATE_BROKEN] = true
					self:Log( "Break gate" )
				end
			end
		end
	end
	return true
end

-------------------------------------------
-- Event method

function Combat:NightAttack( troop )	
	self:ForEachSideTroop( troop._combatSide, function ( target )
		target:AddBuff( CombatBuff.STEALTH, CombatParams.PERMANENT_BUFF_TIME )
		target._combatPurpose = CombatTroopPurpose.ASSULT
	end	)
end