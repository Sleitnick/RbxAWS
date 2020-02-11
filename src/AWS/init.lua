local AWS = {}

local function LoadModules()
	for _,moduleScript in pairs(script:GetChildren()) do
		if (moduleScript:IsA("ModuleScript")) then
			local module = require(moduleScript)
			module.AWS = AWS
			AWS[moduleScript.Name] = module
		end
	end
end

local function InitModules()
	for _,module in pairs(AWS) do
		if (type(module.Init) == "function") then
			module:Init()
		end
	end
end

local function StartModules()
	for _,module in pairs(AWS) do
		if (type(module.Start) == "function") then
			module:Start()
		end
	end
end

local function Setup()
	LoadModules()
	InitModules()
	StartModules()
end

Setup()

return AWS