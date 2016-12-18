CorpsFormationTable = class()

function CorpsFormationTable:Load( data )	
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	self.minTroop = data.minTroop or 1
	
	self.maxTroop = data.maxTroop or 1

	self.troopProps = data.troopProps
end