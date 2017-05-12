HistroyEventType = 
{
	SIEGE_COMBAT_OCCURED = 1,
	FIELD_COMBAT_OCCURED = 2,
	HIRE_CHARACTER       = 3,
}

Chronicle = class()

function Chronicle:__init()
	self.events = {}
	self.eventTimeline = {}
end

function Chronicle:GetList( type )
	local typeList = self.events[type]
	if not typeList then
		typeList = {}
		self.events[type] = typeList
	end
	return typeList
end

function Chronicle:RecordEvent( type, desc, date )
--	local typeList = self:GetList( type )
--	table.insert( typeList, { desc = desc, date = date } )
	table.insert( self.eventTimeline, { type = type, desc = desc, date = date } )
end

function Chronicle:BrowseEvent( type )
	self.file = SaveFileUtility()
	self.file:OpenFile( "log/chronicle_" .. g_gameId .. ".log", true )	
	for k, event in ipairs( self.eventTimeline ) do
		if not type or type == event.type then
			self.file:Write( MathUtility_FindEnumName( HistroyEventType, event.type ) .. "," .. event.desc .. "," .. Calendar:CreateDateDescByValue( event.date ) )
		end
	end
end