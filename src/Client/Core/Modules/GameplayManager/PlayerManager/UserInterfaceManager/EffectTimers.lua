-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}
specificInterfaceManager.TimerInformation = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local numberUtilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.NumberUtilities"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.Container = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Timers")

    -- The timer information was updated.
    coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.TimerInformationUpdated").OnClientEvent:Connect(function(effectInformationArray)

        -- Attempt to merge/update/delete the effect information.
        if typeof(effectInformationArray) == "table" and next(effectInformationArray) ~= nil then
            for effectName, effectInformation in next, effectInformationArray do
                if typeof(effectName) == "string" and typeof(effectInformation) == "table" then
                    specificInterfaceManager.TimerInformation[effectName] = {
                        Start = os.clock(),
                        Duration = effectInformation.Duration or math.huge,
                        IsFresh = not not effectInformation.IsFresh,
                        Color = effectInformation.Color
                    }
                end
            end
        else
            specificInterfaceManager.TimerInformation = {}
        end
    end)

    -- Update loop.
    coroutine.wrap(function()
        while true do
            game:GetService("RunService").RenderStepped:Wait()

            -- Remove old effects.
            for _, effectInformationDisplay in next, specificInterfaceManager.Interface.Container:GetChildren() do
                if effectInformationDisplay:IsA("GuiObject") and not specificInterfaceManager.TimerInformation[effectInformationDisplay.Name] then
                    clientAnimationsLibrary.PlayAnimation("HideEffectInformationDisplay", effectInformationDisplay)
                end
            end

            -- if next(array) == nil then the array is without a doubt empty.
            if next(specificInterfaceManager.TimerInformation) == nil then
                clientAnimationsLibrary.PlayAnimation("HideEffectInformation")
            else
                clientAnimationsLibrary.PlayAnimation("ShowEffectInformation")
            end

            -- Now we can finally update them.
            for effectName, effectInformation in next, specificInterfaceManager.TimerInformation do
                local effectInformationDisplay = specificInterfaceManager.Interface.Container:FindFirstChild(effectName) or coreModule.Shared.GetObject("//Assets.Interfaces.EffectInformationDisplay"):Clone()
                effectInformationDisplay.Name = effectName
                effectInformationDisplay.Content.EffectName.Text = effectName

                -- Update the timer.
                if effectInformation.Duration - (os.clock() - effectInformation.Start) < 1e10 then
                    effectInformationDisplay.Content.Timer.Text = numberUtilitiesLibrary.GetEnforcedPrecisionString(
                        math.max(0, math.floor((effectInformation.Duration - (os.clock() - effectInformation.Start))*10)/10), 1
                    )
                else
                    effectInformationDisplay.Content.Timer.Text = "Infinity"
                end

                -- Update the icon.
                if coreModule.Shared.GetObject("//Assets.Interfaces.EffectIcons"):FindFirstChild(effectName) then
                    effectInformationDisplay.Icon.Image = coreModule.Shared.GetObject("//Assets.Interfaces.EffectIcons."..effectName).Image
                end

                effectInformationDisplay.Parent = specificInterfaceManager.Interface.Container

                -- Remove old effects part 2?
                if os.clock() - effectInformation.Start >= effectInformation.Duration then
                    clientAnimationsLibrary.PlayAnimation("HideEffectInformationDisplay", effectInformationDisplay)
                    specificInterfaceManager.TimerInformation[effectName] = nil
                end
            end
        end
    end)()
end


--
return specificInterfaceManager

--[[

-- Variables
local powerupsInterface = {}
powerupsInterface.Interface = {}
powerupsInterface.PowerupInformation = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local specificInterfaceManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function powerupsInterface.Initialize()
	powerupsInterface.Interface.Container = specificInterfaceManager.GetInterface():WaitForChild("Powerups")
	
	--
	coreModule.Shared.GetObject("//Remotes.PowerupInformationUpdated").OnClientEvent:Connect(function(powerupInformationDictionary, powerupName)
		if powerupName and powerupInformationDictionary[powerupName] then 
			powerupInformationDictionary[powerupName].StartTime = os.clock() 
		end
		
		for nestedPowerupName, powerupInformation in next, powerupInformationDictionary do
			if nestedPowerupName ~= powerupName and powerupsInterface.PowerupInformation[nestedPowerupName] then
				powerupInformation.StartTime = powerupsInterface.PowerupInformation[nestedPowerupName].StartTime
			end
		end
		
		powerupsInterface.PowerupInformation = powerupInformationDictionary
	end)
	
	-- Updates the times and visibility
	coroutine.wrap(function()
		while true do
			for _, powerupDisplayContainer in next, powerupsInterface.Interface.Container:GetChildren() do
				if powerupDisplayContainer:IsA("GuiObject") then
					powerupDisplayContainer.Visible = powerupsInterface.PowerupInformation[powerupDisplayContainer.Name] ~= nil
					
					-- Update the text
					if powerupsInterface.PowerupInformation[powerupDisplayContainer.Name] then
						powerupDisplayContainer.Container.Description.Text = ("%g"):format(math.max(0, math.floor((powerupsInterface.PowerupInformation[powerupDisplayContainer.Name].Duration - (os.clock() - powerupsInterface.PowerupInformation[powerupDisplayContainer.Name].StartTime))*10)/10))
						if tonumber(powerupDisplayContainer.Container.Description.Text)%1 == 0 then powerupDisplayContainer.Container.Description.Text = powerupDisplayContainer.Container.Description.Text..".0" end
						if powerupsInterface.PowerupInformation[powerupDisplayContainer.Name].Config and powerupsInterface.PowerupInformation[powerupDisplayContainer.Name].Config.Color then powerupDisplayContainer.Container.Description.TextColor3 = powerupsInterface.PowerupInformation[powerupDisplayContainer.Name].Config.Color end
						
						--
						if os.clock() - powerupsInterface.PowerupInformation[powerupDisplayContainer.Name].StartTime >= powerupsInterface.PowerupInformation[powerupDisplayContainer.Name].Duration then
							powerupsInterface.PowerupInformation[powerupDisplayContainer.Name] = nil
						end
					end
				end
			end
			
			--
			game:GetService("RunService").RenderStepped:Wait()
		end
	end)()
end

--
return powerupsInterface
]]