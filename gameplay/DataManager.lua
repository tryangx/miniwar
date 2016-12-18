DataManager = class()

function DataManager:__init( name, clz )
	self.name = name
	
	self.clz  = clz

	self.datas = {}
	
	self.count = 0
	
	self.alloateId = 0
end

function DataManager:AllocateId()
	self.alloateId = self.alloateId + 1
	--print( "Allocate id", self.alloateId )
	return self.alloateId
end

function DataManager:GetCount()
	return self.count
end

function DataManager:Clear()
	--print( "clear" )
	self.datas     = {}	
	self.count     = 0
	self.alloateId = 0
end

function DataManager:LoadFromData( datas )
	if not datas then Debug_Log( "Load from data failed, datas invalid" ) return end
	--clear old datas
	self:Clear()
	--load new datas
	for k, data in pairs( datas ) do		
		local newData = self.clz()
		if data.id == nil then
			--print( "Key=" .. k )
			data.id = k
		end
		--MathUtility_Dump( data )
		newData:Load( data )
		--print( "LoadDataFromTable", data.id, " in ", self.name )	
		self:SetData( newData.id, newData )
		if self.alloateId <= data.id then
			self.alloateId = data.id
		end
	end
	print( "Load Data=", self.name, self.count, datas )
end

function DataManager:LoadFromFile( fileName )
	local loadFile = LoadFileUtility()
	loadFile:OpenFile( fileName )
	local datas = {}
	loadFile:ParseTable( datas )	
	self:LoadFromData( datas )
	loadFile:CloseFile()
end

function DataManager:LoadFromTable( tableMng )
	--print( self.name, self.clz )
	self:Clear()
	tableMng:Foreach( function ( data )
		local newData = self.clz()
		newData:Load( data )
		--print( "LoadDataFromTable", data.id, " in ", self.name )
		self:SetData( newData.id, newData )
	end )
end

function DataManager:GenerateData( id, tableMng )
	local data = tableMng:GetData( id )
	if not data then Debug_Error( "Data ["..id.. "] from [".. TableMng:GetTableName() .. "] is invalid" ) end
	local newId = self:AllocateId()
	local newData = self.clz()	
	newData:Generate( data )
	newData.id = newId
	self:SetData( newId, newData )	
	return newData
end

function DataManager:NewData()
	local newId = self:AllocateId()
	local newData = self.clz()
	newData.id = newId
	self:SetData( newId, newData )
	return newData
end

function DataManager:GetData( id )
	--print( "GetData()", self.name, id, self.datas[id], #self.datas )
	if not self.datas then return nil end
	return self.datas[id]
end

function DataManager:GetDataByIndex( index )
	for k, data in pairs( self.datas ) do
		if k == index then return data end
	end
	return nil
end

function DataManager:SetData( id, data )
	if not self.datas then self.datas = {} end
	if not self.datas[id] then
		self.count = self.count + 1
	end	
	self.datas[id] = data
	--print( "setdata", self.name, id, self.datas[id], #self.datas )
end

function DataManager:RemoveData( id )
	if self.datas[id] then	
		self.datas[id] = nil
		self.count = self.count - 1
	else
		print( "Cann't remove data,  id is invalid" )
	end
end

function DataManager:Foreach( fn )
	for k, data in pairs( self.datas ) do
		fn( data )
	end
end

function DataManager:RemoveDataByCondition( fn )
	for k, data in pairs( self.datas ) do
		if fn( data ) then
			self.datas[k] = nil
			self.count = self.count - 1
		end
	end
end