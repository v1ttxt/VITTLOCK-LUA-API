-- 13-custom-fonts-and-images.lua
-- Demonstrates dynamic text sizing, custom fonts, Cyrillic/FontAwesome,
-- image textures, filled polygons, frosted glass, and os.date.

local m = ui.script()
m:category("Examples")

local enabled = m:switch("Enable Render Demo", true)

-- Load an optional system font
local custom_font = render.load_font("DemoSegoe", "C:/Windows/Fonts/segoeui.ttf", 22)
local logo_img = render.load_image("C:/VITTLOCK/assets/logo.png")

callbacks.on_render(function()
    if not enabled:get_bool() then return end

    -- 1. Frosted glass backdrop panel
    render.glass_rect(40, 40, 380, 230, 3, 10.0, { 255, 255, 255, 35 })

    -- 2. Custom font & dynamic text sizing
    render.text(55, 55, 255, 255, 255, 255, "VITTLOCK RENDER ENGINE", 20, "DemoSegoe")
    
    -- 3. Cyrillic & Unicode geometric symbols
    render.text(55, 85, 100, 220, 255, 255, "▶ Игрок: Абрамс | Статус: В игре ●", 15)
    
    -- 4. FontAwesome 6 icons
    render.text(55, 110, 255, 100, 100, 255, "\xef\x80\x84", 18, "fontawesome") -- Heart
    render.text(80, 110, 200, 200, 200, 255, "Icon Atlas Support", 14)

    -- 5. Dual-dimension measurement & standard os.date
    local time_str = os.date("Time: %H:%M:%S")
    local tw, th = render.measure_text(time_str, 14)
    render.filled_rect(55, 140, tw + 12, th + 8, 20, 20, 25, 220, 4)
    render.text(61, 144, 255, 200, 80, 255, time_str, 14)

    -- 6. Filled polygon & outline
    local poly = { { 330, 130 }, { 365, 175 }, { 295, 175 } }
    render.filled_polygon(poly, 80, 200, 120, 180)
    render.polygon(poly, 255, 255, 255, 255, true, 1.5)

    -- 7. Custom disk image & Panorama texture
    if logo_img then
        render.image(logo_img, 55, 180, 36, 36)
    end
    render.panorama_image("panorama/images/items/weapon/blood_tribute_psd.vtex_c", 100, 180, 36, 36)
end)
