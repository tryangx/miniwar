SeasonType =
{
	SPRING = 0,
	
	SUMMER = 1,
	
	AUTUMN = 2,
	
	WINTER = 3,
}

SeasonTable = class()

function SeasonTable:Load( data )
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	self.type = data.type or SeasonType.SPRING
	
	self.dawnTime = data.dawnTime or 0
	
	self.duskTime = data.duskTime or 0
	
	self.startMon = data.startMon or 0
	
	self.startDay = data.startDay or 0
	
	self.endMon   = data.endMon or 0
	
	self.endDay   = data.endDay or 0
	
	self.nextType = data.nextType or SeasonType[self.nextType]
end