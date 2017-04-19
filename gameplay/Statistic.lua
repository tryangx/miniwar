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
	self.groupTracks = {}
	
	--City
	self.cities = {}
	self.fallenCities = {}
	self.cityTracks = {}
	
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
	self.troopList = {}
	self.numOfDieInCombat = 0
	self.numOfSoldier = 0
	self.maxNumOfSoldier = 0
	self.combatDetails = {}
	self.combatLocations = {}
	
	--Tasks
	self.cancelTasks= {}
	self.focusTasks = {}

	--Map Track
	self.mapCityTracks = {}
end

function Statistic:Start()
	self.file = SaveFileUtility()
	self.file:OpenFile( "log/statitstic_" .. g_gameId .. ".log", true )
end

function Statistic:DumpText( ... )
	--print( ... )
	self.file:Write( ... )
end

function Statistic:ClearCharaList()
	InputUtility_Pause( "clear chara lsit" )
	self.activateCharaList  = {}
	self.outCharacterList   = {}
	self.otherCharacterList = {}
end

-------------------------------------

function Statistic:TrackMap()
	local date = g_calendar:GetDateValue()
	local timeline = { date = date, list = {} }	
	g_cityDataMng:Foreach( function ( city )
		local content = ""
		local c1, c2
		if city:GetGroup() then
			c1 = Helper_AbbreviateString( city:GetGroup().name, 3 )
			c2 = Helper_CreateNumberDesc( city:GetPower(), 2 ) .. "/" .. #city.charas
			--c2 = city:GetNumOfFreeChara() .. "/" .. #city.charas
			--c2 = #city.corps
		else
			c1 = Helper_AbbreviateString( "[N]", 3 )
			c2 = city.guards
		end
		local c3 = ""
		if g_warfare:GetExistCombat( city ) then
			c3 = c3 .. "!"
		end
		if city:GetTag( CityTag.BATTLEFRONT ) then
			c3 = c3 .. "B"
		elseif city:GetTag( CityTag.FRONTIER ) then
			c3 = c3 .. "F"
		end

		if city:GetTag( CityTag.INDANGER ) then
			c3 = c3 .. "D"
		end
		if city:GetTag( CityTag.WEAK ) then
			c3 = c3 .. "W"
		end
		if city:GetTag( CityTag.EXPANDABLE ) then
			--c3 = c3 .. "A"
		end
		if city:GetTag( CityTag.SAFE ) then
			--c3 = c3 .. "S"
		end
		if city:GetTag( CityTag.PREPARED ) then
			c3 = c3 .. "P"
		end
		if city:GetTag( CityTag.CONNECTED ) then
			c3 = c3 .. "C"
		else
			if city:GetGroup() and city:GetGroup():GetCapital() ~= city then InputUtility_Pause( city.name ) end
		end
		if city:GetTag( CityTag.UNDERSTAFFED ) then
			c3 = c3 .. "E"
		end
		if city:HasOutsideCorps() then
			c3 = c3 .. "*"
		end
		if city:GetTag( CityTag.ACCEPT_PROPOSAL ) then
			--c3 = c3 .. "="
		end
		if city:GetTag( CityTag.SUBMIT_PROPOSAL ) then
			--c3 = c3 .. "+"
		end
		content = c1 .. Helper_AbbreviateString( c2, 6 ) .. Helper_AbbreviateString( c3, 6 )
		timeline.list[city] = content
	end )
	table.insert( self.mapCityTracks, timeline )
end

-------------------------------------
-- Track

function Statistic:TrackGroup( desc, group )
	desc = desc .. g_calendar:CreateCurrentDateDesc()
	ShowText( desc )
	if not self.groupTracks[group] then self.groupTracks[group] = {} end
	table.insert( self.groupTracks[group], desc )
end

function Statistic:TrackCity( desc, city )
	desc = desc .. g_calendar:CreateCurrentDateDesc()
	ShowText( desc )
	if not self.cityTracks[city] then self.cityTracks[city] = {} end
	table.insert( self.cityTracks[city], desc )
end

function Statistic:SubmitProposal( desc, city )
	--self:TrackCity( "Submit-->" .. desc, city )
end

function Statistic:AcceptProposal( desc, city )
	self:TrackCity( "Accept-->" .. desc, city )
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

	if g_calendar:GetMonth() == 1 and g_calendar:GetDay() == 1 then
		self:TrackGroup( group.name .. " pow=" .. group:GetPower(), group )
	end
	
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
		self.troopList = {}
		return
	end
	table.insert( self.troopList, troop )
	
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
	
	self:CountPopulation( nil )

	self:CountCity( nil )

	self:CountCorps( nil )
	
	self:CountTroop( nil )
	
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
	end	

	self:DumpText( "City          = " .. #self.cities ) 
	for k, city in ipairs( self.cities ) do city:DumpBrief( nil, true ) city:DumpCorpsBrief() end

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
	self:DumpText( "Troop         = " .. #self.troopList )
	
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

--[[
	self:DumpText( "Submit Proposal:" )
	for city, list in pairs( self.citySubmitProposals ) do
		self:DumpText( city.name .. "=" .. #list )
		--for k, desc in ipairs( list ) do self:DumpText( "	" .. desc ) end
	end

	self:DumpText( "Accept Proposal:" )
	for city, list in pairs( self.cityAcceptProposals ) do
		self:DumpText( city.name .. "=" .. #list )
		for k, desc in ipairs( list ) do self:DumpText( "	" .. desc ) end
	end
	]]

	self:DumpText( "Group Track" )
	for group, list in pairs( self.groupTracks ) do
		self:DumpText( group.name .. "=" .. #list )
		for k, desc in ipairs( list ) do self:DumpText( "	" .. desc ) end
	end

	self:DumpText( "City Track" )
	for city, list in pairs( self.cityTracks ) do
		self:DumpText( city.name .. "=" .. #list )
		for k, desc in ipairs( list ) do self:DumpText( "	" .. desc ) end
	end

	self:DumpText( "Map City Timeline" )
	for k, data in pairs( self.mapCityTracks ) do
		local desc = g_calendar:CreateDateDescByValue( data.date ) 
		self:DumpText( desc )
		--for city, v in pairs( data.list ) do self:DumpText( "	" .. city.name .. "=" .. v ) end
		g_gameMap:DrawData( data.list, desc, function ( ... )
			self:DumpText( ... )
		end )
	end

	if self.file then self.file:CloseFile() end
end