--[[
    04 - Rapid fire key
    While the bound key is held, taps the fire button every few commands, for
    weapons that need a click per shot. Releases nothing you are holding
    yourself: it only adds taps.

    Shows: Bind widget, callback.on_createmove, cmd:pulse, InputBitMask_t,
    skipping commands so pulse can re-arm.
]]

local group   = Menu.Create("Examples", "", "Rapid Fire", "", "Settings")
local enabled = group:Switch("Enabled", false)
local key     = group:Bind("Hold key", Enum.ButtonCode.KEY_LALT)
local every   = group:Slider("Tap every N commands", 2, 10, 3)

enabled:ToolTip("Hold the key to tap fire repeatedly.")
every:ToolTip("2 is the fastest: pulse needs one command without a tap to re-arm.")

local counter = 0

callback.on_createmove:set(function(cmd)
    if not enabled:Get() or not key:IsDown() then
        counter = 0
        return
    end
    if cmd.in_shop or cmd.using_free_cursor then return end

    counter = counter + 1
    if counter % every:Get() == 1 then
        cmd:pulse(InputBitMask_t.IN_ATTACK)
    end
end)
