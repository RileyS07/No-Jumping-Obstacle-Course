-- Variables
local specificClientAnimation = {}

-- Methods
function specificClientAnimation.Play(effectInformationDisplay)
    if typeof(effectInformationDisplay) ~= "Instance" or not effectInformationDisplay:IsA("GuiObject") then return end
    effectInformationDisplay:Destroy()
end


--
return specificClientAnimation