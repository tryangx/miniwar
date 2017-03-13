CharacterFamilyName = 
{
	{ name="Zhao", prob=15 },
	{ name="Qian", prob=10 },
	{ name="Sun",  prob=20 },
	{ name="Li",   prob=25 },
	{ name="Zhou", prob=15 },
	{ name="Wu",   prob=15 },
	{ name="Zhen", prob=10 },
	{ name="Wang", prob=20 },	
}

CharacterGivenName = 
{
	{ name="I", prob=10 },
	{ name="II", prob=10 },
	{ name="III", prob=10 },
	{ name="IV", prob=10 },
	{ name="V", prob=10 },
	{ name="VI", prob=10 },
	{ name="VII", prob=10 },
	{ name="VIII", prob=10 },
	{ name="IX", prob=10 },
	{ name="XI", prob=10 },	
	{ name="XII", prob=10 },
	{ name="XIII", prob=10 },
	{ name="XIV", prob=10 },
	{ name="XV", prob=10 },
	{ name="XVI", prob=10 },
	{ name="XVII", prob=10 },
	{ name="XVIII", prob=10 },
	{ name="XIX", prob=10 },
	{ name="XX", prob=10 },
	--[[
	{ name="YI", prob=10 },
	{ name="ER", prob=10 },
	{ name="SAN", prob=10 },
	{ name="SI", prob=10 },
	{ name="WU", prob=10 },
	{ name="LIU", prob=10 },
	{ name="QI", prob=10 },
	{ name="BA", prob=10 },
	{ name="JIU", prob=10 },
	{ name="SHI", prob=10 },	
	{ name="SHIYI", prob=10 },
	{ name="ERER", prob=10 },
	{ name="SANSAN", prob=10 },
	{ name="SISI", prob=10 },
	{ name="WUWU", prob=10 },
	{ name="LIULIU", prob=10 },
	{ name="QIQI", prob=10 },
	{ name="BABA", prob=10 },
	{ name="JIUJIU", prob=10 },
	]]
}

CharacterTemplate = class()

function CharacterTemplate:__init()
	self.usedName = {}
	self.cityList = {}
	
	self.numOfName = 0
	
	self.familyNameProb = 0
	self.givenNameProb  = 0
	self.retryTime = 0
	self.generateChara = 0
end

function CharacterTemplate:GenerateName()
	if self.familyNameProb == 0 then
		for k, data in ipairs( CharacterFamilyName ) do
			self.familyNameProb = self.familyNameProb + data.prob
		end
	end
	if self.givenNameProb == 0 then
		for k, data in ipairs( CharacterGivenName ) do
			self.givenNameProb = self.givenNameProb + data.prob
		end
	end
	local prob, familyNameId, givenNameId	
	prob = Random_SyncGetRange( 1, self.familyNameProb )
	for k, data in ipairs( CharacterFamilyName ) do
		if prob <= data.prob then
			familyNameId = k 
			break
		else
			prob = prob - data.prob
		end
	end
	prob = Random_SyncGetRange( 1, self.givenNameProb )
	for k, data in ipairs( CharacterGivenName ) do
		if prob <= data.prob then
			givenNameId = k 
			break
		else
			prob = prob - data.prob
		end
	end
	local id = givenNameId * 100000 + familyNameId
	if self.usedName[id] and self.retryTime < 10 then
		self.retryTime = self.retryTime + 1
		return self:GenerateName()
	end
	self.usedName[id] = true
	local familyName = CharacterFamilyName[familyNameId].name
	local givenName = CharacterGivenName[givenNameId].name
	local finalName = familyName .. " " .. givenName	
	if self.retryTime > 10 then
		finalName = finalName .. self.numOfName
	else
		self.numOfName = self.numOfName + 1
	end	
	return finalName
end

function CharacterTemplate:CheckNumOfCharaInCity( city )
	local need = QueryCityNeedChara( city )
	local has = g_statistic:QueryNumberOfCharaInCity( city )
	--print( city.name .. " chara=" .. has .."/" .. need, #city.charas )	
	if #city.charas >= need then return end	
	if has >= math.ceil( need * 0.5 ) then return end
	table.insert( self.cityList, city )
end

function CharacterTemplate:GenerateChara( city )
	self.retryTime = 0
	
	local chara = g_charaDataMng:NewData()
	chara:Load( { id=chara.id } )
	chara.type = CharacterType.FICTIONAL
	chara.name = self:GenerateName()
	chara.location = city
	chara.home     = city
	
	return chara
end

function CharacterTemplate:GenerateOutChara( city )
	local chara = self:GenerateChara( city )
	g_statistic:AddOutChara( chara )	
	self.generateChara = self.generateChara + 1	
	--InputUtility_Pause( "generate chara ", NameIDToString( chara ) .. " in " .. city.name, "retry=" .. self.retryTime, "tot=" .. self.generateChara )	
	
	return chara
end

function CharacterTemplate:Update( elapsedTime )
	if #g_statistic.outCharacterList > math.ceil( g_plotMap:GetNumOfPlot() * GlobalConst.LIMIT_OUTCHARA_BY_PLOT_MODULUS ) then return end

	local numberOfChara = Random_SyncGetRange( GlobalConst.MIN_GENERATE_OUTCHARA_PER_TURN, GlobalConst.MAX_GENERATE_OUTCHARA_PER_TURN )
	MathUtility_Shuffle( self.cityList, g_syncRandomizer )
	for k, city in ipairs( self.cityList ) do
		if numberOfChara <= 0 then break end
		self:GenerateOutChara( city )
		numberOfChara = numberOfChara - 1
	end
	
	self.cityList = {}	
end