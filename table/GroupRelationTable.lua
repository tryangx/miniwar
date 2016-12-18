GroupRelationTable = class()

function GroupRelationTable:Load( data )
	self.id       = data.id or 0

	--source id, make master when relationType equal Vassal / Dependence
	self.sid      = data.sid or 0
	
	--target id, means slave when relationType equal Vassal / Dependence
	self.tid      = data.tid or 0

	self.type     = GroupRelationType[data.type]
	
	self.evaluation     = data.evaluation or 0
	
	self.traits         = MathUtility_Copy( data.traits )
end