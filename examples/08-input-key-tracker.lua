-- 08-input-key-tracker.lua
-- Captures every key press ↔ release worldwide and logs the modulo-256 VK.
-- Demonstrates: callbacks.on_key_pressed / on_key_released.

local m = ui.script()
m:category("Info")

local enable   = m:switch("Track keys", false)
local onlyPrintable = m:switch("Only printable (vk 0x20..0x7E)", true)

local function shouldLog(vk)
    if not onlyPrintable:get_bool() then return true end
    return vk >= 0x20 and vk <= 0x7E
end

callbacks.on_key_pressed(function(vk)
    if not enable:get_bool() then return end
    if not shouldLog(vk) then return end
    log.info(string.format("KEYDOWN: 0x%02X (%d)", vk, vk))
end)

callbacks.on_key_released(function(vk)
    if not enable:get_bool() then return end
    if not shouldLog(vk) then return end
    log.info(string.format("KEYUP:   0x%02X (%d)", vk, vk))
end)