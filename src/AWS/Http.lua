--[[
	
	Http:Request(request)

]]


local Http = {}

local httpService = game:GetService("HttpService")

local Date
local Promise
local hashLib
local b64


local function EncodeUri(str)
	return httpService:UrlEncode(str)
end

local function Trim(str)
	return str:match("^%s*(.-)%s*$")
end

local function HMACSHA256(a, b)
	return hashLib.hmac(hashLib.sha256, a, b)
end


function Http:Request(req, awsService)
	return Promise.Async(function(resolve, reject)
		if (not req.Headers) then
			req.Headers = {}
		end
		local configProfile = self.AWS.Config.Default
		-- https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonRequestHeaders.html
		local date = Date.new()
		req.Headers.Date = date:ToISO()
		req.Headers.Authorization = self:_BuildAuthorizationHeader(
			configProfile.AccessKeyId,
			configProfile.SecretAccessKey,
			req.Method or "GET",
			req.Headers,
			req.Body,
			req.Headers["Content-Type"],
			date,
			configProfile.DefaultRegion,
			awsService
		)
		local success, res = pcall(function()
			self.AWS.TableUtil.Print(req, "Request", true)
			return httpService:RequestAsync(req)
		end)
		if (success and res.Success) then
			resolve(res)
		else
			reject(res)
		end
	end)
end


function Http:_BuildAuthStringToSign(canonicalRequest, date, scope)
	local req = hashLib.sha256(canonicalRequest)
	local timestamp = date:ToISO()
	local stringToSign = ("AWS4-HMAC-SHA256\n%s\n%s\n%s"):format(timestamp, scope, req)
	return stringToSign
end


function Http:_BuildAuthSignature(secretAccesKey, stringToSign, date, region, awsService)
	local ymd = date:YMD()
	local dateKey = HMACSHA256("AWS4" .. secretAccesKey, ymd)
	local dateRegionKey = HMACSHA256(dateKey, region)
	local dateRegionServiceKey = HMACSHA256(dateRegionKey, awsService)
	local signingKey = HMACSHA256(dateRegionServiceKey, "aws4_request")
	local signature = HMACSHA256(signingKey, stringToSign)
	return signature
end


function Http:_BuildAuthorizationHeader(accessKeyId, secretAccessKey, httpMethod, uri, queryString, headers, signedHeaders, content, contentType, date, region, awsService)

	-- https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
	-- https://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html

	-- Build canonical URI:
	if ((not uri) or uri == "") then uri = "/" end
	local canonicalUri = EncodeUri(uri)

	-- Build canonical query string:
	local canonicalQueryString = ""

	-- Build canonical headers:
	local canonicalHeaders = {}
	if (headers) then
		for header,value in pairs(headers) do
			table.insert(canonicalHeaders, {header:lower(), Trim(value)})
		end
		table.sort(canonicalHeaders, function(a, b)
			return (a[1] < b[1])
		end)
		for i,h in ipairs(canonicalHeaders) do
			canonicalHeaders[i] = (h[1] .. ":" .. h[2])
		end
		canonicalHeaders = table.concat(canonicalHeaders, "\n")
	end

	-- Build signed headers:
	if (not signedHeaders) then
		signedHeaders = {}
	end
	for i,v in ipairs(signedHeaders) do
		signedHeaders[i] = v:lower()
	end
	signedHeaders = table.concat(signedHeaders, ";")

	-- Hash payload:
	local hashedPayload = hashLib.sha256(content or "")

	-- Build signature:
	local canonicalRequest = ("%s\n%s\n%s\n%s\n%s\n%s"):format(httpMethod, canonicalUri, canonicalQueryString, canonicalHeaders, signedHeaders, hashedPayload)
	local stringToSign = self:_BuildAuthStringToSign(canonicalRequest, date, scope)
	local signature = self:_BuildAuthSignature(secretAccessKey, stringToSign, date, region, awsService)

	return signature

end


function Http:Init()
	Date = self.AWS.Date
	Promise = self.AWS.Promise
	hashLib = self.AWS.HashLib
	b64 = self.AWS.Base64.new()
end


return Http