PlotMap = class()

function PlotMap:__init()
	self.width  = 0
	self.height = 0
	self.mng = DataManager( "PLOT_DATA", Plot )
end

function PlotMap:GetDataManager()
	return self.mng
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
				local plotTable = g_plotTableMng:GetData( plot.tableId )
				content = content .. " " .. Helper_Abbreviate( plotTable.name, 3 ) .. " "
			else
				content = content .. "     "
			end
		end
		print( "Y=".. y, content )
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

function PlotMap:RandomMap( width, height )
	self:Clear()
		
	self.width  = width
	self.height = height
	
	for y = 1, height do
		for x = 1, width do
			local plot = Plot()
			--print( "init plot", x, y )
			plot:Init( x, y, 4000 )
			plot:ConvertID2Data()
			self.mng:SetData( plot.id, plot )
		end
	end
	
	function SimpleRandomPlotType()
		local plotTypeMaps = 
		{
			{ id = 1000, desc = "landPlain", prob = 3000 },
			{ id = 1100, desc = "landGrass", prob = 4000 },
			{ id = 2000, desc = "hillPlain", prob = 5500 },
			{ id = 2100, desc = "hillGrass", prob = 6200 },
			{ id = 3000, desc = "mountainPlain", prob = 200 },
			{ id = 3100, desc = "mountainGrass", prob = 200 },
		}
	
		local rand = Random_LocalGetRange( 1, 10000 )
		for k, mapItem in ipairs( plotTypeMaps ) do
			if rand < mapItem.prob then return mapItem.id end
		end
		return plotTypeMaps[1].id
	end
	
	function SetPlotType()
		self:ForeachPlot( function ( plot ) 
			plot.tableId = SimpleRandomPlotType()
			plot:ConvertID2Data()
		end )	
	end
	
	SetPlotType()
	SetPlotType()
end

function PlotMap:AllocateToCity()
	InputUtility_Pause( "allocate plots to city" )
	g_cityDataMng:Foreach( function ( city )
		local plots = {}
		local pos = city:GetPosition()
		function AddPlot( list, x, y )
			local plot = self:GetPlot( x, y )
			if plot and  not plot:GetData() then
				table.insert( list, plot )
				--plot:SetData( city )
			end
		end
		AddPlot( plots, pos.x, pos.y )
		if city.size >= CitySize.CITY then
			AddPlot( plots, pos.x - 1, pos.y )
			AddPlot( plots, pos.x + 1, pos.y )
			AddPlot( plots, pos.x, pos.y - 1 )
			AddPlot( plots, pos.x, pos.y + 1 )
		end
		city:InitPlots( plots )
	end )
end