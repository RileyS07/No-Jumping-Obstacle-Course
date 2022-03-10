local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

local contentFrame: Frame = userInterfaceManager.GetInterface(script.Name):WaitForChild("Content")
local effectInformationUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.EffectInformationUpdated")
local effectInformationDisplayTemplate: GuiObject = coreModule.Shared.GetObject("//Assets.Interfaces.EffectInformationDisplay")
local effectIconsDirectory: Instance = coreModule.Shared.GetObject("//Assets.Interfaces.EffectIcons")

local ThisInterfaceManager = {}
ThisInterfaceManager.TimerInformation = {}
ThisInterfaceManager.LastServerInformation = {}

-- Initialize
function ThisInterfaceManager.Initialize()

    -- When the effect information is updated we want to sync the timer information.
    effectInformationUpdatedRemote.OnClientEvent:Connect(ThisInterfaceManager._SyncTimerInformation)

    -- Every frame we try to update the content so we get precise times.
    task.defer(function()
        while true do
            task.wait()
            ThisInterfaceManager.UpdateContent()
        end
    end)
end

-- Updates the content, reading from ThisInterfaceManager.TimerInformation.
function ThisInterfaceManager.UpdateContent()

    -- When a timer is finsihed it will b e removed from TimerInformation.
    for _, effectInformationDisplay: Instance in next, contentFrame:GetChildren() do
        if effectInformationDisplay:IsA("GuiObject") and not ThisInterfaceManager.TimerInformation[effectInformationDisplay.Name] then
            effectInformationDisplay:Destroy()
        end
    end

    -- Now we can update the ones that are still in effect.
    for effectName: string, effectInformation: {[string]: {}} in next, ThisInterfaceManager.TimerInformation do

        -- Finding or creating the effect information display.
        local effectInformationDisplay: GuiObject = contentFrame:FindFirstChild(effectName) or effectInformationDisplayTemplate:Clone()
        effectInformationDisplay.Name = effectName
        effectInformationDisplay.Content.EffectName.Text = effectName

        -- Update the timer.
        if effectInformation.Duration - (os.clock() - effectInformation.Start) < 1e10 then
            effectInformationDisplay.Content.Timer.Text = ThisInterfaceManager._GetPaddedString(
                math.max(
                    0,
                    math.floor(
                        (effectInformation.Duration - (os.clock() - effectInformation.Start)) * 10
                    ) / 10
                ), 1
            )
        else
            effectInformationDisplay.Content.Timer.Text = "Infinity"
        end

        -- Update the icon.
        if effectIconsDirectory:FindFirstChild(effectName) and (effectIconsDirectory:FindFirstChild(effectName) :: Instance):IsA("ImageLabel") then
            effectInformationDisplay.Icon.Image = (effectIconsDirectory:FindFirstChild(effectName) :: ImageLabel).Image
        end

        -- Since we also clone it there is a chance we need to parent it.
        effectInformationDisplay.Parent = contentFrame

        -- Remove old effects part 2?
        if os.clock() - effectInformation.Start >= effectInformation.Duration then
            effectInformationDisplay:Destroy()
            ThisInterfaceManager.TimerInformation[effectName] = nil
        end
    end
end

-- Syncs the clients information up with the servers information.
function ThisInterfaceManager._SyncTimerInformation(serverInformation: {[string]: {}}?)

    -- If they have no effects it will be nil.
    if not serverInformation or next(serverInformation) == nil then
        ThisInterfaceManager.TimerInformation = {}
        return
    end

    -- They have some effects!
    for effectName: string, effectInformation: {[string]: {}} in next, serverInformation do

        -- Trying to see if we should update the start time.
        -- If we don't confirm this it will reset the timers for every effect when updating any effect.
        local shouldWeUpdateStartTime: boolean = true

        -- We also need to keep track of the last information sent by the server,
        -- Since os.clock is used for keeping track of time and the times will not sync between machines.
        if ThisInterfaceManager.LastServerInformation[effectName] and serverInformation[effectName] then
            if ThisInterfaceManager.LastServerInformation[effectName].Start == serverInformation[effectName].Start then
                shouldWeUpdateStartTime = false
            end
        end

        -- These are the only values the client needs to worry about.
        ThisInterfaceManager.TimerInformation[effectName] = {
            Start = shouldWeUpdateStartTime and os.clock() or ThisInterfaceManager.TimerInformation[effectName].Start,
            Duration = effectInformation.Duration or math.huge,
            IsFresh = not not effectInformation.IsFresh,
            Color = effectInformation.Color
        }

        ThisInterfaceManager.LastServerInformation = serverInformation
    end
end

-- Makes sure that there is a number and a decimal for this number.
-- We want 10.0 not 10 so it's consistent with 10.1.
function ThisInterfaceManager._GetPaddedString(number: number, precision: number) : string

    -- If it's not an integer then we can treat it normally.
    if number % 1 > 0 then
        return tostring(math.floor(number * (10 ^ precision)) / (10 ^ precision))
    else
        return tostring(number) .. "." .. string.rep("0", precision)
    end
end

return ThisInterfaceManager
