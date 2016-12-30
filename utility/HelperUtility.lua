---------------------------
-- Helper

-- Randomizer
function Random_SyncGetRange( min, max, desc )
	local value = g_asyncRandomizer:GetInt( min, max )
	if desc then 
		Debug_Log( "Gen Random ["..value.."] in ["..min..","..max.."] : " .. desc )
	end
	return value
end

function Random_LocalGetRange( min, max, desc )
	local value = g_globalRandomizer:GetInt( min, max )
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

---------------------------------------------

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
			if value then
				if not range or relation.value <= range - value then
					relation.value = relation.value + value
				end
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
		if relation.type == relationType and ( relation.id == 0 or relation.id == id1 or trait.id == id2 ) then
			return tag
		end
	end
	return nil
end

function Helper_GetTag( tags, tagType )
	if not tags then return nil end
	for k, tag in ipairs( tags ) do		
		if tag.type == tagType then
			return tag
		end
	end
	return nil
end
function Helper_AppendTag( tags, tagType, value, range )
	for k, tag in ipairs( tags ) do
		if tag.type == tagType then
			if not range or tag.value <= range - value then
				tag.value = tag.value + value
			end
			return
		end
	end
	table.insert( tags, { type = tagType, value = value } )
end
function Helper_RemoveTag( tags, tagType, value )
	for k, tag in ipairs( tags ) do
		if tag.type == tagType then
			if tag.value and tag.value > value then
				tag.value = tag.value - value
			else
				table.remove( tags, k )
			end
			return
		end
	end
end

------------------------------------------
-- 
function Helper_IsHarvestTime()
	return MathUtility_IndexOf( CityParams.HARVEST_TIME, g_calendar:GetMonth() ) and g_calendar:GetDay() <= 1
end

function Helper_IsLevyTaxTime()
	return MathUtility_IndexOf( CityParams.LEVY_TAX_TIME, g_calendar:GetMonth() ) and g_calendar:GetDay() <= 1
end

function Helper_IsTurnOverTaxTime()
	return MathUtility_IndexOf( CityParams.TURN_OVER_TAX_TIME, g_calendar:GetMonth() ) and g_calendar:GetDay() <= 1
end

------------------------------------------
-- String

function Helper_Abbreviate( str, length )
	local ret = ""
	for word in string.gmatch( str, "%a+" ) do
		local c = string.sub( word, 1, 1 )		
		ret = ret .. c
		if length >= 1 then length = length - 1 else break end
	end
	if length > 0 then
		local len = string.len( str )
		ret = ret .. string.sub( str, len - length + 1, len )
	end
	local len = string.len( str )
	while len < 3 do
		str = str .. " "
		len = len + 1
	end
	return ret
end