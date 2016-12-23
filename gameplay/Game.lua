-- Blueprint
--	1. Two city in war
--
--  2. Nation( group ) in war
--
--  3. Nation diplomatic
--
--  4. Scenario Event
--
--  5. Random Scenario Event
--
--  6. Every Entity has it's purpose
--     in personally, purpose like below
--			1) survive( keep alive for a while or change some owner )
--			2) inherit( change master of a family for many times )
--			3) kill( kill enough number or special one )
--          4) honor( did special action or get a title )
--
--
----
--
-- To Do
-- 1. Support save/load defense troop like gate, wall, militia
-- [OK]2. Walk through whole game process to win
-- [OK]3. Re factor Game Prototype as recruit/build/invest/attack
-- 4. Data validation( troop.city <-> city->troop like this )
-- 5. Intelligence System, every group has a intel-lib which store other group's info detail as troop, corps, character, city, group, etc
-- [OK]6. Diplomacy System
-- Scenario Event
-- Treasure( book / antique / beauty /  )
-- Nature Diplomacy Change
--
-- ***combat will end after make peace
--
--
-- Game Flow
-- 1. Select MOD( Include configuration )
-- 2. Select scenario( Include dynamic data based on the configuration of the MOD )
-- 3. Select Role ( Now only support Group )
-- 4. Enter Game
-- 5. 
--

require "Global"

GameMode =
{
	NEW_GAME    = 1,	
	LOAD_GAME   = 1,	
	COMBAT_GAME = 2,
}

Game = class()

