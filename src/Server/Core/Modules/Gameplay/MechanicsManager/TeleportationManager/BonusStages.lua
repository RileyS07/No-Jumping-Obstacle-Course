local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local teleportersManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager.Teleporters"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local badgeService = require(coreModule.Shared.GetObject("Libraries.Services.BadgeService"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local badgeList = require(coreModule.Shared.GetObject("Libraries.BadgeList"))

local userInformationUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.UserInformationUpdated")
local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.PlaySoundEffect")
local makeSystemMessageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.MakeSystemMessage")
local bonusStageStorage: Instance? = workspace.Map.Gameplay.LevelStorage:FindFirstChild("BonusStages")

local BonusStagesManager = {}

-- Initialize
function BonusStagesManager.Initialize()
    if not bonusStageStorage then return end

    -- We need to setup all of these bonus stages.
	for _, bonusStage: Instance in next, (bonusStageStorage :: Instance):GetChildren() do

        -- Every bonus stage needs Checkpoints in order to function.
        if bonusStage:FindFirstChild("Checkpoints") then

            -- This bonus stage has checkpoints. Lets go through all of them.
            for _, checkpoint: Instance in next, bonusStage.Checkpoints:GetChildren() do

                -- Each checkpoint needs to be a BasePart and have an integer name.
                if checkpoint:IsA("BasePart") and tonumber(checkpoint.Name) then

                    -- When the checkpoint is touched we want to update their data if possible.
                    checkpoint.Touched:Connect(function(hit: BasePart)

						local player: Player? = players:GetPlayerFromCharacter(hit.Parent)

                        -- Something doesn't add up if these don't pass.
                        if not playerUtilities.IsPlayerAlive(player) then return end
						if not userDataManager.GetData(player) then return end
						if userDataManager.GetData(player).UserInformation.CurrentBonusStage ~= bonusStage.Name then return end
						if userDataManager.GetData(player).UserInformation.CurrentBonusStageCheckpoint >= tonumber(checkpoint.Name) then return end

						local userData: {} = userDataManager.GetData(player)

						-- Is this the final checkpoint?
						if tonumber(checkpoint.Name) == #bonusStage.Checkpoints:GetChildren() then

                            -- We need to teleport them back.
							if teleportersManager.GetIsWaitingOnPlayerConsent(player) then return end

							-- Update their data before we teleport them back.
							userData.UserInformation.CurrentBonusStage = ""
							userData.UserInformation.CurrentBonusStageCheckpoint = 1

                            -- Only add to the table if it doesn't already exist.
                            if not table.find(userData.UserInformation.CompletedBonusStages, bonusStage.Name) then
							    table.insert(userData.UserInformation.CompletedBonusStages, bonusStage.Name)
                            end

							-- We only want to make an announcement if a badge for this bonus stage exists.
							if badgeList.BonusStages[bonusStage.Name] then
								badgeService.AwardBadge(player, badgeList.BonusStages[bonusStage.Name])
								makeSystemMessageRemote:FireAllClients(player.Name .. " has completed " .. bonusStage.Name .. "!")
							end

							-- Send them back.
							playSoundEffectRemote:FireClient(player, "Clapping")
							userInformationUpdatedRemote:FireClient(player, userData)
							teleportationManager.TeleportPlayer(player)
						else

                            -- This is not the final checkpoint.
							userData.UserInformation.CurrentBonusStageCheckpoint = tonumber(checkpoint.Name)
							playSoundEffectRemote:FireClient(player, "CheckpointTouched")
                            userInformationUpdatedRemote:FireClient(player, userData)
						end
					end)
                end
            end
        end
    end
end

return BonusStagesManager
