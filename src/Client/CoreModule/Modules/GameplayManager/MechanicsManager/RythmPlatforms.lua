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