-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Methods
function specificClientAnimation.Play(platformObject, manualBoolean, excludeApperaceChangedEffect)
    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("BasePart") then return end

    -- This is where the transformation happens; CanCollide is inversed and the transparency is changed based on the attributes/defaults.
    if manualBoolean ~= nil then
        platformObject.CanCollide = manualBoolean
    else
        platformObject.CanCollide = not platformObject.CanCollide 
    end
    
    platformObject.Transparency = 
                -- Visible
                platformObject.CanCollide and (platformObject:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) 
                -- Invisible
                or (platformObject:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)

    -- Poof!
    if not excludeApperaceChangedEffect then
        clientAnimationsLibrary.PlayAnimation("GeneralAppearanceChanged", platformObject, 2)
    end
end


--
return specificClientAnimation