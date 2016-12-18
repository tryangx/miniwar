TechniqueTable = class()

function TechniqueTable:Load( data )
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	self.desc = data.name or ""
	
	self.points = data.points or 0
	
	self.prerequisite = MathUtility_Copy( data.prerequisite )
end