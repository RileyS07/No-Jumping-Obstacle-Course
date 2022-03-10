local players: Players = game:GetService("Players")
local guiService: GuiService = game:GetService("GuiService")

local coreModule = require(script:FindFirstAncestor("Core"))
local signal = require(coreModule.Shared.GetObject("Libraries.Signal"))

local UserInterfaceManager = {}
UserInterfaceManager.ActiveInterface = nil
UserInterfaceManager.ActiveInterfaceUpdated = signal.new()

-- Initialize
function UserInterfaceManager.Initialize()

	-- Loading modules.
	--coreModule.LoadModule("/LoadingScreen")

	--coreModule.LoadModule("/LoadingScreen")
	coreModule.LoadModule("/VersionUpdates")
	coreModule.LoadModule("/TeleportationOverlay")
	coreModule.LoadModule("/TeleportationConsent")
	--coreModule.LoadModule("/TopbarManager")
	coreModule.LoadModule("/DoorInterface")
	--coreModule.LoadModule("/EffectTimers")
	--coreModule.LoadModule("/Events")

	-- All experiences should have this feature.
	-- When you hit escape it should close out of all non-essential guis.
	guiService.MenuOpened:Connect(function()

		-- Is there an interface on the screen right now?
		if UserInterfaceManager.ActiveInterface and UserInterfaceManager.ActiveInterface.DisplayOrder <= 0 then
			UserInterfaceManager._CloseInterface(UserInterfaceManager.ActiveInterface)
			UserInterfaceManager.ActiveInterface = nil
			UserInterfaceManager.ActiveInterfaceUpdated:Fire(nil)
		end
	end)
end

-- Get's the desired interface in PlayerGui.
-- In theory this could literally return anything but it should be an interface.
function UserInterfaceManager.GetInterface(interfaceName: string) : GuiBase2d
	return players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild(interfaceName) :: GuiBase2d
end

-- This updates the current interface that is shown.
-- It will hide it if it's already visible and show it if it is not.
function UserInterfaceManager.UpdateInterfaceShown(thisInterface: GuiBase2d, closeOnly: boolean?) : boolean

	-- We need to make an exception for if closeOnly is true.
	if closeOnly and UserInterfaceManager.ActiveInterface ~= thisInterface then
		return false
	end

	-- Case #1: Another interface is active that is not this one.
	-- Response: We close it and open this one, do not change effects.
	if UserInterfaceManager.ActiveInterface and UserInterfaceManager.ActiveInterface ~= thisInterface then

		-- We need to make sure the DisplayOrder is less or the same.
		if UserInterfaceManager.ActiveInterface.DisplayOrder <= thisInterface.DisplayOrder then
			UserInterfaceManager._CloseInterface(UserInterfaceManager.ActiveInterface)
			UserInterfaceManager._OpenInterface(thisInterface)
			UserInterfaceManager.ActiveInterface = thisInterface
			UserInterfaceManager.ActiveInterfaceUpdated:Fire(UserInterfaceManager.ActiveInterface)
		else
			return false
		end

	-- Case #2: Another interface is active and this one is it.
	-- Response: We close it and remove effects.
	elseif UserInterfaceManager.ActiveInterface == thisInterface then
		UserInterfaceManager._CloseInterface(UserInterfaceManager.ActiveInterface)
		UserInterfaceManager.ActiveInterface = nil
		UserInterfaceManager.ActiveInterfaceUpdated:Fire(UserInterfaceManager.ActiveInterface)

	-- Case #3: No interface is active.
	-- Response: We open it and apply effects.
	elseif not UserInterfaceManager.ActiveInterface then
		UserInterfaceManager._OpenInterface(thisInterface)
		UserInterfaceManager.ActiveInterface = thisInterface
		UserInterfaceManager.ActiveInterfaceUpdated:Fire(UserInterfaceManager.ActiveInterface)
	end

	return true
end
--[[
-- Methods
-- Enables a specific ScreenGui while also giving functionality to disable all other interfaces while you're at it.
function UserInterfaceManager.EnableInterface(interfaceName, functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		DisableOtherInterfaces = false,
		IsPriority = false
	}})

	-- Updates the priority interface.
	if UserInterfaceManager.GetPriorityInterface() then return end
	if functionParameters.IsPriority and UserInterfaceManager.GetInterface(interfaceName) then
		UserInterfaceManager.PriorityInterface = UserInterfaceManager.GetInterface(interfaceName)
	end

	-- Gives the responsibility of enabling the interface to DisableInterface since disableOtherInterfaces is true.
	if functionParameters.DisableOtherInterfaces then
		UserInterfaceManager.DisableInterface(interfaceName, true)

	-- Just a safety check to make sure the interface actually exists.
	elseif UserInterfaceManager.GetInterface(interfaceName) and UserInterfaceManager.GetInterface(interfaceName):IsA("GuiBase2d") then
		UserInterfaceManager.GetInterface(interfaceName).Enabled = true
	end
end

