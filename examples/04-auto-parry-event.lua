-- 04-auto-parry-event.lua
-- Auto-parry on detected incoming melee modifier.
-- Demonstrates: callbacks.on_add_modifier payload + cross-cb storage handoff,
-- queues a button press for the next on_pre_createmove tick.

local m = ui.script()
m:category("Combat")

local enabled = m:switch("Auto Parry", false)
local window = m:slider_int("Buffer ms", 0, 200, 50)

callbacks.on_add_modifier(function(mod, ent)
    if not enabled:get_bool() then return end
    if ent:get_handle() ~= Engine.GetLocalPlayerHandle() then return end
    local name = mod.name or ""
    if name:find("melee_target") or name:find("charged_melee") or name:find("light_parry") then
        storage.set("parry_pending", ImGui.GetTime() + (window:get_int() / 1000.0))
        log.info("parry scheduled: incoming modifier", name)
    end
end)

callbacks.on_pre_createmove(function(cmd)
    local due = storage.get("parry_pending")
    if not due then return end
    if ImGui.GetTime() >= due then
        cmd:AddButtonState(InputBitMask_t.IN_ABILITY_HELD)
        storage.set("parry_pending", nil)
    end
end)