-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))

-- Methods
function specificClientAnimation.Play(basePart, smokeParticleEmittance)
    if typeof(basePart) ~= "Instance" or not basePart:IsA("BasePart") then return end

    local smokeParticleEmitter = coreModule.Shared.GetObject("//Assets.Objects.ParticleEmitters.Smoke"):Clone()
	smokeParticleEmitter.Parent = basePart
	smokeParticleEmitter:Emit(smokeParticleEmittance or script:GetAttribute("DefaultSmokeEmittance") or 5)
	coreModule.Services.Debris:AddItem(smokeParticleEmitter, smokeParticleEmitter.Lifetime.Max)

	soundEffectsManager.PlaySoundEffect("Poof", {Parent = basePart})
end


--
return specificClientAnimation