OrderFlow = 
{
	INTERNAL_AFFAIR,
	
	DIPLOMACY,
	
	MILITARY,
	
	UPDATE,
}

OrderStatus = 
{
	WAITING_ORDER = 0,
	
	ACCEPT        = 1,
	
	EXECUTING     = 2,
	
	FINISHED      = 3,
	
	FAILED        = 4,
}

OrderType =
{
	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	NONE     = "none",

	---------------------
	-- Name : Research
	-- Flow : Internal Affair
	-- Actor: Group
	-- Args : tech
	---------------------
	RESEARCH = "research",
	
	---------------------
	-- Name : Build
	-- Flow : Internal Affair
	-- Actor: Group / City
	-- Args : city
	---------------------
	BUILD    = "build",
	
	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	--city
	INVEST   = "invest",
	
	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	--city
	TAX      = "tax",
	
	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	--city
	RECRUIT  = "recruit",
	
	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	--city
	ESTABLISH_CORPS = "establish_corps",

	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	--corps
	ATTACK   = "attack",
	
	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	--chara
	DISPATCH_CHARA = "dispatch_chara",
	--corps
	DISPATCH_CORPS = "dispatch_corps",
	
	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	-----------------------
	--group -> chara
	--args = { target, troop }
	LEAD_TROOP = "lead_troop",
		
	---------------------
	-- Name : 
	-- Flow : 
	-- Actor: 
	-- Args : 
	---------------------
	-----------------------
	--group / chara
	REST     = "rest",
}

--[[
CharacterOrder = 
{
	--diplomacy
	IMPROVE_RELATION,
	
	THREATEN        ,
	
	DECALRE_WAR     ,
	
	MAKE_TRUCE      ,
	
	--
	DISPATCH          = "dispatch",
	
	--personal
	MOVE              = "move",

	REST              = "rest",
}
]]

function Order_GetIDData( order )
	local orderIdData = {}
	if order then
		orderIdData.type   = order.type or OrderType.NONE
		orderIdData.status = order.status or OrderStatus.WAITING_ORDER
		orderIdData.args = {}
		if order.args then
			for k, v in pairs( order.args ) do
				orderIdData.args[k] = v.id
			end
		end
	else
		orderIdData.type   = OrderType.NONE
		orderIdData.status = OrderStatus.WAITING_ORDER
	end
	--MathUtility_Dump( orderIdData )
	return orderIdData
end

function Order_ConvertID2Data( order )
	local orderData = {}
	if order then
		orderData.type   = order.type or OrderType.NONE
		orderData.status = order.status or OrderStatus.WAITING_ORDER
		orderData.args   = {}
		if order.args then
			for k, v in pairs(order.args) do
				--print( "Get order id", k, v )
				if k == "group" then
					orderData.args.group = g_groupDataMng:GetData( v )
				elseif k == "city" then
					orderData.args.city = g_cityDataMng:GetData( v )
				elseif k == "chara" then
					orderData.args.chara = g_charaDataMng:GetData( v )		
				elseif k == "corps" then
					orderData.args.corps = g_corpsDataMng:GetData( v )
				elseif k == "troop" then
					orderData.args.troop = g_troopDataMng:GetData( v )
				end
			end
		end
	else
		orderIdData.type   = OrderType.NONE
		orderIdData.status = OrderStatus.WAITING_ORDER
	end
	return orderData
end

function Order_IsWaitingOrder( actor )
	return actor.order == nil or actor.order.type == 0 or actor.order.status == OrderStatus.WAITING_ORDER
end

function Order_SetStatus( actor, status )
	if actor.order then
		actor.order.status = status
	end
end

function Order_CanExecuteOrder( actor )
	if not actor.order or not actor.order.type then return false end	
	if actor.order.status == OrderStatus.EXECUTING then
		Debug_Log( "["..actor.name.."] is executing order" )
		return false		
	end
	if actor.order.status and actor.order.status ~= OrderStatus.ACCEPT then return false end	
	return true
end

function Order_Finish( actor )
	if not actor.order then return end
	if actor.order.status == OrderStatus.FINISHED or actor.order.status == OrderStatus.FAILED then
		actor.order = nil
	end
end

--[[
	Issue order
	
	It'll replace the previous order 
]]
function Order_Issue( actor, type, args )
	if not actor then Debug_Error( "Invalid actor" ) return end
	if not actor.order then actor.order = {} end
	actor.order.type   = type
	actor.order.args   = args
	actor.order.status = OrderStatus.ACCEPT
	Debug_Log( "[Issue Order]", actor.name, type, args )
end

