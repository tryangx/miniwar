local _PATH = (...):match('^(.*[%./])[^%.%/]+$') or ''

BehaviorNodeType = 
{
	INVALID           = 0,

	-------------------------
	-- Composite Node
	
	-- Run all nodes in given sequence one by one until any node return true, default return false
	SELECTOR          = 100,
	
	-- Run all nodes in random sequence one by one until any node return true, default return false
	RANDOM_SELECTOR   = 101,
	
	-- Run all nodes in given sequence one by one, return false when any node return false, default return true
	SEQUENCE          = 120,
	
	-- Run all nodes in given sequence one by one, 
	--PARALLEL          = 130,	
	
	------------------------
	
	------------------------
	-- Behaviour Node
	
	-- Execute the action, always return true
	ACTION            = 210,
	
	-- Execute the action until condition return true or none condition, after that return true, default return false
	CONDITION_ACTION  = 220,
	
	------------------------
	
	------------------------
	-- Decorator Node
	--
	SUCCESSOR         = 310,
	
	FAILURE           = 320,
	
	NEGATE            = 330,	
	
	------------------------
	
	------------------------
	-- Condition Node
	
	-- Return the result of condition
	FILTER            = 410,
}

BehaviorNodeStatus = 
{
	IDLE      = 0,
	RUNNING   = 1,
	COMPLETED = 2,
}

BehaviorNode = class()

function BehaviorNode:__init( type, desc )
	self.type      = type	
	self.desc      = desc
	self.children  = {}
	self.status    = BehaviorNodeStatus.IDLE
	self.action    = nil
	self.condition = nil
	self.params    = nil
end

function BehaviorNode:SetActionNode( action )
	self.type = BehaviorNodeType.ACTION
	self.func = action
end

function BehaviorNode:SetConditionActionNode( condition, action )
	self.type = BehaviorNodeType.CONDITION_ACTION
	self.func = action
	self.condition = condition
end

function BehaviorNode:SetFilterNode( filter )
	self.type = BehaviorNodeType.FILTER
	self.condition = filter
end

function BehaviorNode:AppendChild( child )
	table.insert( self.children, child )
end

function BehaviorNode:GetFirstChild()
	return self.children[1]
end

--[[
	@usage
		data = 
		{
			type = "RANDOM_SELECTOR", desc = "Root", children = 
			{
				--military
				{ 
					type = "CONDITION_ACTION", desc = "military", condition = function() print( "check military" ) end, action = function() print( "execute military" ) end, children = {},
				},
				--develop
				{
					type = "CONDITION_ACTION", desc = "develop", condition = function() print( "check develop" ) end, action = function() print( "execute develop" ) end, children = {},
				},
			},
		}
		node = BehaviorNode()
		node:BuildTree( data )
--]]
function BehaviorNode:BuildTree( data )
	if not data then return end
	
	-- Base information
	--print( data.type, data.desc, data.condition, data.action )
	self.type = BehaviorNodeType[ string.upper (data.type)]
	self.desc = data.desc
	
	-- Extension
	self.params = data.params
	
	-- Node type
	if self.type == BehaviorNodeType.ACTION then
		self.action = data.action
	elseif self.type == BehaviorNodeType.CONDITION_ACTION then
		self.action    = data.action
		self.condition = data.condition
	elseif self.type == BehaviorNodeType.CONDITION_PARAMS_ACTION then
		self.action    = data.action
		self.condition = data.condition
	elseif self.type == BehaviorNodeType.FILTER then
		self.condition = data.condition
	end
	
	-- Children nodes
	--print( 'build node', self.type, self.desc )
	if data.children then
		for k, childData in ipairs( data.children ) do
			local child = BehaviorNode()
			child:BuildTree( childData )
			self:AppendChild( child )
			--print( 'append child', child.type, child.desc )
		end
	end
end