Climate = class()

-- Need initialized
function Climate:SetDistrict( district )
	self.district = district
end

-- Need initialized
function Climate:SetClimate( id )
	self.g_climateId = id
	self.g_climateTable = g_climateTableMng:GetData( self.g_climateId )
end

function Climate:GetCurrentWeather()
	if not self.district then 
		return WeatherType.SUNNY
	end
	return self.district.weatherType or WeatherType.SUNNY
end

function Climate:SetCurrentWeather( weather )
	if self.district then 
		self.district.weatherType     = weather
		self.district.weatherTable    = self:QueryWeatherTable()				
		self.district.weatherDuration = Random_SyncGetRange( self.g_climateTable.weatherDurationMin, self.g_climateTable.weatherDurationMax, "Random Weather Duration" )	
	end
end

function Climate:QueryWeatherId()	
	if self.district then 
		if self.g_climateTable then
			return self.g_climateTable:GetWeatherId( self:GetCurrentWeather() )
		end
	end
	return nil
end

function Climate:QueryWeatherTable()
	return g_weatherTableMng:GetData( self:QueryWeatherId() )
end

function Climate:Update()
	local g_climateTable = g_climateTableMng:GetData( self.g_climateId )
	if not g_climateTable then Debug_Log( "Climate ID invalid" ) return end
	
	if self.district.weatherDuration > 0 then
		self.district.weatherDuration = self.district.weatherDuration - 1
		return
	end
	
	if Random_SyncGetRange( 1, 100, "Random Weather Alteration" ) > self.g_climateTable.weatherAlterProb then
		return
	end
	
	-- decide nextWeather
	local weatherType = self:GetCurrentWeather()
	local nextWeather = weatherType
	local value = Random_SyncGetRange( 1, RandomParams.MAX_PROBABILITY, "Weather Update" )
	local refer = 0
	for weather = WeatherType.BEGIN, WeatherType.END do
		local prob = g_climateTable:GetProb( weatherType, weather )
		if prob then
			--print( "value="..value.. " prob="..prob.. " w="..weather)
			if value < prob then
				nextWeather = weather
				break
			end
			value = value - prob
		end
	end
	
	-- set current weather type
	self:SetCurrentWeather( nextWeather )
end