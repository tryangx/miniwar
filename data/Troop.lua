Troop = class()

function Troop:Generate( data )	
	self:Load( data )
	self.tableId = data.id
	self:ConvertID2Data()
end

function Troop:Load( data )
	self.id = data.id or 0	
	self.name = data.name or ""
	self.tableId  = data.tableId or 0
	---------------------------------------
	-- Growth
	self.maxLevel  = data.maxLevel or 0
	self.level     = data.level or 0
	self.exp       = data.exp or 0
	-- Potential Ability
	-- Determined by birthplace, it limits maximum level of troop
	self.pa        = data.pa or 0			
	---------------------------------------
	-- Belong Data	
	self.leader     = data.leader or 0	
	self.corps      = data.corps or 0	
	self.location   = data.location or 0	
	self.home = data.home or 0	
	---------------------------------------
	-- Attributes	
	self.maxNumber = data.maxNumber or 0	
	self.maxMorale = data.maxMorale or 0
	self.wounded   = data.wounded or 0	
	self.number    = data.number or 0	
	self.morale    = data.morale or 0
	---------------------------------------
	-- Data
	self.movement  = data.movement or 0	
	self.tags     = MathUtility_Copy( data.tags )	
	self.fatigue  = data.fatigue or 0
	self.tactic   = data.tactic or CombatTactic.DEFAULT		
	self.buffs    = MathUtility_Copy( data.buffs )	
	self.traits   = MathUtility_Copy( data.traits )
	self.disguise = data.disguise or 0	
	---------------------------------------
	-- Combat Temporary Data	
	self._combatSide   = CombatSide.NEUTRAL	
	self._combatAction = CombatAction and CombatAction.NONE	or 0
	self._combatTarget = nil
	self._combatCD     = 0
	-- now only 1d, extension to 2d
	self._combatPosX   = 0
	self._combatPosY   = 0
	self._startPosX    = 0
	self._startPosY    = 0
	self._startLine    = 0
end

function Troop:SaveData()
	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	Data_OutputValue( "id", self )
	Data_OutputValue( "name", self )	
	
	Data_OutputValue( "tableId", self )
	
	Data_OutputValue( "leader", self, "id", 0 )	
	Data_OutputValue( "corps", self, "id", 0 )	
	Data_OutputValue( "location", self, "id", 0 )	
	Data_OutputValue( "home", self, "id", 0 )	
	
	Data_OutputValue( "level", self )
	Data_OutputValue( "exp", self )
	Data_OutputValue( "pa", self )	
	
	Data_OutputValue( "wounded", self )
	Data_OutputValue( "number", self )
	Data_OutputValue( "maxNumber", self )
	Data_OutputValue( "morale", self )
	Data_OutputValue( "maxMorale", self )
	Data_OutputValue( "movement", self )
	
	Data_OutputTable( "tags", self )
	Data_OutputValue( "fatigue", self )	
	Data_OutputValue( "tactic", self )
	Data_OutputTable( "traits", self, "id" )	
	Data_OutputTable( "buffs", self )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
end


function Troop:ConvertID2Data()
	self.table = g_troopTableMng:GetData( self.tableId )

	self.leader = g_charaDataMng:GetData( self.leader )
	self.corps = g_corpsDataMng:GetData( self.corps )	
	self.location   = g_cityDataMng:GetData( self.location )
	self.home = g_cityDataMng:GetData( self.home )
	
	local traits = {}
	for k, id in ipairs( self.traits ) do
		local trait = g_traitTableMng:GetData( id )
		table.insert( traits, trait )
	end
	self.traits = traits

	--default data	
	if self.maxNumber == 0 then self.maxNumber = self.table.maxNumber end
	if self.maxMorale == 0 then self.maxMorale = self.table.maxMorale end
	if self.movement  == 0 then self.movement  = self.table.movement end
	if self.level     == 0 then self.level     = self.table.level end
	if self.morale    == 0 then self.morale    = self.table.maxMorale end
end

