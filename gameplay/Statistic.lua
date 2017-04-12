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
	self.fallenCities = {}
	
	--Character
	self.activateCharaList  = {}
	self.outCharacterList   = {}
	self.otherCharacterList = {}
	self.prisonerCharacterList = {}

	--Population
	self.numOfDieNatural = 0
	self.numOfBornNatural = 0
	self.pouplationUnderRule = 0
	self.totalPopulation = 0
	self.maxTotalPopulation = 0
	self.minTotalPopulation = DEFAULT_MAXIMUM

	--Combat
	self.corpsList = {}
	self.numOfTroop = 0
	self.numOfDieInCombat = 0
	self.numOfSoldier = 0
	self.maxNumOfSoldier = 0
	self.combatDetails = {}
	self.combatLocations = {}

	--Proposal
	self.submitProposals = {}
	self.citySubmitProposals = {}
	self.acceptProposals = {}
	self.cityAcceptProposals = {}
	
	--Tasks
	self.cancelTasks= {}
	self.focusTasks = {}	

	--City Track
	self.cityTracks = {}
end

function Statistic:Start()
	self.file = SaveFileUtility()
	self.file:OpenFile( "statitstic_" .. g_gameId .. ".log", true )
end

function Statistic:DumpText( ... )
	self.file:Write( ... )
end

function Statistic:ClearCharaList()
	InputUtility_Pause( "clear chara lsit" )
	self.activateCharaList  = {}
	self.outCharacterList   = {}
	self.otherCharacterList = {}
end

-------------------------------------
-- Proposal & Task

function Statistic:SubmitProposal( desc, city )
	table.insert( self.submitProposals, desc )
	if not self.citySubmitProposals[city] then self.citySubmitProposals[city] = {} end
	table.insert( self.citySubmitProposals[city], desc )
	--print( "Submit-->>"..desc )
end

function Statistic:AcceptProposal( desc, city )
	table.insert( self.acceptProposals, desc )
	if not self.cityAcceptProposals[city] then self.cityAcceptProposals[city] = {} end
	table.insert( self.cityAcceptProposals[city], desc )
	--print( "Accept-->>"..desc )
end

function Statistic:CancelTask( desc )
	table.insert( self.cancelTasks, desc )
end

function Statistic:FocusTask( desc )
	table.insert( self.focusTasks, desc )
end

-------------------------------------
-- Chara

function Statistic:CalcOutCharaNumber( city )
	local number = 0
	for k, chara in ipairs( g_statistic.outCharacterList ) do
		if chara:GetLocation() == city then
			number = number + 1
		end
	end
	return number
end

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
function Statistic:AddPrisonerChara( chara )
	table.insert( self.prisonerCharacterList, chara )
end
function Statistic:RemovePrisonerChara( chara )
	MathUtility_Remove( self.prisonerCharacterList, chara.id, "id" )
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
end

-------------------------------------
-- Combat

function Statistic:CountCorps( corps )
	if not corps then
		self.corpsList = {}
		return
	end
	table.insert( self.corpsList, corps )
end

function Statistic:CountTroop( troop )
	if not troop then
		self.numOfTroop = 0
		return
	end
	self.numOfTroop = self.numOfTroop + 1
	
	self:CountSoldier( troop.number + troop.wounded )
end

------------------------------------

function Statistic:TrackCity( city, number )
	if not self.cityTracks[city] then self.cityTracks[city] = {} end
	local list = self.cityTracks[city]	
	local len = #list
	if len > 0 then
		if number == list[len].data then
			return
		end
	end
	table.insert( self.cityTracks[city], { data = number, desc = number .. " " .. g_calendar:CreateCurrentDateDesc( true, true ) } )
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

function Statistic:CombatOccured( desc, city )
	table.insert( self.combatDetails, desc )
	self.combatLocations[city] = self.combatLocations[city] and self.combatLocations[city] + 1 or 1
end

function Statistic:CountSoldier( number )
	if not number then self.numOfSoldier = 0 return end
	self.numOfSoldier = self.numOfSoldier + number
	if self.maxNumOfSoldier < self.numOfSoldier then
		self.maxNumOfSoldier = self.numOfSoldier
	end
end

function Statistic:GroupFall( group )
	table.insert( self.fallenGroups, group.name .. " " .. g_calendar:CreateCurrentDateDesc() )
end

function Statistic:CityFall( city, group )
	local oldGroup = city:GetGroup()
	table.insert( self.fallenCities, Helper_AbbreviateString( city.name, 12 ) .. "	" .. ( oldGroup and oldGroup.name or "Neutral" ) .. "->" .. group.name	 .. " " .. g_calendar:CreateCurrentDateDesc( true, true ) )
end

function Statistic:Update()
	self:CountGroup( nil )
	
	self:CountCity( nil )

	self:CountPopulation( nil )
	
	self.numOfTroop = 0
	self:CountSoldier( nil )
end

