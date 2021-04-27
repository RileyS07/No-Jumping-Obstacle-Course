-- Variables
local gameplayLightingManager = {}
gameplayLightingManager.Assets = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local tableUtilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.TableUtilities"))

-- Initialize
function gameplayLightingManager.Initialize()
    gameplayLightingManager.Assets.LightingContainer = coreModule.Shared.GetObject("//Assets.Lighting")

    -- UpdateLighting bindings.
    gameplayLightingManager.UpdateLighting(coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer())
    coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated").OnClientEvent:Connect(function(userData)
        gameplayLightingManager.UpdateLighting(userData)
    end)
end


-- Methods
function gameplayLightingManager.UpdateLighting(userData)

    -- These guard clauses make sure that both this AND UpdateLightingPostTranslation work properly.
    if not userData then return end
    if not gameplayLightingManager.Assets.LightingContainer then return end
	if #gameplayLightingManager.Assets.LightingContainer:GetChildren() == 0 then return end
    if not gameplayLightingManager.Assets.LightingContainer:FindFirstChild("Default") then return end
    if not gameplayLightingManager.Assets.LightingContainer.Default:FindFirstChild("Properties") then return end
    if not gameplayLightingManager.Assets.LightingContainer.Default.Properties:IsA("ModuleScript") then return end

    -- SpecialLocationIdentifier; Checking to see if we can apply any special lighting for these special locations.
    if userData.UserInformation.SpecialLocationIdentifier ~= coreModule.Shared.Enums.SpecialLocation.None then

        -- TherapyZone.
        if userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.TherapyZone then

			local lightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild("TherapyZone")
            if lightingContainer then
                return gameplayLightingManager.UpdateLightingPostTranslation(lightingContainer)
            else
                coreModule.Debug(
                    ("GameplayLighting: %s does not exist."):format("TherapyZone"),
                    coreModule.Shared.Enums.DebugLevel.Exception,
                    warn
                )
            end

        -- VictoryZone.
        elseif userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.VictoryZone then

			local lightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild("VictoryZone")
            if lightingContainer then
                return gameplayLightingManager.UpdateLightingPostTranslation(lightingContainer)
            else
                coreModule.Debug(
                    ("GameplayLighting: %s does not exist."):format("VictoryZone"),
                    coreModule.Shared.Enums.DebugLevel.Exception,
                    warn
                )
            end
        end
    end

    -- Next we're gonna see if they're in a BonusStage.
    if userData.UserInformation.CurrentBonusStage ~= "" then

		local lightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild(userData.UserInformation.CurrentBonusStage)
        if lightingContainer then
            return gameplayLightingManager.UpdateLightingPostTranslation(lightingContainer)
        else
            coreModule.Debug(
                ("GameplayLighting: %s does not exist."):format(userData.UserInformation.CurrentBonusStage),
                coreModule.Shared.Enums.DebugLevel.Standard,
                warn
            )

            -- Resort to the default.
            return gameplayLightingManager.UpdateLightingPostTranslation(gameplayLightingManager.Assets.LightingContainer.Default)
        end
    end

    -- Can we apply a special lighting for a Trial?
    if userData.UserInformation.CurrentCheckpoint > 0 and userData.UserInformation.CurrentCheckpoint%10 == 0 then

		local lightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild("Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial")
        if lightingContainer then
            return gameplayLightingManager.UpdateLightingPostTranslation(lightingContainer)
        else
            coreModule.Debug(
                ("GameplayLighting: %s does not exist."):format("Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial"),
                coreModule.Shared.Enums.DebugLevel.Standard,
                warn
            )
        end
    end
    
	-- Is there any for this specific stage?
	local stageSpecificLightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild("Stage "..tostring(userData.UserInformation.CurrentCheckpoint))
	if stageSpecificLightingContainer then
		return gameplayLightingManager.UpdateLightingPostTranslation(stageSpecificLightingContainer)
	else
		coreModule.Debug(
			("GameplayLighting: %s does not exist."):format("Stage "..tostring(userData.UserInformation.CurrentCheckpoint)),
			coreModule.Shared.Enums.DebugLevel.Standard,
			warn
		)
	end

	-- Is there any for this zone?
	local zoneSpecificLightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild("Zone "..tostring(math.ceil(userData.UserInformation.CurrentCheckpoint/10)))
	if zoneSpecificLightingContainer then
		return gameplayLightingManager.UpdateLightingPostTranslation(zoneSpecificLightingContainer)
	else
		coreModule.Debug(
			("GameplayLighting: %s does not exist."):format("Zone "..tostring(userData.UserInformation.CurrentCheckpoint)),
			coreModule.Shared.Enums.DebugLevel.Exception,
			warn
		)
	end

	-- Resort to the default.
    return gameplayLightingManager.UpdateLightingPostTranslation(gameplayLightingManager.Assets.LightingContainer.Default)