function Troop:CreateBrief()
	local content = ""
	content = NameIDToString( self ) .. " LD=" .. NameIDToString( self:GetLeader() ) .. " Home=" .. NameIDToString( self.home ) .. " Loc=" .. NameIDToString( self.location )
	return content
end

function Troop:Dump( indent )
	if not indent then indent = "" end
	local content = indent .. "Troop=".. self.name .. " Mor=" .. self.morale .. "/" .. self.maxMorale
	content = content .. " Num=" .. self.number .. "/" .. self.maxNumber
	if self:GetCorps() then
		content = content .. " Corps=" .. self:GetCorps().name
	end		
	if self:GetLeader() then
		content = content .. " LD=" .. self:GetLeader().name
	end
	if self:GetHome() then
		content = content .. " Loc=" .. self:GetHome().name
	end
	ShowText( content )
end

-----------------------------------
-- Getter
function Troop:GetGroup()
	return self.group
end

function Troop:GetLeader()
	return self.leader
end

function Troop:GetCorps()
	return self.corps
end

function Troop:GetLocation()
	return self.location
end

function Troop:GetHome()
	return self.home
end

function Troop:GetLevel()
	return self.level
end

function Troop:GetPower()
	return self.number
end

function Troop:GetCombatPower()
	local closeWeapon = self:GetCloseWeapon()
	local chargeWeapon = self:GetChargeWeapon()
	if not closeWeapon and not chargeWeapon then return 0 end
	return math.floor( self.number * math.max( closeWeapon.power, chargeWeapon.power ) * 0.01 )
end
function Troop:GetSiegePower()
	local siegeWeapon = self:GetSiegeWeapon()
	local rangeWeapon = self:GetRangeWeapon()	
	if not siegeWeapon and not rangeWeapon then return 0 end
	return math.floor( self.number * math.max( siegeWeapon.power, rangeWeapon.power ) * 0.01 )
end

function Troop:GetStatusDesc()
	if self.number <= 0 then
		return "[NEUTRALIZED]"
	elseif self._combatFled == true then
		return "[FLED]"
	elseif self._combatSurrendered == true then
		return "[SURRENDER]"
	end
	return "[NORMAL]"
end

-----------------------------------
-- Operation

function Troop:JoinCorps( corps )	
	self.corps = corps
	--ShowText( "Add to corps", self.name, corps.name )
end

function Troop:LeadByChara( chara )
	self.leader = chara
	ShowText( NameIDToString( self ) .. " change leader to=" .. NameIDToString( chara ) )	
end

-----------------------------------
-- Combat Getter

function Troop:IsNoneTask()
	if g_taskMng:GetTaskByActor( self ) then return false end
	if self.corps and g_taskMng:GetTaskByActor( self.corps ) then return false end
	if self.leader and g_taskMng:GetTaskByActor( self.leader ) then return false end
	return true
end

function Troop:IsAtHome()
	return self.location == self.home and not g_movingActorMng:HasActor( MovingActorType.TROOP, self )
end

function Troop:IsInCombat()
	return self.number > 0 and self._combatFled ~= true and self._combatSurrendered ~= true
end

function Troop:IsFled()
	return self.number > 0 and self._combatFled == true
end

function Troop:IsDefence()
	return self.table.category == TroopCategory.DEFENCE
end

function Troop:IsGate()
	return self.table.category == TroopCategory.GATE
end

function Troop:IsCombatUnit()
	return self.table.category ~= TroopCategory.GATE and self.table.category ~= TroopCategory.DEFENCE and self.table.category ~= TroopCategory.TOWER
end

function Troop:IsSiegeWeapon()
	return self.table.category == TroopCategory.SIEGE_WEAPON
end

function Troop:IsSupport()
	return self.table.category == TroopCategory.ARTILLERY
end

function Troop:IsAlive()
	return self.number > 0
end

function Troop:IsOther( target )
	return target.id ~= self.id
end

