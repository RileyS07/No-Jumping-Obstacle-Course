-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientAnimationsLibrary = require(coreModule.GetObject("/Parent"))

-- Methods
function specificClientAnimation.Play(platformObject)
    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("BasePart") then return end

    -- This is where the transformation happens; CanCollide is inversed and the transparency is changed based on the attributes/defaults.
    platformObject.CanCollide = not platformObject.CanCollide
    platformObject.Transparency = 
                -- Visible
                platformObject.CanCollide and (platformObject:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) 
                -- Invisible
                or (platformObject:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)

    clientAnimationsLibrary.PlayAnimation("GeneralAppearanceChanged", platformObject, 2)
end


--
return specificClientAnimation