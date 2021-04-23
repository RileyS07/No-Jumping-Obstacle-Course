-- Variables
local gameplayMusicManager = {}
gameplayMusicManager.PrimarySoundObject = nil
gameplayMusicManager.SecondarySoundObject = nil
gameplayMusicManager.MusicState = nil
gameplayMusicManager.Assets = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function gameplayMusicManager.Initialize()
    gameplayMusicManager.MusicState = coreModule.Enums.MusicState.None
    gameplayMusicManager.Assets.MusicContainer = coreModule.Shared.GetObject("//Assets.Sounds.Music")

	gameplayMusicManager.PrimarySoundObject = Instance.new("Sound")
	gameplayMusicManager.SecondarySoundObject = Instance.new("Sound")
	gameplayMusicManager.PrimarySoundObject.Parent, gameplayMusicManager.SecondarySoundObject.Parent = script, script

	-- UpdateMusic bindings.
	gameplayMusicManager.UpdateMusic(coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer())
	coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.CheckpointInformationUpdated").OnClientEvent:Connect(function(userData)
		gameplayMusicManager.UpdateMusic(userData)
	end)
end


-- Methods
-- This translates the user's userdata into a Sound object or a SoundGroup.
function gameplayMusicManager.UpdateMusic(userData)
    if not userData then return end
    if not gameplayMusicManager.Assets.MusicContainer then return end
	if #gameplayMusicManager.Assets.MusicContainer:GetChildren() == 0 then return end
	
    -- SpecialLocationIdentifier; Checking to see if we can apply any special music for these special locations.
    if userData.UserInformation.SpecialLocationIdentifier ~= coreModule.Shared.Enums.SpecialLocation.None then

        -- TherapyZone.
        if userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.TherapyZone then

			local soundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild("TherapyZone")
            if soundContainerand (soundContainer:IsA("Sound") or soundContainer:IsA("SoundGroup")) then
                return gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
            else
                coreModule.Debug(
                    ("GameplayMusic: %s does not exist."):format("TherapyZone"),
                    coreModule.Shared.Enums.DebugLevel.Exception,
                    warn
                )
            end

        -- VictoryZone.
        elseif userData.UserInformation.SpecialLocationIdentifier == coreModule.Shared.Enums.SpecialLocation.VictoryZone then

			local soundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild("VictoryZone")
            if soundContainer and (soundContainer:IsA("Sound") or soundContainer:IsA("SoundGroup")) then
                return gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
            else
                coreModule.Debug(
                    ("GameplayMusic: %s does not exist."):format("VictoryZone"),
                    coreModule.Shared.Enums.DebugLevel.Exception,
                    warn
                )
            end
        end
    end

    -- Next we're gonna see if they're in a BonusStage.
    if userData.UserInformation.CurrentBonusStage ~= "" then

		local soundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild(userData.UserInformation.CurrentBonusStage)
        if soundContainer and (soundContainer:IsA("Sound") or soundContainer:IsA("SoundGroup")) then
            return gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
        else
            coreModule.Debug(
                ("GameplayMusic: %s does not exist."):format(userData.UserInformation.CurrentBonusStage),
                coreModule.Shared.Enums.DebugLevel.Exception,
                warn
            )
        end
    end

    -- Can we apply a special music for a Trial?
    if userData.UserInformation.CurrentCheckpoint > 0 and userData.UserInformation.CurrentCheckpoint%10 == 0 then

		local soundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild("Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial")
        if soundContainer and (soundContainer:IsA("Sound") or soundContainer:IsA("SoundGroup")) then
            return gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
        else
            coreModule.Debug(
                ("GameplayMusic: %s does not exist."):format("Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial"),
                coreModule.Shared.Enums.DebugLevel.Exception,
                warn
            )
        end
    end

	-- Is there any for this specific stage?
	local stageSpecificSoundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild("Stage "..tostring(userData.UserInformation.CurrentCheckpoint))
	if stageSpecificSoundContainer and (stageSpecificSoundContainer:IsA("Sound") or stageSpecificSoundContainer:IsA("SoundGroup")) then
		return gameplayMusicManager.UpdateMusicPostTranslation(stageSpecificSoundContainer)
	else
		coreModule.Debug(
			("GameplayMusic: %s does not exist."):format("Stage "..tostring(userData.UserInformation.CurrentCheckpoint)),
			coreModule.Shared.Enums.DebugLevel.Exception,
			warn
		)
	end

	-- Is there any for this zone?
	local zoneSpecificSoundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild("Zone "..tostring(math.ceil(userData.UserInformation.CurrentCheckpoint/10)))
	if zoneSpecificSoundContainer and (zoneSpecificSoundContainer:IsA("Sound") or zoneSpecificSoundContainer:IsA("SoundGroup")) then
		return gameplayMusicManager.UpdateMusicPostTranslation(zoneSpecificSoundContainer)
	else
		coreModule.Debug(
			("GameplayMusic: %s does not exist."):format("Stage "..tostring(userData.UserInformation.CurrentCheckpoint)),
			coreModule.Shared.Enums.DebugLevel.Standard,
			warn
		)
	end

	-- Desperation to have at least a sound playing.
	local musicContainerChildren = gameplayMusicManager.Assets.MusicContainer:GetChildren()
	for reverseIndex = #musicContainerChildren, 1, -1 do
		local soundContainer = musicContainerChildren[reverseIndex]

		if soundContainer and (soundContainer:IsA("Sound") or soundContainer:IsA("SoundGroup")) then
            return gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
		end
	end
end


-- Private Methods
-- This takes in a Sound object or SoundGroup.
function gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
	if typeof(soundContainer) ~= "Instance" then return end
	if not soundContainer:IsA("Sound") and not soundContainer:IsA("SoundGroup") then return end
	if gameplayMusicManager.PrimarySoundObject.Name == soundContainer then return end
	gameplayMusicManager.PrimarySoundObject.Name = soundContainer
	
	-- Sounds vs SoundGroups act differently.
	if soundContainer:IsA("Sound") then

	else

	end
	--musicManager.CurrentPlayingMusicsName = newMusicName
	--[[
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
	print(soundContainer.Name)]]
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