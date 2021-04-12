-- Variables
local specificEventManager = {}
specificEventManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserDataManager"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function specificEventManager.Initialize()
	if not workspace.Map.Gameplay.EventStorage:FindFirstChild(script.Name) then return end
	specificEventManager.Remotes.TrophyCollected = coreModule.Shared.GetObject("//Remotes.Gameplay.Events.TrophyCollected")
	
	--
	for _, tropyObject in next, workspace.Map.Gameplay.EventStorage.Trophies:GetChildren() do
		if tropyObject:IsA("BasePart") then
			tropyObject.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				
				-- Is the data there?
				if not userDataManager.GetData(player).UserEventInformation[script:GetAttribute("ChallengeName")] then
					userDataManager.GetData(player).UserEventInformation[script:GetAttribute("ChallengeName")] = {
						Name = (script:GetAttribute("ChallengeName") or ""),
						Description = (script:GetAttribute("ChallengeDescription") or ""),
						Completed = false,
						Progress = 0,
						
						-- Event Specific
						TrophiesCollected = {}
					}
				end
				
				-- Collection time?
				specificEventManager.ValidateEventData(player)
				if not table.find(userDataManager.GetData(player).UserEventInformation[script:GetAttribute("ChallengeName")].TrophiesCollected, tropyObject.Name) then
					table.insert(userDataManager.GetData(player).UserEventInformation[script:GetAttribute("ChallengeName")].TrophiesCollected, tropyObject.Name)
					specificEventManager.Remotes.TrophyCollected:FireClient(player, tropyObject)
				end
			end)
		end
	end
end

-- Methods
function specificEventManager.ValidateEventData(player)
	if not userDataManager.GetData(player).UserEventInformation[script:GetAttribute("ChallengeName")] then return end
	
	-- Do the trophies exist?
	for index = #userDataManager.GetData(player).UserEventInformation[script:GetAttribute("ChallengeName")].TrophiesCollected, 1, -1 do
		if not workspace.Map.Gameplay.EventStorage[script.Name]:FindFirstChild(userDataManager.GetData(player).UserEventInformation[script:GetAttribute("ChallengeName")].TrophiesCollected[index]) then
			table.remove(userDataManager.GetData(player).UserEventInformation[script:GetAttribute("ChallengeName")].TrophiesCollected, index)
		end
	end
end

--
return specificEventManager