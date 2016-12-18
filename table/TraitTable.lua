TraitTrigger =
{
	INITIATIVE = 0,
	
	PASSIVE    = 1,
}

TraitCategory =
{
	NONE       = 0,

	COMBAT     = 1,
	
	AFFAIR     = 2,
	
	DIPLOMATIC = 3,
}

TraitTable = class()

function TraitTable:Load( data )
	self.id     = data.id or 0
	
	self.name   = data.name or ""
	
	self.category  = TraitCategory[data.category] or TraitCategory.NONE
	
	self.effects   = MathUtility_Copy( data.effects )
end

function TraitTable:ConvertID2Data()
	for k, data in ipairs( self.effects ) do		
		local effect = data.effect
		data.effect = TraitEffectType[data.effect]
		if data.effect == TraitEffectType.TROOP_MASTER 
		or data.effect == TraitEffectType.TROOP_RESIST then
			data.cond = TroopCategory[data.cond]
		end
		if not data.effect then Debug_Log( "Invalid chara trait effect=", effect ) end
	end
end

function TraitTable:GetEffect( effect, condition )
	for k, data in ipairs( self.effects ) do
		--print( "check effect", data.effect, effect )
		if data.effect == effect then
			if not condition or condition == data.effect then
				return data
			end
		end
	end
	return nil
end
