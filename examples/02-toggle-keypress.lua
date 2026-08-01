-- 02-toggle-keypress.lua
-- Toggle a feature on keypress, show a transient on-screen notification.
-- Demonstrates: callbacks.on_pre_createmove, m:keybind, ImGui.IsKeyPressed,
-- ImGui.GetTime, ImGui.Begin/End with window flags, render.text.

local m = ui.script()
m:category("Movement")

local enabled    = m:switch("Feature", false)
local toggleKey  = m:keybind("Toggle key", 0x56)    -- V

local active      = false
local notifyUntil = 0

callbacks.on_pre_createmove(function(cmd)
    if not enabled:get_bool() then return end
    if ImGui.IsKeyPressed(toggleKey:get_int()) then
        active = not active
        notifyUntil = ImGui.GetTime() + 2.0
    end
    if active then
        -- your logic here
    end
end)

callbacks.on_render(function()
    if ImGui.GetTime() > notifyUntil then return end
    local s = Engine.GetScreenSize()
    ImGui.SetNextWindowPos(s.w * 0.5 - 60, s.h * 0.28)
    ImGui.SetNextWindowBgAlpha(0.85)
    local flags = ImGui.WindowFlags_NoTitleBar + ImGui.WindowFlags_NoResize
                + ImGui.WindowFlags_NoInputs   + ImGui.WindowFlags_NoNav
                + ImGui.WindowFlags_NoFocusOnAppearing + ImGui.WindowFlags_AlwaysAutoResize
    if ImGui.Begin("##Notify", flags) then
        ImGui.TextColored(
            active and 0.35 or 1.0,
            active and 1.0  or 0.35,
            0.4, 1,
            active and "FEATURE ON" or "FEATURE OFF")
    end
    ImGui.End()
end)