end


-- Private Methods
function gameplayLightingManager.UpdateLightingPostTranslation(lightingInformation)
    if typeof(lightingInformation) ~= "Instance" then return end

    -- We use the default lighting information to fill in any gaps that the new lighting information has.
    local defaultLightingInformation = gameplayLightingManager.Assets.LightingContainer.Default

    -- Replace the Sky.
    if lightingInformation:FindFirstChildOfClass("Sky") then
        utilitiesLibrary.Destroy(coreModule.Services.Lighting:FindFirstChildOfClass("Sky"))
        lightingInformation:FindFirstChildOfClass("Sky"):Clone().Parent = coreModule.Services.Lighting

    elseif defaultLightingInformation:FindFirstChildOfClass("Sky") then
        utilitiesLibrary.Destroy(coreModule.Services.Lighting:FindFirstChildOfClass("Sky"))
        defaultLightingInformation:FindFirstChildOfClass("Sky"):Clone().Parent = coreModule.Services.Lighting
    end

    -- Replace the Atmosphere.
	if lightingInformation:FindFirstChildOfClass("Atmosphere") then
		utilitiesLibrary.Destroy(coreModule.Services.Lighting:FindFirstChildOfClass("Atmosphere"))
		lightingInformation:FindFirstChildOfClass("Atmosphere"):Clone().Parent = coreModule.Services.Lighting

	elseif defaultLightingInformation:FindFirstChildOfClass("Atmosphere") then
		utilitiesLibrary.Destroy(coreModule.Services.Lighting:FindFirstChildOfClass("Atmosphere"))
		defaultLightingInformation:FindFirstChildOfClass("Atmosphere"):Clone().Parent = coreModule.Services.Lighting
	end

    -- Updating the properties; We synchronize so we can fill in any gaps created.
    local propertiesDictionary = tableUtilitiesLibrary.SynchronizeTables(
        lightingInformation:FindFirstChild("Properties") and require(lightingInformation.Properties) or {}, 
        require(gameplayLightingManager.Assets.LightingContainer.Default.Properties)
    )

    for propertyName, propertyValue in next, propertiesDictionary do
        pcall(function()
            coreModule.Services.Lighting[propertyName] = propertyValue
        end)
    end
end

