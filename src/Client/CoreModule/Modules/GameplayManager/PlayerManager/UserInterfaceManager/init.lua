-- Variables
local userInterfaceManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))

-- Initialize
function userInterfaceManager.Initialize()
	
end

-- Methods
function userInterfaceManager.EnableInterface(interfaceName, disableOtherInterfaces)
	if disableOtherInterfaces then
		userInterfaceManager.DisableInterface(interfaceName, true)
	elseif userInterfaceManager.GetInterface(interfaceName) then
		userInterfaceManager.GetInterface(interfaceName).Enabled = true
	end
end

function userInterfaceManager.DisableInterface(interfaceName, exceptionBoolean)
	if interfaceName and not exceptionBoolean then	-- Specific interface
		if not userInterfaceManager.GetInterface(interfaceName) then return end
		userInterfaceManager.GetInterface(interfaceName).Enabled = false
	else											-- All interfaces (unless there's an exception
		for _, interfaceObject in next, clientEssentialsLibrary.GetPlayer():WaitForChild("PlayerGui"):GetChildren() do
			if coreModule.Services.StarterGui:FindFirstChild(interfaceObject.Name) then
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