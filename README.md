# The Walking Dead: Lightweight Zombie Apocalypse (FiveM)

QBCore + ox stack, with the zombie and survival systems written from scratch.
No police, EMS, jobs, dealerships or traditional RP systems.

> **Status: untested on a live server.** Everything was syntax-checked and cross-referenced
> (every export, event and callback has a matching definition), but it has never run inside FXServer.
> Expect to do a tuning pass. See "First boot checklist" below.

## What is in the box

| Resource | Does |
|---|---|
| `zombie-ai` | Shambling zombies, sight/hearing detection, chasing, bite attacks (server validated), headshot kills, night scaling (more, faster, harder-hitting), respawning, safe zones, gunshot noise, zombie kill loot, synced day/night clock, empty-world settings |
| `zombie-hordes` | Roaming hordes that form around a random survivor, plus static nests (military base, labs, towns) with a global cooldown |
| `zombie-infection` | Bites can infect. 4 stages (fever, delirium, turning). Cure with antibiotics (early) or serum. Dying of it reanimates you as a zombie |
| `survival-needs` | Hunger, thirst, HUD, food and medical items, hardcore death (inventory drops in a body bag), respawn at a camp. Also holds every custom item definition |
| `survival-looting` | Search fridges, vending machines, dumpsters, toolboxes and medical cabinets anywhere on the map. Military bunker crates. Timed supply drops. Vehicle scavenging, parts stripping, fuel siphoning and a fuel system |
| `survival-crafting` | Hand crafting (`K`) and workbench crafting. Weapon repair kits |
| `survival-basebuilding` | Place walls, barricades, storage crates and workbenches. Saved in MySQL. Owner pickup, friend access, optional crowbar raiding |
| `survival-start` | **Added by me.** QBCore has no way to create a character without multicharacter/spawn resources, which were not in your list. This gives one character per player: name prompt, appearance editor, starter kit, spawn at a camp |

Folder layout matches your plan, with `[survival]/survival-start` added.

## Install

### Option A: txAdmin recipe
1. In txAdmin, open **Recipe Deployer** and choose **Remote URL**.
2. Enter `https://raw.githubusercontent.com/codysipley31-arch/zombie-apocalypse-server/main/recipe.yaml`.
3. Follow the prompts for your server license key and database. The recipe downloads the dependencies, assembles the resources from the Lua files in this repository, merges the custom items, imports the SQL tables and writes `server.cfg`.

### Option B: manual
1. Install `oxmysql`, `ox_lib`, `ox_inventory` (release builds), `qb-core`, `qb-target`, `illenium-appearance` and the default Cfx resources.
2. Create and populate the resource folders using the file mappings in `recipe.yaml` (the source Lua files are stored at the repository root).
3. Run `survival.sql` on your database.
4. Merge items: rename `ox_inventory/data/items.lua` to `items_base.lua`, then create a new `items.lua` containing:
   ```lua
   local items = lib.load('data.items_base')
   local extra = load(LoadResourceFile('survival-needs', 'data/items.lua'), '@survival-needs/data/items.lua', 't', {})()
   for name, def in pairs(extra) do items[name] = def end
   return items
   ```
5. Use `server.cfg` from this folder (set your license key and database string).

## First boot checklist
1. Join, create a character, confirm you spawn at a camp and get the starter kit.
2. `/settime 23` for night. Zombies should be denser, faster and hit harder.
3. Walk up to a dumpster or fridge and search it.
4. `/infect`, watch the stages, then `/cure`.
5. `/airdrop` drops a crate at your position. `/zclear` deletes all zombies.
6. Press `K` to craft a workbench, place it from your inventory, then use it.

## Things you must verify or change before launch
- **Coordinates are placeholders.** Safe zones, respawns, bunkers, hordes nests, fixed workbenches and airdrop locations are best-effort GTA coordinates. Stand where you want each one and run `/zcoords` (admin), then edit the configs. The bunker crates especially need placing inside the real interiors.
- **Third-party download URLs in `recipe.yaml`** (ox release zips, illenium-appearance) assume the release assets keep their current names and top-level folder layout. If the deploy fails there, download them manually.
- **QBCore first-join flow** depends on `survival-start` calling the standard `QBCore:Server:OnPlayerLoaded` and `QBCore:Client:OnPlayerLoaded` events. If your qb-core version differs, that is the first place to look.
- **Weapon durability** is ox_inventory's built-in system (weapons wear as they fire). This package adds repair kits and the recipes. Tune wear rates in `ox_inventory/data/weapons.lua`.
- **Admin:** add your identifier to `server.cfg` (the commented `add_principal` line) to use `/zcoords`, `/zclear`, `/settime`, `/revive`, `/infect`, `/cure`, `/airdrop`.

## Tuning
Every system has a `config.lua`: spawn caps, detection ranges, night curve and day length (`zombie-ai`), horde timing (`zombie-hordes`), infection speed and cure rules (`zombie-infection`), decay rates and death penalty (`survival-needs`), loot tables and respawn timers (`survival-looting`), recipes (`survival-crafting`), build limits (`survival-basebuilding`).

Performance notes: zombies are client-owned entities, so cost scales with players, not map size. Lower `Config.Spawn.maxPerPlayer` and `pedPoolLimit` first if clients struggle.
