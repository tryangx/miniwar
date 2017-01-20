function GroupResearch( group, tech )
	if not tech then ShowText( "tech is invalid" ) return end
	group.researchTechId = tech.id
	group.researchPoints = tech.points
	
	Debug_Normal( "Research " .. tech.name .. "[" ..tech.id .. "]" )
end

function GroupAttack( group, city, corps )
	--target is city	
	local corps = corps
	Order_Issue( corps, OrderType.ATTACK, { city = city } )

	Debug_Normal( "Send corps [" .. corps.name .. "] Attack " .. city.name .. "("..city.id..")" )
	city:Dump()
end

function GroupDispatch( group, chara, city )
	--[[
	for k, chara in ipairs(args.charaList ) do
		Order_Issue( chara, OrderType.DISPATCH, { city = city } )
	end
	]]
	Order_Issue( chara, OrderType.DISPATCH_CHARA, { city = city } )	
end

function GroupLeadTroop( group, chara, troop )
	chara:LeadTroop( troop )
end

function InventTech( group, tech )
	group:InventTech( tech )
end

---------------------------------------------
--
-- City execution
--
---------------------------------------------

--------------------------
-- Build in City
-- 
--
--------------------------
function CityBuildConstruction( city, construction )
	city:BuildConstruction( construction )			

	Debug_Normal( "Build [" .. construction.name .. "]("..construction.prerequisites.points..") in city [" .. city.name .. "]" )
end

