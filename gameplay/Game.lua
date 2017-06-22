--[[
	Explore
	Exploit
	Expand
	Exterminate
]]
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
-- To Do
-- 1. Support save/load defense troop like gate, wall, militia
-- 2. Intelligence System, every group has a intel-lib which store other group's info detail as troop, corps, character, city, group, etc
-- 3. Scenario Event
-- 4. Treasure( book / antique / beauty /  )
-- 5. 
--
--

require "Global"

Game = class()

function Game:Dump()
--[[
	if self._groupList then
		local findGroup	
		findGroup = nil
		for k, group in ipairs( self._groupList ) do
			if not findGroup then findGroup = group 
			elseif group:GetPower() > findGroup:GetPower() then findGroup = group
			end
		end
		ShowText( "PowerGroup=", findGroup and ( findGroup.name .. "+" .. findGroup:GetPower() ) or "" )
		
		findGroup = nil
		for k, group in ipairs( self._groupList ) do
			if not findGroup then findGroup = group 
			elseif #group.cities > #findGroup.cities then findGroup = group
			end
		end
		ShowText( "Terriority=", findGroup and ( findGroup.name .. "+" .. #findGroup.cities ) or "" )
	end
	]]
end

function Game:PopupSystemMenu()
	self:Dump()
	local menus = {}
	local index = 1
	if self.turn == 0 then
		table.insert( menus, { c = index, content = "New Game", fn = function()
			self:NewGame()
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
	end } )
	index = index + 1
	if self.turn == 0 then
		table.insert( menus, { c = index, content = "Skirmish", fn = function()
			self:TestCombat()
		end } )
		index = index + 1
	end
	--if self.turn > 0 then
		table.insert( menus, { c = index, content = "View Data", fn = function()
			self:ViewData()
		end } )
		index = index + 1
	--end
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

function Game:ViewData()
	self:TestWeapon()
end

function Game:ViewTroopTable()
	g_troopTableMng:Foreach( function ( troop )
		if troop.category >= TroopCategory.CATEGORY_BEG and troop.category <= TroopCategory.CATEGORY_END then
			ShowText( "---------------------------" )
			ShowText( NameIDToString( troop ) )
			for k, weapon in ipairs( troop.weapons ) do
				ShowText( "  [WEAPON] " .. weapon.name .. " pow=" .. weapon.power .. " weight=" .. weapon.weight )
			end
			for k, armor in ipairs( troop.armors ) do
				ShowText( "  [ARMOR] " .. armor.name .. " protection=" .. armor.protection .. " weight=" .. armor.weight )
			end
		end
	end )
end

function Game:TestWeapon()
	g_weaponTableMng:Foreach( 
		function ( weapon )
			if weapon.id < 400 then
				g_armorTableMng:Foreach( function ( armor )					
					local dmg = Combat:CalcWeaponDamage( 200, weapon, armor )					
					ShowText( weapon.name .. " VS " .. armor.name .. " num=" .. 200 .. " dmg=" .. dmg .. " times=" .. Combat:CalcAttackTimes( weapon ) )
					ShowText( "-----------------")
				end )
			end
		end
	)
end

----------------------------

function Game:NewGame()
	self.winner = nil

	self.turn   = 0

	--Load data from configure
	g_troopDataMng:LoadFromData( g_scenario:GetTableData( "TROOP_DATA" ) )
	g_corpsDataMng:LoadFromData( g_scenario:GetTableData( "CORPS_DATA" ) )
	g_cityDataMng:LoadFromData( g_scenario:GetTableData( "CITY_DATA" ) )
	g_groupDataMng:LoadFromData( g_scenario:GetTableData( "GROUP_DATA" ) )
	g_charaDataMng:LoadFromData( g_scenario:GetTableData( "CHARA_DATA" ) )
	g_groupRelationDataMng:LoadFromData( g_scenario:GetTableData( "GROUPRELATION_DATA" ) )
	
	--Plot map
	--g_plotMap:RandomMap( 10, 10 )
	g_plotMap:RandomMap( 72, 72 )
	g_plotMap:AllocateToCity()

	--Choice Player
	local group = g_groupDataMng:GetDataByIndex( 1 )
	--self.player = g_charaDataMng:GetData( 100 )--g_charaDataMng:GetData( group:GetLeader() )
	ShowText( "Select ["..NameIDToString( self.player ) .. "] as player's character" )
	
	--Game Mode
	g_gameMode = GameMode.SCENARIO_GAME

	self:StartGame()
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
	
	ShowText( "turn=", self.turn )
	
	g_gameMode = GameMode.SCENARIO_GAME

	self:StartGame()
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
	
	ShowText( "Save End" )
end

function Game:Init()
	Debug_SetPrinterNode( false )

	self.turn = 0
	self.maxTurn = 3*12*5

	g_gameEvent:InitData()
	
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
	local begdate = g_scenario:GetBegDate()
	g_calendar:SetDate( begdate.year, begdate.month, begdate.day, begdate.hour, begdate.bc )
	
	-- initialize g_season
	g_season:Init( g_calendar, g_seasonTableMng )
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
end

function Game:PreprocessGameData()	
	--entity data relative
	
	--1st Group Data
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
	
	--2nd City Data
	self._cityList      = {}
	g_cityDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		table.insert( self._cityList, data )
	end )
	g_cityDataMng:Foreach( function ( data )
		data:InitAdjacentCity()
		if g_gameMode == GameMode.SCENARIO_GAME then
			data:Harvest()
		end
	end )
	
	--3rd Corps Data
	self._corpsList     = {}
	g_corpsDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		table.insert( self._corpsList, data )
	end )
	
	--4th Chara Data
	g_charaDataMng:Foreach( function ( data )
		data:ConvertID2Data()
		if data.status == CharacterStatus.NORMAL then
			g_statistic:AddActivateChara( data )
		elseif data.status == CharacterStatus.OUT then
			g_statistic:AddOutChara( data )
		elseif data.status == CharacterStatus.PRISONER then
			g_statistic:AddPrisonerChara( data )
		else
			g_statistic:AddOtherChara( data )
		end		
	end )
	
	-- data relative
	-- 1. check data validation
	-- 2. generate list
	-- 3. set default value
	
	-- 5th Troop Data
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
	end )

	g_cityDataMng:Foreach( function ( city )
		for k, adjaCity in ipairs( city.adjacentCities ) do
			local found = false
			for k2, otherCity in ipairs( adjaCity.adjacentCities ) do
				if city == otherCity then
					found = true
					break
				end
			end
			if not found then
				print( "not found ", city.name, " in ", adjaCity.name )
			end
		end
	end)
	
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

