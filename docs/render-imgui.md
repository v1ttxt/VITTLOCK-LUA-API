# `render` & `ImGui`

VITTLOCK provides two overlapping drawing layers:

- **`ImGui.*`** — direct ImGui calls through the game's ImGui context. Use for transient popup windows, buttons, lists, table layouts in your own script-side UI.
- **`render.*`** — thin wrappers over `ImGui::GetForegroundDrawList()`. Use for screen-pixel-prefixed HUD: ESP boxes, text overlays, lines, circles.

There's also a `Render.*` legacy namespace whose calls route to `render.*`.

---

## `render` — foreground draw list

Coordinates are screen pixels (`0..(w-1), 0..(h-1)` where `w=ImGui::GetIO().DisplaySize.x`). Colours are `0..1` floats RGBA. All functions write to `ImGui::GetForegroundDrawList()`, which renders over the entire game viewport.

| Function | Signature | What it does |
|---|---|---|
| `render.line(x1, y1, x2, y2, r, g, b, a, thick)` | drawn as a line segment from `(x1,y1)` to `(x2,y2)` |
| `render.rect(x, y, w, h, r, g, b, a, thick, rounding)` | rectangle outline, top-left = `(x,y)`, size = `(w,h)`, corners rounded by `rounding` px |
| `render.filled_rect(x, y, w, h, r, g, b, a, rounding)` | filled rectangle, otherwise same args |
| `render.circle(x, y, radius, r, g, b, a, segments, thick)` | outlined circle |
| `render.text(x, y, r, g, b, a, s)` | text at screen coords (woff used; uses current ImGui font) |

### Common recipes

#### ESP score banner

```lua
callbacks.on_render(function()
    local s = Engine.GetScreenSize()
    render.filled_rect(s.w - 220, 10, 200, 50, 0, 0, 0, 0.5, 6)
    render.text(s.w - 210, 18, 0, 1, 1, 1, "ALIVE")
    render.text(s.w - 210, 40, 1, 0.4, 0.4, 1, string.format("speed %.0f", Engine.GetLocalVelocity():Length2D()))
end)
```

#### Tracer line from screen-bottom to head

```lua
callbacks.on_render(function()
    local s = Engine.GetScreenSize()
    local cx = s.w * 0.5
    local cy = s.h
    for _, e in ipairs(entity_list:enemies()) do
        local head = Engine.GetBonePosition(e:get_handle(), "Head")
        local p = Engine.WorldToScreen(head)
        if p.visible then
            render.line(cx, cy, p.x, p.y, 1.0, 0.3, 0.3, 0.7, 1.5)
        end
    end
end)
```

#### Health-bar UI

```lua
local function drawBar(x, y, w, h, frac, col)
    render.filled_rect(x, y, w, h, 0, 0, 0, 0.8, 0)
    render.filled_rect(x + 1, y + 1, (w - 2) * frac, h - 2, col[1], col[2], col[3], col[4], 0)
end

callbacks.on_render(function()
    for _, e in ipairs(entity_list:enemies()) do
        local feet = Engine.WorldToScreen(e:get_origin())
        if feet.visible then
            drawBar(feet.x - 30, feet.y - 50, 60, 6, 0.5, {1, 0.2, 0.2, 1})
        end
    end
end)
```

---

## `ImGui` — primitives

The full bindings surface. Everything works inside `on_render` because that's the only place where the ImGui frame is active.

### Window lifecycle — Always call `End()`

```lua
if ImGui.Begin("My Window", ImGui.WindowFlags_AlwaysAutoResize) then
    -- widgets
end
ImGui.End()   -- always call
```

The `Begin` returns `false` when the window is collapsed/clipped but you must still pop the scope — `ImGui.End` must always be called.

### Window flags (integer bitmask — sum with `+`)

| Constant | Effect |
|---|---|
| `ImGui.WindowFlags_NoTitleBar` | No title bar |
| `ImGui.WindowFlags_NoResize` | Not resizable |
| `ImGui.WindowFlags_NoScrollbar` | Suppress scrollbars |
| `ImGui.WindowFlags_NoInputs` | Ignore all inputs |
| `ImGui.WindowFlags_NoBackground` | Fully transparent |
| `ImGui.WindowFlags_AlwaysAutoResize` | Size to content each frame |
| `ImGui.WindowFlags_NoNav` | Not focusable |
| `ImGui.WindowFlags_NoDecoration` | Combo of NoTitleBar+NoResize+NoScrollbar+NoCollapse |
| `ImGui.WindowFlags_NoFocusOnAppearing` | Don't steal focus on first show |
| `ImGui.WindowFlags_NoSavedSettings` | Don't persist position/size |

### Text widgets

| Function | Signature |
|---|---|
| `ImGui.Text(s)` | draw text via `TextUnformatted` |
| `ImGui.TextColored(r, g, b, a, s)` | colored text |