function Troop:IsFriend( target )
	return target._combatSide == self._combatSide and target.id ~= self.id
end

function Troop:IsEnemy( target )
	return target._combatSide ~= self._combatSide
end

function Troop:CanAct()
	return self:IsCombatUnit() and not self:IsActed()
	--return self._combatCD <= 0 and self:IsCombatUnit() and not self:IsActed()
end

function Troop:CanForward()
	return self.table.category == TroopCategory.FOOTSOLDIER or self.table.category == TroopCategory.CAVALRY
end

function Troop:CanSiegeAttack()
	return self:GetSiegeWeapon()
end

function Troop:CanShoot()
	return self:GetRangeWeapon()
end

function Troop:CanCharge()
	return self:GetChargeWeapon() or self:GetLongWeapon()
end

function Troop:CanMeleeFight()
	return self:GetCloseWeapon()
end

function Troop:NewCombat()
	self._combatFled        = false
	self._combatSurrendered = false

	self._combatDealDamage   = 0
	self._combatSufferDamage = 0
	self._combatAttackTimes  = 0
	self._combatDefendTimes  = 0
	self._combatKillList     = {}
	self._combatKill         = 0
	
	self._combatOrganization = math.ceil( self.morale * self.number * 0.01 )

	-- init action
	self._combatPurpose = CombatTroopPurpose.NONE
	
	-- temporary data
	self._combatArmorWeight = 0
	
	self:NextCombatTurn()
end

function Troop:EndCombat()
	self._combatSide = CombatSide.NEUTRAL
	self._combatId   = 0
end

function Troop:NextCombatTurn()
	self._combatWeapon   = nil	
	self._combatDecided  = false
	self._combatActed    = false	
	self._combatMoved    = false
	self._combatAttacked = 0
	self._combatDefended = 0
	self._combatParry    = false
	self._combatTarget   = nil
	self._combatAction   = CombatAction and CombatAction.NONE or 0
end

function Troop:NextCombatDay()
	self._combatFled = false

	if self.morale >= self:GetMaxMorale() then
		local buff = self:GetBuff( CombatBuff.MORALE_BUFF )
		if buff then
			buff.value = MathUtility_Clamp( buff.value + 1, -2, 2 )
		end
		self:RecoverMorale( math.ceil( self.morale + self:GetMaxMorale() * 0.2 ) )
	end
end

function Troop:RestADay()
	self._combatOrganization = math.ceil( self.morale * self.number * 0.01 )
end

function Troop:Acted()
	self._combatActed = true
end

function Troop:Decide()
	self._combatDecided = true
end

function Troop:MoveTo( xPos, yPos )
	self._combatMoved = true
	self._combatPosX = xPos or self._combatPosX
	self._combatPosY = yPos or self._combatPosY
	--ShowText( self.name .. " move to " .. self._combatPosX )
end

function Troop:IsActed()
	return self._combatActed
end

function Troop:IsDecided()
	return self._combatDecided
end

function Troop:IsMoved()
	return self._combatMoved
end

function Troop:IsAttacked()
	return self._combatAttacked > 0
end

function Troop:IsDefended()
	return self._combatDefended
end

function Troop:IsParried()
	return self._combatParry
end

function Troop:IsSiegeUnit()
	return self.table.category == TroopCategory.SIEGE_WEAPON
end

function Troop:HasSiegeWeapon()
	return self:GetWeapon( function( weapon )
		return weapon:IsSiegeWeapon()
	end )
end

function Troop:HasMissileWeapon()
	return self:GetWeapon( function( weapon )
		return weapon:IsMissileWeapon()
	end )
end

-----------------------------
-- Getter 

function Troop:GetNameDesc()
	return "[" .. self.name .. "(" .. self.id .. ")] "
end

function Troop:GetCoordinateDesc()
	return "(" .. self._combatPosX .. "," .. self._combatPosY .. ") "
end

