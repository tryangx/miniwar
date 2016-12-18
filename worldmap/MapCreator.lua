require 'Map'
require 'MapCreatorParam'
require 'randomizer'


MapCreator = class()

local _flags = {}

---------------------------------------------------------

local function IsValidForSea( map, flags, area )
	--print( 'valid' .. area:GetX() .. ',' .. area:GetY() .. ',' .. area:GetTerrain() )
	if area == nil or flags[map:GetAreaIndex( area )] ~= nil then return false end	
	if area:GetTerrain() ~= MapAreaTerrain.INVALID then return false end		
	return true
end

local function FuncSortArea( area1, area2 )	
	return _flags[area1:GetIndex()] > _flags[area2:GetIndex()]
end
---------------------------------------------------------

function MapCreator:__init()
	self.randomizer = Randomizer()
	
	self.markflags = {}
	
	self.adjacentPositions = { { x = 0, y = 1 }, { x = 1, y = 0 }, { x = 0, y = -1 }, { x = -1, y = 0 } }
end

function MapCreator:GetMap()
	return self.map
end

function MapCreator:GetCreatorParam()
	return self.creatorParam
end

function MapCreator:GetRandomizer()
	return self.randomizer
end

function MapCreator:GetGridNumber()
	return self.GridNumber
end

function MapCreator:Init( map, creatorParam )
	creatorParam:SetSeed( os.time() )
	--mapParam:SetSeed( 1 )
	self.map          = map
	self.creatorParam = creatorParam

	if creatorParam.seed ~= nil then
		self.randomizer:SetSeed( creatorParam.seed )
		print( 'seed=' .. creatorParam.seed )
	end	
	
	map.GridWidth = creatorParam.GridWidth
	map.GridHeight = creatorParam.GridHeight
	self.GridNumber = map.GridWidth * map.GridHeight	
	
	self:InitMapAreas()
end

function MapCreator:InitMapAreas()
	self.map.areas = {}	
	for y = 1, self.creatorParam.GridHeight do
		for x = 1, self.creatorParam.GridWidth do				
			area = MapArea()
			area:SetGrid( x, y )
			--print( map:GetAreaIndex( x, y) .. ' ' .. area:GetX() .. ',' .. area:GetY() )
			self.map:SetArea( x, y, area )
		end
	end
end

function MapCreator:GetRandomArea()
	local x = self.randomizer:GetInt( 1, self.creatorParam.GridWidth )
	local y = self.randomizer:GetInt( 1, self.creatorParam.GridHeight )
	return map:GetArea( x, y )
end

function MapCreator:GetRandomSideArea()
	local xMin = 1
	local yMin = 1
	local xMax = self.creatorParam.GridWidth
	local yMax = self.creatorParam.GridHeight
	
	local side = self.randomizer:GetInt( 1, 4 )
	if side == 1 then
		--north
		yMax = 1
	elseif side == 2 then
		--east
		xMin = self.creatorParam.GridWidth
	elseif side == 3 then
		--south
		yMin = self.creatorParam.GridHeight
	elseif side == 4 then
		--west
		xMax = 1
	end
	local x = self.randomizer:GetInt( xMin, xMax )
	local y = self.randomizer:GetInt( yMin, yMax )
	print( 'random side' .. x .. ',' .. y )
	return self.map:GetArea( x, y )
end

function MapCreator:ForAdjacentArea( area, fn )
	for i = 1, #self.adjacentPositions do
		local position = self.adjacentPositions[i]
		local adjacent = self.map:GetAdjacentArea( area:GetX(), area:GetY(), position.x, position.y )				
		if adjacent then fn( self, adjacent ) end
	end	
end

function MapCreator:IsAreaMarked( area )
	return area ~= nil and self.markflags[area:GetIndex()] == 1
end
function MapCreator:SetAreaMarked( area )		
	if area then self.markflags[area:GetIndex()] = 1 end
end

function MapCreator:IsAreaValid( area )	
	if not area or self.markflags[area:GetIndex()] == 1 or area:GetTerrain() ~= MapAreaTerrain.INVALID then return false end	
	return true
end

function MapCreator:ClearAreaMark()
	self.markflags = {}
end

---------------------------------------------------------
--Extends
--[[
function MapCreator:StartCreation()
	--clear variables
		
	--initialize areas
	self:InitMapAreas()
	
	--generate land
	self:GenerateSea()
	
	--generate mountain
	self:GenerateMountain()	
end

function MapCreator:AddToList( list, area )
	--print( name .. ' ' .. area:GetX() .. ',' .. area:GetY() )
	_flags[self.map:GetAreaIndex( area )] = self.randomizer:GetInt( 1, self.creatorParam.GridWidth * self.creatorParam.GridHeight )
	table.insert( list, area )
end

function MapCreator:AddAreaToList( area, list, func )
	local north = self.map:GetArea( area.xGrid, area.yGrid - 1 )	
	local south = self.map:GetArea( area.xGrid, area.yGrid + 1 )
	local east  = self.map:GetArea( area.xGrid + 1, area.yGrid )
	local west  = self.map:GetArea( area.xGrid - 1, area.yGrid )		
	if north ~= nil and func( self.map, _flags, north ) and list ~= nil then self:AddToList( list, north ) end
	if south ~= nil and func( self.map, _flags, south ) and list ~= nil then self:AddToList( list, south )end
	if east  ~= nil and func( self.map, _flags, east ) and list ~= nil then self:AddToList( list, east ) end
	if west  ~= nil and func( self.map, _flags, west ) and list ~= nil then self:AddToList( list, west ) end
end

function MapCreator:GenerateSea()		
	_flags = {}
	
	local totalSea = 0
	local areas = {}
	local seaNumber = self.creatorParam:GetTerrainLimit( MapAreaTerrain.SEA )
	
	--1. find side area
	local begArea = self:GetRandomSideArea()	
	if begArea == nil then return end
	
	--2. expand	
	self:AddToList( areas, area )		
	print( 'gen sea ' .. seaNumber )
	while seaNumber > 0 and #areas > 0 do
		area = table.remove( areas, 1 )
		area:SetTerrain( MapAreaTerrain.SEA )
		_flags[self.map:GetAreaIndex( area )] = 1
		--print( 'sea at' .. totalSea .. ' ' .. area:GetX() .. ',' .. area:GetY() ) --.. ' ' .. self.map:GetAreaIndex( area:GetX(), area:GetY() ) )
		self:AddAreaToList( area, areas, IsValidForSea )
		table.sort( areas, FuncSortArea )
		seaNumber = seaNumber - 1
		totalSea = totalSea + 1
	end
	
	self.seaAreas = Math_Copy( areas )
end
]]