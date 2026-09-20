-- =========================================================================
-- VITTLOCK Lua - Icon & Font Inspector
-- Modern obsidian HUD with isolated badge tiles (no overlapping)
-- =========================================================================

local script_name = __SCRIPT_NAME__ or "IconTest"

-- Register mini-tab under "Visuals" -> "Icons"
local tab = Menu.Create("Visuals", "", script_name, "Icons")

-- Left Column: Layout and sizing controls
local left_card = tab:Create("Display Settings", Enum.GroupSide.Left)
local ui_enabled = left_card:Switch("Enabled", true)
local ui_pos_x   = left_card:Slider("HUD X", 0, 1920, 60)
local ui_pos_y   = left_card:Slider("HUD Y", 0, 1080, 60)
local ui_size    = left_card:Slider("Icon Size", 10, 22, 14)
local ui_glass   = left_card:Switch("Frosted Glass Background", true)

-- Right Column: Categories and toggles
local right_card = tab:Create("Icon Modules", Enum.GroupSide.Right)
local ui_show_fa        = right_card:Switch("FontAwesome Grid", true)
local ui_show_geometric = right_card:Switch("Geometric Shapes (▶, ●, ★, ⚠)", true)
local ui_show_arrows    = right_card:Switch("Directional Arrows (←, ↑, →, ↓)", true)
local ui_show_cyrillic  = right_card:Switch("Cyrillic Test (Russian Font Check)", false)

-- Verified FontAwesome 5 Solid glyphs
local fa_icons = {
    { glyph = "\xef\x80\x84", name = "Heart" },
    { glyph = "\xef\x81\x9b", name = "Crosshair" },
    { glyph = "\xef\x95\x8c", name = "Skull" },
    { glyph = "\xef\x8f\xad", name = "Shield" },
    { glyph = "\xef\x81\xae", name = "Eye" },
    { glyph = "\xef\x83\xa7", name = "Bolt" },
    { glyph = "\xef\x94\xa1", name = "Crown" },
    { glyph = "\xef\x81\xad", name = "Fire" },
    { glyph = "\xef\x9b\xa2", name = "Ghost" },
    { glyph = "\xef\x80\x85", name = "Star" },
    { glyph = "\xef\x80\x87", name = "User" },
    { glyph = "\xef\x80\x93", name = "Gear" },
    { glyph = "\xef\x80\x8c", name = "Check" },
    { glyph = "\xef\x85\x80", name = "Bullseye" },
    { glyph = "\xef\x80\xa3", name = "Lock" },
    { glyph = "\xef\x83\xb3", name = "Bell" }
}

-- Geometric shape test list
local geo_shapes = {
    { symbol = "▶", label = "Play" },
    { symbol = "●", label = "Dot" },
    { symbol = "■", label = "Box" },
    { symbol = "▲", label = "Up" },
    { symbol = "▼", label = "Down" },
    { symbol = "★", label = "Star" },
    { symbol = "⚠", label = "Alert" },
    { symbol = "◆", label = "Diamond" }
}

-- Directional arrows list
local arrow_list = { "←", "↑", "→", "↓", "↖", "↗", "↘", "↙" }

-- Universal value resolver (works across both legacy and modern widget bindings)
local function get_slider_val(w, fallback)
    if not w then return fallback end
    local v = nil
    if w.GetInt then v = w:GetInt() end
    if v == nil and w.GetFloat then v = w:GetFloat() end
    if v == nil and w.Get then
        local g = w:Get()
        if type(g) == "number" then v = g end
    end
    return v or fallback
end

