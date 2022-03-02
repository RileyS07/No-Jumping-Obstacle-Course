--[[
    The purpose of this module is to correct oversights in data
    that lead to minor corruptions that can be repaired.
]]

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local badgeService = require(coreModule.Shared.GetObject("Libraries.Services.BadgeService"))

local CorruptionRepairManager = {}

-- Initialize
function CorruptionRepairManager.Initialize(player: Player)

    -- Here is where it all starts.
    local userData: {} = userDataManager.GetData(player)

    userData.UserInformation.CompletedBonusStages = CorruptionRepairManager._RepairCompletedBonusStages(userData.UserInformation.CompletedBonusStages)
    userData.UserInformation.CompletedStages = CorruptionRepairManager._RepairCompletedStages(userData.UserInformation.CompletedStages)

	CorruptionRepairManager._AttemptAwardNJZCompletionistBadge(player, userData.UserInformation.CurrentCheckpoint)
end

-- There was a bug where the ★ No Jumping Zone Completionist badge was not being awarded.
function CorruptionRepairManager._AttemptAwardNJZCompletionistBadge(player: Player, currentCheckpoint: number)

	if currentCheckpoint == 101 then
		badgeService.AwardBadge(player, 2125036729)
	end
end

-- There was a bug where duplicates of bonus stages were being inserted into here.
function CorruptionRepairManager._RepairCompletedBonusStages(completedBonusStagesArray: {}) : {string}

    local newCompletedBonusStagesArray: {string} = {}

	for _, bonusStageName: string in next, completedBonusStagesArray do
		if not table.find(newCompletedBonusStagesArray, bonusStageName) then
			table.insert(newCompletedBonusStagesArray, bonusStageName)
		end
	end

	return newCompletedBonusStagesArray
end

-- There was a bug where duplicates of stages were being inserted into here.
function CorruptionRepairManager._RepairCompletedStages(completedStagesArray: {}) : {number}

    local newCompletedStagesArray: {number} = {}

	for _, stageNumber: number in next, completedStagesArray do
		if tonumber(stageNumber) and not table.find(newCompletedStagesArray, tonumber(stageNumber)) then
			table.insert(newCompletedStagesArray, tonumber(stageNumber))
		end
	end

	-- Sorting it.
	table.sort(newCompletedStagesArray, function(stageNumberA: number, stageNumberB: number)
		return stageNumberA < stageNumberB
	end)

	return newCompletedStagesArray
end

return CorruptionRepairManager
