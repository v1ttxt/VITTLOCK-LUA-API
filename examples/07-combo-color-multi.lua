-- 07-combo-color-multi.lua
-- Demonstrates every widget kind together + combo index → string mapping.
-- Buttons, combos, color, slider, input_text, group, separator.

local m = ui.script()
m:category("Cookbook")

local enabled  = m:switch("Enabled", true)
local mode     = m:combo("Mode", {"Safe", "Fast", "Insane"}, 1)
local tint     = m:color("Tint", {0.2, 1.0, 0.6, 1.0})
local range    = m:slider_int("Range", 0, 4096, 1200)
local speed    = m:slider_float("Speed", 0.1, 5.0, 1.0)
local comment  = m:input_text("Note", 64, "")

m:separator()
m:group("Actions")
m:button("Reset range", function()
    range:set_int(1200)
    storage.set("clicks", 0)
end)
m:button("Randomize tint", function()
    tint:set_color({ math.random(), math.random(), math.random(), 1 })
end)

local modes = {"Safe", "Fast", "Insane"}

callbacks.on_render(function()
    if not enabled:get_bool() then return end
    local c = tint:get_color()
    local clicks = storage.get("clicks") or 0

    render.filled_rect(20, 20, 360, 90, 0, 0, 0, 0.6, 6)
    render.text(28, 28, c[1], c[2], c[3], c[4],
        string.format("mode=%s  range=%d  speed=%.2f",
            modes[mode:get_int() + 1] or "?", range:get_int(), speed:get_float()))
    render.text(28, 50, 1, 1, 1, 1, string.format("tint=%.2f,%.2f,%.2f,%.2f", c[1], c[2], c[3], c[4]))
    render.text(28, 72, 0.7, 0.7, 0.7, 1,
        string.format("note=%s  clicks=%d", comment:get_string(), clicks))
end)

-- Bump the click counter when the buttons fire
local function count_button(buttonMemoryKey)
    storage.set(buttonMemoryKey, (storage.get(buttonMemoryKey) or 0) + 1)
end

timers.every(1000, function()
    storage.set("ticks_alive", (storage.get("ticks_alive") or 0) + 1)
end)