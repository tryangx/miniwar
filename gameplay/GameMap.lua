GameMap = class()

function GameMap:__init()
	self.map  = nil
	self.xInc = 6
	self.cityNameLen = 4
	self.groupNameLen = 2
	self.blankLength = 6
	self.blank = string.rep( " ", self.blankLength )
end

function GameMap:DrawMapTable( fn )
	local content = string.rep( " ", 5 )
	for x = 1, g_plotMap.width, self.xInc do
		content = content .. ( "x=".. Helper_AbbreviateString( x, self.blankLength - 1 ) )
	end
	print( content )
	for y = 1, g_plotMap.height do
		local row = self.map[y]
		if row then
			local content = ""
			for x = 1, row.length do
				local ret = fn( x, y, row[x] )
				content = content .. ret
			end
			print( "Y=".. y, content )
		end
	end
	--[[
	for y = 1, g_plotMap.height, self.xInc do
		local content = ""
		for x = 1, g_plotMap.width, self.yInc do
			content = content .. fn( x, y )
		end
		print( "Y=".. y, content )
	end
	]]
end

function GameMap:UpdateMap()
	self.map = {}
	--[[
	for y = 1, g_plotMap.height do
		self.map[y] = {}
		for x = 1, g_plotMap.width do
			self.map[y][x] = nil
		end
	end
	]]
	g_cityDataMng:Foreach( function ( city )
		local pos = city.coordinate
		local y = pos.y
		local x = math.ceil( pos.x / self.xInc )
		if not self.map[y] then self.map[y] = {} end
		--if self.map[y][x] then print( "Duplicate", city.name, self.map[y][x].name, "in " .. pos.x .. ",", pos.y ) end
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
	self:DrawResourceMap( true )
	self:DrawCityMap( true )
	self:DrawGroupMap( true )	
end

function GameMap:DrawGroupMap( invalidate )
	if not invalidate then self:UpdateMap() end
	print( "Group Map" )
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
		--InputUtility_Pause( "<"..self.blank..">" )
		return self.blank
	end )
end

function GameMap:DrawCityMap()
	if not invalidate then self:UpdateMap() end
	print( "City Map" )		
	self:DrawMapTable( function( x, y, data )
		local city = data
		if city then return "<".. Helper_AbbreviateString( city.name, self.blankLength ) ..">" end
		return self.blank
	end )
end

function GameMap:DrawResourceMap()
	if not invalidate then self:UpdateMap() end
	print( "Resource Map" )
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