-- Disables a specific interface/disables all interfaces except the one corresponding to interfaceName.
function UserInterfaceManager.DisableInterface(interfaceName, exceptionBoolean)

	-- You only want a specific interface to be disabled only.
	if interfaceName and not exceptionBoolean then
		if not UserInterfaceManager.GetInterface(interfaceName) or not UserInterfaceManager.GetInterface(interfaceName):IsA("GuiBase2d") then return end
		UserInterfaceManager.GetInterface(interfaceName).Enabled = false

		-- Closing this one.
		if UserInterfaceManager.ActiveContainers[UserInterfaceManager.GetInterface(interfaceName)] then
			clientAnimationsLibrary.PlayAnimation("CloseContainer", UserInterfaceManager.ActiveContainers[UserInterfaceManager.GetInterface(interfaceName)])
			UserInterfaceManager.ActiveContainers[UserInterfaceManager.GetInterface(interfaceName)] = nil
			UserInterfaceManager.ActiveContainerUpdated:Fire(UserInterfaceManager.GetInterface(interfaceName), false)
		end

		if UserInterfaceManager.GetPriorityInterface() and interfaceName == UserInterfaceManager.GetPriorityInterface().Name then
			UserInterfaceManager.PriorityInterface = nil
		end

	-- This can either be disable all interfaces or disable all interfaces except interfaceName correspondant.
	else
		for _, interfaceObject in next, thisPlayer:WaitForChild("PlayerGui"):GetChildren() do

			-- This line is important so we don't disable stuff like Chat and PlayerList etc.
			if game:GetService("StarterGui"):FindFirstChild(interfaceObject.Name) and interfaceObject:IsA("GuiBase2d") then
				if not UserInterfaceManager.GetPriorityInterface() or (UserInterfaceManager.GetPriorityInterface() ~= interfaceObject or (exceptionBoolean and UserInterfaceManager.GetPriorityInterface().Name == interfaceName)) then
					interfaceObject.Enabled = exceptionBoolean and interfaceObject.Name == interfaceName

					-- Closing this one.
					if not interfaceObject.Enabled and UserInterfaceManager.ActiveContainers[interfaceObject] then
						clientAnimationsLibrary.PlayAnimation("CloseContainer", UserInterfaceManager.ActiveContainers[interfaceObject])
						UserInterfaceManager.ActiveContainers[interfaceObject] = nil
						UserInterfaceManager.ActiveContainerUpdated:Fire(interfaceObject, false)
					end
				end
			end
		end
	end
end

function UserInterfaceManager.UpdateActiveContainer(container, functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		CloseIfAlreadyActive = true,
		OnlyOpenWhenNoActiveContainer = false,
		OverrideBlur = false
	}})

	-- Type checking.
	if not container or typeof(container) ~= "Instance" or not container:IsA("GuiObject") then return end
	if not container:FindFirstAncestorOfClass("ScreenGui") then return end
	local screenGui = container:FindFirstAncestorOfClass("ScreenGui")
	UserInterfaceManager.EnableInterface(screenGui.Name)

	-- Is there any active container?
	if UserInterfaceManager.HasActiveContainer(screenGui) then

		-- Is this the active container? If so let's close it.
		if UserInterfaceManager.IsActiveContainer(container) then
			if not functionParameters.CloseIfAlreadyActive then return end

			clientAnimationsLibrary.PlayAnimation("CloseContainer", UserInterfaceManager.ActiveContainers[screenGui])
			UserInterfaceManager.ActiveContainerUpdated:Fire(screenGui, false)
			UserInterfaceManager.ActiveContainers[screenGui] = nil

		-- It's not the active container but there is one so we need to close that one and open this one.
		elseif not functionParameters.OnlyOpenWhenNoActiveContainer then
			clientAnimationsLibrary.PlayAnimation("CloseContainer", UserInterfaceManager.ActiveContainers[screenGui])
			UserInterfaceManager.ActiveContainerUpdated:Fire(screenGui, false)

			UserInterfaceManager.ActiveContainers[screenGui] = container
			clientAnimationsLibrary.PlayAnimation("OpenContainer", UserInterfaceManager.ActiveContainers[screenGui])
			UserInterfaceManager.ActiveContainerUpdated:Fire(screenGui, true)
		end

	-- There is no active container.
	else
		UserInterfaceManager.ActiveContainers[screenGui] = container
		clientAnimationsLibrary.PlayAnimation("OpenContainer", UserInterfaceManager.ActiveContainers[screenGui])
		UserInterfaceManager.ActiveContainerUpdated:Fire(screenGui, true)
	end

	-- Do we apply a blur?
	if not functionParameters.OverrideBlur and game:GetService("Lighting"):FindFirstChild("MenuBlur") then
		game:GetService("TweenService"):Create(
			game:GetService("Lighting").MenuBlur,
			TweenInfo.new(0.5, Enum.EasingStyle.Linear),
			{Size = UserInterfaceManager.HasActiveContainer(screenGui) and 13 or 0}
		):Play()
	end
end


function UserInterfaceManager.IsActiveContainer(container)
	if not container or typeof(container) ~= "Instance" or not container:IsA("GuiObject") then return end
	if not container:FindFirstAncestorOfClass("ScreenGui") then return end
	return UserInterfaceManager.ActiveContainers[container:FindFirstAncestorOfClass("ScreenGui")] == container
end


function UserInterfaceManager.HasActiveContainer(screenGui)
	if not screenGui or typeof(screenGui) ~= "Instance" or not screenGui:IsA("ScreenGui") then return end
	return UserInterfaceManager.ActiveContainers[screenGui] ~= nil
end


function UserInterfaceManager.GetPriorityInterface()
	return UserInterfaceManager.PriorityInterface
end]]

-- Opens the given interface.
-- We could add an animation here.
function UserInterfaceManager._OpenInterface(interface: GuiBase2d)
	interface.Enabled = true
end

-- Closes the given interface.
-- We could add an animation here.
function UserInterfaceManager._CloseInterface(interface: GuiBase2d)
	interface.Enabled = false
end

return UserInterfaceManager
