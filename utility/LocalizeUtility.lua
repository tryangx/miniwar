local test_data = 
{
	language 	= "chs",
	texts  		= 
	{
		{ original = "ShiMa Cuo", text = "´í" },
		{ original = "Test 1=$1$ 2=$2$", text = "²âÊÔ $1$ $2$ $1$ $2$" },
	},
}

local localize_config = test_data
local localize_data   = {}

local function Localize_GenerateKey( id1, id2 )
	return id1 + id2
end

local function Localize_GenerateID( text )
	local id1, id2 = 0, 0
	local len = string.len( text )
	for i = 1, len do
		if i % 2 == 0 then
			id1 = id1 + string.byte( text, i )
		else
			id2 = id2 + string.byte( text, i )
		end
	end
	if id2 == 0 then id2 = id1 end
	return id1, id2	
end

function Localize_Init( config )
	if config then
		localize_config = config
	end
	localize_data = {}
	for k, v in pairs( localize_config.texts ) do
		local id1, id2 = Localize_GenerateID( v.original )
		v.id1 = id1
		v.id2 = id2
		local key = Localize_GenerateKey( id1, id2 )
		--print( id1, id2, key )
		if not localize_data[key] then localize_data[key] = {} end
		table.insert( localize_data[key], v )
	end
end

--[[
	print( Localize_Text( "Test 1=$1$ 2=$2$", "abc", 1234 ) )
--]]
function Localize_Text( text, ... )
	local args = { ... }
	local ret
	local id1, id2 = Localize_GenerateID( text )
	local key = Localize_GenerateKey( id1, id2 )
	local list = localize_data[key]
	--print( id1, id2, key, list )
	if list then
		for k, v in ipairs( list ) do
			if v.id1 == id1 and v.id2 == id2 then
				ret = string.rep( v.text, 1 )
				break
			end
		end
	end
	if ret and #args > 0 then
		for i = 1, #args do
			local pattern = "%$"..i.."%$"			
			--print( ret, pattern, args[i] )
			ret = string.gsub( ret, pattern, args[i] )
		end
	end
	return ret
end
