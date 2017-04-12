require "FileUtility"

LogUtility = class()

LogWarningLevel = 
{
	DEBUG  = 0,

	LOG    = 1,
		
	ERROR  = 100,
}

function LogUtility:__init( fileName, logLevel, isPrintLog )
	self.logs = {}
	self.logIndex = 1
	
	self.fileUtility = nil
	self.isPrintLog  = isPrintLog or false
	self.logLevel    = logLevel or LogWarningLevel.LOG

	self:SetLogFile( fileName )
end

function LogUtility:SetLogFile( fileName )
	if not self.fileUtility then self.fileUtility = SaveFileUtility() end
	self.fileUtility:OpenFile( fileName, true )
end

function LogUtility:SetPrinterMode( isOn )		
	self.isPrintLog = isOn
end

function LogUtility:SetLogLevel( level )
	self.logLevel = level
end

function LogUtility:WriteContent( content, level )
	if level <= LogWarningLevel.DEBUG then
		content = "[DEBUG] " .. content
	elseif level <= LogWarningLevel.LOG then
		content = "[LOG] " .. content
	elseif level <= LogWarningLevel.ERROR then
		content = "[ERROR] " .. content
	end
	--print( self.isPrintLog, self.logLevel, level )
	if self.isPrintLog == true and self.logLevel and self.logLevel <= level then print( content ) end
	
	self.fileUtility:WriteContent( content .. "\n" )
	table.insert( self.logs, content )
end

function LogUtility:ConvertContent( ... )
	args = { ... }
	if #args == 0 then return end

	local content = ""
	for i = 1, #args do
		local type = typeof( args[i] )
		if type == "string" or type == "number" then
			content = content .. args[i]
		end
	end
	return content
end

function LogUtility:WriteDebug( ... )
	self:WriteContent( self:ConvertContent( ... ), LogWarningLevel.DEBUG )
end
function LogUtility:WriteLog( ... )
	self:WriteContent( self:ConvertContent( ... ), LogWarningLevel.LOG )
end
function LogUtility:WriteError( ... )
	self:WriteContent( self:ConvertContent( ... ), LogWarningLevel.ERROR )
end

function LogUtility:Clear()
	self.logs = {}
	self.logIndex = 1
end