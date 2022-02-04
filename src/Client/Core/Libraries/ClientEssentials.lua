-- Variables
local clientEssentialsLibrary = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function clientEssentialsLibrary.GetPlayer()
	return game:GetService("Players").LocalPlayer
end


function clientEssentialsLibrary.SetCoreGuiEnabled(coreGuiType, isEnabled)
	repeat
		task.wait()
		game:GetService("StarterGui"):SetCoreGuiEnabled(coreGuiType, isEnabled)
	until game:GetService("StarterGui"):GetCoreGuiEnabled(coreGuiType) == isEnabled
end


function clientEssentialsLibrary.SetCore(...)
	repeat task.wait()
	until pcall(game:GetService("StarterGui").SetCore, game:GetService("StarterGui"), ...)
end


--
return clientEssentialsLibrary