function Statistic:DumpCharaDetail()	
	function DumpList( list )
		for k, item in ipairs( list ) do
			self:DumpText( "	" .. item:CreateBrief() )
		end
	end
	self:DumpText( "ActChara      = ".. #self.activateCharaList )
	DumpList( self.activateCharaList )
	self:DumpText( "OutChara      = ".. #self.outCharacterList )
	DumpList( self.outCharacterList )
	self:DumpText( "OtherChara    = ".. #self.otherCharacterList )	
	DumpList( self.otherCharacterList )
	self:DumpText( "PrisonerChara = ".. #self.prisonerCharacterList )	
	DumpList( self.prisonerCharacterList )
end

function Statistic:Dump()
	self:DumpText( "Tech          = " .. self.numOfReserachTech .. "(tot)/" .. self.maxNumOfResearchTech .. "(max)/" .. self.minNumOfResearchTech .. "(min)" )
	
	self:DumpText( "Activate Group=" .. #self.activateGroups )
	for k, group in ipairs( self.activateGroups ) do
		local content = group.name .. " city=" .. #group.cities.."("..group:GetPlotNumber()..")" .. " chara="..#group.charas .. "/" .. QueryGroupCharaLimit( group ) .. " corps="..#group.corps.. " troops="..#group.troops .. " soldier=" .. group:GetMilitaryPower() .. " popu=" .. group:GetPopulation()
		content = content .. " MilServ=" .. group:GetMilitaryService()
		self:DumpText( "	" .. content )
		local deps = group:GetDependencyRelations()
		if #deps > 0 then
			self:DumpText( "    Dep=" )
			for k, relation in ipairs( deps ) do if relation._targetGroup then self:DumpText( "        " .. relation._targetGroup.name .. "+" .. relation._targetGroup:GetPower() .. " " .. MathUtility_FindEnumName( GroupRelationType, relation.type ) ) end end		
		end
		group:Dump()
		self:DumpText( "	Group Proposals(".. #group.proposals ..")" )		
		--for k, desc in ipairs( group.proposals ) do self:DumpText( "	" .. "	" .. desc ) end
	end	

	self:DumpText( "City          = " .. #self.cities ) 
	--for k, city in ipairs( self.cities ) do city:DumpBrief( nil, true ) city:DumpCorpsBrief() end

	--self:DumpCharaDetail()
	
	self:DumpText( "Cancel Task   = " .. #self.cancelTasks )
	--MathUtility_Dump( self.cancelTasks )
	
	MathUtility_Dump( self.focusTasks )

	self:DumpText( "Fallen   Group:" ) for k, desc in ipairs( self.fallenGroups ) do self:DumpText( "	" .. desc ) end
	
	self:DumpText( "Fallen   City:" ) for k, desc in ipairs( self.fallenCities ) do self:DumpText( "	" .. desc ) end	
	self:DumpText( "Combat Occured= " .. #self.combatDetails )
	for k, desc in ipairs( self.combatDetails ) do self:DumpText( "	" .. desc ) end
	
	self:DumpText( "Die in Combat = " .. self.numOfDieInCombat )
	self:DumpText( "Soldier       = " .. self.numOfSoldier .. "(cur)/" .. self.maxNumOfSoldier .. "(max)" )
	self:DumpText( "Corps         = " .. #self.corpsList )
	self:DumpText( "Troop         = " .. self.numOfTroop )
	
	self:DumpText( "Die Natural   = " .. self.numOfDieNatural )
	self:DumpText( "Born Natural  = " .. self.numOfBornNatural )	
	self:DumpText( "Tot Population= " .. self.totalPopulation .. "/" .. self.maxTotalPopulation .. "(max)/" .. self.minTotalPopulation .. "(min)/" .. self.pouplationUnderRule .. "(city)" )
	
	self:DumpText( "Pass time     = " .. math.floor( self.elapsedTime / 360 ) .. "Y" .. math.floor( ( self.elapsedTime % 360 ) / 30 ) .. "M" .. math.floor( self.elapsedTime % 30 ) .. "D" )
	
	self:DumpText( "Cur Time      = " .. g_calendar:CreateCurrentDateDesc( true, true ) )
	
	self:DumpText( "Seed          = " .. g_syncRandomizer:GetSeed() .. "," .. g_asyncRandomizer:GetSeed() )

	for k, city in ipairs( self.cities ) do
		if not self.combatLocations[city] then
			self:DumpText( city.name .. " occured_combat=" .. ( self.combatLocations[city] and self.combatLocations[city] or "0" ) )
		end
	end

	self:DumpText( "Submit Proposal:" )
	for city, list in pairs( self.citySubmitProposals ) do
		self:DumpText( city.name .. "=" .. #list )
		--for k, desc in ipairs( list ) do self:DumpText( "	" .. desc ) end
	end

	self:DumpText( "Accept Proposal:" )
	for city, list in pairs( self.cityAcceptProposals ) do
		self:DumpText( city.name .. "=" .. #list )
		--for k, desc in ipairs( list ) do self:DumpText( "	" .. desc ) end
	end

	self:DumpText( "City Track" )
	for city, list in pairs( self.cityTracks ) do
		self:DumpText( city.name .. "=" .. #list )
		--for k, data in ipairs( list ) do self:DumpText( "	" .. data.desc ) end
	end

	if self.file then self.file:CloseFile() end
end