function Game:Dump()
	print( "ActChara=",   #g_activateCharaList )
	print( "OutChara=",   #g_outCharacterList )
	print( "OtherChara=", #g_otherCharacterList )
	
	if self._groupList then
		local findGroup	
		findGroup = nil
		for k, group in ipairs( self._groupList ) do
			if not findGroup then findGroup = group 
			elseif group:GetPower() > findGroup:GetPower() then findGroup = group
			end
		end
		print( "PowerGroup=", findGroup and ( findGroup.name .. "+" .. findGroup:GetPower() ) or "" )
		
		findGroup = nil
		for k, group in ipairs( self._groupList ) do
			if not findGroup then findGroup = group 
			elseif #group.cities > #findGroup.cities then findGroup = group
			end
		end
		print( "Terriority=", findGroup and ( findGroup.name .. "+" .. #findGroup.cities ) or "" )
	end
end

function Game:PopupSystemMenu()
	self:Dump()
	local menus = {}
	local index = 1
	if self.turn == 0 then
		table.insert( menus, { c = index, content = "New Game", fn = function()
			self:NewGame()
			self:StartGame()
		end } )		
		index = index + 1
	end
	if self.turn > 0 then
		table.insert( menus, { c = index, content = "Save", fn = function()
			self:SaveGame()
			self:PopupSystemMenu()
		end } )
		index = index + 1
	end
	table.insert( menus, { c = index, content = "Load", fn = function()
		self:LoadGame()
		self:StartGame()
	end } )
	index = index + 1
	if self.turn == 0 then
		table.insert( menus, { c = index, content = "Skirmish", fn = function()
			self:TestCombat()
		end } )
	end
	index = index + 1
	if self.turn > 0 then
		table.insert( menus, { c = nil, content = "Next Turn", fn = function()
		end } )
		index = index + 1
	end
	g_menu:PopupMenu( menus )
end

function Game:MainMenu()	
	self:PopupSystemMenu()
end

----------------------------

function Game:NewGame()
	self.winner = nil

	self.turn   = 1

	--load data from configure
	g_troopDataMng:LoadFromData( g_scenario:GetTableData( "TROOP_DATA" ) )
	g_corpsDataMng:LoadFromData( g_scenario:GetTableData( "CORPS_DATA" ) )
	g_cityDataMng:LoadFromData( g_scenario:GetTableData( "CITY_DATA" ) )
	g_groupDataMng:LoadFromData( g_scenario:GetTableData( "GROUP_DATA" ) )
	g_charaDataMng:LoadFromData( g_scenario:GetTableData( "CHARA_DATA" ) )
	g_groupRelationDataMng:LoadFromData( g_scenario:GetTableData( "GROUPRELATION_DATA" ) )
	
	--plot map
	g_plotMap:RandomMap( 10, 10 )
	g_plotMap:AllocateToCity()

	--Control Player
	local group = g_groupDataMng:GetDataByIndex( 1 )
	--self.player = g_charaDataMng:GetData( 100 )--g_charaDataMng:GetData( group:GetLeader() )
	print( "Select ["..NameIDToString( self.player ) .. "] as player's character" )
	
	--Game Mode
	self.gameMode = GameMode.NEW_GAME
end

function Game:LoadGame()
	Data_OpenInputFile( "save.txt" )
	if self.loadDatas then
		self.loadDatas = nil
	end
	self.loadDatas = {}
	Data_ParseFile( self.loadDatas )
	
	--MathUtility_Dump( datas )
	--sequence is important for dependence
	g_groupRelationDataMng:LoadFromData( self.loadDatas.relations_data )
	g_troopDataMng:LoadFromData( self.loadDatas.troops_data )
	g_corpsDataMng:LoadFromData( self.loadDatas.corps_data )
	g_cityDataMng:LoadFromData( self.loadDatas.cities_data )
	g_charaDataMng:LoadFromData( self.loadDatas.charas_data )
	g_groupDataMng:LoadFromData( self.loadDatas.groups_data )
	g_combatDataMng:LoadFromData( self.loadDatas.combats_data )
	g_plotMap:GetDataManager():LoadFromData( self.loadDatas.plots_data )	
	
	self.turn = self.loadDatas.game_data.turn
	local pid = self.loadDatas.game_data.playerid
	self.player = g_charaDataMng:GetData( pid )
	
	print( "turn=", self.turn )
	
	self.gameMode = GameMode.LOAD_GAME
end

function Game:SaveGame()
	Data_OpenOuputFile( "save.txt" )
	
	Data_OutputBegin( "game_data" )
	Data_OutputValue( "turn", self.turn )
	Data_OutputValue( "playerid", self.player and self.player.id or 0 )
	Data_OutputEnd( "game_data" )
	
	function SaveManagerData( name, mng )
		Data_OutputBegin( name )
		Data_SetIndent( 1 )
		mng:Foreach( function ( data )
			data:SaveData()
		end )	
		Data_SetIndent( -1 )
		Data_OutputEnd()
	end	
	SaveManagerData( "groups_data", g_groupDataMng )
	SaveManagerData( "cities_data", g_cityDataMng )
	SaveManagerData( "charas_data", g_charaDataMng )
	SaveManagerData( "troops_data", g_troopDataMng )
	SaveManagerData( "corps_data",  g_corpsDataMng )
	SaveManagerData( "relations_data", g_groupRelationDataMng )
	SaveManagerData( "combats_data", g_combatDataMng )
	SaveManagerData( "plots_data", g_plotMap:GetDataManager() )
	
	Data_OutputFlush()
	
	print( "Save End" )
end

function Game:Init()
	Debug_SetPrinterNode( true )
	Debug_SetFileMode( false )

	self.turn = 0
	self.maxTurn = 40
	
	local g_scenarioName = "Demo"
	package.path = package.path .. ";asset/Scenario/" .. g_scenarioName .. "/?.lua"
	require( "Scenario_" .. g_scenarioName )
	g_scenario:LoadScenario( ScenarioDemo )
		
	g_cityTableMng:LoadTable( g_scenario:GetTable( g_cityTableMng ) )	
	g_charaTableMng:LoadTable( g_scenario:GetTable( g_charaTableMng ) )
	g_traitTableMng:LoadTable( g_scenario:GetTable( g_traitTableMng ) )
	g_troopTableMng:LoadTable( g_scenario:GetTable( g_troopTableMng ) )
	g_techTableMng:LoadTable( g_scenario:GetTable( g_techTableMng ) )	
	g_constrTableMng:LoadTable( g_scenario:GetTable( g_constrTableMng ) )	
	g_groupTableMng:LoadTable( g_scenario:GetTable( g_groupTableMng ) )
	g_formationTableMng:LoadTable( g_scenario:GetTable( g_formationTableMng ) )
	g_weaponTableMng:LoadTable( g_scenario:GetTable( g_weaponTableMng ) )
	g_armorTableMng:LoadTable( g_scenario:GetTable( g_armorTableMng ) )
	g_groupRelationTableMng:LoadTable( g_scenario:GetTable( g_groupRelationTableMng ) )	
	g_battlefieldTableMng:LoadTable( g_scenario:GetTable( g_battlefieldTableMng ) )		
	
	--standard table
	g_weatherTableMng:LoadTable( Standard_Weather_TableData() )	
	g_climateTableMng:LoadTable( Standard_Climate_TableData() )			
	g_seasonTableMng:LoadTable( Standard_Season_TableData() )
	g_resourceTableMng:LoadTable( Standard_Resource_TableData() )
	g_plotTableMng:LoadTable( Standard_Plot_TableData() )
	
	-- initialize g_calendar
	g_calendar:Init( Standard_Calendar_TableData() )	
	g_calendar:SetDate( 4, 1, 2016, 1 )
	
	-- initialize g_season
	g_season:Init()
	g_season:SetDate( g_calendar.month, g_calendar.day )
		
	-- convert id to data
	g_troopTableMng:Foreach( function ( data ) 		
		data:ConvertID2Data()
	end)
		
	g_traitTableMng:Foreach( function ( data )
		data:ConvertID2Data()
	end )
	
	g_charaTableMng:Foreach( function ( data )
		data:ConvertID2Data()
	end )
	
	self:MainMenu()
end

function Game:PreprocessGameData()	
	--entity data relative
	self._groupList = {}
	g_groupDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		table.insert( self._groupList, data )
	end )
	-- Repair relation data leaks	
	local _firstGroup = self._groupList[1]
	if _firstGroup then
		for k = 2, #self._groupList do
			_firstGroup:GetGroupRelation( self._groupList[k].id )
		end
	end
	
	self._cityList      = {}
	g_cityDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		table.insert( self._cityList, data )
	end )
	g_cityDataMng:Foreach( function ( data )
		data:InitAdjacentCity()
		if self.gameMode == GameMode.NEW_GAME then
			data:Harvest()
		end
	end )
	
	self._corpsList     = {}
	g_corpsDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		table.insert( self._corpsList, data )
	end )
	
	g_activateCharaList  = {}
	g_outCharacterList   = {}
	g_otherCharacterList = {}
	g_charaDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		if data.status == CharacterStatus.NORMAL then
			table.insert( g_activateCharaList, data )	
		elseif data.status == CharacterStatus.OUT then
			table.insert( g_outCharacterList, data )
		else
			table.insert( g_otherCharacterList, data )
		end		
	end )
	
	-- data relative
	-- 1. check data validation
	-- 2. generate list
	-- 3. set default value
	
	self._troopList = {}
	g_troopDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		
		--check weapon
		if data.table then
			local hasMelee = false
			local hasWeapon = false
			for k, weapon in ipairs( data.table.weapons ) do
				hasWeapon = true
				if weapon:IsCloseWeapon() then
					hasMelee = true
					break
				end
			end
			if data:IsCombatUnit() then
				if not hasWeapon then Debug_Log( "["..data.name.."] don't have any weapon" )
				elseif not hasMelee and not data:IsSiegeUnit() then Debug_Log( "["..data.name.."] don't have melee weapon" ) end
			end
		end
		
		table.insert( self._troopList, data )
	end )
	
	self._combatList = {}
	g_combatDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		table.insert( self._combatList, data )
	end )
	
	g_groupRelationDataMng:Foreach( function ( data ) 
		data:ConvertID2Data()
	end )
	
	g_groupDataMng:Foreach( function ( data )
		--Caused by dynamic city data like percent agriculture
		data:Init()
	end )
