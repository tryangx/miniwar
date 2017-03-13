PlotMap = class()

function PlotMap:__init()
	self.width  = 0
	self.height = 0
	self.mng = DataManager( "PLOT_DATA", Plot )
end

function PlotMap:GetDataManager()
	return self.mng
end

function PlotMap:GetNumOfPlot()
	return self.width * self.height
end

function PlotMap:ForeachPlot( fn )
	for y = 1, self.height do
		for x = 1, self.width do
			local plot = self:GetPlot( x, y )
			if plot then fn( plot ) end
		end
	end
end

function PlotMap:Dump()
	for y = 1, self.height do
		local content = ""
		for x = 1, self.width do
			local plot = self:GetPlot( x, y )
			if plot then 
				local plotTable = plot.table
				content = content .. " " .. Helper_AbbreviateString( plotTable.name, 6 ) .. " "
			else
				content = content .. "        "
			end
		end
		ShowText( "Y=".. y, content )
	end
end

function PlotMap:GetPlot( x, y )
	local id = Plot:GenId( x, y )
	return self.mng:GetData( id )
end

function PlotMap:Clear()
	self.width  = 0
	self.height = 0
	self.mng:Clear()
end
function PlotMap:MatchCondition( plot, condition )
	function CheckNearPlot( distance, fn )
		distance = distance or 1
		local matchCondition = false
		for k, offset in ipairs( PlotAdjacentOffsets ) do
			if offset.distance <= distance then
				local adjaPlot = self:GetPlot( plot.x + offset.x, plot.y + offset.y )
				if adjaPlot and fn( adjaPlot ) then matchCondition = true break end
			end
		end
		if not matchCondition then return false end
		return true
	end
	function CheckAwayFromPlot( distance, fn )
		distance = distance or 1
		local matchCondition = true
		for k, offset in ipairs( PlotAdjacentOffsets ) do
			if offset.distance <= distance then
				local adjaPlot = self:GetPlot( plot.x + offset.x, plot.y + offset.y )
				if adjaPlot and fn( adjaPlot ) then matchCondition = false break end
			end
		end
		if not matchCondition then return false end
		return true
	end
	if condition.type == ResourceGenerateCondition.CONDITION_BRANCH then
		for k, subCond in ipairs( condition.value ) do
			if not self:MatchCondition( plot, subCond ) then return false end
		end
	elseif condition.type == ResourceGenerateCondition.PROBABILITY then
		if g_synRandomizer:GetInt( 1, 10000 ) > condition.value then return false end
	elseif condition.type == ResourceGenerateCondition.PLOT_TYPE then
		if condition.value == "LIVING" then				
			if plot.table:GetType() ~= PlotType.HILLS and plot.table:GetType() ~= PlotType.LAND then					
				return false
			end
		elseif plot.table:GetType() ~= PlotType[condition.value] then
			return false
		end
	elseif condition.type == ResourceGenerateCondition.PLOT_TERRAIN_TYPE then
		if plot.table:GetTerrain() ~= PlotTerrainType[condition.value] then return false end
	elseif condition.type == ResourceGenerateCondition.PLOT_FEATURE_TYPE then
		if plot.table:GetFeature() ~= PlotFeatureType[condition.value] then return false end
	elseif condition.type == ResourceGenerateCondition.PLOT_TYPE_EXCEPT then
		if condition.value == "LIVING" then				
			if plot.table:GetType() == PlotType.HILLS or plot.table:GetType() == PlotType.LAND then
				return false
			end
		elseif plot.table:GetType() == PlotType[condition.value] then
			return false
		end
	elseif condition.type == ResourceGenerateCondition.PLOT_TERRAIN_TYPE_EXCEPT then
		if plot.table:GetTerrain() == PlotTerrainType[condition.value] then return false end
	elseif condition.type == ResourceGenerateCondition.PLOT_FEATURE_TYPE_EXCEPT then
		if condition.value == "ALL" then
			if plot.table:GetFeature() ~= PlotFeatureType.NONE then
				return false
			end
		elseif plot.table:GetFeature() == PlotFeatureType[condition.value] then
			return false
		end
	elseif condition.type == ResourceGenerateCondition.NEAR_PLOT_TYPE then
		CheckNearPlot( 1, function( adjaPlot )
			return adjaPlot.table:GetType() == PlotType[condition.value]
		end )
	elseif condition.type == ResourceGenerateCondition.NEAR_TERRAIN_TYPE then
		return CheckNearPlot( 1, function( adjaPlot )
			return adjaPlot.table:GetTerrain() == PlotTerrainType[condition.value]
		end )
	elseif condition.type == ResourceGenerateCondition.NEAR_FEATURE_TYPE then
		return CheckNearPlot( 1, function( adjaPlot )
			return adjaPlot.table:GetFeature() == PlotFeatureType[condition.value]
		end )
	elseif condition.type == ResourceGenerateCondition.AWAY_FROM_PLOT_TYPE then
		return CheckAwayFromPlot( 1, function( adjaPlot )
			return adjaPlot.table:GetType() == PlotType[condition.value]
		end )
	elseif condition.type == ResourceGenerateCondition.AWAY_FROM_TERRAIN_TYPE then
		return CheckAwayFromPlot( 1, function( adjaPlot )
			return adjaPlot.table:GetTerrain() == PlotTerrainType[condition.value]
		end )
	elseif condition.type == ResourceGenerateCondition.AWAY_FROM_FEATURE_TYPE then
		return CheckAwayFromPlot( 1, function( adjaPlot )
			return adjaPlot.table:GetFeature() == PlotFeatureType[condition.value]
		end )
	else
		ShowText( "not match" .. condition.type)
		return false
	end
	--InputUtility_Pause( "match", condition.type, condition.value, plot.table.name )
	return true
