--[[
    This module is meant to replace a global constants module with separate ones.
    It's my idea that loading in a small table is better than a large table into memory.
]]
local ConfigManager = {}

-- Returns the specified config.
function ConfigManager.GetConfig(configName: string) : {}

    -- If there is none we just return an empty table.
    if not script:FindFirstChild(configName) then
        warn("No config created for: " .. configName)
        return {}
    end

    return require(script:FindFirstChild(configName) :: ModuleScript)
end

return ConfigManager