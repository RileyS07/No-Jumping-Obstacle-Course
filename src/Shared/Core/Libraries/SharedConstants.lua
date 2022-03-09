return {
    EVENTS = {
        TROPHIES = {
            BOBBING_DISTANCE = 1,   -- How far the trophy bobs from the center.
            BOBBING_SPEED = 1,      -- How many seconds it takes to do one full bob.
            FADE_SPEED = 2,         -- How many seconds it takes for the trophy to fade away.
            ROTATION_SPEED = 3,     -- How many seconds it takes for a full rotation to be completed.
        }
    },

    FORMATS = {
        BONUS_STAGE_TELEPORTER_CONSENT_FORMAT = "Are you sure you want to teleport to <font color=\"#5352ed\"><b>%s</b></font> bonus level?",
        EXPERIENCE_COMPLETION_MESSAGE_FORMAT = "%s has just beat No Jumping Zone!",
        LOCATION_TELEPORTER_CONSENT_FORMAT = "Are you sure you want to teleport to <font color=\"#5352ed\"><b>%s</b></font>?",
        SYSTEM_MESSAGE_FORMAT = "[System]: %s",
        TRIAL_COMPLETION_MESSAGE_FORMAT = "%s has just finished %s!",
    },

    GENERAL = {
        DEFAULT_FIELD_OF_VIEW =  70,            -- The default field of view applied to the camera.
        DELAY_BETWEEN_PLAYER_RESETS = 2,        -- The amount of time between needed before a player can reset again.
        RESPAWN_COUNT_NEEDED_TO_SHOW_POPUP = 5, -- The amount of failed attempts on a stage needed in order to show the skip stage gui.
    },

    INTERFACE = {
        CONFETTI_DEFAULT_PARTICLE_AMOUNT = 50,  -- The default amount of confetti particle amount.
        CONFETTI_DEFAULT_MAX_CYCLE_COUNT = 5,   -- The default amount of confetti cycles that will play.
        SYSTEM_MESSAGE_DEFAULT_COLOR = Color3.fromHex("#09979f"), -- The default color that a system message will be.
        FORCED_SHIFTLOCK_CONTROLLER_KEYCODE = Enum.KeyCode.ButtonR2   -- The default keycode that controllers will use to update shiftlock.
    },

    MECHANICS = {
        ANY_PLATFORM_DEFAULT_DURATION = 1,          -- The default amount of time a platform will take to finish its effect.
        ANY_POWERUP_DEFAULT_DURATION = 30,          -- The default amount of time a powerup will be applied for.
        ANY_POWERUP_HIT_BOX_SIZE_MULTIPLIER = 2,    -- The amount that the hitboxes size is multiplied.
        ANY_POWERUP_REAPPLICATION_DELAY = 1,        -- How many seconds the system will make the user wait to be able to reapply a powerup.
        DAMAGE_PLATFORM_DEFAULT_DAMAGE = 10,        -- The default amount of damage the platform will deal.
        GRAVITY_POWERUP_DEFAULT_FORCE = 1,          -- The default multiplier of force the power up will use.
        JUMP_PLATFORM_DEFAULT_JUMP_HEIGHT = 20,     -- The default amount of studs that the platform will let them jump.
        JUMP_POWERUP_DEFAULT_JUMP_HEIGHT = 7.5,     -- The default jump height that will be applied if there is no `JumpHeight` attribute.
        HEALING_PLATFORM_DEFAULT_HEAL_AMOUNT = 100, -- The default amount of health the platform will give.
        PAINT_POWERUP_DEFAULT_COLOR = Color3.new(),             -- The default color the player will assume if there is no `Color` attribute.
        SPEED_POWERUP_DEFAULT_MULTIPLIER = 2,                     -- The default multiplier that will be used if there is no `Multiplier` attribute.
    },

    TELEPORTERS = {
        ANY_TELEPORTER_DEFAULT_OVERLAY_COLOR = Color3.new(1, 1, 1), -- The default color that the overlay frame will be.
        ANY_TELEPORTER_DEFAULT_AUTHOR = "???",  -- The default author that is shown when there is no 'Author' attribute.
        ANY_TELEPORTER_DEFAULT_DIFFICULTY = 1,  -- The default difficulty the teleporter will show.
        ANY_TELEPORTER_MAXIMUM_DIFFICULTY = 5,  -- The maxmimum difficulty rating supported.
    }
}