callbacks.on_render(function()
    if not ui_enabled:GetBool() then return end

    local base_x  = get_slider_val(ui_pos_x, 60.0)
    local base_y  = get_slider_val(ui_pos_y, 60.0)
    local icon_sz = get_slider_val(ui_size, 14.0)
    if not icon_sz or icon_sz < 8 then icon_sz = 14.0 end

    local width   = 540.0
    local padding = 16.0
    local cur_y   = base_y + 14.0

    -- Dynamic height computation based on active modules
    local total_h = 56.0
    if ui_show_fa:GetBool()        then total_h = total_h + 200.0 end
    if ui_show_geometric:GetBool() then total_h = total_h + 65.0  end
    if ui_show_arrows:GetBool()    then total_h = total_h + 60.0  end
    if ui_show_cyrillic:GetBool()  then total_h = total_h + 75.0  end

    -- 1. Main Backdrop Container (Sleek Obsidian with soft shadow)
    if ui_glass:GetBool() then
        render.glass_rect(base_x, base_y, width, total_h, 10.0)
    else
        render.filled_rect(base_x - 2, base_y - 2, width + 4, total_h + 4, 0, 0, 0, 50, 12.0)
        render.filled_rect(base_x, base_y, width, total_h, 14, 16, 22, 240, 10.0)
        render.rect(base_x, base_y, width, total_h, 255, 255, 255, 28, 1.0, 10.0)
    end

    -- 2. Header: Logo, Title & Time Badge
    local time_str = os.date("%H:%M:%S")
    render.text(base_x + padding, cur_y + 1, 0, 220, 255, 255, "\xef\x81\x9b", 16, "fontawesome")
    render.text(base_x + padding + 24, cur_y + 1, 255, 255, 255, 255, "VITTLOCK ICON & GLYPH TESTER", 14)

    local tw, th = render.measure_text(time_str, 12)
    local pill_w = tw + 14
    local pill_x = base_x + width - padding - pill_w
    render.filled_rect(pill_x, cur_y, pill_w, 20, 24, 28, 38, 220, 4.0)
    render.rect(pill_x, cur_y, pill_w, 20, 255, 255, 255, 20, 1.0, 4.0)
    render.text(pill_x + 7, cur_y + 3, 175, 190, 215, 255, time_str, 12)

    cur_y = cur_y + 26.0
    render.line(base_x + padding, cur_y, base_x + width - padding, cur_y, 255, 255, 255, 20, 1.0)
    cur_y = cur_y + 10.0

    -- 3. FontAwesome Grid: Discrete isolated badge tiles (Centered icon & label)
    if ui_show_fa:GetBool() then
        render.text(base_x + padding, cur_y, 140, 150, 170, 255, "FONTAWESOME ICONS (16 TILES)", 11)
        cur_y = cur_y + 16.0

        local cols = 4
        local gap_x = 8.0
        local gap_y = 6.0
        local avail_w = width - (padding * 2)
        local tile_w = math.floor((avail_w - (gap_x * (cols - 1))) / cols)
        local tile_h = 36.0

        for i, item in ipairs(fa_icons) do
            local col = (i - 1) % cols
            local row = math.floor((i - 1) / cols)
            local tx = base_x + padding + (col * (tile_w + gap_x))
            local ty = cur_y + (row * (tile_h + gap_y))

            -- Tile background chip
            render.filled_rect(tx, ty, tile_w, tile_h, 20, 24, 34, 200, 6.0)
            render.rect(tx, ty, tile_w, tile_h, 255, 255, 255, 18, 1.0, 6.0)

            -- Icon rendered on the left, vertically centered
            local icon_x = tx + 10.0
            local icon_y = ty + math.floor((tile_h - icon_sz) * 0.5)
            render.text(icon_x, icon_y, 0, 220, 255, 255, item.glyph, icon_sz, "fontawesome")

            -- Label rendered on the right with guaranteed margin
            local label_x = tx + icon_sz + 18.0
            local label_y = ty + math.floor((tile_h - 12.0) * 0.5)
            render.text(label_x, label_y, 215, 220, 230, 255, item.name, 12)
        end

        local total_rows = math.ceil(#fa_icons / cols)
        cur_y = cur_y + (total_rows * (tile_h + gap_y)) + 10.0
    end

    -- 4. Geometric Shapes: Clean horizontal badge chips
    if ui_show_geometric:GetBool() then
        render.text(base_x + padding, cur_y, 140, 150, 170, 255, "GEOMETRIC SHAPES & SYMBOLS", 11)
        cur_y = cur_y + 16.0

        local chip_w = 54.0
        local chip_h = 28.0
        local gap = 8.0

        for i, item in ipairs(geo_shapes) do
            local cx = base_x + padding + ((i - 1) * (chip_w + gap))
            if (cx + chip_w) <= (base_x + width - padding) then
                -- Badge chip
                render.filled_rect(cx, cur_y, chip_w, chip_h, 22, 26, 36, 180, 5.0)
                render.rect(cx, cur_y, chip_w, chip_h, 255, 255, 255, 15, 1.0, 5.0)

                -- Symbol in warm gold
                render.text(cx + 8, cur_y + 5, 255, 215, 0, 255, item.symbol, 16)
                -- Compact label
                render.text(cx + 26, cur_y + 8, 180, 185, 195, 240, item.label, 10)
            end
        end

        cur_y = cur_y + chip_h + 12.0
    end

    -- 5. Directional Arrows: Compass chip row
    if ui_show_arrows:GetBool() then
        render.text(base_x + padding, cur_y, 140, 150, 170, 255, "DIRECTIONAL ARROWS", 11)
        cur_y = cur_y + 16.0

        local arrow_chip_w = 36.0
        local arrow_chip_h = 26.0
        local gap = 6.0

        for i, sym in ipairs(arrow_list) do
            local ax = base_x + padding + ((i - 1) * (arrow_chip_w + gap))
            render.filled_rect(ax, cur_y, arrow_chip_w, arrow_chip_h, 20, 24, 34, 180, 4.0)
            render.rect(ax, cur_y, arrow_chip_w, arrow_chip_h, 255, 255, 255, 15, 1.0, 4.0)

            -- Mint green arrow centered in chip
            render.text(ax + 12, cur_y + 4, 50, 255, 160, 255, sym, 16)
        end

        cur_y = cur_y + arrow_chip_h + 12.0
    end

    -- 6. Cyrillic Font Verification (Disabled by default, toggle in menu to test)
    if ui_show_cyrillic:GetBool() then
        render.text(base_x + padding, cur_y, 140, 150, 170, 255, "CYRILLIC SCRIPT VERIFICATION", 11)
        cur_y = cur_y + 16.0

        local card_w = width - (padding * 2)
        local card_h = 42.0

        render.filled_rect(base_x + padding, cur_y, card_w, card_h, 18, 21, 30, 200, 6.0)
        render.rect(base_x + padding, cur_y, card_w, card_h, 255, 255, 255, 15, 1.0, 6.0)

        local line1 = "▶ Игрок: Абрамс | Статус: В бою ● Здоровье: 100%"
        local line2 = "Тест кириллицы: Привет, мир! Всё работает без знаков вопроса (?)"

        render.text(base_x + padding + 10, cur_y + 6, 255, 120, 120, 255, line1, 13)
        render.text(base_x + padding + 10, cur_y + 22, 160, 230, 160, 255, line2, 12)
    end
end)
