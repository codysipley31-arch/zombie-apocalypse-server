Config = {}

---------------------------------------------------------------------- loot tables
-- entries: { item, min, max, weight }. `rolls` = how many entries are drawn per search.
-- `empty` = chance the container turns out to be empty.
Config.Tables = {
    food = {
        rolls = { 1, 3 }, empty = 0.20,
        items = {
            { 'canned_beans', 1, 2, 22 }, { 'canned_soup', 1, 2, 18 }, { 'canned_peaches', 1, 1, 14 },
            { 'chips', 1, 2, 20 }, { 'energy_bar', 1, 2, 12 }, { 'bottled_water', 1, 2, 24 }, { 'soda', 1, 2, 16 },
        },
    },
    medical = {
        rolls = { 1, 2 }, empty = 0.25,
        items = {
            { 'field_bandage', 1, 3, 30 }, { 'painkillers', 1, 2, 22 }, { 'medkit', 1, 1, 8 },
            { 'antibiotics', 1, 1, 7 }, { 'cure_serum', 1, 1, 0.6 }, { 'cloth', 1, 3, 20 },
        },
    },
    junk = {
        rolls = { 1, 2 }, empty = 0.35,
        items = {
            { 'cloth', 1, 3, 26 }, { 'scrap_metal', 1, 2, 24 }, { 'duct_tape', 1, 1, 10 },
            { 'nails', 2, 6, 14 }, { 'wood_plank', 1, 1, 8 }, { 'bottled_water', 1, 1, 6 }, { 'canned_beans', 1, 1, 4 },
            { 'electronics', 1, 1, 5 },
        },
    },
    tools = {
        rolls = { 1, 3 }, empty = 0.25,
        items = {
            { 'scrap_metal', 1, 3, 25 }, { 'nails', 3, 10, 20 }, { 'duct_tape', 1, 2, 14 },
            { 'wood_plank', 1, 2, 12 }, { 'lockpick', 1, 1, 6 }, { 'WEAPON_CROWBAR', 1, 1, 2 },
            { 'WEAPON_HATCHET', 1, 1, 1.5 }, { 'electronics', 1, 1, 6 }, { 'fuel_can', 1, 1, 4 },
        },
    },
    car = {
        rolls = { 1, 2 }, empty = 0.30,
        items = {
            { 'canned_soup', 1, 1, 8 }, { 'bottled_water', 1, 1, 12 }, { 'field_bandage', 1, 1, 8 },
            { 'cloth', 1, 2, 14 }, { 'duct_tape', 1, 1, 6 }, { 'ammo-9', 4, 12, 5 }, { 'electronics', 1, 1, 4 },
        },
    },
    carparts = {          -- stripping a car for parts
        rolls = { 1, 2 }, empty = 0.0,
        items = {
            { 'car_parts', 1, 2, 24 }, { 'scrap_metal', 2, 4, 24 }, { 'electronics', 1, 1, 8 },
        },
    },
    military = {
        rolls = { 2, 4 }, empty = 0.05,
        items = {
            { 'ammo-9', 12, 30, 20 }, { 'ammo-45', 8, 20, 12 }, { 'ammo-rifle', 15, 45, 12 }, { 'ammo-shotgun', 6, 14, 10 },
            { 'mre', 1, 2, 18 }, { 'medkit', 1, 1, 10 }, { 'field_bandage', 2, 4, 16 }, { 'weapon_repair_kit', 1, 1, 8 },
            { 'WEAPON_PISTOL', 1, 1, 5 }, { 'WEAPON_PUMPSHOTGUN', 1, 1, 2.5 }, { 'WEAPON_CARBINERIFLE', 1, 1, 1.2 },
            { 'gunpowder', 2, 6, 12 }, { 'antibiotics', 1, 2, 6 }, { 'cure_serum', 1, 1, 1.5 },
        },
    },
    airdrop = {
        rolls = { 5, 8 }, empty = 0.0,
        items = {
            { 'ammo-rifle', 30, 90, 18 }, { 'ammo-shotgun', 12, 30, 14 }, { 'ammo-9', 30, 60, 14 },
            { 'mre', 2, 4, 18 }, { 'medkit', 1, 3, 16 }, { 'antibiotics', 1, 3, 10 }, { 'cure_serum', 1, 1, 4 },
            { 'weapon_repair_kit', 1, 2, 12 }, { 'WEAPON_CARBINERIFLE', 1, 1, 5 }, { 'WEAPON_PUMPSHOTGUN', 1, 1, 6 },
            { 'bottled_water', 3, 6, 14 }, { 'canned_beans', 2, 4, 10 }, { 'gunpowder', 4, 10, 10 },
        },
    },
}