----------------------------------------------

function Game:IsGameEnd()
	return self.turn >= self.maxTurn or self.winner
end

function Game:IsPlayer( chara )
	return self.player == chara
end

function Game:IsPlayerGroup( group )
	return self.player:GetGroup() == group
end

----------------------------------------------

function Game:StartGame()
	g_statistic:Start()
	self:PreprocessGameData()	
	self:Run()
end

function Game:TestCombat()	
	--self:NewGame()

	self:PreprocessGameData()
	
	local atkCorps = GenerateCorps( { 1000, 1000, 1000, 1000, 1002 } )
	local defCorps = GenerateCorps( { 1000, 1000, 1000, 1000, 1003 } )
	
	Warfare:Test( { atkCorps }, { defCorps } )
	
	g_gameMode = GameMode.COMBAT_GAME

	self:Run()
end

function Game:End()
	for k, group in ipairs( self._groupList ) do
		group:Dump()
	end
	for k, city in ipairs( self._cityList ) do
		if city:GetGroup() then
			city:Dump()
		end
	end
	g_taskMng:DumpResult()
	g_diplomacy:DumpResult()
	g_movingActorMng:Dump()
	g_statistic:Dump()
	g_gameMap:DrawAll()	
	g_chronicle:BrowseEvent()
	if self.winner then
		InputUtility_Pause( "winner="..self.winner.name )
	end
end

