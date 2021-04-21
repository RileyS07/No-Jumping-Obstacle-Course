-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}
specificInterfaceManager.LastTweenObject = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.ScreenGui = userInterfaceManager.GetInterface("TeleportationOverlay")
    specificInterfaceManager.Interface.Overlay = specificInterfaceManager.Interface.ScreenGui:WaitForChild("Overlay")

    -- The screen fades to white when teleporting.
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportationStateUpdated").OnClientInvoke = function(isTeleporting)
        if specificInterfaceManager.LastTweenObject then specificInterfaceManager.LastTweenObject:Cancel() end
        userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, true)

        specificInterfaceManager.LastTweenObject = coreModule.Services.TweenService:Create(
            specificInterfaceManager.Interface.Overlay,
            TweenInfo.new(0.5, Enum.EasingStyle.Linear),
            {BackgroundTransparency = isTeleporting and 0 or 1}
        )
        specificInterfaceManager.LastTweenObject:Play()

        -- Do we hide the interface?
        if not isTeleporting then
            coroutine.wrap(function()
                specificInterfaceManager.LastTweenObject.Completed:Wait()
                if specificInterfaceManager.Interface.Overlay.BackgroundTransparency == 1 then
                    userInterfaceManager.DisableInterface(specificInterfaceManager.Interface.ScreenGui.Name)
                end
            end)()
        end

        return
    end
end


--
return specificInterfaceManager