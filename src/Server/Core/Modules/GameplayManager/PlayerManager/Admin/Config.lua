-- Usually I would try to use attributes but there would just be so many
return {
	Keybinds = {
		CommandPrefix = "!",
		CommandBatchKey = "|",
		CommandSplitKey = " ",
		CommandConsoleKey = Enum.KeyCode.Quote,
		PublicCommandPrefix = "!",
	},
	
	-- Creator > Owner > Moderator > ...
	RankInformation = {
		Creator = {
			RankIndex = 1,
			Permissions = math.huge,
			Users = {"Group:4246980:253"}
		},
		
		Owner = {
			RankIndex = 2,
			Permissions = math.huge,
			Users = {"UserId:2301928"}
		},
		
		Moderator = {
			RankIndex = 3,
			Permissions = math.huge,
			Users = {"Group:4246980:251"}
		},
		
		Helper = {
			RankIndex = 4,
			Permissions = {
				Miscellaneous = true,
			},
			Users = {"Group:4246980:3", "Group:4246980:2"}
		},
	},
	
	-- Saving stuff like ranks etc
	DataStoreInformation = {
		DataStoreName = "Admin Data",
		DataStoreScope = "Version1",
		DataStoreKey = "Riley"
	}
}