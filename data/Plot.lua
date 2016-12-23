DEFAULT_MAXIMUM_PLOT_WIDTH = 100000

Plot = class()

function Plot:__init()
	self.x       = -1
	self.y       = -1
	self.id      = -1
	self.tableId = 0
	self.data    = nil
end

function Plot:GenId( x, y )
	return y * DEFAULT_MAXIMUM_PLOT_WIDTH + x
end

function Plot:Load( data )
	self.x       = data.x or -1
	self.y       = data.y or -1
	self.id      = self:GenId( self.x, self.y )
	self.tableId = data.tableId or 0
end

function Plot:Save()
	Data_OutputBegin( self.id )	
	Data_IncIndent( 1 )
	
	Data_OutputValue( "x", self )
	Data_OutputValue( "y", self )
	Data_OutputValue( "tableId", self )	
	
	Data_IncIndent( -1 )
	Data_OutputEnd()
end

function Plot:Init( x, y, tableId )
	self.x = x
	self.y = y
	self.tableId = tableId
	self.id = self:GenId( self.x, self.y )
end

function Plot:GetData( data )
	return self.data
end
function Plot:SetData( data )
	self.data = data
end

function Plot:ConvertID2Data()
	self.table = g_plotTableMng:GetData( self.tableId )
end