local CameraUtilities = {}

-- Returns workspace.CurrentCamera.
-- Will yield till it can obtain it.
function CameraUtilities.GetCurrentCamera() : Camera

    -- Can we get it right away?
    if workspace.CurrentCamera then
        return workspace.CurrentCamera
    end

    -- It's not that easy huh.
    repeat
        task.wait()
    until workspace.CurrentCamera ~= nil

    return workspace.CurrentCamera
end

-- Returns whether or not we can manipulate the current camera.
-- We are looking to see if CameraSubject has been set.
function CameraUtilities.IsCurrentCameraManipulatable() : boolean
    return CameraUtilities.GetCurrentCamera().CameraSubject ~= nil
end

-- Waits for the CurrentCamera to be ready for manipulation.
-- We need to wait till roblox has assigned the CameraSubject before we override.
function CameraUtilities.WaitTillCurrentCameraIsManipulatable()

    -- Do we even need to wait?
    if not CameraUtilities.IsCurrentCameraManipulatable() then

        -- We do need to.
        repeat
            task.wait()
        until CameraUtilities.IsCurrentCameraManipulatable()
    end
end

return CameraUtilities
