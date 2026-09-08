# VITTLOCK Lua API

The Lua scripting layer for the **VITTLOCK** Deadlock cheat base. Drop a `.lua` file into `C:\VITTLOCK\Scripts\**\*.lua`, write to the menu, hook callbacks, draw on screen, manipulate the user command, query the entity system, schedule timers, log, persist state, read engine convars, read any schema field, hook named game events, and work with JSON/files — all from a hot-reloading Lua runtime.

This repository is the canonical documentation, examples, and reference for the public Lua API surface.

---

## What's new

**Engine access**
- **`cvar`** — find any console variable by name and read its value directly (typed by the engine's own convar type: int/float/bool/string), or write it through the console path:
  ```lua
  local fps = cvar.find("fps_max")
  print(fps:get_int())        -- direct read from the engine's convar storage

  fps:set_int(400)            -- write via the engine console (same as typing it in-game)
  print(fps:exists())         -- false for unknown names
  ```
- **`Engine.GetProp`** — read any schema field off any entity, typed by the schema (int/float/bool/Vector/QAngle/CHandle/string):
  ```lua
  local hp  = Engine.GetProp(handle, "CCitadelPlayerPawn", "m_iHealth")
  local vel = ent:get_prop("m_vecVelocity")   -- class auto-resolved: {x=, y=, z=}
  ```
- **`callbacks.on_game_event`** — hook named game events with a payload accessor (plus `"*"` for everything):
  ```lua
  callbacks.on_game_event("player_death", function(e)
      print(e.name, e:get_int("attacker"), e:get_int("victim"))
      -- e is only valid inside the callback — copy values out
  end)
  ```

**Data & persistence**
- **`json`** — `json.encode(t)` / `json.decode(s)`; sequential tables encode as arrays, `Vector3`/`QAngle` encode as `{x,y,z}`
- **`fs`** — sandboxed filesystem, jailed to `C:\VITTLOCK\Scripts` (escape attempts return false): `fs.read / write / append / exists / remove / mkdir / list / size`
- **`config`** — per-script widget profiles under `Scripts/<name>/cfg/`:
  ```lua
  config.save("legit")     -- snapshot every widget value
  config.load("legit")     -- restore it (also auto-loads on script reload)
  config.list()            -- { "legit", "rage", ... }
  ```
- **`base64.encode/decode`**, **`hash.crc32`**, and LuaJIT's `bit` library is always available

**Input & render**
- **`input`** — `input.get_cursor_position()`, `input.is_button_down(0x01)`, `input.is_key_down(vk)`, `input.get_scroll()`, `input.get_screen_size()`
- **`render.measure_text([size,] text)`** → `w, h` with the active font
- **`render.line_3d(a, b, r, g, b, a, thick)`** — world-space line between two `Vector3`s
- **`render.text_3d(pos, r, g, b, a, text)`** — text anchored to a world position

**Menu**
- **`m:multi_combo("Flags", {"A","B","C"})`** — bitmask multi-select; `w:get_mask()`, `w:set_mask(bits)`, `w:has(i)`, `w:set_option(i, on)`
- **`w:depend(fn)`** — visibility predicate; the widget hides while `fn` returns false (state is kept)
- Legacy `Menu.Switch / Menu.SliderInt / Menu.SliderFloat` now return the **real widget handle** — `get/set/on_change/depend` all work on them, and same-label widgets across scripts no longer collide

**Vector / angle math**
- `Vector3`: `Dot`, `Cross`, `Distance`, `Distance2D`, `Normalized`, `Normalize`, `ToAngles`, `IsZero` + `__add/sub/mul/div/eq/tostring`
- `QAngle`: `Forward`, `Normalize` (wraps each axis to [-180, 180]), `IsZero` + the same metamethods

---

## Quick start

A complete first script:

```lua
-- C:\VITTLOCK\Scripts\Hello\Hello.lua
local m = ui.script()          -- menu handle for "Hello"
m:category("Demo")             -- tab the script sits under

local enabled = m:switch("Enabled", false)   -- master toggle

callbacks.on_frame(function()                -- every game frame
    if not enabled:get_bool() then return end
    -- do work here
end)

callbacks.on_render(function()               -- every render frame
    if not enabled:get_bool() then return end
    render.text(30, 30, 1, 1, 1, 1, "hello from " .. __SCRIPT_NAME__)
end)
```

Reload it from the in-game menu (**Lua Scripts** tab → right-click → **Reload**) or enable **Hot-reload** and just save the file in your editor.

---

## What you can do

| Capability | Module | Doc |
|---|---|---|
| Build a per-script menu UI | `ui`, `UI`, `Menu` | [docs/widgets-menu.md](docs/widgets-menu.md) |
| React to game events (tick, render, spawn, key, modifier, bullet, particle, entity, **named game events**) | `callbacks` | [docs/callbacks-events.md](docs/callbacks-events.md) |
| Read local player + any entity state | `Engine`, `entity_list` | [docs/engine-accessors.md](docs/engine-accessors.md), [docs/entity-wrappers.md](docs/entity-wrappers.md) |
| **Read any schema field by name** | `Engine.GetProp`, `ent:get_prop` | [docs/engine-accessors.md](docs/engine-accessors.md) |
| **Read/write engine convars** | `cvar` | [docs/engine-accessors.md](docs/engine-accessors.md) |
| Read/write native aimbot settings | `aimbot` | [docs/aimbot-settings.md](docs/aimbot-settings.md) |
| Mutate the per-tick user command | `CUserCmd`, `InputBitMask_t` | [docs/cusercmd-input.md](docs/cusercmd-input.md) |
| Draw on screen (HUD, ESP, **world-space lines/text, text metrics**) | `render`, `ImGui` | [docs/render-imgui.md](docs/render-imgui.md) |
| **Poll mouse & keyboard state** | `input` | [docs/render-imgui.md](docs/render-imgui.md) |
| Ray-cast the world | `Engine.TraceLine` | [docs/trace.md](docs/trace.md) |
| Schedule one-shot + repeating timers | `timers` | [docs/timers.md](docs/timers.md) |
| Per-script in-memory keys | `storage` | [docs/storage.md](docs/storage.md) |
| **Per-script config profiles** | `config` | [docs/storage.md](docs/storage.md) |
| **Sandboxed file access** | `fs` | [docs/storage.md](docs/storage.md) |
| **JSON encode/decode** | `json` | [docs/storage.md](docs/storage.md) |
| **base64 / crc32 / bit ops** | `base64`, `hash`, `bit` | [docs/storage.md](docs/storage.md) |
| Check 305 modifier states | `EModifierState` | [docs/modifier-states.md](docs/modifier-states.md) |
| Vector math | `Vector3`, `QAngle`, `math.angle_vectors` | [docs/math-vector3-qangle.md](docs/math-vector3-qangle.md) |
| Log to the in-app console | `log`, `print`, `Debugger` | [docs/logging-debugger.md](docs/logging-debugger.md) |
| Programmatic doc generation + introspection | `docs` | [docs/docs-api.md](docs/docs-api.md) |

---

## Document index

- **Start here:** [docs/getting-started.md](docs/getting-started.md)
- **Full reference:** [docs/api-reference.md](docs/api-reference.md)
- **Cookbook / examples:** [examples/](examples/) — each file is a runnable `.lua`

---

## Runtime

- **Engine:** LuaJIT 5.1 runtime
- **Concurrency:** all callbacks fire under a single lock from the game thread — you don't need your own locking
- **Per-script sandbox:** none. Every script shares one global state. Top-level `local`s and closures are safe; globals (`x = 5`) collide across scripts — use `local` everywhere

## Script location & loading

- Path: `C:\VITTLOCK\Scripts\<SubDir>\<Name>.lua` — the subdirectory becomes the **category** tab
- Top-level executes once at load and again on every reload
- The first widget you create with `ui.script():switch(...)` (or `UI.AddSwitch(...)`) is the script's **master switch** — its value gates every callback dispatched to that script
- Hot-reload polls file mtime once/second when the toggle is on

## Conventions

- `__SCRIPT_NAME__` is a global string the engine stamps before running your top-level and before firing any of your callbacks/timers/buttons. It's how `ui.script()`, `log.*`, `storage.*`, and `callbacks.*(fn)` know who you are — you almost never read it directly
- Widget handles returned by factory functions are cheap Lua tables holding `(script, label)` — store them in a local and reuse them, don't keep looking them up by name
- Colours are `0..1` floats (RGBA), not `0..255`
- Virtual-key codes follow Win32 `VK_*` — see the [Win32 VK table](https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes)

## Compatibility note

This API surface has two generations: **legacy `UI.AddSwitch(script, ...)` / `callback.on_X:set(fn)` / `Render.Text(...)`** and **modern `ui.script():switch(...)` / `callbacks.on_X(fn)` / `render.text(...)`**. Both work and both are documented. New scripts should use the modern API.

As of this release the legacy `Menu.Switch / Menu.SliderInt / Menu.SliderFloat` factories return the **full widget handle** (same object as `ui.script():switch(...)`), so `get/set/on_change/depend` work everywhere. Widget identity now includes the widget kind and each row renders under its own ImGui ID scope — same-label widgets in different scripts no longer collide.
