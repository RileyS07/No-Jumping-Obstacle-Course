local teleportService: TeleportService = game:GetService("TeleportService")
local runService: RunService = game:GetService("RunService")

local TeleportServiceWrapper = {}
TeleportServiceWrapper.AutomaticRetry = true
TeleportServiceWrapper._TeleportInitFailedListener = nil

-- Returns an access code that can be used to teleport players to a reserved server, along with the DataModel.PrivateServerId for it
function TeleportServiceWrapper.ReserveServer(placeId: number) : (string, string)
    return teleportService:ReserveServer(placeId)
end

-- The all encompassing method to teleport a player or group of players from one server to another.
function TeleportServiceWrapper.TeleportAsync(placeId: number, players: {Player}, teleportOptions: TeleportOptions?) : TeleportAsyncResult?

    -- We cannot teleport in studio or on the client.
    if runService:IsStudio() or not runService:IsServer() then return end

    -- Let's try once before anything else.
    local wasSuccessful: boolean, resultValue: TeleportAsyncResult | string = pcall(
        teleportService.TeleportAsync, teleportService, placeId, players, teleportOptions
    )

    -- Uh oh! It wasn't successful!
    if not wasSuccessful then
        warn(resultValue)

        -- We only retry if this is true.
        if TeleportServiceWrapper.AutomaticRetry then
            repeat
                task.wait(1)

                -- Trying again.
                wasSuccessful, resultValue = pcall(
                    teleportService.TeleportAsync, teleportService, placeId, players, teleportOptions
                )

                -- We need to debug again.
                if not wasSuccessful then
                    warn(resultValue)
                end
            until wasSuccessful
        end
    end

    return resultValue :: TeleportAsyncResult
end

-- Creates a TeleportOptions instance given the property values.
function TeleportServiceWrapper.CreateTeleportOptions(reservedServerAccessCode: string?, serverInstanceId: string?, shouldReserveServer: boolean?) : TeleportOptions

    local teleportOptions: TeleportOptions = Instance.new("TeleportOptions")
    teleportOptions.ReservedServerAccessCode = reservedServerAccessCode or ""
    teleportOptions.ServerInstanceId = serverInstanceId or ""
    teleportOptions.ShouldReserveServer = not not shouldReserveServer

    return teleportOptions
end

-- Initialization
if runService:IsServer() then
    if not TeleportServiceWrapper._TeleportInitFailedListener then

        -- We can output what type of error is happening to give better feedback.
        TeleportServiceWrapper._TeleportInitFailedListener = teleportService.TeleportInitFailed:Connect(function(_, teleportResult: Enum.TeleportResult, errorMessage: string)
            warn(string.format("Invalid teleport [%s]: %s", teleportResult.Name, errorMessage))
        end)
    end
end

return TeleportServiceWrapper
