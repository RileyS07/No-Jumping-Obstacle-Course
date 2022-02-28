local marketplaceService: MarketplaceService = game:GetService("MarketplaceService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local PurchaseManager = {}

-- Initialize
function PurchaseManager.Initialize()

    -- When a player tries to purchase a product in-game.
    marketplaceService.ProcessReceipt = function(receiptInformation: {})

        -- Is this player valid?
        local player: Player? = players:GetPlayerByUserId(receiptInformation.PlayerId)

        if not playerUtilities.IsPlayerValid(player) then
            return Enum.ProductPurchaseDecision.NotProcessedYet
        end

        -- Can we find the product module representing this ProductId?
        for _, moduleScript: Instance in next, script:GetChildren() do
            if tonumber(string.match(moduleScript.Name, "%d+")) == receiptInformation.ProductId then
                require(moduleScript).Process(player)
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end

        return Enum.ProductPurchaseDecision.NotProcessedYet
    end

    -- Testing code to make sure purchase handlers are setup for all devproducts.
    local developerProductsPages: Pages = marketplaceService:GetDeveloperProductsAsync()

    while true do
        for _, developerProductInformation: {} in next, developerProductsPages:GetCurrentPage() do

            -- Checking to see if the purchase handler for this exists.
            local doesPurchaseHandlerExist: boolean = false

            for _, moduleScript: Instance in next, script:GetChildren() do
                if tonumber(string.match(moduleScript.Name, "%d+")) == developerProductInformation.ProductId then
                    if moduleScript:IsA("ModuleScript") and require(moduleScript).Process then
                        doesPurchaseHandlerExist = true
                        break
                    end
                end
            end

            -- Does it not exist?
            if not doesPurchaseHandlerExist then
                warn(string.format(
                    "Purchase handler for developer product named: %s, id: %d does not exist!",
                    developerProductInformation.Name,
                    developerProductInformation.ProductId
                ))
            end
        end

        if developerProductsPages.IsFinished then
            break
        end

        developerProductsPages:AdvanceToNextPageAsync()
    end
end

return PurchaseManager
