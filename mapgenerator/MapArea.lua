--[[
	
--]]

require 'unclasslib'
require 'MapDefine'

MapArea = class()

function MapArea:__init()
	self.xGrid = -1
	self.yGrid = -1
	
	self.terrain  = MapAreaTerrain.INVALID
	
	-- additional resource, like metal, horse, stone etc
	self.resource = 0
	
	-- river shape
	self.river    = 0
	
	-- road level
	self.road     = 0
	
	-- city, town, village, camp, fortress
	self.Architecture = 0	
end

function MapArea:SetGrid( x, y )
	self.xGrid = x
	self.yGrid = y
end

function MapArea:GetX()
	return self.xGrid
end
function MapArea:GetY()
	return self.yGrid
end


--[[
	Set storage index
]]
function MapArea:SetIndex( index )
	self.index = index
end
--[[
	Get storage index
]]
function MapArea:GetIndex()
	return self.index
end

function MapArea:SetTerrain( terrain )
	self.terrain = terrain
end
function MapArea:GetTerrain()
	return self.terrain
end

function MapArea:GetRiver()
	return self.river
end
function MapArea:SetRiver( river )
	self.river = river
end

function MapArea:SetArchitecture( architecture )
	self.Architecture = architecture
end
function MapArea:GetArchitecture()
	return self.Architecture
end

function MapArea:GetRoad()
	return self.road
end
function MapArea:SetRoad( road )
	self.road = road
end