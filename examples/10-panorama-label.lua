--[[
    10 - Panorama label
    Adds a text label to the game's own HUD (a real game UI panel, not an
    overlay drawing) that shows the game time, and removes it when turned off.

    Shows: panorama.get_panel_by_id, panorama.create_panel, uipanel methods,
    panel lifetime (is_valid, delete_async). Panorama calls are only allowed
    in on_frame / on_createmove.
]]

local group   = Menu.Create("Examples", "", "HUD Label", "", "Settings")
local enabled = group:Switch("Enabled", true)

local STYLE = "horizontal-align: center; y: 64px; font-size: 22px; color: #ffffffdd;"
              .. " text-shadow: 0px 1px 3px 0.0 #000000ee;"

local label   -- our uipanel, or nil

local function remove_label()
    if label and label:is_valid() then
        label:delete_async(0)
    end
    label = nil
end

callback.on_frame:set(function()
    if not enabled:Get() or not entity_list.local_pawn() then
        remove_label()
        return
    end

    -- The HUD is rebuilt on map changes: create the label again when it's gone.
    if not label or not label:is_valid() then
        local hud = panorama.get_panel_by_id("Hud")
        if not hud then return end
        label = panorama.create_panel("Label", "example_clock_label", hud, "", STYLE)
        if not label then return end
    end

    local t = math.max(game_rules.game_time(), 0)
    label:set_text(("%02d:%02d"):format(math.floor(t / 60), math.floor(t % 60)))
end)
