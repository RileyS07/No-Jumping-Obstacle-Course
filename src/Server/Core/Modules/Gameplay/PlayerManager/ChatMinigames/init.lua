--[[
    https://www.spigotmc.org/resources/chatreaction.3748/
]]
local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local config = require(coreModule.Shared.GetObject("Libraries.Config")).GetConfig(script.Name)
local wordBank = require(script.WordBank)

local chatMakeSystemMessageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.MakeSystemMessage")
local randomNumberGenerator: Random = Random.new()

local ChatMinigamesManager = {}
ChatMinigamesManager.IsMinigameActive = false
ChatMinigamesManager.MinigameInformation = {}
ChatMinigamesManager.MinigameNames = {"Math", "Scramble", "Reaction"}
ChatMinigamesManager.MinigameAnswer = ""

-- Initialize
function ChatMinigamesManager.Initialize()
--[[
    -- Setting up the loop to create and handle the minigames.
    task.spawn(function()
        while true do
            task.wait(config.CHAT_MINIGAME_DELAY)

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
            chatMakeSystemMessageRemote:FireAllClients(string.format(
                config.CHAT_MINIGAME_CORRECT_ANSWER_FORMAT,
                player.DisplayName
            ))
        end)
    end)]]
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

        answerMessage = tostring(numberA + numberB)
        messageToSendToClient = string.format(
            config.CHAT_MINIGAME_QUESTION_TYPE_MATH_FORMAT,
            tostring(numberA) .. " + " .. tostring(numberB)
        )

    -- For scramble we want to select a random word and scramble it.
    elseif selectedMinigame == "Scramble" then

        local selectedWord: string = wordBank[randomNumberGenerator:NextInteger(1, #wordBank)]
        local copyOfSelectedWord: string = selectedWord
        local scrambledWord: string = ""

        -- We select a random letter from the string and add it to the new one.
        for _ = 1, string.len(copyOfSelectedWord) do
            local thisIndex: number = randomNumberGenerator:NextInteger(1, string.len(copyOfSelectedWord))

            scrambledWord = scrambledWord .. string.sub(copyOfSelectedWord, thisIndex, thisIndex)
            copyOfSelectedWord = string.sub(copyOfSelectedWord, 1, thisIndex - 1) .. string.sub(copyOfSelectedWord, thisIndex + 1)
        end

        answerMessage = selectedWord
        messageToSendToClient = string.format(
            config.CHAT_MINIGAME_QUESTION_TYPE_SCRAMBLE_FORMAT,
            scrambledWord
        )

    elseif selectedMinigame == "Reaction" then

        local selectedWord: string = wordBank[randomNumberGenerator:NextInteger(1, #wordBank)]

        answerMessage = selectedWord
        messageToSendToClient = string.format(
            config.CHAT_MINIGAME_QUESTION_TYPE_REACTION_FORMAT,
            selectedWord
        )

    end

    -- Let's tell the client about this.
    ChatMinigamesManager.MinigameAnswer = answerMessage
    chatMakeSystemMessageRemote:FireAllClients(messageToSendToClient)
end

return ChatMinigamesManager
