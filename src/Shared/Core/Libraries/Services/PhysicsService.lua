local physicsService: PhysicsService = game:GetService("PhysicsService")

local PhysicsServiceWrapper = {}

-- Returns whether the part is in the collision group.
function PhysicsServiceWrapper.CollisionGroupContainsPart(collisionGroupName: string, part: BasePart) : boolean

	if not PhysicsServiceWrapper._GetCollisionGroup(collisionGroupName) then
		return false
	end

	return physicsService:CollisionGroupContainsPart(
		PhysicsServiceWrapper._GetCollisionGroup(collisionGroupName),
		part
	)
end

-- Sets the collision status between two groups.
function PhysicsServiceWrapper.CollisionGroupSetCollidable(collisionGroupAName: string, collisionGroupBName, areCollidable: boolean)

	local collisionGroupA: string = PhysicsServiceWrapper._GetCollisionGroup(collisionGroupAName)
	local collisionGroupB: string = PhysicsServiceWrapper._GetCollisionGroup(collisionGroupBName)

	if collisionGroupA and collisionGroupB then
		physicsService:CollisionGroupSetCollidable(collisionGroupA, collisionGroupB, areCollidable)
	end
end

-- Returns whether the two groups will collide.
function PhysicsServiceWrapper.CollisionGroupsAreCollidable(collisionGroupAName: string, collisionGroupBName: string) : boolean

	local collisionGroupAId: number = PhysicsServiceWrapper.GetCollisionGroupId(collisionGroupAName)
	local collisionGroupBId: number = PhysicsServiceWrapper.GetCollisionGroupId(collisionGroupBName)

	if collisionGroupAId ~= -1 and collisionGroupBId ~= -1 then
		return physicsService:CollisionGroupsAreCollidable(collisionGroupAName, collisionGroupBName)
	else
		return false
	end
end

-- Creates a new collision group with the given name, and returns the id of the created group.
function PhysicsServiceWrapper.CreateCollisionGroup(collisionGroupName: string) : number

	local wasSuccessful: boolean, collisionGroupId: number | string = pcall(physicsService.CreateCollisionGroup, physicsService, collisionGroupName)
	return wasSuccessful and collisionGroupId or -1
end

-- Returns the id of the group with the specified name.
function PhysicsServiceWrapper.GetCollisionGroupId(collisionGroupName: string) : number

	local wasSuccessful: boolean, collisionGroupId: number | string = pcall(physicsService.GetCollisionGroupId, physicsService, collisionGroupName)
	return wasSuccessful and collisionGroupId or -1
end

-- Returns the name of the group with the corresponding id.
function PhysicsServiceWrapper.GetCollisionGroupName(collisionGroupId: number) : string

	local wasSuccessful: boolean, collisionGroupName: string = pcall(physicsService.GetCollisionGroupName, physicsService, collisionGroupId)
	return wasSuccessful and collisionGroupName or ""
end

-- Returns a table with info on all of the place’s collision groups.
function PhysicsServiceWrapper.GetCollisionGroups() : {}
	return physicsService:GetCollisionGroups()
end

-- Returns the maximum number of collision groups.
function PhysicsServiceWrapper.GetMaxCollisionGroups() : number
	return physicsService:GetMaxCollisionGroups()
end

-- There is no documentation for what this does...
function PhysicsServiceWrapper.LocalIkSolve(...)
	physicsService:LocalIkSolve(...)
end

-- Removes the collision group with the given name.
function PhysicsServiceWrapper.RemoveCollisionGroup(collisionGroupName: string) : boolean
	return (pcall(physicsService.RemoveCollisionGroup, physicsService, PhysicsServiceWrapper._GetCollisionGroup(collisionGroupName)))
end

-- Renames specified collision group.
function PhysicsServiceWrapper.RenameCollisionGroup(originalCollisionGroupName: string, newCollisionGroupName: string) : boolean
	return (pcall(physicsService.RenameCollisionGroup, physicsService, originalCollisionGroupName, newCollisionGroupName))
end

-- Sets the collision group of a part.
function PhysicsServiceWrapper.SetPartCollisionGroup(part: BasePart, collisionGroupName: string)
	physicsService:SetPartCollisionGroup(part, PhysicsServiceWrapper._GetCollisionGroup(collisionGroupName))
end

-- Sets the collision group of any parts in a collection.
function PhysicsServiceWrapper.SetCollectionsCollisionGroup(collection: {}, collisionGroupName: string)

    for _, object in next, collection do
		if typeof(object) == "Instance" and object:IsA("BasePart") then
			PhysicsServiceWrapper.SetPartCollisionGroup(object, collisionGroupName)
		end
	end
end

-- Creates the collision group if it does not exist.
function PhysicsServiceWrapper._GetCollisionGroup(collisionGroupName: string)

	if PhysicsServiceWrapper.GetCollisionGroupId(collisionGroupName) == -1 then
		PhysicsServiceWrapper.CreateCollisionGroup(collisionGroupName)
	end

	return collisionGroupName
end

return PhysicsServiceWrapper
