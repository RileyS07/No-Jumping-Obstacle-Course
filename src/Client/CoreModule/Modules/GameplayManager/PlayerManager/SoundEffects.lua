-- Variables
local soundEffectsManager = {}
soundEffectsManager.SoundGroup = nil
soundEffectsManager.SoundEffectsFolder = nil
soundEffectsManager.CachedSoundObjects = {}
soundEffectsManager.VolumeModifier = 1

local coreModule = require(script:FindFirstAncestor("CoreModule"))
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

	-- Does a cache exist? If not we create one; I do this to save some on performance but it can be detrimental for memory so maybe a more complex solution in the future.
	if not soundEffectsManager.CachedSoundObjects[soundEffectName] then
		soundEffectsManager.CachedSoundObjects[soundEffectName] = coreModule.Shared.GetObject("//Assets.Sounds.SoundEffects."..soundEffectName)
	end

	-- Creating the sound object
	local soundObject = soundEffectsManager.CachedSoundObjects[soundEffectName]:Clone()
	soundObject.Name = soundEffectName 
	soundObject.SoundGroup = soundEffectsManager.SoundGroup
	soundObject.Volume *= soundEffectsManager.VolumeModifier
	soundObject.Parent = functionParameters.Parent
	soundObject:Play()

	-- Cleanup
	coroutine.wrap(function()
		if soundObject.IsPlaying then soundObject.Ended:Wait() end
		soundObject:Destroy()
	end)()
end

-- Settings compatibility
function soundEffectsManager.UpdateSetting(newValue)
	soundEffectsManager.VolumeModifier = newValue
end


--
return soundEffectsManager