local S3 = {}
S3.__index = S3

S3.API = {
	Metadata = {
		ApiVersion = "2006-03-01";
		ChecksumFormat = "md5";
		EndpointPrefix = "s3";
		GlobalEndpoint = "s3.amazonaws.com";
		Protocol = "rest-xml";
		ServiceAbbreviation = "Amazon S3";
		ServiceFullName = "Amazon Simple Storage Service";
		ServiceId = "S3";
		SignatureVersion = "s3";
		UID = "s3-2006-03-01"
	};
	Operations = {
		ListBuckets = {
			Name = "ListBuckets";
			Http = {
				Method = "GET";
				RequestUri = "/";
			};
		};
	};
}

function S3.new()
	local self = setmetatable({}, S3)
	return self
end

function S3:_HttpRequest(req)
	return self.AWS.Http:Request(req, "s3")
end

function S3:ListObjects(bucketName)
	error("Not yet implemented")
end

function S3:ListBuckets()
	return self:_HttpRequest({
		Endpoint = self.API.Metadata.GlobalEndpoint;
		Uri = self.API.Operations.ListBuckets.Http.RequestUri;
		Query = "";
		Method = self.API.Operations.ListBuckets.Http.Method;
	}):Then(function(res)
		local xml = res.Body
		local handler = self.AWS.XML2Lua.XmlHandler.Tree
		local parser = self.AWS.XML2Lua.parser(handler)
		parser:parse(xml)
		print(xml)
		return handler.root.ListAllMyBucketsResult
	end)
end

return S3