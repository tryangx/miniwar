TechniqueTable = class()

function TechniqueTable:Load( data )
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	self.desc = data.name or ""
		
	self.prerequisites = MathUtility_Copy( data.prerequisites )
end