------------------------------------------------
--
-- Season
--
-- Season will affect time of dusk and dawn
--
------------------------------------------------

Season = class()

function Season:Init( calendar, tableMng )
	self.defaultSeason = 
	{
		name          = "spring",
		type          = "SPRING",
		dawnTime      = 6,
		duskTime      = 18,
		startMon      = 1,
		startDay      = 1,
		endMon        = 12,
		endDay        = 30,
	}

	self.seasons = {}
	tableMng:Foreach( function ( season )
		self.seasons[season.type] = season
	end )
	
	self.seasonTable = self.defaultSeason
	self.seasonType  = self.defaultSeason.type
	
	self.calendar = calendar
end

function Season:SetDate( month, day, monthInYear, dayInMonth )
	local curDateVal = self.calendar:ConvertDateValue( 1, month, day )
	for k, season in pairs( self.seasons ) do
		local dateVal1 = self.calendar:ConvertDateValue( 1, season.startMon, season.startDay )
		local dateVal2 = self.calendar:ConvertDateValue( 1, season.endMon, season.endDay )
		--ShowText( season.name, dateVal1, curDateVal, dateVal2 )
		local inSeason = true
		if season.startMon <= season.endMon then
			inSeason = curDateVal >= dateVal1 and curDateVal <= dateVal2
		else
			inSeason = not ( curDateVal < dateVal1 and curDateVal > dateVal2 )
		end		
		if inSeason then
			self.seasonTable = season
			self.seasonType  = season.type
			ShowText( "Set Season:" .. season.name .. " for date=" .. month .. "M" .. day .. "D" )
			return
		end
	end
	ShowText( "No match season for date=" .. month .. "M" .. day .. "D" )
end

function Season:SetSeason( seasonType )
	local nextSeason = self.seasons[seasonType]
	if nextSeason then self.season = nextSeason end
end

-- Get current season configure data
function Season:GetSeasonTable()	
	return self.seasonTable
end

-- Time flow, enter new season
function Season:NextSeason()
	if not self.season then return end
	if season then self:SetSeason( self.season.nextType ) end
end
