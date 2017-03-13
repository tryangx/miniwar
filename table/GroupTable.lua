GroupTable = class()

function GroupTable:Load( data )

	self.id        = data.id or 0
	
	self.name      = data.name or ""

	--------------------------------------
	-- basic
	
	-- Organization form, like empire, kingdom, region, etc
	self.government = GroupGovernment[data.government] or GroupGovernment.NONE
	
	-- Winning Condition
	self.goals     = data.goals or {}
	
	-- Capital id / pointer
	self.capital   = data.capital or nil
	
	--Use to produce / recruit / research / invest
	self.money     = data.money or 0

	--Diplomatic Relation
	self.relations = data.relations or {}
	
	--------------------------------------
	-- Additional Data	
	self.cities    =  data.cities or {}
	
	self.corps     =  data.corps or {}
	
	self.troops    =  data.troops or {}
	
	self.charas    =  data.charas or {}
	
	self.techs     =  data.techs or {}
	
	self.formations =  data.formations or {}
end