-- Variables
local specificEventManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Initialize
function specificEventManager.Initialize()
	workspace.Map.Gameplay.EventStorage:WaitForChild("Trophies")
	
	-- Setting up the trophies in Workspace
	coroutine.wrap(function()
		local userData = coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer()
		
		-- Setup the visual effects
		for _, trophyObject in next, workspace.Map.Gameplay.EventStorage.Trophies:GetChildren() do
			if trophyObject:IsA("BasePart") then

				specificEventManager.SetupTrophyVisualEffects(trophyObject)
				
				-- Hide ones already collected
				if userData.UserEventInformation.Trophy_Event and table.find(userData.UserEventInformation.Trophy_Event.TrophiesCollected, trophyObject.Name) then
					coroutine.wrap(specificEventManager.HideTrophyObject)(trophyObject)
				end
			end
		end
	end)()
	
	-- TrophyCollected dissappearing animation.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Events.TrophyCollected").OnClientEvent:Connect(function(trophyObject)
		if not trophyObject then return end
		specificEventManager.HideTrophyObject(trophyObject)
	end)
end


-- Methods
-- This animation includes the bobbing and spinning of the trophy objects.
function specificEventManager.SetupTrophyVisualEffects(trophyObject)

	-- Bobbing animation
	trophyObject.Position = trophyObject.Position + Vector3.new(0, -(script:GetAttribute("BobbingDistance") or 1), 0)
	game:GetService("TweenService"):Create(
		trophyObject, 
		TweenInfo.new(script:GetAttribute("BobbingSpeed") or 1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, true),
		{Position = trophyObject.Position + Vector3.new(0, 2*(script:GetAttribute("BobbingDistance") or 1), 0)}
	):Play()

	-- Spinning animation
	coroutine.wrap(function()
		while trophyObject do
			local deltaTime = game:GetService("RunService").RenderStepped:Wait()
			trophyObject.Orientation = trophyObject.Orientation + Vector3.new(0, 360/(script:GetAttribute("SpinningSpeed") or 3)*deltaTime, 0)
		end
	end)()
end


-- This animation makes the trophy fade away from existance.
function specificEventManager.HideTrophyObject(trophyObject)
	local commonFadeTweenInfo = TweenInfo.new(script:GetAttribute("FadeDuration") or 1, Enum.EasingStyle.Linear)

	-- The core tween object that makes the trophy invisible; We yield this one later on.
	local transparencyTweenObject = game:GetService("TweenService"):Create(trophyObject, commonFadeTweenInfo, {Transparency = 1})

	-- Tween out the PointLight, Shine, and Sparkles if they exist.
	if trophyObject:FindFirstChild("PointLight") then
		game:GetService("TweenService"):Create(trophyObject.PointLight, commonFadeTweenInfo, {Brightness = 0}):Play()
	end

	if trophyObject:FindFirstChild("Shine") then
		trophyObject.Shine.Enabled = false
		trophyObject.Shine:Clear()
	end

	if trophyObject:FindFirstChild("Sparkles") then
		trophyObject.Sparkles.Enabled = false
		trophyObject.Sparkles:Clear()
	end

	-- Yielding for the core tween object and then cleaning up.
	transparencyTweenObject:Play()
	transparencyTweenObject.Completed:Wait()
	trophyObject:Destroy()
end


--
return specificEventManager