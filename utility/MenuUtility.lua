MenuUtility = class()

function MenuUtility:__init()
	--[[
	self.Keys = { 
		{ c = 'c', name = "Test Button", fn = function ()
				print( "test" )
			end }
	}
	]]
	self.checks = nil
	self.minSelection = 1
end

function MenuUtility:SetHint( hint )
	self.hint = hint
end

function MenuUtility:SetKeys( keys )	
	self.keys = keys
end

----------------------------------

function MenuUtility:ShowMenu( multi )
	self.defaultKey = nil
	for k, key in pairs( self.keys ) do
		if key.c then
			print( "["..key.c.."]" .. ( key.content and key.content or "" ) )
		else
			self.defaultKey = key
		end
	end
end

function MenuUtility:ShowMultiMenu()
	for k, key in pairs( self.keys ) do
		if key.c then
			local status = "o"
			if not self.checks[k] or self.checks[k] == 0 then
				status = "-"
			end
			print( "{" .. status .. "}["..key.c.."]" .. key.content )
		end
	end	
	print( "[X]End" )
end

----------------------------------

function MenuUtility:SingleSelect()
	if #self.keys == 0 then return end
	print( "@Make your choice:" )
	local c = InputUtility_ReceiveInput()
	for k, key in pairs( self.keys ) do
		if self.defaultKey and c == "" then
			self.defaultKey.fn( key )			
			return self.defaultKey.ret or true
		elseif key.c then
			if c == string.upper( key.c ) or c == string.lower( key.c ) then
				key.fn( key )
				return key.ret or true
			end
		end
	end
	return self:SingleSelect()
end

function MenuUtility:MultiSelect()
	if #self.keys == 0 then return end
	self:ShowMultiMenu( true )
	print( "@Make your choice:" )
	local c = InputUtility_ReceiveInput()
	for k, key in pairs( self.keys ) do
		if c == string.upper( key.c ) or c == string.lower( key.c ) then
			key.fn( key )
			--print( self.checks[k] )
			if not self.checks[k] or self.checks[k] == 0 then
				self.checks[k] = 1
			elseif self.checks[k] == 1 then
				self.checks[k] = 0
			end
			return self:MultiSelect()
		end
		if c == "x" or c == "X" then
			local count = 0
			for k, check in ipairs( self.checks ) do
				if check == 1 then count = count + 1 end
			end
			if count < self.minSelection then
				print( "At least choice [" .. self.minSelection .. "] selection" )
				return self:MultiSelect()
			end
			return false
		end
	end
	return self:MultiSelect()
end

-- Single Option
function MenuUtility:PopupMenu( keys, title )
	if #keys <= 0 then return end
	print( "========== Single Menu ===========" )
	if title then print( "### " .. title .. " ###" ) end	
	if self.hint then print( self.hint ) end
	self:SetKeys( keys )
	self:ShowMenu()
	self:SingleSelect()
end

-- Multile Option
function MenuUtility:PopupMultiSelMenu( keys, title, minOptions )
	if #keys <= 0 then return end
	print( "========= Multi Menu ==========" )
	if title then print( "### " .. title .. " ###" ) end	
	if self.hint then print( self.hint ) end
	if minOptions and minOptions > 1 then
		self.minSelection = minOptions
	else
		self.minSelection = 1
	end
	print( "[Select Options At least]=", self.minSelection )
	self.checks = {}
	self:SetKeys( keys )	
	self:MultiSelect()
end