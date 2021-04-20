-- Variables
local teleportationManager = {}
teleportationManager.PlayersBeingTeleported = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function teleportationManager.Initialize()
	coreModule.LoadModule("/Checkpoints")
	coreModule.LoadModule("/RespawnPlatforms")
end


-- Methods
-- TODO: Actually complete this.
function teleportationManager.TeleportPlayer(player)
	
end


function teleportationManager.IsPlayerBeingTeleported(player)
	return teleportationManager.PlayersBeingTeleported[player]
end


--
return teleportationManager

--[[

-- Variables
local generalTeleportationManager = {}
generalTeleportationManager.PlayersBeingTeleported = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local powerupsManager = require(coreModule.GetObject("Game.ServerMechanicsManager.Powerups"))
local persistentDataManager = require(coreModule.GetObject("Game.PlayerManager.UserDataManager.PersistentData"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local collisionsLibrary = require(coreModule.Shared.GetObject("Libraries.Collisions"))
local config = require(script.Config)

-- Initialize
function generalTeleportationManager.Initialize()
	if not workspace:FindFirstChild("Map") then return end
	coreModule.LoadModule("/SendBacks")
	coreModule.LoadModule("/Checkpoints")
	coreModule.LoadModule("/Teleporters")
end

-- Methods
function generalTeleportationManager.TeleportPlayer(player, functionParamaters)
	if not workspace:FindFirstChild("Map") then return end
	if not utilitiesLibrary.IsValidPlayer(player) then return end
	functionParamaters = setmetatable(functionParamaters or {}, {__index = {
		TeleportationMode = coreModule.Enums.TeleportationMode.Data,
		Location = nil,
		RestoreConditions = true
	}})
	
	-- Data?
	if functionParamaters.TeleportationMode == coreModule.Enums.TeleportationMode.Data then
		local userData = persistentDataManager.GetData(player)
		
		-- Therapy Room
		if userData.CurrentStats.IsInTherapy and workspace.Map:FindFirstChild("Teleporters") and workspace.Map.Teleporters:FindFirstChild("TherapyRoom") and workspace.Map.Teleporters.TherapyRoom:FindFirstChild("TeleportPart") then
			generalTeleportationManager.TeleportPlayer(player, {TeleportationMode = coreModule.Enums.TeleportationMode.BasePart, Location = workspace.Map.Teleporters.TherapyRoom.TeleportPart})
			return
		end
		
		-- Bonus Level
		if userData.CurrentStats.BonusLevelName ~= "" and workspace.Map:FindFirstChild("Levels") and workspace.Map.Levels:FindFirstChild(userData.CurrentStats.BonusLevelName) and workspace.Map.Levels:FindFirstChild(userData.CurrentStats.BonusLevelName):FindFirstChild("StartingPoint") then
			if workspace.Map.Levels[userData.CurrentStats.BonusLevelName]:FindFirstChild("Checkpoints") and workspace.Map.Levels[userData.CurrentStats.BonusLevelName].Checkpoints:FindFirstChild(userData.CurrentStats.CurrentUsingBonusLevelCheckpoint) then
				generalTeleportationManager.TeleportPlayer(player, {TeleportationMode = coreModule.Enums.TeleportationMode.BasePart, Location = workspace.Map.Levels:FindFirstChild(userData.CurrentStats.BonusLevelName).Checkpoints[userData.CurrentStats.CurrentUsingBonusLevelCheckpoint]})
			else
				generalTeleportationManager.TeleportPlayer(player, {TeleportationMode = coreModule.Enums.TeleportationMode.BasePart, Location = workspace.Map.Levels:FindFirstChild(userData.CurrentStats.BonusLevelName).StartingPoint})
			end
			return
		end
		
		-- Checkpoints
		if workspace.Map:FindFirstChild("Checkpoints") then
			if not workspace.Map.Checkpoints:FindFirstChild(userData.CurrentStats.CurrentUsingCheckpoint) then
				generalTeleportationManager.TeleportPlayer(player, {TeleportationMode = coreModule.Enums.TeleportationMode.BasePart, Location = workspace.Map.Checkpoints["1"]})
			else
				generalTeleportationManager.TeleportPlayer(player, {TeleportationMode = coreModule.Enums.TeleportationMode.BasePart, Location = workspace.Map.Checkpoints[userData.CurrentStats.CurrentUsingCheckpoint]})
			end
		end
	elseif functionParamaters.TeleportationMode == coreModule.Enums.TeleportationMode.Place then
		if coreModule.Services.RunService:IsStudio() then return end
		if not functionParamaters.Location then return end
		generalTeleportationManager.YieldBeforeTeleportation(player)
		generalTeleportationManager.PlayersBeingTeleported[player] = true
		
		-- Teleport
		coreModule.Services.TeleportService:Teleport(functionParamaters.Location, player)
		coroutine.wrap(function() wait(config.TeleportationTimeout) generalTeleportationManager.PlayersBeingTeleported[player] = nil end)()
	else
		if not functionParamaters.Location or not functionParamaters.Location:IsA("BasePart") then return end
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
		generalTeleportationManager.YieldBeforeTeleportation(player)
		generalTeleportationManager.PlayersBeingTeleported[player] = true
		
		-- Teleport
		player.Character:SetPrimaryPartCFrame(generalTeleportationManager.GetPerfectPositionAbovePlatform(player, functionParamaters.Location))
		coreModule.Services.RunService.Heartbeat:Wait()
		generalTeleportationManager.PlayersBeingTeleported[player] = nil
		
		--
		if functionParamaters.RestoreConditions then
			generalTeleportationManager.ResetPlayerConditions(player)
		end
	end
end

function generalTeleportationManager.ResetPlayerConditions(player)
	if not utilitiesLibrary.IsPlayerAlive(player) then return end
	
	--
	local userData = persistentDataManager.GetData(player)
	userData.CurrentStats.IsInVictory = false
	
	-- 
	powerupsManager.ClearPowerups(player)
	player.Character.Humanoid.Health = player.Character.Humanoid.MaxHealth
	player.Character.HumanoidRootPart.Velocity = Vector3.new()
	collisionsLibrary.SetDescendantsCollisionGroup(player.Character, "Players")
	coreModule.Shared.GetObject("//Remotes.RestoreDefaultPlayerConditions"):FireClient(player, userData)
	for _, collectionServiceTagName in next, coreModule.Services.CollectionService:GetTags(player.Character) do
		coreModule.Services.CollectionService:RemoveTag(player.Character, collectionServiceTagName)
	end
	
	-- Jumping?
	if not userData.CurrentStats.IsInTherapy then
		player.Character.Humanoid.UseJumpPower = false
		player.Character.Humanoid.JumpPower = 0
	end
end

function generalTeleportationManager.YieldBeforeTeleportation(player)
	if generalTeleportationManager.PlayersBeingTeleported[player] then
		repeat wait(1) until not generalTeleportationManager.PlayersBeingTeleported[player]
	end
end

function generalTeleportationManager.GetPerfectPositionAbovePlatform(player, location)
	if not utilitiesLibrary.IsPlayerAlive(player) or not player.Character:FindFirstChild("Left Leg") then
		return location.CFrame + Vector3.new(0, 5, 0)
	end

	--
	return CFrame.new(
		location.Position + Vector3.new(0, location.Size.Y/2 + player.Character["Left Leg"].Size.Y + player.Character.HumanoidRootPart.Size.Y + player.Character.Humanoid.HipHeight, 0)
	)*(location.CFrame - location.Position)
end

function generalTeleportationManager.IsPlayerBeingTeleported(player)
	return generalTeleportationManager.PlayersBeingTeleported[player] ~= nil
end

--
return generalTeleportationManager
]]