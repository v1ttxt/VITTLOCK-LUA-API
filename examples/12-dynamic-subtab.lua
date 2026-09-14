--[[
    12-dynamic-subtab.lua - Dedicated Script Sub-Tab & Two-Column Cards
    Demonstrates:
      - Menu.CreateSubTab() to register a top-level tab in the Lua menu
      - subtab:Section() / subtab:Card() to split controls into left and right columns
      - MultiCombo with string and bitmask checks
      - ColorPicker with FontAwesome icons
      - Reactive visibility updates with SetCallback()
]]

local script_name = __SCRIPT_NAME__ or "DemoHero"

-- 1. Register dedicated sub-tab in the Lua menu
local subtab = Menu.CreateSubTab(script_name, "Demo Hero", "combat")

-- 2. Left Card: Combat Mechanics
local left_card = subtab:Section("Combat & Targeting")

local enabled = left_card:Switch("Auto Combo", true)
enabled:ToolTip("Executes target combo when enemy enters range.")

local targets = left_card:MultiCombo("Targets", { "Heroes", "Troopers", "Bosses" }, { "Heroes" })
targets:ToolTip("Filter target types to prioritize.")

local range = left_card:Slider("Activation Range", 10.0, 100.0, 45.0, "%.1fm")
local delay = left_card:Slider("Cast Delay", 0.0, 1.0, 0.2, "%.2fs")

-- 3. Right Card: Visuals & Overlays
local right_card = subtab:Section("Visual Overlays")

local show_fov = right_card:Switch("Draw Range Circle", true)
local fov_color = right_card:ColorPicker("Circle Color", Color(120, 220, 255, 255))
local show_trail = right_card:Switch("Target Trail", false)
local trail_duration = right_card:Slider("Trail Duration", 0.1, 2.0, 0.5, "%.2fs")

-- Reactive visibility: only show trail slider when trail toggle is active
show_trail:SetCallback(function(w)
    trail_duration:Visible(w:Get())
end, true)

-- 4. Main Event Tick
callbacks.on_post_createmove(script_name, function(cmd)
    if not enabled:Get() then return end

    local local_pawn = entity_list.local_pawn()
    if not local_pawn or not local_pawn:valid() or not local_pawn:is_alive() then
        return
    end

    -- Target selection logic...
    local check_heroes = targets:Get("Heroes")
    local check_troopers = targets:Get("Troopers")
    -- Combo execution logic...
end)

callbacks.on_render(script_name, function()
    if not enabled:Get() or not show_fov:Get() then return end

    local local_pawn = entity_list.local_pawn()
    if not local_pawn or not local_pawn:valid() then return end

    -- Draw range ring on local origin
    local origin = local_pawn:get_origin()
    local screen_pos, on_screen = Render.WorldToScreen(origin)
    if on_screen then
        Render.Circle(screen_pos, range:Get() * 3.5, fov_color:Get(), 1.5)
    end
end)
