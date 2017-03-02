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
		CityBuildAuto( actor )
	elseif type == OrderType.INVEST then
		CityInvest( actor )
	elseif type == OrderType.TAX then
		CityTax( actor )
	elseif type == OrderType.RECRUIT then
		CityRecruit( actor )
	elseif type == OrderType.ESTABLISH_CORPS then
		CharaEstablishCorps( actor )
	end
end
function Order_CorpsExecute( actor )	
	local type   = actor.order.type
	local args   = actor.order.args
	
	if type == OrderType.ATTACK then
		CorpsAttack( actor, args.city )
	elseif type == OrderType.DISPATCH_CORPS then
		CorpsDispatchToCity( actor, args.city )
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
		CharaDispatchToCity( actor, args.city )
	elseif type == OrderType.MOVE then
	elseif type == OrderType.REST then
	end
end

---------------------------

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