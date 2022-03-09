local tweenService: TweenService = game:GetService("TweenService")

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local config = require(coreModule.Shared.GetObject("Libraries.Config")).GetConfig(script.Name)

local thisInterface: GuiBase2d = userInterfaceManager.GetInterface("TeleportationOverlay")
local overlayFrame: Frame = thisInterface:WaitForChild("Overlay")
local teleportationStateUpdated: RemoteFunction = coreModule.Shared.GetObject("//Remotes.TeleportationStateUpdated")

local ThisInterfaceManager = {}

-- Initialize
function ThisInterfaceManager.Initialize()

    -- When a player is teleporting we want to cover their screen so they teleport smoother.
    teleportationStateUpdated.OnClientInvoke = function(isStarting: boolean, overlayColor: Color3)

        -- Making sure it's enabled.
        if userInterfaceManager.ActiveInterface ~= thisInterface then
            userInterfaceManager.UpdateInterfaceShown(thisInterface)
        end

        overlayFrame.BackgroundColor3 = overlayColor

        -- We want to tween the BackgroundTransparency of the overlayFrame.
        local hasThisTweenBeenDisabled: boolean = false
        local overlayTransparencyTween: Tween = tweenService:Create(
            overlayFrame,
            TweenInfo.new(config.OVERLAY_TRANSITION_TIME, Enum.EasingStyle.Linear),
            {BackgroundTransparency = if isStarting then 0 else 1}
        )

        overlayTransparencyTween:Play()

        -- If they aren't just starting then we want to hide the interface after this.
        if not isStarting then
            task.spawn(function()

                if overlayTransparencyTween.PlaybackState ~= Enum.PlaybackState.Completed then
                    overlayTransparencyTween.Completed:Wait()
                end

                -- Has it been disabled already?
                if not hasThisTweenBeenDisabled and userInterfaceManager.ActiveInterface == thisInterface then
                    userInterfaceManager.UpdateInterfaceShown(thisInterface)
                    hasThisTweenBeenDisabled = true
                end
            end)

            -- In case this user didn't get the second call.
            task.delay(10, function()

                -- Has it been disabled already?
                if not hasThisTweenBeenDisabled and userInterfaceManager.ActiveInterface == thisInterface then
                    print("This should not be the case.", overlayTransparencyTween.PlaybackState)
                    userInterfaceManager.UpdateInterfaceShown(thisInterface)
                    hasThisTweenBeenDisabled = true
                end
            end)
        end
        --[[if not isStarting then

            -- Let's do this in another thread since this is a RemoteFunction.
            task.spawn(function()

                if overlayTransparencyTween.PlaybackState ~= Enum.PlaybackState.Completed then
                    overlayTransparencyTween.Completed:Wait()
                end

                -- Has it been disabled already?
                if not hasThisTweenBeenDisabled and userInterfaceManager.ActiveInterface == thisInterface then
                    userInterfaceManager.UpdateInterfaceShown(thisInterface)
                    print("This should have been canceled.")
                    hasThisTweenBeenDisabled = true
                end
            end)

            -- In case this user didn't get the second call.
            task.delay(10, function()

                -- Has it been disabled already?
                if not hasThisTweenBeenDisabled and userInterfaceManager.ActiveInterface == thisInterface then
                    print("This should not be the case.", overlayTransparencyTween.PlaybackState)
                    userInterfaceManager.UpdateInterfaceShown(thisInterface)
                    hasThisTweenBeenDisabled = true
                end
            end)
        end]]

        return
    end
end

return ThisInterfaceManager
