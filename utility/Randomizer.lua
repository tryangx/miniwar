Randomizer = class()

function Randomizer:__init( seed )
	self.seed = 0
end

function Randomizer:GetSeed( seed )
	return self.seed
end

function Randomizer:SetSeed( seed )
	self.seed = seed
end

function Randomizer:GetInt( min, max )
	self.seed = ( self.seed * 32765 + 12345 ) % 2147483647
	if min < max then
		return self.seed % ( max - min ) + min
	elseif min > max then
		return self.seed % ( min - max ) + max
	end
	return min
end