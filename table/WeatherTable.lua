WeatherType = 
{
	BEGIN       = 1,
	
	SUNNY       = 1,
	
	CLOUDY      = 2,
	
	RAINY       = 3,
	
	SNOW        = 4,
	
	FOGGY       = 5,
	
	STORM       = 6,
	
	BLIZZARD    = 7,
	
	DUST_STORM  = 8,

	END         = 8,
}

WeatherTable = class()

function WeatherTable:Load( data )
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	self.type = data.type or WeatherType.SUNNY
	
	-- Percent
	self.movePenalty    = data.movePenalty or 0
	
	-- Percent
	self.meleePenalty   = data.meleePenalty or 0
	
	-- Percent
	self.missilePenalty = data.missilePenalty or 0
end