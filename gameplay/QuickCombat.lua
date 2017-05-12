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
-- Siege Combat
--[[
	DEFENCE = DEFENCE / GATE /TOWER,
	BACK    = CAVALRY,
	FRONT   = ARTILLERY / FOOTSOLDIER,
	CHARGE  = ,
	MELEE   = ,
--]]
--[[
	
	

]]

CombatStatus = 
{
	GATE_BROKEN   = 1,	
	WALL_BROKEN   = 2,	
	TOWER_BROKEN  = 3,	
	SIDE_RETREAT  = 4,
	SIDE_FLEE     = 5,
}

CombatAttitude = 
{
	--Probing Combat
	[0] =
	{
		--Start Combat Condition
		FIGHT_MORALE                   = 80,

		--Surrender( Both Field-Combat, Siege-Combat )
		--SURRENDER_MORALE               = 30,
		--SURRENDER_CASUALTY_RATE        = 70,

		--Flee( Both Field-Combat, Siege-Combat )
		FLEE_MORALE                    = 45,
		FLEE_CASUALTY_RATE             = 30,

		--Retreat( Field-Combat )
		RETREAT_MORALE                 = 60,
		RETREAT_CASUALTY_RATE          = 15,
	},	
	
	--Conventional Combat
	[1] =
	{
		FIGHT_MORALE                   = 70,

		--SURRENDER_MORALE               = 30,
		--SURRENDER_CASUALTY_RATE        = 80,

		FLEE_MORALE                    = 35,
		FLEE_CASUALTY_RATE             = 45,

		RETREAT_MORALE                 = 50,
		RETREAT_CASUALTY_RATE          = 30,
	},
	
	--Desperate Combat
	[2] =
	{
		FIGHT_MORALE                   = 60,

		--SURRENDER_MORALE               = 20,
		--SURRENDER_CASUALTY_RATE        = 90,

		FLEE_MORALE                    = 25,
		FLEE_CASUALTY_RATE             = 65,

		RETREAT_MORALE                 = 40,
		RETREAT_CASUALTY_RATE          = 55,	
	},
}

CombatParams = 
{
	DEFAULT_ELAPSED_TIME     = 60,

	DEFAULT_ATTACK_TIME      = 600,

	CRITICAL_MODULUS         = 1.5,

	-----------------------
	--
	-----------------------
	DEFAULT_LINE_DEPTH                   = 5,
	
	-----------------------
	-- Damage Calculation
	-----------------------
	NUMBER_BONUS_TO_DAMAGE_MIN_FACTOR    = 0.1,
	NUMBER_BONUS_TO_DAMAGE_MAX_FACTOR    = 2.5,
	LEVEL_BONUS_TO_DAMAGE_MIN_FACTOR     = 10,
	LEVEL_BONUS_TO_DAMAGE_MAX_FACTOR     = 250,

	-----------------------
	-- Score Calculation
	-----------------------
	SCORE_GAP_WITH_BRILLIANTLY_VICTORY   = 250,
	SCORE_GAP_WITH_STRATEGIC_VICTORY     = 120,
	SCORE_GAP_WITH_TACTICAL_VICTORY      = 60,
	SIEGE_COMBAT_SCORE_MODULUS           = 2,
	SIEGE_CAPITAL_COMBAT_SCORE_MODULUS   = 4,

	--New Method
	--Use percentage
	BRILLIANTLY_SCORE                    = 75,
	STRATEGIC_SCORE                      = 45,
	TACTICAL_SCORE                       = 20,
	
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
	PREPARE_ROUND         = 0,
	SHOOT_ROUND           = 1,
	CHARGE_ROUND          = 2,
	FORWARD_ROUND         = 3,
	FIGHT_ROUND           = 4,
	PURSUE_ROUND          = 5,
	SIEGE_ROUND           = 6,
	END_ROUND             = 7,	
}

CombatFlow =
{
	--Prepare
	{
		action = function ( combat )
			combat:RunRound( CombatRound.PREPARE_ROUND )
		end,
	},
	--Siege-combat first round
	{
		action = function ( combat )
			combat:RunRound( CombatRound.SIEGE_ROUND )
			combat:RunRound( CombatRound.SHOOT_ROUND )
		end,
		condition = function ( combat )
			return combat.type == CombatType.SIEGE_COMBAT
		end
	},	
	--End combat when attacker is probing in siege-combat
	{	
		action = function ( combat )
			combat:RunRound( CombatRound.END_ROUND )
		end,
		condition = function ( combat )
			local purpose = combat:GetPurpose( CombatSide.ATTACKER )
			return purpose == CombatPurpose.PROBING and combat.type == CombatType.SIEGE_COMBAT
		end
	},
	--Charge in siege-combat
	{
		action = function ( combat )
			combat:RunRound( CombatRound.CHARGE_ROUND )
		end,
		condition = function ( combat )
			return combat.type == CombatType.FIELD_COMBAT
		end
	},
	--Normal combat step
	{
		action = function ( combat )
			combat:RunRound( CombatRound.SIEGE_ROUND )
			combat:RunRound( CombatRound.FORWARD_ROUND )
		end,
	},
	{
		action = function ( combat )
			combat:RunRound( CombatRound.SIEGE_ROUND )
			combat:RunRound( CombatRound.FIGHT_ROUND )
		end,
	},
	--Check pursue first time
	{
		action = function ( combat )
			combat:RunRound( CombatRound.PURSUE_ROUND )
		end,
		condition = function ( combat )
			return combat.round == CombatRound.PURSUE_ROUND
		end
	},
	--End combat when any side is probing
	{
		action = function ( combat )
			combat:RunRound( CombatRound.END_ROUND )
		end,
		condition = function ( combat )
			local atkPurpose = combat:GetPurpose( CombatSide.ATTACKER )
			local defPurpose = combat:GetPurpose( CombatSide.DEFENDER )
			return combat.type == CombatType.FIELD_COMBAT and ( atkPurpose == CombatPurpose.PROBING or defPurpose == CombatPurpose.PROBING )
		end,
	},
	--Conventional fight
	{
		action = function ( combat )
			combat:RunRound( CombatRound.SIEGE_ROUND )
			combat:RunRound( CombatRound.FIGHT_ROUND )
		end,
		condition = function ( combat )
			local purpose = combat:GetPurpose( CombatSide.ATTACKER )
			return purpose == CombatPurpose.CONVENTIONAL
		end,
	},
	--Desperate in siege-combat
	{
		action = function ( combat )
			combat:RunRound( CombatRound.FIGHT_ROUND )
		end,
		condition = function ( combat )
			local atkPurpose = combat:GetPurpose( CombatSide.ATTACKER )
			return combat.type == CombatType.SIEGE_COMBAT and atkPurpose == CombatPurpose.DESPERATE
		end,
	},
	--Desperate in field-combat
	{
		action = function ( combat )
			combat:RunRound( CombatRound.FIGHT_ROUND )
		end,
		condition = function ( combat )
			local atkPurpose = combat:GetPurpose( CombatSide.ATTACKER )
			local defPurpose = combat:GetPurpose( CombatSide.DEFENDER )
			return combat.type == CombatType.FIELD_COMBAT and ( atkPurpose == CombatPurpose.DESPERATE or defPurpose == CombatPurpose.DESPERATE )
		end,
	},
	--Check pursue last time
	{
		action = function ( combat )
			combat:RunRound( CombatRound.PURSUE_ROUND )
		end,
		condition = function ( combat )
			return combat.round == CombatRound.PURSUE_ROUND
		end
	},
}

