local players: Players = game:GetService("Players")

local SpatialQueryUtilities = {}

-- Returns a list of players that have part of their character inside of the given part.
function SpatialQueryUtilities.GetPlayersWithinParts(part: BasePart, overlapParameters: OverlapParams?) : {Player}

    local playersArray: {Player} = {}

    for _, partWithinPart: BasePart in next, workspace:GetPartsInPart(part, overlapParameters) do

        -- Is this a player and one that is not in the array already?
        local player: Player? = players:GetPlayerFromCharacter(partWithinPart:FindFirstAncestorOfClass("Model"))

        if player and not table.find(playersArray, player) then
            table.insert(playersArray, player)
        end
    end

    return playersArray
end

-- Returns a list of players that have a part of their character within a box area.
function SpatialQueryUtilities.GetPlayersWithinBox(cframe: CFrame, size: Vector3, overlapParameters: OverlapParams?) : {Player}

    local playersArray: {Player} = {}

    for _, partsWithinBox: BasePart in next, workspace:GetPartBoundsInBox(cframe, size, overlapParameters) do

        -- Is this a player and one that is not in the array already?
        local player: Player? = players:GetPlayerFromCharacter(partsWithinBox:FindFirstAncestorOfClass("Model"))

        if player and not table.find(playersArray, player) then
            table.insert(playersArray, player)
        end
    end

    return playersArray
end

-- Returns a whitelist OverlapParams instance that only allows characters.
function SpatialQueryUtilities.CreateCharacterWhitelistOverlapParams() : OverlapParams

    local filterDescendantsInstances: {Model} = {}
    local overlapParameters: OverlapParams = OverlapParams.new()
    overlapParameters.FilterType = Enum.RaycastFilterType.Whitelist

    -- Creating the filter array.
    for _, player: Player in next, players:GetPlayers() do
        if player.Character then
            table.insert(filterDescendantsInstances, player.Character)
        end
    end

    overlapParameters.FilterDescendantsInstances = filterDescendantsInstances

    return overlapParameters
end

return SpatialQueryUtilities