```lua
ImGui.TextColored(0.4, 1.0, 0.4, 1.0, "alive")
ImGui.TextColored(1.0, 0.4, 0.4, 1.0, "down")
```

### Buttons & checkboxes

| Function | Returns |
|---|---|
| `ImGui.Button(label, w, h)` | bool — `true` on click |
| `ImGui.Checkbox(label, value)` | **`(changed, newValue)`** as a Lua multi-return — both values matter |

```lua
-- Toggle state with ImGui.Checkbox
local enabled = false
callbacks.on_render(function()
    if ImGui.Begin("Test") then
        local changed, val = ImGui.Checkbox("Toggle me", enabled)
        if changed then enabled = val end
    end
    ImGui.End()
end)
```

⚠️ `ImGui.Checkbox` returns `(changed, value)` as a Lua multi-return. Both values matter — the first tells you whether the user clicked this frame, the second is the visible checkbox state.

### Layout helpers

| Function | Note |
|---|---|
| `ImGui.SetNextWindowPos(x, y)` | Absolute, always |
| `ImGui.SetNextWindowSize(w, h)` | First-use-only cond |
| `ImGui.SetNextWindowBgAlpha(a)` | 0..1 |
| `ImGui.BeginChild(id, w, h, border)` | Scrolling region — bool |
| `ImGui.EndChild()` | |
| `ImGui.SetScrollHereY(ratio)` | Scroll to ratio (0=top, 1=bottom) |
| `ImGui.SameLine()` | Stay on same line |
| `ImGui.Separator()` | Horizontal rule |
| `ImGui.Spacing()` | Vertical spacing |

### Input

| Function | Note |
|---|---|
| `ImGui.GetTime()` | Seconds since ImGui context creation |
| `ImGui.IsKeyPressed(vk)` | True the frame the key went down — uses `GetAsyncKeyState(vk) & 0x1` |
| `ImGui.IsKeyDown(vk)` | True while held — `GetAsyncKeyState(vk) & 0x8000` |

`vk` is a Win32 virtual-key code — `0x2D`=`VK_INSERT`, `0x56`='V', etc. See [Win32 VK table](https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes).

⚠️ `IsKeyPressed` checks `GetAsyncKeyState & 0x1`, which is the *since-last-query* bit. This is reliably per-frame only when called once per frame — if you query the same key twice in a frame, the second will read `false`. Cache results.

---

## `Render.*` — legacy alias

Old scripts used `Render.Text/FilledRect/Line/Poly`. All still work — they shim to `render.*`:

```lua
Render.Text(x, y, r, g, b, a, "hi")          -- routes to render.text
Render.FilledRect(x, y, w, h, r, g, b, a)    -- routes to render.filled_rect, rounding=0
Render.Line(x1, y1, x2, y2, r, g, b, a)      -- routes to render.line, thick=1.0
Render.Poly(...)                              -- no-op; returns nil
```

The legacy shims are defined as a Lua blob internally. They exist purely so existing scripts using `Render.Text` keep working. The signature differences: `Render.FilledRect` doesn't take `rounding`; `Render.Line` doesn't take `thick`. Defaults: rounding=`0`, thick=`1.0`.

---

## Pitfalls

### Calling `render.*` outside `on_render`

Most calls work (the foreground draw list is valid during the entire ImGui frame), but the result is undefined behaviour prior to `NewFrame` or after `EndFrame`. Stick to `on_render`.

### Drawing on a deleted widget

`render.*` calls don't auto-flush. If you call them from `on_pre_createmove` thinking they'd surface in the next frame, you're writing into a draw list while the engine has lock — they may or may not show up depending on the timing of `EndFrame`.

### Naming your window with `##` (double-hash) to dedupe

ImGui windows are named and identified by their title string. If you want a visible title, write `"visible title"` — the full string becomes the window title. To dedupe (avoid duplicate-window warning) prefix with `##`: `"##MyInternalName"`. You'll see no title bar if you also pass `WindowFlags_NoTitleBar`.

### Writing widgets from `on_render` on top of the cheat's own menu

The cheat's menu is *itself* an ImGui window. Your script's `ImGui.Begin("Hi")` renders after the cheat's menu render pass — they can stack. They're separate windows. Fine.

### ImGui.Checkbox: ignoring the second return

The function returns `(changed, value)` — `value` is what the checkbox visually shows. If you drop `val` and just store `changed`, you'll confuse yourself. Always use both.

---

## See also

- [callbacks-events.md](callbacks-events.md) — `on_render` timing
- [examples/03-enemy-esp-box.lua](../examples/03-enemy-esp-box.lua) — full ESP recipe
- [examples/05-velocity-hud.lua](../examples/05-velocity-hud.lua) — HUD readout