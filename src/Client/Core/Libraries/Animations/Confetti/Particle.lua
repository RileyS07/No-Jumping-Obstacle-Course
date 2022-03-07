local randomNumberGenerator: Random = Random.new()
local currentCamera: Camera = workspace.CurrentCamera

local Particle = {}
Particle.__index = Particle
Particle.DEFAULT_EMITTER_POSITION = UDim2.fromScale(0.5, 0)
Particle.DEFAULT_EMITTER_POWER_RANGE = {X = NumberRange.new(-50, 50), Y = NumberRange.new(-20, -5)}
Particle.DEFAULT_MAX_CYCLE_COUNT = 1
Particle.DEFAULT_MAXIMUM_SIZE = 30
Particle.GRAVITY_HORIZONTAL_DAMPENING = 1.09
Particle.GRAVITY_VERTICAL_DAMPENING = 1.1
Particle.DEFAULT_COLORS = {
    Color3.fromRGB(168,100,253),
    Color3.fromRGB(41,205,255),
    Color3.fromRGB(120,255,68),
    Color3.fromRGB(255,113,141),
    Color3.fromRGB(253,255,106)
}

-- Creates a new Particle instance.
function Particle.new(parent: Instance)


    -- Creating the new instance.
    local newInstance: {} = setmetatable({}, Particle)

    -- Setting up the options.
    newInstance.Options = {
        Colors = Particle.DEFAULT_COLORS,
        MaxCycleCount = Particle.DEFAULT_MAX_CYCLE_COUNT,
        MaximumSize = Particle.DEFAULT_MAXIMUM_SIZE
    }

    -- These two values never change, they're just used for reference.
    newInstance.EmitterPosition = Particle.DEFAULT_EMITTER_POSITION
    newInstance.EmitterPower = Vector2.new(
        randomNumberGenerator:NextNumber(Particle.DEFAULT_EMITTER_POWER_RANGE.X.Min, Particle.DEFAULT_EMITTER_POWER_RANGE.X.Max),
        randomNumberGenerator:NextNumber(Particle.DEFAULT_EMITTER_POWER_RANGE.Y.Min, Particle.DEFAULT_EMITTER_POWER_RANGE.Y.Max)
    )

    -- These values will change when updated.
    newInstance.ParticlePosition = Vector2.new(0, 0)
    newInstance.CurrentEmitterPower = newInstance.EmitterPower
    newInstance.Color = newInstance:GetRandomColor()
    newInstance.IsEnabled = false
    newInstance.IsOutOfBounds = false
    newInstance.CycleCount = 0
    newInstance.HorizontalGrowDirection = -1
    newInstance.Cycled = Instance.new("BindableEvent")

    -- Creating the interface.
    newInstance._Interface = Particle._CreateParticleInterface(newInstance.Color, parent)

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
    self.Cycled:Destroy()
    self:Disable()
end

-- Returns whether or not the particle is done cycling.
function Particle:IsFinished() : boolean
    return self.CycleCount >= self.Options.MaxCycleCount
end

-- Updates this particles emitter position.
function Particle:SetEmitterPosition(emitterPosition: UDim2?)
    if not emitterPosition then return end

    self.EmitterPosition = emitterPosition
end

function Particle:SetEmitterPower(emitterPower: Vector2?)
    if not emitterPower then return end

    self.EmitterPower = Vector2.new(
        emitterPower.X,
        emitterPower.Y + ((0 - math.abs(emitterPower.X)) * 0.75)
    )
end

-- Updates this particles options.
function Particle:SetOptions(newOptions: {}?)
    if not newOptions then return end

    self.Options.Colors = newOptions.Colors or self.Options.Colors
    self.Options.MaxCycleCount = newOptions.MaxCycleCount or self.Options.MaxCycleCount
    self.Options.MaximumSize = newOptions.MaximumSize or self.Options.MaximumSize
end

