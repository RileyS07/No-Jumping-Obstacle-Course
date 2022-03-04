local tweenService: TweenService = game:GetService("TweenService")

local coreModule = require(script:FindFirstAncestor("Core"))
local eventsInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager.Events"))
local soundEffectsManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.SoundEffects"))
local instanceUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.InstanceUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local thisEventStorage: Instance = workspace:WaitForChild("Map"):WaitForChild("Gameplay"):WaitForChild("EventStorage"):WaitForChild("Trophies")
local collectableTrophies: {Instance} = instanceUtilities.GetChildrenWhichAre(thisEventStorage, "BasePart")
local trophyFadeTweenInfo: TweenInfo = TweenInfo.new(sharedConstants.EVENTS.TROPHIES.FADE_SPEED, Enum.EasingStyle.Linear)

local ThisEventVisualsManager = {}

-- Initialize
function ThisEventVisualsManager.Initialize()

	-- We want to update all of the trophies in the game to match their data.
	task.defer(function()

		local userData: {} = coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer()

		-- We want all trophies to spin.
		for _, trophy: BasePart in next, collectableTrophies do
			ThisEventVisualsManager.SetupTrophyVisualEffects(trophy)

			-- Do we need to hide this?
			if table.find(userData.UserEventInformation.Trophy_Event.TrophiesCollected, trophy.Name) then
				task.spawn(ThisEventVisualsManager.HideTrophyObject, trophy)
			end
		end
	end)

	-- A player just collected a trophy, so we need to hide it and update the interface.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Events.TrophyCollected").OnClientEvent:Connect(function(trophy: BasePart)
		soundEffectsManager.PlaySoundEffect("TrophyCollected", {Parent = trophy})
		eventsInterfaceManager.UpdateContent()
		ThisEventVisualsManager.HideTrophyObject(trophy)
	end)
end

-- This animation includes the bobbing and spinning of the trophy objects.
function ThisEventVisualsManager.SetupTrophyVisualEffects(trophy: BasePart)

	-- Bobbing is the up and down movement.
	trophy.Position = trophy.Position + Vector3.new(0, -sharedConstants.EVENTS.TROPHIES.BOBBING_DISTANCE, 0)

	tweenService:Create(
		trophy,
		TweenInfo.new(sharedConstants.EVENTS.TROPHIES.BOBBING_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, true),
		{Position = trophy.Position + Vector3.new(0, 2 * sharedConstants.EVENTS.TROPHIES.BOBBING_DISTANCE, 0)}
	):Play()

	-- Starting the spinning animation.
	task.defer(function()
		while trophy and trophy:IsDescendantOf(workspace) do
			trophy.Orientation += Vector3.new(
				0,
				360 / sharedConstants.EVENTS.TROPHIES.ROTATION_SPEED * task.wait(),
				0
			)
		end
	end)
end


-- This animation makes the trophy fade away from existance.
function ThisEventVisualsManager.HideTrophyObject(trophy: BasePart)

	-- The core tween object that makes the trophy invisible; We yield this one later on.
	local transparencyTweenObject = tweenService:Create(trophy, trophyFadeTweenInfo, {Transparency = 1})

	-- Turning off any lights or partcile emitters.
	for _, child: Instance in next, trophy:GetChildren() do
		if child:IsA("PointLight") then
			tweenService:Create(child, trophyFadeTweenInfo, {Brightness = 0}):Play()
		elseif child:IsA("ParticleEmitter") then
			child.Enabled = false
			child:Clear()
		end
	end

	-- Yielding for the core tween object and then cleaning up.
	transparencyTweenObject:Play()
	transparencyTweenObject.Completed:Wait()
	trophy:Destroy()
end

return ThisEventVisualsManager
