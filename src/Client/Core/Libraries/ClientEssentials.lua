-- Variables
local clientEssentialsLibrary = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function clientEssentialsLibrary.GetPlayer()
	return game:GetService("Players").LocalPlayer
end


function clientEssentialsLibrary.SetCoreGuiEnabled(coreGuiType, isEnabled)
	repeat
		game:GetService("RunService").RenderStepped:Wait()
		game:GetService("StarterGui"):SetCoreGuiEnabled(coreGuiType, isEnabled)
	until game:GetService("StarterGui"):GetCoreGuiEnabled(coreGuiType) == isEnabled
end


function clientEssentialsLibrary.SetCore(...)
	repeat game:GetService("RunService").Stepped:Wait()
		print("???")
	until pcall(game:GetService("StarterGui").SetCore, game:GetService("StarterGui"), ...)
end


--
return clientEssentialsLibrary