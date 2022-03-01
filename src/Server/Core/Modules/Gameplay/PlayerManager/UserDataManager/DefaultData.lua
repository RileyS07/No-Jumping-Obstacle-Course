return {
	-- This is data that is essential for the core gameplay to function properly
	UserInformation = {
		-- Used to keep track of completion for whatever purposes we need
		CompletedStages = {},
		CompletedBonusStages = {},

		-- Checkpoints and checkpoint related data
		FarthestCheckpoint = 1,	-- This is the farthest you've gone in the game
		CurrentCheckpoint = 1,	-- This is where the player is currently and will respawn at
		CurrentBonusStage = "",	-- The name of the bonus stage they're on currently; "" = none
		CurrentBonusStageCheckpoint = 1,	-- Bonus stages can have checkpoints too!
	},

	-- Settings that determine how the game appears/acts for their client
	Settings = {
		MusicVolumeModifier = 1,
		SoundEffectsVolumeModifier = 1,
		RenderCharactersPhaseIndex = 0,
		ShowChatHints = true
	},

	-- This is an empty array for all events to store information in as needed; with some guidelines
	UserEventInformation = {
		--[[
		{
			Completed = true/false,
			Progress = 0-1,
			Name = "Event Name",
			Description = "Description..."
		}
		]]
	}
}
