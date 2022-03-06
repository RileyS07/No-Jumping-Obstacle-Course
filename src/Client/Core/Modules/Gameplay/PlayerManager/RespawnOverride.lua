local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local respawnUserRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.RespawnUser")

local RespawnOverrideManager = {}
RespawnOverrideManager.CanRespawn = true

-- Initialize
function RespawnOverrideManager.Initialize()

    -- Overriding the Respawn button.
    -- First ResetButtonCallback requires us to create a bindable event for this.
    local bindableEventToCallHandler: BindableEvent = Instance.new("BindableEvent")

    bindableEventToCallHandler.Event:Connect(function()

        -- If they can't respawn what are they doing.
        if not RespawnOverrideManager.GetCanRespawn() then return end

        -- They can respawn!
        RespawnOverrideManager.SetCanRespawn(false)
        respawnUserRemote:FireServer()
        task.wait(sharedConstants.GENERAL.DELAY_BETWEEN_PLAYER_RESETS)
        RespawnOverrideManager.SetCanRespawn(true)
    end)

    -- Binding it.
    playerUtilities.SetCore(
        "ResetButtonCallback",
        bindableEventToCallHandler
    )
end

-- Returns whether or not the user can respawn.
function RespawnOverrideManager.GetCanRespawn() : boolean
    return RespawnOverrideManager.CanRespawn
end

-- Sets whether or not the user can respawn.
function RespawnOverrideManager.SetCanRespawn(canRespawn: boolean)
    RespawnOverrideManager.CanRespawn = canRespawn
end

return RespawnOverrideManager
