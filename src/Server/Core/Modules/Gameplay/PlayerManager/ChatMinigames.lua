--[[
    https://www.spigotmc.org/resources/chatreaction.3748/
]]
local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local chatMakeSystemMessageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.MakeSystemMessage")
local randomNumberGenerator: Random = Random.new()

local ChatMinigamesManager = {}
ChatMinigamesManager.IsMinigameActive = false
ChatMinigamesManager.MinigameInformation = {}
ChatMinigamesManager.MinigameNames = {"Math", "Scramble", "Reaction"}
ChatMinigamesManager.MinigameAnswer = ""

-- Initialize
function ChatMinigamesManager.Initialize()

    -- Setting up the loop to create and handle the minigames.
    task.spawn(function()
        while true do
            task.wait(sharedConstants.GENERAL.CHAT_MINIGAME_DELAY)

            -- We create it and make players able to answer.
            ChatMinigamesManager._CreateMinigame()
            ChatMinigamesManager.SetIsMinigameActive(true)
        end
    end)

    -- Checking if players got it right.
    playerUtilities.CreatePlayerAddedWrapper(function(player: Player)
        player.Chatted:Connect(function(message: string)

            -- Can they answer this? And is this the right answer?
            if not ChatMinigamesManager.GetIsMinigameActive() then return end
            if ChatMinigamesManager.MinigameAnswer ~= message then return end

            -- They can answer it!
            ChatMinigamesManager.SetIsMinigameActive(false)
            chatMakeSystemMessageRemote:FireAllClients(player.DisplayName .. " has got the answer of " .. message .. " correct!")
        end)
    end)
end

-- Returns whether or not a minigame is currently active.
function ChatMinigamesManager.GetIsMinigameActive() : boolean
    return ChatMinigamesManager.IsMinigameActive
end

-- Sets whether or not a minigame is currently active.
function ChatMinigamesManager.SetIsMinigameActive(isMinigameActive: boolean)
    ChatMinigamesManager.IsMinigameActive = isMinigameActive
end

-- Creates a chat minigame.
function ChatMinigamesManager._CreateMinigame()

    -- We need to select which type of minigame to create.
    local selectedMinigame: string = ChatMinigamesManager.MinigameNames[randomNumberGenerator:NextInteger(1, #ChatMinigamesManager.MinigameNames)]
    local messageToSendToClient: string = ""
    local answerMessage: string = ""

    -- For math ones we just want a number within 1-1000.
    if selectedMinigame == "Math" then

        local numberA: number = randomNumberGenerator:NextInteger(1, 1000)
        local numberB: number = randomNumberGenerator:NextInteger(1, 1000)

        messageToSendToClient = "For a free skip, by the first to solve " .. tostring(numberA) .. " + " .. tostring(numberB)
        answerMessage = tostring(numberA + numberB)
    elseif selectedMinigame == "Scramble" then

        messageToSendToClient = "For a free skip, by the first to unscramble this word: eRiely_"
        answerMessage = "Rile_ey"
    elseif selectedMinigame == "Reaction" then

        messageToSendToClient = "For a free skip, by the first to type: Tommy"
        answerMessage = "Tommy"
    end

    -- Let's tell the client about this.
    ChatMinigamesManager.MinigameAnswer = answerMessage
    chatMakeSystemMessageRemote:FireAllClients(messageToSendToClient)
end

return ChatMinigamesManager
