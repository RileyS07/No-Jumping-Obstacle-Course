-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.ScreenGui = userInterfaceManager.GetInterface("VersionUpdateInterface")

    -- The game's version was updated; Someone hit shutdown lol.
    coreModule.Shared.GetObject("//Remotes.Server.VersionUpdated").OnClientEvent:Connect(function()
        userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, {DisableOtherInterfaces = true})
        clientEssentialsLibrary.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end)

    -- Is it a reserved server?
    if coreModule.Shared.GetObject("//Remotes.Server.IsReservedServer"):InvokeServer() then
        userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, {DisableOtherInterfaces = true})
        clientEssentialsLibrary.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
    end
end


--
return specificInterfaceManager