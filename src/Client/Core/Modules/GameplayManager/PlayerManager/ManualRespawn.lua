-- Variables
local manualRespawnManager: {} = {}
manualRespawnManager.CanRespawn = true

local coreModule: {} = require(script:FindFirstAncestor("Core"))

-- Initialize
function manualRespawnManager.Initialize()

    -- Creating the button.
    game:GetService("ContextActionService"):BindAction(
        "RespawnUser",
        manualRespawnManager._HandleRespawn,
        true,
        Enum.KeyCode.R
    )

    -- Overriding the Respawn button.
    local bindableEventToCallHandler: BindableEvent = Instance.new("BindableEvent")
    bindableEventToCallHandler.Event:Connect(function()
        manualRespawnManager._HandleRespawn("", Enum.UserInputState.Begin)
    end)

    game:GetService("StarterGui"):SetCore("ResetButtonCallback", bindableEventToCallHandler)
end

-- Private Methods
function manualRespawnManager._HandleRespawn(_, userInputState: Enum.UserInputState)
    if userInputState ~= Enum.UserInputState.Begin then return end
    if not manualRespawnManager.CanRespawn then return end

    manualRespawnManager.CanRespawn = false
    coreModule.Shared.GetObject("//Remotes.RespawnUser"):FireServer()
    task.wait(2)
    manualRespawnManager.CanRespawn = true
end

--
return manualRespawnManager