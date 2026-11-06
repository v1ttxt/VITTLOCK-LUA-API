--[[
    06 - Camp timers
    Shows a camp icon and a respawn countdown over every neutral camp that is
    down, in the world, within a chosen distance.

    Shows: map_info.camps and its enum tables, spawn windows, built-in
    "~/deadlock/..." SVG icons loaded once, Render.ImageCentered.
]]

local group    = Menu.Create("Examples", "", "Camp Timers", "", "Settings")
local enabled  = group:Switch("Enabled", true)
local max_dist = group:Slider("Max distance (m)", 20, 400, 150, "%d m")
local show_up  = group:Switch("Also mark camps that are up", false)

local UNITS_PER_METER = 39.37

-- Built-in icons, rasterized once at 28x28.
local ICON_SIZE = Vec2(28, 28)
local ICONS = {
    [map_info.CampKind.SMALL]  = Render.LoadSvg("~/deadlock/camp_small.svg", ICON_SIZE),
    [map_info.CampKind.MEDIUM] = Render.LoadSvg("~/deadlock/camp_medium.svg", ICON_SIZE),
    [map_info.CampKind.LARGE]  = Render.LoadSvg("~/deadlock/camp_large.svg", ICON_SIZE),
    [map_info.CampKind.SINNER] = Render.LoadSvg("~/deadlock/sinner.svg", ICON_SIZE),
}
local TINT = {
    [map_info.CampKind.SMALL]  = Color(161, 221, 67),
    [map_info.CampKind.MEDIUM] = Color(247, 240, 84),
    [map_info.CampKind.LARGE]  = Color(206, 53, 53),
    [map_info.CampKind.SINNER] = Color(98, 252, 233),
}

-- { pos = Vector, kind = integer, text = string|nil } per camp to draw.
local marks = {}

local function countdown(window)
    if not window then return nil end
    local s = window.earliest_in
    if s <= 0 then return "now" end
    return ("%d:%02d"):format(math.floor(s / 60), math.floor(s % 60))
end

callback.on_frame:set(function()
    marks = {}
    if not enabled:Get() or not map_info.map().supported then return end
    local me = entity_list.local_pawn()
    if not me then return end
    local my_pos = me:get_origin()
    local limit = max_dist:Get() * UNITS_PER_METER

    for _, camp in ipairs(map_info.camps().items) do
        if my_pos:Distance(camp.position) <= limit then
            local down = camp.state == map_info.CampState.DEAD or camp.state == map_info.CampState.WAITING_INITIAL
            if down then
                marks[#marks + 1] = { pos = camp.position, kind = camp.kind, text = countdown(camp.next_spawn) }
            elseif show_up:Get() and camp.state == map_info.CampState.ALIVE then
                marks[#marks + 1] = { pos = camp.position, kind = camp.kind }
            end
        end
    end
end)

callback.on_draw:set(function()
    for _, m in ipairs(marks) do
        local screen, on_screen = Render.WorldToScreen(m.pos + Vector(0, 0, 80))
        local icon = ICONS[m.kind]
        if on_screen and icon and icon ~= 0 then
            Render.ImageCentered(icon, screen, ICON_SIZE, TINT[m.kind] or Color(255, 255, 255))
            if m.text then
                local ts = Render.TextSize(0, 14, m.text)
                local at = Vec2(screen.x - ts.x / 2, screen.y + ICON_SIZE.y / 2 + 2)
                Render.FilledRect(at - Vec2(4, 1), at + Vec2(ts.x + 4, ts.y + 1), Color(0, 0, 0, 150), 4)
                Render.Text(0, 14, m.text, at, Color(255, 255, 255))
            end
        end
    end
end)
