require 'Map'
require 'MapCreator_HeightMap'
require 'MapCreatorParam'
require 'loop.table'
require 'mathlib'

--[[
function comp( v1, v2 )
	return math.random( 1, 100 ) < math.random( 1, 100 )
end

function ps( arr )
	local str = ''
	for i, v in ipairs( arr ) do
		str = str .. ' ' .. v
	end
	print( str )
end

math.randomseed( os.time() )
local a1 = { 1, 2, 3, 4, 5, 6 }
--local a2 = a1
local a2 = loop.table.copy( a1 )
table.sort( a2, comp )

ps( a1 )
ps( a2 )


table = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 }

Math_Foreach( table, function ( v ) print( v ) end )
Math_Shuffle( table )
Math_Foreach( table, function ( v ) print( v ) end )

]]

m = Map()
p = MapCreatorParam()
gen = MapCreator_HeightMap()
gen:Init( m, p )
gen:StartCreation()
m:Dump()

--[[
function func( a )
	print( a )
end

clz = class()

function clz:test( a )	
	print( a )	
end

function clz:ps( fn )	
	print( fn )
	if fn ~= nil then
		fn( 'hello' )
	end
end

c = clz()
]]

--[[
c.ps( func )
print( '2' )
c:ps( func )
]]

--[[
print( 'step1' )
c:ps( clz.test )
print( '\nstep2' )
c:ps( func )
]]

--[[
mapParam = MapParam()

m = Map()
m:Generate( mapParam )
m:Dump()
]]
