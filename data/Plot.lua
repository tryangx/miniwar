DEFAULT_MAXIMUM_PLOT_WIDTH = 100000

PlotAssetType = 
{
	--Growth
	AGRICULTURE = 1,
	ECONOMY     = 2,
	PRODUCTION  = 3,
	POPULATION  = 4,
	
	--Condition
	SECURITY    = 10,
	TRAFFIC     = 11,
}

Plot = class()

function Plot:__init()
	self.x        = -1
	self.y        = -1
	self.id       = -1
	self.table    = 0
	self.resource = 0
	--city
	self.city     = nil
	--data assets
	self.assets   = {}
	--reserved
	self.data     = nil
end

function Plot:GenId( x, y )
	return y * DEFAULT_MAXIMUM_PLOT_WIDTH + x
end

function Plot:Load( data )
	self.x        = data.x or -1
	self.y        = data.y or -1
	self.id       = self:GenId( self.x, self.y )
	self.table    = data.table or 0
	self.resource = data.resource
	self.assets   = MathUtility_ConvertKeyToID( PlotAssetType, data.assets )
end

function Plot:Save()
	local reservedAssets = self.assets
	self.assets = MathUtility_ConvertKeyToString( PlotAssetType, self.assets )

	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	
	Data_OutputValue( "x", self )
	Data_OutputValue( "y", self )
	Data_OutputValue( "tableId", self, "id" )
	Data_OutputValue( "resource", self, "id" )
	--growth
	Data_OutputTable( "assets", self )
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
	
	self.assets = reservedAssets
end

function Plot:InitPlot( x, y, table )
	self.x = x
	self.y = y
	self.table = table
	self.id = self:GenId( self.x, self.y )
	self:ConvertID2Data()
end

function Plot:InitPlotAssets( params )
	local prob
	local settlement = params and params.settlement	or 0
	--growth
	self.maxAgriculture = self:GetBonusValue( PlotResourceBonusType.AGRICULTURE )
	self.maxEconomy     = self:GetBonusValue( PlotResourceBonusType.ECONOMY )
	self.maxProduction  = self:GetBonusValue( PlotResourceBonusType.PRODUCTION )
	self._livingSpace   = self:GetBonusValue( PlotResourceBonusType.LIVING_SPACE )
	prob = Random_SyncGetRange( 60, 80 )
	self:SetAsset( PlotAssetType.AGRICULTURE, math.floor( prob * self.maxAgriculture * 0.01 ) )
	prob = Random_SyncGetRange( 50, 80 )
	self:SetAsset( PlotAssetType.ECONOMY, math.floor( prob * self.maxEconomy * 0.01 ) )
	prob = Random_SyncGetRange( 50, 80 )
	self:SetAsset( PlotAssetType.PRODUCTION, math.floor( prob * self.maxProduction * 0.01 ) )
	
	--status evaluation
	prob = Random_SyncGetRange( 40, 80 )
	self:SetAsset( PlotAssetType.SECURITY, math.floor( prob * PlotParams.MAX_PLOT_SECURITY * 0.01 ) )
	
	--population
	local prob = Random_SyncGetRange( 30 + settlement * 35, 50 + settlement * 35 )
	local living = CalcPlotPopulation( self._livingSpace )
	local supply = CalcPlotSupply( self:GetAsset( PlotAssetType.AGRICULTURE ) )	
	local population = math.min( living, math.floor( prob * supply * 0.01 ) )
	self:SetAsset( PlotAssetType.POPULATION, population )
	
	--InputUtility_Pause( self.x, self.y, population, settlement, prob, living, supply, params and params.city.name or "" )
	--ShowText( "agr="..self:GetAsset( PlotAssetType.AGRICULTURE ), "popu=" .. self:GetAsset( PlotAssetType.POPULATION ), population )
end

--------------------------------

function Plot:GetData( data )
	return self.data
end
function Plot:SetData( data )
	self.data = data
end

function Plot:SetTable( id )
	self.table = g_plotTableMng:GetData( id )
end

function Plot:ConvertID2Data()
	self.resource = g_resourceTableMng:GetData( self.resource )
end

function Plot:GetResource()
	return self.resource
end

function Plot:GetAsset( plotAssetType )
	return self.assets[plotAssetType] or 0
end

function Plot:SetAsset( plotAssetType, value )
	self.assets[plotAssetType] = value
end

function Plot:GetBonusValue( bonusType )
	local value = 0
	--plot bonus
	local plotBonus = self.table and self.table:GetBonusValue( bonusType ) or 0	
	value = value + plotBonus
	--resource bonus
	local resBonus = self.resource and self.resource:GetBonusValue( bonusType ) or 0
	value = value + resBonus
	--InputUtility_Pause( self.table.name, MathUtility_FindEnumName( PlotResourceBonusType, bonusType ), plotBonus, resBonus )
	return value
end

function Plot:Own( city )
	self.city = city
end

function Plot:Update( elapsedTime )
	local rate = elapsedTime / GlobalConst.TIME_PER_YEAR
	local population = self:GetAsset( PlotAssetType.POPULATION )
	--population born
	local birth = math.ceil( population * ( PlotParams.PLOT_POPULATION_GROWTH_RATE * rate ) )
	--population die
	local dead = math.ceil( population * ( PlotParams.PLOT_POPULATION_DEATH_RATE * rate ) )
	population = population + birth + dead 
	self:SetAsset( PlotAssetType.POPULATION, population )
	--ShowText( "Plot("..self.x..","..self.y..") born="..birth..",die="..dead..",now="..population )
	g_statistic:CountPopulation( population )
	g_statistic:DieNatural( dead )
	g_statistic:BornNatural( birth )
end