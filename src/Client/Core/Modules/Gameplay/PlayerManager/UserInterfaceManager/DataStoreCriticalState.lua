local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

local contentFrame: Frame = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Outage")
local dataStoreCriticalStateRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.DataStoreCriticalState")
local getIsDataStoreInCriticalState: RemoteFunction = coreModule.Shared.GetObject("//Remotes.GetIsDataStoreInCriticalState")

local ThisInterfaceManager = {}

-- Initialize
function ThisInterfaceManager.Initialize()

    -- Making the warning visible / invisible.
    contentFrame.Visible = getIsDataStoreInCriticalState:InvokeServer()

    dataStoreCriticalStateRemote.OnClientEvent:Connect(function(isCritical: boolean)
        contentFrame.Visible = isCritical
    end)
end

return ThisInterfaceManager
