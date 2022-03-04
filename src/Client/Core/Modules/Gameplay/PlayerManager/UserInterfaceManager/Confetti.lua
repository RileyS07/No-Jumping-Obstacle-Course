local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local confettiClass = require(coreModule.GetObject("Libraries.Animations.Confetti"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

type Confetti = typeof(confettiClass.Confetti)

local ThisInterfaceManager = {}

-- Initialize
function ThisInterfaceManager.Initialize()

    coreModule.Shared.GetObject("//Remotes.DoConfettiDisplay").OnClientEvent:Connect(function(maxCycleCount: number?)
        ThisInterfaceManager.CreateConfettiDisplay(maxCycleCount)
    end)
end

-- Does a confetti display on the screen.
function ThisInterfaceManager.CreateConfettiDisplay(maxCycleCount: number?)

    -- TEMPORARY CODE.
    userInterfaceManager.GetInterface(script.Name).Enabled = true

    -- We create two in each corner.
    local firstConfettiInstance: Confetti = ThisInterfaceManager._CreateConfettiInstance(UDim2.fromScale(0.25, -0.1), maxCycleCount)
    local secondConfettiInstance: Confetti = ThisInterfaceManager._CreateConfettiInstance(UDim2.fromScale(0.75, -0.1), maxCycleCount)

    -- Let's start both of these.
    firstConfettiInstance:Enable()
    secondConfettiInstance:Enable()

    -- Let's wait to delete them.
    task.spawn(function()
        firstConfettiInstance.Finished.Event:Wait()
        firstConfettiInstance:Destroy()
    end)

    task.spawn(function()
        secondConfettiInstance.Finished.Event:Wait()
        secondConfettiInstance:Destroy()
    end)
end

-- Creates a confetti instance and adds particles.
function ThisInterfaceManager._CreateConfettiInstance(emitterPosition: UDim2?, maxCycleCount: number?) : Confetti

    -- This is where we can play the confetti sound.
    local newConfettiInstance: Confetti = confettiClass.new()

    -- We need to add all of the particles.
    newConfettiInstance:AddParticles(
        userInterfaceManager.GetInterface(script.Name),
        sharedConstants.INTERFACE.CONFETTI_DEFAULT_PARTICLE_AMOUNT,
        {MaxCycleCount = maxCycleCount or sharedConstants.INTERFACE.CONFETTI_DEFAULT_MAX_CYCLE_COUNT},
        emitterPosition
    )

    return newConfettiInstance
end

return ThisInterfaceManager
