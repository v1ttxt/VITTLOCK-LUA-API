--[[
    07 - Status alerts
    Shows a notification card when you get stunned, silenced or immobilized,
    with how long it lasts, and logs who applied new effects to you.

    Shows: entity:has_modifier_state, get_modifier_state_remaining_duration,
    EModifierState, Notification, callback.on_add_modifier, MultiCombo.
]]

local group   = Menu.Create("Examples", "", "Status Alerts", "", "Settings")
local enabled = group:Switch("Enabled", true)
local which   = group:MultiCombo("Alert on", { "Stunned", "Silenced", "Immobilized" },
                                 { "Stunned", "Silenced", "Immobilized" })
local log_mods = group:Switch("Log effects applied to me", false)

local STATES = {
    { label = "Stunned",     state = EModifierState.MODIFIER_STATE_STUNNED },
    { label = "Silenced",    state = EModifierState.MODIFIER_STATE_SILENCED },
    { label = "Immobilized", state = EModifierState.MODIFIER_STATE_IMMOBILIZED },
}

local was_active = {}

callback.on_frame:set(function()
    local me = entity_list.local_pawn()
    if not enabled:Get() or not me or not me:is_alive() then
        was_active = {}
        return
    end

    for _, s in ipairs(STATES) do
        local active = me:has_modifier_state(s.state)
        -- Only on the moment it starts, not every frame it lasts.
        if active and not was_active[s.label] and which:Get(s.label) then
            local left = me:get_modifier_state_remaining_duration(s.state)
            Notification({
                id             = "status_" .. s.label,
                primary_text   = s.label .. "!",
                secondary_text = left > 0 and ("%.1f seconds"):format(left) or nil,
                timer          = left > 0 and left or nil,
                duration       = math.max(left, 1.5),
                active         = true,
            })
        end
        was_active[s.label] = active
    end
end)

callback.on_add_modifier:set(function(mod, target, owner)
    if not log_mods:Get() then return end
    local me = entity_list.local_pawn()
    if not me or not target or target ~= me then return end
    local from = owner and owner:get_name() or "unknown"
    print(("%s from %s (%.1f s)"):format(mod:get_name(), from, mod:get_remaining_duration()))
end)
