---------------------------
-- Helper

-- Randomizer
function Random_SyncGetRange( min, max, desc )
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