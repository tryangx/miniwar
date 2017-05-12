--[[
	Moving Actor
	
	Corps / Character / Refugee

]]

MovingActorType = 
{
	CHARACTER  = 10,
	CORPS      = 20,
	TROOP      = 21,	
	REFUGEE    = 30,	
	BARBARIAN  = 40,
	CASH_TRUCK = 50,
}

MovingActorStatus = 
{
	NONE      = 0,
	MOVING    = 1,
	SUCCESSED = 2,
	FAILED    = 3,
	SUSPENDED = 4,
}

MovingActor = class()

function MovingActor:__init()
	self.id          = nil
	self.data        = nil
	self.location    = nil
	self.destination = nil
	self.remainTime  = 0
	self.status      = MovingActorStatus.NONE
end

function MovingActor:Init( type )
	self.status      = MovingActorStatus.MOVING
	self.remainTime  = -1
	if type == MovingActorType.CHARACTER then
	elseif type == MovingActorType.CORPS then
	elseif type == MovingActorType.TROOP then
	elseif type == MovingActorType.REFUGEE then	
		self.location = self.data.location		
	elseif type == MovingActorType.BARBARIAN then
	elseif type == MovingActorType.CASH_TRUCK then
		self.location    = self.data.location
		self.destination = self.data.group:GetCapital()		
		self.remainTime  = CalcSpendTimeOnRoad( self.location, self.destination )
	else
		self.status = MovingActorStatus.SUSPENDED
		return
	end
	--ShowText( MathUtility_FindEnumName( MovingActorType, type ) .. " " .. self.remainTime, "next" )	
end
	
function MovingActor:Update( type, elapsedTime )
	if self.status == MovingActorStatus.SUSPENDED then return end
	
	if self.remainTime < 0 then return end
	
	if self.remainTime > elapsedTime then
		self.remainTime = self.remainTime - elapsedTime
		return
	end

	if type == MovingActorType.CHARACTER then
	elseif type == MovingActorType.CORPS then
	elseif type == MovingActorType.TROOP then
	elseif type == MovingActorType.REFUGEE then	
	elseif type == MovingActorType.BARBARIAN then
	elseif type == MovingActorType.CASH_TRUCK then
		self.data.group:ReceiveTax( self.data.number, self.location )
	end
	
	self.status      = MovingActorStatus.SUCCESSED
end

function MovingActor:IsFinished()
	return self.status == MovingActorStatus.SUCCESSED or self.status == MovingActorStatus.FAILED
end

----------------------------------

MovingActorManager = class()


function MovingActorManager:__init()
	self.allocateId = 0
	self.lists = {}
end

function MovingActorManager:Load()

end
function MovingActorManager:Save()

end

function MovingActorManager:GetList( type )
	local list = self.lists[type]
	if not list then
		list = {}
		self.lists[type] = list
	end
	return list
end

function MovingActorManager:HasActor( actorType, actor )
	local list = self:GetList( actorType )
	return list and list[actor.id] ~= nil
end

function MovingActorManager:RemoveActor( actorType, actor )
	local list = self:GetList( actorType )
	if list and actor then
		list[actor.id] = nil
		ShowText( "remove moving actor=", NameIDToString( actor ) )
	end
end

function MovingActorManager:AddActor( actorType, actor, data )
	local m
	local list = self:GetList( actorType )
	m = list[actor.id]
	if actor.id and m then
		ShowDebug( "exist moving actor=", m.data and m.data.reason or "", NameIDToString( actor ) )
		InputUtility_Pause( "Add Move Actor=" .. NameIDToString( actor ), ( data and data.reason or "" ) )
		k.p = 1
		return false
	end
	m = MovingActor()
	m.id = actor.id
	m.data = data
	list[m.id] = m
	ShowText( "add moving actor=", NameIDToString( actor ), m.data and m.data.reason or "" )
	return true
end

function MovingActorManager:CreateActor( actorType, data )
	local list = self:GetList( actorType )
	if data.id and list[data.id] then
		InputUtility_Pause( "Create Moving actor is exist! id=" .. data.id )
		return
	end
	local actor = MovingActor()	
	actor.data = data
	actor:Init( actorType )
	if not actor.id then
		self.allocateId = self.allocateId + 1
		actor.id = self.allocateId
	end
	list[actor.id] = actor
	
	--ShowText( "create moving actor=".. actor.id, MathUtility_FindEnumName( MovingActorType, actorType ), actor.location and actor.location.name or "", actor.destination and actor.destination.name or "" )
end

function MovingActorManager:Dump()
	ShowText( ">>>>>>>>>>>>>>>>>MovingActor Statistic" )
	for actorType, list in pairs( self.lists ) do
		local len = MathUtility_CountLength( list )
		--if len > 0 then
			ShowText( MathUtility_FindEnumName( MovingActorType, actorType ) .. "=" .. len )
		--end
	end
	ShowText( "<<<<<<<<<<<<<<<<" )
end

function MovingActorManager:Update( elapsedTime )
	for actorType, list in pairs( self.lists ) do
		for id, actor in pairs( list ) do
			actor:Update( actorType, elapsedTime )
			if actor:IsFinished() then
				--ShowText( MathUtility_FindEnumName( MovingActorType, actorType ) .. " id=" .. actor.id .. " finished" )
				list[id] = nil
			end
		end
	end
	
	self:Dump()
end