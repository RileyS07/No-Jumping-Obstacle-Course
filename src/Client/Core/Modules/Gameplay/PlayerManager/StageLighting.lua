local lighting: Lighting = game:GetService("Lighting")

local coreModule = require(script:FindFirstAncestor("Core"))
local instanceUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.InstanceUtilities"))
local tableUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.TableUtilities"))

local lightingDirectory: Instance = coreModule.Shared.GetObject("//Assets.Lighting")
local getUserDataRemote: RemoteFunction = coreModule.Shared.GetObject("//Remotes.GetUserData")
local userInformationUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.UserInformationUpdated")

local StageLightingManager = {}

-- Initialize
function StageLightingManager.Initialize()

    -- We need the default lighting to exist or else we can never revert.
    if not lightingDirectory:FindFirstChild("Default") then
        warn(lightingDirectory:GetFullName() .. ".Default does not exist!")
        warn("This user will not have any lighting updates!")
        return
    elseif not lightingDirectory.Default:FindFirstChild("Properties") then
        warn(lightingDirectory:GetFullName() .. ".Default.Properties does not exist!")
        warn("This user will not have any lighting updates!")
        return
    end

    -- This is to update it when the user first joins.
    StageLightingManager.UpdateLighting(getUserDataRemote:InvokeServer())

    -- This updates it while the user is playing.
    userInformationUpdatedRemote.OnClientEvent:Connect(StageLightingManager.UpdateLighting)
end

-- This updates the lighting effects that are displayed for this user.
function StageLightingManager.UpdateLighting(userData: {})

    -- If this is not valid then something has gone terribly wrong.
    if not userData then return end

    -- We need the lighting information before we can do anything.
    local thisLightingInformation: Instance = StageLightingManager._DetermineLightingInformation(userData)
    local defaultLightingInformation: Instance = lightingDirectory.Default

    -- Replace the Sky.
    if thisLightingInformation:FindFirstChildOfClass("Sky") then
        instanceUtilities.SafeDestroy(lighting:FindFirstChildOfClass("Sky"))
        thisLightingInformation:FindFirstChildOfClass("Sky"):Clone().Parent = lighting

    elseif defaultLightingInformation:FindFirstChildOfClass("Sky") then
        instanceUtilities.SafeDestroy(lighting:FindFirstChildOfClass("Sky"))
        defaultLightingInformation:FindFirstChildOfClass("Sky"):Clone().Parent = lighting
    end

    -- Replacing the Atmosphere.
    if thisLightingInformation:FindFirstChildOfClass("Atmosphere") then
        instanceUtilities.SafeDestroy(lighting:FindFirstChildOfClass("Atmosphere"))
        thisLightingInformation:FindFirstChildOfClass("Atmosphere"):Clone().Parent = lighting

    elseif defaultLightingInformation:FindFirstChildOfClass("Atmosphere") then
        instanceUtilities.SafeDestroy(lighting:FindFirstChildOfClass("Atmosphere"))
        defaultLightingInformation:FindFirstChildOfClass("Atmosphere"):Clone().Parent = lighting
    end

    -- Update the ColorCorrection.
    if thisLightingInformation:FindFirstChildOfClass("ColorCorrectionEffect") then
        instanceUtilities.SafeDestroy(lighting:FindFirstChildOfClass("ColorCorrectionEffect"))
        thisLightingInformation:FindFirstChildOfClass("ColorCorrectionEffect").Parent = lighting
    else
        instanceUtilities.SafeDestroy(lighting:FindFirstChildOfClass("ColorCorrectionEffect"))
    end

    -- Updating the properties; We synchronize so we can fill in any gaps created.
    local propertiesDictionary = tableUtilities.Sync(
        thisLightingInformation:FindFirstChild("Properties") and require(thisLightingInformation.Properties) or {},
        require(lightingDirectory.Default.Properties)
    )

    for propertyName: string, propertyValue: any in next, propertiesDictionary do
        pcall(function()
            lighting[propertyName] = propertyValue
        end)
    end
end

-- Determines what lighting information should be used.
function StageLightingManager._DetermineLightingInformation(userData: {}) : Instance

    local currentBonusStageName: string = userData.UserInformation.CurrentBonusStage
    local currentCheckpoint: number = userData.UserInformation.CurrentCheckpoint

    -- First we want to try to apply for bonus stages.
    if currentBonusStageName ~= "" then
        return lightingDirectory:FindFirstChild(currentBonusStageName) or lightingDirectory.Default
    end

    -- Now we want to check if there is special lighting for this trial stage if it is one.
    if currentCheckpoint > 0 and currentCheckpoint % 10 == 0 then
        if lightingDirectory:FindFirstChild("Zone " .. tostring(currentCheckpoint / 10) .. " Trial") then
            return lightingDirectory:FindFirstChild("Zone " .. tostring(currentCheckpoint / 10) .. " Trial")
        end
    end

	-- We want to check if there is any for this special stage before moving on.
	if lightingDirectory:FindFirstChild("Stage " .. currentCheckpoint) then
		return lightingDirectory["Stage " .. currentCheckpoint]
	end

	-- Is there any for this zone?
	if lightingDirectory:FindFirstChild("Zone " .. tostring(math.ceil(currentCheckpoint / 10))) then
		return lightingDirectory["Zone " .. tostring(math.ceil(currentCheckpoint / 10))]
	end

    -- No other options.
    return lightingDirectory.Default
end

return StageLightingManager
