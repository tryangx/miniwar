require "FileUtility"

LogUtility = class()

LogFileMode =
{
	WRITE_MANUAL      = 1,
	
	WRITE_IMMEDIATELY = 2,	
}

LogPrinterMode = 
{
	OFF = 1,
	
	ON  = 2,
}

LogWarningLevel = 
{
	DEBUG  = 0,

	NORMAL = 1,
	
	ASSERT = 50,
	
	ERROR  = 100,
}

function LogUtility:__init( fileName, fileMode, printerMode, logLevel, isAppend )
	self.logs = {}
	self.logIndex = 1
	
	self.fileUtility = nil
	self.fileMode    = fileMode or LogFileMode.WRITE_MANUAL
	self.printerMode = printerMode or LogPrinterMode.OFF	
	self.logLevel    = logLevel
	self.isAppend    = isAppend	
	self:SetLogFile( fileName )
end

function LogUtility:SetLogFile( fileName )
	if not self.fileUtility then
		self.fileUtility = SaveFileUtility()
		self.fileUtility:SetMode( self.isAppend )
	end
	if fileName then
		self.fileUtility:OpenFile( fileName )
	end
end

function LogUtility:SetLogFileMode( immediately )
	if immediately == true then
		self.fileMode = LogFileMode.WRITE_IMMEDIATELY
	else
		self.fileMode = LogFileMode.WRITE_MANUAL
	end
end

function LogUtility:SetPrinterMode( isOn )		
	if isOn then
		self.printerMode = LogPrinterMode.ON
	else
		self.printerMode = LogPrinterMode.OFF
	end
end

function LogUtility:SetLogLevel( level )
	self.logLevel = level
end

function LogUtility:WriteLog( content, level )	
	if not content then return end
	if level >= LogWarningLevel.NORMAL and level < LogWarningLevel.ASSERT then
		content = "[LOG] " .. content
	elseif level >= LogWarningLevel.ASSERT and level < LogWarningLevel.ERROR then	
		content = "[ASSERT] " .. content
	elseif level >= LogWarningLevel.ERROR then
		content = "[ERROR] " .. content
	else
		content = "[DEBUG] " .. content
	end
	if self.printerMode == LogPrinterMode.ON then
		if self.logLevel and self.logLevel <= level then
			ShowText( content )
		end
	end
	if self.fileMode == LogFileMode.WRITE_IMMEDIATELY then
		self.fileUtility:WriteContent( content .. "\n" )
		self.fileUtility:ReopenFile()
	end
	table.insert( self.logs, content )
end

function LogUtility:Flush()	
	if self.fileUtility then
		self.fileUtility:ReopenFile()
		local len = #self.logs
		print( "Flush", len, self.fileUtility:IsOpen() )
		for i = self.logIndex, len do		
			self.fileUtility:WriteContent( self.logs[i] .. "\n" )
		end
		self.logIndex = len		
		self.fileUtility:CloseFile()
	end
end

function LogUtility:Clear()
	self.logs = {}
	self.logIndex = 1
end