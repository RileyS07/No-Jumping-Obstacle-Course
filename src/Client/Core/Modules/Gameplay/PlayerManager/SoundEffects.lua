-- Variables
local soundEffectsManager = {}
soundEffectsManager.SoundGroup = nil
soundEffectsManager.SoundEffectsFolder = nil
soundEffectsManager.CachedSoundObjects = {}
soundEffectsManager.VolumeModifier = 1

local coreModule = require(script:FindFirstAncestor("Core"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))

-- Initialize
function soundEffectsManager.Initialize()
	soundEffectsManager.SoundEffectsFolder = coreModule.Shared.GetObject("//Assets.Sounds.SoundEffects")
	soundEffectsManager.SoundGroup = Instance.new("SoundGroup")
	soundEffectsManager.SoundGroup.Name = "SoundEffectsSoundGroup"
	soundEffectsManager.SoundGroup.Parent = clientEssentialsLibrary.GetPlayer()

	-- Server influenced sound effect.
	coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect").OnClientEvent:Connect(function(soundEffectName, functionParameters)
		soundEffectsManager.PlaySoundEffect(soundEffectName, functionParameters)
	end)
end


-- Methods
function soundEffectsManager.PlaySoundEffect(soundEffectName, functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		AllowOverlapping = true,
		Parent = soundEffectsManager.SoundGroup,
	}})

	-- Guard clause to make sure it even exists.
	if not soundEffectsManager.SoundEffectsFolder then return end
	if not soundEffectName or not soundEffectsManager.SoundEffectsFolder:FindFirstChild(soundEffectName) then return end

	-- Creating the sound object
	local soundObject = soundEffectsManager.SoundEffectsFolder[soundEffectName]:Clone()
	soundObject.Name = soundEffectName
	soundObject.SoundGroup = soundEffectsManager.SoundGroup
	soundObject.Volume *= soundEffectsManager.VolumeModifier
	soundObject.Parent = functionParameters.Parent
	soundObject:Play()
	game:GetService("Debris"):AddItem(soundObject, soundObject.TimeLength)
end

-- Settings compatibility
function soundEffectsManager.UpdateSetting(newValue)
	soundEffectsManager.VolumeModifier = newValue
	
	if soundEffectsManager.SoundGroup then
		for _, soundEffect in next, soundEffectsManager.SoundGroup:GetChildren() do
			if soundEffect:IsA("Sound") then
				soundEffect.Volume = (soundEffectsManager.CachedSoundObjects[soundEffect.Name] and soundEffectsManager.CachedSoundObjects[soundEffect.Name].Volume or 1)*newValue
			end
		end
	end
end


--
return soundEffectsManager