--------------------------------------------

Combat = class()

function Combat:__init()
	self.time  = 0
	
	self.day    = 0
	self.endDay = 30
	
	self.result = CombatResult.DRAW
	self.flow = 0

	self.atkGroup = nil
	self.defGroup = nil

	self.corps = {}	
	self.troops = {}
	
	self.status = {}
	self.sideOptions = {}
	
	--troops in lines
	self.frontLine   = {}	
	self.backLine    = {}
	self.defenceLine = {}
	self.chargeLine  = {}
	self.meleeLine   = {}
	--troops in sides
	self.attackers   = {}
	self.defenders   = {}
	
	--statistic
	self.totalSoldier = 0
	self.atkNumber = 0
	self.defNumber = 0
	self.atkKill = 0
	self.defKill = 0
	self.atkHit = 0
	self.defHit = 0	
	self.updateTime  = 0
	self.shootRound  = 0
	self.fowardRound = 0
	self.fightRound  = 0
	self.restDay     = 0
	self.elapsedTime = 0
end

local logUtility = LogUtility( "log/combat_" .. g_gameId .. ".log", LogWarningLevel.DEBUG, false )

function Combat:ShowText( ... )	
	if g_gameMode == GameMode.COMBAT_GAME then
		print( ... )
	end
	logUtility:WriteLog( ... )
end

function Combat:Log( ... )
	if g_gameMode == GameMode.COMBAT_GAME then
		print( ... )
	end
	logUtility:WriteLog( ... )
end

function Combat:Brief()
	local atkNum, atkTroop, atkMorale, atkFatigue, atkStartNum, atkMaxNum = self:GetSideStatus( CombatSide.ATTACKER )
	local defNum, defTroop, defMorale, defFatigue, defStartNum, defMaxNum = self:GetSideStatus( CombatSide.DEFENDER )
	local content = "Combat=" .. self.id;
	content = content .. " ["..( self.location and self.location.name or "" ).."] "
	content = content .. "@" .. ( ( self.location and self.location:GetGroup() ) and self.location:GetGroup().name or "" )
	content = content .. ( self.atkGroup and self.atkGroup.name or "Neutral" ) .. "+" .. atkNum .. "/" .. atkMaxNum .. "("..atkTroop..")"
	content = content .. " VS "
	content = content .. ( self.defGroup and self.defGroup.name or "Neutral" ) .. "+" .. defNum .. "/" .. defMaxNum .. "("..defTroop..")" 
	content = content .. " corps=" .. self:GetCorpsNumber( CombatSide.ATTACKER ) .. "/" .. self:GetCorpsNumber( CombatSide.DEFENDER )
	content = content .. " troop=" .. self:GetTroopNumber( CombatSide.ATTACKER ) .. "/" .. self:GetTroopNumber( CombatSide.DEFENDER )
	self:ShowText( content )
end

function Combat:CreateDesc()
	if not self.endDate then self.endDate = g_calendar:GetDateValue() end
	local desc = self.id .. " " .. ( self.atkGroup and self.atkGroup.name or "Neutral" ) .. " v " .. ( self.defGroup and self.defGroup.name or "Neutral" )
	desc = desc .. " @" .. ( self.location and self.location.name or "" )
	desc = desc .. " " .. MathUtility_FindEnumName( CombatType, self.type )
	desc = desc .. " day=" .. self.day
	desc = desc .. " rest=" .. self.restDay .. " up=" .. self.updateTime .. " round=" .. self.shootRound .. "/" .. self.fowardRound .. "/" .. self.fightRound
	desc = desc .. " date=" .. g_calendar:CreateDateDescByValue( self.begDate, true, true ) .."->"..g_calendar:CreateDateDescByValue( self.endDate, true, true )
	desc = desc .. " rslt=" .. MathUtility_FindEnumName( CombatResult, self.result )
	desc = desc .. " soldier=" .. self.atkNumber .. "/" .. self.defNumber
	desc = desc .. " died=" .. self.defKill .. "/" .. self.atkKill
	desc = desc .. " corps_vs=" .. self:GetCorpsNumber( CombatSide.ATTACKER ) .. "/" .. self:GetCorpsNumber( CombatSide.DEFENDER )
	desc = desc .. " troops_vs=" .. self:GetTroopNumber( CombatSide.ATTACKER ) .. "/" .. self:GetTroopNumber( CombatSide.DEFENDER )
	desc = desc .. " reinforce=" .. ( self.reinforce or "" )
	desc = desc .. " Purpose=" .. MathUtility_FindEnumName( CombatPurpose, self:GetPurpose( CombatSide.ATTACKER ) ) .. "/" .. MathUtility_FindEnumName( CombatPurpose, self:GetPurpose( CombatSide.DEFENDER ) )
	return desc
end

