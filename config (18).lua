Config = {}

Config.InfectionChance = 0.30      -- chance a zombie hit infects (per accepted hit)
Config.TickSeconds = 10            -- server progression tick

-- Seconds of online time since infection at which each stage begins.
Config.Stages = {
    [1] = 0,        -- bitten: nothing obvious yet
    [2] = 480,      -- fever & cough, slow health drain
    [3] = 1080,     -- delirium, faster drain, stumbling
    [4] = 1680,     -- turning: death, then reanimation
}

Config.Drain = {                   -- hp lost per client tick (every 8 s)
    [2] = 1,
    [3] = 3,
}

Config.CureItems = {
    antibiotics = { maxStage = 2, label = 'Antibiotics' },   -- works while still early
    cure_serum  = { maxStage = 3, label = 'Experimental Serum' },
}

Config.ReanimateDelayMs = 9000     -- body lies still, then rises as a zombie
Config.ReanimateAsRunner = false
