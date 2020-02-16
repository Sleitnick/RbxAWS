--[[

	Config.[PROFILE_NAME].AccessKeyId
	Config.[PROFILE_NAME].SecretAccessKey
	Config.[PROFILE_NAME].SessionToken
	Config.[PROFILE_NAME].DefaultRegion

	Config:SetAccessKeyId(accessKeyId [, profileName])
	Config:SetSecretAccessKey(secretAccessKey [, profileName])
	Config:SetSessionToken(sessionToken [, profileName])
	Config:SetDefaultRegion(defaultRegion [, profileName])
	Config:Set(accessKeyId, secretAccessKey, sessionToken, defaultRegion [, profileName])

	The "Default" profile is included by default.

]]

local Config = {}

local tableUtil

local profileTemplate = {
	AccessKeyId = "";
	SecretAccessKey = "";
	SessionToken = "";
	DefaultRegion = "us-east-1";
}

local profiles = {}

local function GetProfile(profileName)
	if (profileName == nil) then
		profileName = "Default"
	end
	assert(type(profileName) == "string", "Profile should be a string")
	local profile = profiles[profileName];
	if (not profile) then
		profile = tableUtil.Copy(profileTemplate);
		profiles[profileName] = profile
	end
	return profile
end

function Config:SetAccessKeyId(accessKeyId, profileName)
	assert(type(accessKeyId) == "string", "AccessKeyId must be a string")
	local profile = GetProfile(profileName)
	profile.AccessKeyId = accessKeyId
end

function Config:SetSecretAccessKey(secretAccessKey, profileName)
	assert(type(secretAccessKey) == "string", "SecretAccessKey must be a string")
	local profile = GetProfile(profileName)
	profile.SecretAccessKey = secretAccessKey
end

function Config:SetSessionToken(sessionToken, profileName)
	assert(type(sessionToken) == "string", "SessionToken must be a string")
	local profile = GetProfile(profileName)
	profile.SessionToken = sessionToken
end

function Config:SetDefaultRegion(defaultRegion, profileName)
	assert(type(defaultRegion) == "string", "DefaultRegion must be a string")
	local profile = GetProfile(profileName)
	profile.DefaultRegion = defaultRegion
end

function Config:Set(accessKeyId, secretAccessKey, sessionToken, defaultRegion, profileName)
	self:SetAccessKeyId(accessKeyId, profileName)
	self:SetSecretAccessKey(secretAccessKey, profileName)
	self:SetSessionToken(sessionToken, profileName)
	self:SetDefaultRegion(defaultRegion, profileName)
end

function Config:Init()

	tableUtil = self.AWS.TableUtil
	profiles.Default = tableUtil.Copy(profileTemplate)
	profiles.Test = tableUtil.Copy(profileTemplate)
	profiles.Test.AccessKeyId = "AKIAIOSFODNN7EXAMPLE"
	profiles.Test.SecretAccessKey = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"

	local awsCreds = game:GetService("ServerStorage"):FindFirstChild("AWSCredentials")
	if (awsCreds) then
		for _,folder in ipairs(awsCreds:GetChildren()) do
			if (folder:IsA("Folder") and folder:FindFirstChild("AccessKeyId") and folder:FindFirstChild("SecretAccessKey")) then
				local profileName = folder.Name
				local accessKeyId = folder.AccessKeyId.Value
				local secretAccessKey = folder.SecretAccessKey.Value
				Config:SetAccessKeyId(accessKeyId, profileName)
				Config:SetSecretAccessKey(secretAccessKey, profileName)
			end
		end
		-- Destroy the AWSCredentials folder if in actual game runtime:
		if (not game:GetService("RunService"):IsStudio()) then
			awsCreds:Destroy()
		end
	else
		warn("Did not find AWSCredentials folder under ServerStorage")
	end

end

return setmetatable(Config, {
	__index = profiles;
	__newindex = profiles;
})