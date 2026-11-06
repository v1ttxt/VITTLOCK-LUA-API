--[[
    01 - Hello
    The smallest useful script: a menu page with two widgets, and a line of
    text drawn every frame while you're in a match.

    Shows: Menu.Create, Switch, ColorPicker, callback.on_draw, Render.Text,
    entity_list.local_pawn, reading a networked field.
]]

local group   = Menu.Create("Examples", "", "Hello", "", "Settings")
local enabled = group:Switch("Enabled", true)
local color   = group:ColorPicker("Text color", Color(255, 255, 255))

enabled:ToolTip("Draws your health on the left side of the screen.")

callback.on_draw:set(function()
    if not enabled:Get() then return end

    local me = entity_list.local_pawn()
    if not me or not me:is_alive() then return end

    local text = ("Health: %d / %d"):format(me.m_iHealth, me:get_max_health())
    Render.Text(0, 18, text, Vec2(20, 200), color:Get())
end)