---------------------------------------------------------------------- lootable props
-- Any world object with these models can be searched, anywhere on the map. Zero coordinates needed.
-- Respawn is per prop, per server (restocks after `respawn` real minutes).
Config.Props = {
    food = {
        label = 'Search', icon = 'fas fa-utensils', time = 5000, respawn = 40, anim = 'rummage',
        models = {
            'prop_vend_soda_01', 'prop_vend_soda_02', 'prop_vend_snak_01', 'prop_vend_snak_01_tu',
            'prop_vend_coffe_01', 'prop_vend_water_01', 'prop_fridge_01', 'prop_fridge_03',
            'v_res_fridgemodsml', 'prop_trailr_fridge', 'prop_bar_fridge_01', 'prop_bar_fridge_02',
            'prop_bar_fridge_03', 'prop_bar_fridge_04',
        },
    },
    medical = {
        label = 'Search Cabinet', icon = 'fas fa-briefcase-medical', time = 6000, respawn = 70, anim = 'rummage',
        models = { 'v_med_cor_medstor', 'v_med_medwaste', 'prop_ld_health_pack', 'v_med_bigcab', 'prop_medcab' },
    },
    junk = {
        label = 'Dig Through Trash', icon = 'fas fa-dumpster', time = 6500, respawn = 30, anim = 'rummage',
        models = {
            'prop_dumpster_01a', 'prop_dumpster_02a', 'prop_dumpster_02b', 'prop_dumpster_3a', 'prop_dumpster_4a',
            'prop_dumpster_4b', 'prop_cs_dumpster_01a', 'prop_skip_01a', 'prop_skip_02a', 'prop_skip_03',
            'prop_rub_binbag_01', 'prop_bin_01a', 'prop_bin_02a', 'prop_bin_03a', 'prop_bin_04a',
        },
    },
    tools = {
        label = 'Search Toolbox', icon = 'fas fa-toolbox', time = 6000, respawn = 60, anim = 'rummage',
        models = {
            'prop_toolchest_01', 'prop_toolchest_02', 'prop_toolchest_03', 'prop_toolchest_04', 'prop_toolchest_05',
            'prop_tool_box_01', 'prop_tool_box_02', 'prop_tool_box_04', 'prop_tool_box_06', 'prop_cs_toolbox',
            'prop_ld_toolbox_01', 'prop_ld_ammo_pack_01',
        },
    },
}

---------------------------------------------------------------------- military bunkers
-- Crates spawn locally when you get close. Coordinates are starting points; verify each with /zcoords
-- and move crates to match actual interiors/ground before launch.
Config.Bunkers = {
    {
        name = 'Zancudo Supply Depot', respawn = 90,
        crates = {
            { coords = vec4(-2047.4, 3132.1, 32.8, 150.0), table = 'military' },
            { coords = vec4(-2050.3, 3134.6, 32.8, 150.0), table = 'military' },
            { coords = vec4(-2052.9, 3137.0, 32.8, 150.0), table = 'military' },
            { coords = vec4(-2058.1, 3141.2, 32.8, 150.0), table = 'military' },
        },
    },
    {
        name = 'Humane Labs Storage', respawn = 90,
        crates = {
            { coords = vec4(3526.8, 3671.3, 28.1, 170.0), table = 'military' },
            { coords = vec4(3530.2, 3670.4, 28.1, 170.0), table = 'medical' },
            { coords = vec4(3534.0, 3669.2, 28.1, 170.0), table = 'medical' },
        },
    },
}
Config.BunkerModel = 'prop_box_ammo03a_set'
Config.BunkerSpawnDistance = 80.0

---------------------------------------------------------------------- supply drops
Config.Airdrops = {
    enabled = true,
    minMinutes = 35,           -- real minutes between drops
    maxMinutes = 60,
    lifetimeMinutes = 25,      -- crate disappears after this
    minPlayers = 1,
    crateModel = 'prop_drop_crate_01',
    alertZombies = true,       -- the crash draws zombies
    locations = {
        vec3(1692.3, 3283.1, 40.2),
        vec3(-1100.2, 4950.7, 218.4),
        vec3(2540.0, 2630.0, 37.9),
        vec3(-107.0, 6460.0, 31.6),
        vec3(1190.0, 2640.0, 37.4),
        vec3(-2290.0, 267.0, 169.6),
        vec3(1560.0, 6420.0, 24.0),
    },
}

---------------------------------------------------------------------- vehicles
Config.Vehicle = {
    glovebox = { time = 5000, cooldown = 45 },            -- search the interior (minutes per vehicle)
    strip    = { time = 12000, cooldown = 120, requires = 'WEAPON_CROWBAR' },
    siphon   = { time = 8000, cooldown = 30, requires = 'fuel_can', minFuel = 8.0, takePerSiphon = 12.0 },
    fuelCanCapacity = 20.0,    -- units of fuel (same 0-100 scale as vehicle tank) stored in a can
    refuelPerUse = 20.0,
}

Config.Fuel = {
    enabled = true,
    -- tank percent burned per second: idle + consumption * (speed / 30 m/s)
    consumption = 0.09,
    idle = 0.008,
    startFuelMin = 5.0,         -- abandoned vehicles spawn with 5-30 percent
    startFuelMax = 30.0,
}
