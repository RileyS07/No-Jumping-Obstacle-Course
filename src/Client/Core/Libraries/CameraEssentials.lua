-- Variables
local cameraEssentialsLibrary = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Methods
function cameraEssentialsLibrary.IsCurrentCameraReadyForManipulation()
    if not workspace.CurrentCamera then return false end
    return workspace.CurrentCamera.CameraSubject ~= nil	
end


function cameraEssentialsLibrary.YieldTillCurrentCameraIsReadyForManipulation()
    if not cameraEssentialsLibrary.IsCurrentCameraReadyForManipulation() then
        repeat wait() until cameraEssentialsLibrary.IsCurrentCameraReadyForManipulation()
    end
end


--
return cameraEssentialsLibrary