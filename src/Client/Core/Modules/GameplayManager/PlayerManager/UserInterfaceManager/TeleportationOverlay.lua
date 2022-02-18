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
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportationStateUpdated").OnClientInvoke = function(isTeleporting, animationLength, overlayColor: Color3?)
        if specificInterfaceManager.LastTweenObject then specificInterfaceManager.LastTweenObject:Cancel() end
        userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, {DisableOtherInterfaces = true})
        specificInterfaceManager.Interface.Overlay.BackgroundColor3 = overlayColor or Color3.new(0, 0, 0)

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

            -- Last case scenario.
            task.delay(10, function()
                if specificInterfaceManager.Interface.ScreenGui.Enabled then
                    userInterfaceManager.DisableInterface(specificInterfaceManager.Interface.ScreenGui.Name)
                    userInterfaceManager.EnableInterface("MainInterface")
                end
            end)
        end

        return
    end
end


--
return specificInterfaceManager