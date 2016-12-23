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
	
	if type == MovingActorType.CHARACTER then
	elseif type == MovingActorType.CORPS then
	elseif type == MovingActorType.TROOP then
	elseif type == MovingActorType.REFUGEE then	
		self.location = self.data.location
		self.remainTime = -1
	elseif type == MovingActorType.BARBARIAN then
	elseif type == MovingActorType.CASH_TRUCK then
		self.location    = self.data.location
		self.destination = self.data.group:GetCapital()		
		self.remainTime  = CalcSpendTimeOnRoad( self.location, self.destination )
	else
		self.status = MovingActorStatus.SUSPENDED
		return
	end
	--print( MathUtility_FindEnumName( MovingActorType, type ) .. " " .. self.remainTime, "next" )	
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

function MovingActorManager:AddMovingActor( actorType, data )
	local list = self:GetList( actorType )
	if data.id and list[data.id] then
		--InputUtility_Wait( "Moving actor is exist! id=" .. data.id )
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
	
	print( "new moving actor=".. actor.id, MathUtility_FindEnumName( MovingActorType, actorType ), actor.location and actor.location.name or "", actor.destination and actor.destination.name or "" )
end

function MovingActorManager:Dump()
	print( ">>>>>>>>>>>>>>>>>MovingActor Statistic" )
	for actorType, list in pairs( self.lists ) do
		local len = MathUtility_CountLength( list )
		--if len > 0 then
			print( MathUtility_FindEnumName( MovingActorType, actorType ) .. "=" .. len )
		--end
	end
	print( "<<<<<<<<<<<<<<<<" )
end

function MovingActorManager:Update( elapsedTime )
	for actorType, list in pairs( self.lists ) do
		local removeList = {}
		for id, actor in pairs( list ) do
			actor:Update( actorType, elapsedTime )
			if actor:IsFinished() then
				table.insert( removeList, actor )
			end
		end
		for k, actor in ipairs( removeList ) do
			print( MathUtility_FindEnumName( MovingActorType, actorType ) .. " id=" .. actor.id .. " finished" )
			MathUtility_RemoveAndReserved( list, actor )
		end		
		removeList = nil
	end
	
	self:Dump()
end