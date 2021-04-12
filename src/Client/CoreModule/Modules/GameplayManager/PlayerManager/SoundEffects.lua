-- Variables
local soundEffectsManager = {}
soundEffectsManager.SoundGroup = nil
soundEffectsManager.SoundEffectsFolder = nil
soundEffectsManager.CachedSoundObjects = {}
soundEffectsManager.LocalSoundVolumeModifier = 1

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))

-- Initialize
function soundEffectsManager.Initialize()
	soundEffectsManager.SoundEffectsFolder = coreModule.Shared.GetObject("//Assets.Sounds.SoundEffects")
	soundEffectsManager.SoundGroup = Instance.new("SoundGroup")
	soundEffectsManager.SoundGroup.Name = "SoundEffectsSoundGroup"
	soundEffectsManager.SoundGroup.Parent = clientEssentialsLibrary.GetPlayer()

	-- Server communication babey
	coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.PlaySoundEffect").OnClientEvent:Connect(function(soundEffectName, functionParameters)
		soundEffectsManager.PlaySoundEffect(soundEffectName, functionParameters)
	end)
end

-- Methods
function soundEffectsManager.PlaySoundEffect(soundEffectName, functionParameters)
	if not soundEffectName or not soundEffectsManager.SoundEffectsFolder:FindFirstChild(soundEffectName) then return end
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		AllowOverlapping = true,
		Parent = soundEffectsManager.SoundGroup,
	}})

	-- Create the sound
	if not soundEffectsManager.CachedSoundObjects[soundEffectName] then
		soundEffectsManager.CachedSoundObjects[soundEffectName] = coreModule.Shared.GetObject("//Assets.Sounds.SoundEffects."..soundEffectName)
	end

	local soundObject = soundEffectsManager.CachedSoundObjects[soundEffectName]:Clone()
	soundObject.Name = soundEffectName 
	soundObject.SoundGroup = soundEffectsManager.SoundGroup
	soundObject.Volume *= soundEffectsManager.LocalSoundVolumeModifier
	soundObject.Parent = functionParameters.Parent
	soundObject:Play()

	-- Cleanup
	coroutine.wrap(function()
		if soundObject.IsPlaying then soundObject.Ended:Wait() end
		soundObject:Destroy()
	end)()
end

function soundEffectsManager.Update(settingValue)
	soundEffectsManager.LocalSoundVolumeModifier = settingValue and 1 or 0
end

--
return soundEffectsManager