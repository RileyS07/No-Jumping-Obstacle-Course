-- Variables
local coreModule = {}

-- Initialize
function coreModule.Initialize() 

end

-- Methods
function coreModule.GetObject(objectPathString, functionParameters)
    functionParameters = setmetatable(functionParameters or {}, {__index = {
        EnvironmentOffset = 0,
        ShowDebugMessage = false
    }})
    
    
end

-- 
return coreModule