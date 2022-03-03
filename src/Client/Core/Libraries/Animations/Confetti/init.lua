--[[
    Confetti Cannon by Richard, Onogork 2018.
]]
local runService: RunService = game:GetService("RunService")

local particleClass = require(script:WaitForChild("Particle"))

local Confetti = {}
Confetti.__index = Confetti
Confetti.Shapes = {script:WaitForChild("CircularConfetti"), script:WaitForChild("SquareConfetti")}
Confetti.Colors = {
    Color3.fromRGB(168,100,253),
    Color3.fromRGB(41,205,255),
    Color3.fromRGB(120,255,68),
    Color3.fromRGB(255,113,141),
    Color3.fromRGB(253,255,106)
}

-- Creates a new Confetti instance.
function Confetti.new()

	-- Creating the new instance.
	local newInstance: {} = {
		Gravity = Vector2.new(0, 1),
		IsEnabled = false,
		Finished = Instance.new("BindableEvent"),
		Particles = {},
		_RenderStepped = nil
	}

	-- Starting the update loop.
	newInstance._RenderStepped = runService.RenderStepped:Connect(function()
		for _, particle: particleClass.Particle in next, newInstance.Particles do
			particle:Update(newInstance.Gravity)

			-- Should we destroy this?
			if particle.CycleCount == particle.Options.MaxCycleCount then
				print("What")
				particle:Destroy()
			end
		end

		-- Should we destroy this confetti?
		if #newInstance.Particles == 0 and newInstance.IsEnabled then
			newInstance.Finished:Fire()
			newInstance.IsEnabled = false
		end
	end)

	return setmetatable(newInstance, Confetti)
end

-- Adds a new particle to the confetti bunch.
function Confetti:AddParticle(parent: Instance, maxCycles: number?, emitterPosition: UDim2?, emitterPower: Vector2?) : particleClass.Particle

	-- Creating the new particle instance.
	local newParticleInstance: particleClass.Particle = particleClass.new(
		parent, maxCycles, emitterPosition, emitterPower
	)

	table.insert(self.Particles, newParticleInstance)
	return newParticleInstance
end

-- Adds x amount of new particles to the confetti bunch.
function Confetti:AddParticles(parent: Instance, amount: number, maxCycles: number?, emitterPosition: UDim2?, emitterPower: Vector2?) : {particleClass.Particle}

	local addedParticles: {particleClass.Particle} = {}

	for _ = 1, amount do
		table.insert(
			addedParticles,
			self:AddParticle(parent, maxCycles, emitterPosition, emitterPower)
		)
	end

	return addedParticles
end

-- Enables the confettis.
function Confetti:Enable()
	self.IsEnabled = true

	for _, particle: particleClass.Particle in next, self.Particles do
		particle:Enable()
	end
end

-- Disables the confettis.
function Confetti:Disable()
	self.IsEnabled = false

	for _, particle: particleClass.Particle in next, self.Particles do
		particle:Disable()
	end
end

-- Updates the gravity that effects the confettis.
function Confetti:UpdateGravity(gravity: Vector2)
	self.Gravity = gravity
end

-- Destroys the confetti instance.
function Confetti:Destroy()
	self._RenderStepped:Disconnect()

	-- Destroy the particles.
	for _, particle: particleClass.Particle in next, self.Particles do
		particle:Destroy()
	end

	self.Particles = nil
	setmetatable(self, nil)
end

export type Confetti = typeof(Confetti.new())
export type Particle = particleClass.Particle
return Confetti

--[[
--//
-- Confetti Cannon by Richard, Onogork 2018.
--//
local svcRun = game:GetService("RunService");
local ConfettiCannon = require(script.ConfettiParticles);
ConfettiCannon.setGravity(Vector2.new(0,1));
local confetti = {};
-- Create confetti paper.
local AmountOfConfetti = 25;
for i=1, AmountOfConfetti do
	local p = ConfettiCannon.createParticle(
		Vector2.new(0.5,1), 									-- Position on screen. (Scales)
		Vector2.new(math.random(90)-45, math.random(70,100)), 		-- The direction power of the blast.
		script.Parent, 												-- The frame that these should be displayed on.
		{Color3.fromRGB(255,255,100), Color3.fromRGB(255,100,100)} 	-- The colors that should be used.
	);
	table.insert(confetti, p);
end;

local confettiColors = {Color3.fromRGB(255,255,100), Color3.fromRGB(255,100,100)};
local confettiActive = false;
-- Update position of all confetti.
svcRun.RenderStepped:Connect(function()
	for _,val in pairs(confetti) do
		if (confettiColors) then val:SetColors(confettiColors); end;
		val.Enabled = confettiActive;
		val:Update();
	end;
end);

local fire = function(paramColors)
	confettiColors = paramColors;
	spawn(function()
		confettiActive = true;
		wait(tick);
		confettiActive = false;
	end);
end;
while wait(5) do
	fire({Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255)});
end;
]]