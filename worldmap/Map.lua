require 'unclasslib'
require 'MapArea'

Map = class()

function Map:__init()
	self.GridWidth  = 0
	self.GridHeight = 0
	self.areas = {}
end

function Map:ForEachArea( fn )
	for i, area in ipairs( self.areas ) do
		fn( area )
	end
end

function Map:GetGridIndex( x, y )
	return ( y - 1 ) * self.GridWidth + x
end

function Map:GetAreaIndex( area )
	return ( area:GetY() - 1 ) * self.GridWidth + area:GetX()
end

function Map:GetArea( x, y )
	if x < 1 or x > self.GridWidth then return nil end
	if y < 1 or y > self.GridHeight then return nil end
	local index = ( y - 1 ) * self.GridWidth + x
	--print( 'get area', x, y, self.areas[index] )
	return self.areas[index]
end

function Map:GetAdjacentArea( x, y, xOff, yOff )
	x = x + xOff
	y = y + yOff
	--print( 'get ', x, y )
	return self:GetArea( x, y )
end

function Map:SetArea( x, y, area )
	if x < 1 or x > self.GridWidth then return end
	if y < 1 or y > self.GridHeight then return end
	local index = ( y - 1 ) * self.GridWidth + x
	self.areas[index] = area
	area:SetIndex( index )
end

--[[
function Map:SetArea( index, area )
	self.areas[index] = area
	area:SetIndex( index )
end

function Map:AddArea( area )
	area:SetIndex( Map:GetAreaIndex( area ) )
	table.insert( self.areas, area )
end
]]

function Map:Dump()
	print( 'map:'..#self.areas..'\n' )	
	local str = ''
	for i, area in ipairs( self.areas ) do
		if 1 == 1 then
			if area.terrain == MapAreaTerrain.SEA then str = str .. '#'
			elseif area.terrain == MapAreaTerrain.OCEAN then str = str .. '#'
			elseif area.terrain == MapAreaTerrain.MOUNTAIN then str = str .. 'M'
			elseif area.terrain == MapAreaTerrain.HILL then str = str .. 'H'
			elseif area.terrain == MapAreaTerrain.MOUNTAIN_FOREST then str = str .. '^'
			elseif area.terrain == MapAreaTerrain.GRASSLAND then str = str .. 'G'
			elseif area.terrain == MapAreaTerrain.DESERT then str = str .. 'D'
			elseif area.terrain == MapAreaTerrain.JUNGLE then str = str .. 'J'
			elseif area.terrain == MapAreaTerrain.ICE then str = str .. 'I'
			elseif area.terrain == MapAreaTerrain.FROZEN_GROUND then str = str .. 'Z'
			elseif area.terrain == MapAreaTerrain.OASIS then str = str .. 'O'			
			elseif area.terrain == MapAreaTerrain.FLOOD_PLAIN then str = str .. 'L'
			else str = str .. ' ' 
			end
		else
			str = str .. ' '
		end
		
		if area:GetRiver() ~= 0 then
			if area:GetRoad() ~= 0 then
				str = str .. '+'
			else
				str = str .. '~'
			end			
		elseif area:GetArchitecture() == MapAreaArchitecture.VILLAGE then
			str = str .. 'v'		
		elseif area:GetArchitecture() == MapAreaArchitecture.TOWN then
			str = str .. 't'
		elseif area:GetArchitecture() == MapAreaArchitecture.CITY then
			str = str .. 'c'
		elseif area:GetRoad() ~= 0 then
			str = str .. '.'
		else
			str = str .. ' '
		end
				
		if i % self.GridWidth == 0 then
			print( str )
			str = ''
		end
	end
end