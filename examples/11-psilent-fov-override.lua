-- Native pSilent FOV override.
-- Menu.Find cannot access native CAimbot controls; use the aimbot module.

local menu = ui.script()
menu:category("Examples")

local enabled = menu:switch("Override pSilent FOV", false)
local target_fov = menu:slider_float("Target pSilent FOV", 10, 500, 170)
local last_applied = nil

callbacks.on_frame(function()
    if not enabled:get_bool() then
        last_applied = nil
        return
    end

    local wanted = target_fov:get_float()
    if wanted == last_applied then return end

    if aimbot.set("psilent_fov", wanted) then
        last_applied = wanted
    else
        log.error("unable to set native psilent_fov")
    end
end)
