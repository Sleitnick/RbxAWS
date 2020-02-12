--[[
	
	Http:Request()

]]


local Http = {}

local httpService = game:GetService("HttpService")

local Date
local Promise
local hashLib
local b64


function Http:Request(req)
	return Promise.Async(function(resolve, reject)
		local success, res = pcall(function()
			return httpService:RequestAsync(req)
		end)
		if (success and res.Success) then
			resolve(res)
		else
			reject(res)
		end
	end)
end


function Http:_BuildAuthorizationHeader(accessKeyId, secretAccessKey, httpVerb, headers, content, contentType)

	-- https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html
	--[[

		Authorization = "AWS" + " " + AWSAccessKeyId + ":" + Signature;

		Signature = Base64( HMAC-SHA1( YourSecretAccessKey, UTF-8-Encoding-Of( StringToSign ) ) );

		StringToSign = HTTP-Verb + "\n" +
			Content-MD5 + "\n" +
			Content-Type + "\n" +
			Date + "\n" +
			CanonicalizedAmzHeaders +
			CanonicalizedResource;

		CanonicalizedResource = [ "/" + Bucket ] +
			<HTTP-Request-URI, from the protocol name up to the query string> +
			[ subresource, if present. For example "?acl", "?location", "?logging", or "?torrent"];

		CanonicalizedAmzHeaders = <described in link at top>

	]]

	local date = tostring(Date.new())
	local contentMd5 = (content and hashLib.md5(content) or "")

	-- Canonicalized Resource remains blank unless using virtualized endpoints
	local canonicalizedResource = ""

	-- Build canonicalized headers:
	local canonicalizedAmzHeaders
	local headersArray = {}
	if (headers) then
		for key,val in pairs(headers) do
			if (key:sub(1, 6):lower() == "x-amz-") then
				table.insert(headersArray, key:lower() .. ":" .. val)
			end
		end
	end
	table.sort(headersArray, function(a, b) return a:match("(.-):") < b:match("(.-):") end)
	canonicalizedAmzHeaders = table.concat(headersArray, "\n")

	-- Build StringToSign:
	local stringToSign = httpVerb .. "\n" .. contentMd5 .. "\n" .. (contentType or "") .. "\n" ..
							date .. "\n" .. canonicalizedAmzHeaders .. canonicalizedResource

	-- Hash and encode signature:
	local signature = b64:Encode(hashLib.hmac(hashLib.sha1, secretAccessKey, stringToSign))

	-- Create authorization header value:
	local authorization = "AWS " .. accessKeyId .. ":" .. signature

	return authorization

end


function Http:Init()
	Date = self.AWS.Date
	Promise = self.AWS.Promise
	hashLib = self.AWS.HashLib
	b64 = self.AWS.Base64.new()
end


return Http