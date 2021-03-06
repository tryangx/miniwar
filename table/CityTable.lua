CityTable = class()

function CityTable:Load( data )
	self.id = data.id or 0
	
	self.name = data.name or ""
	
	-----------------------------------
	-- Map
	
	self.adjacentCities = data.adjacentCities or {}
	
	-----------------------------------
	-- Basic Attributes

	--self.size        = CitySize[data.size] or CitySize.CITY
	
	self.status      = data.status or {}
	
	-----------------------------------
	-- extension
	
	--Culture circle
	--More deep effects
	self.cultrueCircle = data.cultureCircle or 0
	
	--political point
	self.politicalPoint = data.politicalPoint or 0
	
	--Trait
	--Type-Value datas
	self.traits      = data.traits or {}
	
	-----------------------------------
	-- additional datas
	
	--Character
	self.charas      = data.charas or {}
		
	--Garrison Troops
	self.troops      = data.troops or {}
	
	--Construction 
	self.constrs     = data.constrs or {}
	
	--Resource around
	self.resources   = data.resources or {}
	
	--Corps
	self.corps       = data.corps or {}
end