-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.Container = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("TeleportationConsent")
    specificInterfaceManager.Interface.Content = specificInterfaceManager.Interface.Container:WaitForChild("Content")

    -- GetTeleportationConsent shows a gui on their screen and waits for a yes/no.
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.GetTeleportationConsent").OnClientInvoke = function(title, description, imageContent)
        userInterfaceManager.UpdateActiveContainer(specificInterfaceManager.Interface.Container)
        return true
    end
end


--
return specificInterfaceManager

--[[

-- Variables
local teleportationConsentInterface = {}
teleportationConsentInterface.ConsentUpdated = Instance.new("BindableEvent")
teleportationConsentInterface.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local combinedInterfaceManager = require(coreModule.GetObject("/Parent"))
local userInterfaceManager = require(coreModule.GetObject("/Parent.Parent"))
local soundEffectsManager = require(coreModule.GetObject("Game.PlayerManager.SoundEffectsManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local config = require(script.Config)

-- Initialize
function teleportationConsentInterface.Initialize()
	for _, interface in next, combinedInterfaceManager.GetInterfaces() do
		teleportationConsentInterface.Interface[interface.Name.."Container"] = interface:WaitForChild("Frames"):WaitForChild("TeleportConsent")
		teleportationConsentInterface.Interface[interface.Name.."Buttons"] = teleportationConsentInterface.Interface[interface.Name.."Container"]:WaitForChild("Container"):WaitForChild("Buttons")
		teleportationConsentInterface.Interface[interface.Name.."Header"] = teleportationConsentInterface.Interface[interface.Name.."Container"]:WaitForChild("Container"):WaitForChild("Header")
		teleportationConsentInterface.Interface[interface.Name.."Hint"] = teleportationConsentInterface.Interface[interface.Name.."Header"]:WaitForChild("Hint")
	end

	-- Consent
	coreModule.Shared.GetObject("//Remotes.GetTeleportationConsent").OnClientInvoke = function(teleportConsentMode, teleporterObject, locationName)
		teleportationConsentInterface.SetupForcedCancelMeasures(teleporterObject)
		for _, interface in next, combinedInterfaceManager.GetInterfaces() do
			teleportationConsentInterface.Interface[interface.Name.."Hint"].Text = config.TeleporterConsentText[teleportConsentMode]:format(locationName)
			userInterfaceManager.UpdateCurrentActiveContainer(teleportationConsentInterface.Interface[interface.Name.."Container"])
		end
		
		--
		local teleportationConsentStatus = teleportationConsentInterface.ConsentUpdated.Event:Wait()
		if combinedInterfaceManager.AreContainersActive("Frames.TeleportConsent") then 
			for _, interface in next, combinedInterfaceManager.GetInterfaces() do
				userInterfaceManager.UpdateCurrentActiveContainer(teleportationConsentInterface.Interface[interface.Name.."Container"])
			end
		end
		return teleportationConsentStatus
	end
	
	--
	userInterfaceManager.ContainerClosed.Event:Connect(function(container)
		for _, interface in next, combinedInterfaceManager.GetInterfaces() do
			if container == teleportationConsentInterface.Interface[interface.Name.."Container"] then
				teleportationConsentInterface.ConsentUpdated:Fire(false)
				return
			end
		end
	end)
	
	--
	for _, interface in next, combinedInterfaceManager.GetInterfaces() do
		teleportationConsentInterface.Interface[interface.Name.."Buttons"]:WaitForChild("Yes").Activated:Connect(function()
			teleportationConsentInterface.ConsentUpdated:Fire(true)
		end)
	
		teleportationConsentInterface.Interface[interface.Name.."Buttons"]:WaitForChild("No").Activated:Connect(function()
			teleportationConsentInterface.ConsentUpdated:Fire(false)
		end)
	end
end

-- Methods
function teleportationConsentInterface.SetupForcedCancelMeasures(teleporterObject)
	coroutine.wrap(function()
		while true do
			if not teleporterObject or not teleporterObject.PrimaryPart then return end
			if not combinedInterfaceManager.AreContainersActive("Frames.TeleportConsent") then return end
			if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then teleportationConsentInterface.ConsentUpdated:Fire(false) return end
			if clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(teleporterObject.PrimaryPart.Position) > config.AllowedDistanceFromTeleporter then teleportationConsentInterface.ConsentUpdated:Fire(false) return end
			coreModule.Services.RunService.Stepped:Wait()
		end
	end)()
	
	--
	delay(config.AllowedTimeForConsent, function()
		if not combinedInterfaceManager.AreContainersActive("Frames.TeleportConsent") then return end
		teleportationConsentInterface.ConsentUpdated:Fire(false)
	end)
end

--
return teleportationConsentInterface
]]