require 'randomizer'

MathCompareMethod =
{
	EQUALS = 0,
	
	MORE_THAN = 1,
	
	LESS_THAN = 2,
	
	MORE_THAN_AND_EQUALS = 3,
	
	LESS_THAN_AND_EQUALS = 4,
}


--[[
	Clamp the given value
	
	@usage 
		print( MathUtility_Clamp( 100, 2, 80 ) ) -- 80
		print( MathUtility_Clamp( 1, 2, 80 ) )   -- 2

]]
function MathUtility_Clamp( value, min, max )
	if value < min then value = min
	elseif value > max then value = max end
	return value
end


--[[
	Shuffle Table
	
	-- @usage 
		MathUtility_Shuffle( { 1, 3, 5 } ) -- { 3, 5, 1 }
]]
function MathUtility_Shuffle( table, randomizer, desc )
	if not randomizer then
		randomizer = Randomizer()
		randomizer:SetSeed( 1 )--os.time() )	
	end
	local length = #table
	if length > 1 then
		for i = 1, length do			
			local t = randomizer:GetInt( 1, length - 1, desc ) + 1
			local temp = table[i]
			table[i] = table[t]
			table[t] = temp
		end
	end
	return table
end

function MathUtility_ShuffleByGetter( table, getter, desc )
	local length = #table
	if length > 1 then
		for i = 1, length do
			local t = getter( 1, length - 1, desc ) + 1
			local temp = table[i]
			table[i] = table[t]
			table[t] = temp
		end
	end
	return table
end


--[[
	Call for each in Table with function

	-- @usage MathUtility_Foreach( table, function( v ) print( v ) end )
]]
function MathUtility_Foreach( table, fn )	
	for k, v in pairs( table ) do
		if type( v ) == "table" then
			MathUtility_Foreach( v, fn )
		else
			fn( v )
		end
	end
end


function MathUtility_QueryTableName( table )
	for k, v in pairs(_G) do
		--print( k, ",", v )
		if table == v then
			return k
		end
	end
	return ""
end


function MathUtility_DumpWithTab( content, indent )
	io.write( string.rep (" ", indent) ) -- indent it
	io.write( content )
	io.write( "\n" )
	--print( str )
end


function MathUtility_Dump( table, indent )
	if not indent then indent = 0 end
	if not table then
		print( "Dump table is invalid!" )
		return
	end
	if indent > 3 then
		return
		--print( "Depth too high" )
	end
	MathUtility_DumpWithTab( "{", indent )	
	for k, v in pairs( table ) do
		if type( v ) == "table" then
			MathUtility_DumpWithTab( k .. "=", indent + 1 )
			MathUtility_Dump( v, indent + 1 )
		elseif type( v ) == "string" then
			MathUtility_DumpWithTab( k .. "=\"" .. v .. "\"", indent + 1 )
		elseif type( v ) == "boolean" then
			if v then 
				MathUtility_DumpWithTab( k .. "=true", indent + 1 )
			else
				MathUtility_DumpWithTab( k .. "=false", indent + 1 )
			end
		elseif type( v ) == "function" then
			break
		elseif type( v ) == "object" then
			break
		else
			MathUtility_DumpWithTab( k .. "=" .. v, indent + 1 )
		end
	end
	MathUtility_DumpWithTab( "}", indent )
end


--[[
	
]]
function MathUtility_EnumAssign( table )
	local index = 1
	for k, v in pairs( table ) do
		table[k] = index
		index = index + 1
	end
end

