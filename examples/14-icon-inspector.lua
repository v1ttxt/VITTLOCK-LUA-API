-- =========================================================================
-- 14-icon-inspector.lua
-- Demonstrates FontAwesome 6 icons, Unicode geometric shapes, Cyrillic, and sizing
-- =========================================================================

local script_name = __SCRIPT_NAME__ or "IconTest"

-- Register mini-tab under "Visuals" -> "Icons"
local tab = Menu.Create("Visuals", "", script_name, "Icons")

-- Left Column: Layout and sizing controls
local left_card = tab:Create("Display Settings", Enum.GroupSide.Left)
local ui_enabled = left_card:Switch("Enabled", true)
local ui_pos_x   = left_card:Slider("HUD X", 0, 1920, 80, "%.0f px")
local ui_pos_y   = left_card:Slider("HUD Y", 0, 1080, 80, "%.0f px")
local ui_size    = left_card:Slider("Icon Size", 12, 40, 20, "%.0f px")
local ui_glass   = left_card:Switch("Frosted Glass Background", true)

-- Right Column: Categories and palette
local right_card = tab:Create("Icon Modules", Enum.GroupSide.Right)
local ui_show_fa        = right_card:Switch("FontAwesome Grid", true)
local ui_show_geometric = right_card:Switch("Geometric Shapes (▶, ●, ★, ⚠)", true)
local ui_show_cyrillic  = right_card:Switch("Cyrillic & Unicode Strings", true)
local ui_show_arrows    = right_card:Switch("Directional Arrows (←, ↑, →, ↓)", true)
local ui_accent_color   = right_card:Color("Accent Color", { 0, 220, 255, 255 })

