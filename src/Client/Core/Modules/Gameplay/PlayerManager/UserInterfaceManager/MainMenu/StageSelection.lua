-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}
specificInterfaceManager.UserData = nil
specificInterfaceManager.CurrentZone = 1
specificInterfaceManager.ZoneNames = {
    "The Legacy", "The Mist", "The Infectious", "The Glaciers", "The Platform", "The Abstract", "The Eerie", "The Valley", "The Time", "The Champions"
}

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.Container = userInterfaceManager.GetInterface("MainMenu"):WaitForChild("Container"):WaitForChild("Stages")
    specificInterfaceManager.Interface.Header = specificInterfaceManager.Interface.Container:WaitForChild("Header")
    specificInterfaceManager.Interface.Content = specificInterfaceManager.Interface.Container:WaitForChild("Content")
    specificInterfaceManager.UserData = coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()
    specificInterfaceManager.CurrentZone = math.ceil(specificInterfaceManager.UserData.UserInformation.CurrentCheckpoint/10)

    -- Open the container.
    specificInterfaceManager.UpdateContent()

    -- Stage updated.
    coreModule.Shared.GetObject("//Remotes.UserInformationUpdated").OnClientEvent:Connect(function(userData)
        specificInterfaceManager.UserData = userData
        specificInterfaceManager.UpdateContent()
    end)

    -- Setting up the interface.
    for _, button in next, specificInterfaceManager.Interface.Content:GetChildren() do
        if button:IsA("TextButton") and tonumber(button.Name) then
            button.Activated:Connect(function()
                if specificInterfaceManager.UserData.UserInformation.FarthestCheckpoint < (specificInterfaceManager.CurrentZone - 1)*10 + tonumber(button.Name) then return end
                coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportToStage"):FireServer((specificInterfaceManager.CurrentZone - 1)*10 + tonumber(button.Name))
            end)
        end
    end

    specificInterfaceManager.Interface.Header.Buttons.Right.Activated:Connect(function()
        if specificInterfaceManager.CurrentZone >= math.ceil(specificInterfaceManager.UserData.UserInformation.FarthestCheckpoint/10) then return end
        specificInterfaceManager.CurrentZone += 1
        specificInterfaceManager.UpdateContent()
    end)

    specificInterfaceManager.Interface.Header.Buttons.Left.Activated:Connect(function()
        if specificInterfaceManager.CurrentZone <= 1 then return end
        specificInterfaceManager.CurrentZone -= 1
        specificInterfaceManager.UpdateContent()
    end)
end


-- Methods
function specificInterfaceManager.UpdateContent()
    for _, button in next, specificInterfaceManager.Interface.Content:GetChildren() do
        if tonumber(button.Name) then
            button.TextLabel.Text = (specificInterfaceManager.CurrentZone - 1)*10 + tonumber(button.Name)
            button.TextLabel.TextColor3 = (tonumber(button.Name) == (specificInterfaceManager.UserData.UserInformation.CurrentCheckpoint - (specificInterfaceManager.CurrentZone - 1)*10)) and Color3.fromRGB(30, 198, 227) or Color3.fromRGB(55, 71, 79)
            button.Visible = tonumber(button.Name) <= (specificInterfaceManager.UserData.UserInformation.FarthestCheckpoint - (specificInterfaceManager.CurrentZone - 1)*10)
        end
    end

    -- Update the header.
    specificInterfaceManager.Interface.Header.Description.Title.Text = "Zone "..tostring(specificInterfaceManager.CurrentZone)..": "..(specificInterfaceManager.ZoneNames[specificInterfaceManager.CurrentZone] or "???")
    specificInterfaceManager.Interface.Header.Description.StageCount.Text = tostring(math.clamp(specificInterfaceManager.UserData.UserInformation.FarthestCheckpoint - (specificInterfaceManager.CurrentZone - 1)*10, 1, 10)).." out of 10 stages"
    specificInterfaceManager.Interface.Header.Buttons.Right.ImageTransparency = (specificInterfaceManager.CurrentZone < math.ceil(specificInterfaceManager.UserData.UserInformation.FarthestCheckpoint/10)) and 0.2 or 0.8
    specificInterfaceManager.Interface.Header.Buttons.Left.ImageTransparency = (specificInterfaceManager.CurrentZone > 1) and 0.2 or 0.8
end


--
return specificInterfaceManager