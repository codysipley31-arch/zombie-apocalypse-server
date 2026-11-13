-- Item definitions merged into ox_inventory/data/items.lua by the recipe.
-- Server exports referenced below live in the named resources.

local function food(label, weight, desc, anim)
    return {
        label = label,
        weight = weight,
        stack = true,
        close = true,
        consume = 1,
        description = desc,
        server = { export = 'survival-needs.consume' },
        client = {
            anim = anim or { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp', flag = 49 },
            usetime = 3500,
            notification = nil,
        },
    }
end

local drink = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 }
local heal = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 }

return {
    -- Food & water ---------------------------------------------------------
    canned_beans   = food('Canned Beans', 350, 'Salty, cold and still better than nothing.'),
    canned_soup    = food('Canned Soup', 400, 'Chicken noodle. Somebody had to save this.'),
    canned_peaches = food('Canned Peaches', 400, 'Sweet and syrupy.'),
    chips          = food('Bag of Chips', 120, 'Stale but edible.'),
    energy_bar     = food('Energy Bar', 80, 'A little energy for the road.'),
    mre            = food('Military MRE', 500, 'Standard issue ready-to-eat meal.'),
    bottled_water  = food('Bottled Water', 500, 'Sealed and safe to drink.', drink),
    soda           = food('Soda Can', 330, 'Warm and flat. Still wet.', drink),

    -- Medical --------------------------------------------------------------
    field_bandage = {
        label = 'Field Bandage', weight = 120, stack = true, close = true, consume = 1,
        description = 'Stops the bleeding and patches you up a little.',
        server = { export = 'survival-needs.consume' },
        client = { anim = heal, usetime = 4000 },
    },
    medkit = {
        label = 'Medkit', weight = 800, stack = true, close = true, consume = 1,
        description = 'Proper supplies. Heals most wounds.',
        server = { export = 'survival-needs.consume' },
        client = { anim = heal, usetime = 8000 },
    },
    painkillers = {
        label = 'Painkillers', weight = 60, stack = true, close = true, consume = 1,
        description = 'Takes the edge off.',
        server = { export = 'survival-needs.consume' },
        client = { anim = drink, usetime = 2000 },
    },
    antibiotics = {
        label = 'Antibiotics', weight = 80, stack = true, close = true, consume = 1,
        description = 'Slows or stops an infection if taken early.',
        server = { export = 'zombie-infection.antibiotics' },
        client = { anim = drink, usetime = 2500 },
    },
    cure_serum = {
        label = 'Experimental Serum', weight = 150, stack = true, close = true, consume = 1,
        description = 'Unmarked vial from a lab. Might just cure a bite.',
        server = { export = 'zombie-infection.cure_serum' },
        client = { anim = heal, usetime = 5000 },
    },

    -- Materials ------------------------------------------------------------
    cloth        = { label = 'Cloth Scraps', weight = 60, stack = true, description = 'Torn clothing.' },
    scrap_metal  = { label = 'Scrap Metal', weight = 250, stack = true, description = 'Bent, rusty metal.' },
    duct_tape    = { label = 'Duct Tape', weight = 150, stack = true, description = 'Fixes everything.' },
    wood_plank   = { label = 'Wood Plank', weight = 800, stack = true, description = 'A sturdy plank.' },
    nails        = { label = 'Nails', weight = 40, stack = true, description = 'A handful of nails.' },
    gunpowder    = { label = 'Gunpowder', weight = 60, stack = true, description = 'Loose black powder.' },
    electronics  = { label = 'Electronics', weight = 150, stack = true, description = 'Salvaged circuit boards.' },
    car_parts    = { label = 'Car Parts', weight = 600, stack = true, description = 'Salvaged from abandoned vehicles.' },

    -- Tools ----------------------------------------------------------------
    lockpick = {
        label = 'Lockpick', weight = 60, stack = true, description = 'For doors that did not survive the apocalypse.',
    },
    fuel_can = {
        label = 'Fuel Can', weight = 3500, stack = false, close = true,
        description = 'Holds precious gasoline. Use it next to a vehicle to refuel.',
        server = { export = 'survival-looting.fuel_can' },
    },
    weapon_repair_kit = {
        label = 'Weapon Repair Kit', weight = 900, stack = true, close = true, consume = 0,
        description = 'Hold the weapon you want to repair, then use this.',
        server = { export = 'survival-crafting.weapon_repair_kit' },
    },

    -- Placeables (survival-basebuilding) -------------------------------------
    base_wall = {
        label = 'Wooden Wall', weight = 4000, stack = true, close = true,
        description = 'A reinforced wall panel. Use to place.',
        server = { export = 'survival-basebuilding.place' },
    },
    base_barricade = {
        label = 'Barricade', weight = 5000, stack = true, close = true,
        description = 'Sandbag and plank barricade. Use to place.',
        server = { export = 'survival-basebuilding.place' },
    },
    base_crate = {
        label = 'Storage Crate', weight = 6000, stack = true, close = true,
        description = 'Store your supplies at camp. Use to place.',
        server = { export = 'survival-basebuilding.place' },
    },
    base_workbench = {
        label = 'Workbench', weight = 9000, stack = true, close = true,
        description = 'A sturdy bench for crafting. Use to place.',
        server = { export = 'survival-basebuilding.place' },
    },
}
