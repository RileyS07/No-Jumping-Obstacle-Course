-- Variables
local gameplayMusicManager = {}
gameplayMusicManager.VolumeModifier = 1
gameplayMusicManager.PrimarySoundObject = nil
gameplayMusicManager.SecondarySoundObject = nil
gameplayMusicManager.MusicState = nil
gameplayMusicManager.Assets = {}

gameplayMusicManager.Enums = {
	MusicState = {
		None = 1, Fading = 2, Playing = 3
	}
}
local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))

-- Initialize
function gameplayMusicManager.Initialize()
    gameplayMusicManager.MusicState = gameplayMusicManager.Enums.MusicState.None
    gameplayMusicManager.Assets.MusicContainer = coreModule.Shared.GetObject("//Assets.Sounds.Music")

	gameplayMusicManager.PrimarySoundObject = Instance.new("Sound")
	gameplayMusicManager.SecondarySoundObject = Instance.new("Sound")
	gameplayMusicManager.PrimarySoundObject.Looped, gameplayMusicManager.SecondarySoundObject.Looped = true, true
	gameplayMusicManager.PrimarySoundObject.Playing, gameplayMusicManager.SecondarySoundObject.Playing = true, true
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
    if not gameplayMusicManager.Assets.MusicContainer then return end
	if #gameplayMusicManager.Assets.MusicContainer:GetChildren() == 0 then return end

	-- FIRST we check if there is a priority interface and also if there's music for it.
	if userInterfaceManager.GetPriorityInterface() then
		local soundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild(userInterfaceManager.GetPriorityInterface().Name)
		if soundContainer and (soundContainer:IsA("Sound") or soundContainer:IsA("SoundGroup")) then
			return gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
		end
	end

	-- Past this point we only rely on data.
	if not userData then return end

    -- Second we're gonna see if they're in a BonusStage.
    if userData.UserInformation.CurrentBonusStage ~= "" then

		local soundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild(userData.UserInformation.CurrentBonusStage)
        if soundContainer and (soundContainer:IsA("Sound") or soundContainer:IsA("SoundGroup")) then
            return gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
        end
    end

    -- Can we apply a special music for a Trial?
    if userData.UserInformation.CurrentCheckpoint > 0 and userData.UserInformation.CurrentCheckpoint%10 == 0 then

		local soundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild("Zone "..tostring(userData.UserInformation.CurrentCheckpoint/10).." Trial")
        if soundContainer and (soundContainer:IsA("Sound") or soundContainer:IsA("SoundGroup")) then
            return gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
        end
    end

	-- Is there any for this specific stage?
	local stageSpecificSoundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild("Stage "..tostring(userData.UserInformation.CurrentCheckpoint))
	if stageSpecificSoundContainer and (stageSpecificSoundContainer:IsA("Sound") or stageSpecificSoundContainer:IsA("SoundGroup")) then
		return gameplayMusicManager.UpdateMusicPostTranslation(stageSpecificSoundContainer)
	end

	-- Is there any for this zone?
	local zoneSpecificSoundContainer = gameplayMusicManager.Assets.MusicContainer:FindFirstChild("Zone "..tostring(math.ceil(userData.UserInformation.CurrentCheckpoint/10)))
	if zoneSpecificSoundContainer and (zoneSpecificSoundContainer:IsA("Sound") or zoneSpecificSoundContainer:IsA("SoundGroup")) then
		return gameplayMusicManager.UpdateMusicPostTranslation(zoneSpecificSoundContainer)
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


function gameplayMusicManager.UpdateSetting(newValue)
	if typeof(newValue) ~= "number" then return end

	gameplayMusicManager.VolumeModifier = newValue
	gameplayMusicManager.PrimarySoundObject.Volume = 0.25 * gameplayMusicManager.VolumeModifier
end