end

function Game:StartGame()
	Debug_Log( "Start Game" )

	self:PreprocessGameData()
	
	self:Run()
end

function Game:TestCombat()	
	self:NewGame()
		
	self:PreprocessGameData()
	
	Warfare:Test( { g_corpsDataMng:GetData( 1 ) }, { g_corpsDataMng:GetData( 2 ) } )
	
	self.gameMode = GameMode.COMBAT_GAME

	--Warfare:RunOneDay()
	self:Run()
end

function Game:Run()
	while self.turn < self.maxTurn do
		--self:PopupSystemMenu()
		
		if self.gameMode == GameMode.NEW_GAME or self.gameMode == GameMode.LOAD_GAME then
			self:NextTurn()
		elseif self.gameMode == GameMode.COMBAT_GAME then
			Warfare:RunOneDay()
			--Warfare:RunOneHour()
		end
		if self.winner then break end
	end
	if self.turn >= self.maxTurn then
		for k, group in ipairs( self._groupList ) do
			group:Dump()
		end
		for k, city in ipairs( self._cityList ) do
			city:Dump()
		end
		g_taskMng:DumpResult()
	end
	if self.winner then
		InputUtility_Wait( "winner="..self.winner.name, "end" )
	end
end

----------------------------------------------

function Game:IsPlayer( chara )
	return self.player == chara
