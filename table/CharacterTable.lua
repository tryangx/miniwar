CharacterPersonality = 
{
	CONSERVATIVE  = 0x1,
}

CharacterPurpose =
{
	SURVIVE       = 0,
}

CharacterTraitType = 
{
	BRAVERY       = 0,	
}

CharacterTable = class()

function CharacterTable:Load( data )
	self.id   = data.id or 0

	self.name = data.name or ""

	self.ca          = data.ca or 0

	self.pa          = data.pa or 0

	self.purpose     = data.purpose or 0

	self.traits      = data.traits or {}
	
	self.status      = data.status or CharacterStatus.NORMAL
end

function CharacterTable:ConvertID2Data( data )	
	--MathUtility_Dump( self.traits )
	local traits = {}
	for k, id in ipairs( self.traits ) do
		local trait = g_traitTableMng:GetData( id )		
		table.insert( traits, trait )
	end
	self.traits = traits
end