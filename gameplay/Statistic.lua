local DEFAULT_MAXIMUM = 999999999

Statistic = class()

function Statistic:__init()
	--Time
	self.elapsedTime = 0
	
	--Tech
	self.numOfReserachTech = 0
	self.maxNumOfResearchTech = 0
	self.minNumOfResearchTech = 0

	--Group
	self.activateGroups = {}
	self.numOfIndependenceGroup = 0
	self.fallenGroups = {}
	
	--City
	self.cities = {}
	
	--Character
	self.activateCharaList  = {}
	self.outCharacterList   = {}
	self.otherCharacterList = {}

	--Population
	self.numOfDieNatural = 0
	self.numOfBornNatural = 0
	self.pouplationUnderRule = 0
	self.totalPopulation = 0
	self.maxTotalPopulation = 0
	self.minTotalPopulation = DEFAULT_MAXIMUM

	--Combat
	self.numOfCorps = 0
	self.numOfTroop = 0
	self.numOfDieInCombat = 0
	self.numOfCombatOccured = 0
	self.numOfSoldier = 0
	self.maxNumOfSoldier = 0
	self.combatDetails = {}
	
	--Proposal
	self.submitProposals = {}
end

function Statistic:ClearCharaList()
	self.activateCharaList  = {}
	self.outCharacterList   = {}
	self.otherCharacterList = {}
end


function Statistic:SubmitProposal( desc )
	table.insert( self.submitProposals, desc )
end

-------------------------------------
-- Chara

function Statistic:AddActivateChara( chara )
	table.insert( self.activateCharaList, chara )
end
function Statistic:AddOutChara( chara )
	table.insert( self.outCharacterList, chara )
end
function Statistic:AddOtherChara( chara )
	table.insert( self.otherCharacterList, chara )
end
function Statistic:RemoveActivateChara( chara )	
	MathUtility_Remove( self.activateCharaList, chara.id, "id" )
end
function Statistic:RemoveOutChara( chara )	
	MathUtility_Remove( self.outCharacterList, chara.id, "id" )
end

function Statistic:QueryNumberOfCharaInCity( city )
	local number = 0
	for k, chara in ipairs( self.outCharacterList ) do
		if chara:GetLocation() == city then
			number = number + 1
		end
	end
	return number + #city.charas
end

-------------------------------------
-- Group
function Statistic:AddGroup( group )	
end

function Statistic:CountGroup( group )
	if not group then
		self.activateGroups = {}
		self.numOfIndependenceGroup = 0
		self.numOfReserachTech = 0
		self.maxNumOfResearchTech = 0
		self.minNumOfResearchTech = DEFAULT_MAXIMUM
		return
	end
	if group:IsIndependence() then
		self.numOfIndependenceGroup = self.numOfIndependenceGroup + 1
	end
	table.insert( self.activateGroups, group )
	
	local numOfTech = #group.techs
	self.numOfReserachTech = self.numOfReserachTech + numOfTech
	if numOfTech > self.maxNumOfResearchTech then self.maxNumOfResearchTech = numOfTech end
	if numOfTech < self.minNumOfResearchTech then self.minNumOfResearchTech = numOfTech end
end

function Statistic:CountCity( city )
	if not city then
		self.cities = {}
		self.pouplationUnderRule = 0
		return
	end
	table.insert( self.cities, city )
	
	self.pouplationUnderRule = self.pouplationUnderRule + city.population
	
	for k, corps in ipairs( city.corps ) do
		self:CountCorps( corps )
	end
	for k, troop in ipairs( city.troops ) do
		self:CountTroop( troop )
	end
end

-------------------------------------
-- Combat

function Statistic:CountCorps( corps )
	if not corps then
		self.numOfCorps = 0
		return
	end
	self.numOfCorps = self.numOfCorps + 1
end

function Statistic:CountTroop( troop )
	if not troop then
		self.numOfTroop = 0
		return
	end
	self.numOfTroop = self.numOfTroop + 1
	
	self:CountSoldier( troop.number + troop.wounded )
end

-------------------------------------

function Statistic:DieInCombat( number )	
	self.numOfDieInCombat = self.numOfDieInCombat + number
end

function Statistic:DieNatural( number )
	self.numOfDieNatural = self.numOfDieNatural + number
end

function Statistic:BornNatural( number )
	self.numOfBornNatural = self.numOfBornNatural + number
