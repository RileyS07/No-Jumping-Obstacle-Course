-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}
specificInterfaceManager.LastTweenObject = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.ScreenGui = userInterfaceManager.GetInterface("TeleportationOverlay")
    specificInterfaceManager.Interface.Overlay = specificInterfaceManager.Interface.ScreenGui:WaitForChild("Overlay")

    -- The screen fades to white when teleporting.
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportationStateUpdated").OnClientInvoke = function(isTeleporting, animationLength)
        if specificInterfaceManager.LastTweenObject then specificInterfaceManager.LastTweenObject:Cancel() end
        userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, true)
        clientAnimationsLibrary.PlayAnimation("TeleportationOverlay", specificInterfaceManager.Interface.Overlay, animationLength, isTeleporting)

        -- Do we hide the interface?
        if not isTeleporting then
            coroutine.wrap(function()
                wait(animationLength)

                if math.round(specificInterfaceManager.Interface.Overlay.BackgroundTransparency) == 1 then
                    userInterfaceManager.DisableInterface(specificInterfaceManager.Interface.ScreenGui.Name)
                end
            end)()
        end

        return
    end
end


--
return specificInterfaceManager