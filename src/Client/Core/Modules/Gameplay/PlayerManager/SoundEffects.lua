local debris: Debris = game:GetService("Debris")
local players: Players = game:GetService("Players")
local soundService: SoundService = game:GetService("SoundService")

local coreModule = require(script:FindFirstAncestor("Core"))

local soundEffectsDirectory: Instance = coreModule.Shared.GetObject("//Assets.Sounds.SoundEffects")
local soundEffectsSoundGroup: SoundGroup = soundService:WaitForChild("SoundEffects")
local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.PlaySoundEffect")

local SoundEffectsManager = {}

-- Initialize
function SoundEffectsManager.Initialize()

	-- The server saying we should play a sound effect.
	playSoundEffectRemote.OnClientEvent:Connect(SoundEffectsManager.PlaySoundEffect)
end

-- Creates and plays a sound effect.
function SoundEffectsManager.PlaySoundEffect(soundEffectName: string, optionalParent: BasePart?)

	-- Does this sound effect even exist?
	if not soundEffectsDirectory:FindFirstChild(soundEffectName) then
		return
	end

	-- Creating the sound object
	local newSoundEffect: Sound = soundEffectsDirectory[soundEffectName]:Clone()
	newSoundEffect.SoundGroup = soundEffectsSoundGroup
	newSoundEffect.Parent = optionalParent or players.LocalPlayer
	newSoundEffect:Play()

	-- Getting rid of it.
	debris:AddItem(
		newSoundEffect,
		newSoundEffect.TimeLength
	)
end

-- Updates to comply with the new setting value.
function SoundEffectsManager.UpdateSetting(newValue: number)
	soundEffectsSoundGroup.Volume = newValue
end

return SoundEffectsManager
