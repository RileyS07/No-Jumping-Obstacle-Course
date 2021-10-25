-- Variables
local clientEssentialsLibrary = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function clientEssentialsLibrary.GetPlayer()
	return coreModule.Services.Players.LocalPlayer
end


function clientEssentialsLibrary.SetCoreGuiEnabled(coreGuiType, isEnabled)
	repeat
		coreModule.Services.RunService.RenderStepped:Wait()
		coreModule.Services.StarterGui:SetCoreGuiEnabled(coreGuiType, isEnabled)
	until coreModule.Services.StarterGui:GetCoreGuiEnabled(coreGuiType) == isEnabled
end


function clientEssentialsLibrary.SetCore(...)
	repeat coreModule.Services.RunService.Stepped:Wait()
	until pcall(coreModule.Services.StarterGui.SetCore, coreModule.Services.StarterGui, ...)
end


--
return clientEssentialsLibrary