function Order_Execute( actor )		
	if not Order_CanExecuteOrder( actor ) then return end
	
	if not actor.order then Debug_Log( "Order Invalid" ) return end
	Debug_Log( "[Order] Execute [" .. actor.name .. "] [".. MathUtility_FindEnumName( OrderType, actor.order.type ).. "]" )
	
	if actor:is_a( Group ) then
		Order_GroupExecute( actor )
	elseif actor:is_a( City ) then
		Order_CityExecute( actor )
	elseif actor:is_a( Corps ) then
		Order_CorpsExecute( actor )
	elseif actor:is_a( Character ) then		
		Order_CharacterExecute( actor )
	end
end

function Order_GroupExecute( actor )		
	local type   = actor.order.type	
	local args   = actor.order.args
	
	if type == OrderType.RESEARCH then
		GroupResearch( actor, args.tech )
		
	elseif type == OrderType.BUILD then		
		Order_Issue( args.city, OrderType.BUILD, nil )
		
	elseif type == OrderType.INVEST then
		--Debug_Log( "Invest in city [" .. args.city.name .. "]" )
		Order_Issue( args.city, OrderType.INVEST, nil )
		
	elseif type == OrderType.TAX then
		--Debug_Log( "Collect tax in city [" .. args.city.name .. "]" )
		Order_Issue( args.city, OrderType.TAX, nil )
		
	elseif type == OrderType.RECRUIT then
		--Debug_Log( "Recruit in city [" .. args.city.name .. "]" )
		Order_Issue( args.city, OrderType.RECRUIT, nil )
		
	elseif type == OrderType.ESTABLISH_CORPS then
		--Debug_Log( "Establish corps in city [" .. args.city.name .. "]" )
		Order_Issue( args.city, OrderType.ESTABLISH_CORPS, nil )
		
	elseif type == OrderType.ATTACK then
		GroupAttack( actor, args.city, args.corps )
		
	elseif type == OrderType.DISPATCH_CHARA then
		GroupDispatch( actor, args.chara, args.city )

	elseif type == OrderType.DISPATCH_CORPS then
		GroupDispatch( actor, args.corps, args.city )
				
	elseif type == OrderType.LEAD_TROOP then		
		GroupLeadTroop( actor, args.chara, args.troop )
		
	end
end

function Order_CityExecute( actor )	
	local type   = actor.order.type
	local args   = actor.order.args
	local target = args and args.target
	
	if type == OrderType.BUILD then
		CityBuild( actor )
	elseif type == OrderType.INVEST then
		CityInvest( actor )
	elseif type == OrderType.TAX then
		CityTax( actor )
	elseif type == OrderType.RECRUIT then
		CityRecruit( actor )
	elseif type == OrderType.ESTABLISH_CORPS then
		CityEsablishCorps( actor )
	end
end
function Order_CorpsExecute( actor )	
	local type   = actor.order.type
	local args   = actor.order.args
	
	if type == OrderType.ATTACK then
		CorpsAttack( actor, args.city )
	elseif type == OrderType.DISPATCH_CORPS then
		CorpsDispatch( actor, args.city )
	end
end
function Order_CharacterExecute( actor )	
	local type   = actor.order.type
	local args   = actor.order.args
	local target = args and args.target
	
	if type == OrderType.IMPROVE_RELATION then
	elseif type == OrderType.THREATEN then
	elseif type == OrderType.DECALRE_WAR then
	elseif type == OrderType.MAKE_TRUCE then
	elseif type == OrderType.DISPATCH_CHARA then
		CharaDispatch( actor, args.city )
	elseif type == OrderType.MOVE then
	elseif type == OrderType.REST then
	end
end

function GroupResearch( group, tech )
	if not tech then print( "tech is invalid" ) return end
	group.researchTechId = tech.id
	group.researchPoints = tech.points
		
	Order_SetStatus( group, OrderStatus.FINISHED )
	
	Debug_Normal( "Research " .. tech.name .. "[" ..tech.id .. "]" )
end

function GroupAttack( group, city, corps )
	--target is city	
	local corps = corps
	Order_Issue( corps, OrderType.ATTACK, { city = city } )
		
	Order_SetStatus( group, OrderStatus.FINISHED )

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
	
	Order_SetStatus( group, OrderStatus.FINISHED )
end

function GroupLeadTroop( group, chara, troop )
	chara:LeadTroop( troop )
	
	Order_SetStatus( group, OrderStatus.FINISHED )
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
	city.recruitTroopId      = 0
	city.buildConstructionId = construction.id
	city.remainBuildPoints = construction.points
				
	Order_SetStatus( city, OrderStatus.FINISHED )
		
	local constr = g_constrTableMng:GetData( city.buildConstructionId )	
	Debug_Normal( "Build [" .. constr.name .. "]("..constr.points..") in city [" .. city.name .. "]" )
