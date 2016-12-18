Report = class()

function Report:__init()
	self._reports = {}
end

function Report:AddReport( id, content )
	if not self._reporters[id] then
		self._reporters[id] = { index=1, logs = {} }
	end
	
	table.insert( self._reporters[id].logs, content )
end

function Report:Brief( id )
	if not self._reporters[id] then return end
	local reporter = self._reporters[id]
	for k = reporter.index, #reporter.logs do
		Debug_Log( reporter.logs[k] )
	end
	reporter.index = #reporter.logs
end

function Report:Clear( id )
	if self._reporters[id] then
		self._reporters[id].logs = {}
		self._reporters[id].index = 1
	end
end