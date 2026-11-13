Config = {}

Config.StarterItems = {
    { 'bottled_water', 2 },
    { 'canned_beans', 1 },
    { 'field_bandage', 2 },
    { 'WEAPON_KNIFE', 1 },
}

Config.Models = { [0] = 'mp_m_freemode_01', [1] = 'mp_f_freemode_01' }

Config.NamePattern = '^[%a%-\' ]+$'    -- letters, hyphen, apostrophe, space
Config.NameMin, Config.NameMax = 2, 16

Config.Fallback = vec4(1392.9, 3604.7, 35.0, 200.0)   -- used only if no safe zones exist
