-- Variables
local collisionsLibrary = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function collisionsLibrary.GetCollisionGroup(groupName)
	local collisionGroupExists = pcall(coreModule.Services.PhysicsService.GetCollisionGroupId, coreModule.Services.PhysicsService, groupName)
	if not collisionGroupExists then
		pcall(coreModule.Services.PhysicsService.CreateCollisionGroup, coreModule.Services.PhysicsService, groupName)
	end
	
	return groupName
end


function collisionsLibrary.CollisionGroupSetCollidable(collisionGroupAName, collisionGroupBName, collidable)
	local collisionGroupA = collisionsLibrary.GetCollisionGroup(collisionGroupAName)
	local collisionGroupB = collisionsLibrary.GetCollisionGroup(collisionGroupBName)
	coreModule.Services.PhysicsService:CollisionGroupSetCollidable(collisionGroupA, collisionGroupB, collidable)
end


function collisionsLibrary.SetPartCollisionGroup(basePart, collisionGroupName)
	coreModule.Services.PhysicsService:SetPartCollisionGroup(basePart, collisionsLibrary.GetCollisionGroup(collisionGroupName))
end


function collisionsLibrary.SetDescendantsCollisionGroup(object, collisionGroupName)
	for _, basePart in next, object:GetDescendants() do
		if basePart:IsA("BasePart") then
			collisionsLibrary.SetPartCollisionGroup(basePart, collisionGroupName)
		end
	end
end


--
return collisionsLibrary