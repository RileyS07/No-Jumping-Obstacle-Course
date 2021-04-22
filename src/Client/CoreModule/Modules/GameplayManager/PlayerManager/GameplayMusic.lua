-- Variables
local gameplayMusicManager = {}
gameplayMusicManager.MusicState = nil
gameplayMusicManager.Assets = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function gameplayMusicManager.Initialize()
    gameplayMusicManager.MusicState = coreModule.Enums.MusicState.None
    gameplayMusicManager.Assets.MusicContainer = coreModule.Shared.GetObject("//Assets.Sounds.Music")

end


-- Methods
-- This translates the user's userdata into a Sound object or a SoundGroup.
function gameplayMusicManager.UpdateMusic(userData)
    if not userData then return end
    if not gameplayMusicManager.Assets.MusicContainer then return end

    -- SpecialLocationIdentifier; Checking to see if we can apply any special music for these special locations.
    if userData.UserInformation.SpecialLocationIdentifier ~= coreModule.Shared.Enums.SpecialLocation.None then

        -- TherapyZone.
        if userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.TherapyZone then
            if gameplayMusicManager.Assets.MusicContainer:FindFirstChild("TherapyZone") and (gameplayMusicManager.Assets.MusicContainer.TherapyZone:IsA("Sound") or gameplayMusicManager.Assets.MusicContainer.TherapyZone:IsA("SoundGroup")) then
                gameplayMusicManager.UpdateMusicPostTranslation(gameplayMusicManager.Assets.MusicContainer.TherapyZone)
            else
                coreModule.Debug(
                    ("GameplayMusic: %s does not exist."):format("TherapyZone"),
                    coreModule.Shared.DebugLevel.Exception,
                    warn
                )
            end

        -- VictoryZone.
        elseif userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.VictoryZone then
            if gameplayMusicManager.Assets.MusicContainer:FindFirstChild("VictoryZone") and (gameplayMusicManager.Assets.MusicContainer.VictoryZone:IsA("Sound") or gameplayMusicManager.Assets.MusicContainer.VictoryZone:IsA("SoundGroup")) then
                gameplayMusicManager.UpdateMusicPostTranslation(gameplayMusicManager.Assets.MusicContainer.VictoryZone)
            else
                coreModule.Debug(
                    ("GameplayMusic: %s does not exist."):format("VictoryZone"),
                    coreModule.Shared.DebugLevel.Exception,
                    warn
                )
            end
        end
    end

    -- Next we're gonna see if they're in a BonusStage.
    if userData.UserInformation.CurrentBonusStage ~= "" then
        if gameplayMusicManager.Assets.MusicContainer:FindFirstChild(userData.UserInformation.CurrentBonusStage) and (gameplayMusicManager.Assets.MusicContainer[userData.UserInformation.CurrentBonusStage]:IsA("Sound") or gameplayMusicManager.Assets.MusicContainer[userData.UserInformation.CurrentBonusStage]:IsA("SoundGroup")) then
            gameplayMusicManager.UpdateMusicPostTranslation(gameplayMusicManager.Assets.MusicContainer[userData.UserInformation.CurrentBonusStage])
        else
            coreModule.Debug(
                ("GameplayMusic: %s does not exist."):format(userData.UserInformation.CurrentBonusStage),
                coreModule.Shared.DebugLevel.Exception,
                warn
            )
        end
    end

    -- Can we apply a special music for a Trial?
    if userData.UserInformation.CurrentCheckpoint > 0 and userData.UserInformation.CurrentCheckpoint%10 == 0 then
        if gameplayMusicManager.Assets.MusicContainer:FindFirstChild("Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial") and (gameplayMusicManager.Assets.MusicContainer["Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial"]:IsA("Sound") or gameplayMusicManager.Assets.MusicContainer["Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial"]:IsA("SoundGroup")) then
            gameplayMusicManager.UpdateMusicPostTranslation(gameplayMusicManager.Assets.MusicContainer["Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial"])
        else
            coreModule.Debug(
                ("GameplayMusic: %s does not exist."):format("Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial"),
                coreModule.Shared.DebugLevel.Exception,
                warn
            )
        end
    end
    --[[
function musicManager.GetMusicNameFromData()
	if not musicManager.UserData then return end
	
	--
	if musicManager.UserData.CurrentStats.IsInTherapy then return config.TherapyMusicName end
	if musicManager.UserData.CurrentStats.IsInVictory then return config.VictoryMusicName end
	if musicManager.UserData.CurrentStats.BonusLevelName ~= "" then return config.BonusLevelMusicNameFormat:format(musicManager.UserData.CurrentStats.BonusLevelName) end
	if musicManager.UserData.CurrentStats.CurrentUsingCheckpoint%10 == 0 then return config.TrialLevelMusicNameFormat:format(math.ceil(musicManager.UserData.CurrentStats.CurrentUsingCheckpoint/10)) end
	return config.NormalLevelMusicNameFormat:format(math.ceil(musicManager.UserData.CurrentStats.CurrentUsingCheckpoint/10))
end
    ]]
