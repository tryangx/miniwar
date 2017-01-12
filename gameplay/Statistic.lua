Statistic = class()

function Statistic:__init()
	--Time
	self.elapsedTime = 0

	--Group
	self.numOfIndependenceGroup = 0

	--Population
	self.numOfDieNatural = 0
	self.numOfBornNatural = 0
	self.totalPopulation = 0

	--Combat
	self.numOfDieInCombat = 0
	self.numOfCombatOccured = 0
end

function Statistic:DieInCombat( number )
	self.numOfDieInCombat = self.numOfDieInCombat + number
end

function Statistic:DieNatural( number )
	self.numOfDieNatural = self.numOfDieNatural + number
end

function Statistic:BornNatural( number )
	self.numOfBornNatural = self.numOfBornNatural + number
end

function Statistic:ElapseTime( elapsedTime )
	self.elapsedTime = self.elapsedTime + elapsedTime
end

function Statistic:CalcPopulation( population )
	if not population then self.totalPopulation = 0
	else self.totalPopulation = self.totalPopulation + population end 
end

function Statistic:CombatOccured()
	self.numOfCombatOccured = self.numOfCombatOccured + 1
end

function Statistic:Dump()
	print( "Pass time     =" .. math.floor( self.elapsedTime / 360 ) .. "Y" .. math.floor( ( self.elapsedTime % 360 ) / 30 ) .. "M" .. math.floor( self.elapsedTime % 30 ) .. "D" )
	
	print( "Combat Occured=" .. self.numOfCombatOccured )
	print( "Die in Combat =" .. self.numOfDieInCombat )
	
	print( "Die Natural   =" .. self.numOfDieNatural )
	print( "Born Natural  =" .. self.numOfBornNatural )	
	print( "Tot Population=" .. self.totalPopulation )
end