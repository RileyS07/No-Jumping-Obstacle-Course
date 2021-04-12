-- Variables
local mechanicTutorialsManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local cutsceneManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function mechanicTutorialsManager.Initialize()
	coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated").OnClientEvent:Connect(function(userData)
		for _, tutorialModule in next, script:GetChildren() do
			if tutorialModule:IsA("ModuleScript") and require(tutorialModule).Stage and require(tutorialModule).PlayTutorial then
				if userData.UserInformation.FarthestCheckpoint == require(tutorialModule).Stage then
					if not cutsceneManager.IsCameraReadyForManipulation() then
						repeat wait() until cutsceneManager.IsCameraReadyForManipulation()
					end
					
					cutsceneManager.UpdatePlayerBeingShownCutscene(true)
					require(tutorialModule).PlayTutorial()
					cutsceneManager.UpdatePlayerBeingShownCutscene(false)
				end
			end
		end
	end)
end

--
return mechanicTutorialsManager