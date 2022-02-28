-- Variables
local mechanicTutorialsManager = {}
mechanicTutorialsManager.SameServerTutorialCache = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local cutsceneManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function mechanicTutorialsManager.Initialize()

	-- The server wants a cutscene the begin
	coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated").OnClientEvent:Connect(function(userData)

		-- Looking for the correct module if it exists and if it's in a format we can work with; If it is we play it.
		for _, tutorialModule in next, script:GetChildren() do
			if tutorialModule:IsA("ModuleScript") and require(tutorialModule).Stage and require(tutorialModule).PlayTutorial then

				-- MechanicTutorials only run based on stage numbers; We introduce certain mechanics on certain stages for the first time.
				if userData.UserInformation.FarthestCheckpoint == require(tutorialModule).Stage and not mechanicTutorialsManager.SameServerTutorialCache[tutorialModule] then
					mechanicTutorialsManager.SameServerTutorialCache[tutorialModule] = true
					mechanicTutorialsManager.PlayTutorial(tutorialModule)
				end
			end
		end
	end)
end


-- Methods
-- This is in it's own method just in case somewhere down the line we want a client triggered tutorial instead of server triggered.
function mechanicTutorialsManager.PlayTutorial(tutorialModule)
	cutsceneManager.YieldTillCameraIsReadyForManipulation()

	cutsceneManager.UpdatePlayerBeingShownCutscene(true)
	require(tutorialModule).PlayTutorial()
	cutsceneManager.UpdatePlayerBeingShownCutscene(false)
end


--
return mechanicTutorialsManager