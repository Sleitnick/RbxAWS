local Date = {}
Date.__index = Date

local weekdays = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}
local months = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

function Date.new()
	local self = setmetatable(os.date("!*t"), Date)
	return self
end

-- ISO8601
function Date:ToISO()
	return ("%i%.2i%.2iT%.2i%.2i%.2iZ"):format(self.year, self.month, self.day, self.hour, self.min, self.sec)
end

-- YYYYMMDD
function Date:YMD()
	return ("%i%.2i%.2i"):format(self.year, self.month, self.day)
end

function Date:__tostring()
	-- Tue, 27 Mar 2007 19:36:42 +0000
	return ("%s, %.2i %s %i %.2i:%.2i:%.2i +0000"):format(weekdays[self.wday], self.day, months[self.month], self.year, self.hour, self.min, self.sec)
end

return Date