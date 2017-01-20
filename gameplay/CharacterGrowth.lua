CharacterDeathData = 
{
	[1] = { maxAge = 20, prob = 10 },
	[2] = { maxAge = 30, prob = 25 },
	[3] = { maxAge = 40, prob = 100 },
	[4] = { maxAge = 50, prob = 600 },
	[5] = { maxAge = 60, prob = 2000 },
	[6] = { maxAge = 70, prob = 4000 },
	[7] = { maxAge = 80, prob = 8500 },
	[8] = { maxAge = -1, prob = 9500 },
}

CharacterGrowthStageData = 
{
	[10] = { name="YOUTH_WEAK",    minAge=-1, maxAge=30, rise=4, decline=-2, prob=4500 },
	[11] = { name="YOUTH_NORMAL",  minAge=-1, maxAge=30, rise=6, decline=-2, prob=6000 },	
	[12] = { name="YOUTH_STRONG",  minAge=-1, maxAge=30, rise=8, decline=-1, prob=7000 },
	
	[20] = { name="MIDAGE_WEAK",   minAge=31, maxAge=50, rise=1, decline=0,  prob=4500 },
	[21] = { name="MIDAGE_NORMAL", minAge=31, maxAge=50, rise=4, decline=-1, prob=5000 },
	[22] = { name="MIDAGE_STRONG", minAge=31, maxAge=50, rise=6, decline=0,  prob=6000 },	
	
	[30] = { name="OLDAGE_WEAK",   minAge=51, maxAge=-1, rise=1, decline=-4, prob=4500 },	
	[31] = { name="OLDAGE_NORMAL", minAge=51, maxAge=-1, rise=2, decline=-3, prob=4500 },
	[32] = { name="OLDAGE_STRONG", minAge=51, maxAge=-1, rise=4, decline=-2, prob=5500 },	
}

CharacterGrowthData =
{
	[10] = { name="YOUTH2_MIDAGE2_OLDAGE2", stages = { 11, 21, 31 } },	
	[11] = { name="YOUTH2_MIDAGE3_OLDAGE2", stages = { 11, 22, 31 } },	
	[12] = { name="YOUTH2_MIDAGE2_OLDAGE3", stages = { 11, 21, 32 } },	
	
	[20] = { name="YOUTH3_MIDAGE2_OLDAGE2", stages = { 12, 21, 31 } },
	[21] = { name="YOUTH3_MIDAGE1_OLDAGE2", stages = { 12, 20, 31 } },
	[22] = { name="YOUTH3_MIDAGE3_OLDAGE1", stages = { 12, 22, 30 } },
	
	[30] = { name="YOUTH1_MIDAGE2_OLDAGE3", stages = { 10, 21, 32 } },
	[31] = { name="YOUTH1_MIDAGE3_OLDAGE2", stages = { 10, 22, 31 } },
	[32] = { name="YOUTH1_MIDAGE3_OLDAGE3", stages = { 10, 22, 32 } },
}

function UpdateCharaGrowth( chara )
	local delta = Random_SyncGetRange( 2, -2 )
	chara.satisfaction = MathUtility_Clamp( chara.satisfaction + delta, 0, CharacterParams.ATTRIBUTE.MAX_SATISFACTION )

	if g_calendar.passMonth then
		for k, data in ipairs( CharacterDeathData ) do
			if data.maxAge == -1 or data.maxAge >= chara.age then
				if Random_SyncGetProb() < data.prob then
					--CharaDie( chara )
				end
				break
			end
		end
	end
	
	if g_calendar.passYear then
		chara.age = chara.age + 1
		local growthData = CharacterGrowthData[10]
		for k, stage in ipairs( growthData.stages ) do
			local stageData = CharacterGrowthStageData[stage]
			if ( stageData.minAge == -1 or stageData.minAge <= chara.age ) and ( stageData.maxAge == -1 or stageData.maxAge >= chara.age ) then
				if Random_SyncGetProb() < stageData.prob then
					local delta = Random_SyncGetRange( stageData.decline, stageData.rise )
					chara.ca = MathUtility_Clamp( chara.ca + delta, 1, chara.ap )
					--InputUtility_Pause( chara.name .. " ca=" .. chara.ca .."/" .. chara.ap ..( delta < 0 and delta or "+" ..delta ), stageData.name, chara.age )
				end
				break
			end
		end
	end
end

-----------------------

CharacterEventType = 
{
	--Task
	ATTACK_CITY = 100,
	LEAD_TROOP  = 101,	
	
	--Event
	PROMOTION = 200,
}

CharacterEventData = 
{
	[1] = { type="PROMOTION", satisfaction="" },
}

CharacterEvent = class()

function CharacterEvent:__init()
	
end