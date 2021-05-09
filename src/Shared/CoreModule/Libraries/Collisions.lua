-- Variables
local collisionsLibrary = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function collisionsLibrary.GetCollisionGroup(collisionGroupName)
	local collisionGroupExists = pcall(coreModule.Services.PhysicsService.GetCollisionGroupId, coreModule.Services.PhysicsService, collisionGroupName)
	if not collisionGroupExists then
		pcall(coreModule.Services.PhysicsService.CreateCollisionGroup, coreModule.Services.PhysicsService, collisionGroupName)
	end
	
	return collisionGroupName
end


function collisionsLibrary.CollisionGroupSetCollidable(collisionGroupAName, collisionGroupBName, collidable)
	local collisionGroupA = collisionsLibrary.GetCollisionGroup(collisionGroupAName)
	local collisionGroupB = collisionsLibrary.GetCollisionGroup(collisionGroupBName)
	coreModule.Services.PhysicsService:CollisionGroupSetCollidable(collisionGroupA, collisionGroupB, collidable)
end


function collisionsLibrary.SetPartCollisionGroup(basePart, collisionGroupName)
	if not collisionsLibrary.GetCollisionGroup(collisionGroupName) then return end
	coreModule.Services.PhysicsService:SetPartCollisionGroup(basePart, collisionsLibrary.GetCollisionGroup(collisionGroupName))
end


function collisionsLibrary.SetDescendantsCollisionGroup(object, collisionGroupName)
	for _, basePart in next, object:GetDescendants() do
		if basePart:IsA("BasePart") then
			collisionsLibrary.SetPartCollisionGroup(basePart, collisionGroupName)
		end
	end
end


function collisionsLibrary.CollisionGroupContainsPart(collisionGroupName, basePart)
	if not collisionsLibrary.GetCollisionGroup(collisionGroupName) then return end
	return coreModule.Services.PhysicsService:CollisionGroupContainsPart(collisionsLibrary.GetCollisionGroup(collisionGroupName), basePart)
end


--
return collisionsLibrary