end


-- Private Methods
-- This takes in a Sound object or SoundGroup.
function gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)

end


--
return gameplayMusicManager

--[[

-- Variables
local musicManager = {}
musicManager.PrimaryMusicObject = script:WaitForChild("PrimaryMusic")
musicManager.SecondaryMusicObject = script:WaitForChild("SecondaryMusic")
musicManager.CurrentPlayingMusicsName = ""
musicManager.IsPlayingMusic = false
musicManager.IsFadingMusic = false
musicManager.CanPlayMusic = true
musicManager.UserData = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local musicFadingLibrary = require(coreModule.Shared.GetObject("Libraries.MusicFading"))
local config = require(script.Config)

-- Initialize
function musicManager.Initialize()
	musicManager.UserData = coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()
	
	--
	musicManager.UpdateMusic()
	coreModule.Shared.GetObject("//Remotes.StageInformationUpdated").OnClientEvent:Connect(function(userData)
		musicManager.UserData = userData
		musicManager.UpdateMusic()
	end)
end

-- Methods
function musicManager.UpdateMusic()
	if not musicManager.CanPlayMusic then return end
	if not musicManager.GetMusicNameFromData() then return end
	if musicManager.CurrentPlayingMusicsName == musicManager.GetMusicNameFromData() then return end
	
	--
	local newMusicName = musicManager.GetMusicNameFromData()
	if not coreModule.Shared.GetObject("//Assets.Sounds.Music"):FindFirstChild(newMusicName) then
		newMusicName = coreModule.Shared.GetObject("//Assets.Sounds.Music"):GetChildren()[Random.new():NextInteger(1, #coreModule.Shared.GetObject("//Assets.Sounds.Music"):GetChildren())].Name
	end
	
	--
	musicManager.CurrentPlayingMusicsName = newMusicName
	if coreModule.Shared.GetObject("//Assets.Sounds.Music."..musicManager.CurrentPlayingMusicsName):IsA("Sound") then
		if musicManager.IsPlayingMusic then
			if musicManager.IsFadingMusic then
				musicManager.SecondaryMusicObject.SoundId = coreModule.Shared.GetObject("//Assets.Sounds.Music."..musicManager.CurrentPlayingMusicsName).SoundId
				return
			end
			
			--
			musicManager.SecondaryMusicObject.SoundId = coreModule.Shared.GetObject("//Assets.Sounds.Music."..musicManager.CurrentPlayingMusicsName).SoundId
			musicManager.SecondaryMusicObject.TimePosition = 0
			musicManager.IsFadingMusic = true
			musicFadingLibrary.Fade(musicManager.PrimaryMusicObject, musicManager.SecondaryMusicObject, config.MusicFadeDuration)
			musicManager.PrimaryMusicObject.Name, musicManager.SecondaryMusicObject.Name = musicManager.SecondaryMusicObject.Name, musicManager.PrimaryMusicObject.Name
			musicManager.PrimaryMusicObject, musicManager.SecondaryMusicObject = musicManager.SecondaryMusicObject, musicManager.PrimaryMusicObject
			musicManager.SecondaryMusicObject.TimePosition = 0
			musicManager.IsFadingMusic = false
		else
			musicManager.PrimaryMusicObject.SoundId = coreModule.Shared.GetObject("//Assets.Sounds.Music."..musicManager.CurrentPlayingMusicsName).SoundId
			musicManager.IsPlayingMusic = true
		end
	else
		coroutine.wrap(function()
			while musicManager.CurrentPlayingMusicsName == newMusicName do
				for index = 1, #coreModule.Shared.GetObject("//Assets.Sounds.Music."..musicManager.CurrentPlayingMusicsName):GetChildren() do
					if musicManager.CurrentPlayingMusicsName ~= newMusicName then return end
					
					--
					if musicManager.IsPlayingMusic then
						if musicManager.IsFadingMusic then
							musicManager.SecondaryMusicObject.SoundId = coreModule.Shared.GetObject("//Assets.Sounds.Music."..musicManager.CurrentPlayingMusicsName):GetChildren()[index].SoundId
							return
						end

						--
						musicManager.SecondaryMusicObject.SoundId = coreModule.Shared.GetObject("//Assets.Sounds.Music."..musicManager.CurrentPlayingMusicsName):GetChildren()[index].SoundId
						musicManager.SecondaryMusicObject.TimePosition = 0
						musicManager.IsFadingMusic = true
						musicFadingLibrary.Fade(musicManager.PrimaryMusicObject, musicManager.SecondaryMusicObject, config.MusicFadeDuration)
						musicManager.PrimaryMusicObject.Name, musicManager.SecondaryMusicObject.Name = musicManager.SecondaryMusicObject.Name, musicManager.PrimaryMusicObject.Name
						musicManager.PrimaryMusicObject, musicManager.SecondaryMusicObject = musicManager.SecondaryMusicObject, musicManager.PrimaryMusicObject
						musicManager.SecondaryMusicObject.TimePosition = 0
						musicManager.IsFadingMusic = false
					else
						musicManager.PrimaryMusicObject.SoundId = coreModule.Shared.GetObject("//Assets.Sounds.Music."..musicManager.CurrentPlayingMusicsName):GetChildren()[index].SoundId
						musicManager.IsPlayingMusic = true
					end
					
					--
					musicManager.PrimaryMusicObject.DidLoop:Wait()
				end
			end
		end)()
	end
end

function musicManager.GetMusicNameFromData()
	if not musicManager.UserData then return end
	
	--
	if musicManager.UserData.CurrentStats.IsInTherapy then return config.TherapyMusicName end
	if musicManager.UserData.CurrentStats.IsInVictory then return config.VictoryMusicName end
	if musicManager.UserData.CurrentStats.BonusLevelName ~= "" then return config.BonusLevelMusicNameFormat:format(musicManager.UserData.CurrentStats.BonusLevelName) end
	if musicManager.UserData.CurrentStats.CurrentUsingCheckpoint%10 == 0 then return config.TrialLevelMusicNameFormat:format(math.ceil(musicManager.UserData.CurrentStats.CurrentUsingCheckpoint/10)) end
	return config.NormalLevelMusicNameFormat:format(math.ceil(musicManager.UserData.CurrentStats.CurrentUsingCheckpoint/10))
end

function musicManager.Update(settingValue)
	if not musicManager.PrimaryMusicObject or not musicManager.SecondaryMusicObject then return end
	musicManager.CanPlayMusic = settingValue
	
	--
	if settingValue then
		musicManager.PrimaryMusicObject.Playing = true
		musicManager.SecondaryMusicObject.Playing = true
		coroutine.wrap(musicManager.UpdateMusic)()
	else
		musicManager.PrimaryMusicObject.Playing = false
		musicManager.SecondaryMusicObject.Playing = false
	end
end

--
return musicManager
]]