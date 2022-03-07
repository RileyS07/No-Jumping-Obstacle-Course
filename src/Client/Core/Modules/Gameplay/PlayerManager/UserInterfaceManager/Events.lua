local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local confettiInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager.Confetti"))
local numberUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.NumberUtilities"))

local getUserDataRemote: RemoteFunction = coreModule.Shared.GetObject("//Remotes.GetUserData")
local eventsInterface: GuiObject = userInterfaceManager.GetInterface("Events")
local eventsInterfaceContainer: GuiObject = eventsInterface:WaitForChild("Container")

local ThisInterfaceManager = {}

-- Initialize
function ThisInterfaceManager.Initialize()
    ThisInterfaceManager.UpdateContent()
end

-- Updates all of the event visuals.
function ThisInterfaceManager.UpdateContent()

    -- Has something gone wrong?
    local userData: {} = getUserDataRemote:InvokeServer()
    if not userData then return end

    -- We want to check all of the children in the container.
    for _, eventVisual: GuiObject in next, eventsInterfaceContainer:GetChildren() do
        if eventVisual:IsA("Frame") and userData.UserEventInformation[eventVisual.Name] then

            local thisEventInformation: {} = userData.UserEventInformation[eventVisual.Name]
            local eventVisualContent: GuiObject = eventVisual:WaitForChild("Content")
            local shouldEventVisualBeVisible: boolean = ThisInterfaceManager._ShouldEventVisualBeVisible(thisEventInformation)

            -- Should it be visible? We need to check if they just completed it.
            if not shouldEventVisualBeVisible and eventVisual.Visible then
                task.spawn(confettiInterfaceManager.CreateConfettiDisplay)
            end

            -- Updating the interface.
            eventVisual.Visible = shouldEventVisualBeVisible
            eventVisual.LayoutOrder = ThisInterfaceManager._CalculateLayoutOrder(thisEventInformation)
            eventVisualContent:WaitForChild("Title").Text = thisEventInformation.Name
            eventVisualContent:WaitForChild("Progress").Text = thisEventInformation.ProgressText
        end
    end

    -- Should we enable the interface?
    eventsInterface.Enabled = ThisInterfaceManager._ShouldEventInterfaceBeEnabled(userData.UserEventInformation)
end

-- Returns whether or not this event visual should be visible.
function ThisInterfaceManager._ShouldEventVisualBeVisible(thisEventInformation: {}) : boolean
    if thisEventInformation.Completed then return false end
    if thisEventInformation.IsProgressBound and thisEventInformation.Progress == 0 then return false end

    return true
end

-- Returns whether or not the event interface should be enabled.
function ThisInterfaceManager._ShouldEventInterfaceBeEnabled(userEventInformation: {}) : boolean

    local shouldTheEventInterfaceBeEnabled: boolean = false

    -- Checking all of the events.
    for _, thisEventInformation: {} in next, userEventInformation do
        if ThisInterfaceManager._ShouldEventVisualBeVisible(thisEventInformation) then
            shouldTheEventInterfaceBeEnabled = true
        end
    end

    return shouldTheEventInterfaceBeEnabled
end

-- Returns the layout order value given the event information.
function ThisInterfaceManager._CalculateLayoutOrder(thisEventInformation: {}) : number
    return -(thisEventInformation.Progress * 1000) - numberUtilities.Sum(
        string.byte(thisEventInformation.Name, 1, 3)
    )
end

return ThisInterfaceManager