end	

function PlotMap:FindPlotSuitable( conditions )
	local plotList = {}
	self:ForeachPlot( function ( plot ) 					
		if plot:GetResource() then return end				
		local matchCondition = true
		if conditions and #conditions > 0 then
			--check conditions
			matchCondition = false
			for k, condition in pairs( conditions ) do
				if self:MatchCondition( plot, condition ) then matchCondition = true end
			end
		end
		if matchCondition then table.insert( plotList, plot ) end
	end )
	return plotList
end
function PlotMap:PutResource( items )
	local plotNunmber = self.width * self.height
	for k, item in pairs( items ) do
		local percent = item.percent or 0
		item.count = math.ceil( plotNunmber * percent * 0.01 )
		local resource = g_resourceTableMng:GetData( item.id )
		if resource then
			local plotList = self:FindPlotSuitable( resource.conditions )
			plotList = MathUtility_Shuffle( plotList, g_synRandomizer )
			for number = 1, #plotList do
				if number > item.count then break end
				local plot = plotList[number]					
				plot.resource = item.id
				--InputUtility_Pause( "put ", resource.name, "on", plot.x, plot.y )
			end
		end
	end
end

function PlotMap:RandomMap( width, height )
	self:Clear()
	
	----------------------------
	--Initialize
	self.width  = width
	self.height = height
	
	for y = 1, height do
		for x = 1, width do
			local plot = Plot()
			--ShowText( "init plot", x, y )
			plot:InitPlot( x, y, 4000 )
			self.mng:SetData( plot.id, plot )
		end
	end
		
	
	----------------------------
	--Plot Type and Terrain
	function SimpleRandomPlotType()
		local plotTypeMaps = 
		{
			{ id = 1000, desc = "landPlain", prob = 3000 },	
			{ id = 1100, desc = "landGrass", prob = 3000 },
			{ id = 1200, desc = "landDesert", prob = 800 },
			{ id = 1300, desc = "landTundra", prob = 400 },
			
			{ id = 2000, desc = "hillPlain", prob = 3500 },
			{ id = 2100, desc = "hillGrass", prob = 3500 },
			{ id = 2200, desc = "hillDesert", prob = 600 },
			{ id = 2300, desc = "hillTundra", prob = 300 },
			
			{ id = 3000, desc = "mountainPlain", prob = 1000 },
			
			{ id = 4000, desc = "lake", prob = 500 },
		}
		local totalProb = 0
		for k, mapItem in ipairs( plotTypeMaps ) do
			totalProb = totalProb + mapItem.prob
		end
		local rand = Random_SyncGetRange( 1, totalProb )
		for k, mapItem in ipairs( plotTypeMaps ) do
			if rand < mapItem.prob then return mapItem.id end
			rand = rand - mapItem.prob
		end
		return plotTypeMaps[1].id
	end
	
	function SetPlotType()
		self:ForeachPlot( function ( plot )
			plot:SetTable( SimpleRandomPlotType() )
		end )	
	end
		
	----------------------------
	--Initialize plot type
	SetPlotType()
	SetPlotType()	
	
	--Put strategic resource	
	local strategicResourceItems =
	{
		{ id=100, percent=8, },--copper
		{ id=101, percent=5, },--iron
		{ id=120, percent=5, },--horse
	}
	local bonusResourceItems =
	{
		{ id=200, percent=10, },--rice
		{ id=201, percent=8, },--wheat
		{ id=205, percent=3, },--salt
		{ id=206, percent=8, },--fertile
		{ id=207, percent=3, },--infertile
	}
	local luxuryResourceItems = 
	{
		{ id=300, percent=5, },--silver
		{ id=301, percent=2, },--gold
	}
	local artificialResourceItems = 
	{
		{ id=500, percent=20, }--settlement
	}
	
	self:PutResource( strategicResourceItems )
	self:PutResource( bonusResourceItems )
	self:PutResource( luxuryResourceItems )
	--self:PutResource( artificialResourceItems )
	
	--InputUtility_Pause( "finished put resource" )
	
	----------------------------
	--Initialize asset data
	self:ForeachPlot( function ( plot ) 		
		plot:ConvertID2Data()		
	end )	
