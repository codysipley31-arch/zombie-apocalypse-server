Config = {}

Config.Debug = false

-- Ped models used for zombies (all stock GTA V models)
Config.Models = {
    'u_m_y_zombie_01', 'u_m_y_zombie_01', 'u_m_y_zombie_01',
    'a_m_m_hillbilly_01', 'a_m_m_hillbilly_02', 'a_m_m_tramp_01',
    'a_m_o_tramp_01', 'a_m_m_trampbeac_01', 'a_f_m_trampbeac_01',
    'a_m_m_skidrow_01', 'a_f_m_skidrow_01', 'a_m_m_farmer_01',
    'a_m_m_salton_01', 'a_m_y_hippy_01', 'a_f_y_hippie_01',
}

-- Drunk walk clipsets give the shambling look. Runners (night only) skip these.
Config.WalkStyles = {
    'move_m@drunk@verydrunk',
    'move_m@drunk@moderatedrunk',
    'move_m@drunk@slightlydrunk',
}

Config.ZombieHealth = 200       -- body shots wear them down, headshots kill instantly
Config.HeadshotInstantKill = true

Config.Spawn = {
    maxPerPlayer = 22,          -- daytime cap near each player
    groupScale   = 0.3,         -- +30% cap per extra player nearby (max 3 players counted)
    minDist      = 45.0,        -- never spawn closer than this
    maxDist      = 110.0,
    despawnDist  = 170.0,       -- zombies farther than this from every player are removed
    interval     = 2500,        -- ms between spawn cycles
    perCycle     = 3,           -- max zombies spawned per cycle
    corpseMs     = 45000,       -- how long bodies stay before cleanup
    pedPoolLimit = 170,         -- stop spawning when this many peds exist client side
}

Config.Detect = {
    sightDay   = 18.0,          -- see-you distance (needs line of sight)
    sightNight = 32.0,
    hearWalk   = 8.0,           -- hear-you distance while walking
    hearRun    = 20.0,
    hearSneak  = 3.0,
    hearVehicle = 55.0,
    loseFactor = 1.7,           -- zombie gives up when you are farther than sight * this
    alertMs    = 25000,         -- how long a noise alert (gunshot) pulls zombies
}

Config.Wander = {
    idleMs = 9000,              -- re-issue wander task this often when idle
}

Config.Night = {
    start      = 21.0,          -- full dark begins (hour)
    finish     = 4.5,           -- full dark ends
    ramp       = 2.0,           -- hours of dusk/dawn transition
    spawnMult  = 1.7,           -- zombie cap multiplier at full night
    speedDay   = 0.9,           -- move rate override (1.0 = normal ped speed)
    speedNight = 1.12,
    damageMult = 1.4,
    runnerChance = 0.15,        -- chance a zombie is a fast runner at full night
}

Config.Attack = {
    range     = 1.5,
    cooldown  = 1600,           -- ms between bites per zombie
    damage    = 8,              -- base damage per hit
    maxServerRange = 3.8,       -- server rejects hits from farther than this
    dict      = 'melee@unarmed@streamed_core',
    clip      = 'short_0_punch',
}

-- Day/night cycle (server synced). 2000 ms per game minute = 48 minute full day.
Config.Time = {
    enabled    = true,
    startHour  = 18,
    msPerMinute = 2000,
}

Config.World = {
    trafficDensity = 0.0,       -- moving traffic (0 = none)
    parkedDensity  = 0.25,      -- parked cars (use survival-looting for scavenge vehicles)
    weather        = 'OVERCAST',
}

-- Zombie-free zones. Zombies never spawn here and are removed if they wander in.
-- Defaults are suggestions: stand where you want a zone and use /zcoords (admin) to print coords.
Config.SafeZones = {
    { name = 'Grapeseed Farm Camp',  coords = vec3(2447.9, 4977.5, 46.8), radius = 70.0 },
    { name = 'Sandy Shores Camp',    coords = vec3(1392.9, 3604.7, 35.0), radius = 60.0 },
    { name = 'Paleto Survivor Camp', coords = vec3(-552.0, 5330.0, 70.0), radius = 60.0 },
}

-- Chance a killed zombie drops a small bag, and what it can hold.
Config.KillLoot = {
    chance = 0.30,
    rolls  = { min = 1, max = 2 },
    table = {
        { name = 'cloth',         min = 1, max = 2, weight = 30 },
        { name = 'scrap_metal',   min = 1, max = 2, weight = 25 },
        { name = 'duct_tape',     min = 1, max = 1, weight = 10 },
        { name = 'canned_beans',  min = 1, max = 1, weight = 12 },
        { name = 'bottled_water', min = 1, max = 1, weight = 12 },
        { name = 'field_bandage', min = 1, max = 1, weight = 8  },
        { name = 'ammo-9',        min = 3, max = 9, weight = 3  },
    },
}
