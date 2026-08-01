-- 05-velocity-hud.lua
-- HUD readout of local velocity + game time + tick interval.
-- Demonstrates: Engine.GetLocalVelocity, Vector3:Length2D, Engine.GetCurTime,
-- ImGui.Begin with NoTitleBar+NoInputs+AlwaysAutoResize, multi-line HUD.

local m = ui.script()
m:category("Info")
local show = m:switch("Show HUD", true)

callbacks.on_render(function()
    if not show:get_bool() then return end

    local v = Engine.GetLocalVelocity()
    local speed2D = v:Length2D()
    local speed3D = v:Length()
    local tick    = Engine.GetTickInterval()
    local curtime = Engine.GetCurTime()

    local flags = ImGui.WindowFlags_NoTitleBar + ImGui.WindowFlags_AlwaysAutoResize
                + ImGui.WindowFlags_NoInputs   + ImGui.WindowFlags_NoNav
                + ImGui.WindowFlags_NoSavedSettings

    ImGui.SetNextWindowPos(20, 20)
    ImGui.SetNextWindowBgAlpha(0.65)

    if ImGui.Begin("##hud", flags) then
        ImGui.Text(string.format("speed2D : %.0f", speed2D))
        ImGui.Text(string.format("speed3D : %.0f", speed3D))
        ImGui.Text(string.format("curtime : %.1f", curtime))
        ImGui.Text(string.format("tick    : %.4f", tick))
        ImGui.Text(string.format("script  : %s",  __SCRIPT_NAME__))
    end
    ImGui.End()
end)