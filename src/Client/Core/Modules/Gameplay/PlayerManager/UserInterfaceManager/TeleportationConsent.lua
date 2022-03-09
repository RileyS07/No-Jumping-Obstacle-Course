local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

local thisInterface: ScreenGui = userInterfaceManager.GetInterface(script.Name)
local contentFrame: Frame = thisInterface:WaitForChild("Container"):WaitForChild("Content")
local buttonsContainer: Frame = contentFrame:WaitForChild("Buttons")
local descriptionText: TextLabel = contentFrame:WaitForChild("Description")

local getTeleportationConsentRemote: RemoteFunction = coreModule.Shared.GetObject("//Remotes.GetTeleportationConsent")

local ThisInterfaceManager = {}

-- Initialize
function ThisInterfaceManager.Initialize()

	-- This bindable is used to communicate for their decision.
	local consentUpdatedBindable: BindableEvent = Instance.new("BindableEvent")
	ThisInterfaceManager._SetupConsentUpdateMethods(consentUpdatedBindable)

	-- GetTeleportationConsent shows a gui on their screen and waits for a yes/no.
	getTeleportationConsentRemote.OnClientInvoke = function(destinationDescription: string)
		if userInterfaceManager.ActiveInterface == thisInterface then return end

		-- We need to update the visuals before showing the interface.
		descriptionText.Text = destinationDescription
		userInterfaceManager.UpdateInterfaceShown(thisInterface)

		-- This is in case players take too long, we don't want the server waiting forever.
		task.delay(15, function()
			if userInterfaceManager.ActiveInterface == thisInterface then
				consentUpdatedBindable:Fire(false)
			end
		end)

		-- We need to wait for their decision.
		local wasConsentGranted: boolean = consentUpdatedBindable.Event:Wait()

		-- Regardless of their decision this is when we disable the interface.
		if userInterfaceManager.ActiveInterface == thisInterface then
			userInterfaceManager.UpdateInterfaceShown(thisInterface)
		end

		return wasConsentGranted
	end
end

-- Sets up the methods of consent updates: yes, no, interface updated.
function ThisInterfaceManager._SetupConsentUpdateMethods(consentUpdatedBindable: BindableEvent)

	-- When the user hits yes they consent to being teleported.
	buttonsContainer:WaitForChild("Yes").Activated:Connect(function()
		consentUpdatedBindable:Fire(true)
	end)

	-- When the user hits no they do not consent to being teleported.
	buttonsContainer:WaitForChild("No").Activated:Connect(function()
		consentUpdatedBindable:Fire(false)
	end)

	-- If the interface was closed for whatever reason we also cancel it.
	userInterfaceManager.ActiveInterfaceUpdated:Connect(function(interface: GuiBase2d?)
		if interface ~= thisInterface then return end

		consentUpdatedBindable:Fire(false)
	end)
end

return ThisInterfaceManager
