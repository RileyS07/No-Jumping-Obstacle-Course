--[[
    Confetti Cannon by Richard, Onogork 2018.
]]
local runService: RunService = game:GetService("RunService")

local particleClass = require(script:WaitForChild("Particle"))

local Confetti = {}
Confetti.DEFAULT_GRAVITY = Vector2.new(0, 1)
Confetti.__index = Confetti

-- Creates a new Confetti instance.
function Confetti.new()

	-- Creating the new instance.
	local newInstance: {} = setmetatable({}, Confetti)

	-- Gravity is the only thing that is really changable.
	newInstance.Gravity = Confetti.DEFAULT_GRAVITY
	newInstance.IsEnabled = false
	newInstance.Finished = Instance.new("BindableEvent")
	newInstance._Particles = {}
	newInstance._RenderStepped = nil

	-- Starting the update loop.
	newInstance._RenderStepped = runService.RenderStepped:Connect(function()
		for _, particle: particleClass.Particle in next, newInstance._Particles do
			particle:Update(newInstance.Gravity)

			-- Should we destroy this?
			if particle:IsFinished() then
				particle:Destroy()
				table.remove(newInstance._Particles, table.find(newInstance._Particles, particle))
			end
		end

		-- Should we destroy this confetti?
		if #newInstance._Particles == 0 and newInstance.IsEnabled then
			newInstance:Disable()
			newInstance.Finished:Fire()
		end
	end)

	return newInstance
end

-- Adds a new particle to the confetti bunch.
function Confetti:AddParticle(parent: Instance, options: {}?, emitterPosition: UDim2?, emitterPower: Vector2?) : particleClass.Particle

	-- Creating the new particle instance.
	local newParticleInstance: particleClass.Particle = particleClass.new(parent)
	newParticleInstance:SetEmitterPosition(emitterPosition)
	newParticleInstance:SetEmitterPower(emitterPower)
	newParticleInstance:SetOptions(options)

	table.insert(self._Particles, newParticleInstance)

	return newParticleInstance
end

-- Adds x amount of new _Particles to the confetti bunch.
function Confetti:AddParticles(parent: Instance, particleCount: number, options: {}?, emitterPosition: UDim2?, emitterPower: Vector2?) : {particleClass.Particle}

	local addedParticles: {particleClass.Particle} = {}

	for _ = 1, particleCount do
		table.insert(
			addedParticles,
			self:AddParticle(
				parent, options, emitterPosition, emitterPower
			)
		)
	end

	return addedParticles
end

-- Enables the confettis.
function Confetti:Enable()
	self.IsEnabled = true

	for _, particle: particleClass.Particle in next, self._Particles do
		particle:Enable()
	end
end

-- Disables the confettis.
function Confetti:Disable()
	self.IsEnabled = false

	for _, particle: particleClass.Particle in next, self._Particles do
		particle:Disable()
	end
end

-- Updates the gravity that effects the confettis.
function Confetti:SetGravity(gravity: Vector2)
	self.Gravity = gravity
end

-- Destroys the confetti instance.
function Confetti:Destroy()
	self._RenderStepped:Disconnect()
	self.Finished:Destroy()

	-- Destroy the _Particles.
	for _, particle: particleClass.Particle in next, self._Particles do
		particle:Destroy()
	end

	self._Particles = nil
	setmetatable(self, nil)
end

export type Confetti = typeof(Confetti.new())
export type Particle = particleClass.Particle
return Confetti