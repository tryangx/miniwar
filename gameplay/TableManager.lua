--------------------------------
-- Table Manager
--------------------------------

TableManager = class()

function TableManager:__init( name, clz )
	self.name = name
		
	self.clz  = clz
	
	self.datas = {}
		
	self.count = 0
end

function TableManager:GetTableName()
	return self.name
end

function TableManager:Clear()
	self.datas     = {}	
	self.count     = 0
end

function TableManager:LoadTable( sources )
	self:Clear()
	if self.clz then
		if not sources then
			Debug_Error( "Sources is invalied" )
			return
		end
		if typeof( sources ) ~= "table" then
			Debug_Error( "Table="..sources.." is not table" )
			return
		end
		for k, data in pairs( sources ) do
			local newData = self.clz()
			if data.id == nil then
				--print( "Allocate id=" .. k )
				data.id = k
			end
			newData:Load( data )
			if not data.id then Debug_Error( "Data has no id" ) end
			--print( data.id, data.name )
			if not self.datas[data.id] then self.count = self.count + 1 end
			self.datas[data.id] = newData
		end
	else
		--swallow copy		
		self.datas = sources
	end		
	print( "Load Table=", self.name, self.count )
	--MathUtility_Dump( self.datas )
end

function TableManager:GetData( id )
	if not id or id == 0 then return nil end
	return self.datas and self.datas[id]
end

function TableManager:Foreach( fn, params )
	if not self.datas then return end
	for k, v in pairs( self.datas ) do
		fn( v, params )
	end
end