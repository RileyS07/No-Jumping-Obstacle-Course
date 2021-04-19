-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
	gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("RythmPlatforms")

	-- Setting up the RythmPlatforms to be functional.
	for _, rythmPlatformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
		for _, rythmPlatform in next, rythmPlatformContainer:GetChildren() do

			-- We put each RythmPlatform into it's own coroutine so they all run separate from eachother.
			coroutine.wrap(function()
				local platformConfig = setmetatable(rythmPlatform:FindFirstChild("Config") and require(rythmPlatform.Config) or {}, {__index = {
					-- Duration is how long the beat stays active.
					[1] = {Duration = 3},
					[2] = {Duration = 3}
				}})

				while true do
					for index = 1, math.max(#platformConfig, 2) do

						-- Update the BaseParts for CanCollide and Transparency.
						for _, basePart in next, rythmPlatform:GetDescendants() do

							-- The parts need to be named after numbers.
							if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
								basePart.CanCollide = tonumber(basePart.Parent.Name) == index
								basePart.Transparency = 
									-- Visible
									basePart.CanCollide and (rythmPlatform:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) 
									-- Invisible
									or (rythmPlatform:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)
							end
						end

						-- Wait before starting the animation; duration - numBlinks*blinkLength.
						wait((platformConfig[index].Duration or script:GetAttribute("DefaultBeatDuration") or 3) - (script:GetAttribute("NumberOfBlinks") or 3)*(script:GetAttribute("BlinkLength") or 0.45))

						-- Blinking animation.
						for blinkIndex = 1, script:GetAttribute("NumberOfBlinks") or 3 do
							for _, basePart in next, rythmPlatform:GetDescendants() do
								if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
									if tonumber(basePart.Parent.Name) == index then

										-- The magic behind the blinking.
										coreModule.Services.TweenService:Create(
											basePart, 
											TweenInfo.new((script:GetAttribute("BlinkLength") or 0.45)/2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true), 
											{Transparency = script:GetAttribute("GoalTransparency") or 0.5, Color = script:GetAttribute("GoalColor") or Color3.new(1, 1, 1)}
										):Play()
									end
								end
							
							--[[-- Poof! Smoke animation when they change + sound effect.
							local smokeParticleEmitter = coreModule.Shared.GetObject("//Assets.Objects.ParticleEmitters.Smoke"):Clone()
							smokeParticleEmitter.Parent = basePart

							smokeParticleEmitter:Emit(script:GetAttribute("SmokeParticleEmittance") or 5)
							coreModule.Services.Debris:AddItem(smokeParticleEmitter, smokeParticleEmitter.Lifetime.Max)
							soundEffectsManager.PlaySoundEffect("Poof", {Parent = basePart})								
							]]
							end
							wait(script:GetAttribute("BlinkLength") or 0.45)
						end

						--[[ Final poof! Smoke animation when they change + sound effect.
						for _, basePart in next, rythmPlatform:GetDescendants() do
							if basePart:IsA("BasePart") and tonumber(basePart.Parent.Name) then
								local smokeParticleEmitter = coreModule.Shared.GetObject("//Assets.Objects.ParticleEmitters.Smoke"):Clone()
								smokeParticleEmitter.Parent = basePart

								smokeParticleEmitter:Emit(script:GetAttribute("SmokeParticleEmittance") or 5)
								coreModule.Services.Debris:AddItem(smokeParticleEmitter, smokeParticleEmitter.Lifetime.Max)
								soundEffectsManager.PlaySoundEffect("Poof", {Parent = basePart})	
							end
						end]]
					end
				end
			end)()
		end
	end
end


-- Methods
function gameplayMechanicManager.SimulateBeatMap(rythmPlatform, beatMap)

end


function gameplayMechanicManager.GenerateValidBeatmap(possibleBeatMap, numberOfSequencesNeeded)

end


--
return gameplayMechanicManager
--[[

-- Variables
local rhythmBlocksMechanic = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientMechanicsManager = require(coreModule.GetObject("/Parent"))
local soundEffectsManager = require(coreModule.GetObject("Game.PlayerManager.SoundEffectsManager"))
local config = require(script.Config)

-- Initialize
function rhythmBlocksMechanic.Initialize()
	if not clientMechanicsManager.GetPlatformerMechanicsContainer():FindFirstChild("Rhythm Blocks") then return end
	
	--
	for _, rythmBlockContainer in next, clientMechanicsManager.GetPlatformerMechanicsContainer()["Rhythm Blocks"]:GetChildren() do
		if rythmBlockContainer:FindFirstChild("Config") and #require(rythmBlockContainer.Config).BeatMap > 0 then
			coroutine.wrap(function()
				local rythmBlockConfig = require(rythmBlockContainer.Config)
				
				--
				while true do
					for beatMapIndex = 1, #rythmBlockConfig.BeatMap do
						for _, object in next, rythmBlockContainer:GetDescendants() do
							if object:IsA("BasePart") and tonumber(object.Parent.Name) then
								object.CanCollide = tonumber(object.Parent.Name) == beatMapIndex
								object.Transparency = object.CanCollide and config.DefaultVisibleTransparency or config.DefaultInvisibleTransparency
							end
						end
						
						-- Wait before animation
						wait((rythmBlockConfig.BeatMap[beatMapIndex].Duration or config.DefaultBeatDuration) - config.AnimationInformation.TotalNumberOfBlinks*config.AnimationInformation.HalfBlinkLength*2)
						
						-- Animation
						for blinkIndex = 1, config.AnimationInformation.TotalNumberOfBlinks do
							for _, object in next, rythmBlockContainer:GetDescendants() do
								if object:IsA("BasePart") and tonumber(object.Parent.Name) then
									if tonumber(object.Parent.Name) == beatMapIndex then
										coreModule.Services.TweenService:Create(object, TweenInfo.new(config.AnimationInformation.HalfBlinkLength, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, true), {Transparency = config.AnimationInformation.GoalTransparency, Color = config.AnimationInformation.GoalColor}):Play()
									end
								end
							end
							
							soundEffectsManager.PlaySoundEffect("Beep", {Parent = rythmBlockContainer[beatMapIndex]:GetChildren()[Random.new():NextInteger(1, #rythmBlockContainer[beatMapIndex]:GetChildren())]})
							wait(config.AnimationInformation.HalfBlinkLength*2)
						end
						
						-- Poof!
						soundEffectsManager.PlaySoundEffect("Poof", {Parent = rythmBlockContainer[beatMapIndex]:GetChildren()[Random.new():NextInteger(1, #rythmBlockContainer[beatMapIndex]:GetChildren())]})
					end
				end
			end)()
		end
	end
end

--
return rhythmBlocksMechanic
]]