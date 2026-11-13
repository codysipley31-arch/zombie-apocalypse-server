ZUtil = {}

function ZUtil.lerp(a, b, t)
    return a + (b - a) * t
end

-- 0.0 = full day, 1.0 = full night, smooth dusk/dawn ramps. `h` is a 0-24 hour float.
function ZUtil.nightFactor(h)
    local n = Config.Night
    local dusk = n.start - n.ramp
    if h >= n.start or h < n.finish then
        return 1.0
    elseif h >= dusk then
        return (h - dusk) / n.ramp
    elseif h < n.finish + n.ramp then
        return 1.0 - (h - n.finish) / n.ramp
    end
    return 0.0
end

-- Current world hour as float (server synced when the cycle is enabled).
function ZUtil.hour()
    local m = GlobalState.worldMinutes
    if m then return m / 60.0 end
    if IsDuplicityVersion() then return 12.0 end
    return GetClockHours() + GetClockMinutes() / 60.0
end

function ZUtil.inSafeZone(coords, pad)
    pad = pad or 0.0
    for i = 1, #Config.SafeZones do
        local z = Config.SafeZones[i]
        if #(coords - z.coords) <= z.radius + pad then
            return true, z
        end
    end
    return false
end

function ZUtil.pickWeighted(list)
    local total = 0
    for i = 1, #list do total = total + list[i].weight end
    local roll = math.random() * total
    for i = 1, #list do
        roll = roll - list[i].weight
        if roll <= 0 then return list[i] end
    end
    return list[#list]
end
