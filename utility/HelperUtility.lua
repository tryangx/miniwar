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

function Helper_AppendTrait( traits, traitType, id, value, range )
	for k, trait in ipairs( traits ) do
		if trait.type == traitType and ( not id or trait.id == 0 or trait.id == id ) then
			if value then
				if not range or trait.value <= range - value then
					trait.value = trait.value + value
				end
			end
			return
		end
	end
	table.insert( traits, { type = traitType, id = id or 0, value = value or 0 } )

end

function Helper_RemoveTrait( traits, traitType, id, value )
	for k, trait in ipairs( traits ) do
		if trait.type == traitType and ( not id or trait.id == 0 or trait.id == id ) then
			if value then
				if trait.value and trait.value > value then
					trait.value = trait.value - value
				else
					table.remove( traits, k )
				end
			end
			return
		end
	end
end

function Helper_GetTag( tags, tagType )
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