Simple_DayPerMonth = 
{
	[1] = 30,
	[2] = 30,
	[3] = 30,
	[4] = 30,
	[5] = 30,
	[6] = 30,
	[7] = 30,
	[8] = 30,
	[9] = 30,
	[10] = 30,
	[11] = 30,
	[12] = 30,
}

Normal_DayPerMonth =
{
	[1] = 31,
	[2] = 28,
	[3] = 31,
	[4] = 30,
	[5] = 31,
	[6] = 30,
	[7] = 31,
	[8] = 31,
	[9] = 30,
	[10] = 31,
	[11] = 30,
	[12] = 31,
}

Calendar = class()

function Calendar:__init()
	self.year  = 2000

	--month from 1 ~ 12
	self.month = 1	
	
	--day from 1~31
	self.day   = 1
	
	--hour form 0 ~ 23
	self.hour  = 0
	
	--manual compute without datas?
	self.leapYear = 0
	
	--days in month
	self.daysInMonth = Simple_DayPerMonth
end

function Calendar:Init( daysInMonth )
	self.daysInMonth = daysInMonth
end

function Calendar:SetDate( month, day, year, hour )
	self.month = month or self.month
	
	self.day   = day or self.day
	
	self.year  = year or self.year
	
	self.hour  = hour or self.hour
	
	Debug_Log( "Set Date=" .. self.year .. "/" .. self.month .. "/" .. self.day .. " " .. self.hour )
end

function Calendar:GetDayInMonth()
	if self.daysInMonth and self.daysInMonth[self.month] then
		return self.daysInMonth[self.month]
	end
	return 30
end

function Calendar:GetYear()
	return self.year
end

function Calendar:GetMonth()
	return self.month
end

function Calendar:GetDay()
	return self.day
end

function Calendar:GetDateValue()
	return self.year * 10000 + self.month * 100 + self.day
end

function Calendar:DumpDayUnit()
	print( self.month .. "/" .. self.day .. "/" .. self.year )
end

function Calendar:DumpMonthUnit()
	print( self.year .. "/" .. self.month )
end

-----------------------------
-- Operation method

function Calendar:PassAMonth()
	self.hour  = 0
	self.day   = 1
	self.month = self.month + 1
	if self.month > 12 then
		self.month = 1
		self.year  = self.year + 1
	end
end

function Calendar:PassADay()
	self.hour = 0
	self.day  = self.day + 1
	if self.day > self:GetDayInMonth() then	
		self:PassAMonth()
	end
end

function Calendar:PassAHour()
	self.hour = self.hour + 1
	if self.hour > 23 then
		self:PassADay()
	end
end

function Calendar:ConvertFromDateValue( dateValue )
	local year  = math.floor( dateValue / 10000 )
	local month = math.floor( ( dateValue % 10000 ) / 100 )
	local day   = dateValue % 100
	--print( "Convert From DateValue=", year, month, day )
	return year, month, day
end

function Calendar:CalcDiffByYear( dateValue )
	if not dateValue then return 0 end
	local year, month, day = self:ConvertFromDateValue( dateValue )
	return math.abs( year - self.year )
end

function Calendar:CalcDiffByMonth( dateValue )	
	if not dateValue then return 0 end
	local year, month, day = self:ConvertFromDateValue( dateValue )
	if year > self.year then
		--given date is newer than current date
		return ( year - self.year ) * 12 + month + ( 12 - self.month )
	else
		--given date is older than current date
		return ( self.year - year ) * 12 + self.month + ( 12 - month )
	end
end