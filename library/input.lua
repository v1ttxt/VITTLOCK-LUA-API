---@meta
-- input: keyboard and mouse state, cursor position

---Keyboard, mouse and cursor state. Key codes are `Enum.ButtonCode` values.
---@class input
input = {}

---True while the key or mouse button is held. For KEY_MWHEELUP / KEY_MWHEELDOWN: true on the frame the wheel turned.
---@param key Enum.ButtonCode|integer Key code
---@return boolean down
function input.is_down(key) end

---True on the frame the key or mouse button went down (it was up on the previous frame). For the wheel codes: true on the frame the wheel turned.
---@param key Enum.ButtonCode|integer Key code
---@return boolean pressed
function input.is_pressed(key) end

---The mouse cursor position in screen pixels (top-left is 0, 0).
---@return Vec2 pos
function input.cursor_pos() end

---True if the cursor is inside the rectangle spanned by two corners (any order, edges included).
---@param a Vec2 One corner
---@param b Vec2 The opposite corner
---@return boolean inside
function input.cursor_in_bounds(a, b) end

---True while the cursor is free to point at things: the VITTLOCK menu is open, or the game's free cursor or shop is up.
---@return boolean free
function input.has_free_cursor() end