end

function PlotMap:AllocateToCity()
	ShowText( "allocate plots to city" )
	--[[
	07 08 09
   18 01 02 10
  17 06 00 03 11
   16 05 04 12
	15 14 13
	]]
	local maxDistance = 3
	
	--1st, allocate plots to city
	g_cityDataMng:Foreach( function ( city )
		local plots = {}
		local pos = city:GetCoordinate()
		function AddPlot( list, x, y, settlement )
			local plot = self:GetPlot( x, y )
			if plot then
				if not plot:HasResource() then
					plot.resource = 500
				end
				if ( not plot:GetData() or settlement == maxDistance ) then
					table.insert( list, plot )
					plot:SetData( { city = city, settlement = settlement } )
					return 1
				end
			end
			return 0
		end
		AddPlot( plots, pos.x, pos.y, maxDistance )
		
		--allocate adjacent plot to the city
		local left = city.level	- 1		
		--ShowText( city.name, x, y, left, #PlotAdjacentOffsets )
		for k, offset in ipairs( PlotAdjacentOffsets ) do		
			if left > 0 and offset.distance < maxDistance then
				left = left - AddPlot( plots, pos.x + offset.x, pos.y + offset.y, maxDistance - offset.distance )
			else
				break
			end
		end
		city:SetPlots( plots )
	end )

	--2nd, init plot assets, gather people
	self:ForeachPlot( function ( plot )
		plot:InitPlotAssets( plot:GetData() )
	end )
	
	--3rd, update city plots
	g_cityDataMng:Foreach( function ( city )
		city:UpdatePlots()
	end )
end

function PlotMap:Update( elapsedTime )
	self:ForeachPlot( function ( plot )
		plot:Update( elapsedTime )
	end )
end