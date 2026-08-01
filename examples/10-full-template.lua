-- 10-full-template.lua
-- Comprehensive script template that touches every subsystem.
-- Copy this as a starting point for any new script.
-- Demonstrates: ui.script + every widget factory, every callback, timers,
-- storage, log.*, Engine.* query, entity_list, render.* + ImGui overlay.

local m = ui.script()
m:category("Template")

-- ──────── widgets ────────
local enabled      = m:switch("Enabled", false)
local mode         = m:combo("Mode", {"Safe", "Fast", "Insane"}, 0)
local range        = m:slider_int("Range", 0, 4096, 1200)
local speed        = m:slider_float("Speed", 0.1, 5.0, 1.0)
local toggleKey    = m:keybind("Toggle key", 0x2D)        -- VK_INSERT
local tint         = m:color("Tint", {1.0, 0.4, 0.2, 1.0})
local note         = m:input_text("Note", 32, "")

m:separator()
m:group("Actions")
m:button("Reset counter", function()
    storage.set("counter", 0)
    log.info("counter reset")
end)
m:button("Randomize tint", function()
    tint:set({ math.random(), math.random(), math.random(), 1 })
end)

m:separator()
m:group("Helpers")
m:tooltip("Range", "Maximum range in Deadlock units.")
m:tooltip("Mode", "Behaviour selection. 0 = Safe, 1 = Fast, 2 = Insane.")

-- ──────── state ────────
local active   = false   -- flipped by the toggle key
local frameIx  = 0       -- monotonic per-frame counter for this life

-- ──────── life cycle ────────
callbacks.on_script_loaded(function()
    log.info("template loaded for script", __SCRIPT_NAME__)
end)

callbacks.on_local_spawn(function()
    log.info("spawned at curtime", Engine.GetCurTime())
    frameIx = 0
end)

callbacks.on_local_death(function()
    log.info("died at curtime", Engine.GetCurTime())
end)

-- ──────── per-frame logic ────────
callbacks.on_pre_createmove(function(cmd)
    if not enabled:get_bool() then return end

    if ImGui.IsKeyPressed(toggleKey:get_int()) then
        active = not active
        log.info("toggled", active and "ON" or "OFF")
    end

    if not active then return end

    -- e.g. auto-attack on melee targeting you
    local myH = Engine.GetLocalPlayerHandle()
    for _, e in ipairs(entity_list:enemies()) do
        local eH = e:get_handle()
        if e:has_modifier("melee_target_self") then
            cmd:AddButtonState(InputBitMask_t.IN_ATTACK)
            break
        end
    end
end)

callbacks.on_post_createmove(function(cmd)
    -- observation: log button state occasionally
    if frameIx % 600 == 0 and enabled:get_bool() then
        log.info(string.format("buttons=0x%x  curtime=%.2f",
            cmd:GetButtonState(), Engine.GetCurTime()))
    end
end)

callbacks.on_frame(function()
    if not enabled:get_bool() then return end
    frameIx = frameIx + 1
end)

-- ──────── rendering ────────
callbacks.on_render(function()
    if not enabled:get_bool() then return end

    -- Foreground draw-list HUD
    local s = Engine.GetScreenSize()
    render.filled_rect(s.w - 240, 20, 220, 80, 0, 0, 0, 0.55, 6)
    local c = tint:get_color()
    render.text(s.w - 230, 28, c[1], c[2], c[3], c[4],
        string.format("%s · mode=%s · armed=%s",
            __SCRIPT_NAME__, ({"Safe","Fast","Insane"})[mode:get_int() + 1],
            active and "ON" or "OFF"))
    render.text(s.w - 230, 48, 0.7, 0.7, 1, 1,
        string.format("range=%d  speed=%.2f  frames=%d",
            range:get_int(), speed:get_float(), frameIx))
    render.text(s.w - 230, 64, 0.5, 0.5, 0.5, 1,
        "note: " .. note:get_string())

    -- ImGui pop-up window with a button
    ImGui.SetNextWindowSize(260, 100)
    ImGui.SetNextWindowPos(s.w - 280, 120)
    ImGui.SetNextWindowBgAlpha(0.80)
    if ImGui.Begin("Template UI", ImGui.WindowFlags_NoSavedSettings + ImGui.WindowFlags_AlwaysAutoResize) then
        if ImGui.Button("Snapshot state", 200, 28) then
            storage.set("snapshot", {
                active = active,
                range  = range:get_int(),
                speed  = speed:get_float(),
                tint   = tint:get_color(),
            })
            log.info("snapshot saved")
        end
    end
    ImGui.End()
end)

-- ──────── key edge events ────────
callbacks.on_key_pressed(function(vk)
    if not enabled:get_bool() then return end
    -- only log alphanumeric
    if vk >= 0x41 and vk <= 0x5A then
        log.info("alpha key:", string.char(vk))
    end
end)

-- ──────── modifier deltas ────────
callbacks.on_add_modifier(function(mod, ent)
    if not enabled:get_bool() then return end
    if ent:get_handle() ~= Engine.GetLocalPlayerHandle() then return end
    log.info(string.format("modifier added to me: %s (%.2fs)", mod.name, mod:get_duration()))
end)

-- ──────── timers ────────
local beatId
callbacks.on_script_loaded(function()
    if beatId then timers.cancel(beatId) end
    beatId = timers.every(10000, function()
        if not enabled:get_bool() then return end
        log.info(string.format("heartbeat, frames=%d", frameIx))
    end)
end)