-- Variables
local userInterfaceManager = {}
userInterfaceManager.ActiveContainers = {}
userInterfaceManager.ActiveContainerUpdated = Instance.new("BindableEvent")	-- => screenGui, container, isActive

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function userInterfaceManager.Initialize()
	
	-- Loading modules.
	coreModule.LoadModule("/TeleportationConsent")
	coreModule.LoadModule("/TeleportationOverlay")
	coreModule.LoadModule("/VersionUpdates")
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
	if typeof(interfaceName) ~= "string" then return end
	return clientEssentialsLibrary.GetPlayer():WaitForChild("PlayerGui"):WaitForChild(interfaceName)
end


function userInterfaceManager.UpdateActiveContainer(container, functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		CloseIfAlreadyActive = true,
		OnlyOpenWhenNoActiveContainer = false,
		OverrideBlur = false
	}})

	-- Type checking.
	if not container or typeof(container) ~= "Instance" or not container:IsA("GuiObject") then return end
	if not container:FindFirstAncestorOfClass("ScreenGui") then return end
	local screenGui = container:FindFirstAncestorOfClass("ScreenGui")
	userInterfaceManager.EnableInterface(screenGui.Name)

	-- Is there any active container?
	if userInterfaceManager.HasActiveContainer(screenGui) then

		-- Is this the active container? If so let's close it.
		if userInterfaceManager.IsActiveContainer(container) then
			if not functionParameters.CloseIfAlreadyActive then return end

			clientAnimationsLibrary.PlayAnimation("CloseContainer", userInterfaceManager.ActiveContainers[screenGui])
			userInterfaceManager.ActiveContainerUpdated:Fire(screenGui, userInterfaceManager.ActiveContainers[screenGui], false)
			userInterfaceManager.ActiveContainers[screenGui] = nil

		-- It's not the active container but there is one so we need to close that one and open this one.
		elseif not functionParameters.OnlyOpenWhenNoActiveContainer then
			clientAnimationsLibrary.PlayAnimation("CloseContainer", userInterfaceManager.ActiveContainers[screenGui])
			userInterfaceManager.ActiveContainerUpdated:Fire(screenGui, userInterfaceManager.ActiveContainers[screenGui], false)

			userInterfaceManager.ActiveContainers[screenGui] = container
			clientAnimationsLibrary.PlayAnimation("OpenContainer", userInterfaceManager.ActiveContainers[screenGui])
			userInterfaceManager.ActiveContainerUpdated:Fire(screenGui, userInterfaceManager.ActiveContainers[screenGui], true)
		end

	-- There is no active container.
	else
		userInterfaceManager.ActiveContainers[screenGui] = container
		clientAnimationsLibrary.PlayAnimation("OpenContainer", userInterfaceManager.ActiveContainers[screenGui])
		userInterfaceManager.ActiveContainerUpdated:Fire(screenGui, userInterfaceManager.ActiveContainers[screenGui], true)
	end

	-- Do we apply a blur?
	if not functionParameters.OverrideBlur and coreModule.Services.Lighting:FindFirstChild("MenuBlur") then
		coreModule.Services.TweenService:Create(
			coreModule.Services.Lighting.MenuBlur,
			TweenInfo.new(0.5, Enum.EasingStyle.Linear),
			{Size = userInterfaceManager.HasActiveContainer(screenGui) and 13 or 0}
		):Play()
	end
end


function userInterfaceManager.IsActiveContainer(container)
	if not container or typeof(container) ~= "Instance" or not container:IsA("GuiObject") then return end
	if not container:FindFirstAncestorOfClass("ScreenGui") then return end
	return userInterfaceManager.ActiveContainers[container:FindFirstAncestorOfClass("ScreenGui")] == container
end


function userInterfaceManager.HasActiveContainer(screenGui)
	if not screenGui or typeof(screenGui) ~= "Instance" or not screenGui:IsA("ScreenGui") then return end
	return userInterfaceManager.ActiveContainers[screenGui] ~= nil
end


--
return userInterfaceManager