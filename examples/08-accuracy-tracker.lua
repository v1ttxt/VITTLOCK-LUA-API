--[[
    08 - Accuracy tracker
    A small panel with your shots, hits, accuracy and headshot rate for this
    match, plus your best accuracy ever, which is remembered between sessions.

    Shows: player_stats.all, the persistent db table, a button with a click
    handler, Render.Shadow / FilledRect for a panel.
]]

local group     = Menu.Create("Examples", "", "Accuracy", "", "Settings")
local enabled   = group:Switch("Enabled", true)
local min_shots = group:Slider("Shots before a best counts", 10, 500, 50)
group:Button("Reset best accuracy", function()
    db.accuracy_example = { best = 0 }
    print("best accuracy reset")
end)

-- One key of our own in the shared database.
if not db.accuracy_example then
    db.accuracy_example = { best = 0 }
end

local mine   -- my PlayerStatsRecord this frame, or nil

callback.on_frame:set(function()
    mine = nil
    if not enabled:Get() then return end

    for _, r in ipairs(player_stats.all()) do
        if r.is_local then
            mine = r
            break
        end
    end

    local store = db.accuracy_example
    if mine and mine.shots >= min_shots:Get() and mine.accuracy > (store.best or 0) then
        store.best = mine.accuracy
    end
end)

callback.on_draw:set(function()
    if not enabled:Get() or not mine then return end

    local lines = {
        ("Shots      %d"):format(mine.shots),
        ("Hits       %d"):format(mine.hits),
        ("Accuracy   %.1f%%"):format(mine.accuracy),
        ("Headshots  %.1f%%"):format(mine.headshot_percentage),
        ("Best       %.1f%%"):format(db.accuracy_example.best or 0),
    }

    local from = Vec2(20, 300)
    local to = from + Vec2(170, 14 + #lines * 18)
    Render.Shadow(from, to, Color(0, 0, 0, 120), 16, 8)
    Render.FilledRect(from, to, Menu.Style("main_background"), 8)
    for i, text in ipairs(lines) do
        Render.Text(0, 14, text, from + Vec2(10, 7 + (i - 1) * 18), Menu.Style("primary_widgets_text"))
    end
end)
