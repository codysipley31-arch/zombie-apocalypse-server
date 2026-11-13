Config = {}

Config.MaxPiecesPerPlayer = 40
Config.MinDistanceFromSafeZone = 25.0      -- cannot build next to a camp
Config.MaxPlaceDistance = 9.0              -- how far ahead you can place a piece
Config.MinSpacing = 0.6                    -- stops stacking identical pieces on one spot
Config.AllowRaiding = true                 -- non-owners can break pieces with a crowbar (slow)
Config.RaidTimeMs = 30000
Config.RaidItem = 'WEAPON_CROWBAR'

-- item -> piece definition. `z` is the vertical offset applied after ground snapping.
-- The workbench model must match survival-crafting Config.WorkbenchModel.
Config.Pieces = {
    base_wall = {
        label = 'Wooden Wall', model = 'prop_fncwood_16a', z = 0.0, stash = false,
    },
    base_barricade = {
        label = 'Barricade', model = 'prop_barrier_work06a', z = 0.0, stash = false,
    },
    base_crate = {
        label = 'Storage Crate', model = 'prop_box_wood05a', z = 0.0, stash = { slots = 40, weight = 150000 },
    },
    base_workbench = {
        label = 'Workbench', model = 'prop_tool_bench02', z = 0.0, stash = false, workbench = true,
    },
}
