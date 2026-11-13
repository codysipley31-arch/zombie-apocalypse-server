Config = {}

-- Roaming hordes: every so often a horde forms around one random survivor and shambles toward them.
Config.Roaming = {
    enabled     = true,
    minMinutes  = 14,       -- real minutes between horde events (server wide)
    maxMinutes  = 28,
    nightMult   = 0.5,      -- at full night the wait is multiplied by this (more hordes)
    size        = { min = 10, max = 20 },
    nightExtra  = 12,       -- extra zombies at full night
    spawnDist   = { min = 70.0, max = 110.0 },
    warning     = true,     -- tell the target a horde is coming
    minPlayers  = 1,
}

-- Static nests: big clusters at dangerous places. Spawn when a player gets close,
-- then go on cooldown (server wide) so they come back later.
Config.Nests = {
    { name = 'Fort Zancudo Gate',  coords = vec3(-1599.0, 2807.0, 17.0), radius = 55.0, size = 28, cooldown = 25 },
    { name = 'Humane Labs',        coords = vec3(3619.0, 3739.0, 28.7),  radius = 50.0, size = 24, cooldown = 25 },
    { name = 'Sandy Shores Strip', coords = vec3(1858.0, 3678.0, 33.8),  radius = 45.0, size = 14, cooldown = 15 },
    { name = 'Mirror Park',        coords = vec3(1065.0, -702.0, 57.8),  radius = 55.0, size = 18, cooldown = 15 },
    { name = 'Davis Quartz',       coords = vec3(2958.0, 2753.0, 43.0),  radius = 60.0, size = 16, cooldown = 15 },
    { name = 'Paleto Mill',        coords = vec3(-550.0, 5320.0, 74.0),  radius = 45.0, size = 14, cooldown = 15 },
}
-- cooldown is in real minutes. Edit coords to taste with /zcoords.

Config.NestTriggerDistance = 140.0
Config.PedPoolSoftLimit = 200
