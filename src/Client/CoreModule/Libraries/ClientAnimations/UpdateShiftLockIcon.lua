-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function specificClientAnimation.Play(shiftLockIcon, isShiftLockActive)
    if typeof(shiftLockIcon) ~= "Instance" or not shiftLockIcon:IsA("ImageButton") then return end

    -- Update the icon.
    shiftLockIcon.Image = isShiftLockActive and "rbxasset://textures/ui/mouseLock_on@2x.png" or "rbxasset://textures/ui/mouseLock_off@2x.png"
end


--
return specificClientAnimation