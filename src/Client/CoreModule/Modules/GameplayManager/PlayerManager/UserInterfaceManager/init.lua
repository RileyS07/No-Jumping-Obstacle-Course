-- Variables
local userInterfaceManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))

-- Initialize
function userInterfaceManager.Initialize()
	
	-- Loading modules.
	coreModule.LoadModule("/TeleportationOverlay")
end


-- Methods
-- Enables a specific ScreenGui while also giving functionality to disable all other interfaces while you're at it.
function userInterfaceManager.EnableInterface(interfaceName, disableOtherInterfaces)

	-- Gives the responsibility of enabling the interface to DisableInterface since disableOtherInterfaces is true.
	if disableOtherInterfaces then
		userInterfaceManager.DisableInterface(interfaceName, true)

	-- Just a safety check to make sure the interface actually exists.
	elseif userInterfaceManager.GetInterface(interfaceName) and userInterfaceManager.GetInterface(interfaceName):IsA("GuiBase2d") then
		userInterfaceManager.GetInterface(interfaceName).Enabled = true
	end
end


-- Disables a specific interface/disables all interfaces except the one corresponding to interfaceName.
function userInterfaceManager.DisableInterface(interfaceName, exceptionBoolean)

	-- You only want a specific interface to be disabled only.
	if interfaceName and not exceptionBoolean then
		if not userInterfaceManager.GetInterface(interfaceName) or not userInterfaceManager.GetInterface(interfaceName):IsA("GuiBase2d") then return end
		userInterfaceManager.GetInterface(interfaceName).Enabled = false

	-- This can either be disable all interfaces or disable all interfaces except interfaceName correspondant.
	else
		for _, interfaceObject in next, clientEssentialsLibrary.GetPlayer():WaitForChild("PlayerGui"):GetChildren() do

			-- This line is important so we don't disable stuff like Chat and PlayerList etc.
			if coreModule.Services.StarterGui:FindFirstChild(interfaceObject.Name) and interfaceObject:IsA("GuiBase2d") then
				interfaceObject.Enabled = exceptionBoolean and interfaceObject.Name == interfaceName
			end
		end
	end
end


function userInterfaceManager.GetInterface(interfaceName)
	return clientEssentialsLibrary.GetPlayer():WaitForChild("PlayerGui"):WaitForChild(interfaceName)
end


--
return userInterfaceManager