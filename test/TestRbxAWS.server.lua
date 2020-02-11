local AWS = require(game:GetService("ServerStorage").RbxAWS.AWS)

AWS.Config:SetDefaultRegion("us-east-2")

local s3 = AWS.S3.new()
local buckets = s3:ListBuckets()