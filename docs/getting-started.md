# Getting started

A VITTLOCK Lua script is a plain `.lua` file that the engine loads and runs against a shared LuaJIT state. Top-level runs once at load. You declare widgets in the menu there and hook callbacks that fire every game frame/render/tick. All real work happens inside the callbacks.

---

## Drop a script and run

1. Place a `.lua` file inside `C:\VITTLOCK\Scripts\<SubDir>\`. Example: `C:\VITTLOCK\Scripts\Demo\Hello.lua`.
   - The subdirectory name becomes the **category** tab the script is grouped under (also overridable by `m:category(...)`).
2. Open the VITTLOCK menu (default overlay key), navigate to the **Lua Scripts** tab. You should see the script appear as a card.
3. Right-click the card → **Reload** to re-run top-level, or toggle **Hot-reload** in the controls row and just save the file in your editor.
4. Open in editor via right-click → **Open in editor** (uses `ShellExecute`).

---

## Script anatomy

```lua
-- Hello.lua
local m = ui.script()              -- menu handle for THIS script
m:category("Demo")                 -- category tab label

local enabled = m:switch("Enabled", false)         -- master switch (shows on card)
local radius  = m:slider_float("Radius", 16, 4096, 800)

callbacks.on_frame(function()
    if not enabled:get_bool() then return end       -- gate by master switch
    local r = radius:get_float()
    -- per-frame work
end)

callbacks.on_render(function()
    if not enabled:get_bool() then return end
    render.text(30, 30, 1, 1, 1, 1, "R = " .. radius:get_float())
end)
```

Key points:

- `ui.script()` returns a handle bound to the file's name (without extension). No need to pass the script name as an argument everywhere — the engine knows who you are.
- The **first widget** you add (`switch` here) becomes the master switch. Its checked state gates every callback fired by the event bus: if the switch is off none of your callbacks run.
- Store widget handles in `local`s and call their getters inside callbacks — that's the hot path.
- Use `local` everywhere. Top-level globals collide across scripts — there is no per-script sandbox yet.

---

## Lifecycle

1. The engine reads every `.lua` file under `C:\VITTLOCK\Scripts\` recursively (skipping the `_docs` subfolder).
2. For each file it stamps the global `__SCRIPT_NAME__` with the filename stem, then executes the file's top-level.
3. Widget declarations populate the per-script menu row.
4. Callback/timer/button registrations attach to the bus and inherit the script's enabled flag.
5. When the file reloads, every callback/timer for this script is detached and the file re-runs.
6. On DLL shutdown, `on_script_unloaded` fires for each script before teardown.
7. Auto-generated docs are written to `<ScriptsPath>/_docs/vittlock.d.lua` + `_docs/API.md` immediately after load and after every reload.

### Reload rules

- **Manual:** lua card right-click → Reload, or **Reload All** button — synchronous
- **Hot-reload:** menu-toggle on; engine polls file mtime once/second; on change it calls `ReloadSingleScript(name)`. `GetLastWriteTime` errors are swallowed — if you delete or lock the file nothing happens, no toast fires.
- On reload: every callback, timer, and menu entry owned by this script is detached, then the file re-runs from the top.
- After reload: if the old widget label still exists, the saved value is preserved.

---

## The `__SCRIPT_NAME__` convention

You don't normally read this global. It's the filename stem (no extension, no path). The engine stamps it:

- Once at top-level execution start
- Again before firing any callback owned by this script
- Before firing `timers.after/every` callbacks
- Before firing button `on_click` handlers
- Before `log.*` / `storage.*` calls (they read it from the live state view)

All derived context — `ui.script()` (no-arg form), `log.info(...)`, `storage.set/get`, `callbacks.on_X(fn)` (single-arg form) — read this global to know who you are.

Child-script direct read:

```lua
print("running from", __SCRIPT_NAME__)  -- "running from Hello"
```

---

## Master switch & gating

Every event delivered by the event bus skips any subscription whose owning script's enabled flag is `false`. The `enabled` field is set from the **first** widget's value the moment the script's widgets are built:

```lua
-- The first widget you create becomes the master switch.
local enabled = m:switch("Enabled", false)
```

So:

- If you create a `m:switch("Enabled", false)` as your first widget, the Enabled switch becomes the master.
- If you create a slider first... it's still whatever `GetScriptEnabled` returns, which defaults to the underlying `bValue` of the first widget added. The convention is: name your first widget "Enabled" and treat it as the master switch.

Inside every callback, your first line should be:

```lua
if not enabled:get_bool() then return end
```

— where `enabled` is the local you captured for the switch handle.

---

## A more complete starting template

```lua
-- Template.lua
local m = ui.script()
m:category("Custom")

local enabled = m:switch("Enabled", false)
local mode    = m:combo("Mode", {"Safe", "Fast", "Insane"}, 0)
local range   = m:slider_int("Range", 0, 4096, 1200)
local key     = m:keybind("Toggle key", 0x2D)   -- VK_INSERT
local tint    = m:color("Tint", {1.0, 0.4, 0.2, 1.0})

m:separator()
m:group("Actions")
m:button("Reset counter", function()
    storage.set("counter", 0)
    log.info("counter reset")
end)

local counter = 0
local toggled = false

callbacks.on_local_spawn(function()
    log.info("spawned at", Engine.GetCurTime())
    counter = 0
end)

callbacks.on_pre_createmove(function(cmd)
    if not enabled:get_bool() then return end
    if ImGui.IsKeyPressed(key:get_int()) then
        toggled = not toggled
    end
    if toggled then
        -- mutate cmd here
    end
end)

callbacks.on_render(function()
    if not enabled:get_bool() then return end
    counter = counter + 1
    local c = tint:get_color()
    render.filled_rect(20, 20, 220, 40, 0, 0, 0, 0.6, 6)
    render.text(28, 30, c[1], c[2], c[3], c[4],
        string.format("mode=%s  range=%d  frames=%d",
            ({"Safe","Fast","Insane"})[mode:get_int() + 1],
            range:get_int(), counter))
end)

timers.every(5000, function()
    if enabled:get_bool() then
        log.info("heartbeat", counter)
    end
end)
```

This template touches every subsystem: menu, callbacks, entity (spawn), input keys, render, math (format), timer, storage, logging. Drop it into `C:\VITTLOCK\Scripts\Template\Template.lua` and watch it run.

---

## Next

- [callbacks-events.md](callbacks-events.md) — every callback in detail
- [widgets-menu.md](widgets-menu.md) — every widget
- [examples/](../examples/) — runnable recipes