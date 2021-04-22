-- Variables
local specificClientAnimation = {}

-- Methods
function specificClientAnimation.Play(container)
    if not container or typeof(container) ~= "Instance" or not container:IsA("GuiObject") then return end

    container.Visible = true
end


--
return specificClientAnimation