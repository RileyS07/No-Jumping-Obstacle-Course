return {
    EVENTS = {
        TROPHIES = {
            BOBBING_DISTANCE = 1,   -- How far the trophy bobs from the center.
            BOBBING_SPEED = 1,      -- How many seconds it takes to do one full bob.
            FADE_SPEED = 2,         -- How many seconds it takes for the trophy to fade away.
            ROTATION_SPEED = 3,     -- How many seconds it takes for a full rotation to be completed.
        }
    },

    MECHANICS = {
        ANY_PLATFORM_DEFAULT_DURATION = 1,          -- The default amount of time a platform will take to finish it's effect.
        ANY_POWERUP_DEFAULT_DURATION = 30,          -- The default amount of time a powerup will be applied for.
        ANY_POWERUP_HIT_BOX_SIZE_MULTIPLIER = 2,    -- The amount that the hitboxes size is multiplied.
        ANY_POWERUP_REAPPLICATION_DELAY = 1,        -- How many seconds the system will make the user wait to be able to reapply a powerup.
        DAMAGE_PLATFORM_DEFAULT_DAMAGE = 10,        -- The default amount of damage the platform will deal.
        JUMP_PLATFORM_DEFAULT_JUMP_HEIGHT = 20,     -- The default amount of studs that the platform will let them jump.
        HEALING_PLATFORM_DEFAULT_HEAL_AMOUNT = 100, -- The default amount of health the platform will give.
    }
}
