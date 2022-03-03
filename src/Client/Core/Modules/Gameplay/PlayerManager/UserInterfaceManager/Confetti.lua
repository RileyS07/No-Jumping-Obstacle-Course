local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local confettiClass = require(coreModule.GetObject("Libraries.Animations.Confetti"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local ThisInterfaceManager = {}

-- Initialize
function ThisInterfaceManager.Initialize()
    task.delay(20, ThisInterfaceManager.CreateConfettiDisplay, 1)
end

-- Does a confetti display on the screen.
function ThisInterfaceManager.CreateConfettiDisplay(maxCycleCount: number, maxParticleCount: number?)

    local newConfettiInstance = confettiClass.new()
    userInterfaceManager.GetInterface(script.Name).Enabled = true

    -- We need to add all of the particles first.
    newConfettiInstance:AddParticles(
        userInterfaceManager.GetInterface(script.Name),
        maxParticleCount or sharedConstants.INTERFACE.CONFETTI_DEFAULT_PARTICLE_AMOUNT,
        maxCycleCount
    )

    newConfettiInstance:Enable()

    -- Let's wait till it finishes.
    newConfettiInstance.Finished.Event:Wait()
    print("What2")
    newConfettiInstance:Destroy()
end

return ThisInterfaceManager
