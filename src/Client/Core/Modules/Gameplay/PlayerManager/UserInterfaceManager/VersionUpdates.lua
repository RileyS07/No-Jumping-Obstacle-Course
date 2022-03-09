local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local thisInterface: GuiBase2d = userInterfaceManager.GetInterface(script.Name)
local versionUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.VersionUpdated")
local isReservedServerRemote: RemoteFunction = coreModule.Shared.GetObject("//Remotes.IsReservedServer")

local ThisInterfaceManager = {}

-- Initialize
function ThisInterfaceManager.Initialize()

    -- This is called when the server is shutdown.
    -- This is what signals an incoming update.
    versionUpdatedRemote.OnClientEvent:Connect(function()
        userInterfaceManager.UpdateInterfaceShown(thisInterface)
        playerUtilities.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end)

    -- If it's a reserved server then we know this is phase 1 of the 2 phase update procedure.
    if isReservedServerRemote:InvokeServer() then
        userInterfaceManager.UpdateInterfaceShown(thisInterface)
        playerUtilities.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end
end

return ThisInterfaceManager
