# Input

The `input` table reads the keyboard, mouse buttons, scroll wheel and cursor. Use it for hotkeys and for mouse interaction with things you draw. Keys are identified by `Enum.ButtonCode` values, the same codes the menu's key binds and [`on_key_event`](callbacks.md#on_key_eventdata) use.

To send buttons to the game (fire, jump, cast), change the user command instead: see [usercmd](usercmd.md).

## Functions

### `input.is_down(key)`
Returns `true` while the key or mouse button is held.

- `key` (integer): an `Enum.ButtonCode` value.
- For `KEY_MWHEELUP` / `KEY_MWHEELDOWN` it returns `true` on the frame the wheel turned in that direction.
- Reads the key's state at the moment of the call, from any callback.
- It does not care whether the menu or a text box has focus. Check `input.has_free_cursor()` if your hotkey shouldn't fire while the player is using a cursor.

### `input.is_pressed(key)`
Returns `true` on the frame the key or mouse button went down: it is down now and was up on the previous frame. For the wheel codes, `true` on the frame the wheel turned.

- `key` (integer): an `Enum.ButtonCode` value.
- The state updates once per frame, just before `on_frame`. Read it in `on_frame`. Commands are not built once per frame, so in `on_createmove` a press can be missed or seen twice. To act on a press in a command, set a flag in `on_frame` and consume it in `on_createmove` (see the example below).

### `input.cursor_pos()`
Returns the mouse cursor position as a `Vec2` in screen pixels, with (0, 0) at the top-left. Returns (0, 0) before the overlay is ready.

### `input.cursor_in_bounds(a, b)`
Returns `true` if the cursor is inside the rectangle spanned by the corners `a` and `b`, edges included.

| Name | Type | Description |
|---|---|---|
| `a` | Vec2 | One corner. |
| `b` | Vec2 | The opposite corner. The corners can be given in any order. |

### `input.has_free_cursor()`
Returns `true` while the cursor is free to point at things: the VITTLOCK menu is open, or the game's free cursor or shop is up (as of the last user command).

## Example

```lua
local BC = Enum.ButtonCode
local IN = InputBitMask_t

local enabled = false
local want_reload = false

callback.on_frame:set(function()
    -- F6 toggles the feature (only while the player isn't using a cursor).
    if input.is_pressed(BC.KEY_F6) and not input.has_free_cursor() then
        enabled = not enabled
        print("enabled: " .. tostring(enabled))
    end
    -- Middle mouse queues one reload for the next command.
    if enabled and input.is_pressed(BC.KEY_MOUSE3) then
        want_reload = true
    end
end)

callback.on_createmove:set(function(cmd)
    if want_reload then
        want_reload = false
        cmd:pulse(IN.IN_RELOAD)
    end
end)

-- A clickable box drawn while the menu is open.
local box_min, box_max = Vec2(100, 100), Vec2(260, 140)
callback.on_frame:set(function()
    if input.has_free_cursor() and input.cursor_in_bounds(box_min, box_max) and input.is_pressed(BC.KEY_MOUSE1) then
        print("box clicked at " .. tostring(input.cursor_pos()))
    end
end)
```

## Key events

For every key press and release (not only the ones you poll), use `callback.on_key_event`. The handler gets a table with `key` (an `Enum.ButtonCode` value) and `event` (an `Enum.KeyEvent` value). Held keys don't send repeat events. Returning `false` keeps the message from the menu and the game window, though the game may still read the key through its own input. See [callbacks](callbacks.md#on_key_eventdata).

| `Enum.KeyEvent` | Value |
|---|---|
| `SCROLL_DOWN` | 0 |
| `SCROLL_UP` | 1 |
| `KEY_DOWN` | 2 |
| `KEY_UP` | 3 |

```lua
callback.on_key_event:set(function(e)
    if e.event == Enum.KeyEvent.KEY_DOWN and e.key == Enum.ButtonCode.KEY_F7 then
        print("F7 down")
    end
end)
```

## Key codes (Enum.ButtonCode)

| Name | Value |
|---|---|
| `BUTTON_CODE_INVALID` | -1 |
| `BUTTON_CODE_NONE`, `KEY_NONE`, `KEY_FIRST` | 0 |
| `KEY_0` .. `KEY_9` | 1 .. 10 |
| `KEY_A` .. `KEY_Z` | 11 .. 36 |
| `KEY_PAD_0` .. `KEY_PAD_9` | 37 .. 46 |
| `KEY_PAD_DIVIDE`, `KEY_PAD_MULTIPLY`, `KEY_PAD_MINUS`, `KEY_PAD_PLUS`, `KEY_PAD_ENTER`, `KEY_PAD_DECIMAL` | 47 .. 52 |
| `KEY_LBRACKET`, `KEY_RBRACKET` | 54, 55 |
| `KEY_SEMICOLON`, `KEY_APOSTROPHE`, `KEY_BACKQUOTE`, `KEY_COMMA`, `KEY_PERIOD`, `KEY_SLASH`, `KEY_BACKSLASH`, `KEY_MINUS`, `KEY_EQUAL` | 56 .. 64 |
| `KEY_ENTER`, `KEY_SPACE`, `KEY_BACKSPACE`, `KEY_TAB` | 65 .. 68 |
| `KEY_CAPSLOCK`, `KEY_NUMLOCK`, `KEY_ESCAPE`, `KEY_SCROLLLOCK` | 69 .. 72 |
| `KEY_INSERT`, `KEY_DELETE`, `KEY_HOME`, `KEY_END`, `KEY_PAGEUP`, `KEY_PAGEDOWN`, `KEY_BREAK` | 73 .. 79 |
| `KEY_LSHIFT`, `KEY_RSHIFT`, `KEY_LALT`, `KEY_RALT`, `KEY_LCONTROL`, `KEY_RCONTROL` | 80 .. 85 |
| `KEY_LWIN`, `KEY_RWIN`, `KEY_APP` | 86 .. 88 |
| `KEY_UP`, `KEY_LEFT`, `KEY_DOWN`, `KEY_RIGHT` | 89 .. 92 |
| `KEY_F1` .. `KEY_F12` | 93 .. 104 |
| `KEY_CAPSLOCKTOGGLE`, `KEY_NUMLOCKTOGGLE`, `KEY_SCROLLLOCKTOGGLE` | 105 .. 107 |
| `KEY_MOUSE1` (left), `KEY_MOUSE2` (right), `KEY_MOUSE3` (middle) | 314 .. 316 |
| `KEY_MOUSE4`, `KEY_MOUSE5` (side buttons) | 317, 318 |
| `KEY_MWHEELUP`, `KEY_MWHEELDOWN` | 319, 320 |

Values in a range follow the order listed (for example `KEY_A` = 11, `KEY_B` = 12).