--
return gameplayLightingManager
--[[
    -- Variables
local lightingManager = {}
lightingManager.UserData = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local config = require(script.Config)

-- Initialize
function lightingManager.Initialize()
	lightingManager.UserData = coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()
	
	--
	lightingManager.UpdateLighting()
	coreModule.Shared.GetObject("//Remotes.StageInformationUpdated").OnClientEvent:Connect(function(userData)
		lightingManager.UserData = userData
		lightingManager.UpdateLighting()
	end)
end

-- Methods
function lightingManager.UpdateLighting()
	if not coreModule.Shared.GetObject("//Assets.Lighting"):FindFirstChild("Default") then return end
	if not lightingManager.GetLightingInformationFromData() then return end
	
	--
	local defaultLightingInformation = coreModule.Shared.GetObject("//Assets.Lighting.Default")
	local newLightingInformation = lightingManager.GetLightingInformationFromData()
	
	-- Replacing the Sky
	if newLightingInformation:FindFirstChildOfClass("Sky") then
		utilitiesLibrary.Destroy(coreModule.Services.Lighting:FindFirstChildOfClass("Sky"))
		newLightingInformation:FindFirstChildOfClass("Sky"):Clone().Parent = coreModule.Services.Lighting
	elseif defaultLightingInformation:FindFirstChildOfClass("Sky") then
		utilitiesLibrary.Destroy(coreModule.Services.Lighting:FindFirstChildOfClass("Sky"))
		defaultLightingInformation:FindFirstChildOfClass("Sky"):Clone().Parent = coreModule.Services.Lighting
	end

	-- Replacing the Atmosphere
	if newLightingInformation:FindFirstChildOfClass("Atmosphere") then
		utilitiesLibrary.Destroy(coreModule.Services.Lighting:FindFirstChildOfClass("Atmosphere"))
		newLightingInformation:FindFirstChildOfClass("Atmosphere"):Clone().Parent = coreModule.Services.Lighting
	elseif defaultLightingInformation:FindFirstChildOfClass("Atmosphere") then
		utilitiesLibrary.Destroy(coreModule.Services.Lighting:FindFirstChildOfClass("Atmosphere"))
		defaultLightingInformation:FindFirstChildOfClass("Atmosphere"):Clone().Parent = coreModule.Services.Lighting
	end

	-- Updating the properties
	if newLightingInformation:FindFirstChild("Properties") then
		for propertyName, propertyValue in next, require(newLightingInformation.Properties) do
			coreModule.Services.Lighting[propertyName] = propertyValue
		end
	end
end

function lightingManager.GetLightingInformationFromData()
	if not lightingManager.UserData then return end
	
	--
	if lightingManager.UserData.CurrentStats.IsInTherapy and coreModule.Shared.GetObject("//Assets.Lighting"):FindFirstChild(config.TherapyMusicName) then
		return coreModule.Shared.GetObject("//Assets.Lighting."..config.TherapyMusicName)
	elseif lightingManager.UserData.CurrentStats.IsInVictory and coreModule.Shared.GetObject("//Assets.Lighting"):FindFirstChild(config.VictoryMusicName) then
		return coreModule.Shared.GetObject("//Assets.Lighting."..config.VictoryMusicName)
	elseif lightingManager.UserData.CurrentStats.BonusLevelName ~= "" and coreModule.Shared.GetObject("//Assets.Lighting"):FindFirstChild(config.BonusLevelNameFormat:format(lightingManager.UserData.CurrentStats.BonusLevelName)) then
		return coreModule.Shared.GetObject("//Assets.Lighting."..config.BonusLevelNameFormat:format(lightingManager.UserData.CurrentStats.BonusLevelName))
	elseif coreModule.Shared.GetObject("//Assets.Lighting"):FindFirstChild(config.StageNameFormat:format(lightingManager.UserData.CurrentStats.CurrentUsingCheckpoint)) then
		return coreModule.Shared.GetObject("//Assets.Lighting."..config.StageNameFormat:format(lightingManager.UserData.CurrentStats.CurrentUsingCheckpoint))
	elseif coreModule.Shared.GetObject("//Assets.Lighting"):FindFirstChild(config.ZoneNameFormat:format(math.ceil(lightingManager.UserData.CurrentStats.CurrentUsingCheckpoint/10))) then
		return coreModule.Shared.GetObject("//Assets.Lighting."..config.ZoneNameFormat:format(math.ceil(lightingManager.UserData.CurrentStats.CurrentUsingCheckpoint/10)))
	else
		return coreModule.Shared.GetObject("//Assets.Lighting.Default")
	end
end

--
return lightingManager
]]