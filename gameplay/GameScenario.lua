GameScenario = class()

function GameScenario:__init()
	self.id   = 0	
	self.name = 0
	self.begdate = { year = 2000, month = 1, day = 1 }
	
	self.tables = {}
	self.fucs   = {}
end


function GameScenario:LoadScenario( g_scenario )
	self.id   = g_scenario.id
	self.name = g_scenario.name
	self.begdate = g_scenario.begdate
	if g_scenario.tables then
		for k, info in pairs( g_scenario.tables ) do
			if info.data then
				self.tables[k] = info.data()
			end
		end
	end
	
	self.funcs = MathUtility_ShallowCopy( g_scenario.functions )
end

function GameScenario:GetBegDate()
	return self.begdate
end

function GameScenario:GetTable( tableMng )
	if not tableMng then 
		Debug_Error( "Table manager is invalid!" )
		return nil
	end
	return self:GetTableData( tableMng:GetTableName() )
end

function GameScenario:GetTableData( name )	
	if not name then return nil	end
	local data = self.tables[name]	
	if data and data then
		return data
	end
	Debug_Error( "Invalid table [" .. name .. "] data" )
	return nil
end

function GameScenario:CallFunction( funcName, params )
	local func = self.funcs[funcName]
	if func then
		return func( params )
	else
		InputUtility_Pause( "No func=" .. funcName )
	end
	return nil
end