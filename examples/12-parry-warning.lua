--[[
    12 - Parry warning
    Warns you when an enemy hero close in front of you is parrying, so you
    don't melee into it. Draws a warning under the crosshair and a ring
    around the parrying enemy.

    Shows: checking a modifier state on enemies, a simple facing test with
    the camera angles (Angle:GetForward / Vector:Dot), mixing on_frame data with
    on_draw, Render.Circle.
]]

local group   = Menu.Create("Examples", "", "Parry Warning", "", "Settings")
local enabled = group:Switch("Enabled", true)
local range   = group:Slider("Range (m)", 2, 15, 6, "%d m")
local cone    = group:Slider("Cone half-angle (deg)", 10, 90, 45, "%d deg")
local color   = group:ColorPicker("Warning color", Color(255, 70, 70))

local UNITS_PER_METER = 39.37

local parrying = {}   -- origins of parrying enemies in front of you

callback.on_frame:set(function()
    parrying = {}
    if not enabled:Get() then return end
    local me = entity_list.local_pawn()
    if not me or not me:is_alive() then return end

    local my_pos  = me:get_origin()
    local forward = utils.get_camera_angles():GetForward()
    forward.z = 0
    forward = forward:Normalized()
    local max_dist = range:Get() * UNITS_PER_METER
    local min_dot  = math.cos(math.rad(cone:Get()))

    for _, e in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        if e:is_alive() and not e:is_dormant()
            and e:has_modifier_state(EModifierState.MODIFIER_STATE_PARRY_ACTIVE) then
            local pos = e:get_origin()
            local to_enemy = pos - my_pos
            to_enemy.z = 0
            local dist = to_enemy:Length()
            if dist <= max_dist and (dist < 1 or forward:Dot(to_enemy / dist) >= min_dot) then
                parrying[#parrying + 1] = pos
            end
        end
    end
end)

callback.on_draw:set(function()
    if #parrying == 0 then return end
    local c = color:Get()

    for _, pos in ipairs(parrying) do
        local screen, on_screen = Render.WorldToScreen(pos + Vector(0, 0, 40))
        if on_screen then
            Render.Circle(screen, 28, c, 3)
        end
    end

    local screen = Render.ScreenSize()
    local text = "ENEMY PARRYING"
    local ts = Render.TextSize(0, 20, text)
    Render.Text(0, 20, text, Vec2(screen.x / 2 - ts.x / 2, screen.y / 2 + 60), c)
end)
