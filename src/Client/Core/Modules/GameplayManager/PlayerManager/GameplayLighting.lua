-- Variables
local gameplayLightingManager = {}
gameplayLightingManager.Assets = {}

local coreModule = require(script:FindFirstAncestor("Core"))
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
    print("WHAT")
    -- These guard clauses make sure that both this AND UpdateLightingPostTranslation work properly.
    if not userData then return end
    if not gameplayLightingManager.Assets.LightingContainer then return end
	if #gameplayLightingManager.Assets.LightingContainer:GetChildren() == 0 then return end
    if not gameplayLightingManager.Assets.LightingContainer:FindFirstChild("Default") then return end
    if not gameplayLightingManager.Assets.LightingContainer.Default:FindFirstChild("Properties") then return end
    if not gameplayLightingManager.Assets.LightingContainer.Default.Properties:IsA("ModuleScript") then return end
    print(userData)
    -- First we're gonna see if they're in a BonusStage.
    if userData.UserInformation.CurrentBonusStage ~= "" then

		local lightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild(userData.UserInformation.CurrentBonusStage)
        if lightingContainer then
            return gameplayLightingManager.UpdateLightingPostTranslation(lightingContainer)
        else
            coreModule.Debug(
                ("GameplayLighting: %s does not exist."):format(userData.UserInformation.CurrentBonusStage),
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
            print("???")
            return gameplayLightingManager.UpdateLightingPostTranslation(lightingContainer)
        else
            coreModule.Debug(
                ("GameplayLighting: %s does not exist."):format("Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial"),
                warn
            )
        end
    end
    
	-- Is there any for this specific stage?
	local stageSpecificLightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild("Stage "..tostring(userData.UserInformation.CurrentCheckpoint))
	if stageSpecificLightingContainer then
		return gameplayLightingManager.UpdateLightingPostTranslation(stageSpecificLightingContainer)
	end

	-- Is there any for this zone?
	local zoneSpecificLightingContainer = gameplayLightingManager.Assets.LightingContainer:FindFirstChild("Zone "..tostring(math.ceil(userData.UserInformation.CurrentCheckpoint/10)))
	if zoneSpecificLightingContainer then
		return gameplayLightingManager.UpdateLightingPostTranslation(zoneSpecificLightingContainer)
	else
		coreModule.Debug(
			("GameplayLighting: %s does not exist."):format("Zone "..tostring(math.ceil(userData.UserInformation.CurrentCheckpoint/10))),
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
        utilitiesLibrary.Destroy(game:GetService("Lighting"):FindFirstChildOfClass("Sky"))
        lightingInformation:FindFirstChildOfClass("Sky"):Clone().Parent = game:GetService("Lighting")

    elseif defaultLightingInformation:FindFirstChildOfClass("Sky") then
        utilitiesLibrary.Destroy(game:GetService("Lighting"):FindFirstChildOfClass("Sky"))
        defaultLightingInformation:FindFirstChildOfClass("Sky"):Clone().Parent = game:GetService("Lighting")
    end

    -- Replace the Atmosphere.
	if lightingInformation:FindFirstChildOfClass("Atmosphere") then
		utilitiesLibrary.Destroy(game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere"))
		lightingInformation:FindFirstChildOfClass("Atmosphere"):Clone().Parent = game:GetService("Lighting")

	elseif defaultLightingInformation:FindFirstChildOfClass("Atmosphere") then
		utilitiesLibrary.Destroy(game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere"))
		defaultLightingInformation:FindFirstChildOfClass("Atmosphere"):Clone().Parent = game:GetService("Lighting")
	end

	-- Update the ColorCorrection.
	if lightingInformation:FindFirstChildOfClass("ColorCorrectionEffect") then
        utilitiesLibrary.Destroy(game:GetService("Lighting"):FindFirstChildOfClass("ColorCorrectionEffect"))
        lightingInformation:FindFirstChildOfClass("ColorCorrectionEffect").Parent = game:GetService("Lighting")
	else
        utilitiesLibrary.Destroy(game:GetService("Lighting"):FindFirstChildOfClass("ColorCorrectionEffect"))
	end

    -- Updating the properties; We synchronize so we can fill in any gaps created.
    local propertiesDictionary = tableUtilitiesLibrary.SynchronizeTables(
        lightingInformation:FindFirstChild("Properties") and require(lightingInformation.Properties) or {}, 
        require(gameplayLightingManager.Assets.LightingContainer.Default.Properties)
    )

    for propertyName, propertyValue in next, propertiesDictionary do
        pcall(function()
            game:GetService("Lighting")[propertyName] = propertyValue
        end)
    end
end

--
return gameplayLightingManager