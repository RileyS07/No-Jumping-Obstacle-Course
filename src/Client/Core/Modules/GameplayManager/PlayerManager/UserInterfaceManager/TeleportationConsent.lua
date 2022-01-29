-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}
specificInterfaceManager.ConsentUpdated = Instance.new("BindableEvent")

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.Container = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Containers"):WaitForChild("TeleportationConsent")
    specificInterfaceManager.Interface.Content = specificInterfaceManager.Interface.Container:WaitForChild("Content")
	specificInterfaceManager.Interface.Buttons = specificInterfaceManager.Interface.Content:WaitForChild("Buttons")

    -- GetTeleportationConsent shows a gui on their screen and waits for a yes/no.
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.GetTeleportationConsent").OnClientInvoke = function(title, description, imageContent)

		-- Update the visuals on the ui.
		specificInterfaceManager.Interface.Container:WaitForChild("BackgroundImage"):WaitForChild("ImageLabel").Image = imageContent or "rbxassetid://5632265938"
		specificInterfaceManager.Interface.Container:WaitForChild("BackgroundImage"):WaitForChild("Title").Text = title or "???"
		specificInterfaceManager.Interface.Content:WaitForChild("Description").Text = description or "???"

		-- We don't want overlapping.
		if userInterfaceManager.IsActiveContainer(specificInterfaceManager.Interface.Container) then return end
        userInterfaceManager.UpdateActiveContainer(specificInterfaceManager.Interface.Container)

		-- Setup the timeout.
		delay(script:GetAttribute("TimeoutThreshold") or 15, function()
			if not userInterfaceManager.IsActiveContainer(specificInterfaceManager.Interface.Container) then return end
			specificInterfaceManager.ConsentUpdated:Fire(false)
		end)

		-- Get the consent status then update the container.
		local wasConsentGranted = specificInterfaceManager.ConsentUpdated.Event:Wait()
		if userInterfaceManager.IsActiveContainer(specificInterfaceManager.Interface.Container) then
			userInterfaceManager.UpdateActiveContainer(specificInterfaceManager.Interface.Container)
		end

        return wasConsentGranted
    end

	-- Below will be various different conditions that influence consent.

	-- Yes/No activated.
	specificInterfaceManager.Interface.Buttons:WaitForChild("Yes").Activated:Connect(function()
		specificInterfaceManager.ConsentUpdated:Fire(true)
	end)

	specificInterfaceManager.Interface.Buttons:WaitForChild("No").Activated:Connect(function()
		specificInterfaceManager.ConsentUpdated:Fire(false)
	end)

	-- If the interface was closed for whatever reason we also cancel it.
	userInterfaceManager.ActiveContainerUpdated.Event:Connect(function(container, isActive)
		if container ~= specificInterfaceManager.Interface.Container then return end
		if isActive then return end
		specificInterfaceManager.ConsentUpdated:Fire(false)
	end)
end


--
return specificInterfaceManager