-- Variables
local specificClientAnimation = {}

-- Methods
function specificClientAnimation.Play(container)
    if typeof(container) ~= "Instance" or not container:IsA("GuiObject") then return end

    container.Visible = true
end


--
return specificClientAnimation