-- Pre-defined FontAwesome 6 glyph definitions
local fa_icons = {
    { glyph = "\xef\x80\x84", name = "Heart",     tag = "fa-heart" },
    { glyph = "\xef\x84\x9e", name = "Crosshair", tag = "fa-crosshairs" },
    { glyph = "\xef\x95\x8c", name = "Skull",     tag = "fa-skull" },
    { glyph = "\xef\x84\xb2", name = "Shield",    tag = "fa-shield" },
    { glyph = "\xef\x81\xae", name = "Eye",       tag = "fa-eye" },
    { glyph = "\xef\x83\xa7", name = "Bolt",      tag = "fa-bolt" },
    { glyph = "\xef\x94\xa1", name = "Crown",     tag = "fa-crown" },
    { glyph = "\xef\x81\xad", name = "Fire",      tag = "fa-fire" },
    { glyph = "\xef\x87\xa2", name = "Bomb",      tag = "fa-bomb" },
    { glyph = "\xef\x88\x99", name = "Gem",       tag = "fa-gem" },
    { glyph = "\xef\x80\x87", name = "User",      tag = "fa-user" },
    { glyph = "\xef\x80\x93", name = "Gear",      tag = "fa-gear" }
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
    local width    = 480.0
    local cur_y    = base_y + 14.0
    local padding  = 16.0

    local col_accent = ui_accent_color:GetColor()
    local ar = col_accent[1] or 0
    local ag = col_accent[2] or 220
    local ab = col_accent[3] or 255
    local aa = col_accent[4] or 255

    -- Estimate height dynamically for the glass backdrop
    local total_h = 60.0
    if ui_show_fa:GetBool()        then total_h = total_h + 130.0 end
    if ui_show_geometric:GetBool() then total_h = total_h + 65.0  end
    if ui_show_arrows:GetBool()    then total_h = total_h + 50.0  end
    if ui_show_cyrillic:GetBool()  then total_h = total_h + 75.0  end

    -- 1. Backdrop (Frosted glass or tinted pill)
    if ui_glass:GetBool() then
        render.glass_rect(base_x, base_y, width, total_h, 3, 10.0, { ar, ag, ab, 60 })
    else
        render.filled_rect(base_x, base_y, width, total_h, 15, 17, 22, 235, 10.0)
        render.rect(base_x, base_y, width, total_h, ar, ag, ab, 120, 1.0, 10.0)
    end

    -- 2. Header title with icon & dual-dimension measurement
    local header_title = "VITTLOCK ICON & GLYPH TESTER"
    local time_str = os.date("%H:%M:%S")
    render.text(base_x + padding, cur_y, ar, ag, ab, 255, "\xef\x84\x9e", 18, "fontawesome")
    render.text(base_x + padding + 26, cur_y + 1, 255, 255, 255, 255, header_title, 15)

    -- Time pill on right
    local tw, th = render.measure_text(time_str, 12)
    local pill_x = base_x + width - tw - padding - 10
    render.filled_rect(pill_x, cur_y, tw + 10, th + 4, 30, 34, 45, 200, 4.0)
    render.text(pill_x + 5, cur_y + 2, 180, 190, 210, 255, time_str, 12)

    cur_y = cur_y + 28.0
    render.line(base_x + padding, cur_y, base_x + width - padding, cur_y, 255, 255, 255, 30, 1.0)
    cur_y = cur_y + 10.0

    -- 3. FontAwesome Grid (4 columns)
    if ui_show_fa:GetBool() then
        render.text(base_x + padding, cur_y, 160, 170, 185, 255, "FONTAWESOME 6 ICONS", 12)
        cur_y = cur_y + 18.0

        local cols = 4
        local col_w = (width - (padding * 2)) / cols
        for i, item in ipairs(fa_icons) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local item_x = base_x + padding + (col * col_w)
            local item_y = cur_y + (row * (icon_sz + 10.0))

            -- Render the FontAwesome icon
            render.text(item_x, item_y, ar, ag, ab, 255, item.glyph, icon_sz, "fontawesome")
            
            -- Render label next to it
            render.text(item_x + icon_sz + 6, item_y + ((icon_sz - text_sz) * 0.5), 230, 235, 245, 255, item.name, text_sz)
        end

        local total_rows = math.ceil(#fa_icons / cols)
        cur_y = cur_y + (total_rows * (icon_sz + 10.0)) + 6.0
    end

    -- 4. Geometric Shapes (▶, ●, ■, etc.)
    if ui_show_geometric:GetBool() then
        render.text(base_x + padding, cur_y, 160, 170, 185, 255, "GEOMETRIC SHAPES & SYMBOLS", 12)
        cur_y = cur_y + 18.0

        local shape_x = base_x + padding
        for _, item in ipairs(geo_shapes) do
            -- Render symbol
            render.text(shape_x, cur_y, 255, 215, 0, 255, item.symbol, 18)
            local sw, _ = render.measure_text(item.symbol, 18)
            shape_x = shape_x + sw + 4

            -- Render compact name
            render.text(shape_x, cur_y + 2, 200, 205, 215, 220, item.symbol, 14)
            shape_x = shape_x + 28.0
        end

        cur_y = cur_y + 30.0
    end

    -- 5. Directional Arrows (←, ↑, →, ↓, ↖, ↗, ↘, ↙)
    if ui_show_arrows:GetBool() then
        render.text(base_x + padding, cur_y, 160, 170, 185, 255, "DIRECTIONAL ARROWS", 12)
        cur_y = cur_y + 18.0

        local arrow_x = base_x + padding
        for _, item in ipairs(arrow_list) do
            render.text(arrow_x, cur_y, 50, 255, 150, 255, item.symbol, 18)
            local aw, _ = render.measure_text(item.symbol, 18)
            arrow_x = arrow_x + aw + 16.0
        end

        cur_y = cur_y + 26.0
    end

    -- 6. Cyrillic & Extended Unicode String Rendering
    if ui_show_cyrillic:GetBool() then
        render.text(base_x + padding, cur_y, 160, 170, 185, 255, "CYRILLIC SCRIPT VERIFICATION", 12)
        cur_y = cur_y + 18.0

        -- Render sample game status in Cyrillic
        local line1 = "▶ Игрок: Абрамс | Статус: В бою ● Здоровье: 100%"
        local line2 = "Тест кириллицы: Привет, мир! Всё работает без знаков вопроса (?)"
        
        render.text(base_x + padding, cur_y, 255, 120, 120, 255, line1, 14)
        cur_y = cur_y + 18.0
        render.text(base_x + padding, cur_y, 180, 230, 180, 255, line2, 13)
    end
end)
