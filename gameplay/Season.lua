------------------------------------------------
--
-- Season
--
-- Season will affect time of dusk and dawn
--
------------------------------------------------

Season = class()

function Season:Init()
	self.g_seasons = {}
	g_seasonTableMng:Foreach( function ( g_season )
		self.g_seasons[g_season.type] = g_season
	end )
	
	self.g_seasonType  = SeasonType.SPRING
	self.g_seasonTable = nil
end

function Season:SetDate( month, day )
	for k, g_season in pairs( self.g_seasons ) do		
		if month >= g_season.startMon and day >= g_season.startDay and month <= g_season.endMon and month <= g_season.endDay then			
			self.g_seasonTable = g_season
			self.g_seasonType  = g_season.type
			Debug_Log( "Set Season:" .. g_season.name )
			break
		end
	end
end

--[[
function Season:SetSeason( g_seasonType )
	self.g_season = self.g_seasons[g_seasonType]
end
]]

-- Get current g_season configure data
function Season:GetSeasonTable()	
	return self.g_seasonTable
end

-- Time flow, enter new g_season
function Season:NextSeason()
	if not self.g_season then return end
	if g_season then self:SetSeason( self.g_season.nextType ) end
end
