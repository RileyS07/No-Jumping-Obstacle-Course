-- Variables
local specificEventManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function specificEventManager.Initialize()
	workspace.Map.Gameplay.EventStorage:WaitForChild("Trophies")
	
	-- 
	coroutine.wrap(function()
		local userData = coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer()
		
		-- Setup
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
	
	-- TrophyCollected dissappearing Visual
	coreModule.Shared.GetObject("//Remotes.Gameplay.Events.TrophyCollected").OnClientEvent:Connect(function(trophyObject)
		if not trophyObject then return end
		specificEventManager.HideTrophyObject(trophyObject)
	end)
end

-- Methods
function specificEventManager.SetupTrophyVisualEffects(trophyObject)
	-- Setup the bobbing
	trophyObject.Position = trophyObject.Position + Vector3.new(0, -(script:GetAttribute("BobbingDistance") or 1), 0)
	coreModule.Services.TweenService:Create(
		trophyObject, 
		TweenInfo.new(script:GetAttribute("BobbingSpeed") or 1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, math.huge, true),
		{Position = trophyObject.Position + Vector3.new(0, 2*(script:GetAttribute("BobbingDistance") or 1), 0)}
	):Play()

	-- Setting up the spinning
	coroutine.wrap(function()
		while trophyObject do
			local deltaTime = coreModule.Services.RunService.RenderStepped:Wait()
			trophyObject.Orientation = trophyObject.Orientation + Vector3.new(0, 360/(script:GetAttribute("SpinningSpeed") or 3)*deltaTime, 0)
		end
	end)()
end

function specificEventManager.HideTrophyObject(trophyObject)
	-- Main one that we'll yield for
	local mainTrophyTween = coreModule.Services.TweenService:Create(
		trophyObject, 
		TweenInfo.new(script:GetAttribute("FadeDuration") or 1, Enum.EasingStyle.Linear), 
		{Transparency = 1}
	)

	-- Tween out the PointLight, Shine, and Sparkles if they exist
	if trophyObject:FindFirstChild("PointLight") then
		coreModule.Services.TweenService:Create(
			trophyObject.PointLight,
			TweenInfo.new(script:GetAttribute("FadeDuration") or 1), 
			{Brightness = 0}
		):Play()
	end

	if trophyObject:FindFirstChild("Shine") then
		trophyObject.Shine.Enabled = false
		trophyObject.Shine:Clear()
	end

	if trophyObject:FindFirstChild("Sparkles") then
		trophyObject.Sparkles.Enabled = false
		trophyObject.Sparkles:Clear()
	end

	-- Yield for the main one
	mainTrophyTween:Play()
	mainTrophyTween.Completed:Wait()
	trophyObject:Destroy()
end

--
return specificEventManager