--------------------------
-- Invest in City
-- 
--
--------------------------
function CityInvest( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end	
	city:Invest()
end

function CityFarm( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end
	city:Farm()
end

function CityLevyTax( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end
	local income = city:GetIncome()
	city:LevyTax( income )
end

function CityPatrol( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end
	city:Patrol()
end

--------------------------
-- Instruct City
-- 
--
--------------------------
function CityInstruct( city, instruction )
	city.instruction = instruction
end

--------------------------
-- Recruit in City
-- 
--
--------------------------
function CityRecruitTroop( city, troopData )
	--[[
	local tableData = g_troopTableMng:GetData( troop.id )
	if not tableData then
		InputUtility_Wait( "Wrong troop table id=" .. troop.id )
		return
	end
	]]
	local troop = g_troopDataMng:GenerateData( troopData.id, g_troopTableMng )
	troop.name    = ( city:GetGroup() and city:GetGroup().name .. "-" or "" ) .. troop.name
	troop.tableId = troopData.id
	troop.table   = troopData
	troop.maxNumber = troop.maxNumber * GroupParams.RECRUIT.MAX_NUMBER_MODULUS
	troop.number  = troop.maxNumber * 0.5
	city:RecruitTroop( troop )
	
	--maybe decrease at first
	city.population = city.population - troop.number
	
	Debug_Normal( "Recruit troop [" .. NameIDToString( troop ) .."] in city [" .. city.name .. "]" )
end

function CityRecruit( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end
	
	local soldierNum = {}
	for cate = TroopCategory.CATEGORY_BEG, TroopCategory.CATEGORY_END do
		soldierNum[cate] = 0
	end
	
	local totalSoldier = 0
	for k, v in ipairs( city.troops ) do
		local cat = v.table.category		
		soldierNum[cat] = soldierNum[cat] + v.number
		totalSoldier = totalSoldier + v.number
	end
	
	local priorityList = {}
	for cate = TroopCategory.CATEGORY_BEG, TroopCategory.CATEGORY_END do
		local proportion
		if totalSoldier == 0 then
			proportion = 0
		else
			proportion = soldierNum[cate] * 100 / totalSoldier
		end
		--ShowText( Parameter.DEFAULT_TROOP_PROPORTION[cate], proportion, cate )
		local diff = Parameter.DEFAULT_TROOP_PROPORTION[cate] - proportion
		--descending
		MathUtility_Insert( priorityList, { cate = cate, diff = diff }, "diff", true )
	end

	local canRecruitTroops = {}
	--check tech requirement
	for k, v in ipairs( city._group._canRecruitTroops ) do
		local enable = true
		
		--ShowText( "!!!!!!!!!!!!!", v.prerequisites.points )
		
		--check points validation
		if not v.prerequisites.points then enable = false end	
		
		--check construction requirement
		if enable and v.prerequisites.construction and not MathUtility_IndexOf( city.constrs, v.prerequisites.construction, "id" ) then enable = false end
		
		--check money requirement
		if enable and  v.prerequisites.money and v.prerequisites.money > city._group.money then enable = false end
		
		--check resource requirement
		if enable and  v.prerequisites.resource and not MathUtility_IndexOf( city.resource, v.prerequisites.resource, "id" ) then enable = false end		
				
		if enable then table.insert( canRecruitTroops, v ) end
	end
	
	--MathUtility_Dump( priorityList )
	
	for k1, prior in ipairs( priorityList ) do			
		for k2, troop in ipairs( canRecruitTroops ) do	
			--ShowText( troop.category, prior.cate, k1, k2 )
			if troop.category == prior.cate then
				CityRecruitTroop( city, troop )
				return
			end
		end
	end
	
	Debug_Normal( "Recruit troop failed!" )
end


--------------------------
-- in City
-- 
--
--------------------------
function CharaEstablishCorpsByTroop( city, idleTroopList )
	local corps = Corps()
	corps.id = g_corpsDataMng:AllocateId()
	
	local idleTroopNum = #idleTroopList
	local troopNum = {}
	local movement = nil
	for k, troop in ipairs( idleTroopList ) do
		ShowText( "Add troop [".. NameIDToString( troop ) .."] to corps" )
		corps:AddTroop( troop )
		if not movement or movement > troop.movement then
			movement = troop.movement
		end
	end
	
	corps.location   = city
	corps.encampment = city
	corps.formation  = formation
	corps.movement   = movement
	
	corps._group = city:GetGroup()
	
	--put corps into data manager
	g_corpsDataMng:SetData( corps.id, corps )
	
	--put corps into city
	city:EstablishCorps( corps )
end

function CharaEstablishCorps( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end

	--find formation
	local formation = city._group.formations[1]
	if not formation then
		Debug_Error( "Group has none default corps formation" )
		--get default one
		formation = g_formationTableMng:GetData( 1 )
	end	
	if not formation then
		Debug_Error( "Damn it! Even default corps formation isn't exist!" )
	end
	
	local corps = Corps()
	corps.id = g_corpsDataMng:AllocateId()

	local idleTroopList = {}
	for k, troop in ipairs( city.troops ) do
		print( troop.name, troop:GetCorps() )
		if not troop:GetCorps() then
			ShowText( NameIDToString( troop ) )
			table.insert( idleTroopList, troop )
		end
	end
	local idleTroopNum = #idleTroopList
	local troopNum = {}
	for cate = TroopCategory.CATEGORY_BEG, TroopCategory.CATEGORY_END do
		troopNum[cate] = 0
	end
	local movement = nil
	for k, troop in ipairs( idleTroopList ) do
		if #corps.troops >= CorpsParams.NUMBER_OF_TROOP_MAXIMUM then break end
		corps:AddTroop( troop )
	end
	
	--[[
	local leftSlot = formation.maxTroop
	if leftSlot >= idleTroopNum then
		for k, troop in ipairs( idleTroopList ) do
			corps:AddTroop( troop )
			if troop.table then
				troopNum[troop.table.category] = troopNum[troop.table.category] + 1
				if not movement or movement > troop.movement then
					movement = troop.movement
				end
			end
		end
	else
		for k, troop in ipairs( idleTroopList ) do
			--ShowText( troopNum[troop.table.category], idleTroopNum, formation.troopProps[troop.table.category] )
			if troopNum[troop.table.category] < idleTroopNum * formation.troopProps[troop.table.category] then			
				corps:AddTroop( troop )
				troopNum[troop.table.category] = troopNum[troop.table.category] + 1
				leftSlot = leftSlot - 1
				if not movement or movement > troop.movement then
					movement = troop.movement
				end
			end
			if leftSlot <= 0 then break end
		end
	end
	]]
	corps.location   = city
	corps.encampment = city	
	corps.formation  = formation
	corps.movement   = movement
	corps._group     = city:GetGroup()
	
	--put corps into data manager
	g_corpsDataMng:SetData( corps.id, corps )
	
	--put corps into city
	city:EstablishCorps( corps )	
end

---------------------------------------------
--
-- Coprs execution
--
---------------------------------------------

function CorpsRegroup( corps, troops )
	local content = ""
	for k, troop in ipairs( troops ) do
		corps:AddTroop( troop )
		content = content .. NameIDToString( troop ) .. " "
	end
	
	Debug_Normal( "Regroup ["..corps.name.."] with ["..content .."]" )
end
function CorpsReinforce( corps )
	local city = corps:GetLocation()
	if not city then
		ShowText( a.b )
		return
	end	
	local number, totalNumber = corps:GetNumberStatus()
	local needPeople = totalNumber - number
	if city.population < needPeople then 
		ShowText( "Reinforce ["..corps.name.."] failed, not enough ["..needPeople .."/"..city.population.."]" )
		return
	end	
	local minPopulation = city:GetMinPopulation()
	local reinforcement = needPeople
	city.population = city.population - reinforcement
	corps:Reinforce( reinforcement )	
	Debug_Normal( "Reinforce ["..corps.name.."] with soldier ["..reinforcement.."] from " .. totalNumber .. " to " .. totalNumber + reinforcement )
end

function CorpsTrain( corps )
	local oldValue = 0
	local training = 0
	for k, troop in ipairs( corps.troops ) do
		local tag = troop:GetAsset( TroopTag.TRAINING )
		local current = tag and tag.value or 0
		oldValue = oldValue + current
		local delta = MathUtility_Clamp( ( TroopTag.MAX_VALUE[TroopTag.TRAINING] - current ) * TroopParams.TRAINING.TRAIN_DIFF_MODULUS + TroopParams.TRAINING.TRAIN_STANDARD_VALUE, 0, TroopTag.MAX_VALUE[TroopTag.TRAINING] )
		training = training + current + delta
		troop:AppendAsset( TroopTag.TRAINING, delta, TroopTag.MAX_VALUE[TroopTag.TRAINING] )
	end
	oldValue = math.floor( oldValue / #corps.troops )
	training = math.floor( training / #corps.troops )
	Debug_Normal( "Train ["..corps.name.."] from " .. oldValue .. "->" .. training )
end

function CorpsAttack( corps, city )
	g_warfare:AddWarfarePlan( corps, city )
	corps:MoveToLocation( city )
	
	Debug_Normal( "["..corps.name.."] attack ["..city.name.."]" )
end

function CorpsExpedition( corps, city )
	g_warfare:AddWarfarePlan( corps, city )	
	corps.location = city
	
	Debug_Normal( "["..corps.name.."] go expedition to ["..city.name.."]" )
end

function CorpsFinishAttack( corps )
end

function CorpsDispatchToCity( corps, city )
	corps:DispatchToCity( city )
end

function CorpsMoveToLocation( corps, location )
	corps:MoveToLocation( location )
end

---------------------------------------------
--
-- Character execution
--
---------------------------------------------
function CharaPromote( chara, city )
	
end

function CharaHire( chara, city )
	if chara:GetGroup() then
		InputUtility_Pause( NameIDToString( chara )  .. " already in group=" .. chara:GetGroup().name )
		return false
	end
	city:GetGroup():CharaJoin( chara )
	city:CharaLive( chara )
	chara:JoinGroup( city:GetGroup() )
	chara.job = CharacterJob.OFFICER
	
	g_statistic:RemoveOutChara( chara )
	g_statistic:AddActivateChara( chara )
	Debug_Normal( "Hire " .. chara.name .. " in [" .. city.name .. "]" )	
	--g_statistic:DumpCharaDetail()
	--InputUtility_Pause( "hire")
	return true
end

function CharaDie( chara )
	local group = chara:GetGroup()
	local isLeader = chara:IsGroupLeader()

	local city = chara:GetHome()
	city:GetGroup():CharaLeave( chara )
	city:CharaLeave( chara )
	chara:Die()
	
	g_statistic:RemoveActivateChara( chara )
	g_statistic:AddOtherChara( chara )
	
	Debug_Normal( chara.name .. " died" )
	
	if not isLeader then return end
	if #group.charas == 0 then
		--group fallen
		group:Fall()
		return
	end
	local index = Random_SyncGetRange( 1, #group.charas )
	group.leader = group.charas[index]
	--InputUtility_Pause( "Find new heri", group.leader.name )
end

function CharaExile( chara, city )
	city:GetGroup():CharaLeave( chara )
	city:CharaLeave( chara )
	chara:Out( city:GetGroup() )
	
	g_statistic:RemoveActivateChara( chara )
	g_statistic:AddOutChara( chara )
	
	--Should the character hate who exile him, to do
	
	Debug_Normal( "Exile " .. chara.name .. " in [" .. city.name .. "]" )
end

function CharaCall( chara, city )
	local home = chara:GetHome()
	
	home:CharaLeave( chara )
	city:CharaLive( chara )
	
	Debug_Normal( "Call" .. chara.name .. " to [" .. home.name .. "]" )
end

function CharaDispatch( chara, city )
	chara:GetHome():CharaLeave( chara )
	city:CharaLive( chara )	
	
	Debug_Normal( "Dispatch " .. chara.name .. " to [" .. city.name .. "]" )
end

function CharaLeadTroop( chara, troop )
	chara:LeadTroop( troop )
end

function CharaMoveToLocation( chara, location )
	chara:MoveToLocation( location )
end