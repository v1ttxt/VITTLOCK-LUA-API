-- 03-enemy-esp-box.lua
-- Enemy ESP: 2D box around each enemy using WorldToScreen + bone positions.
-- Demonstrates: callbacks.on_render, m:color, entity_list:enemies,
-- Engine.GetBonePosition, Engine.WorldToScreen, render.rect.

local m = ui.script()
m:category("Visuals")

local enabled = m:switch("Enemy ESP", true)
local color   = m:color("Box tint", {1, 0.3, 0.3, 1})
local thick   = m:slider_float("Line thickness", 0.5, 4.0, 1.5)

callbacks.on_render(function()
    if not enabled:get_bool() then return end
    local c = color:get_color()
    local th = thick:get_float()

    for _, e in ipairs(entity_list:enemies()) do
        local head = Engine.GetBonePosition(e:get_handle(), "Head")
        local feet = e:get_origin()
        local pHead = Engine.WorldToScreen(head)
        local pFeet = Engine.WorldToScreen(feet)
        if pHead.visible and pFeet.visible then
            local h = pFeet.y - pHead.y
            if h > 5 then
                local w = h * 0.5
                render.rect(pHead.x - w * 0.5, pHead.y, w, h,
                    c[1], c[2], c[3], c[4], th, 0)
            end
        end
    end
end)