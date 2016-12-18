------------------------------------------
--
-- Save File Utility
--
------------------------------------------

LoadFileUtility = class()


function LoadFileUtility:__init()
	self.fileName    = nil
	self.fileHandler = nil
end

function LoadFileUtility:GetFileName()
	return self.fileName
end

function LoadFileUtility:IsOpen()
	return self.fileHandler
end

function LoadFileUtility:CloseFile()
	if self.fileHandler then
		print( "Close file="..self.fileName )
		self.fileHandler:close();		
	end
	self.fileHandler = nil
end

function LoadFileUtility:OpenFile( fileName )
	if self:IsOpen() then
		self:CloseFile()
	end
	self.fileName    = fileName
	self.fileHandler = io.open( fileName, "r" )
	if self.fileHandler then
		print( "Open file="..self.fileName )
	end
end

function LoadFileUtility:ReopenFile( fileName )
	self:OpenFile( self.fileName )
end

--[[
--Standard Format
{
	t1={
		str = "test"
		number= 100
		float =1.2
		nested={
			C = "A"
			B = "c"
		}
	}
	t2=
	{
	}
}
--]]

local TablePattern = 
{
	COMMENT       = "[-][-]",
	CHARACTER     = "%w+",

	TABLE_START   = "{+",
	TABLE_END     = "%s*}",
	TABLE_HEADER  = "%s*%w+%s*=+%s*$",
	TABLE_NAME    = "%w+",
	
	KEY_NAME       = "[%w-_]+",--"%w+",
	NUMBERKEY_NAME = "\[%d+\]",
	
	ASSIGNMENT    = "%s*=%s*",
	
	STRING_VALUE  = "[\"][%w%W]*[\"]",
	NUMBER_VALUE  = "%d+",
	FLOAT_VALUE   = "%d*.%d+"
}

local function ParserDebug( ... )
	if nil then 
		args = { ... }
		local content = ""
		for i = 1, #args do
			content = content .. " " .. args[i]
		end
		print( content )
	end
end

----------------------------
-- Parser

local _lastKeyName = nil

local function ParseNextLine( file, tableData )
	local pos1, pos2
	
	local line = file:read( "*line" )
	
	if not line then
		ParserDebug( "EOF" )
		return false
	end
	
	ParserDebug( "\nRead line:" .. line )
		
	--Key name
	pos1, pos2 = string.find( line, TablePattern.KEY_NAME )
	if not pos1 then
		pos1, pos2 = string.find( line, TablePattern.KEY_NAME )
	end	
	local keyName
	local lastKeyName = _lastKeyName
	if pos1 then
		keyName = string.sub( line, pos1, pos2 )				
		local num = tonumber( keyName )
		if num then			
			keyName = num
			--ParserDebug( "tonumber=" .. keyName, typeof(keyName) )
		else
			--ParserDebug( "keyName=" .. keyName )
		end
		_lastKeyName = keyName
	end
	
	--Table Begin
	pos1, pos2 = string.find( line, TablePattern.TABLE_START )
	if pos1 then		
		ParserDebug( "Table Begin" )
		pos1, pos2 = string.find( line, TablePattern.TABLE_END, pos2 )
		if not keyName then 
			keyName = lastKeyName
			ParserDebug( "likes {", lastKeyName )
		elseif pos1 then
			ParserDebug( "likes A = {}" )
		else
			ParserDebug( "likes A = {" )
		end			
		if keyName then
			local subTable = {}			
			tableData[keyName] = subTable
			ParserDebug( "Subtable", keyName )
			if not pos1 then
				ParseNextLine( file, subTable )
			end
		end
		return ParseNextLine( file, tableData )
	else
		pos1, pos2 = string.find( line, TablePattern.TABLE_HEADER )
		if pos1 then
			-- Style likes "A = "			
			if keyName then
				ParserDebug( "likes A = ")
				local subTable = {}
				tableData[keyName] = subTable
				ParseNextLine( file, subTable )
			end
			return ParseNextLine( file, tableData )
		end
	end
		
	--Table End
	pos1, pos2 = string.find( line, TablePattern.TABLE_END )
	if pos1 then
		--table end
		ParserDebug( "Table End" )
		return true
	end
	
	--Comment
	pos1, pos2 = string.find( line, TablePattern.COMMENT )	
	if pos1 then
		ParserDebug( "Find comment", string.sub( line, pos1, pos2 ) )
		return ParseNextLine( file, tableData )
	end	
	
	--EMPTY
	pos1, pos2 = string.find( line, TablePattern.CHARACTER )	
	if not pos1 then
		ParserDebug( "Find Empty" )
		return ParseNextLine( file, tableData )
	end	
	
	--Key
	pos1, pos2 = string.find( line, TablePattern.KEY_NAME )
	assert( pos1, "Invalid key" .. line )
	local key = string.sub( line, pos1, pos2 )
	
	--Assignment
	pos1, pos2 = string.find( line, TablePattern.ASSIGNMENT, pos2 + 1 )
	assert( pos1, "Invalid assignment" )
	
	local valuePos = pos2 + 1
	
	--Value
	pos1, pos2 = string.find( line, TablePattern.FLOAT_VALUE, valuePos )
	if pos1 then
		local value = string.sub( line, pos1, pos2 )
		tableData[keyName] = tonumber( value )
		ParserDebug( "Find ", key, tableData[keyName] )
		return ParseNextLine( file, tableData )
	end
	pos1, pos2 = string.find( line, TablePattern.NUMBER_VALUE, valuePos )
	if pos1 then
		local value = string.sub( line, pos1, pos2 )
		tableData[keyName] = tonumber( value )
		ParserDebug( "Find ", key, tableData[keyName] )
		return ParseNextLine( file, tableData )
	end
	pos1, pos2 = string.find( line, TablePattern.STRING_VALUE, valuePos )
	if pos1 then
		local value = string.sub( line, pos1 + 1, pos2 - 1 )
		tableData[keyName] = value
		ParserDebug( "Find ", key, tableData[keyName] )
		return ParseNextLine( file, tableData )
	end
	return true
