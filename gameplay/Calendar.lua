local DAY_IN_MONTH = 30
local MONTH_IN_YEAR        = 12
local HOUR_IN_DAY          = 24

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
	self.beforeChrist = 0	
	--manual compute without datas?
	self.leapYear = 0		
	--days in month
	self.daysInMonth = Simple_DayPerMonth
end

function Calendar:Init( daysInMonth )
	self.daysInMonth = daysInMonth
end

function Calendar:SetDate( month, day, year, hour, beforeChrist )
	self.beforeChrist = beforeChrist or 0
	self.month = month or self.month	
	self.day   = day or self.day	
	self.year  = math.abs( year or self.year )	
	self.hour  = hour or self.hour	
	Debug_Log( "Set Date=" .. self.year .. "/" .. self.month .. "/" .. self.day .. " " .. self.hour )
end

function Calendar:GetDayInMonth()
	if self.daysInMonth and self.daysInMonth[self.month] then
		return self.daysInMonth[self.month]
	end
	return DAY_IN_MONTH
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

function Calendar:ConvertDateValue( year, month, day, beforeChrist )
	beforeChrist = beforeChrist or 0
	if day > DAY_IN_MONTH then month = month + math.floor( day / DAY_IN_MONTH ) * ( beforeChrist and -1 or 1 ) end
	if month > MONTH_IN_YEAR then year = year + math.floor( month / MONTH_IN_YEAR ) * ( beforeChrist and -1 or 1 ) end	
	local ret = year * 100000 + month * 1000 + day * 10 + beforeChrist
	return ret
end

function Calendar:GetDateValue()
	return self:ConvertDateValue( self.year, self.month, self.day, self.beforeChrist )
end

function Calendar:ConvertFromDateValue( dateValue )
	local year  = math.floor( dateValue / 100000 )
	local month = math.floor( ( dateValue % 100000 ) / 1000 )
	local day   = math.floor( ( dateValue % 1000 ) / 10 )
	local beforeChrist = dateValue % 10
	--print( "Convert From DateValue=", year, month, day )
	return year, month, day, beforeChrist
end

function Calendar:CreateDateDesc( year, month, day, beforeChrist, byDay, byMonth )
	local content = ( beforeChrist and "BC " or "AD " )
	if byDay then content = content .. year .. "Y" .. month .. "M" .. day .. "D"
	elseif byMonth then content = content .. year .. "Y" .. month .. "M"
	else content = content .. year .. "Y" 
	end
	return content
end

function Calendar:CreateDateDescByValue( dateValue, byDay, byMonth )
	local year, month, day, beforeChrist = self:ConvertFromDateValue( dateValue )
	return self:CreateDateDesc( year, month, day, beforeChrist, byDay, byMonth )
end

function Calendar:DumpDate( byDay, byMonth )
	print( self:CreateDateDesc( self.year, self.month, self.day, self.beforeChrist, byDay, byMonth ) )
end

-----------------------------
-- Operation method

function Calendar:PassAMonth()
	self.hour  = 0
	self.day   = 1
	self.month = self.month + 1
	if self.month > MONTH_IN_YEAR then
		self.month = 1
		if self.beforeChrist then
			self.year  = self.year - 1
			if self.year == 0 then
				self.beforeChrist = 1 
				self.year = 1
			end
		else
			self.year = self.year + 1
		end		
	end
end

function Calendar:PassADay()
	self.hour = 0
	self.day  = self.day + 1
	if self.day > self:GetDayInMonth() then	self:PassAMonth() end
end

function Calendar:PassAHour()
	self.hour = self.hour + 1
	if self.hour > HOUR_IN_DAY - 1 then self:PassADay() end
end

function Calendar:CalcDiffByYear( dateValue )
	if not dateValue then return 0 end
	local year, month, day, beforeChrist = self:ConvertFromDateValue( dateValue )
	if beforeChrist ~= self.beforeChrist then
		return year + self.year
	end
	return math.abs( year - self.year )
end

function Calendar:CalcDiffByMonth( dateValue )	
	if not dateValue then return 0 end
	local year, month, day, beforeChrist = self:ConvertFromDateValue( dateValue )
	
	if beforeChrist ~= self.beforeChrist then
		if beforeChrist > 0 then
			return ( year + self.year ) * MONTH_IN_YEAR + ( MONTH_IN_YEAR - month ) + self.month
		elseif self.beforeChrist > 0 then
			return ( year + self.year ) * MONTH_IN_YEAR + month + ( MONTH_IN_YEAR - self.month )
		end
	end
	
	if year > self.year then
		--given date is newer than current date
		return ( year - self.year ) * MONTH_IN_YEAR + month + ( MONTH_IN_YEAR - self.month )
	else
		--given date is older than current date
		return ( self.year - year ) * MONTH_IN_YEAR + self.month + ( MONTH_IN_YEAR - month )
	end
end