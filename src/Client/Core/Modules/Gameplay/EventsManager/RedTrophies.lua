local tweenService: TweenService = game:GetService("TweenService")

local coreModule = require(script:FindFirstAncestor("Core"))
local eventsInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager.Events"))
local soundEffectsManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.SoundEffects"))
local instanceUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.InstanceUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local thisEventStorage: Instance? = workspace.Map.Gameplay.EventStorage:FindFirstChild(script.Name)
local collectableInstances: {Instance} = instanceUtilities.GetChildrenWhichAre(thisEventStorage, "BasePart")
local trophyFadeTweenInfo: TweenInfo = TweenInfo.new(sharedConstants.EVENTS.TROPHIES.FADE_SPEED, Enum.EasingStyle.Linear)

local ThisEventVisualsManager = {}

-- Initialize
function ThisEventVisualsManager.Initialize()

	-- We want to update all of the trophies in the game to match their data.
	task.defer(function()

		local userData: {} = coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()

		-- We want all trophies to spin.
		for _, eventObject: BasePart in next, collectableInstances do
			ThisEventVisualsManager.SetupVisualEffects(eventObject)

			-- Do we need to hide this?
			if table.find(userData.UserEventInformation[script.Name].TrophiesCollected, eventObject.Name) then
				task.spawn(ThisEventVisualsManager.HideEventObject, eventObject)
			end
		end
	end)

	-- A player just collected a eventObject, so we need to hide it and update the interface.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Events.EventItemCollected").OnClientEvent:Connect(function(eventObject: BasePart)
		if not eventObject:IsDescendantOf(thisEventStorage) then return end

		soundEffectsManager.PlaySoundEffect("EventItemCollected", eventObject)
		eventsInterfaceManager.UpdateContent()
		ThisEventVisualsManager.HideEventObject(eventObject)
	end)
end

-- This animation includes the bobbing and spinning of the eventObject objects.
function ThisEventVisualsManager.SetupVisualEffects(eventObject: BasePart)

	-- Bobbing is the up and down movement.
	eventObject.Position = eventObject.Position + Vector3.new(0, -sharedConstants.EVENTS.TROPHIES.BOBBING_DISTANCE, 0)

	tweenService:Create(
		eventObject,
		TweenInfo.new(sharedConstants.EVENTS.TROPHIES.BOBBING_SPEED, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, true),
		{Position = eventObject.Position + Vector3.new(0, 2 * sharedConstants.EVENTS.TROPHIES.BOBBING_DISTANCE, 0)}
	):Play()

	-- Starting the spinning animation.
	task.defer(function()
		while eventObject and eventObject:IsDescendantOf(workspace) do
			eventObject.Orientation += Vector3.new(
				0,
				360 / sharedConstants.EVENTS.TROPHIES.ROTATION_SPEED * task.wait(),
				0
			)
		end
	end)
end


-- This animation makes the eventObject fade away from existance.
function ThisEventVisualsManager.HideEventObject(eventObject: BasePart)

	-- The core tween object that makes the eventObject invisible; We yield this one later on.
	local transparencyTweenObject = tweenService:Create(eventObject, trophyFadeTweenInfo, {Transparency = 1})

	-- Turning off any lights or partcile emitters.
	for _, child: Instance in next, eventObject:GetChildren() do
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
	eventObject:Destroy()
end

return ThisEventVisualsManager
