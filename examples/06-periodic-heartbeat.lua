-- 06-periodic-heartbeat.lua
-- Every N seconds: log a counter and heartbeat.
-- Demonstrates: timers.every + storage for state, m:button to reset.

local m = ui.script()
m:category("Utility")

local master = m:switch("Heartbeat", true)
local period  = m:slider_int("Period (ms)", 1000, 60000, 5000)

m:button("Reset counter", function()
    storage.set("n", 0)
    log.info("counter reset by user")
end)

-- Remember the timer id so we can swap periods
local timerId = nil
local function startHeartbeat()
    if timerId then timers.cancel(timerId) end
    timerId = timers.every(period:get_int(), function()
        if not master:get_bool() then return end
        local n = (storage.get("n") or 0) + 1
        storage.set("n", n)
        log.info(string.format("beat %d @ curtime %.1f", n, Engine.GetCurTime()))
    end)
end

callbacks.on_script_loaded(function()
    startHeartbeat()
    log.info("heartbeat started, period=", period:get_int(), "ms")
end)