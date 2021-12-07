-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.CurrentRenderedParts = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local mechanicsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("Powerups"):WaitForChild("Radar")


    -- RadarStatusUpdated determines how we render the accessableParts.
    coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.RadarStatusUpdated").OnClientEvent:Connect(function(accessableParts)
        
        -- Backtrack and get rid of old rendered parts.
        if not accessableParts or (accessableParts and #gameplayMechanicManager.CurrentRenderedParts > 0) then
            gameplayMechanicManager.SimulateMechanic(false)
        end

        -- Render new parts.
        if typeof(accessableParts) == "table" and #accessableParts > 0 then
            gameplayMechanicManager.CurrentRenderedParts = accessableParts
            gameplayMechanicManager.SimulateMechanic(true)
        end
    end)
end


-- Methods
function gameplayMechanicManager.SimulateMechanic(renderStatus)
    for _, renderObject in next, gameplayMechanicManager.CurrentRenderedParts do
        if renderObject:IsA("BasePart") or (renderObject:IsA("ObjectValue") and renderObject.Value and renderObject.Value:IsA("BasePart")) then
            local basePart = renderObject:IsA("ObjectValue") and renderObject.Value or renderObject

            -- renderStatus == true and visible or invisible.
            basePart.Transparency = renderStatus and (script:GetAttribute("DefaultVisibleTransparency") or 0) or (script:GetAttribute("DefaultInvisibleTransparency") or 1)

            -- Update particles.
            if basePart:FindFirstChildOfClass("ParticleEmitter") then
                basePart:FindFirstChildOfClass("ParticleEmitter").Enabled = renderStatus
            end

            -- Update lights.
            if basePart:FindFirstChildOfClass("Light") then
                basePart:FindFirstChildOfClass("Light").Enabled = renderStatus
            end
        end
    end
end


--
return gameplayMechanicManager