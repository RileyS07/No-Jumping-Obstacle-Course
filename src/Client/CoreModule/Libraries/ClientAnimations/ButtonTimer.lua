-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))

-- Methods
function specificClientAnimation.Play(buttonObject, simulationLength, showTimerCountdown)
    if not showTimerCountdown then return end
    
    if typeof(buttonObject) ~= "Instance" or not buttonObject:IsA("Model") or not buttonObject.PrimaryPart then return end
    if not buttonObject.PrimaryPart:FindFirstChild("TimerInterface") or not buttonObject.PrimaryPart.TimerInterface:FindFirstChild("TimerState") then return end
    if typeof(simulationLength) ~= "number" or simulationLength <= 0 then return end

    -- Button timer; 30 -> 29 -> 28 -> ...
    local timerStateText = buttonObject.PrimaryPart.TimerInterface.TimerState

    for index = simulationLength, 1, -1 do
        timerStateText.Text = index
        wait(1)
    end

    timerStateText.Text = script:GetAttribute("InactiveStateText") or "Press me!"
end


--
return specificClientAnimation