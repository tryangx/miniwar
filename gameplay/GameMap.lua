GameMap = class()

function GameMap:__init()
	self.map  = nil
	self.xInc = 8
	self.cityNameLen = 6
	self.groupNameLen = 3
	self.blankLength = 8
	self.blank = string.rep( " ", self.blankLength )
end

function GameMap:DrawMapTable( fn, data, printer )
	if not data then data = self.map end
	if not printer then printer = ShowText end
	local content = string.rep( " ", 5 )
	for x = 1, g_plotMap.width, self.xInc do
		content = content .. ( "x=".. Helper_AbbreviateString( x, self.blankLength - 1 ) )
	end
	printer( content )
	for y = 1, g_plotMap.height do
		local row = data[y]
		if row then
			local content = ""
			for x = 1, row.length do
				local ret = fn( x, y, row[x] )
				content = content .. ret
			end
			printer( "Y=".. y, content )
		end
	end
end

function GameMap:UpdateMap()
	self.map = {}
	g_cityDataMng:Foreach( function ( city )
		local pos = city.coordinate
		local y = pos.y
		local x = math.ceil( pos.x / self.xInc )
		if not self.map[y] then self.map[y] = {} end
		if self.map[y][x] then
			InputUtility_Pause( "Duplicate", city.name, self.map[y][x].name, "in " .. pos.x .. ",", pos.y )
		end
		self.map[y][x] = city
		if not self.map[y].length then
			self.map[y].length = x
		else
			self.map[y].length = math.max( self.map[y].length, x )
		end
	end )
end

function GameMap:DrawAll()
	self:UpdateMap()
	--self:DrawResourceMap( true )
	--self:DrawCityMap( true )
	--self:DrawGroupMap( true )
	--self:DrawCharaMap( true )
	self:DrawPowerMap( true )
end

function GameMap:DrawData( data, desc, printer )
	ShowText( desc )
	local tempMapData = {}
	for city, number in pairs( data ) do
		local pos = city.coordinate
		local y = pos.y
		local x = math.ceil( pos.x / self.xInc )
		if not tempMapData[y] then tempMapData[y] = {} end
		tempMapData[y][x] = city
		if not tempMapData[y].length then
			tempMapData[y].length = x
		else
			tempMapData[y].length = math.max( tempMapData[y].length, x )
		end
	end
	self:DrawMapTable( function( x, y, c )
		local city = c	
		if city then			
			local content = ""
			content = content .. data[city]
			return content
		end
		return self.blank
	end, tempMapData, printer )
end

function GameMap:DrawCharaMap( invalidate )
	if not invalidate then self:UpdateMap() end
	ShowText( "Chara Map" )
	self:DrawMapTable( function( x, y, data )
		local city = data	
		if city then			
			local content = ""
			content = content .. #city.charas .. "/"
			content = content .. g_statistic:CalcOutCharaNumber( city )
			return content
		end
		return self.blank
	end )
end

function GameMap:DrawPowerMap( invalidate )
	if not invalidate then self:UpdateMap() end
	ShowText( "Power Map" )
	self:DrawMapTable( function( x, y, data )
		local city = data	
		if city then			
			local content = ""
			if city:GetGroup() then
				local str = Helper_CreateNumberDesc( city:GetPower() )--GuessCityPower( city ) )
				content = content .. Helper_AbbreviateString( city:GetGroup().name, self.cityNameLen + 1 ) .. "=" .. Helper_AbbreviateString( str, 4 )
			else
				local str = Helper_CreateNumberDesc( city.guards )
				content = content .. Helper_AbbreviateString( city.name, self.groupNameLen + 1 ) .. " " .. Helper_AbbreviateString( str, 4 )
				--content = content .. Helper_AbbreviateString( string.lower( city.name ), self.cityNameLen + 4 )
			end
			return content
		end
		return self.blank
	end )
end

function GameMap:DrawGroupMap( invalidate )
	if not invalidate then self:UpdateMap() end
	ShowText( "Group Map" )
	self:DrawMapTable( function( x, y, data )
		local city = data	
		if city then
			local content = " ".. Helper_AbbreviateString( city.name, self.cityNameLen )
			if city:GetGroup() then
				content = content .. "@".. Helper_AbbreviateString( city:GetGroup().name, self.groupNameLen ) .. " "
			else
				content = content .. "   "
			end
			return content
		end
		return self.blank
	end )
end

function GameMap:DrawCityMap()
	if not invalidate then self:UpdateMap() end
	ShowText( "City Map" )		
	self:DrawMapTable( function( x, y, data )
		local city = data
		if city then return "<".. Helper_AbbreviateString( city.name, self.blankLength ) ..">" end
		return self.blank
	end )
end

function GameMap:DrawResourceMap()
	if not invalidate then self:UpdateMap() end
	ShowText( "Resource Map" )
	self:DrawMapTable( function ( x, y, data )
		local plot = g_plotMap:GetPlot( x, y )
		if plot.resource then
			return "<".. Helper_TrimString( plot.resource.name, self.blankLength ) ..">"
		end
		return self.blank
	end )
end

function GameMap:DrawMap()	
	InputUtility_Pause()
end