package.path = package.path .. ";utility/?.lua"
package.path = package.path .. ";gameplay/?.lua"
package.path = package.path .. ";table/?.lua"
package.path = package.path .. ";data/?.lua"
package.path = package.path .. ";behavior/?.lua"
package.path = package.path .. ";ai/?.lua"

require "unclasslib"
require "MathUtility"
require "DebugUtility"
require 'Game'

--[[
line = "test123_123sf="
pos1, pos2 = string.find( line, "[%w-_]+" )
if pos1 and pos2 then
print( string.sub( line, pos1, pos2 ) )
end
--]]


--[[
-- Test Class Copy
clz = class()
function clz:__init()
	self.a = 0
end

c1 = clz()
c1.a = 10
print( c1.a )

tab = {}
table.insert( tab, c1 )
print( tab[1].a )
c1.a = 50
print( tab[1].a, tab[1] )
print( c1.a, c1 )
tab[1].a = 20
print( tab[1].a )
print( c1.a )


--]]

--[[
local c1 = {
	a = {
		b =100
	}
}

local c2 = MathUtility_Copy( c1 )

c1.a.b = 150
print( c1.a.b )
MathUtility_Dump( c1 )
print( "-")
print( c2.a.b )
MathUtility_Dump( c2 )
]]

--[[]]

game = Game()
game:Init()
game:MainMenu()
--]]


--[[
require "Behavior"
require "BehaviorNode"

Behavior_Test()
]]

require "FileUtility"

saveData = 
{
	--[[
	{
		id = 1,
		type = "nation",
		name = "red",
		value = 100,
	},
	
	{
		id = 2,
		type = "nation",
		name = "blue",
		value = 50,
	},
	
	]]
	t1 = {
		str = "test",
		number= 100,
		float =1.2,
		nested={
			c="1",
		}
	},
	t2 = 
	{
	},
	k = 34,
}


--[[
save = SaveFileUtility()
save:OpenFile( "output.log" )
save:WriteTable( saveData )
save:CloseFile()
MathUtility_Dump( saveData )
--]]

--[[
line1 = "--aa"
line2 = "/* */"
line3 = "//"

function parse( str, pattern )
	local pos1, pos2 = string.find( str, pattern )
	print( "parse:" .. str, "pattern:" .. pattern )
	if pos1 then
		local v = string.sub( str, pos1, pos2 )
		print( "result:", v	.. "#")
	end	
	print()
end

--pattern = "%w+"
pattern = "[a]{2,}"
parse( line1, pattern )
parse( line2, pattern )
parse( line3, pattern )
--]]

--[[
load = LoadFileUtility()
load:OpenFile( "output.log" )
local table = load:ParseTable()
MathUtility_Dump( table )
print( table[1] )
print( table["t1"] )
print( table["t2"] )

--]]