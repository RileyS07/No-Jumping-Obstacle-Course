local InstanceUtilities = {}

-- An extension of Instance.new to support all properties.
function InstanceUtilities.Create(className: string, properties: {[string]: any}?) : Instance
    assert(typeof(className) == "string", "Argument #1 expected string. Got " .. typeof(className))
    assert(typeof(properties) == "table" or typeof(properties) == "nil", "Argument #2 expected dictionary. Got " .. typeof(properties))

    local newInstance = Instance.new(className)
    properties = properties or {}

    for propertyName, propertyValue in next, properties do
        if typeof(propertyName) == "string" and propertyName ~= "Parent" then
            newInstance[propertyName] = propertyValue
        end
    end

    newInstance.Parent = properties.Parent

    return newInstance
end

-- A function to replace the common scheme of 'if ... then (...):Destroy() end'
function InstanceUtilities.SafeDestroy(instance: Instance?)
    if typeof(instance) == "Instance" then
        instance:Destroy()
    end
end

-- An extension of Instance:GetChildren() to only get certain children with a filter.
function InstanceUtilities.GetChildren(instance: Instance, filterFunction: (Instance) -> boolean) : {Instance}

    local children = instance:GetChildren()

    -- Sorting them out.
    for index = #children, 1, -1 do
        if not filterFunction(children[index]) then
            table.remove(children, index)
        end
    end

    return children
end

-- An extension of Instance:GetChildren() to only get certain children of a class type.
function InstanceUtilities.GetChildrenWhichAre(instance: Instance, className: string) : {Instance}

    local children = instance:GetChildren()

    -- Sorting them out.
    for index = #children, 1, -1 do
        if not children[index]:IsA(className) then
            table.remove(children, index)
        end
    end

    return children
end

-- An extension of Instance:GetDescendants() to only get certain descendants.
function InstanceUtilities.GetDescendants(instance: Instance, filterFunction: (Instance) -> boolean) : {Instance}

    local descendants = instance:GetDescendants()

    -- Sorting them out.
    for index = #descendants, 1, -1 do
        if not filterFunction(descendants[index]) then
            table.remove(descendants, index)
        end
    end

    return descendants
end

-- This function returns the total mass of an instances parts.
function InstanceUtilities.GetMass(thisInstance: Instance) : number

    local finalMassAmount: number = 0

    -- We want to check all of it's descendants.
    for _, descendant: Instance in next, thisInstance:GetDescendants() do
        if descendant:IsA("BasePart") then
            finalMassAmount += (descendant :: BasePart):GetMass()
        end
    end

    return finalMassAmount
end

return InstanceUtilities
