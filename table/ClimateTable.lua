------------------------------------------------
--
-- Climate
--
-- Climate will determine weather changes
--
------------------------------------------------


ClimateTable = class()

function ClimateTable:Load( data )
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	--percent
	self.weatherAlterProb = data.weatherAlterProb or 0
	
	--minutes
	self.weatherDurationMin = data.weatherDurationMin or 0	
	self.weatherDurationMax = data.weatherDurationMax or 0
	
	--weather datas
	self.weathers = MathUtility_Copy( data.weathers )
	
	self.weatherIds = MathUtility_Copy( data.weatherIds )
end

function ClimateTable:GetProb( currentWeather, nextWeather )
	if not currentWeather or not nextWeather then return nil end
	return self.weathers[currentWeather] and self.weathers[currentWeather][nextWeather]
end

function ClimateTable:GetWeatherId( currentWeather )
	return currentWeather and self.weatherIds[currentWeather]
end