function MathUtility_Merge( left, right, condition )
	if not right then return left end
	
	local destination = {}
	for k, v in pairs( left ) do
		if not condition or condition( v ) then
			table.insert( destination, v )
		end
	end
	for k, v in pairs( right ) do
		if not condition or condition( v ) then
			table.insert( destination, v )
		end
	end
	--print( #left, #right, #destination )
	return destination
end


--[[
	Copy Table
	
	-- @usage copied = MathUtility_Copy(results)
	-- @usage MathUtility_Copy(results, newcopy)
]]
function MathUtility_Copy(source, destination)
	if not destination then destination = {} end
	if source then
		for field, value in pairs(source) do
			if typeof(value) == "table" then
				destination[field] = {}
				MathUtility_Copy( value, destination[field] )
			else
				--print( "rawset", field, value )
				rawset(destination, field, value)
			end
		end
	end
	return destination
end

function MathUtility_ShallowCopy( source, destination )
	if not destination then destination = {} end
	if source then
		for field, value in pairs(source) do
			destination[field] = value
		end
	end
	return destination
end

--[[
	@return return index of the item in the table
	
	@usage 
		table = { 1, 2, 3 }
		if MathUtility_IndexOf( table, 2 ) then
			print( "find" )
		end

]]
function MathUtility_IndexOf( table, target, name )
	if not table then return nil end
	if not name then
		for k, v in pairs( table ) do
			if v == target then return k end
		end
	else
		for k, v in pairs( table ) do
			if v[name] == target then return k end
		end
	end
	return nil
end

function MathUtility_FindData( table, target, name )
	if not table then return nil end
	if name then
		for k, v in pairs( table ) do
			if v[name] == target then return v end
		end
	end
	return nil
end

--[[
	@param descending true/false

	@usage 
		list = { { v = 1 }, { v = 3 }, { v = 5 } 
		MathUtility_Insert( list, { v = 4 }, "v" )
		//output
		// { { v = 1 }, { v = 3 }, { v = 4 }, { v = 5 } }
]]
function MathUtility_Insert( list, target, name, descending )
	if descending then
		if name then
			for k, v in ipairs( list ) do
				if v[name] < target[name] then
					table.insert( list, k, target )
					return k
				end
			end
		else
			for k, v in ipairs( list ) do
				if v < target then
					table.insert( list, k, target )
					return k
				end
			end
		end
	else
		if name then
			for k, v in ipairs( list ) do
				if v[name] > target[name] then
					table.insert( list, k, target )
					return k
				end
			end
		else
			for k, v in ipairs( list ) do
				if v > target then
					table.insert( list, k, target )
					return k
				end
			end		
		end
	end
	table.insert( list, target )
	return #list - 1
end

--[[
	push target into the back of table without duplicated

]]
function MathUtility_PushBack( list, target, name )
	if not name then
		for k, v in ipairs( list ) do
			if v == target then return false end
		end
	else
		for k, v in ipairs( list ) do
			if v[name] == target then return false end
		end
	end
	table.insert( list, target )
	return true
end

--[[
	This is not really remove, just set id to nil
	
	@param target It's item in the list which should be 'removed'
]]
function MathUtility_RemoveAndReserved( list, target, name )
	if not list then return end
	if not name then
		for k, v in pairs( list ) do
			if v == target then
				list[k] = nil
				return true
			end
		end
	else
		for k, v in pairs( list ) do
			if v[name] == target then
				list[k] = nil
				return true
			end
		end
	end
	return false
end

function MathUtility_Remove( list, target, name )
	if not list then 
		print( "List is invalid" )
		return false
	end
	if not name then 
		for k, v in pairs( list ) do
			if v == target then
				table.remove( list, k )
				return true
			end
		end
	else
		for k, v in pairs( list ) do
			if v[name] == target then
				table.remove( list, k )
				return true
			end
		end
	end
	return false
end

--[[
	Return the string name equal the given value in the enum list
]]
function MathUtility_FindEnumName( enumList, value )
	for k, v in pairs( enumList ) do
		if v == value then return k end
	end
	return ""
end

--[[
	Return the key of the right name in the enum list
]]
function MathUtility_FindEnumKey( enumList, value )
	for k, v in pairs( enumList ) do
		if v == value then return k end
	end
	return 0
end

function MathUtility_ClearInvalid( source )
	local destination = {}	
	if source then
		for field, value in pairs(source) do
			table.insert( destination, value )
		end
	end
	return destination
end

--[[
	Find median
]]
function MathUtility_FindMedian( list, keyName )
	local list = {}
	if keyName then
		for k, v in pairs( list ) do
			MathUtility_Insert( list, v[keyName], keyName )
		end
	else
		for k, v in pairs( list ) do
			MathUtility_Insert( list, v )
		end
	end	
	local number = #list
	if number == 0 then return 0 end
	return list[math.ceil(number/2)]
end

--[[
	(Test not pass)Return an array with index limited by the given range
]]
function MathUtility_CreateRandomIndexs( min, max, num )
	local len = math.abs( max - min )
	if max < min then
		min, max = max, min
	end
	local try = 0
	local array = {}
	repeat
		try = try + 1
		local ret = math.random( min, max )
		if not MathUtility_IndexOf( array, ret ) then
			table.insert( array, ret )
		end
		--print( #array, num, try, ret, min, max )
	until #array >= num or try >= len
	
	if #array < num and num < len then
		for k = min, max do
			if not MathUtility_IndexOf( array, k ) then
				table.insert( array, k )
			end
			if #array > num then
				break
			end
		end
	end
	
	return array
end

function MathUtility_CountLength( list )
	local len = 0
	for k, v in pairs( list ) do
		len = len + 1
	end
	return len
end

--[[
--Sqrt Positive Integer Below 10
local _SqrtPIB10 = nil
function MathUtility_SqrtPIBBelow10( number )
	if number <= 0 then return 0 end 
	if number > 10 then return math.sqrt( number ) end
	if not _SqrtPIB10 then
		_SqrtPIB10 = {}
		for k = 1, 100 do
			_SqrtPIB10[k] = { sqrt = math.sqrt( k * 0.1 ) }
		end
	end
	local index = math.ceil( number / 0.1 )	
	--print( number, index, _SqrtPIB10[index].sqrt, math.sqrt( number ) )
	return _SqrtPIB10[index].sqrt
end

local _SqrtPIB1 = nil
function MathUtility_SqrtPIB1( number )
	if number <= 0 then return 0 end 
	if number > 1 then return math.sqrt( number ) end
	if not _SqrtPIB1 then
		_SqrtPIB1 = {}
		for k = 1, 100 do
			_SqrtPIB1[k] = { sqrt = math.sqrt( k * 0.01 ) }
		end
	end
	local index = math.ceil( number / 0.01 )	
	--print( number, _SqrtPIB1[index].sqrt, math.sqrt( number ) )
	return _SqrtPIB1[index].sqrt
end
]]

--[[
	@usage 
		local enum = 
		{
			power = 1,
			speed = 2,	
		}

		list_a = {
			[1] = 100,
			[2] = 50,
		}

		local list = list_a
		local list_b = MathUtility_ConvertKeyToString( enum, list )
		list = list_a
		MathUtility_Dump( list ) 
		--{
		--  1 = 100,
		--  2 = 50,
		--}
		list = list_b
		MathUtility_Dump( list )		
		--{	
		--  speed = 50,
		--  power = 100,
		--}
		
		local list_c = MathUtility_ConvertKeyToID( enum, list_b )
		list = list_c
		MathUtility_Dump( list )
		--{
		--  1 = 100,
		--  2 = 50,
		--}
]]
function MathUtility_ConvertKeyToString( keyEnum, list )
	local newList = {}
	if not list then return newList end
	for k, v in pairs( list ) do	
		newList[MathUtility_FindEnumKey( keyEnum, k )] = v
	end
	return newList
end

-- Reverse from MathUtility_ConvertKeyToString()
function MathUtility_ConvertKeyToID( keyEnum, list )
	local newList = {}	
	if not list then return newList end
	for k, v in pairs( list ) do
		newList[keyEnum[k]] = v
	end
	return newList
end