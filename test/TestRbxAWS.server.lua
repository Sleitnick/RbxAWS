local AWS = require(game:GetService("ServerStorage").RbxAWS.AWS)

AWS.Config:SetDefaultRegion("us-east-2")

--local s3 = AWS.S3.new()
--local buckets = s3:ListBuckets()

--[[
-- TEST AUTH:
local accessKeyId = AWS.Config.Default.AccessKeyId
local secretAccessKey = AWS.Config.Default.SecretAccessKey
local httpVerb = "POST"
local headers = {["Test"] = "Hello world"; ["X-Roblox"] = "Hi"}
local content = game:GetService("HttpService"):JSONEncode({Kills = 32; Deaths = 16; Points = 1000})
local contentType = "application/json"
local auth = AWS.Http:BuildAuthorizationHeader(accessKeyId, secretAccessKey, httpVerb, headers, content, contentType)
print(auth)
]]

local req = {
	Url = "https://www.google.com";
	Method = "GET";
}

AWS.Http:Request(req)
	:Then(function(res)
		print("SUCCESS")
		print(res.Body)
	end)
	:Catch(function(res)
		print("FAILURE")
		warn(res.StatusCode .. ": " .. res.StatusMessage)
	end)