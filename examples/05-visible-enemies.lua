--[[
    05 - Visible enemies
    Marks enemy heroes whose head you can see from your camera with a dot on
    their head, and lists how many are visible.

    Shows: trace.line with a line-of-sight mask and an entity filter,
    trace_t:is_visible_entity, utils.get_camera_pos, throttling work in on_frame.
]]

local group    = Menu.Create("Examples", "", "Visible Enemies", "", "Settings")
local enabled  = group:Switch("Enabled", true)
local dot_col  = group:ColorPicker("Dot color", Color(255, 220, 60))

-- Interaction layers a line-of-sight check collides with (world geometry and heroes).
local LOS_MASK = 0x1C1003

local visible_heads = {}   -- Vector positions, read by on_draw
local next_check = 0

local function head_visible(enemy, me, cam)
    local head = enemy:get_bone_pos("head")
    if not head then return nil end
    local tr = trace.line(cam, head, LOS_MASK, 0, 0, 7, 4, function(ent)
        -- Teammates don't block the view for this check; everything else does.
        return ent.m_iTeamNum ~= me.m_iTeamNum
    end)
    if tr:is_visible_entity(enemy, cam:Distance(head)) then
        return head
    end
    return nil
end

callback.on_frame:set(function()
    if not enabled:Get() then
        visible_heads = {}
        return
    end

    -- Traces cost time: 20 checks per second is plenty for a visual marker.
    local now = global_vars.curtime()
    if now < next_check then return end
    next_check = now + 0.05

    visible_heads = {}
    local me = entity_list.local_pawn()
    if not me then return end
    local cam = utils.get_camera_pos()

    for _, e in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        if e:is_alive() and not e:is_dormant() then
            local head = head_visible(e, me, cam)
            if head then visible_heads[#visible_heads + 1] = head end
        end
    end
end)

callback.on_draw:set(function()
    if not enabled:Get() then return end

    for _, head in ipairs(visible_heads) do
        local pos, on_screen = Render.WorldToScreen(head)
        if on_screen then
            Render.FilledCircle(pos, 5, Color(0, 0, 0, 180))
            Render.FilledCircle(pos, 3.5, dot_col:Get())
        end
    end

    Render.Text(0, 16, ("Visible enemies: %d"):format(#visible_heads), Vec2(20, 230), Color(255, 255, 255))
end)
