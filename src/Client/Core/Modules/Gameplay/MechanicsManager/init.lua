-- Variables
local mechanicsManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local soundEffectsManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.SoundEffects"))
local playerMouseLibrary = require(coreModule.GetObject("Libraries.UserInput.Mouse"))

-- Initialize
function mechanicsManager.Initialize()
	mechanicsManager.GetPlatformerMechanics()
	playerMouseLibrary.Initialize()

	-- Loading modules
	coreModule.LoadModule("/Buttons")
	coreModule.LoadModule("/Doors")
	coreModule.LoadModule("/ForcedCameraView")
	coreModule.LoadModule("/ManualSwitchPlatforms")
	coreModule.LoadModule("/MovingPlatforms")
	coreModule.LoadModule("/Radar")
	coreModule.LoadModule("/RythmPlatforms")
	coreModule.LoadModule("/SpinningPlatforms")
	coreModule.LoadModule("/SwitchPlatforms")
end


-- Methods
function mechanicsManager.GetPlatformerMechanics()
	return workspace.Map.Gameplay:WaitForChild("PlatformerMechanics")
end


-- So many of the mechanics have this same effect so it's in our best interest to have it centralized.
function mechanicsManager.PlayAppearanceChangedEffect(basePart, smokeParticleEmittance)
	if not basePart or typeof(basePart) ~= "Instance" or not basePart:IsA("BasePart") then return end
	
	local smokeParticleEmitter = coreModule.Shared.GetObject("//Assets.Objects.ParticleEmitters.Smoke"):Clone()
	smokeParticleEmitter.Parent = basePart
	smokeParticleEmitter:Emit(smokeParticleEmittance or 5)
	game:GetService("Debris"):AddItem(smokeParticleEmitter, smokeParticleEmitter.Lifetime.Max)

	soundEffectsManager.PlaySoundEffect("Poof", basePart)
end


--
return mechanicsManager