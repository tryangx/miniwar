local _profileItems = {}

function ProfileStart( name )
	local item = _profileItems[name]
	if not item then
		item = { 
			name = name,
			totalTime = 0, 
			totalCount = 0,
			maxDuration = 0,
			minDuration = 999999999,
		}
		_profileItems[name] = item
	end
	
	item.startTime = os.clock()
	--print( os.time(), os.clock() )
end

function ProfileEnd( name )
	local item = _profileItems[name]
	if item then
		item.endTime = os.clock()
		
		local duration = item.endTime - item.startTime
		if item.maxDuration < duration then
			item.maxDuration = duration
		end
		if item.minDuration > duration then
			item.minDuration = duration
		end
		item.totalTime = item.totalTime + duration
		item.totalCount = item.totalCount + 1
	end
end

function ProfileResult()
	print( "================ Profile Result ==============" )
	for k, item in pairs( _profileItems ) do
		print( "Profile Item [" .. item.name .. "] Count = " .. item.totalCount )
		print( "  Duration ( Avg / Min / Max ) = " .. string.format( "%0.2f", item.totalTime / item.totalCount ) .. " / " .. string.format( "%0.2f", item.minDuration ) .. " / " .. string.format( "%0.2f", item.maxDuration ) )
	end
end