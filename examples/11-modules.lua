--[[
    11 - Modules
    Splits code into a reusable module. This script draws your health and
    souls with helpers from lib/example_draw.lua.

    Setup: copy lib/example_draw.lua to C:\VITTLOCK\scripts\v2\lib\ and this
    file to C:\VITTLOCK\scripts\v2\.

    Shows: require (dots become folders; loaded once per session), keeping
    shared code in scripts\v2\lib\, player_pawn:get_currency.
]]

local draw = require("lib.example_draw")

local group   = Menu.Create("Examples", "", "Modules", "", "Settings")
local enabled = group:Switch("Enabled", true)

local info   -- { health, max_health, souls }

callback.on_frame:set(function()
    info = nil
    if not enabled:Get() then return end
    local me = entity_list.local_pawn()
    if not me or not me:is_alive() then return end
    info = {
        health     = me.m_iHealth,
        max_health = math.max(me:get_max_health(), 1),
        souls      = me:get_currency(ECurrencyType.EGold),
    }
end)

callback.on_draw:set(function()
    if not info then return end
    local from = Vec2(20, 420)
    local to = from + Vec2(200, 58)
    draw.panel(from, to)
    draw.text(("Health %d / %d"):format(info.health, info.max_health), from + Vec2(10, 6), 14,
        Menu.Style("primary_widgets_text"))
    draw.bar(from + Vec2(10, 26), from + Vec2(190, 32), info.health / info.max_health, Color(80, 200, 100))
    draw.text(("Souls %d"):format(info.souls), from + Vec2(10, 37), 14, Menu.Style("primary"))
end)