end

----------------------------------------------

function Game:NextTurn()
	--[[
		Game Turn Flow ( Ver 1.1 )
		
			Event Flow
			
			Action Flow
				Personal Flow
					Choice to attend meeting, enjoy self, have a rest, etc.
					
				Hold Meeting Flow
					Hold meeting for groups ( Presence people include all members stays in the capital )
						Political, Diplomatic, Technological
					Hold meeting for cities ( Presence people include all members stays in the city	)
					Hold meeting for corps( Presence people include all members stays in the corps )				
						
			Update Flow		
				Update Warfare
				Update Group
				Update City
				Update Corps
				Update Chara
				
		Political     = Modify Policy( Innovate ) / Faction
		Diplomatic    = Friend / Threaten / Ally / ...
		Technological = Research 
		Military      = Recruit / Train Troop / Attack / Create Corps / Modify Troop / Modify Corps / Dispatch Corps				
		Economic      = Invest / Tax / Build			
	--]]
	
	-- Notice winner
	if self.winner then
		Debug_Normal( "Winner is " .. NameIDToString( self.winner ) )
		return
	end
	
	g_calendar:PassAMonth()
	
	-- Event Flow
	-- ...
	
	-- Action Flow
	self:ActionFlow()

	self.turn = self.turn + 1
	print( "" )
	print( "####################################" )
	print( "############# Turn=" .. self.turn .. " ##############" )
	g_calendar:DumpMonthUnit()
	
	-- Update Flow
	self:Update( GlobalConst.ELPASED_TIME )
end

function Game:DrawMap()
	local map = {}
	for k, city in ipairs( self._cityList ) do
		local pos = city.position
		if not map[pos.y] then
			map[pos.y] = {} 
		end
		if map[pos.y][pos.x] then
			print( "Duplicate", city.name, map[pos.y][pos.x].name )
		end
		map[pos.y][pos.x] = city
	end
	for y = 1, 10 do
		local row = map[y]
		local content = ""
		for x = 1, 10 do			
			local city = row and row[x]
			if not city then
				content = content .. "     "
			else				
				content = content .. "<".. Helper_Abbreviate( city.name, 3 ) ..">"
			end
		end
		print( "Y=".. y, content )
	end