function Combat:Dump()
	self:ShowText( "ID      : ".. self.id )
	self:ShowText( "Day     : ".. self.day .. " rest=" .. self.restDay )
	self:ShowText( "Time    : ".. math.ceil( self.time / 60 ) )
	self:ShowText( "Weather : ".. self.weatherTable.name .. "/" .. self.weatherDuration )
	self:ShowText( "Type    : " .. MathUtility_FindEnumName( CombatType, self.type ) )
	self:ShowText( "VS      : ".. ( self.atkGroup and self.atkGroup.name or "Neutral" ) .. " / " .. ( self.defGroup and self.defGroup.name or "Neutral" ) )
	self:ShowText( "Location: ".. ( self.location and self.location.name .. ( self.location:GetGroup() and "@" .. self.location:GetGroup().name or "" ) or "" ) )	
	self:ShowText( "Line    : ".. "Melee=" .. #self.meleeLine .. "," .. "Charge=" .. #self.chargeLine .. "," .. "Front=" .. #self.frontLine .. "," .. "Back=" .. #self.backLine .. "," .. "Defence=" .. #self.defenceLine )
	self:ShowText( "Round   : ".. MathUtility_FindEnumName( CombatRound, self.round ) )
	self:ShowText( "Score   : " .. self.atkScore .. "/" .. self.defScore )
	self:ShowText( "Result  : "..MathUtility_FindEnumName( CombatResult, self.result ) )
	local atkNumber, defNumber = 0, 0
	function dumpTroop( troops )
		for k, troop in ipairs( troops ) do
			local content = "	" .. troop.name .. " 	id=" .. troop.id .. "(".. ( troop.corps and troop.corps.id or "" )..") num=" .. troop.number .. " side=" .. MathUtility_FindEnumName( CombatSide, troop._combatSide ) .. " Line=" .. MathUtility_FindEnumName( TroopStartLine, troop._startLine ) .. " Mor=" .. troop.morale .. "/" .. troop:GetMaxMorale() .. " In="..(troop:IsInCombat() and "true" or "false" )
			content = content .. " " .. ( troop:GetGroup() and troop:GetGroup().name or "" )
			self:ShowText( content )
			if troop:IsCombatUnit() then
				if troop._combatSide == CombatSide.ATTACKER then
					atkNumber = atkNumber + troop.number
				elseif troop._combatSide == CombatSide.DEFENDER then
					defNumber = defNumber + troop.number
				end
			end
		end
	end
	dumpTroop( self.troops )
	--[[
	self:ShowText( "Attacker:" )
	dumpTroop( self.attackers )
	self:ShowText( "Defender:" )
	dumpTroop( self.defenders )	
	]]
	self:ShowText( "Atk/Def     : ".. atkNumber .. "/" .. defNumber )
	self:ShowText( "AtkM/DefM   : ".. self.atkMorale .. "/" .. self.defMorale )
	self:ShowText( "AtkK/DefK   : ".. self.atkKill .. "/" .. self.defKill )
end

function Combat:DumpResult()
	if 1 then return end
	local atkDeal, defDeal, atkHit, defHit, atkKill, defKill = 0, 0, 0, 0, 0, 0	
	for k, troop in ipairs( self.troops ) do
		if troop:IsCombatUnit() then
			content = NameIDToString( troop )
			content = content .. ( troop._combatSide == CombatSide.ATTACKER and "[ATK]" or "[DEF]" )
			content = content .. troop:GetStatusDesc()
			content = content .. " Deal/Suf=" .. troop._combatDealDamage .. "/" .. troop._combatSufferDamage
			content = content .. " AtkT/DefT=" .. troop._combatAttackTimes .. "/" .. troop._combatDefendTimes
			content = content .. " Kill=" .. troop._combatKill
			self:Log( content )
			if troop._combatSide == CombatSide.ATTACKER then
				atkDeal = atkDeal + troop._combatDealDamage
				atkKill = atkKill + troop._combatKill
				atkHit  = atkHit + troop._combatAttackTimes
			elseif troop._combatSide == CombatSide.DEFENDER then
				defDeal = defDeal + troop._combatDealDamage
				defKill = defKill + troop._combatKill
				defHit  = defHit + troop._combatAttackTimes
			end
		end
	end
	self:Log( "Atk Deal: " .. atkKill .. "k " .. atkDeal .. "d " .. atkHit .. "h" )
	self:Log( "Def Deal: " .. defKill .. "k " .. defDeal .. "d " .. defHit .. "h" )
	self:Log( "Result  : "..MathUtility_FindEnumName( CombatResult, self.result ) )
	self:Log( "Elapsed : " .. self.elapsedTime )
end

function Combat:AddTroopToSide( side, troop )
	if not troop then return end
	
	for k, other in ipairs( self.troops ) do
		if other:GetGroup() ~= troop:GetGroup() and troop:GetGroup() and other._combatSide == side then
			local relation = other:GetGroup():GetGroupRelation( troop:GetGroup().id )
			if relation and not relation:IsAllyOrDependence() then
				InputUtility_Pause( self.id, other:GetGroup().name, troop:GetGroup().name, " is diff", MathUtility_FindEnumName( CombatSide, side ) )
				break
			end
		end
	end
--print( "troop="..NameIDToString( troop ) .. " attend combat=" .. self.id )
	Helper_AddDataSafety( self.troops, troop )

	troop:NewCombat()
	
	--init side
	troop._combatSide = side	

--[[
	if ( side == CombatSide.ATTACKER and troop:GetGroup() == self.defGroup ) then		
		InputUtility_Pause( NameIDToString( troop ), troop:GetGroup().name, self.defGroup.name, "DefSide error!!!", troop._combatId )
	elseif ( side == CombatSide.DEFENDER and troop:GetGroup() == self.atkGroup ) then
		InputUtility_Pause( NameIDToString( troop ), troop:GetGroup().name, self.atkGroup.name, "AtkSide error!!!", troop._combatId )
	end
	]]	
	
	troop._combatId = self.id

	--init variables
	troop._armorWeight = 0
	for k, armor in pairs( troop.table.armors ) do
		troop._armorWeight = troop._armorWeight + armor.weight
	end
end

function Combat:ForeachCorps( fn )
	for k, corps in ipairs( self.corps ) do
		fn( corps )
	end
end

function Combat:AddCorpsToSide( side, corps )
	self:ShowText( self.id, "Add Corps=", NameIDToString( corps ) )

	table.insert( self.corps, corps )

	for k, troop in ipairs( corps.troops ) do
		self:AddTroopToSide( side, troop )
	end
end

function Combat:Reinforce()
	if not self.reinforce then
		self.reinforce = 1
	else
		self.reinforce = self.reinforce + 1
	end
end

function Combat:SetEndDay( day )
	self.endDay = day
end

function Combat:SetType( combatType )
	self.type = combatType
end

function Combat:SetGroup( side, group )
	if side == CombatSide.ATTACKER then
		self.atkGroup = group
	elseif side == CombatSide.DEFENDER then
		self.defGroup = group
	end
end

function Combat:SetLocation( location )
	self.location = location
end

function Combat:SetSide( side, data )
	self.sideOptions[side] = data

	self:ShowText( "Set side=" .. MathUtility_FindEnumName( CombatSide, side ) .." purpose=" .. MathUtility_FindEnumName( CombatPurpose, data.purpose ) )
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

function Combat:EndCombat()
	--InputUtility_Pause( "end combat="..self:CreateDesc())
	self.endDate = g_calendar:GetDateValue()
	
	for k, troop in ipairs( self.troops ) do
		troop:EndCombat()
	end
end

function Combat:Init()
	if not self.battlefield then return end
	
	self.begDate = g_calendar:GetDateValue()

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
	
	self.atkNumber   = 0
	self.defNumber   = 0
	self.atkTotal    = 0
	self.defTotal    = 0
	self.atkMorale   = 0
	self.defMorale   = 0
	for k, troop in ipairs( self.troops ) do
		if troop._combatSide == CombatSide.ATTACKER then
			table.insert( self.attackers, troop )
		elseif troop._combatSide == CombatSide.DEFENDER then
			table.insert( self.defenders, troop )
		end
		if self.day <= 1 then troop._startNumber = troop.number end
		--Field Stand Line
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

		elseif self.type == CombatType.SIEGE_COMBAT then
			local purpose = self:GetPurpose( CombatSide.ATTACKER )
			if troop.table.startLine == TroopStartLine.FRONT then				
				troop._startLine = TroopStartLine.FRONT
				table.insert( self.frontLine, troop )
			elseif troop.table.startLine == TroopStartLine.BACK then
				troop._startLine = TroopStartLine.FRONT
				table.insert( self.frontLine, troop )
			elseif troop.table.startLine == TroopStartLine.DEFENCE then
				troop._startLine = TroopStartLine.DEFENCE
				table.insert( self.defenceLine, troop )
			elseif troop.table.startLine == TroopStartLine.CHARGE then
				troop._startLine = TroopStartLine.FRONT
				table.insert( self.frontLine, troop )
			end
			--self:ShowText( "embattle siege", troop.name, MathUtility_FindEnumName( TroopStartLine, troop._startLine ) )
		end

		if self.day > 1 then
			troop:NextCombatDay()
			local rate = 0.05
			if self.type == CombatType.SIEGE_COMBAT and troop._combatSide == CombatSide.ATTACKER then
				rate = rate + 0.05
			end
			troop:RecoverMorale( math.ceil( troop.morale + ( troop:GetMaxMorale() - troop.morale ) * rate ) )
		end

		if troop:IsCombatUnit() then
			self.totalSoldier = self.totalSoldier + troop.number
			if troop._combatSide == CombatSide.ATTACKER then
				self.atkNumber = self.atkNumber + troop.number
				self.atkTotal  = self.atkTotal + troop:GetCombatOrganization()
				self.atkMorale = self.atkMorale + troop.morale * troop.number
			else
				self.defNumber = self.defNumber + troop.number
				self.defTotal  = self.defTotal + troop:GetCombatOrganization()
				self.defMorale = self.defMorale + troop.morale * troop.number
			end
		end
	end
end

function Combat:InitPurpose()
	function SetPurpose( side, powerRatio )
		if self.type == CombatType.FIELD_COMBAT then
			if powerRatio < 50 then
				self:SetSide( side, { purpose = CombatPurpose.PROBING } )
			elseif powerRatio > 75 then
				if Random_SyncGetProb() < 7000 then
					self:SetSide( side, { purpose = CombatPurpose.CONVENTIONAL } )
				else
					self:SetSide( side, { purpose = CombatPurpose.DESPERATE } )
				end			
			else
				self:SetSide( side, { purpose = CombatPurpose.CONVENTIONAL } )
			end
		elseif self.type == CombatType.SIEGE_COMBAT then
			if side == CombatSide.ATTACKER then
				if powerRatio < 50 then
					self:SetSide( side, { purpose = CombatPurpose.PROBING } )
				elseif powerRatio > 80 then
					self:SetSide( side, { purpose = CombatPurpose.DESPERATE } )
				elseif powerRatio < 75 then
					if Random_SyncGetProb() < 7000 then
						self:SetSide( side, { purpose = CombatPurpose.CONVENTIONAL } )
					else
						self:SetSide( side, { purpose = CombatPurpose.PROBING } )
					end
				else
					self:SetSide( side, { purpose = CombatPurpose.CONVENTIONAL } )
				end
			elseif side == CombatSide.DEFENDER then
				if powerRatio > 35 or not self.location:IsConnected() then
					if Random_SyncGetProb() < 7000 then
						self:SetSide( side, { purpose = CombatPurpose.CONVENTIONAL } )
					else
						self:SetSide( side, { purpose = CombatPurpose.DESPERATE } )
					end
				else
					self:SetSide( side, { purpose = CombatPurpose.CONVENTIONAL } )
				end
			end			
		end
	end
	local powerRatio = math.ceil( self.atkNumber * 100 / ( self.atkNumber + self.defNumber ) )
	SetPurpose( CombatSide.ATTACKER, powerRatio )
	SetPurpose( CombatSide.DEFENDER, 100 - powerRatio )
end

-------------------------------

function Combat:GetLocation()
	return self.location
end

function Combat:GetSideGroup( side )
	if side == CombatSide.ATTACKER then
		return self.atkGroup
	elseif side == CombatSide.DEFENDER then
		return self.defGroup
	end
	return nil
end

function Combat:GetCorpsNumber( side )
	local number = 0
	for k, corps in ipairs( self.corps ) do
		if corps:GetGroup() == self.atkGroup and side == CombatSide.ATTACKER then
			number = number + 1
		elseif corps:GetGroup() == self.defGroup and side == CombatSide.DEFENDER then
			number = number + 1
		end
	end
	return number
end

function Combat:GetTroopNumber( side )
	local number = 0
	for k, troop in ipairs( self.troops ) do
		if troop._combatSide == side then
			number = number + 1
		end
	end
	return number
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
	if self.result > CombatResult.COMBAT_END_RESULT or ( self.endDay and self.endDay < self.day ) then
		return true
	end
	local atkPurpose = self:GetPurpose( CombatSide.ATTACKER )	
	if self.result == CombatResult.TACTICAL_LOSE and atkPurpose == CombatPurpose.PROBING then
		return true
	end
	local defPurpose = self:GetPurpose( CombatSide.DEFENDER )
	if self.result == CombatResult.TACTICAL_VICTORY and defPurpose == CombatPurpose.PROBING then
		return true
	end
	return false
end

function Combat:IsDayEnd()
	return self.round >= CombatRound.END_ROUND
end

function Combat:GetSideStatus( side, includeWounded )
	local number, morale, fatigue, startNumber, maxNumber, count = 0, 0, 0, 0, 0, 0
	for k, target in ipairs( self.troops ) do
		if target._combatSide == side and target:IsCombatUnit() then
			if target:IsInCombat() then
				count = count + 1
				number = number + target.number
				if target._startNumber then
					startNumber = startNumber + target._startNumber
				end
				maxNumber = maxNumber + target.maxNumber
				morale = morale + target.morale
				fatigue = fatigue + target.fatigue
				if includeWounded then
					number = number + target.wounded
				end
			end
		end
	end
	return number, count, count > 0 and math.floor( morale / count ) or 0, count > 0 and math.floor( fatigue / count ) or 0, startNumber, maxNumber
end

-------------------------------


function Combat:GetResult()
	if self.result ~= CombatResult.DRAW then return self.result end

	local atkScore = self.atkScore * 100 / self.defTotal
	local defScore = self.defScore * 100 / self.atkTotal
	local gapScore = atkScore + defScore > 0 and math.abs( atkScore - defScore ) * 100 / ( atkScore + defScore ) or 0
	local ret = CombatResult.DRAW
	if gapScore >= CombatParams.BRILLIANTLY_SCORE then		
		ret = atkScore > defScore and CombatResult.BRILLIANT_VICTORY or CombatResult.DISASTROUS_LOSE
	elseif gapScore >= CombatParams.STRATEGIC_SCORE then		
		ret = atkScore > defScore and CombatResult.STRATEGIC_VICTORY or CombatResult.STRATEGIC_LOSE
	elseif gapScore >= CombatParams.TACTICAL_SCORE then
		ret = atkScore > defScore and CombatResult.TACTICAL_VICTORY or CombatResult.TACTICAL_LOSE
	end
	if ret ~= CombatResult.DRAW then
		self:ShowText( "atkscore=", math.ceil( atkScore ), self.atkScore, self.defTotal )
		self:ShowText( "defscore=", math.ceil( defScore ), self.defScore, self.atkTotal )
		self:ShowText( "combat result=", self.id, MathUtility_FindEnumName( CombatResult, ret ), math.ceil( gapScore ) )		
	end
	return ret
end

function Combat:GetWinner()
	if self.result == CombatResult.DRAW then
		return CombatSide.NEUTRAL
	elseif self.result == CombatResult.STRATEGIC_LOSE or self.result == CombatResult.TACTICAL_LOSE or self.result == CombatResult.DISASTROUS_LOSE then
		return CombatSide.DEFENDER
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

-------------------------------

function Combat:NextDay()
	--if self.day >= 1 then InputUtility_Pause( "next day", MathUtility_FindEnumName( CombatResult, self.reuslt ) ) end
	
	--start time
	self.time = ( self.battlefield.time + g_season:GetSeasonTable().dawnTime ) * 60
	self.startTime = self.time
	--day counter
	self.day = self.day + 1	
	self.flow = 1
	self.round = CombatRound.PREPARE_ROUND
	self.result = CombatResult.DRAW	
	self:Embattle()
	self:InitPurpose()

	self.atkMorale = math.ceil( self.atkMorale / self.atkNumber )
	self.defMorale = math.ceil( self.defMorale / self.defNumber )

	local atkAttitude = self:GetAttitude( CombatSide.ATTACKER )
	local defAttitude = self:GetAttitude( CombatSide.DEFENDER )
	if self.atkMorale < atkAttitude.FIGHT_MORALE and self.defMorale < defAttitude.FIGHT_MORALE then
		self.restDay = self.restDay + 1
		--InputUtility_Pause( "rest", self.atkMorale, atkAttitude.FIGHT_MORALE, self.defMorale, defAttitude.FIGHT_MORALE )
		return false
	end

	local defNum = self:GetSideStatus( CombatSide.DEFENDER )
	if defNum <= 0 then
		self.round = CombatRound.END_ROUND
		self.result = CombatResult.BRILLIANT_VICTORY
		InputUtility_Pause( "next day end" )
	end

	return true
end

function Combat:RunOneDay()
	--print( "Combat=", self.id, " Result=", MathUtility_FindEnumName( CombatResult, self.result ) )

	if not self:NextDay() then return end
	
	repeat
		self:Run()
	until self:IsDayEnd() or self:IsCombatEnd()
	
	--self:Dump()
	self:DumpResult()
end

function Combat:RunRound( round )
	if round == CombatRound.PREPARE_ROUND then
	elseif round == CombatRound.SHOOT_ROUND then
		self:Shoot()
	elseif round == CombatRound.CHARGE_ROUND then
		self:Charge()
	elseif round == CombatRound.FORWARD_ROUND then
		self:Forward()
	elseif round == CombatRound.FIGHT_ROUND then
		self:Fight()
	elseif round == CombatRound.PURSUE_ROUND then
		self:Pursue()
	elseif round == CombatRound.SIEGE_ROUND then
		if self.type == CombatType.SIEGE_COMBAT then
			--siege weapon
			self:SiegeWeaponAttack()
			--defence construction
			self:CityDefenceAttack()
		end
	elseif round == CombatRound.END_ROUND then
	end
	self.round = round
	if not self.round then k.p = 1 end
end

function Combat:UpdateFlow()
	if self:IsDayEnd() then return end

	local flowData = CombatFlow[self.flow]
	if not flowData then
		self.round = CombatRound.END_ROUND
		return
	end

	self.flow = self.flow + 1

	if not flowData.condition or flowData.condition( self ) ~= false then
		if flowData.action then
			flowData.action( self )
		end
	else
		self:UpdateFlow()
	end
end

function Combat:Run()
	if not self.battlefield then self:Log( "Battlefield invalid" ) return end
	
	if self:IsDayEnd() or self:IsCombatEnd() then
		return
	end
	
	self.updateTime = self.updateTime + 1

	-- update elapsed
	local passTime = CombatParams.DEFAULT_ELAPSED_TIME	
	self.elapsedTime = self.elapsedTime + passTime
	-- update time( 24h, minute unit )
	local oldHour = math.ceil( self.time / 60 )
	self.time = self.time + passTime
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

	self:NextTurn()

	self:UpdateFlow()
end

function Combat:NextTurn()
	for k, troop in ipairs( self.troops ) do
		if troop:IsInCombat() then
			troop:NextCombatTurn()
		end
	end

	local side, sideCount = nil, 0

	local atkAttitude = self:GetAttitude( CombatSide.ATTACKER )
	local defAttitude = self:GetAttitude( CombatSide.DEFENDER )
	local atkNum, atkTroop, atkMorale, atkFatigue, atkStartNum, atkMaxNum = self:GetSideStatus( CombatSide.ATTACKER )
	local defNum, defTroop, defMorale, defFatigue, defStartNum, defMaxNum = self:GetSideStatus( CombatSide.DEFENDER )	
	local atkCasulaty = math.floor( ( atkStartNum - atkNum ) * 100 / atkStartNum )
	local defCasulaty = math.floor( ( defStartNum - defNum ) * 100 / defStartNum )
	self:ShowText( "casualty=",  atkCasulaty, defCasulaty )

	--All troop fled or terminated
	if not side then
		if atkNum == 0 then
			side = CombatSide.ATTACKER
			sideCount = sideCount + 1
		end
		if defNum == 0 then
			side = CombatSide.DEFENDER
			sideCount = sideCount + 1
		end
		if sideCount == 1 then
			self.result = side == CombatSide.ATTACKER and CombatResult.DISASTROUS_LOSE or CombatResult.BRILLIANT_VICTORY
			self:ShowText( "fled leads retreat", side )
		end
	end

	--High casualty or Low morale leads to flee
	if not side then
		if atkCasulaty > atkAttitude.FLEE_CASUALTY_RATE or self.atkMorale < atkAttitude.FLEE_MORALE then
			side = CombatSide.ATTACKER
			sideCount = sideCount + 1
		end
		if defCasulaty > defAttitude.FLEE_CASUALTY_RATE or self.defMorale < defAttitude.FLEE_MORALE then
			side = CombatSide.DEFENDER
			sideCount = sideCount + 1
		end
		if sideCount == 1 then
			self:AddStatus( CombatStatus.SIDE_FLEE )
			self.result = side == CombatSide.ATTACKER and CombatResult.STRATEGIC_LOSE or CombatResult.STRATEGIC_VICTORY			
			self:ShowText( "Low morale leads flee", atkCasualty, defCasulaty, self.atkMorale, self.defMorale )
		end
	end

--[[
	--High casualty and low morale leads to surrender?
	if not side then
		if atkCasulaty > atkAttitude.SURRENDER_CASUALTY_RATE and self.atkMorale < atkAttitude.SURRENDER_MORALE then
			side = CombatSide.ATTACKER
			sideCount = sideCount + 1
		end
		if defCasulaty > defAttitude.SURRENDER_CASUALTY_RATE and self.defMorale < defAttitude.SURRENDER_MORALE then
			side = CombatSide.DEFENDER
			sideCount = sideCount + 1
		end
		if sideCount == 1 then
			self.result = side == CombatSide.ATTACKER and CombatResult.DISASTROUS_LOSE or CombatResult.BRILLIANT_VICTORY
			InputUtility_Pause( "casualty leads surrender", side )
		elseif sideCount == 2 then
			if self.type == CombatType.FIELD_COMBAT then
				--end combat, both sides are high casualty rate
				self.day = self.endDay
			end
		end
	end
]]	

	if self.type == CombatType.FIELD_COMBAT then
		--Casualty leads retreat
		if not side then
			if atkCasulaty > atkAttitude.RETREAT_CASUALTY_RATE then
				side = CombatSide.ATTACKER
				sideCount = sideCount + 1
			end
			if defCasulaty > defAttitude.RETREAT_CASUALTY_RATE then
				side = CombatSide.DEFENDER
				sideCount = sideCount + 1
			end			
			if sideCount == 1 then
				self.result = side == CombatSide.ATTACKER and CombatResult.STRATEGIC_LOSE or CombatResult.STRATEGIC_VICTORY
				self:ShowText( "casualty leads retreat", side )
			elseif sideCount == 2 then
				if self.type == CombatType.FIELD_COMBAT then
					--end combat, both sides are high casualty rate
					self.day = self.endDay
				end
			end
		end

		--Low morale leads retreat
		if not side then
			if self.atkMorale < atkAttitude.RETREAT_MORALE then
				side = CombatSide.ATTACKER
				sideCount = sideCount + 1
			end
			if self.defMorale < defAttitude.RETREAT_MORALE then
				side = CombatSide.DEFENDER
				sideCount = sideCount + 1
			end
			if sideCount == 1 then
				self:AddStatus( CombatStatus.SIDE_RETREAT )
				self.result = self:GetResult()
				self:ShowText( "Low morale leads retreat", self.atkMorale, self.defMorale )
			end
		end
	end

	if side then
		if sideCount > 1 then
			--InputUtility_Pause( "draw", self.atkMorale, self.defMorale )			
			self.round = CombatRound.END_ROUND
			self.result = CombatResult.DRAW
			return
		end

		for _, troop in ipairs( self.troops ) do
			if troop:IsCombatUnit() and troop._combatSide == side then
				troop:Flee()
			end
		end

		if self.result > CombatResult.COMBAT_END_RESULT then
			if self.type == CombatType.FIELD_COMBAT then
				if self:HasStatus( CombatStatus.SIDE_FLEE ) then
					self:RunRound( CombatRound.PURSUE_ROUND )
				end
			elseif self.type == CombatType.SIEGE_COMBAT then
				--Massacre?
			end
		end
		self.round = CombatRound.END_ROUND
		return
	end

	self.result = self:GetResult()
end

function Combat:IsDayEnd()
	return self.round >= CombatRound.END_ROUND
end

function Combat:SelectTarget( line, side, fn )
	if not line then return nil end
	local targetList = {}
	for _, target in ipairs( line ) do
		if target:IsInCombat() and target._combatSide ~= side and fn( target ) then
			table.insert( targetList, target )
		end
	end
	if #targetList == 0 then return nil end
	local index = Random_SyncGetRange( 1, #targetList, "Random Target" )
	return targetList[index]
end

function Combat:FindTargetInLine( troop, line )
	local lineTroops = nil
	if line == TroopStartLine.FRONT then lineTroops = self.frontLine
	elseif line == TroopStartLine.BACK then lineTroops = self.backLine
	elseif line == TroopStartLine.DEFENCE then lineTroops = self.defenceLine
	elseif line == TroopStartLine.CHARGE then lineTroops = self.chargeLine
	elseif line == TroopStartLine.MELEE then lineTroops = self.meleeLine
	end	
	--self:ShowText( "find line", MathUtility_FindEnumName( TroopStartLine, line ), lineTroops and #lineTroops or 0 )
	return self:SelectTarget( lineTroops, troop._combatSide, function ( target )
			return true
		end )
end

function Combat:FindLinetarget( troop )
	local target = nil
	for line = TroopStartLine.MELEE, TroopStartLine.BACK, -1 do
		target = self:FindTargetInLine( troop, line )
		if target then break end 
	end
	--self:ShowText( NameIDToString( troop ) .. " Find target=" .. ( target and target.name or "" ) )
	return target
end

function Combat:FindShootTarget( troop )
	local weapon = troop:GetRangeWeapon()
	local target = nil
	for line = TroopStartLine.MELEE, TroopStartLine.FRONT, -1 do
		target = self:FindTargetInLine( troop, line )
		if target then break end 
	end
	--self:ShowText( NameIDToString( troop ) .. " Find target=" .. ( target and target.name or "" ) )
	return target
end

function Combat:FindGateTarget( troop, params )
	return self:SelectTarget( self.defenceLine, troop._combatSide, function ( target )
			return target.table.category == TroopCategory.GATE
		end )
end
function Combat:FindDefenceTarget( troop, params )
	return self:SelectTarget( self.defenceLine,troop._combatSide, function ( target )
			return target.table.category == TroopCategory.DEFENCE
		end )
end
function Combat:FindTowerTarget( troop, params )
	return self:SelectTarget( self.defenceLine,troop._combatSide, function ( target )
			return target.table.category == TroopCategory.TOWER
		end )
end

function Combat:FindSiegeTarget( troop, params )
	return self:SelectTarget( self.defenceLine,troop._combatSide, function ( target )
			return target:IsDefence()
		end )
end

--[[
	Purse target: in Line of "Melee, Charge"
]]
function Combat:FindPursueTarget( troop )
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

--[[
	Defence Construction Target: in Line of "Melee, Charge"
]]
function Combat:FindDefenceTarget( troop )
	local target = nil
	for line = TroopStartLine.MELEE, TroopStartLine.CHARGE, -1 do
		target = self:FindTargetInLine( troop, line )
		if target then break end 
	end
	--self:ShowText( NameIDToString( troop ) .. " Find target=" .. ( target and target.name or "" ) )
	return target
end

--------------------------------------------------

function Combat:CalcAttackTimes( weapon )
	return math.floor( 0.5 + CombatParams.DEFAULT_ATTACK_TIME / ( weapon.weight * weapon.range + weapon.cd ) )
end

---------------------------------
-- Very Important function !!!!
--
---------------------------------
function Combat:CalcWeaponDamage( modNumber, weapon, armor, params )
	--Hit times Modification
	local atkTimes = self:CalcAttackTimes( weapon )
	if armor then
		if armor.weight < weapon.weight * 0.8 then
			atkTimes = math.max( 1, atkTimes - 2 )
		elseif armor.weight < weapon.weight * 1.2 then
			atkTimes = math.max( 1, atkTimes - 1 )
		elseif armor.weight > weapon.weight * 4 then
			atkTimes = math.max( 1, atkTimes + 2)
		elseif armor.weight > weapon.weight * 2.5 then
			atkTimes = math.max( 1, atkTimes + 1 )
		end
	end
	--[[
	local dmg = 0
	local dmgContent = ""
	for k = 1, atkTimes do
		-- Weapon & Armor modification
		local protection = armor and armor.protection or 0
		local weaponRate = armor and weapon.power * math.min( 100, ( 100 - math.min( 100, protection ) ) ) or weapon.power
		local defendRate = 1 --armor and math.max( 1, ( weapon.weight - armor.weight ) / ( weapon.weight + armor.weight ) ) or 1		
		--local weaponRate = armor and math.max( 10, ( weapon.power - armor.protection ) ) / ( 100 + armor.protection ) or 1
		--local weaponRate = armor and math.max( 10, math.min( 250, weapon.power * armor.protection / ( 100 + armor.protection ) ) ) or 100
		--local weaponMod = Random_SyncGetRange( weapon.power - weapon.weight, weapon.power + math.max( 0, weapon.range - weapon.weight * 0.5 ) )
		--local armorMod  = armor and Random_SyncGetRange( armor.protection - armor.weight, armor.protection ) or 0
		--local weaponRate = math.max( 10, weaponMod - (  weaponMod >= armorMod and 1 or 2 ) * armorMod )
		-- Calculate Base Damage Value
		local curDmg = math.floor( modNumber * weaponRate * defendRate * 0.0001 )
		dmg = dmg + curDmg
		dmgContent = dmgContent .. "(" .. curDmg .. "," .. math.floor( weaponRate ) .. ")"--," .. defendRate .. "," .. protection .. "," .. armor.protection .. ")"
	end
]]
	local dmg = 0
	local weaponRate = armor and weapon.power * math.min( 100, ( 100 - math.min( 100, armor.protection ) ) ) or weapon.power	
	for k = 1, atkTimes do		
		local curDmg = math.ceil( modNumber * weaponRate * 0.0001 )	
		if params.criticalProb > 0 and Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "critical prob" ) < params.criticalProb then
			curDmg = curDmg * CombatParams.CRITICAL_MODULUS
		end
		dmg = dmg + curDmg
	end

	--ShowText( weapon.name, atkTimes, weapon.weight * weapon.range, weapon.cd, " pow=" .. weapon.power )
	--ShowText( "times=" .. atkTimes .. " dmg="..dmg .. " num=" .. modNumber .. " weapon=" .. weapon.power..","..armor.protection .. " weight=" .. weapon.weight .. "," .. armor.weight )	
	
	return dmg
end

function Combat:CalcDamage( troop, target, weapon, armor, params )
	------------------------------------
	-- 		Critical Modification
	------------------------------------
	if params.isMelee then
		local cprob1 = ( troop.morale - target.morale ) * 10000 / ( troop.morale + target.morale )
		local cprob2 = ( troop.level - target.level ) * 10000 / ( troop.level + target.level )
		params.criticalProb = ( cprob1 + cprob2 ) * 0.5
	end

	------------------------------------
	-- 		Calculate Base Damage	
	------------------------------------
	local modNumber = math.max( troop.number, target.number ) / CombatParams.DEFAULT_LINE_DEPTH
	local dmg = self:CalcWeaponDamage( modNumber, weapon, armor, params )	

	------------------------------------
	-- 		Damage Modification
	------------------------------------
	--	Counter Attack Reduce
	if params.isCounter then dmg = dmg * 0.65 end
	
	--	Move & Hit
	if params.isMissile and target._startLine == TroopStartLine.CHARGE then dmg = dmg * 0.45 end

	if params.isPursue then dmg = dmg * Random_SyncGetRange( 1.5, 3 ) end
	
	--	Reduction after ATTACK too many times
	if troop:IsAttacked() then dmg = dmg * 0.5 end --MathUtility_Clamp( 1 - 0.35 * troop:GetAttackTime(), 0.3, 1 ) end

	--	Addtion after DEFEND too many times
	if target:IsDefended() then dmg = dmg * MathUtility_Clamp( 1 + 0.35 * target:GetDefendTime(), 1, 2.5 ) end
	
	--	Siege Combat, Attacker penalty & Defender penalty
	if self.type == CombatType.SIEGE_COMBAT then
		if troop._combatSide == CombatSide.ATTACKER then
			local ratio = 0.35
			if self:HasStatus( CombatStatus.GATE_BROKEN ) then ratio = ratio + 0.3 end
			if self:HasStatus( CombatStatus.WALL_BROKEN ) then ratio = ratio + 0.3 end
			dmg = dmg * ratio
		elseif troop._combatSide == CombatSide.DEFENDER then
			dmg = dmg * 0.65
		end
	end
	
	-----------------------------
	-- 		Trait
	-- to do!!!
	-----------------------------
	
	-----------------------------
	-- 		Weather penalty
	------------------------------------
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
	-----------------------------
	dmg = math.floor( dmg )

	return dmg
end

function Combat:Retreat( target )	
	--print( NameIDToString( target ), MathUtility_FindEnumName( CombatSide, target._combatSide ), " retreat", target.morale, target:GetCombatOrganization() * 100 / target.maxNumber )
	self:MoveToLine( target, TroopStartLine.BACK )
	target:Flee()

	if target._combatSide == CombatSide.ATTACKER then
		self.atkMorale = math.max( 0, self.atkMorale - math.ceil( 100 / self:GetTroopNumber( target._combatSide ) ) )
	elseif target._combatSide == CombatSide.DEFENDER then		
		self.defMorale = math.max( 0, self.defMorale - math.ceil( 100 / self:GetTroopNumber( target._combatSide ) ) )
	end
end

function Combat:Flee( target )
	--print( NameIDToString( target ), MathUtility_FindEnumName( CombatSide, target._combatSide ), " flee" )
	self:Retreat( target )
	
	local totalNum, troop, troop, morale, fatigue, startNum, maxNum = self:GetSideStatus( target._combatSide )
	for k, troop in ipairs( self.troops ) do
		if troop:IsCombatUnit() and troop.id ~= target.id and troop._combatSide == target._combatSide then
			troop:LoseMorale( math.ceil( target.number * 100 / totalNum ), nil, 1 )
		end
	end
end

function Combat:LostMorale( target, morale )	
	if not target:IsInCombat() then return end

	target:LoseMorale( morale )

	self:ShowText( NameIDToString( target ), "lose morale=" .. morale .. "->" .. target.morale )

	local attitude = self:GetAttitude( target._combatSide )
	if target.number <= 0 then self.morale = 0 end
	if target.morale <= 0 then self:Flee( target ) return end
	if target:GetCombatOrganization() <= 0 then
		target:LoseMorale( math.ceil( target.morale * 0.5 ) )
		self:Retreat( target )
	end
end

function Combat:DealDamage( troop, target, damage )
	troop:DealDamage( damage )
	damage = target:ReduceOrganization( damage )
	damage = target:SufferDamage( damage )
	troop:KillSoldier( target, damage, not target:IsAlive() )
	if troop._combatSide == CombatSide.ATTACKER then
		self.atkKill = self.atkKill + damage
	else
		self.defKill = self.defKill + damage
	end
	g_statistic:DieInCombat( damage )	
	return damage
end

-----------------------------------
-- Very important function!!!!!!!!
-----------------------------------
function Combat:Hit( troop, target, params )
	if not params or not troop:IsAlive() then
		self:ShowText( "troop is not alive", NameIDToString( troop ) )
		return
	end
	if target:IsFled() and not params.isPursue then
		self:ShowText( "target is fled", NameIDToString( target ) )
		return
	end
	
	-------------------------------------
	-- Choose Weapon & Armor
	-------------------------------------	
	local atkWeapon = nil
	if params.isMissile then atkWeapon = troop:GetRangeWeapon()
	elseif params.isCharge then atkWeapon = troop:GetChargeWeapon()
	elseif params.isMelee then atkWeapon = troop:GetCloseWeapon()		
	elseif params.isSiege then atkWeapon = troop:GetSiegeWeapon()
	elseif params.isTower then atkWeapon = troop:GetRangeWeapon()
	end
	if not atkWeapon then
		self:ShowText( NameIDToString( troop ) .. " don't have right weapon", params.isMissile, params.isCharge, params.isMelee, params.isCounter, params.isTower )
		return
	end
	--[[
	local atkTimes = self:CalcAttackTimes( atkWeapon )
	if troop:GetAttackTime() > atkTimes then
		--self:ShowText( "troop cann't attack again", NameIDToString( troop ), atkTimes )
		return
	end
	]]

	local defArmor = target:GetDefendArmor( atkWeapon )
	troop:UseWeapon( atkWeapon )
	target:UseArmor( defArmor )

	-------------------------------------
	-- Calculate Damage
	-------------------------------------
	local damage = self:CalcDamage( troop, target, atkWeapon, defArmor, params )
	
	-------------------------------------
	-- Deal Damage
	-------------------------------------	
	local oldNumber = target.number	
	self:DealDamage( troop, target, damage )
	self:Log( NameIDToString( troop ) .. "+" .. troop.number .. ( params.isCounter and " counter " or " hit" ) .. NameIDToString( target ) .. "+" .. target.number .. " use ["..atkWeapon.name.."] vs [" .. defArmor.name .. "] deal dmg=" .. damage )
	
	-------------------------------------
	-- Calculate Score( Victory Point )
	-------------------------------------
	local rate = damage / oldNumber
	local score = 0
	for k, data in ipairs( CombatParams.DAMAGE_SCORE ) do
		if rate < data.rate then 
			--self:ShowText( MathUtility_FindEnumName( CombatSide, troop._combatSide ) .. " score+", data.score, rate )
			score = data.score
			score = damage
			self:LostMorale( target, math.floor( target.morale * data.rate + data.morale ) )
			break
		end
	end
	if troop._combatSide == CombatSide.ATTACKER then
		self.atkScore = self.atkScore + score
	else
		self.defScore = self.defScore + score
	end

	if not params.isPursue and not target:IsInCombat() then
		troop:Banish()
	end
	
	-------------------------------------
	-- Counterattack
	-------------------------------------
	if target:CanAct() and not params.isCounter and not params.isPursue and ( params.isMelee or params.isCharge ) then
		if troop._startLine ~= TroopStartLine.CHARGE then
			self:Hit( target, troop, { isCounter = true, isMelee = true } )
		end
	end
end

function Combat:MoveToLine( troop, line )
	local lineTroops
	if troop._startLine == TroopStartLine.DEFENCE then
		return
	elseif troop._startLine == TroopStartLine.BACK then
		lineTroops = self.backLine
	elseif troop._startLine == TroopStartLine.FRONT then
		lineTroops = self.frontLine
	elseif troop._startLine == TroopStartLine.CHARGE then
		lineTroops = self.chargeLine
	elseif troop._startLine == TroopStartLine.MELEE then
		lineTroops = self.meleeLine
	end
	if not lineTroops then return end

	MathUtility_Remove( lineTroops, troop )

	local targetLine = self.backLine
	table.insert( targetLine, troop )
	troop._startLine = TroopStartLine.BACK
end

function Combat:GetLineTroop( troops )
	--return MathUtility_ShallowCopy( troops, g_syncRandomizer )
 	return MathUtility_Shuffle( troops, g_syncRandomizer )
end

-- 1. Shoot Round   -- Actor[ All archer ]  Target [ Charge Line / Front Line / Back Line ]
function Combat:Shoot()
	self.shootRound = self.shootRound + 1

	local lineTroops = self:GetLineTroop( self.troops )
	for k, troop in ipairs( lineTroops ) do
		if troop:CanAct() then
			local target = troop:CanShoot() and self:FindShootTarget( troop ) or nil
			if target then
				self:Hit( troop, target, { isMissile = true } )
			end
		end
	end
end

function Combat:SiegeWeaponAttack()
	if not self:HasStatus( CombatStatus.GATE_BROKEN ) then
		local lineTroops = self:GetLineTroop( self.meleeLine )
		for k, troop in ipairs( lineTroops ) do
			if troop:CanAct() and troop:IsSiegeWeapon() then
				local target = self:FindGateTarget( troop )
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
	if not self:HasStatus( CombatStatus.TOWER_BROKEN ) then
		local lineTroops = self:GetLineTroop( self.meleeLine )
		for k, troop in ipairs( lineTroops ) do
			if troop:CanAct() and troop:IsSiegeWeapon() then
				local target = self:FindTowerTarget( troop )
				if not target then
					--todo
					self:AddStatus( CombatStatus.TOWER_BROKEN )
					break
				else
					self:Hit( troop, target, { isSiege = true } )
				end
			end
		end
	end
	if not self:HasStatus( CombatStatus.WALL_BROKEN ) then
		local lineTroops = self:GetLineTroop( self.backLine )
		for k, troop in ipairs( lineTroops ) do
			if troop:CanAct() and troop:IsSiegeWeapon() then
				local target = nil
				if not self:HasStatus( CombatStatus.WALL_BROKEN ) then
					target = self:FindDefenceTarget( troop )
					if not target then
						--todo
						self:AddStatus( CombatStatus.WALL_BROKEN )
						break
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
	local lineTroops = self:GetLineTroop( self.chargeLine )
	for k, troop in ipairs( lineTroops ) do
		self:ShowText( NameIDToString( troop ), "charge", troop:CanCharge() )
		if troop:IsInCombat() and troop:CanCharge() then			
			local target = self:FindLinetarget( troop )
			if target then
				self:Hit( troop, target, { isCharge = true } )
			end
		end		
	end
	for k, troop in ipairs( lineTroops ) do
		troop._startLine = TroopStartLine.MELEE
	end
	self.meleeLine = self.chargeLine
	self.chargeLine = {}
end

-- 3. Forward Round -- Actor [ All footman / All archer ]
function Combat:Forward()
	self.fowardRound = self.fowardRound + 1

	local removes = {}

	------------------------------------
	-- Move forward from CHARGE
	for k, troop in ipairs( self.chargeLine ) do
		--InputUtility_Pause( NameIDToString( troop ), "move to melee line")
		troop._startLine = TroopStartLine.MELEE
	end
	self.meleeLine = self.chargeLine
	------------------------------------

	------------------------------------
	-- Move forward from FRONT
	local line = {}
	for k, troop in ipairs( self.frontLine ) do
		if troop:IsInCombat() and troop:CanForward() then
			troop._startLine = TroopStartLine.MELEE
			table.insert( self.meleeLine, troop )
		else
			table.insert( line, troop )
		end
	end
	self.frontLine = line
	------------------------------------
	
	------------------------------------
	--Move DEFENDERS
	if self.type == CombatType.SIEGE_COMBAT then
		local line = {}
		for k, troop in ipairs( self.backLine ) do
			if troop:IsInCombat() and troop:CanForward() and troop._combatSide == CombatSide.DEFENDER then
				troop._startLine = TroopStartLine.MELEE
				table.insert( self.meleeLine, troop )
			else
				table.insert( line, troop )
			end
		end	
		self.backLine = line
	end
	------------------------------------
end

-- 4. Fight Round   -- Actor[ All footman / All cavalry / All archer ] Target [ Charge Line / Front Line / Back Line ]
function Combat:Fight()
	self.fightRound = self.fightRound + 1

	local lineTroops = self:GetLineTroop( self.meleeLine )
	for k, troop in ipairs( lineTroops ) do
		if troop:IsInCombat() then
			local target = self:FindLinetarget( troop )
			if target then
				self:Hit( troop, target, { isMelee = true } )
			end
		end
	end
end

-- 5. Pursue Round
function Combat:Pursue()
	for k, troop in ipairs( self.troops ) do
		if troop:IsInCombat() and not troop:IsFled() then			
			local target = self:FindPursueTarget( troop )			
			if target then
				self:Hit( troop, target, { isMelee = true, isPursue = true } )
			end
		end
	end
end

function Combat:CityDefenceAttack()
	for k, troop in ipairs( self.defenceLine ) do
		if troop.table.category == TroopCategory.TOWER then
			local target = self:FindDefenceTarget( troop )
			if target then
				self:Hit( troop, target, { isTower = true } )
			end
		end
	end
end