-- Private Methods
-- This takes in a Sound object or SoundGroup.
function gameplayMusicManager.UpdateMusicPostTranslation(soundContainer)
	if typeof(soundContainer) ~= "Instance" then return end
	if not soundContainer:IsA("Sound") and not soundContainer:IsA("SoundGroup") then return end
	if gameplayMusicManager.PrimarySoundObject.Name == soundContainer.Name then return end
	gameplayMusicManager.PrimarySoundObject.Name = soundContainer.Name

	-- Sounds vs SoundGroups act differently.
	if soundContainer:IsA("Sound") then
		if gameplayMusicManager.MusicState ~= gameplayMusicManager.Enums.MusicState.None then

			-- If it's in the process of fading between songs we just update and let it do it's thing.
			if gameplayMusicManager.MusicState == gameplayMusicManager.Enums.MusicState.Fading then
				gameplayMusicManager.SecondarySoundObject.SoundId = soundContainer.SoundId
				return
			end

			-- So this means we need to switch sources so we can fade properly.
			gameplayMusicManager.MusicState = gameplayMusicManager.Enums.MusicState.Fading
			gameplayMusicManager.SwitchSoundObjects(soundContainer)
			gameplayMusicManager.MusicState = gameplayMusicManager.Enums.MusicState.Playing
		else
			gameplayMusicManager.MusicState = gameplayMusicManager.Enums.MusicState.Playing
			gameplayMusicManager.PrimarySoundObject.SoundId = soundContainer.SoundId
		end

	-- We play SoundGroups like a sound track.
	elseif #soundContainer:GetChildren() > 0 then

		coroutine.wrap(function()
			while gameplayMusicManager.PrimarySoundObject.Name == soundContainer.Name do
				for _, soundObject in next, soundContainer:GetChildren() do
					if gameplayMusicManager.PrimarySoundObject.Name ~= soundContainer.Name then return end

					-- From here it's literally copy and paste...
					if gameplayMusicManager.MusicState ~= gameplayMusicManager.Enums.MusicState.None then

						-- If it's in the process of fading between songs we just update and let it do it's thing.
						if gameplayMusicManager.MusicState == gameplayMusicManager.Enums.MusicState.Fading then
							gameplayMusicManager.SecondarySoundObject.SoundId = soundObject.SoundId
							return
						end
			
						-- So this means we need to switch sources so we can fade properly.
						gameplayMusicManager.MusicState = gameplayMusicManager.Enums.MusicState.Fading
						gameplayMusicManager.SwitchSoundObjects(soundObject)
						gameplayMusicManager.MusicState = gameplayMusicManager.Enums.MusicState.Playing
					else
						gameplayMusicManager.MusicState = gameplayMusicManager.Enums.MusicState.Playing
						gameplayMusicManager.PrimarySoundObject.SoundId = soundObject.SoundId
					end

					gameplayMusicManager.PrimarySoundObject.DidLoop:Wait()
				end
			end
		end)()
	end
end


-- This methods allows for clean fading of music using FadeBetweenSounds; THIS METHOD DOES NOT HANDLE STATE CHANGES.
function gameplayMusicManager.SwitchSoundObjects(soundObject)
	gameplayMusicManager.SecondarySoundObject.SoundId = soundObject.SoundId
	gameplayMusicManager.SecondarySoundObject.TimePosition = 0

	gameplayMusicManager.FadeBetweenSounds()

	-- Switch time.
	gameplayMusicManager.PrimarySoundObject.Name, gameplayMusicManager.SecondarySoundObject.Name = gameplayMusicManager.SecondarySoundObject.Name, gameplayMusicManager.PrimarySoundObject.Name
	gameplayMusicManager.PrimarySoundObject, gameplayMusicManager.SecondarySoundObject = gameplayMusicManager.SecondarySoundObject, gameplayMusicManager.PrimarySoundObject

	-- Finish.
	gameplayMusicManager.SecondarySoundObject.TimePosition = 0
end


function gameplayMusicManager.FadeBetweenSounds()
	local currentSoundObjectFadeTween = game:GetService("TweenService"):Create(
		gameplayMusicManager.PrimarySoundObject,
		TweenInfo.new(1, Enum.EasingStyle.Linear),
		{Volume = 0}
	)

	currentSoundObjectFadeTween:Play()
	currentSoundObjectFadeTween.Completed:Wait()

	local nextSoundObjectFadeTween = game:GetService("TweenService"):Create(
		gameplayMusicManager.SecondarySoundObject,
		TweenInfo.new(1, Enum.EasingStyle.Linear),
		{Volume = 0.25 * gameplayMusicManager.VolumeModifier}
	)

	nextSoundObjectFadeTween:Play()
	nextSoundObjectFadeTween.Completed:Wait()
end


--
return gameplayMusicManager