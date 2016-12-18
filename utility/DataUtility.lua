-------------------------------
-- Try to support redirect
--
-- 1. Write to file directly
-- 2. Write to buffer
--
-------------------------------

Data_OutputMode =
{
	ORIGINAL_TEXT

	--BINARY_FILE,
}

local _fileMode    = Data_OutputMode.ORIGINAL_TEXT


---------------------------------------------

local _indent      = 0
local _fileHandler = nil

local function Data_OutputOriginalText( text, indent )
	if not indent then
		indent = _indent
	else
		indent = indent + _indent
	end
	--print( text )
	_fileHandler:WriteContent( string.rep("	", indent) .. text )
end

local function Data_OutputItem2File( itemName, value, indent )
	local itemvalue
	if typeof(value) == "string" then
		itemvalue = "\"" .. value .. "\""
	else
		itemvalue = value
	end
	--print( itemName, typeof(itemName) )
	if typeof(itemName) == "number" then		
		Data_OutputOriginalText( "[" .. itemName .. "]=" .. itemvalue .. ",\n", indent )
	else
		Data_OutputOriginalText( itemName .. "=" .. itemvalue .. ",\n", indent )
	end
end

local function Data_OutputBegin2File( itemName )
	--print( "Output Begin = ", itemName )
	if itemName then
		Data_OutputOriginalText( itemName .. "={\n" )
	else
		Data_OutputOriginalText( "={\n" )
	end
end

local function Data_OutputEnd2File()
	Data_OutputOriginalText( "},\n" )
end

local function Data_OutputFlush2File()
	if _fileHandler then
		_fileHandler:CloseFile()
	end
end

local function Data_OutputValue2File( itemName, data, subName, default )
	if not _fileHandler then print( "File not opened") return end
	if not data then
		print( "Output Data invalid.", itemName, ",", data, ",", subName )
		Data_OutputItem2File( itemName, 0 )
		return
	end
	if not itemName then
		print( "Output ItemName invalid", itemName, ",", data, ",", subName )
		Data_OutputItem2File( itemName, 0 )
		return
	end
	
	if typeof(data) == "number" then
		print( "Output Data is number", itemName, ",", data, ",", subName )
		Data_OutputItem2File( itemName, data )
		return
	end
	
	if typeof(data) == "string" then
		print( "Output Data is string", itemName, ",", data, ",", subName )
		Data_OutputItem2File( itemName, data )
		return
	end
	
	local value = data[itemName]
	if not value then
		if default then
			Data_OutputItem2File( itemName, default )
		else
			print( "Output Item invalid", itemName, ",", data, ",", subName, value )		
			Data_OutputItem2File( itemName, 0 )
		end
		return
	end
		
	if not subName then
		v = value
	elseif typeof(value) == "number" then
		print( "Output Value is number", itemName, ",", data, ",", subName )
		Data_OutputItem2File( itemName, value )
		return
	else
		v = value[subName]		
	end	
	
	Data_OutputItem2File( itemName, v )
end

local function Data_OutputTable2File( tableName, data, itemName )
	if not _fileHandler then print( "File not opened") return end
	if not data then print( "Table invalid" ) return end		
	Data_OutputOriginalText( tableName .. "={\n" )	
	local table = data[tableName]
	if table then
		if itemName then
			for k, v in pairs( table ) do
				--print( k, "=", v[itemName] )
				Data_OutputItem2File( k, v[itemName], 1 )
			end
		else
			for k, v in pairs( table ) do				
				--print( k, "=", v )
				if typeof( v ) == "table" then
					local currentIndent = _indent
					Data_SetIndent( currentIndent + 1 )
					Data_OutputTable2File( k, table )
					Data_SetIndent( currentIndent )
				else					
					Data_OutputItem2File( k, v, 1 )
				end
			end
		end
	end
	Data_OutputOriginalText( "},\n" )	
end

------------------------------------------------


function Data_OpenOuputFile( fileName )
	_fileHandler = SaveFileUtility()

	_fileHandler:OpenFile( fileName )
end

function Data_FinishOutput()
	if _fileHandler then
		_fileHandler:CloseFile()
	end
end

function Data_SetIndent( indent )
	_indent = indent
end

function Data_IncIndent( delta )
	_indent = _indent + delta
end

--[[
function Data_OutputItem( itemName, data )
	Data_OutputItem2File( itemName, data )
end
]]

function Data_OutputValue( itemName, data, subName, default )
	Data_OutputValue2File( itemName, data, subName, default )
end

--
-- Support Pattern
--   Data_OutputTable( "id", item )
--   Data_OutputTable( "item", bag, "id" )
--
function Data_OutputTable( tableName, data, itemName )
	Data_OutputTable2File( tableName, data, itemName )
end

function Data_OutputBegin( itemName )
	Data_OutputBegin2File( itemName )
end
function Data_OutputEnd()
	Data_OutputEnd2File()
end

function Data_OutputFlush()
	Data_OutputFlush2File()
end

--------------------

local _loadHandler = nil

function Data_OpenInputFile( fileName )
	if not _loadHandler then _loadHandler = LoadFileUtility() end
	_loadHandler:OpenFile( fileName )
end

function Data_ParseFile( data )
	if not _loadHandler then print( "File not opened" ) end
	_loadHandler:ParseTable( data )
end