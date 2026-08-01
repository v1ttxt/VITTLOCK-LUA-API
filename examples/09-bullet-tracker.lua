-- 09-bullet-tracker.lua
-- Tracks every bullet fired in the game and shows an on-screen feed + counters.
-- Demonstrates: callbacks.on_bullet_create payload, render.text, storage for counts.

local m = ui.script()
m:category("Combat")

local enabled   = m:switch("Track bullets", false)
local logEach   = m:switch("Log to console", false)
local showFeed  = m:switch("Show on-screen feed", true)
local feedLines = m:slider_int("Lines", 1, 20, 8)

local lastEvents = {}   -- ring buffer
local function pushEvent(line)
    table.insert(lastEvents, line)
    while #lastEvents > feedLines:get_int() do table.remove(lastEvents, 1) end
end

callbacks.on_bullet_create(function(b)
    if not enabled:get_bool() then return end

    local line = string.format("%.2f  shooter=%d  team=%d  weapon=%s  range=%.0f",
        Engine.GetCurTime(),
        b.shooter_handle,
        b.team,
        b.weapon_name or "?",
        tonumber(b.range) or 0)
    pushEvent(line)

    if logEach:get_bool() then
        log.info(line)
    end

    storage.set("bullets_seen", (storage.get("bullets_seen") or 0) + 1)
end)

callbacks.on_render(function()
    if not enabled:get_bool() or not showFeed:get_bool() then return end

    local s = Engine.GetScreenSize()
    local x = s.w - 400
    local y = 80
    local w, h = 380, 16 + #lastEvents * 16

    render.filled_rect(x, y, w, h, 0, 0, 0, 0.5, 4)
    render.text(x + 8, y + 4, 0.5, 1.0, 0.5, 1,
        string.format("bullets: %d", storage.get("bullets_seen") or 0))

    for i, line in ipairs(lastEvents) do
        render.text(x + 8, y + 16 + (i - 1) * 16, 1, 1, 1, 1, line)
    end
end)