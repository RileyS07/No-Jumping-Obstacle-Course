-- Variables
local collisionsLibrary = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function collisionsLibrary.GetCollisionGroup(collisionGroupName)
	local collisionGroupExists = pcall(game:GetService("PhysicsService").GetCollisionGroupId, game:GetService("PhysicsService"), collisionGroupName)
	if not collisionGroupExists then
		pcall(game:GetService("PhysicsService").CreateCollisionGroup, game:GetService("PhysicsService"), collisionGroupName)
	end
	
	return collisionGroupName
end


function collisionsLibrary.CollisionGroupSetCollidable(collisionGroupAName, collisionGroupBName, collidable)
	local collisionGroupA = collisionsLibrary.GetCollisionGroup(collisionGroupAName)
	local collisionGroupB = collisionsLibrary.GetCollisionGroup(collisionGroupBName)
	game:GetService("PhysicsService"):CollisionGroupSetCollidable(collisionGroupA, collisionGroupB, collidable)
end


function collisionsLibrary.SetPartCollisionGroup(basePart, collisionGroupName)
	if not collisionsLibrary.GetCollisionGroup(collisionGroupName) then return end
	game:GetService("PhysicsService"):SetPartCollisionGroup(basePart, collisionsLibrary.GetCollisionGroup(collisionGroupName))
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
	return game:GetService("PhysicsService"):CollisionGroupContainsPart(collisionsLibrary.GetCollisionGroup(collisionGroupName), basePart)
end


--
return collisionsLibrary