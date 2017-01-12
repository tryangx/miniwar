---------------------------
-- Helper

-- Randomizer
function Random_LocalGetRange( min, max, desc )
	local value = g_asyncRandomizer:GetInt( min, max )
	if desc then 
		Debug_Log( "Gen Random ["..value.."] in ["..min..","..max.."] : " .. desc )
	end
	return value
end

function Random_SyncGetRange( min, max, desc )
	local value = g_syncRandomizer:GetInt( min, max )
	if desc then 
		Debug_Log( "Gen Random ["..value.."] in ["..min..","..max.."] : " .. desc )
	end
	return value
end

function Random_SyncGetProb( desc )
	local value = g_syncRandomizer:GetInt( 1, 10000 )
	if desc then 
		Debug_Log( "Gen Random ["..value.."] in ["..min..","..max.."] : " .. desc )
	end
	return value
end

function NameIDToString( data )
	local content = ""
	if data then
		if data.name then
			content = content .. "[" .. data.name .. "]"
		end
		if data.id then
			content = content .. "(" .. data.id .. ")"
		end
	end
	return content
end

function Helper_CreateNumberDesc( number, digit )
	if digit == 2 then
		digit = 100
	else
		digit = 10
	end
	local eng_units= 
	{
		{ range = 1000000, unit = "M", },
		{ range = 1000, unit = "K", },
	}
	local chi_units = 
	{
		{ range = 1000000, unit = "°ÙÍò", },
		{ range = 10000, unit = "Íò", },
	}
	local items = chi_units--eng_units
	for k, v in ipairs( items ) do
		if math.abs( number ) > v.range then
			local integer = number * digit / v.range
			local ret = math.floor( integer / digit ) .. "." .. ( math.floor( integer ) % digit ) .. v.unit
			--print( number .. "->" .. ret )
			return ret
		end
	end
	return number
end

---------------------------------------------

function Helper_SumIf( datas, itemName, itemValue, countName, itemNameEnum )
	local ret = 0
	if itemNameEnum then
		for k, data in ipairs( datas ) do					
			if itemNameEnum[data[itemName]] == itemValue then
				--print( itemName, data[itemName], itemNameEnum[data[itemName]], itemValue )
				ret = ret + data[countName]
			end
		end
	else
		for k, data in ipairs( datas ) do		
			if data[itemName] == itemValue then
				ret = ret + data[countName]
			end
		end
	end
	return ret
end

function Helper_CountIf( datas, condition )
	local number = 0
	for k, v in pairs( datas ) do
		if condition( v ) then
			number = number + 1
		end
	end
	return number
end

function Helper_ListIf( datas, condition )
	local list = {}
	for k, v in pairs( datas ) do
		if condition( v ) then
			table.insert( list, v )
		end
	end
	return list
end

function Helper_ListEach( datas, condition )
	local list = {}
	for k, v in pairs( datas ) do
		condition( v, list )
	end
	return list
end

---------------------------------------------
--Relation & Tag
function Helper_AppendRelation( relations, relationType, id, value, range )
	for k, relation in ipairs( relations ) do
		if relation.type == relationType and ( not id or relation.id == 0 or relation.id == id ) then
			if value and ( not range or relation.value <= range - value ) then
				relation.value = relation.value + value
			end
			return
		end
	end
	table.insert( relations, { type = relationType, id = id or 0, value = value or 0 } )
end
function Helper_RemoveRelation( relations, relationType, id, value )
	for k, relation in ipairs( relations ) do
		if relation.type == relationType and ( not id or relation.id == 0 or relation.id == id ) then
			if value then
				if relation.value and relation.value > value then
					relation.value = relation.value - value
				else
					table.remove( relations, k )
				end
			end
			return
		end
	end
end
function Helper_GetRelation( relations, relationType, id1, id2 )
	if not relations then return nil end
	for k, relation in ipairs( relations ) do
		if relation.type == relationType and ( relation.id == 0 or relation.id == id1 or relation.id == id2 ) then
			return relation
		end
	end
	return nil
end

function Helper_GetVarb( varbs, varbType )	
	if not varbs then return nil end
	for k, varb in ipairs( varbs ) do		
		if varb.type == varbType then
			return varb
		end
	end
	return nil
end
function Helper_SetVarb( varbs, varbType, value )
	for k, varb in ipairs( varbs ) do
		if varb.type == varbType then
			varb.value = varb.value + value
			return
		end
	end
	table.insert( varbs, { type = varbType, value = value } )
end
function Helper_AppendVarb( varbs, varbType, value, maximum )
	for k, varb in ipairs( varbs ) do
		if varb.type == varbType then
			if not maximum or varb.value <= maximum - value then
				varb.value = varb.value + value
			end
			return
		end
	end
	table.insert( varbs, { type = varbType, value = value } )
end
--[[
	@value when value is -1, means remove all
]]
function Helper_RemoveVarb( varbs, varbType, value, minimum )
	minimum = minimum or 0
	for k, varb in ipairs( varbs ) do
		if varb.type == varbType then
			if varb.value and varb.value ~= -1 and varb.value > value + minimum then
				varb.value = varb.value - value
			else
				table.remove( varbs, k )
			end
			return
		end
	end
end

------------------------------------------
-- 
function Helper_IsHarvestTime()
	return MathUtility_IndexOf( CityParams.HARVEST.HARVEST_TIME, g_calendar:GetMonth() ) and g_calendar:GetDay() <= 1
end

function Helper_IsLevyTaxTime()
	return MathUtility_IndexOf( CityParams.LEVY_TAX.LEVY_TAX_TIME, g_calendar:GetMonth() ) and g_calendar:GetDay() <= 1
end

function Helper_IsTurnOverTaxTime()
	return MathUtility_IndexOf( CityParams.TURN_OVER_TAX_TIME, g_calendar:GetMonth() ) and g_calendar:GetDay() <= 1
end

------------------------------------------
-- String

function Helper_TrimString( str, finalLength, curLength )
	local ret
	local length = #str
	if finalLength then
		if length < finalLength then
			ret = str
			for k = 1, finalLength - length do
				ret = ret .. " "
			end
		else
			ret = string.sub( str, 1, finalLength )
		end
	elseif cutLength then
		if curLength >= length then
			ret = ""
		else
			ret = string.sub( str, 1, length - curLength )
		end
	end
	return ret
end

function Helper_AbbreviateString( str, length )
	local ret = ""
	local len = string.len( str )
	if len < length then
		ret = str
	else
		for word in string.gmatch( str, "%a+" ) do
			local c = string.sub( word, 1, 1 )		
			ret = ret .. c
			if length >= 1 then length = length - 1 else break end
		end
		if length > 0 then		
			ret = ret .. string.sub( str, len - length + 1, len )
		end
	end
	for k = 1, length - len do
		ret = ret .. " "
	end
	return ret
end