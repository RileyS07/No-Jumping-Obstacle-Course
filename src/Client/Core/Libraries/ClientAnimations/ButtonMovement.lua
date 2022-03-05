-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local soundEffectsManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.SoundEffects"))

-- Methods
function specificClientAnimation.Play(platformObject, simulationLength)
    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end
    if typeof(simulationLength) ~= "number" or simulationLength <= 0 then return end

    -- The button will move down and then back up later and change colors.
    local buttonMovementTweenInfo = TweenInfo.new(math.min(1, simulationLength/2), Enum.EasingStyle.Linear)

    -- Downwards.
    platformObject.PrimaryPart.Color = script:GetAttribute("ActiveStateColor") or Color3.fromRGB(255, 0, 0)
    soundEffectsManager.PlaySoundEffect("ButtonActivated", platformObject.PrimaryPart)
    game:GetService("TweenService"):Create(
        platformObject.PrimaryPart, 
        buttonMovementTweenInfo, 
        {CFrame = platformObject:GetPrimaryPartCFrame()*CFrame.new(-(script:GetAttribute("ActiveStateOffset") or Vector3.new(0, 0.3, 0)))}
    ):Play()

    task.wait(simulationLength - math.min(1, simulationLength/2))

    -- Upwards.
    local upwardsTweenObject = game:GetService("TweenService"):Create(
        platformObject.PrimaryPart, buttonMovementTweenInfo, {
            CFrame = platformObject:GetPrimaryPartCFrame()*CFrame.new(script:GetAttribute("ActiveStateOffset") or Vector3.new(0, 0.3, 0))
        }
    )

    upwardsTweenObject:Play()
    upwardsTweenObject.Completed:Wait()
    platformObject.PrimaryPart.Color = script:GetAttribute("InactiveStateColor") or Color3.fromRGB(104, 212, 113)
end


--
return specificClientAnimation