local AWS = require(game:GetService("ServerStorage").RbxAWS.AWS:Clone())

AWS.Config:SetDefaultRegion("us-east-2")

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

--[[
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
]]

--[=[
local xml = [[
<people>
  <person type="natural">
    <name>Manoel</name>
    <city>Palmas-TO</city>
  </person>
  <person type="legal">
    <name>University of Brasília</name>
    <city>Brasília-DF</city>
  </person>
</people>
]]
local handler = AWS.XML2Lua.XmlHandler.Tree
local parser = AWS.XML2Lua.parser(handler)
parser:parse(xml)

for i,p in pairs(handler.root.people.person) do
	print(i, "Name:", p.name, "City:", p.city, "Type:", p._attr.type)
end
]=]


local s3 = AWS.S3.new()
s3:ListBuckets()
	:Then(function(res)
		local buckets = res.Buckets.Bucket
		for _,bucket in ipairs(buckets) do
			print(bucket.Name)
		end
	end):Catch(function(res)
		warn(res)
	end)
