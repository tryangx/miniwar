require 'MapCreator'
require 'MathUtility'

MapCreator_HeightMap = class( MapCreator )

-- For all adjacent area
function MapCreator_HeightMap:ForAdjacentArea( area, fn )
	for i = 1, #self[MapCreator].adjacentPositions do
		local position = self[MapCreator].adjacentPositions[i]
		local adjacent = self:GetMap():GetAdjacentArea( area:GetX(), area:GetY(), position.x, position.y )				
		if adjacent then fn( self, adjacent ) end
	end	
end

-- Random selet a adjacent area
function MapCreator_HeightMap:ForSingleAdjacentArea( area, fn )	
	local dir = self:GetRandomizer():GetInt( 1, #self[MapCreator].adjacentPositions )
	local position = self[MapCreator].adjacentPositions[dir]
	local adjacent = self:GetMap():GetAdjacentArea( area:GetX(), area:GetY(), position.x, position.y )				
	if adjacent then fn( self, adjacent ) end
end

function MapCreator_HeightMap:IsAreaValidForArchitecture( area )
	for i = 1, #self[MapCreator].adjacentPositions do
		local position = self[MapCreator].adjacentPositions[i]
		local adjacent = self:GetMap():GetAdjacentArea( area:GetX(), area:GetY(), position.x, position.y )				
		if not adjacent or adjacent:GetArchitecture() ~= 0 then return false end
	end
	return true
end

function MapCreator_HeightMap:IsAreaValidForRiver( area )
	local terrain = area:GetTerrain()
	if terrain == MapAreaTerrain.PLAIN 
	or terrain == MapAreaTerrain.GRASSLAND 
	or terrain == MapAreaTerrain.FOREST 
	or terrain == MapAreaTerrain.JUNGLE 
	or terrain == MapAreaTerrain.ICE then		
		return true
	end
	return false
end

local function MapCreator_HeightMap_CreateSea( creator, area )
	if not creator:IsAreaValid( area ) then return end
	table.insert( creator.oceans, area )
	creator:SetAreaMarked( area )
end

local function MapCreator_HeightMap_CreateMountain( creator, area )
	if not creator:IsAreaValid( area ) then return end
	table.insert( creator.mountains, area )
	creator:SetAreaMarked( area )
end

local function MapCreator_HeightMap_CreateHill( creator, area )
	if not creator:IsAreaValid( area ) then return end	
	table.insert( creator.hills, area )
	creator:SetAreaMarked( area )
end

local function MapCreator_HeightMap_CreateRiver( creator, area )	
	if creator:IsAreaMarked( area ) then return end	
	if not creator:IsAreaValidForRiver( area ) then return end		
	table.insert( creator.rivers, area )
	creator:SetAreaMarked( area )
end

function MapCreator_HeightMap:ConnectCity( sour, dest )	
	local area = nil
	local openAreas = { { distance = 0, area = sour } }
	local paths = {}
	local findPath = false
	self:SetAreaMarked( area )
	while #openAreas > 0 do
		local dat = table.remove( openAreas, 1 )
		area = dat.area
		table.insert( paths, { area = area } )
		if area == dest then findPath = true break end				
		for i = 1, #self[MapCreator].adjacentPositions do			
			local position = self[MapCreator].adjacentPositions[i]
			local adjacent = self:GetMap():GetAdjacentArea( area:GetX(), area:GetY(), position.x, position.y )
			if adjacent and not self:IsAreaMarked( adjacent ) then
				self:SetAreaMarked( adjacent )
				local distance = ( adjacent:GetX() - dest:GetX() ) * ( adjacent:GetX() - dest:GetX() ) + ( adjacent:GetY() - dest:GetY() ) * ( adjacent:GetY() - dest:GetY() )
				if #openAreas == 0 then
					--print( 'distance', distance )
					table.insert( openAreas, { distance = distance, area = adjacent } )
				elseif adjacent:GetRoad() ~= 0 then
					--print( 'road priority' )
					table.insert( openAreas, 1, { distance = distance, area = adjacent } )
				else
					for j = 1, #openAreas do
						if distance < openAreas[j].distance then
							table.insert( openAreas, j, { distance = distance, area = adjacent } )
							--print( 'distance less', adjacent:GetX(), adjacent:GetY() )
							break
						end
					end
				end
			end
		end
	end
	if findPath then
		for i = 1, #paths do
			local area = paths[i].area
			area:SetRoad( 1 )
			--print( 'path', area:GetX(), area:GetY() )
		end
		--print( 'length', #paths )
		return true
	end
	return false
end

function MapCreator_HeightMap:CreateByAltitude( area )
	local altitude = self.heightMap[area:GetIndex()]
	if altitude >= self:GetCreatorParam().MountainMinAltitude then
		table.insert( self.mountains, area )
	elseif altitude <= self:GetCreatorParam().SeaLevelMaxAltitude then
		table.insert( self.oceans, area )
	end	
end

function MapCreator_HeightMap:CreateByRainfall( area )
	local rainfall = self.rainfallMap[area:GetIndex()]
	if rainfall <= self:GetCreatorParam().DesertMinRainfall then
		area:SetTerrain( MapAreaTerrain.DESERT )
		self:SetAreaMarked( area )
	elseif rainfall <= self:GetCreatorParam().GrasslandMinRainfall then
		area:SetTerrain( MapAreaTerrain.GRASSLAND )
		self:SetAreaMarked( area )
	elseif rainfall >= self:GetCreatorParam().ForestMinRainfall then
		if area:GetTerrain() == MapAreaTerrain.HILL then
			area:SetTerrain( MapAreaTerrain.MOUNTAIN_FOREST )
			self:SetAreaMarked( area )
		elseif area:GetTerrain() == MapAreaTerrain.INVALID then
			area:SetTerrain( MapAreaTerrain.FOREST )
			self:SetAreaMarked( area )
		end
	end	
end

function MapCreator_HeightMap:CreateByTemperature( area )
	local temperature = self.temperatureMap[area:GetIndex()]
	local terrain = area:GetTerrain()
	if temperature <= self:GetCreatorParam().FrozenMaxTemperature then
		area:SetTerrain( MapAreaTerrain.FROZEN_GROUND )
		self:SetAreaMarked( area )
	elseif temperature <= self:GetCreatorParam().IceMaxTemperature then
		area:SetTerrain( MapAreaTerrain.ICE )
		self:SetAreaMarked( area )
	elseif terrain == MapAreaTerrain.DESERT then
		if temperature <= self:GetCreatorParam().DesertMinTemperature then
			area:SetTerrain( MapAreaTerrain.GRASSLAND )
			self:SetAreaMarked( area )
		elseif temperature <= self:GetCreatorParam().OasisMaxTemperature then
			area:SetTerrain( MapAreaTerrain.OASIS )
			self:SetAreaMarked( area )
		end
	elseif terrain == MapAreaTerrain.FOREST then
		if temperature >= self:GetCreatorParam().JungleMinTemperature then
			area:SetTerrain( MapAreaTerrain.JUNGLE )
			self:SetAreaMarked( area )
		end
	end
end

function MapCreator_HeightMap:StartCreation()	
	print( 'start creation ( height map )' )
	
	self.mountains = {}	
	self.hills     = {}
	self.oceans    = {}	
	self.plains    = {}
	
	local GridNumber = self:GetGridNumber()

	-- Create HeightMap
	self.heightMap = {}
	for i = 1, self:GetGridNumber() do
		self.heightMap[i] = i * 100 / GridNumber
	end	
	-- Randomize altitude
	Math_Shuffle( self.heightMap )	
	-- Set terrain with ocean and mountain range
	for k, area in ipairs( self:GetMap().areas ) do
		self:CreateByAltitude( area )
	end
	
	-- fill mountain
	local mountainNumber = self:GetCreatorParam():GetTerrainLimit( MapAreaTerrain.MOUNTAIN )	
	local lenth = #self.mountains
	while #self.mountains > 0 and mountainNumber > 0 do
		local mountain = table.remove( self.mountains, self:GetRandomizer():GetInt( 1, #self.mountains ) )
		mountain:SetTerrain( MapAreaTerrain.MOUNTAIN )
		self:SetAreaMarked( mountain )
		mountainNumber = mountainNumber - 1;
		table.insert( self.hills, mountain )
		--print( 'setmountain', mountain:GetX(), mountain:GetY(), mountainNumber )
		self:ForAdjacentArea( mountain, MapCreator_HeightMap_CreateMountain )
	end
		
	-- fill sea	
	local seaNumber = self:GetCreatorParam():GetTerrainLimit( MapAreaTerrain.SEA )	
	while #self.oceans > 0 and seaNumber > 0 do
		local sea = table.remove( self.oceans, self:GetRandomizer():GetInt( 1, #self.oceans ) )
		sea:SetTerrain( MapAreaTerrain.SEA )
		self:SetAreaMarked( sea )
		seaNumber = seaNumber - 1
		self:ForAdjacentArea( sea, MapCreator_HeightMap_CreateSea )
	end	
	
	-- fill hill
	local hillNumber = self:GetCreatorParam():GetTerrainLimit( MapAreaTerrain.HILL )
	while #self.hills > 0 and hillNumber > 0 do
		local hill = table.remove( self.hills, self:GetRandomizer():GetInt( 1, #self.hills ) )
		if self:IsAreaValid( hill ) then
			hill:SetTerrain( MapAreaTerrain.HILL )
			self:SetAreaMarked( hill )
			hillNumber = hillNumber - 1
		end
		self:ForAdjacentArea( hill, MapCreator_HeightMap_CreateHill )
	end
	
	-- Create RainFall
	-- Simulate rainfall with belt
	-- Truely, it'll be effect by many facts, ex. distance from Ocean
	print( 'Create Rainfall' )
	self.rainfallMap = {}
	for y = 1, self:GetCreatorParam().GridHeight do		
		local width = self:GetCreatorParam().GridWidth		
		local rainfall = self:GetRandomizer():GetInt( -width, width )
		local str = ' '
		for x = 1, self:GetCreatorParam().GridWidth do
			if rainfall + x < 0 then
				self.rainfallMap[self:GetMap():GetGridIndex( x, y )] = 0
			elseif rainfall + x < width then
				self.rainfallMap[self:GetMap():GetGridIndex( x, y )] = ( rainfall + x ) * 100 / width
			else
				self.rainfallMap[self:GetMap():GetGridIndex( x, y )] = ( width * 2 - rainfall - x ) * 100 / width
			end
			str = str .. self.rainfallMap[self:GetMap():GetGridIndex( x, y )] .. ' '
		end
		--print( str )
	end
	
	-- Rainfall determines grassland, forest, desert
	for k, area in ipairs( self:GetMap().areas ) do
		self:CreateByRainfall( area )
	end	
	
	-- Create temperature
	-- Simulate the latitude's effect	
	self.temperatureMap = {}
	print( 'Create Temperature' )
	local northTemperature = self:GetCreatorParam().temperatureEquator - self:GetCreatorParam().temperatureNorthPole
	local southTemperature = self:GetCreatorParam().temperatureEquator - self:GetCreatorParam().temperatureSouthPole
	local halfGridHeight = ( self:GetCreatorParam().GridHeight + 1 ) / 2
	for y = 1, self:GetCreatorParam().GridHeight do		
		local latitude = 0
		if y <= halfGridHeight then
			latitude = y / halfGridHeight
		else
			latitude = ( halfGridHeight + halfGridHeight - y ) / halfGridHeight
		end
		local temperatureRange = 0
		if latitude <= 1 then
			temperatureRange = northTemperature
		else
			temperatureRange = southTemperature;
		end
		local str = ' '		
		--print( 'latitude', y, latitude )
		for x = 1, self:GetCreatorParam().GridWidth do			
			local temperature = latitude * temperatureRange
			self.temperatureMap[self:GetMap():GetGridIndex( x, y )] = temperature + self:GetRandomizer():GetInt( -self:GetCreatorParam().temperatureRandomizeRange, self:GetCreatorParam().temperatureRandomizeRange )
			str = str .. math.floor( self.temperatureMap[self:GetMap():GetGridIndex( x, y )] ) .. ' '
		end
		--print( str )
	end	
		
	-- Temperature determines forest or jungle	
	for k, area in ipairs( self:GetMap().areas ) do
		self:CreateByTemperature( area )
	end	
	
	-- River comes from Mountain
	self:ClearAreaMark()
	
	self.rivers = {}
	Math_CopyTable( self.mountains, self.rivers )
	while #self.rivers > 0 do				
		local area = table.remove( self.rivers, self:GetRandomizer():GetInt( 1, #self.rivers ) )
		self:SetAreaMarked( area )		
		if self:IsAreaValidForRiver( area ) then
			area:SetRiver( 1 )
			self:ForSingleAdjacentArea( area, MapCreator_HeightMap_CreateRiver )
		end
	end
	
	-- Place plain
	for k, area in ipairs( self:GetMap().areas ) do
		if area:GetTerrain() == MapAreaTerrain.INVALID then
			area:SetTerrain( MapAreaTerrain.PLAIN )
			table.insert( self.plains, area )
		end
	end
	Math_Shuffle( self.plains )	
	
	-- Build Architecture
	self.architetures = {}
	
	-- Build City
	local cityLimits = self:GetCreatorParam().ArchitectureNumbers[MapAreaArchitecture.CITY]
	local cityNumber = self:GetRandomizer():GetInt( cityLimits.min, cityLimits.max )
	for i = 1, cityNumber do
		if #self.plains <= 0 then break end
		area = table.remove( self.plains, 1 )
		if self:IsAreaValidForArchitecture( area ) then
			area:SetArchitecture( MapAreaArchitecture.CITY )
			table.insert( self.architetures, area )
		end
	end
	
	-- Build Town
	local townLimits = self:GetCreatorParam().ArchitectureNumbers[MapAreaArchitecture.TOWN]
	local townNumber = self:GetRandomizer():GetInt( townLimits.min, townLimits.max )
	for i = 1, townNumber do
		if #self.plains <= 0 then break end
		area = table.remove( self.plains, 1 )
		if self:IsAreaValidForArchitecture( area ) then
			area:SetArchitecture( MapAreaArchitecture.TOWN )
			table.insert( self.architetures, area )
		end
	end	
	
	-- Build village
	local villageLimits = self:GetCreatorParam().ArchitectureNumbers[MapAreaArchitecture.TOWN]
	local villageNumber = self:GetRandomizer():GetInt( townLimits.min, townLimits.max )
	for i = 1, villageNumber do
		if #self.plains <= 0 then break end
		area = table.remove( self.plains, 1 )
		if self:IsAreaValidForArchitecture( area ) then
			area:SetArchitecture( MapAreaArchitecture.VILLAGE )
			table.insert( self.architetures, area )
		end
	end	
	
	-- Connect architecture	
	for k, area in ipairs( self.architetures ) do
		local roadNumber = 2--self:GetRandomizer():GetInt( 2, self:GetCreatorParam().ArchitectureRoadNumberLimit )
		local roads = {}
		for k2, target in ipairs( self.architetures ) do
			if target ~= area then
				local distance = ( target:GetX() - area:GetX() ) * ( target:GetX() - area:GetX() ) + ( target:GetY() - area:GetY() ) * ( target:GetY() - area:GetY() )  
				table.insert( roads, { distance = distance, area = target } )				
			end
		end
		table.sort( roads, function ( left, right )
			if left.distance < right.distance then return true end
			return false
		end )		
		local index = 1		
		while roadNumber > 0 and index < #roads do			
			--print( 'connect', area:GetArchitecture(), area:GetX(), area:GetY(), roads[index].area:GetArchitecture(),  roads[index].area:GetX(), roads[index].area:GetY() )
			self:ClearAreaMark()
			if self:ConnectCity( area, roads[index].area ) then				
				roadNumber = roadNumber - 1				
			end
			index = index + 1
		end
		break
	end
end