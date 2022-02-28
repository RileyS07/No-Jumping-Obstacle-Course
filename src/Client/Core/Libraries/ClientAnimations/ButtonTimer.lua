-- Variables
local specificClientAnimation = {}
--local coreModule = require(script:FindFirstAncestor("Core"))
--local soundEffectsManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.SoundEffects"))

-- Methods
function specificClientAnimation.Play(platformObject, simulationLength, showTimerCountdown)
    if not showTimerCountdown then return end

    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end
    if not platformObject.PrimaryPart:FindFirstChild("TimerInterface") or not platformObject.PrimaryPart.TimerInterface:FindFirstChild("TimerState") then return end
    if typeof(simulationLength) ~= "number" or simulationLength <= 0 then return end

    -- Button timer; 30 -> 29 -> 28 -> ...
    local timerStateText = platformObject.PrimaryPart.TimerInterface.TimerState

    for index = simulationLength, 1, -1 do
        timerStateText.Text = index
        task.wait(1)
    end

    timerStateText.Text = script:GetAttribute("InactiveStateText") or "Press me!"
end


--
return specificClientAnimation