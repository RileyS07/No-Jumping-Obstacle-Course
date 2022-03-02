local collectionService: CollectionService = game:GetService("CollectionService")

local InstanceUtilities = {}

-- An extension of Instance.new to support all properties.
function InstanceUtilities.Create(className: string, properties: {[string]: any}?) : Instance

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
function InstanceUtilities.SafeDestroy(thisInstance: Instance?)
    if typeof(thisInstance) == "Instance" then
        thisInstance:Destroy()
    end
end

-- An extension of Instance:GetChildren() to only get certain children with a filter.
function InstanceUtilities.GetChildren(thisInstance: Instance, filterFunction: (Instance) -> boolean) : {Instance}

    local children = thisInstance:GetChildren()

    -- Sorting them out.
    for index = #children, 1, -1 do
        if not filterFunction(children[index]) then
            table.remove(children, index)
        end
    end

    return children
end

-- An extension of Instance:GetChildren() to only get certain children of a class type.
function InstanceUtilities.GetChildrenWhichAre(thisInstance: Instance, className: string) : {Instance}

    local children = thisInstance:GetChildren()

    -- Sorting them out.
    for index = #children, 1, -1 do
        if not children[index]:IsA(className) then
            table.remove(children, index)
        end
    end

    return children
end

-- An extension of Instance:GetDescendants() to only get certain descendants.
function InstanceUtilities.GetDescendants(thisInstance: Instance, filterFunction: (Instance) -> boolean) : {Instance}

    local descendants = thisInstance:GetDescendants()

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


-- This function will remove all tags from this given instance.
function InstanceUtilities.RemoveTags(thisInstance: Instance)

	for _, collectionServiceTagName: string in next, collectionService:GetTags(thisInstance) do
		collectionService:RemoveTag(thisInstance, collectionServiceTagName)
	end
end

return InstanceUtilities
