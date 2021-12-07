-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}
specificInterfaceManager.LastTweenObject = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.ScreenGui = userInterfaceManager.GetInterface("TeleportationOverlay")
    specificInterfaceManager.Interface.Overlay = specificInterfaceManager.Interface.ScreenGui:WaitForChild("Overlay")

    -- The screen fades to white when teleporting.
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportationStateUpdated").OnClientInvoke = function(isTeleporting, animationLength)
        if specificInterfaceManager.LastTweenObject then specificInterfaceManager.LastTweenObject:Cancel() end
        userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, {DisableOtherInterfaces = true})

        local tweenObject = clientAnimationsLibrary.PlayAnimation(
            "TeleportationOverlay", specificInterfaceManager.Interface.Overlay, animationLength, isTeleporting
        )

        -- Do we hide the interface?
        if not isTeleporting then
            coroutine.wrap(function()
                if tweenObject.PlaybackState ~= Enum.PlaybackState.Completed then
                    tweenObject.Completed:Wait()
                end

                userInterfaceManager.DisableInterface(specificInterfaceManager.Interface.ScreenGui.Name)
                userInterfaceManager.EnableInterface("MainInterface")
            end)()
        end

        return
    end
end


--
return specificInterfaceManager