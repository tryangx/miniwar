local _PATH = (...):match('^(.*[%./])[^%.%/]+$') or ""

require "BehaviorNode"

local DEBUG_LOG = false

Behavior = class()

local function Selector( behavior, node )
	if DEBUG_LOG then 
		print( "Selector=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	for k, child in ipairs( node.children ) do
		behavior:SetCurrentNode( node )
		local fn = behavior.functions[child.type]
		if fn and fn( behavior, child ) then return true end
	end	
	return false
end
local function RandomSelector( behavior, node )	
	if DEBUG_LOG then 
		print( "RandomSelector=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	local children = behavior:Copy( node.children )
	behavior:Shuffle( children )
	for k, child in pairs( children ) do		
		behavior:SetCurrentNode( node )
		local fn = behavior.functions[child.type]
		if fn and fn( behavior, child ) then return true end
	end
	return false
end
local function Sequence( behavior, node )
	if DEBUG_LOG then 
		print( "Sequence=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	for k, child in pairs( node.children ) do		
		behavior:SetCurrentNode( node )
		local fn = behavior.functions[child.type]
		if fn and fn( behavior, child ) == false then
			return false
		end
	end
	return true
end
--[[
local function Parallel( behavior, node )
	if DEBUG_LOG then print( "Parallel" ) end
	for k, child in pairs( node.children ) do
		if behavior.functions[child.type]( behavior, child ) == false then return false end
	end
	return true
end
]]

local function Action( behavior, node )
	if DEBUG_LOG and node.desc  then 
		print( "Action=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	behavior:SetCurrentNode( node )
	if node.action then
		if node.params then
			node.action( node.params )
		else
			node.action()
		end
	end
	return true
end
local function ConditionAction( behavior, node )
	if DEBUG_LOG and node.desc  then 
		print( "ConditionAction=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	behavior:SetCurrentNode( node )
	if node.condition and node.condition() then	
		if node.action then node.action( node.params ) end
		return true
	end
	return false
end

local function Successor( behavior, node )
	if DEBUG_LOG and node.desc  then 
		print( "Successor=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	behavior:SetCurrentNode( node )
	behavior:Run( node:GetFirstChild() )
	return true
end
local function Failure( behavior, node )
	if DEBUG_LOG and node.desc  then 
		print( "Failure=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	behavior:SetCurrentNode( node )
	behavior:Run( node:GetFirstChild() )
	return false
end
local function Negate( behavior, node )
	if DEBUG_LOG and node.desc then 
		print( "Negate=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	behavior:SetCurrentNode( node )	
	return not behavior:Run( node:GetFirstChild() )
end

local function Filter( behavior, node )
	if DEBUG_LOG and node.desc then 
		print( "Filter=" .. ( node.desc or "" ) .. " nodes=" .. #node.children )		
	end
	behavior:SetCurrentNode( node )
	return node.condition and node.condition( node.params )
end

function Behavior:__init( ... )	
	self.functions = {}
	self.functions[BehaviorNodeType.SELECTOR] = Selector
	self.functions[BehaviorNodeType.RANDOM_SELECTOR] = RandomSelector
	self.functions[BehaviorNodeType.SEQUENCE] = Sequence
	--self.functions[BehaviorNodeType.PARALLEL] = Parallel
	
	self.functions[BehaviorNodeType.ACTION] = Action
	self.functions[BehaviorNodeType.CONDITION_ACTION] = ConditionAction
	
	self.functions[BehaviorNodeType.SUCCESSOR] = Successor
	self.functions[BehaviorNodeType.FAILURE] = Failure
	self.functions[BehaviorNodeType.NEGATE] = Negate
	
	self.functions[BehaviorNodeType.FILTER] = Filter
end

function Behavior:SetCurrentNode( node )
	self._checkNode = node
end

function Behavior:GetCurrentNode()
	return self._checkNode
end

function Behavior:Run( node )
	if not node then return false end
	
	self:SetCurrentNode( node )
	
	if DEBUG_LOG and node.desc then print( "desc=", node.desc, " nodes=" .. #node.children ) end	
	
	local func = self.functions[node.type]
	if func then return func( self, node ) end
	
	print( "Invalid Node Type=", node.type, func )
	return false
end

function Behavior:Random( min, max )
	return math.random( min, max )
end

function Behavior:Copy( sour )
	local dest = {}
	for k, v in pairs( sour ) do
		rawset( dest, k, v )
	end
	return dest
end

function Behavior:Shuffle( list )
	local length = #list
	if length > 1 then
		for index = 1, length do
			local target = self:Random( 1, length - 1 )
			list[index], list[target] = list[target], list[index]		
		end
	end
end

function Behavior_Test()
	data1 = 
	{
		type = "SEQUENCE", children =
		{
			{ type = "FILTER", condition = function() print( "check1" ) return false end },
			{ type = "ACTION", action = function() print( "act1" ) end },
		}
	}
	data2 = 
	{
		type = "SEQUENCE", children =
		{
			{ type = "FILTER", condition = function() print( "check2" ) return true end },
			{ type = "ACTION", action = function() print( "act2" ) end },
		}
	}
	data3 = 
	{
		type = "SEQUENCE", children = {
			data1,
			data2,
		},
	}
	data4 = 
	{
		type = "SELECTOR", children = { 		
			data1,
			data2,
		},
	}

	tree = BehaviorNode()
	tree:BuildTree( data4 )

	bev = Behavior()
	bev:Run( tree )
end