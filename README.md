# VITTLOCK Lua API

The Lua scripting layer for the **VITTLOCK** Deadlock cheat base. Drop a `.lua` file into `C:\VITTLOCK\Scripts\**\*.lua`, write to the menu, hook callbacks, draw on screen, manipulate the user command, query the entity system, schedule timers, log, and persist state — all from a hot-reloading Lua runtime.

This repository is the canonical documentation, examples, and reference for the public Lua API surface.

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
| React to game events (tick, render, spawn, key, modifier, bullet, particle, entity) | `callbacks` | [docs/callbacks-events.md](docs/callbacks-events.md) |
| Read local player + any entity state | `Engine`, `entity_list` | [docs/engine-accessors.md](docs/engine-accessors.md), [docs/entity-wrappers.md](docs/entity-wrappers.md) |
| Read/write native aimbot settings | `aimbot` | [docs/aimbot-settings.md](docs/aimbot-settings.md) |
| Mutate the per-tick user command | `CUserCmd`, `InputBitMask_t` | [docs/cusercmd-input.md](docs/cusercmd-input.md) |
| Draw on screen (HUD, ESP) | `render`, `ImGui` | [docs/render-imgui.md](docs/render-imgui.md) |
| Ray-cast the world | `Engine.TraceLine` | [docs/trace.md](docs/trace.md) |
| Schedule one-shot + repeating timers | `timers` | [docs/timers.md](docs/timers.md) |
| Per-script in-memory keys | `storage` | [docs/storage.md](docs/storage.md) |
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
