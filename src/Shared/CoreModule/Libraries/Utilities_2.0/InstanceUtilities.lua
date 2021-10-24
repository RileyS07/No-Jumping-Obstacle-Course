-- Variables
local instanceUtilitiesLibrary = {}

-- Public Methods

-- An extension of Instance.new to support all properties.
function instanceUtilitiesLibrary.Create(className: string, properties: {[string]: any}?) : Instance
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
function instanceUtilitiesLibrary.SafeDestroy(instance: Instance?)
    if typeof(instance) == "Instance" then
        instance:Destroy()
    end
end

--
return instanceUtilitiesLibrary