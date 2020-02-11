local DynamoDB = {}
DynamoDB.__index = DynamoDB

function DynamoDB.new()
	local self = setmetatable({}, DynamoDB)
	return self
end

return DynamoDB