function Game:Run()
	if g_gameMode == GameMode.SCENARIO_GAME then
		while self.turn < self.maxTurn do
			self:NextTurn()			
			if self.winner then break end
		end
		if self.turn >= self.maxTurn or self.winner then self:End() end
	elseif g_gameMode == GameMode.COMBAT_GAME then
		while g_warfare:GetCombatCount() > 0 do
			g_warfare:RunOneDay()
		end
	end
	
end

----------------------------------------------

function Game:NextTurn()
	if self.winner then
		Debug_Normal( "Winner is " .. NameIDToString( self.winner ) )
		EndShowText()
		return
	end
	
	self.turn = self.turn + 1

	local elapsedTime = GlobalConst.ELPASED_TIME
	g_statistic:ElapseTime( elapsedTime )	
	g_calendar:ElapseDay( elapsedTime )		
	ShowImpText( "############# Turn=" .. self.turn .. " " .. g_calendar:CreateCurrentDateDesc( true ) .. " seed=" .. g_syncRandomizer:GetSeed(), g_asyncRandomizer:GetSeed() )
	
	-- Event Flow	
	g_gameEvent:Trigger()
	
	-- Update Flow
	self:Update( elapsedTime )

	self:HoldMeeting()
end

function Game:Update( elpasedTime )
	ShowText( "************** Update Flow ******************" )
	local passDay = elpasedTime
	
	g_statistic:Update()	
	g_statistic:TrackMap()

	g_warfare:Update( elpasedTime )	
	g_diplomacy:Update( elpasedTime )	
	g_taskMng:Update( elpasedTime )	
	g_movingActorMng:Update( elpasedTime )
	g_plotMap:Update( elpasedTime )
	
	for k, group in ipairs( self._groupList ) do
		group:Update()
		g_statistic:CountGroup( group )
	end	
	for k, city in ipairs( self._cityList ) do		
		city:Update()
		g_statistic:CountCity( city )
		g_charaTemplate:CheckNumOfCharaInCity( city )
	end
	g_corpsDataMng:Foreach( function ( data )
		data:Update()
		g_statistic:CountCorps( data )
	end )
	g_troopDataMng:Foreach( function ( data )
		data:Update()
		g_statistic:CountTroop( data )
	end )
	for k, chara in ipairs( g_statistic.activateCharaList ) do
		chara:Update( elapsedTime )
	end
	g_charaTemplate:Update( elapsedTime )
	--ProfileResult()

	--InputUtility_Pause( "" )
end

function Game:HoldMeeting()	
	--g_gameMap:DrawPowerMap()

	--[[
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
			local action = Random_SyncGetRange( 1, 3 )		
			action = CharacterAction.ATTEND_MEETING
			chara:ChoiceAction( action )
		end
	end
	]]
	
	ShowText( "************** Meeting Flow ******************" )
		
	-- Hold Group Meeting
	--[[]]
	MathUtility_Shuffle( self._groupList )
	local removeGroupNum = 0
	local independences = {}
	for k, group  in ipairs( self._groupList ) do
		if not group:IsFallen() then
			if HaveAchievedGroupFinalGoal( group ) then 
				self.winner = group
			end
			group:SetShortTermGoal()
			--group:DumpDiplomacyMethod()
			--g_meeting:HoldGroupMeeting( self, group )
			--InputUtility_Pause( "Group meeting... " )
			--break
			if group:IsIndependence() then
				table.insert( independences, group )
			end
		else
			g_statistic:GroupFall( group )
			g_diplomacy:RemoveGroupRelation( group )
			self._groupList[k] = nil
			removeGroupNum = removeGroupNum + 1
		end
	end
	if removeGroupNum > 0 then self._groupList = MathUtility_NewList( self._groupList ) end
	
	--if #independences == 1 then self.winner = independences[1] end
	
	--if true or self.player then InputUtility_Pause( "City Meeting....." ) 	end
	
	-- Hold City Meeting
	for k, city in ipairs( self._cityList ) do
		if city:GetGroup() and not city:GetGroup():IsFallen() then
			g_meeting:HoldCityMeeting( self, city )
		end
	end	

	--[[
	-- Hold Corps Meeting
	for k, corps in ipairs( self._corpsList ) do
		corps:HoldMeeting()
	end
	]]
	
	--execute immediately task
	--g_taskMng:Update( 0 )
end