end

function CityBuild( city )
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
		
		Order_SetStatus( city, OrderStatus.FINISHED )
		
		local constr = g_constrTableMng:GetData( city.buildConstructionId )
		Debug_Normal( "Build [" .. constr.name .. "]("..constr.points..") in city [" .. city.name .. "]" )
		return
	end
	
	if #constrList > 0 then
		CityBuildConstruction( constrList[1] )
		return
	end	
	Order_SetStatus( city, OrderStatus.FAILED )
end


--------------------------
-- Invest in City
-- 
--
--------------------------
function CityInvest( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end
	
	local money = Parameter.CITY_INVEST_MONEY[city.size]
	if city._group.money < money then
		money = city._group.money
	end
	city._group.money = city._group.money - Parameter.CITY_INVEST_MONEY[city.size]
	city:Invest( money )
	
	Order_SetStatus( city, OrderStatus.FINISHED )
	
	Debug_Normal( "Invest in city [" .. city.name .. "] with money [" .. money .. "]" )
end

--------------------------
-- Collect tax in City
-- 
--
--------------------------
function CityLevyTax( city )
	if not city._group then Debug_Error( "City is not belong to any group" ) return end

	city:LevyTax( 1 )
	--[[
	local taxMoney = city:GetIncome()
	city._group.money = city._group.money + taxMoney	
	
	Order_SetStatus( city, OrderStatus.FINISHED )
		
	]]
	Debug_Normal( "Collect tax in city [" .. city.name .. "]" )
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
	city.recruitTroopId      = troop.id
	city.remainRecruitPoints = troop.prerequisites.points or 0
	
	Order_SetStatus( city, OrderStatus.FINISHED )
	
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
		
	Order_SetStatus( city, OrderStatus.FAILED )
	
	Debug_Normal( "Recruit troop failed!" )
end


--------------------------
-- in City
-- 
--
--------------------------
function CityEsablishCorpsByTroop( city, idleTroopList )
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
	
	Order_SetStatus( city, OrderStatus.FINISHED )
end

function CityEsablishCorps( city )
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
				troopNum[troop.table.category] = troopNum[troop.table.category] + 1
				if not movement or movement > troop.movement then
					movement = troop.movement
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
	
	Order_SetStatus( city, OrderStatus.FINISHED )
end


function CityReinforceCorps( corps, troops )
	local content = ""
	for k, troop in ipairs( troops ) do
		corps:AddTroop( troop )
		content = content .. troop.name .. " "
	end
	
	Debug_Normal( "Reinforce ["..corps.name.."] with ["..content .."]" )
end

---------------------------------------------
--
-- Coprs execution
--
---------------------------------------------

function CorpsAttack( corps, city )
	g_warfare:AddPlan( corps, city )	
	corps.location = city
	
	Debug_Normal( "["..corps.name.."] attack ["..city.name.."]" )
	
	Order_SetStatus( corps, OrderStatus.EXECUTING )
end

function CorpsExpedition( corps, city )
	g_warfare:AddPlan( corps, city )	
	corps.location = city
	
	Debug_Normal( "["..corps.name.."] go expedition to ["..city.name.."]" )
	
	Order_SetStatus( corps, OrderStatus.EXECUTING )
end

function CorpsFinishAttack( corps )
	Order_SetStatus( corps, OrderStatus.WAITING_ORDER )
end

function CorpsDispatch( corps, city )
	corps:DispatchCity( city )
	Order_SetStatus( corps, OrderStatus.EXECUTING )
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
	city:CharaEnter( chara )
	chara:JoinGroup( city:GetGroup() )
	chara.job = CharacterJob.OFFICER
	
	MathUtility_Remove( g_outCharacterList, chara.id, "id" )
	table.insert( g_activateCharaList, chara )
	
	Debug_Normal( "Hire " .. chara.name .. " in [" .. city.name .. "]" )
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
	local oldCity = chara:GetCity()
	
	oldCity:CharaLeave( chara )
	city:CharaEnter( chara )
	
	Debug_Normal( "Call" .. chara.name .. " to [" .. oldCity.name .. "]" )
	
	Order_SetStatus( chara, OrderStatus.FINISHED )
end

function CharaDispatch( chara, city )
	chara:GetCity():CharaLeave( chara )
	city:CharaEnter( chara )	
	
	Debug_Normal( "Dispatch " .. chara.name .. " to [" .. city.name .. "]" )	

	Order_SetStatus( chara, OrderStatus.FINISHED )
end

function CharaLead( chara, troop )
	chara:LeadTroop( troop )
end