function Troop:GetArmorWeight()
	if self._combatArmorWeight > 0 then return self._combatArmorWeight end
	local weight = 0
	for k, armor in ipairs( self.table.armors ) do
		weight = weight + armor.weight
	end
	self._combatArmorWeight = weight
	return weight
end

-- local Interface
function Troop:GetWeapon( condition )
	if not self.table then return nil end
	local selWeapon = nil
	for k, weapon in ipairs( self.table.weapons ) do
		if condition( weapon ) then	selWeapon = weapon end
	end
	--if selWeapon then ShowText( "Find weapon", self.name, selWeapon.name ) end
	return selWeapon
end

function Troop:GetRangeWeapon()
	if self._combatWeapon then
		if self._combatWeapon:IsFireWeapon() then
			return self._combatWeapon
		end
		--Debug_Log( "["..self.name.."]("..self.id..") Can't fire, still use ["..self._combatWeapon.name.."]" )
		return nil
	end
	return self:GetWeapon( function ( weapon )
		return weapon:IsFireWeapon()
	end )
end

function Troop:GetChargeWeapon()
	if self._combatWeapon then
		if self._combatWeapon:IsChargeWeapon() then
			return self._combatWeapon
		end
		--Debug_Log( self:GetNameDesc() .. " Can't charge, still use ["..self._combatWeapon.name.."]" )
		return nil
	end
	return self:GetWeapon( function ( weapon )
		return weapon:IsChargeWeapon()
	end )
end

--only used to block charge
function Troop:GetLongWeapon()
	if self._combatWeapon then
		if self._combatWeapon:IsLongWeapon() then
			return self._combatWeapon
		end
		--Debug_Log( self:GetNameDesc() .. " Can't change long, still use ["..self._combatWeapon.name.."]" )
		return nil
	end
	return self:GetWeapon( function ( weapon )
		return weapon:IsLongWeapon()
	end )
end

--melee fight
function Troop:GetCloseWeapon()
	if self._combatWeapon then
		if self._combatWeapon:IsCloseWeapon() then
			return self._combatWeapon
		end
		--Debug_Log( self:GetNameDesc() .. " Can't change close, still use ["..self._combatWeapon.name.."]" )
		return nil
	end
	return self:GetWeapon( function ( weapon )
		return weapon:IsCloseWeapon()
	end )
end

function Troop:GetSiegeWeapon()
	if self._combatWeapon then
		if self._combatWeapon:IsSiegeWeapon() then
			return self._combatWeapon
		end
		--Debug_Log( self:GetNameDesc() .. " Can't change siege, still use ["..self._combatWeapon.name.."]" )
		return nil
	end
	return self:GetWeapon( function ( weapon )
		return weapon:IsSiegeWeapon()
	end )
end

function Troop:GetArmor( condition )	
	if not self.table then return nil end
	local selArmor = nil
	for k, armor in ipairs( self.table.armors ) do
		if condition( armor ) then
			selArmor      = armor
		end
	end	
	return selArmor
end

