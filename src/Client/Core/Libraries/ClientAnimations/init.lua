-- Variables
local clientAnimationsLibrary = {}

-- Initialize
function clientAnimationsLibrary.PlayAnimation(animationName, ...)
    if typeof(animationName) ~= "string" then return end
    if not script:FindFirstChild(animationName) then return end
    if not script:FindFirstChild(animationName):IsA("ModuleScript") then return end
    local packedArguments = {...}

    return select(2, pcall(function()
        return require(script:FindFirstChild(animationName)).Play(unpack(packedArguments))
    end))
end


function clientAnimationsLibrary.PauseAnimation(animationName, ...)
    if typeof(animationName) ~= "string" then return end
    if not script:FindFirstChild(animationName) then return end
    if not script:FindFirstChild(animationName):IsA("ModuleScript") then return end
    local packedArguments = {...}

    return select(2, pcall(function()
        return require(script:FindFirstChild(animationName)).Pause(unpack(packedArguments))
    end))
end


function clientAnimationsLibrary.StopAnimation(animationName, ...)
    if typeof(animationName) ~= "string" then return end
    if not script:FindFirstChild(animationName) then return end
    if not script:FindFirstChild(animationName):IsA("ModuleScript") then return end
    local packedArguments = {...}
    
    return select(2, pcall(function()
        return require(script:FindFirstChild(animationName)).Stop(unpack(packedArguments))
    end))
end


--
return clientAnimationsLibrary