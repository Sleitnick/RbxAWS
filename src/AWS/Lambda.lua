local Lambda = {}
Lambda.__index = Lambda

function Lambda.new()
	local self = setmetatable({}, Lambda)
	return self
end

return Lambda