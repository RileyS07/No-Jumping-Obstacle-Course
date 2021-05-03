-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))

-- Methods
function specificClientAnimation.Play(buttonObject, simulationLength)
    if typeof(buttonObject) ~= "Instance" or not buttonObject:IsA("Model") or not buttonObject.PrimaryPart then return end
    if typeof(simulationLength) ~= "number" or simulationLength <= 0 then return end

    -- The button will move down and then back up later and change colors.
    local buttonMovementTweenInfo = TweenInfo.new(math.min(1, simulationLength/2), Enum.EasingStyle.Linear)

    -- Downwards.
    buttonObject.PrimaryPart.Color = script:GetAttribute("ActiveStateColor") or Color3.fromRGB(255, 0, 0)
    soundEffectsManager.PlaySoundEffect("ButtonActivated", {Parent = buttonObject.PrimaryPart})
    coreModule.Services.TweenService:Create(
        buttonObject.PrimaryPart, 
        buttonMovementTweenInfo, 
        {CFrame = buttonObject:GetPrimaryPartCFrame()*CFrame.new(-(script:GetAttribute("ActiveStateOffset") or Vector3.new(0, 0.3, 0)))}
    ):Play()

    wait(simulationLength - math.min(1, simulationLength/2))

    -- Upwards.
    local upwardsTweenObject = coreModule.Services.TweenService:Create(
        buttonObject.PrimaryPart, buttonMovementTweenInfo, {
            CFrame = buttonObject:GetPrimaryPartCFrame()*CFrame.new(script:GetAttribute("ActiveStateOffset") or Vector3.new(0, 0.3, 0))
        }
    )

    upwardsTweenObject:Play()
    upwardsTweenObject.Completed:Wait()
    buttonObject.PrimaryPart.Color = script:GetAttribute("InactiveStateColor") or Color3.fromRGB(104, 212, 113)
end


--
return specificClientAnimation