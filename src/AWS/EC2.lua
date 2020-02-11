local EC2 = {}
EC2.__index = EC2

function EC2.new()
	local self = setmetatable({}, EC2)
	return self
end

return EC2