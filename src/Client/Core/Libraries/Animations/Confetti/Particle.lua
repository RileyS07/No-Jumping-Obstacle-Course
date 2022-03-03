local randomNumberGenerator: Random = Random.new()
local currentCamera: Camera = workspace.CurrentCamera

local Particle = {}
Particle.DEFAULT_EMITTER_POSITION = UDim2.fromScale(0.5, -0.1)
Particle.DEFAULT_EMITTER_POWER_RANGE = {X = NumberRange.new(-50, 50), Y = NumberRange.new(-20, -10)}
Particle.MAXIMUM_SIZE = 30
Particle.__index = Particle

Particle.Shapes = {script.Parent:WaitForChild("CircularConfetti"), script.Parent:WaitForChild("SquareConfetti")}
Particle.DEFAULT_COLORS = {
    Color3.fromRGB(168,100,253),
    Color3.fromRGB(41,205,255),
    Color3.fromRGB(120,255,68),
    Color3.fromRGB(255,113,141),
    Color3.fromRGB(253,255,106)
}

-- Creates a new Particle instance.
function Particle.new(parent: Instance, maxCycles: number?, emitterPosition: UDim2?, emitterPower: Vector2?)

    local startingEmitterPower: Vector2? = emitterPower and Vector2.new(
        emitterPower.X,
        emitterPower.Y + ((0 - math.abs(emitterPower.X)) * 0.75)
    )

    -- Creating the new instance.
    local newInstance: {} = setmetatable({}, Particle)

    -- These two values never change, they're just used for reference.
    newInstance.EmitterPosition = emitterPosition or Particle.DEFAULT_EMITTER_POSITION
    newInstance.EmitterPower = startingEmitterPower or Vector2.new(
        randomNumberGenerator:NextNumber(Particle.DEFAULT_EMITTER_POWER_RANGE.X.Min, Particle.DEFAULT_EMITTER_POWER_RANGE.X.Max),
        randomNumberGenerator:NextNumber(Particle.DEFAULT_EMITTER_POWER_RANGE.Y.Min, Particle.DEFAULT_EMITTER_POWER_RANGE.Y.Max)
    )

    -- These values will change when updated.
    newInstance.ParticlePosition = Vector2.new()
    newInstance.CurrentEmitterPower = newInstance.EmitterPower
    newInstance.Color = Particle.DEFAULT_COLORS[randomNumberGenerator:NextInteger(1, #Particle.DEFAULT_COLORS)]
    newInstance.IsEnabled = false
    newInstance.IsOutOfBounds = false
    newInstance.CycleCount = 0
    newInstance.HorizontalGrowDirection = -1

    -- Creating the interface.
    newInstance._Interface = Particle._CreateParticleInterface(newInstance.Color, parent)

    -- Setting up the options.
    newInstance.Options = {
        Colors = Particle.DEFAULT_COLORS,
        MaxCycleCount = maxCycles or math.huge
    }

	return newInstance
end

-- Enables the particle.
function Particle:Enable()
    self.IsEnabled = true
end

-- Disables the particle.
function Particle:Disable()
    self.IsEnabled = false
end

-- Destroys the Particle instance.
function Particle:Destroy()
	self._Interface:Destroy()
end

-- Update the position of the confetti.
function Particle:Update(gravity: Vector2)

    -- It's out of bounds!
    if self.IsEnabled and self.IsOutOfBounds then
        self._Interface.ImageColor3 = self.Color
        self.ParticlePosition = Vector2.new()
        self.CurrentEmitterPower = self.EmitterPower + Vector2.new(randomNumberGenerator:NextNumber(-5, 5), randomNumberGenerator:NextNumber(-5, 5))
        self.CycleCount += 1
    end

    -- This is out of bounds and not enabled or it's enabled and has 0 CycleCount.
    -- The documentation is very sparse so I don't exactly know why it does this.
    -- It really just regenerates the Color.
    if (not self.IsEnabled and self.IsOutOfBounds) or (not self.IsEnabled and self.CycleCount == 0) then
        self._Interface.Visible = false
        self.IsOutOfBounds = true
        self.Color = self:GetRandomColor()
    else
        self._Interface.Visible = true
    end

    -- We reached the maximum amount of CycleCount.
    if self.CycleCount >= self.Options.MaxCycleCount then
        self._Interface.Visible = false
        self.IsOutOfBounds = true
        return
    end

    -- We need to keep references to these for some reason.
    local startingPosition: UDim2 = self.EmitterPosition
    local currentPosition: Vector2 = self.ParticlePosition
    local CurrentEmitterPower: Vector2 = self.CurrentEmitterPower
    local imageLabel: ImageLabel = self._Interface

    -- We can only apply a change if the _Interface exists.
    if imageLabel then

        -- We want to update the position of the imageLabel.
        local newPosition: Vector2 = Vector2.new(currentPosition.X - CurrentEmitterPower.X, currentPosition.Y - CurrentEmitterPower.Y)
        local newPower: Vector2 = Vector2.new(CurrentEmitterPower.X / 1.09 - gravity.X, CurrentEmitterPower.Y / 1.1 - gravity.Y)

        local currentViewportSize: Vector2 = currentCamera.ViewportSize
        imageLabel.Position = startingPosition + UDim2.fromOffset(newPosition.X, newPosition.Y)

        -- Is it now out of bounds?
        self.IsOutOfBounds =
            (imageLabel.AbsolutePosition.X > currentViewportSize.X and gravity.X > 0) or
            (imageLabel.AbsolutePosition.Y > currentViewportSize.Y and gravity.Y > 0) or
            (imageLabel.AbsolutePosition.X < 0  and gravity.X < 0) or
            (imageLabel.AbsolutePosition.Y < 0 and gravity.Y < 0)

        -- Updating the position and CurrentEmitterPower to reflect the new changes.
        self.ParticlePosition = newPosition
        self.CurrentEmitterPower = newPower

        -- It can start spinning if it's reached it's max height.
        if newPower.Y < 0 then

            -- If the size is <= 0 then we need to increase it.
            -- HorizontalGrowDirection determines which direction it grows in.
            if imageLabel.Size.Y.Offset <= 0 then
                self.HorizontalGrowDirection = 1
                imageLabel.ImageColor3 = self.Color
            end

            -- If the size is >= the maximum size we need to decrease it.
            if imageLabel.Size.Y.Offset >= Particle.MAXIMUM_SIZE then
                self.HorizontalGrowDirection = -1
                imageLabel.ImageColor3 = Color3.new(self.Color.R * 0.65, self.Color.G * 0.65, self.Color.B * 0.65)
            end

            -- We increase the size based on the HorizontalGrowDirection value.
            imageLabel.Size = UDim2.new(0, Particle.MAXIMUM_SIZE, 0, imageLabel.Size.Y.Offset + self.HorizontalGrowDirection * 2)
        end
    end
end

-- Gets a random color from this particles options.
function Particle:GetRandomColor() : Color3
    return self.Options.Colors[randomNumberGenerator:NextInteger(1, #self.Options.Colors)]
end

-- Creates the interface for the particle itself.
function Particle._CreateParticleInterface(color: Color3, parent: Instance) : ImageLabel

    local particleInterface: ImageLabel = Particle.Shapes[randomNumberGenerator:NextInteger(1, #Particle.Shapes)]:Clone()
    particleInterface.ImageColor3 = color
    particleInterface.Rotation = randomNumberGenerator:NextNumber(1, 360)
    particleInterface.Visible = true
    particleInterface.ZIndex = 20
    particleInterface.Parent = parent

    return particleInterface
end

export type Particle = typeof(Particle.new())
return Particle
