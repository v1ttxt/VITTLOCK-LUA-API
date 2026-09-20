-- =========================================================================
-- 14-icon-inspector.lua
-- Demonstrates FontAwesome icons, Unicode geometric shapes, Cyrillic, and sizing
-- =========================================================================

local script_name = __SCRIPT_NAME__ or "IconTest"

-- Register mini-tab under "Visuals" -> "Icons"
local tab = Menu.Create("Visuals", "", script_name, "Icons")

-- Left Column: Layout and sizing controls
local left_card = tab:Create("Display Settings", Enum.GroupSide.Left)
local ui_enabled = left_card:Switch("Enabled", true)
local ui_pos_x   = left_card:Slider("HUD X", 0, 1920, 60, "%.0f px")
local ui_pos_y   = left_card:Slider("HUD Y", 0, 1080, 60, "%.0f px")
local ui_size    = left_card:Slider("Icon Size", 12, 36, 18, "%.0f px")
local ui_glass   = left_card:Switch("Frosted Glass Background", true)

-- Right Column: Categories and palette
local right_card = tab:Create("Icon Modules", Enum.GroupSide.Right)
local ui_show_fa        = right_card:Switch("FontAwesome Grid", true)
local ui_show_geometric = right_card:Switch("Geometric Shapes (▶, ●, ★, ⚠)", true)
local ui_show_cyrillic  = right_card:Switch("Cyrillic & Unicode Strings", true)
local ui_show_arrows    = right_card:Switch("Directional Arrows (←, ↑, →, ↓)", true)

-- Verified FontAwesome 5 Solid glyphs
local fa_icons = {
    { glyph = "\xef\x80\x84", name = "Heart",      code = "F004" },
    { glyph = "\xef\x81\x9b", name = "Crosshair",  code = "F05B" },
    { glyph = "\xef\x95\x8c", name = "Skull",      code = "F54C" },
    { glyph = "\xef\x8f\xad", name = "Shield",     code = "F3ED" },
    { glyph = "\xef\x81\xae", name = "Eye",        code = "F06E" },
    { glyph = "\xef\x83\xa7", name = "Bolt",       code = "F0E7" },
    { glyph = "\xef\x94\xa1", name = "Crown",      code = "F521" },
    { glyph = "\xef\x81\xad", name = "Fire",       code = "F06D" },
    { glyph = "\xef\x9b\xa2", name = "Ghost",      code = "F6E2" },
    { glyph = "\xef\x80\x85", name = "Star",       code = "F005" },
    { glyph = "\xef\x80\x87", name = "User",       code = "F007" },
    { glyph = "\xef\x80\x93", name = "Gear",       code = "F013" },
    { glyph = "\xef\x80\x8c", name = "Check",      code = "F00C" },
    { glyph = "\xef\x85\x80", name = "Bullseye",   code = "F140" },
    { glyph = "\xef\x80\xa3", name = "Lock",       code = "F023" },
    { glyph = "\xef\x83\xb3", name = "Bell",       code = "F0F3" }
}

-- Geometric shape test list
local geo_shapes = {
    { symbol = "▶", label = "Play Triangle" },
    { symbol = "●", label = "Bullet Circle" },
    { symbol = "■", label = "Solid Square" },
    { symbol = "▲", label = "Triangle Up" },
    { symbol = "▼", label = "Triangle Down" },
    { symbol = "★", label = "Star" },
    { symbol = "⚠", label = "Warning" },
    { symbol = "✔", label = "Checkmark" },
    { symbol = "✖", label = "Multiply / Cross" }
}

-- Directional arrows list
local arrow_list = {
    { symbol = "←", label = "Left" },
    { symbol = "↑", label = "Up" },
    { symbol = "→", label = "Right" },
    { symbol = "↓", label = "Down" },
    { symbol = "↖", label = "Up-Left" },
    { symbol = "↗", label = "Up-Right" },
    { symbol = "↘", label = "Down-Right" },
    { symbol = "↙", label = "Down-Left" }
}

