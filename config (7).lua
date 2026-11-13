Config = {}

Config.Tick = 30                    -- seconds between server need ticks
Config.Decay = {                    -- points lost per tick (0-100 scale)
    hunger = 0.45,                  -- ~110 min from full to empty
    thirst = 0.65,                  -- ~77 min
}
Config.SprintExtra = 1.6            -- decay multiplier if the player was sprinting/swimming for most of the tick
Config.StartValue = 80
Config.RespawnValue = 60

Config.Starving = {                 -- at 0, the client drains health
    hungerDrain = 2,                -- hp per 8s
    thirstDrain = 3,
    warnAt = 20,                    -- warning notification threshold
}

-- Effects of using an item (handled in the 'usedItem' event)
-- hunger/thirst are added (0-100), heal is hp (0-200 scale on the player ped), bleed clears bleeding visuals.
Config.Consumables = {
    canned_beans    = { hunger = 28 },
    canned_soup     = { hunger = 22, thirst = 8 },
    canned_peaches  = { hunger = 18, thirst = 12 },
    chips           = { hunger = 12 },
    energy_bar      = { hunger = 16, thirst = -2 },
    mre             = { hunger = 55, thirst = 5, heal = 10 },
    bottled_water   = { thirst = 38 },
    soda            = { thirst = 20, hunger = 4 },

    field_bandage   = { heal = 25, bleed = true, hot = 6 },        -- hot = heal over seconds
    medkit          = { heal = 90, bleed = true, hot = 10 },
    painkillers     = { heal = 35, hot = 20 },
}

Config.Death = {
    respawnSeconds = 30,            -- lie there at least this long
    dropInventory  = true,          -- hardcore: everything you carry drops in a body bag
    keepItems      = {},            -- e.g. { 'phone' }
    bagLabel       = 'Dead Survivor',
}

-- Where the dead come back. Defaults match zombie-ai safe zones; edit to taste.
Config.Respawns = {
    { name = 'Grapeseed Farm Camp',  coords = vec4(2447.9, 4977.5, 46.8, 90.0) },
    { name = 'Sandy Shores Camp',    coords = vec4(1392.9, 3604.7, 35.0, 200.0) },
    { name = 'Paleto Survivor Camp', coords = vec4(-552.0, 5330.0, 70.0, 150.0) },
}

Config.HUD = {
    enabled = true,
    x = 0.015, y = 0.93,            -- bottom-left, just above the radar
}