end

function Game:ActionFlow()	
	g_plotMap:Dump()
	self:DrawMap()
	
	-- Personal Choice
	for k, chara in ipairs( g_activateCharaList ) do
		if nil and chara == self.player then
			local cmds = {
				{ c = '1', content = "ATTEND MEETING", fn = function ()
					chara:ChoiceAction( CharacterAction.ATTEND_MEETING )
				end },
				{ c = '2', content = "ENJOY", fn = function ()
					chara:ChoiceAction( CharacterAction.ENJOY_SELF )
				end },
				{ c = '3', content = "REST", fn = function ()
					chara:ChoiceAction( CharacterAction.HAVE_REST )
				end },			
			}
			input:PopupMenu( cmds, "Please select your action" )
		else
			local action = g_globalRandomizer:GetInt( 1, 3 )		
			action = CharacterAction.ATTEND_MEETING
			chara:ChoiceAction( action )
		end
	end
	
	print( "************** Meeting Flow ******************" )
		
	-- Hold Group Meeting
	--[[]]
	MathUtility_Shuffle( self._groupList )
	local independences = {}
	for k, group  in ipairs( self._groupList ) do
		if not group:IsFallen() then
			if group:IsAchieveGoal() then self.winner = group end
			--group:DumpDiplomacyMethod()
			g_meeting:HoldGroupMeeting( self, group )
			--InputUtility_Pause( "Group meeting... " )
			--break
			if group:IsIndependence() then
				table.insert( independences, group )
			end
		else
			print( "######################gropu is fallend" .. group.name )
		end
	end
	--]]
	
	if #independences == 1 then
		self.winner = independences[1]
	end
	
	--if true or self.player then InputUtility_Pause( "City Meeting....." ) 	end
	
	-- Hold City Meeting
	for k, city in ipairs( self._cityList ) do
		--print( city.name, city ~= city:GetGroup():GetCapital(), city:GetNumOfIdleChara() )
		if city:GetGroup() and city ~= city:GetGroup():GetCapital() and city:GetNumOfIdleChara() > 0 then						
			g_meeting:HoldCityMeeting( self, city )
		end
	end	

	--[[
	-- Hold Corps Meeting
	for k, corps in ipairs( self._corpsList ) do
		corps:HoldMeeting()
	end
	]]
end

function Game:Update( elpasedTime )
	print( "************** Update Flow ******************" )
	
	local passDay = elpasedTime
	
	g_warfare:Update( elpasedTime )	
	g_diplomacy:Update( elpasedTime )	
	g_taskMng:Update( elpasedTime )	
	g_movingActorMng:Update( elpasedTime )

	for k, group in ipairs( self._groupList ) do
		print( group.name .. " mi_pow=" .. group:GetPower() )
		group:Update()
	end
	
	--InputUtility_Pause( "" )
	
	for k, city in ipairs( self._cityList ) do	
		city:Update()
	end
	for k, corps in ipairs( self._corpsList ) do
		corps:Update()
	end	
	for k, chara in ipairs( g_activateCharaList ) do
		chara:Update()
	end	
	
	--ProfileResult()
end

function Game:IssueGroupOrder( group )	
	self:Hint( '[' .. group.name .. ']' .. ' is thinking'	)
	
	--Decide next command
	g_groupAI:SetActor( group )
	g_groupAI:Run()
end

function Game:ExecuteGroupOrder( group )	
	Order_Execute( group )
end

function Game:ExecuteCityOrder( city )
	Order_Execute( city )
end

function Game:ExecuteCorpsOrder( corps )
	Order_Execute( corps )
end

function Game:ExecuteCharaOrder( chara )
	Order_Execute( chara )
end

function Game:Hint( content )
	Debug_Log( content )
end