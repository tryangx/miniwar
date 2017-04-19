require "LogUtility"

local enableDebug = false
local DebugLog = nil

local function Debug_GetLog()
 	if not DebugLog then DebugLog = LogUtility( "log/debug_" .. g_gameId .. ".log", LogWarningLevel.LOG, true ) end
 	return DebugLog
end

function Debug_Level( level )
	if level then DebugLog:SetLogLevel( level ) end
end

function Debug_Normal( ... )
	if enableDebug then Debug_GetLog():WriteDebug( ... ) end
end

function Debug_Log( ... )
	if enableDebug then Debug_GetLog():WriteLog( ... ) end
end

function Debug_Error( ... )
	if enableDebug then Debug_GetLog():WriteError( ... ) end
end

function Debug_Assert( condition, ... )
	if not condition or condition() then
		Debug_GetLog():Write( ..., LogWarningLevel.LOG )
	end
end

function Debug_Enable( enable )
	enableDebug = enable
end

function Debug_SetPrinterNode( isOn )
	Debug_GetLog():SetPrinterMode( isOn )
end