ResourceCategory = 
{
	NONE       = 0,
	STRATEGIC  = 1,	
	BONUS      = 2,
	LUXURY     = 3,
	NATURAL    = 4,
	ARTIFICIAL = 5,
}

ResourceGenerateCondition =
{
	CONDITION_BRANCH         = 1,
	PROBABILITY              = 2,
	PLOT_TYPE                = 10,	
	PLOT_TERRAIN_TYPE        = 11,	
	PLOT_FEATURE_TYPE        = 12,
	PLOT_TYPE_EXCEPT         = 13,
	PLOT_TERRAIN_TYPE_EXCEPT = 14,
	PLOT_FEATURE_TYPE_EXCEPT = 15,
	NEAR_PLOT_TYPE           = 20,
	NEAR_TERRAIN_TYPE        = 21,
	NEAR_FEATURE_TYPE        = 22,
	AWAY_FROM_PLOT_TYPE      = 23,
	AWAY_FROM_TERRAIN_TYPE   = 24,
	AWAY_FROM_FEATURE_TYPE   = 25,
}

ResourceTable = class()

function ResourceTable:Load( data )
	self.id   = data.id or 0	
	self.name = data.name or 0
	self.category = ResourceCategory[data.category] or ResourceCategory.NONE
	self.bonuses = MathUtility_Copy( data.bonuses )
	self.conditions = MathUtility_Copy( data.conditions )
	
	function ConvertConditionData( conditions )
		for k, condition in ipairs( conditions ) do
			condition.type = ResourceGenerateCondition[condition.type]
			if condition.type == ResourceGenerateCondition.CONDITION_BRANCH then
				ConvertConditionData( condition.value )
			end
		end	
	end
	ConvertConditionData( self.conditions )
end

function ResourceTable:GetBonusValue( bonusType )
	local ret = Helper_SumIf( self.bonuses, "type", bonusType, "value", PlotResourceBonusType )	
	--InputUtility_Pause( self.name, #self.bonuses, ret, MathUtility_FindEnumKey( PlotResourceBonusType, bonusType ) )
	return ret
end