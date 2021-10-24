-- Variables
local instanceUtilities = {}

-- Public Methods

-- An extension of Instance.new to support all properties.
function instanceUtilities.Create(className: string, properties: {[string]: any}?) : Instance
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
function instanceUtilities.SafeDestroy(instance: Instance?)
    if typeof(instance) == "Instance" then
        instance:Destroy()
    end
end

--[[
    local children: {Instance} = instanceUtilities.GetChildren(workspace, function(instance: Instance)
        return instance:IsA("BasePart")
    end)
]]
-- An extension of Instance:GetChildren() to only get certain children.
function instanceUtilities.GetChildren(instance: Instance, filterFunction: (Instance) -> boolean) : {Instance}
    assert(typeof(instance) == "Instance", "Argument #1 expected Instance. Got " .. typeof(instance))
    assert(typeof(filterFunction) == "function", "Argument #2 expected function. Got " .. typeof(filterFunction))

    local children = instance:GetChildren()

    -- Sorting them out.
    for index = #children, 1, -1 do
        if not filterFunction(children[index]) then
            table.remove(children, index)
        end
    end

    return children
end

--[[
    local descendants: {Instance} = instanceUtilities.GetDescendants(workspace, function(instance: Instance)
        return instance:IsA("BasePart")
    end)
]]
-- An extension of Instance:GetDescendants() to only get certain descendants.
function instanceUtilities.GetDescendants(instance: Instance, filterFunction: (Instance) -> boolean) : {Instance}
    assert(typeof(instance) == "Instance", "Argument #1 expected Instance. Got " .. typeof(instance))
    assert(typeof(filterFunction) == "function", "Argument #2 expected function. Got " .. typeof(filterFunction))

    local descendants = instance:GetDescendants()

    for index = #descendants, 1, -1 do
        if not filterFunction(descendants[index]) then
            table.remove(descendants, index)
        end
    end

    return descendants
end

--
return instanceUtilities