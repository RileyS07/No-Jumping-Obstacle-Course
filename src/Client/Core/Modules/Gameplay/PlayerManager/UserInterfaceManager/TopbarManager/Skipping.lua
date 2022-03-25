-- Variables
local skippingInterface = {}
skippingInterface.UserData = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local TopbarContainer: Instance = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Containers"):WaitForChild("TopbarContainer")
local SkipButton: GuiButton = TopbarContainer:WaitForChild("Skip")
local SkipValue: GuiObject = SkipButton:WaitForChild("SkipValue")

-- Initialize
function skippingInterface.Initialize()

    -- WE need th ed sata. tsdgzxcvbxdtghdrfgdrfzgdfrgzdgfgdfdfg
    skippingInterface.UserData = coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()
    SkipValue.Visible = skippingInterface.UserData.UserInformation.SavedSkips > 0
    SkipValue:WaitForChild("TextLabel").Text = tostring(skippingInterface.UserData.UserInformation.SavedSkips)

    coreModule.Shared.GetObject("//Remotes.UserInformationUpdated").OnClientEvent:Connect(function(userData)
        SkipValue.Visible = userData.UserInformation.SavedSkips > 0
        SkipValue:WaitForChild("TextLabel").Text = tostring(userData.UserInformation.SavedSkips)
        skippingInterface.UserData = userData
    end)

    -- Skip.
    SkipButton.Activated:Connect(function()
        if skippingInterface.UserData then
            if skippingInterface.UserData.UserInformation.SavedSkips > 0 then
                coreModule.Shared.GetObject("//Remotes.SkipStage"):FireServer()
                return
            end
        end

        game:GetService("MarketplaceService"):PromptProductPurchase(
            game:GetService("Players").LocalPlayer,
            976456113
        )
    end)
end

--
return skippingInterface