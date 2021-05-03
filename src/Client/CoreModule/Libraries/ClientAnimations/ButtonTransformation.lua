-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local buttonMechanicManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.Buttons"))
local clientAnimationsLibrary = require(coreModule.GetObject("/Parent"))

-- Methods
function specificClientAnimation.Play(platformObject, simulationLength)
    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("Model") or not platformObject.PrimaryPart then return end
    if not platformObject:FindFirstChild("TransformationModel") then return end
    if typeof(simulationLength) ~= "number" or simulationLength <= 0 then return end

    -- This is where the transformation happens; CanCollide is inversed and the transparency is changed based on the attributes/defaults.
    local function transformButtonTransformationModel()
        for _, basePart in next, platformObject.TransformationModel:GetDescendants() do
            if basePart:IsA("BasePart") then
                clientAnimationsLibrary.PlayAnimation("GeneralAppearanceChanged", basePart)

                basePart.CanCollide = not basePart.CanCollide
                basePart.Transparency = 
                    -- Visible
                    basePart.CanCollide and (platformObject:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) 
                    -- Invisible
                    or (platformObject:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)
            end
        end
    end

    -- Simulating the effect to sync with the button.
    transformButtonTransformationModel()
	wait(simulationLength)
	transformButtonTransformationModel()
    wait(0.5)
	
	buttonMechanicManager.UpdatePlatformBeingSimulated(platformObject, nil)
end


--
return specificClientAnimation