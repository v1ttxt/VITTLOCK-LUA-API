--[[
    lib/example_draw.lua - a small drawing helper module, used by 11-modules.lua.

    Files in scripts\v2\lib\ are not run as scripts: they only run when a
    script requires them, once per session. Copy this file to
    C:\VITTLOCK\scripts\v2\lib\example_draw.lua.
]]

local M = {}

--- A rounded panel with a soft shadow, in the menu's colours.
---@param from Vec2
---@param to Vec2
function M.panel(from, to)
    Render.Shadow(from, to, Color(0, 0, 0, 110), 14, 8)
    Render.FilledRect(from, to, Menu.Style("main_background"), 8)
    Render.Rect(from, to, Menu.Style("outline"), 8)
end

--- Text with a 1 px shadow.
---@param text string
---@param pos Vec2
---@param size number
---@param color Color
function M.text(text, pos, size, color)
    Render.Text(0, size, text, pos + Vec2(1, 1), Color(0, 0, 0, 200))
    Render.Text(0, size, text, pos, color)
end

--- A horizontal bar filled to `frac` (0-1).
---@param from Vec2
---@param to Vec2
---@param frac number
---@param color Color
function M.bar(from, to, frac, color)
    frac = math.min(math.max(frac, 0), 1)
    Render.FilledRect(from, to, Color(0, 0, 0, 150), 3)
    if frac > 0 then
        Render.FilledRect(from, Vec2(from.x + (to.x - from.x) * frac, to.y), color, 3)
    end
end

return M
