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
	--ShowText( "Allocate id", self.alloateId )
	return self.alloateId
end

function DataManager:GetCount()
	return self.count
end

function DataManager:Clear()
	--ShowText( "clear" )
	self.datas     = {}	
	self.count     = 0
	self.alloateId = 0
end

function DataManager:Dump()
	print( "Data Container=" .. self.name )
	for k, data in pairs( self.datas ) do
		print( "Data=" .. k, data.name )
	end
end

function DataManager:LoadFromData( datas )
	if not datas then Debug_Log( "Load from data failed, datas invalid" ) return end
	--clear old datas
	self:Clear()
	--load new datas
	for k, data in pairs( datas ) do		
		local newData = self.clz()
		if data.id == nil then
			--ShowText( "Key=" .. k )
			data.id = k
		end
		--MathUtility_Dump( data )
		newData:Load( data )
		--ShowText( "LoadDataFromTable", data.id, " in ", self.name )	
		self:SetData( newData.id, newData )
		if self.alloateId <= data.id then
			self.alloateId = data.id
		end
	end
	ShowText( "Load Data=", self.name, self.count, datas )
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
	--ShowText( self.name, self.clz )
	self:Clear()
	tableMng:Foreach( function ( data )
		local newData = self.clz()
		newData:Load( data )
		--ShowText( "LoadDataFromTable", data.id, " in ", self.name )
		self:SetData( newData.id, newData )
		if self.alloateId <= newData.id then 
			self.alloateId = newData.id
		end
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
	if not id or id == 0 then return nil end
	--ShowText( "GetData()", self.name, id, self.datas[id], #self.datas )
	if not self.datas then return nil end
	return self.datas[id]
end

function DataManager:GetDataByIndex( index )
	--if index < 0 or index > #self.datas then return nil end
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
	--ShowText( "setdata", self.name, id, self.datas[id], #self.datas )
end

function DataManager:RemoveData( id )
	if self.datas[id] then	
		--print( self.name, " remove data=", id )
		self.datas[id] = nil
		self.count = self.count - 1
	else
		print( self.name .. " cann't remove data from=" .. ", id="..id.." is invalid" )
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