-- Update the position of the confetti.
function Particle:Update(gravity: Vector2)

    -- It's out of bounds!
    -- This is how we detect when it's done a cycle.
    if self.IsEnabled and self.IsOutOfBounds then
        self.ParticlePosition = Vector2.new()
        self.CycleCount += 1
        self.Cycled:Fire()
        self.CurrentEmitterPower = self.EmitterPower + Vector2.new(
            randomNumberGenerator:NextNumber(-5, 5),
            randomNumberGenerator:NextNumber(-5, 5)
        )

        if self._Interface then
            self._Interface.ImageColor3 = self.Color
        end
    end

    -- We reached the maximum amount of CycleCount.
    if self:IsFinished() then
        self.IsOutOfBounds = true

        if self._Interface then
            self._Interface.Visible = false
        end

        return
    end

    -- If the particle is not enabled we still want it to finish this cycle before making the interface visible.
    if not self.IsEnabled and (self.IsOutOfBounds or self.CycleCount == 0) then
        self.IsOutOfBounds = true
        self.Color = self:GetRandomColor()

        if self._Interface then
            self._Interface.Visible = false
        end
    elseif self._Interface then
        self._Interface.Visible = true
    end

    -- Now we can start updating the particles position.
    -- We need to keep references to these for some reason.
    local startingPosition: UDim2 = self.EmitterPosition
    local currentPosition: Vector2 = self.ParticlePosition
    local currentEmitterPower: Vector2 = self.CurrentEmitterPower

    -- We can only apply a change if the _Interface exists.
    if self._Interface then

        -- We want to update the position of the imageLabel.
        local newPosition: Vector2 = currentPosition - currentEmitterPower
        local newPower: Vector2 = Vector2.new(
            currentEmitterPower.X / Particle.GRAVITY_HORIZONTAL_DAMPENING - gravity.X,
            currentEmitterPower.Y / Particle.GRAVITY_VERTICAL_DAMPENING - gravity.Y
        )

        -- This does basically everything.
        self._Interface.Position = startingPosition + UDim2.fromOffset(newPosition.X, newPosition.Y)

        -- Updating the values to reflect these new changes..
        self.ParticlePosition = newPosition
        self.CurrentEmitterPower = newPower
        self.IsOutOfBounds = self:DetermineIsOutOfBounds(gravity)

        -- It can start spinning if it's reached it's max height.
        if newPower.Y < 0 then

            -- If the size is <= 0 then we need to increase it.
            -- HorizontalGrowDirection determines which direction it grows in.
            if self._Interface.Size.Y.Offset <= 0 then
                self.HorizontalGrowDirection = 1
                self._Interface.ImageColor3 = self.Color
            end

            -- If the size is >= the maximum size we need to decrease it.
            -- It's my guess we change the color to implement some sort of effect.
            if self._Interface.Size.Y.Offset >= self.Options.MaximumSize then
                self.HorizontalGrowDirection = -1
                self._Interface.ImageColor3 = Color3.new(
                    self.Color.R * 0.65,
                    self.Color.G * 0.65,
                    self.Color.B * 0.65
                )
            end

            -- We increase the size based on the HorizontalGrowDirection value.
            self._Interface.Size = UDim2.fromOffset(
                self.Options.MaximumSize,
                self._Interface.Size.Y.Offset + self.HorizontalGrowDirection * 2
            )
        end
    end
end

-- Gets a random color from this particles options.
function Particle:GetRandomColor() : Color3
    return self.Options.Colors[randomNumberGenerator:NextInteger(1, #self.Options.Colors)]
end

-- Determines whether or not the particle is out of bounds.
function Particle:DetermineIsOutOfBounds(currentGravity: number) : boolean

    local currentViewportSize: Vector2 = currentCamera.ViewportSize

    return
        (self._Interface.AbsolutePosition.X > currentViewportSize.X and currentGravity.X > 0) or
        (self._Interface.AbsolutePosition.Y > currentViewportSize.Y and currentGravity.Y > 0) or
        (self._Interface.AbsolutePosition.X < 0  and currentGravity.X < 0) or
        (self._Interface.AbsolutePosition.Y < 0 and currentGravity.Y < 0)
end

-- Creates the interface for the particle itself.
function Particle._CreateParticleInterface(color: Color3, parent: Instance) : ImageLabel

    local particleShapes: {} = {
        script.Parent:WaitForChild("CircularConfetti"),
        script.Parent:WaitForChild("SquareConfetti")
    }

    -- Creating the interface
    local particleInterface: ImageLabel = particleShapes[randomNumberGenerator:NextInteger(1, #particleShapes)]:Clone()
    particleInterface.ImageColor3 = color
    particleInterface.Rotation = randomNumberGenerator:NextNumber(1, 360)
    particleInterface.Visible = true
    particleInterface.ZIndex = 20
    particleInterface.Parent = parent

    return particleInterface
end

export type Particle = typeof(Particle.new())
return Particle
