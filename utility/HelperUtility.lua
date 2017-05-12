---------------------------
-- Helper

debugAddRemoveData = true
quickSimulate = true
debugMeeting = false

local HelperLog = nil
local function Helper_GetLog()
	if not HelperLog then HelperLog = LogUtility( "log/helper_" .. g_gameId .. ".log", LogWarningLevel.IMPORTANT, true ) end
	return HelperLog
end

function IsSimulating()
	return quickSimulate or not g_game:IsGameEnd()
end

function ShowDebug( ... )
	Helper_GetLog():WriteDebug( ... )
end

function ShowText( ... )
	Helper_GetLog():WriteLog( ... )
	--if not IsSimulating() then print( ... ) end
end

function ShowImpText( ... )
	Helper_GetLog():WriteImportant( ... )
end

function EndShowText()
	quickSimulate = false
	debugLog:CloseFile()
end

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

--------------------------------------------

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

function MakeActorBriefString( data )
	local content = ""
	if data then
		if data.name then
			content = content .. "[" .. data.name .. "]"
		end
		if data.id then
			content = content .. "(" .. data.id .. ")"
		end
		if data.GetTroop then
			content = content .. " troop=" .. NameIDToString( data:GetTroop() )
		end
		if data.GetLeader then
			content = content .. " chara=" .. NameIDToString( data:GetLeader() )
		end
		if data.GetCorps then
			content = content .. " corps=" .. NameIDToString( data:GetCorps() )
		end
	end
	return content
end

function Helper_DumpList( list, fn )
	for k, item in pairs( list ) do
		local content
		if fn then
			content = fn( item )
		else
			content = NameIDToString( item )
		end
		print( content )
	end
end

function Helper_ConcatListName( list, fn )
	local content = ""
	for k, item in pairs( list ) do
		content = content .. NameIDToString( item )
		if fn then content = content .. fn( item ) end		
		content = content .. "/"
	end
	return content
end

function Helper_CreateNumberDesc( number, digit, decimal )
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
		{ range = 1000000, unit = "百万", },
		{ range = 10000, unit = "万", },
		{ range = 1000, unit = "千", },
		--{ range = 100, unit = "百", },
	}
	local items = eng_units
	if g_language == "chs" then
		items = chi_units
	elseif g_language == "eng" then
		items = eng_units
	end
	for k, v in ipairs( items ) do
		if math.abs( number ) >= v.range then
			local integer = number * digit / v.range
			local ret = math.floor( integer / digit )
			if decimal then ret = ret .. "." .. ( math.floor( integer ) % digit ) end
			ret = ret .. v.unit
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
			if not itemValue or itemNameEnum[data[itemName]] == itemValue then
				--print( itemName, data[itemName], itemNameEnum[data[itemName]], itemValue )
				ret = ret + data[countName]
			end
		end
	else
		for k, data in ipairs( datas ) do		
			if not itemValue or data[itemName] == itemValue then
				ret = ret + data[countName]
			end
		end
	end
	return ret
end

function Helper_Count( datas, itemName )
	local number = 0
	for k, v in pairs( datas ) do
		local value = v[itemName] or 0
		number = number + value
	end
	return number
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
	for k, relation in pairs( relations ) do
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
	for k, relation in pairs( relations ) do
		if relation.type == relationType and ( not id or relation.id == 0 or relation.id == id ) then
			if value then
				if relation.value and relation.value > value then
					relation.value = relation.value - value
				else
					table.remove( relations, k )
				end
			else
				table.remove( relations, k )
			end
			return
		end
	end
end
function Helper_GetRelation( relations, relationType, id1, id2 )
	if not relations then return nil end
	for k, relation in pairs( relations ) do
		if relation.type == relationType and ( relation.id == 0 or relation.id == id1 or relation.id == id2 ) then
			return relation
		end
	end
	return nil
end

function Helper_GetVarb( varbs, varbType )	
	if not varbs then return nil end
	for k, varb in pairs( varbs ) do		
		if varb.type == varbType and varb.value then
			return varb
		end
	end
	return nil
end
function Helper_SetVarb( varbs, varbType, value )
	for k, varb in pairs( varbs ) do
		if varb.type == varbType then
			if value then
				varb.value = varb.value + value
			else
				--equal to nil, means remove
				varb.value = value
			end
			return
		end
	end
	table.insert( varbs, { type = varbType, value = value } )
end
function Helper_AppendVarb( varbs, varbType, value, maximum )
	if not value then value = 0 end
	for k, varb in pairs( varbs ) do
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
	for k, varb in pairs( varbs ) do
		if varb.type == varbType then			
			if value then
				if varb.value and varb.value ~= -1 and varb.value > value + minimum then
					varb.value = varb.value - value
				else
					table.remove( varbs, k )
				end
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
		local abStr = ""
		local left = length
		for word in string.gmatch( str, "%a+" ) do
			local c = string.sub( word, 1, 1 )		
			abStr = abStr .. c
			if left >= 1 then left = left - 1 else break end
		end
		if left > 0 then
			--ret = ret .. string.sub( str, len - left + 1, len )
			ret = ret .. string.sub( str, 1, length )
		else
			ret = abStr
		end
	end
	for k = 1, length - len do
		ret = ret .. " "
	end
	return ret
end

-----------------------------------------

function Helper_FindPathBetweenCity( location, destination )
	local closeList = {}
	local openList = {}
	local parentList = {}
	local costList = {}
	table.insert( openList, destination )
	
	--print( "find way ", location.name, destination.name )
	
	--bfs
	while #openList > 0 do
		local current = openList[1]
		table.remove( openList, 1 )
		closeList[current] = 1
		for k, adja in ipairs( current.adjacentCities ) do
			if adja == location then
				--reverse to get path
				path = { destination }
				local parent = parentList[current]
				while parent do
					--print( "parent", parent.name )
					table.insert( path, parent )
					parent = parentList[parent]
				end
				--InputUtility_Pause( "Find path=" .. #path )
				return path
			else
				if not closeList[adja] then
					parentList[adja] = current
					table.insert( openList, adja )
				end
			end
		end
	end
	return nil
end

-----------------------------------------------

function Helper_AddDataSafety( list, data )
	if debugAddRemoveData and MathUtility_IndexOf( list, data ) then
		InputUtility_Pause( "data " .. NameIDToString( data ) .. " already in" )
		return false
	end
	table.insert( list, data )
	return true
end

function Helper_RemoveDataSafety( list, data )
	if debugAddRemoveData and not MathUtility_IndexOf( list, data ) then
		InputUtility_Pause( "data " .. NameIDToString( data ) .. " not in" )
		return false
	end
	--print( "removed " .. NameIDToString( data ) )
	MathUtility_Remove( list, data )
	return true
end