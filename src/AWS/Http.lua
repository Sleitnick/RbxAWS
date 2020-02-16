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

local function HMAC_SHA256(key, msg)
	return hashLib.hmac(hashLib.sha256, key, msg)
end


function Http:Request(req, awsService)
	return Promise.Async(function(resolve, reject)
		if (not req.Headers) then
			req.Headers = {}
		end
		local configProfile = self.AWS.Config.Default
		-- https://docs.aws.amazon.com/AmazonS3/latest/API/RESTCommonRequestHeaders.html
		local date = Date.new()
		local hashedPayload = hashLib.sha256(req.Body or "")
		req.Headers["x-amz-date"] = date:ToISO()
		req.Headers["x-amz-content-sha256"] = hashedPayload
		--req.Headers["x-amz-signedheaders"] = "host;x-amz-date"
		local startAuth = tick()
		req.Headers.Authorization = self:_BuildAuthorizationHeader(
			configProfile.AccessKeyId,
			configProfile.SecretAccessKey,
			req.Method or "GET",
			"",
			"",
			req.Headers,
			{"host", "x-amz-date"},
			hashedPayload,
			req.Headers["Content-Type"],
			date,
			awsService == "s3" and "us-east-1" or configProfile.DefaultRegion,
			awsService
		)
		local authDur = (tick() - startAuth)
		print(("Calculated auth in %ims"):format(authDur * 1000))
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


function Http:_BuildAuthStringToSign(canonicalRequest, date, region, awsService)
	-- TODO: AWS is getting a different result for the hash of the canonical request:
	local scope = date:YMD() .. "/" .. region .. "/" .. awsService .. "/aws4_request"
	local req = hashLib.sha256(canonicalRequest)
	local timestamp = date:ToISO()
	local stringToSign = ("AWS4-HMAC-SHA256\n%s\n%s\n%s"):format(timestamp, scope, req)
	return stringToSign, scope
end


function Http:_BuildAuthSignature(secretAccesKey, stringToSign, date, region, awsService)
	local ymd = date:YMD()
	local dateKey = HMAC_SHA256("AWS4" .. secretAccesKey, ymd)
	local dateRegionKey = HMAC_SHA256(dateKey, region)
	local dateRegionServiceKey = HMAC_SHA256(dateRegionKey, awsService)
	local signingKey = HMAC_SHA256(dateRegionServiceKey, "aws4_request")
	local signature = HMAC_SHA256(signingKey, stringToSign)
	return signature
end


function Http:_BuildAuthorizationHeader(accessKeyId, secretAccessKey, httpMethod, uri, queryString, headers, signedHeaders, hashedPayload, contentType, date, region, awsService)

	-- https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
	-- https://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html

	print("_BuildAuthorizationHeader")

	-- Build canonical URI:
	if ((not uri) or uri == "") then uri = "/" end
	local canonicalUri = uri--EncodeUri(uri)
	print("CanonicalUri", canonicalUri)

	-- Build canonical query string:
	local canonicalQueryString = ""

	-- Build canonical headers:
	local canonicalHeaders = {host = awsService .. ".amazonaws.com"}
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
	else
		canonicalHeaders = ""
	end
	print("CanonicalHeaders", canonicalHeaders)

	-- Build signed headers:
	if (not signedHeaders) then
		signedHeaders = {}
	end
	for i,v in ipairs(signedHeaders) do
		signedHeaders[i] = v:lower()
	end
	table.sort(signedHeaders, function(a, b) return a < b end)
	signedHeaders = table.concat(signedHeaders, ";")
	print("SignedHeaders", signedHeaders)

	-- Build signature:
	local canonicalRequest = ("%s\n%s\n%s\n%s\n\n%s\n%s"):format(httpMethod, canonicalUri, canonicalQueryString, canonicalHeaders, signedHeaders, hashedPayload)
	print("CanonicalRequest", canonicalRequest)
	local stringToSign, scope = self:_BuildAuthStringToSign(canonicalRequest, date, region, awsService)
	print("StringToSign", stringToSign)
	local signature = self:_BuildAuthSignature(secretAccessKey, stringToSign, date, region, awsService)
	print("Signature", signature)

	local auth = ("AWS4-HMAC-SHA256 Credential=%s/%s, SignedHeaders=%s, Signature=%s"):format(accessKeyId, scope, signedHeaders, signature)
	print("Auth", auth)

	return auth

end


function Http:Init()
	Date = self.AWS.Date
	Promise = self.AWS.Promise
	hashLib = self.AWS.HashLib
	b64 = self.AWS.Base64.new()
end


return Http