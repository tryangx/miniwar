TroopTable = class()

function TroopTable:Load( data )

	self.id   = data.id or 0
	
	self.name = data.name or ""
		
	self.category = data.category and TroopCategory[data.category] or TroopCategory.FOOTSOLDIER
	
	------------------------------------
	-- Attributes
	
	self.startLine = data.startLine and TroopStartLine[data.startLine] or TroopStartLine.FRONT
	
	self.radius    = data.radius or 0
	
	self.level     = data.level or 0
	
	-- New Tech/Theory will support troop to combined together thant maxnumber also increase
	self.maxNumber = data.maxNumber or 0
	
	self.maxMorale = data.maxMorale or 0
		
	self.capacity  = data.capacity or 0
		
	self.movement  = data.movement or 0
	
	--Consume food
	self.consume   = data.consume or 0
	
	--Maintain money
	self.salary    = data.salary or 0
	
	self.traits    = data.traits or {}
	
	------------------------------------
	-- Equipment
	self.weapons    = MathUtility_Copy( data.weapons )
	self.armors     = MathUtility_Copy( data.armors )
	
	------------------------------------
	-- Requirement
	self.prerequisites = MathUtility_Copy( data.prerequisites )
end

function TroopTable:ConvertID2Data()
	local weapons = {}
	for k, id in pairs( self.weapons ) do
		table.insert( weapons, g_weaponTableMng:GetData( id ) )
	end	
	self.weapons = weapons
	
	local armors = {}
	for k, id in pairs( self.armors ) do
		table.insert( armors, g_armorTableMng:GetData( id ) )
	end	
	self.armors = armors
	
	local traits = {}
	for k, id in ipairs( self.traits ) do
		local trait = g_traitTableMng:GetData( id )		
		table.insert( traits, trait )
	end
	self.traits = traits
end