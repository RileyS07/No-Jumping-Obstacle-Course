-- Variables
local skippingInterface = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))

-- Initialize
function skippingInterface.Initialize()
    userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Containers"):WaitForChild("TopbarContainer"):WaitForChild("Skip").Activated:Connect(function()
        game:GetService("MarketplaceService"):PromptProductPurchase(
            game:GetService("Players").LocalPlayer,
            976456113
        )
    end)
end

--
return skippingInterface