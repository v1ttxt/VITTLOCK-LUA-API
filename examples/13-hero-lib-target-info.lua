--[[
    13 - Target info (HERO_LIB)
    Picks the enemy hero you are aiming at with the built-in target
    selection (Heroes > Settings > General > Helper Target Selection), then
    shows its state under the crosshair: effective health, the disables and
    immunities on it, and whether it is in the open. A ring marks it in the
    world.

    Shows: HERO_LIB.lp / is_lp_alive, find_helper_target, the status checks,
    get_damageable_health, no_obs_to_target, get_on_hero_indicator_pos,
    get_disable_remaining, gathering in on_createmove and drawing in on_draw.
]]

local group   = Menu.Create("Examples", "", "Target Info", "", "Settings")
local enabled = group:Switch("Enabled", true)
local color   = group:ColorPicker("Ring color", Color(255, 200, 60))

local font = Render.LoadFont("Inter", Enum.FontCreate.FONTFLAG_ANTIALIAS, 600)

-- Plain values gathered on the last command; on_draw only reads them.
local info = nil

local function flags_of(t)
    local out = {}
    if HERO_LIB.is_stunned(t) then
        out[#out + 1] = ("stunned %.1fs"):format(HERO_LIB.get_disable_remaining(t))
    end
    if HERO_LIB.is_silenced(t)      then out[#out + 1] = "silenced" end
    if HERO_LIB.is_sleeped(t)       then out[#out + 1] = "asleep" end
    if HERO_LIB.is_unstoppable(t)   then out[#out + 1] = "unstoppable" end
    if HERO_LIB.is_invulnerable(t)  then out[#out + 1] = "invulnerable" end
    if HERO_LIB.is_tech_invulnerable(t) then out[#out + 1] = "spirit immune" end
    if HERO_LIB.avoids_spells(t)    then out[#out + 1] = "spell shield" end
    if HERO_LIB.is_any_dashing(t)   then out[#out + 1] = "dashing" end
    if HERO_LIB.is_on_zipline(t)    then out[#out + 1] = "zipline" end
    return out
end

callback.on_createmove:set(function(cmd)
    info = nil
    if not enabled:Get() then return end
    local me = HERO_LIB.lp
    if not me or not HERO_LIB.is_lp_alive then return end

    local target = HERO_LIB.find_helper_target(cmd, me)
    if not target or HERO_LIB.is_inactive_target(target) then return end

    local health = HERO_LIB.get_damageable_health(target) or 0
    local percent = HERO_LIB.get_health_percent(target) or 0
    info = {
        name    = target:get_name():gsub("^hero_", ""),
        health  = math.floor(health),
        percent = math.floor(percent),
        open    = HERO_LIB.no_obs_to_target(target),
        flags   = flags_of(target),
        marker  = HERO_LIB.get_on_hero_indicator_pos(target),
    }
end)

callback.on_draw:set(function()
    if not info then return end

    -- Ring over the target.
    if info.marker then
        local pos, visible = Render.WorldToScreen(info.marker)
        if visible then
            Render.Circle(pos, 14, color:Get(), 2)
        end
    end

    -- Panel under the crosshair.
    local screen = Render.ScreenSize()
    local lines = {
        ("%s  %d hp (%d%%)"):format(info.name, info.health, info.percent),
        info.open and "in the open" or "behind cover",
    }
    if #info.flags > 0 then
        lines[#lines + 1] = table.concat(info.flags, ", ")
    end
    local y = screen.y / 2 + 60
    for _, line in ipairs(lines) do
        local size = Render.TextSize(font, 14, line)
        Render.Text(font, 14, line, Vec2(screen.x / 2 - size.x / 2, y), Color(255, 255, 255, 230))
        y = y + size.y + 2
    end
end)