end	

function Statistic:ElapseTime( elapsedTime )
	self.elapsedTime = self.elapsedTime + elapsedTime
end

function Statistic:CountPopulation( population )	
	if not population then
		--InputUtility_Pause( self.totalPopulation )
		if self.totalPopulation > 0 and self.minTotalPopulation > self.totalPopulation then
			self.minTotalPopulation = self.totalPopulation
		end
		self.totalPopulation = 0
	else
		self.totalPopulation = self.totalPopulation + population
		if self.totalPopulation > self.maxTotalPopulation then
			self.maxTotalPopulation = self.totalPopulation
		end
	end
end

function Statistic:CombatOccured( desc )
	table.insert( self.combatDetails, desc )
	self.numOfCombatOccured = self.numOfCombatOccured + 1
end

function Statistic:CountSoldier( number )
	if not number then self.numOfSoldier = 0 return end
	self.numOfSoldier = self.numOfSoldier + number
	if self.maxNumOfSoldier < self.numOfSoldier then
		self.maxNumOfSoldier = self.numOfSoldier
	end
end

function Statistic:GroupFall( group )
	table.insert( self.fallenGroups, group.name )
end

function Statistic:Update()
	self:CountGroup( nil )
	
	self:CountCity( nil )

	self:CountPopulation( nil )
	
	self.numOfCorps = 0
	self.numOfTroop = 0
	self:CountSoldier( nil )
end

function Statistic:DumpCharaDetail()	
	function DumpList( list )
		for k, item in ipairs( list ) do
			ShowText( "", NameIDToString( item ), item.location.name, MathUtility_FindEnumName( CharacterStatus, item.status ) )
		end
	end
	ShowText( "ActChara      = ".. #self.activateCharaList )
	DumpList( self.activateCharaList )
	ShowText( "OutChara      = ".. #self.outCharacterList )
	DumpList( self.outCharacterList )
	ShowText( "OtherChara    = ".. #self.otherCharacterList )	
	DumpList( self.otherCharacterList )
end

function Statistic:Dump()
	ShowText( "Tech          = " .. self.numOfReserachTech .. "/" .. self.maxNumOfResearchTech .. "/" .. self.minNumOfResearchTech )
	
	ShowText( "Activate Group=" .. #self.activateGroups )
	for k, group in ipairs( self.activateGroups ) do
		ShowText( "", group.name, " city=" .. #group.cities, " chara="..#group.charas .. "/" .. QueryGroupCharaLimit( group ), " corps="..#group.corps.."/"..#group.troops, " soldier=" .. group:GetMilitaryPower(), " popu=" .. group:GetPopulation(), " sup="..group:GetSupply() )
		ShowText( "  proposals(".. #group.proposals ..")" )
		--group:Dump()
		for k, desc in ipairs( group.proposals ) do
			--ShowText( "", "", desc )
		end
	end	
	ShowText( "Fallen   Group:" )
	for k, name in ipairs( self.fallenGroups ) do
		ShowText( "", name )
	end
	
	ShowText( "City          = " .. #self.cities )
	for k, city in ipairs( self.cities ) do
		--city:Dump()
	end
	
	--self:DumpCharaDetail()
	
	ShowText( "Combat Occured= " .. self.numOfCombatOccured )
	for k, desc in ipairs( self.combatDetails ) do
		ShowText( "", desc )
	end	
	ShowText( "Die in Combat = " .. self.numOfDieInCombat )
	ShowText( "Soldier       = " .. self.numOfSoldier .. "/" .. self.maxNumOfSoldier )
	ShowText( "Corps         = " .. self.numOfCorps )
	ShowText( "Troop         = " .. self.numOfTroop )
	
	ShowText( "Die Natural   = " .. self.numOfDieNatural )
	ShowText( "Born Natural  = " .. self.numOfBornNatural )	
	ShowText( "Tot Population= " .. self.totalPopulation .. "/" .. self.maxTotalPopulation .. "/" .. self.minTotalPopulation .. "/" .. self.pouplationUnderRule )
	
	ShowText( "Pass time     = " .. math.floor( self.elapsedTime / 360 ) .. "Y" .. math.floor( ( self.elapsedTime % 360 ) / 30 ) .. "M" .. math.floor( self.elapsedTime % 30 ) .. "D" )
	
	--MathUtility_Dump( self.submitProposals )
end