callbacks.on_render(function()
    if not ui_enabled:GetBool() then return end

    local base_x   = ui_pos_x:GetFloat()
    local base_y   = ui_pos_y:GetFloat()
    local icon_sz  = ui_size:GetFloat()
    local text_sz  = 13.0
    local width    = 490.0
    local cur_y    = base_y + 14.0
    local padding  = 16.0

    -- Accent palette (Cyan & White)
    local ar, ag, ab = 0, 220, 255

    -- Estimate height dynamically for the backdrop
    local total_h = 60.0
    if ui_show_fa:GetBool()        then total_h = total_h + (math.ceil(#fa_icons / 4) * (icon_sz + 10.0)) + 30.0 end
    if ui_show_geometric:GetBool() then total_h = total_h + 60.0  end
    if ui_show_arrows:GetBool()    then total_h = total_h + 50.0  end
    if ui_show_cyrillic:GetBool()  then total_h = total_h + 75.0  end

    -- 1. Dark obsidian frosted backdrop (No ugly yellow tint)
    if ui_glass:GetBool() then
        render.glass_rect(base_x, base_y, width, total_h, 10.0)
    else
        render.filled_rect(base_x, base_y, width, total_h, 14, 16, 22, 235, 10.0)
        render.rect(base_x, base_y, width, total_h, 255, 255, 255, 30, 1.0, 10.0)
    end

    -- 2. Header title with icon & dual-dimension measurement
    local header_title = "VITTLOCK ICON & GLYPH TESTER"
    local time_str = os.date("%H:%M:%S")
    render.text(base_x + padding, cur_y, ar, ag, ab, 255, "\xef\x81\x9b", 18, "fontawesome")
    render.text(base_x + padding + 26, cur_y + 1, 255, 255, 255, 255, header_title, 15)

    -- Time pill badge on top-right
    local tw, th = render.measure_text(time_str, 12)
    local pill_x = base_x + width - tw - padding - 12
    render.filled_rect(pill_x, cur_y, tw + 12, th + 4, 25, 28, 38, 220, 4.0)
    render.text(pill_x + 6, cur_y + 2, 180, 195, 220, 255, time_str, 12)

    cur_y = cur_y + 28.0
    render.line(base_x + padding, cur_y, base_x + width - padding, cur_y, 255, 255, 255, 25, 1.0)
    cur_y = cur_y + 10.0

    -- 3. FontAwesome Grid (4 columns)
    if ui_show_fa:GetBool() then
        render.text(base_x + padding, cur_y, 140, 150, 170, 255, "FONTAWESOME 6 ICONS", 11)
        cur_y = cur_y + 18.0

        local cols = 4
        local col_w = (width - (padding * 2)) / cols
        for i, item in ipairs(fa_icons) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local item_x = base_x + padding + (col * col_w)
            local item_y = cur_y + (row * (icon_sz + 10.0))

            -- Render the FontAwesome icon with font name "fontawesome"
            render.text(item_x, item_y, ar, ag, ab, 255, item.glyph, icon_sz, "fontawesome")
            
            -- Render label next to it
            render.text(item_x + icon_sz + 6, item_y + ((icon_sz - text_sz) * 0.5), 220, 225, 235, 255, item.name, text_sz)
        end

        local total_rows = math.ceil(#fa_icons / cols)
        cur_y = cur_y + (total_rows * (icon_sz + 10.0)) + 8.0
    end

    -- 4. Geometric Shapes (▶, ●, ■, etc.)
    if ui_show_geometric:GetBool() then
        render.text(base_x + padding, cur_y, 140, 150, 170, 255, "GEOMETRIC SHAPES & SYMBOLS", 11)
        cur_y = cur_y + 18.0

        local shape_x = base_x + padding
        for _, item in ipairs(geo_shapes) do
            -- Render symbol in Gold
            render.text(shape_x, cur_y, 255, 215, 0, 255, item.symbol, 18)
            local sw, _ = render.measure_text(item.symbol, 18)
            shape_x = shape_x + sw + 4

            -- Render compact label
            render.text(shape_x, cur_y + 2, 190, 195, 205, 220, item.symbol, 14)
            shape_x = shape_x + 26.0
        end

        cur_y = cur_y + 30.0
    end

    -- 5. Directional Arrows (←, ↑, →, ↓, ↖, ↗, ↘, ↙)
    if ui_show_arrows:GetBool() then
        render.text(base_x + padding, cur_y, 140, 150, 170, 255, "DIRECTIONAL ARROWS", 11)
        cur_y = cur_y + 18.0

        local arrow_x = base_x + padding
        for _, item in ipairs(arrow_list) do
            render.text(arrow_x, cur_y, 50, 255, 160, 255, item.symbol, 18)
            local aw, _ = render.measure_text(item.symbol, 18)
            arrow_x = arrow_x + aw + 16.0
        end

        cur_y = cur_y + 26.0
    end

    -- 6. Cyrillic & Extended Unicode String Rendering
    if ui_show_cyrillic:GetBool() then
        render.text(base_x + padding, cur_y, 140, 150, 170, 255, "CYRILLIC SCRIPT VERIFICATION", 11)
        cur_y = cur_y + 18.0

        -- Render sample game status in Cyrillic
        local line1 = "▶ Игрок: Абрамс | Статус: В бою ● Здоровье: 100%"
        local line2 = "Тест кириллицы: Привет, мир! Всё работает без знаков вопроса (?)"
        
        render.text(base_x + padding, cur_y, 255, 120, 120, 255, line1, 14)
        cur_y = cur_y + 18.0
        render.text(base_x + padding, cur_y, 160, 230, 160, 255, line2, 13)
    end
end)
