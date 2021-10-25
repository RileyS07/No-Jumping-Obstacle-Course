-- Variables
local specificClientAnimation = {}
specificClientAnimation.DefaultKeybinds = {
    [Enum.UserInputType.MouseMovement] = "Shift",
    [Enum.UserInputType.Keyboard] = "Shift",
    [Enum.UserInputType.Touch] = "Click",
    [Enum.UserInputType.Gamepad1] = "R2"
}

local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function specificClientAnimation.Play(isShiftLockActive, shiftLockIcon, keybindNameText)
    if typeof(shiftLockIcon) ~= "Instance" or not shiftLockIcon:IsA("ImageLabel") then return end
    if typeof(keybindNameText) ~= "Instance" or not keybindNameText:IsA("TextLabel") then return end

    -- Update the icon.
    shiftLockIcon.Image = isShiftLockActive and "rbxasset://textures/ui/mouseLock_on@2x.png" or "rbxasset://textures/ui/mouseLock_off@2x.png"

    -- Update the keybindNameText.
    if specificClientAnimation.DefaultKeybinds[coreModule.Services.UserInputService:GetLastInputType()] then
        keybindNameText.Text = specificClientAnimation.DefaultKeybinds[coreModule.Services.UserInputService:GetLastInputType()]
    end
end


--
return specificClientAnimation