end

function LoadFileUtility:ParseTable( tableData ) 
	if not self.fileHandler then error( "File handler invalid" ) end
	
	if not tableData then tableData = {} end
	while ParseNextLine( self.fileHandler, tableData ) do end	
	return tableData
end

------------------------------------------
--
-- Save File Utility
--
------------------------------------------

SaveFileUtility = class()


function SaveFileUtility:__init()
	self.fileName    = nil
	self.fileHandler = nil
end

function SaveFileUtility:GetFileName()
	return self.fileName
end

function SaveFileUtility:IsOpen()
	return self.fileHandler
end

function SaveFileUtility:Clear()	
	self.fileName    = nil
end

function SaveFileUtility:CloseFile()
	if self.fileHandler then
		self.fileHandler:close();
		print( "Close file="..self.fileName )
	end	
	self.fileHandler = nil
end

function SaveFileUtility:SetMode( append )
	self.isAppend = append
end

function SaveFileUtility:OpenFile( fileName )
	if self:IsOpen() then
		self:CloseFile()
	end
	self.fileName    = fileName
	if self.isAppend == true then
		self.fileHandler = io.open( fileName, "a+" )
	else
		self.fileHandler = io.open( fileName, "w+" )		
	end
	if self.fileHandler then
		print( "Open file="..self.fileName )
	end
end

function SaveFileUtility:ReopenFile()
	self:OpenFile( self.fileName )
end

function SaveFileUtility:WriteTable( obj, filter )
	if not self.fileHandler then error( "File handler invalid" ) end
	if not obj then error( "Data is corrupted" ) end
	
	local objType = type( obj )
	--ParserDebug( objType, obj )
	if objType == "number" then
		self.fileHandler:write( obj )
	elseif objType == "string" then		
		self.fileHandler:write( string.format("%q", obj ) )
	elseif objType == "table" then
		self.fileHandler:write( "{\n" )
		for k, v in pairs( obj ) do
			if not filter or filter( k, v ) then
				--print( "k=", k, " v=", v )
				self.fileHandler:write( k )
				self.fileHandler:write( "=" )
				self:WriteTable( v )
				self.fileHandler:write( ",\n" )
			end
		end
		self.fileHandler:write( "}" )
	else
		error( "Invalid handler with " .. objType .. "," .. obj )
	end
end

function SaveFileUtility:WriteContent( v )
	self.fileHandler:write( v )
end