-- 01-minimal.lua
-- Minimal: declare one switch + one on_frame callback, draw a hello-world HUD.
-- Drop in C:\VITTLOCK\Scripts\Demo\01-minimal.lua

local m = ui.script()
m:category("Demo")

local enabled = m:switch("Enabled", false)

callbacks.on_frame(function()
    if not enabled:get_bool() then return end
    -- this runs every game frame after the cmd is sent
end)

callbacks.on_render(function()
    if not enabled:get_bool() then return end
    render.text(30, 30, 1, 1, 1, 1, "hello world from 01-minimal")
end)