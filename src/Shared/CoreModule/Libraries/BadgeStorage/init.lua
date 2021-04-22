-- Variables
local badgeStorageLibrary = {}

-- Methods
function badgeStorageLibrary.GetBadgeList(badgeListName)
    if typeof(badgeListName) ~= "string" then return end
    if not script:FindFirstChild(badgeListName) or not script:FindFirstChild(badgeListName):IsA("ModuleScript") then return end
    return require(script:FindFirstChild(badgeListName))
end


--
return badgeStorageLibrary