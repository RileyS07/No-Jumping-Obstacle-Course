-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Methods
function specificClientAnimation.Play(platformObject, beatMapIndex, numberOfBlinks, blinkLength)
    if typeof(platformObject) ~= "Instance" then return end
    if typeof(beatMapIndex) ~= "number" then return end
    if typeof(numberOfBlinks) ~= "number" then return end
    if typeof(blinkLength) ~= "number" then return end

    -- Blinking animation.
    for _ = 1, numberOfBlinks do
        for _, basePart in next, platformObject:GetDescendants() do
            if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) == beatMapIndex then
                game:GetService("TweenService"):Create(
                    basePart, 
                    TweenInfo.new(blinkLength/2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true), 
                    {Transparency = script:GetAttribute("GoalTransparency") or 0.5, Color = script:GetAttribute("GoalColor") or Color3.new(1, 1, 1)}
                ):Play()
            end

            -- The blinking animation plays only for baseparts about to switch; This one plays for all of them that are valid.
            if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
                clientAnimationsLibrary.PlayAnimation("GeneralAppearanceChanged", platformObject, 2)
                soundEffectsManager.PlaySoundEffect("Beep", {Parent = basePart})
            end
        end

        task.wait(blinkLength)
    end
end


--
return specificClientAnimation