require "LogUtility"

local DebugLog = LogUtility( "debug.log", LogFileMode.WRITE_MANUAL, LogPrinterMode.OFF, LogWarningLevel.NORMAL )

function Debug_Level( level )
	if level then 
		DebugLog:SetLogLevel( LogWarningLevel.DEBUG )
	else
		DebugLog:SetLogLevel( LogWarningLevel.NORMAL )
	end
end

function Debug_Log( message )
	DebugLog:WriteLog( message, LogWarningLevel.DEBUG )
end

function Debug_Normal( message )
	DebugLog:WriteLog( message, LogWarningLevel.NORMAL )
end

function Debug_Assert( condition, message )
	if not condition then
		DebugLog:WriteLog( message, LogWarningLevel.ASSERT )
	end
end

function Debug_Error( message )
	DebugLog:WriteLog( message, LogWarningLevel.ERROR )	
end

function Debug_SetFileMode( isWriteImmediately )
	DebugLog:SetLogFileMode( isWriteImmediately )
end

function Debug_SetPrinterNode( isOn )	
	DebugLog:SetPrinterMode( isOn )
end

function Debug_Flush()
	DebugLog:Flush()
end