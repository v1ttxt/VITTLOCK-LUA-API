--[[
    02 - Enemy ESP
    Boxes, health bars and distance for enemy heroes.

    Shows: gathering data in on_frame and drawing it in on_draw,
    entity_list.by_class_name with a team filter, get_bone_pos,
    Render.WorldToScreen, Render.Rect / FilledRect / Text / TextSize.
]]

local group    = Menu.Create("Examples", "", "Enemy ESP", "", "Settings")
local enabled  = group:Switch("Enabled", true)
local box_on   = group:Switch("Box", true)
local hp_on    = group:Switch("Health bar", true)
local dist_on  = group:Switch("Distance", true)
local max_dist = group:Slider("Max distance (m)", 10, 200, 80, "%d m")
local box_col  = group:ColorPicker("Box color", Color(255, 80, 80))

local UNITS_PER_METER = 39.37   -- world units per meter (approximately)

-- Filled in on_frame, read in on_draw: plain values only, no game objects.
local targets = {}

callback.on_frame:set(function()
    targets = {}
    if not enabled:Get() then return end

    local me = entity_list.local_pawn()
    if not me then return end
    local my_pos = me:get_origin()

    for _, e in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        if e:is_alive() and not e:is_dormant() then
            local feet = e:get_origin()
            local head = e:get_bone_pos("head")
            local meters = my_pos:Distance(feet) / UNITS_PER_METER
            if head and meters <= max_dist:Get() then
                targets[#targets + 1] = {
                    feet   = feet,
                    head   = head + Vector(0, 0, 12),   -- a little above the head bone
                    health = e.m_iHealth,
                    max    = math.max(e:get_max_health(), 1),
                    meters = meters,
                }
            end
        end
    end
end)

callback.on_draw:set(function()
    for _, t in ipairs(targets) do
        local top, top_ok = Render.WorldToScreen(t.head)
        local bottom, bottom_ok = Render.WorldToScreen(t.feet)
        if top_ok and bottom_ok then
            local h = bottom.y - top.y
            local w = h * 0.45
            local left, right = top.x - w / 2, top.x + w / 2

            if box_on:Get() then
                Render.Rect(Vec2(left - 1, top.y - 1), Vec2(right + 1, bottom.y + 1), Color(0, 0, 0, 160))
                Render.Rect(Vec2(left, top.y), Vec2(right, bottom.y), box_col:Get())
            end

            if hp_on:Get() then
                local frac = math.min(math.max(t.health / t.max, 0), 1)
                local bar_top = bottom.y - h * frac
                Render.FilledRect(Vec2(left - 6, top.y - 1), Vec2(left - 2, bottom.y + 1), Color(0, 0, 0, 170))
                Render.FilledRect(Vec2(left - 5, bar_top), Vec2(left - 3, bottom.y),
                    Color(math.floor(255 * (1 - frac)), math.floor(220 * frac), 60))
            end

            if dist_on:Get() then
                local label = ("%dm"):format(math.floor(t.meters))
                local size = Render.TextSize(0, 13, label)
                Render.Text(0, 13, label, Vec2(top.x - size.x / 2, bottom.y + 3), Color(255, 255, 255, 220))
            end
        end
    end
end)
