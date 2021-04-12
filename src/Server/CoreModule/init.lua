-- Variables
local coreModule = {}
coreModule.Shared = nil
coreModule.DebugLevel = nil
coreModule.Services = nil
coreModule.Enums = nil

-- Initialize
function coreModule.Initialize()
    coreModule.Services = coreModule.SetupServices()
    coreModule.Shared = require(coreModule.Services.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CoreModule"))
    coreModule.Shared.Initialize();

    coreModule.Enums = coreModule.SetupEnums()
    coreModule.DebugLevel = coreModule.Shared.Enums.DebugLevel.Standard
    
    -- Loading submodules
    coreModule.LoadModule("Modules.GameplayManager")
end


-- Public Methods
-- A powerful yet niche method I love to give me the ability to write syntax like, coreModule.GetObject("ObjectName") or coreModule.GetObject "ObjectName".
function coreModule.GetObject(objectPathString, functionParameters) 
    functionParameters = setmetatable(functionParameters or {}, {__index = {
        EnvironmentOffset = 0,
        ShowDebugMessage = true
    }})
    
    -- Default values for the search
    local getObjectSearchLocation = script
    local getObjectSearchPathArray = objectPathString:split(".")

    --[[
        The method provides to QoL features for path matching;
        // - Starts the search off at the folder holding the CoreModule.
        /  - Starts the search off at the script that called GetObject.
    ]]

    if objectPathString:match("^//") then
        getObjectSearchLocation = script.Parent
        getObjectSearchPathArray = objectPathString:match("^//(.+)"):split(".")
    elseif objectPathString:match("^/") then
        getObjectSearchLocation = getfenv(2 + functionParameters.EnvironmentOffset).script
        getObjectSearchPathArray = objectPathString:match("^/(.+)"):split(".")
    end

    -- There's a lot of indexing here but it's just following the path array to the actual object
    for index = 1, #getObjectSearchPathArray do
        if not getObjectSearchLocation:FindFirstChild(getObjectSearchPathArray[index]) then
            -- I could just blindly index and accept whatever error Roblox wants to throw but I wanted to add a little more consistency
            coreModule.Debug(
                getObjectSearchLocation:GetFullName().." does not have a child/field named: "..getObjectSearchPathArray[index], 
                coreModule.Shared.Enums.DebugLevel.Exception, 
                error
            )
        end

        getObjectSearchLocation = getObjectSearchLocation[getObjectSearchPathArray[index]]
    end

    -- The only reason I have ShowDebugMessage is because I don't like LoadModule sending a GetObject debug call when trying to fetch the module.
    if functionParameters.ShowDebugMessage then 
        coreModule.Debug("Fetched asset: "..getObjectSearchLocation:GetFullName(), coreModule.Shared.Enums.DebugLevel.Core) 
    end

    return getObjectSearchLocation
end


-- A centralized way of loading modules so that I can take advantage of debugging/logging/analytics easier.
function coreModule.LoadModule(objectPathString, ...)
    local fetchedModuleObject = coreModule.GetObject(objectPathString, {ShowDebugMessage = false, EnvironmentOffset = 1})

    --[[
        Debugging #1; Checking for the following in order:
        1) Does the asset exist?
        2) Is the asset a ModuleScript?
        3) Can the module be required?
        4) Does the module return a table and have an 'Initialize' method?

        And then a final case where all checks were passed and we do a success debug message to start the loading process.
    ]]

    if not fetchedModuleObject then
        coreModule.Debug("Failed to fetch asset with objectPathString of: "..objectPathString, coreModule.Shared.Enums.DebugLevel.Exception, error)
    
    elseif not fetchedModuleObject:IsA("ModuleScript") then
        coreModule.Debug("Fetched asset: "..fetchedModuleObject:GetFullName()..", is not a ModuleScript", coreModule.Shared.Enums.DebugLevel.Exception, error)
    
    elseif not pcall(require, fetchedModuleObject) then
        coreModule.Debug("Failed to require module: "..fetchedModuleObject:GetFullName()..", because: "..select(2, pcall(require, fetchedModuleObject)), coreModule.Shared.Enums.DebugLevel.Exception, error)
    
    elseif not typeof(require(fetchedModuleObject)) == "table" or not require(fetchedModuleObject).Initialize then
        coreModule.Debug("Failed to initialize module: "..fetchedModuleObject:GetFullName()..", because it does not have an 'Initialize' method", coreModule.Shared.Enums.DebugLevel.Exception, error)
   
    else
        coreModule.Debug("Loading module: "..fetchedModuleObject:GetFullName())
    end

    -- Debugging #2; Just checking if the initialize call was successful or not, between these is also where we'll see a lot of cyclic behavior if you're not careful.
    local wasSuccessful, errorMessage = pcall(require(fetchedModuleObject).Initialize, ...)

    if not wasSuccessful then
        coreModule.Debug("Failed to initialize module: "..fetchedModuleObject:GetFullName()..", because: "..errorMessage, coreModule.Shared.Enums.DebugLevel.Exception, error)
    else
        coreModule.Debug("Loaded module: "..fetchedModuleObject:GetFullName())
    end
end


-- Centralized and consistent debugging.
function coreModule.Debug(debugMessage, debugLevel, outputFunction)
    --[[
        So this excessively long line only checks 3 things:
        1) Did you pass a DebugLevel of 'Exception' which ignores the DebugLevel assigned to the module?
        2) Is the current DebugLevel assigned equal to 'All'?
        3) Is the current DebugLevel assigned equal to the debugLevel you passed into the function?
    ]]

    if debugLevel == coreModule.Shared.Enums.DebugLevel.Exception or coreModule.DebugLevel == coreModule.Shared.Enums.DebugLevel.All or coreModule.DebugLevel == (debugLevel or coreModule.Shared.Enums.DebugLevel.Standard) then
       -- [00:01][Debug]: This is an example debug message that was made one second after the server started.
        (outputFunction or print)(
            "["..("%02d:%02d"):format(math.floor(time()/60), time()%60).."][Debug]: "..debugMessage 
        )
    end
end


-- Private Methods
function coreModule.SetupServices()
    return setmetatable({}, {__index = function(cache, serviceName)
        cache[serviceName] = game:GetService(serviceName)
        return cache[serviceName]
    end})
end


function coreModule.SetupEnums()
    return setmetatable({}, {__index = function(cache, enumName)
        cache[enumName] = require(script.Enums[enumName])
        return cache[enumName]
    end})
end


--
return coreModule