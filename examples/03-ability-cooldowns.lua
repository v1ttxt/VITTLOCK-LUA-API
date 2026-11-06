--[[
    03 - Ability cooldowns
    A small HUD under your crosshair with your four abilities: green when
    ready, grey with the seconds left while on cooldown.

    Shows: player_pawn:get_ability_by_slot, ability:get_level / get_cooldown,
    EAbilitySlots_t, Render.ScreenSize, a font loaded once at the top level.
]]

local group   = Menu.Create("Examples", "", "Cooldowns", "", "Settings")
local enabled = group:Switch("Enabled", true)
local offset  = group:Slider("Vertical offset", 0, 400, 120, "%d px")

local font = Render.LoadFont("Inter", Enum.FontCreate.FONTFLAG_ANTIALIAS, 600)   -- once, not every frame

local SLOTS = {
    EAbilitySlots_t.ESlot_Signature_1,
    EAbilitySlots_t.ESlot_Signature_2,
    EAbilitySlots_t.ESlot_Signature_3,
    EAbilitySlots_t.ESlot_Signature_4,
}

-- { level = n, cooldown = seconds } per slot, refreshed in on_frame.
local state = {}

callback.on_frame:set(function()
    state = {}
    if not enabled:Get() then return end
    local me = entity_list.local_pawn()
    if not me or not me:is_alive() then return end

    for i, slot in ipairs(SLOTS) do
        local ab = me:get_ability_by_slot(slot)
        if ab then
            state[i] = { level = ab:get_level(), cooldown = ab:get_cooldown() }
        end
    end
end)

callback.on_draw:set(function()
    if next(state) == nil then return end

    local screen = Render.ScreenSize()
    local size, gap = 36, 8
    local total = #SLOTS * size + (#SLOTS - 1) * gap
    local x = screen.x / 2 - total / 2
    local y = screen.y / 2 + offset:Get()

    for i = 1, #SLOTS do
        local s = state[i]
        local from = Vec2(x + (i - 1) * (size + gap), y)
        local to = from + Vec2(size, size)

        local bg
        if not s or s.level == 0 then
            bg = Color(30, 30, 35, 160)        -- not learned
        elseif s.cooldown > 0 then
            bg = Color(70, 70, 80, 200)        -- on cooldown
        else
            bg = Color(60, 170, 90, 220)       -- ready
        end
        Render.FilledRect(from, to, bg, 6)
        Render.Rect(from, to, Color(0, 0, 0, 200), 6)

        local label = tostring(i)
        if s and s.level > 0 and s.cooldown > 0 then
            label = s.cooldown >= 10 and ("%d"):format(math.ceil(s.cooldown)) or ("%.1f"):format(s.cooldown)
        end
        local ts = Render.TextSize(font, 15, label)
        Render.Text(font, 15, label, Vec2(from.x + (size - ts.x) / 2, from.y + (size - ts.y) / 2), Color(255, 255, 255))
    end
end)