function Troop:GetDefendArmor( weapon )
	if not weapon then return nil end
	local selArmor = nil
	if weapon:IsFireWeapon() then
		selArmor = self:GetArmor( function ( armor )
			return armor:CanDefendMissile()
		end )		
	elseif weapon:IsLongWeapon() then
		selArmor = self:GetArmor( function ( armor )
			return armor:CanDefendLongWeapon()
		end )
	elseif weapon:IsCloseWeapon() then
		selArmor = self:GetArmor( function ( armor )
			return armor:CanDefendCloseWeapon()
		end )
	elseif weapon:IsChargeWeapon() then	
		selArmor = self:GetArmor( function ( armor )
			return armor:CanDefendChargeWeapon()
		end )
	end
	if not selArmor and #self.table.armors > 0 then
		selArmor = self.table.armors[Random_SyncGetRange( 1, #self.table.armors, "Random Armor" )]
	end
	return selArmor
end

function Troop:GetMaxMorale()
	local buff = self:GetBuff( CombatBuff.MORALE_BUFF )
	if buff then
		return self.maxMorale * ( 1 + buff.value * 0.2 )
	end
	return self.maxMorale
end

function Troop:GetCombatOrganization()
	return self._combatOrganization
end

function Troop:GetAttackTime()
	return self._combatAttacked
end

function Troop:GetDefendTime()
	return self._combatDefended
end

-------------------------------
-- Combat Operation

function Troop:ChooseTarget( target, description )
	self._combatTarget = target
	Debug_Log( self:GetNameDesc() .. " choose target " .. ( target and target:GetNameDesc() or "" ) .." for "..( description or "" ) )
end

--in a turn, troop can only use only weapon
function Troop:UseWeapon( weapon )	
	self._combatWeapon = weapon	
	self._combatCD     = weapon.cd
	self._combatAttacked = self._combatAttacked and self._combatAttacked + 1 or 1
	--Debug_Log( self:GetNameDesc() .. " use weapon ["..weapon.name.."]" )
end

function Troop:UseArmor( armor )
	self._combatDefendTimes = self._combatDefendTimes + 1
	self._combatDefended    = self._combatDefended and self._combatDefended + 1 or 1
end

function Troop:RecoverMorale( value )
	self.morale = MathUtility_Clamp( self.morale + value, 0, self:GetMaxMorale() )
end

function Troop:LoseMorale( value )
	self.morale = MathUtility_Clamp( self.morale - value, 0, self:GetMaxMorale() )
end

function Troop:DealDamage( damage )
	self._combatAttackTimes = self._combatAttackTimes + 1
	self._combatDealDamage  = self._combatDealDamage + damage
	--Debug_Log( "["..self.name.. "] deal damage " .. damage )
end

function Troop:ReduceOrganization( damage )
	local rate = self._combatOrganization / ( self._combatOrganization + self.number )
	self._combatOrganization = math.max( 0, self._combatOrganization - damage )	
	local ret = math.ceil( damage * ( 1 - rate ) )
	return ret
end

function Troop:SufferDamage( damage )	
	if self.number < damage then
		damage = self.number
		self.number = 0
		Debug_Log( self:GetNameDesc() .. " suffer damage " .. damage .. ", neutralized" )						
	else
		self.number = self.number - damage
		Debug_Log( self:GetNameDesc() .. " suffer damage " .. damage .. ", remain " .. self.number  )
	end
	self._combatSufferDamage = self._combatSufferDamage + damage
	return damage
end

function Troop:Parry()
	self._combatParry = true
end

function Troop:KillSoldier( enemy, damage, neutralized )	
	table.insert( self._combatKillList, enemy )	
	self._combatKill = self._combatKill + damage
	
	local rate = ( enemy:GetLevel() - self:GetLevel() ) / ( enemy:GetLevel() + self:GetLevel() )
	local exp = math.ceil( damage * ( 1 + ( enemy:GetLevel() - self:GetLevel() ) / ( enemy:GetLevel() + self:GetLevel() ) ) )
	if neutralized then exp = exp * 2 end
	self:GainExp( exp )
	--InputUtility_Pause( "lv=" .. self:GetLevel() .. " gain exp=" .. exp .. "/" .. self.exp, rate, damage, neutralized )
end

function Troop:Banish()
	local buff = self:GetBuff( CombatBuff.MORALE_BUFF )
	if buff then
		buff.value = MathUtility_Clamp( buff.value + 1, -2, 2 )
	else
		self:AddBuff( CombatBuff.MORALE_BUFF, 1 )
	end
	self:RecoverMorale( math.ceil( self.morale + self:GetMaxMorale() * 0.2 ) )
end

function Troop:Flee()
	local buff = self:GetBuff( CombatBuff.MORALE_BUFF )
	if buff then
		buff.value = MathUtility_Clamp( buff.value - 1, -2, 2 )
	else
		self:AddBuff( CombatBuff.MORALE_BUFF, -1 )
	end
	self._combatFled = true
end

function Troop:Surrender()
	self._combatSurrendered = true
end

function Troop:GainSkill()
	
end

function Troop:GainExp( exp )
	if self:IsCombatUnit() and self.level < self.maxLevel then
		self.exp = self.exp + exp
		if self.exp > TroopParams.LEVEL_UP_EXP then
			self.exp = self.exp - TroopParams.LEVEL_UP_EXP
			self.level = self.level + 1
			self:GainSkill()
		end
	end
end

--------------------------------
-- Combat Buff

-- duration( minutes )
function Troop:AddBuff( buffId, duration, value )
	if not duration then duration = -1 end
	if not value then value = 0 end
	table.insert( self.buffs, { id=buffId, duration=duration, value=value } )
end

function Troop:GetBuff( buffId )
	return MathUtility_FindData( self.buffs, buffId, "id" )
end

function Troop:HasBuff( buffId )
	return MathUtility_IndexOf( self.buffs, buffId, "id" ) ~= nil
end

function Troop:RemoveBuff( buffId )
	MathUtility_Remove( self.buffs, buffId, "id" )
	--ShowText( "remove buff", buffId )
end

function Troop:RemoveAllBuff()
	self.buffs = {}
end

function Troop:UpdateBuff( elapsedTime )
	for k, buff in pairs( self.buffs ) do
		--ShowText( "update buff", buff.id )
		if buff.duration > 0 then
			if buff.duration > elapsedTime then
				buff.duration = buff.duration - elapsedTime
			else
				table.remove( self.buffs, k )
			end
		end
	end
end

function Troop:QueryTrait( effect, params )
	--ShowText( "query trait", effect, #self.traits )
	for k, trait in ipairs( self.traits ) do		
		local data = trait:GetEffect( effect, params )
		if data then
			return data
		end
	end
	if not self.leader then return nil end
	return self.leader:QueryTrait( effect, params )
end

function Troop:GetAsset( tagType )
	return Helper_GetVarb( self.tags, tagType )
end

function Troop:AppendAsset( tagType, value, range )
	Helper_AppendVarb( self.tags, tagType, value, range )
end

function Troop:RemoveAsset( tagType, value )
	Helper_RemoveVarb( self.tags, tagType, value )
end

---------------------------

function Troop:Update()	
	if self:IsCombatUnit() then
		--restore organization
		local trainging = self:GetAsset( TroopTag.TRAINIG )
		if training then
			local restoreRate = 0.3
			if not self:GetCorps() then restoreRate = restoreRate * 0.5 end
			local restore = restoreRate * training.value
			self:AppendAsset( TroopTag.ORGANIZATION, restore, training.value )
		end
		--recover moral		
		if self.morale < self.maxMorale then
			local recoverRate = 0.6
			if not self:GetCorps() then recoverRate = recoverRate * 0.5 end
			local recover = recoverRate * self.maxMorale
			self:RecoverMorale( recover, "update" )
			--ShowText( "morale ", NameIDToString( self ), self.morale, self.maxMorale, recover )
		end
	end
	
end

-------------------------
function Troop:MoveOn( reason )
	g_movingActorMng:AddActor( MovingActorType.TROOP, self, { reason = reason } )
end

function Troop:MoveToLocation( location )
	self.location = location
	g_movingActorMng:RemoveActor( MovingActorType.TROOP, self )
end

function Troop:JoinCity( city, includeAll )
	--print( NameIDToString( self ) .. " join", city and city.name or "none")
	if city and city:GetGroup() ~= self:GetGroup() then	
		InputUtility_Pause( city.name .. "["..city:GetGroup().name.."] isn't belong to", self:GetGroup().name )
		k.p = 1
	end
	self.home = city	
	if includeAll then
		if self.leader then
			self.leader:JoinCity( city )
		end
	end
end

function Troop:JoinGroup( group )
	self.group = group
end

function Troop:RefreshName()
	local oldName = self.name	
	self.name = self:GetGroup().name .. "-" .. self.table.name
	--print( "troop rename="..oldName.."->".. self.name )
end