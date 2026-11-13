Config = {}

Config.HandCraftKey = 'K'          -- default key (players can rebind in Settings > Key Bindings > FiveM)

-- Must match the model of the 'base_workbench' piece in survival-basebuilding.
Config.WorkbenchModel = 'prop_tool_bench02'
Config.BenchRange = 6.0            -- server check: how close you must be to a bench

-- Free benches set up at safe-zone camps (props spawn locally when you get near)
Config.FixedBenches = {
    vec4(2452.4, 4980.9, 46.8, 90.0),    -- Grapeseed Farm Camp
    vec4(1396.5, 3606.8, 35.0, 200.0),   -- Sandy Shores Camp
    vec4(-548.6, 5333.1, 70.0, 150.0),   -- Paleto Survivor Camp
}

-- bench = 'hand' (anywhere) or 'workbench' (near a bench)
-- time in ms; ingredients are consumed on success
Config.Recipes = {
    -- hand crafting
    { id = 'bandage',    bench = 'hand', label = 'Field Bandage', time = 4000,
      ingredients = { cloth = 3 },                                  result = { 'field_bandage', 1 } },
    { id = 'lockpick',   bench = 'hand', label = 'Lockpick', time = 5000,
      ingredients = { scrap_metal = 1, duct_tape = 1 },             result = { 'lockpick', 2 } },
    { id = 'workbench',  bench = 'hand', label = 'Workbench (placeable)', time = 9000,
      ingredients = { wood_plank = 6, scrap_metal = 6, nails = 12, duct_tape = 2 }, result = { 'base_workbench', 1 } },
    { id = 'crate',      bench = 'hand', label = 'Storage Crate (placeable)', time = 7000,
      ingredients = { wood_plank = 5, nails = 8 },                  result = { 'base_crate', 1 } },

    -- workbench crafting
    { id = 'bat',        bench = 'workbench', label = 'Nail Bat', time = 8000,
      ingredients = { wood_plank = 2, nails = 4, duct_tape = 1 },   result = { 'WEAPON_BAT', 1 } },
    { id = 'machete',    bench = 'workbench', label = 'Machete', time = 10000,
      ingredients = { scrap_metal = 4, duct_tape = 2, wood_plank = 1 }, result = { 'WEAPON_MACHETE', 1 } },
    { id = 'repairkit',  bench = 'workbench', label = 'Weapon Repair Kit', time = 9000,
      ingredients = { scrap_metal = 3, duct_tape = 2, nails = 4, electronics = 1 }, result = { 'weapon_repair_kit', 1 } },
    { id = 'ammo9',      bench = 'workbench', label = '9mm Rounds (x12)', time = 9000,
      ingredients = { gunpowder = 3, scrap_metal = 2 },             result = { 'ammo-9', 12 } },
    { id = 'ammoshot',   bench = 'workbench', label = 'Shotgun Shells (x6)', time = 9000,
      ingredients = { gunpowder = 4, scrap_metal = 3 },             result = { 'ammo-shotgun', 6 } },
    { id = 'wall',       bench = 'workbench', label = 'Wooden Wall (placeable)', time = 9000,
      ingredients = { wood_plank = 4, nails = 10, duct_tape = 1 },  result = { 'base_wall', 1 } },
    { id = 'barricade',  bench = 'workbench', label = 'Barricade (placeable)', time = 9000,
      ingredients = { wood_plank = 3, scrap_metal = 3, cloth = 4, nails = 6 }, result = { 'base_barricade', 1 } },
    { id = 'medkit',     bench = 'workbench', label = 'Medkit', time = 10000,
      ingredients = { field_bandage = 3, painkillers = 1, duct_tape = 1 }, result = { 'medkit', 1 } },
}

-- Weapon repair kit: durability restored per use (0-100 scale)
Config.RepairAmount = 60
