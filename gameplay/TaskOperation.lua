function GroupResearch( group, tech )
	if not tech then print( "tech is invalid" ) return end
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

function CityBuildAuto( city )
	if city.recruitTroopId ~= 0 then
		Debug_Error( "City is recruiting" )
	end
	if city.buildConstructionId ~= 0 then
		Debug_Error( "City is building" )
	end
			
	--calculate priority
	--supply->economy->military->culture	
	local priorityTrait = ConstructionTrait.SUPPLY
	if city._supplyConsume / city._supplyIncome < Parameter.SAFETY_CITY_SUPPLY_CONSUME_RATIO then
		priorityTrait = ConstructionTrait.SUPPLY
	elseif city.economy / city.maxEconomy < Parameter.SAFETY_CITY_ECONOMY_RATIO then
		priorityTrait = ConstructionTrait.ECONOMY
	elseif city:GetMilitaryPower() < Parameter.SAFETY_CITY_MILITARY_POWER[city.size] then
		priorityTrait = ConstructionTrait.MILITARY
	elseif city:GetTraitPower() / Parameter.SAFETY_CITY_CULTURE_POWER[city.size] then
		priorityTrait = ConstructionTrait.CULTURE
	end	
	
	local constrList = city:GetBuildList()
	local priorityConstrList = {}	
	table.sort( constrList, function( left, right )
		return left.points < right.points 
	end )
	for k, constr in ipairs( constrList ) do
		if priorityTrait == constr.trait then			
			table.insert( priorityConstrList, constr )
		end
	end
	
	--print( #constrList, #priorityConstrList )
	
	--process with priority construction list
	if #priorityConstrList > 0 then
		city.recruitTroopId      = 0
		city.buildConstructionId = priorityConstrList[1].id
		city.remainBuildPoints = priorityConstrList[1].points
		
		local constr = g_constrTableMng:GetData( city.buildConstructionId )
		Debug_Normal( "Build [" .. constr.name .. "]("..constr.points..") in city [" .. city.name .. "]" )
		return
	end
	
	if #constrList > 0 then
		CityBuildConstruction( constrList[1] )
		return
	end	
end


--------------------------
-- Invest in City
-- 
--
--------------------------
function CityInvest( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end
	
	city:Invest()
	
	Debug_Normal( "Invest in city [" .. city.name .. "]" )
end

--------------------------
-- Collect tax in City
-- 
--
--------------------------
function CityLevyTax( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end

	local income = city:GetIncome()
	city:LevyTax( income )
	
	--Debug_Normal( "Collect tax in city [" .. city.name .. "] with money ["..income.."]" )
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
function CityRecruitTroop( city, troop )
	local tableData = g_troopTableMng:GetData( troop.id )
	if not tableData then
		InputUtility_Wait( "Wrong troop table id=" .. troop.id )
		return
	end
	local troop = g_troopDataMng:GenerateData( troop.id, g_troopTableMng )
	troop.tableId = troop.id
	troop.table   = tableData
	troop.number  = troop.maxNumber
	city:RecruitTroop( troop )
	
	--maybe decrease at first
	city.population = city.population - troop.number
	
	Debug_Normal( "Recruit troop [" .. troop.name .."] in city [" .. city.name .. "]" )
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
		--print( Parameter.DEFAULT_TROOP_PROPORTION[cate], proportion, cate )
		local diff = Parameter.DEFAULT_TROOP_PROPORTION[cate] - proportion
		--descending
		MathUtility_Insert( priorityList, { cate = cate, diff = diff }, "diff", true )
	end

	local canRecruitTroops = {}
	--check tech requirement
	for k, v in ipairs( city._group._canRecruitTroops ) do
		local enable = true
		
		--print( "!!!!!!!!!!!!!", v.prerequisites.points )
		
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
			--print( troop.category, prior.cate, k1, k2 )
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
		print( "Add troop ["..troop.name.."] to corps" )
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
		if not troop:GetCorps() then
			table.insert( idleTroopList, troop )
		end
	end
	local idleTroopNum = #idleTroopList
	local troopNum = {}
	for cate = TroopCategory.CATEGORY_BEG, TroopCategory.CATEGORY_END do
		troopNum[cate] = 0
	end
	local movement = nil
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
			--print( troopNum[troop.table.category], idleTroopNum, formation.troopProps[troop.table.category] )
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

function CorpsReinforce( corps, troops )
	local content = ""
	for k, troop in ipairs( troops ) do
		corps:AddTroop( troop )
		content = content .. troop.name .. " "
	end
	
	Debug_Normal( "Reinforce ["..corps.name.."] with ["..content .."]" )
end

function CorpsAttack( corps, city )
	g_warfare:AddPlan( corps, city )	
	corps:MoveToLocation( city )
	
	Debug_Normal( "["..corps.name.."] attack ["..city.name.."]" )
end

function CorpsExpedition( corps, city )
	g_warfare:AddPlan( corps, city )	
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
	city:GetGroup():CharaJoin( chara )
	city:CharaLive( chara )
	chara:JoinGroup( city:GetGroup() )
	chara.job = CharacterJob.OFFICER
	
	MathUtility_Remove( g_outCharacterList, chara.id, "id" )
	table.insert( g_activateCharaList, chara )
	
	Debug_Normal( "Hire " .. chara.name .. " in [" .. city.name .. "]" )
	
	return true
end

function CharaExile( chara, city )
	city:GetGroup():CharaLeave( chara )
	city:CharaLeave( chara )
	chara:Out( city:GetGroup() )
	
	MathUtility_Remove( g_activateCharaList, chara.id, "id" )
	table.insert( g_outCharacterList, chara )
	
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