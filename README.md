# VITTLOCK Lua API

The Lua scripting layer for the **VITTLOCK** Deadlock cheat base. Drop a `.lua` file into `C:\VITTLOCK\Scripts\**\*.lua`, write to the menu, hook callbacks, draw on screen, manipulate the user command, query the entity system, schedule timers, log, persist state, read engine convars, read any schema field, hook named game events, and work with JSON/files — all from a hot-reloading Lua runtime.

This repository is the canonical documentation, examples, and reference for the public Lua API surface.

---

## What's new

**Rendering Engine Expansion & Extended Fonts (`render.*`)**
- **Dynamic Font Sizing & Custom TTF/OTF Fonts** — `render.text(x, y, r, g, b, a, text, [size], [font])`, `render.load_font(name, path, size)`, `render.push_font(font)`, `render.pop_font()`:
  ```lua
  local header_font = render.load_font("HeaderFont", "C:/Windows/Fonts/segoeui.ttf", 24)
  render.text(100, 100, 255, 255, 255, 255, "Custom Sized Header", 24, "HeaderFont")
  ```
- **Cyrillic & Extended Unicode Support** — native font atlas baking for Cyrillic (`0x0400` - `0x04FF`) and geometric shapes (`0x25A0` - `0x25FF`, `0x2190` - `0x21FF`). Russian/Ukrainian text and symbols (`▶`, `●`, `★`, `⚠`, arrows) render crisp without turning into `?`.
- **Native FontAwesome 6 Icons** — embedded FontAwesome icon atlas available via font name `"fontawesome"` or `"fa"`:
  ```lua
  render.text(20, 20, 255, 100, 100, 255, "\xef\x80\x84", 18, "fontawesome") -- Heart
  ```
- **Dual-Dimension Text Measurement (`render.measure_text`)** — returns `w, h` as a multi-value tuple:
  ```lua
  local w, h = render.measure_text("Deadlock", 18)
  ```
- **Image & Texture Rendering (`render.load_image`, `render.image`, `render.panorama_image`)** — load external `.png`, `.jpg`, `.bmp`, `.tga` files or stream in-game Panorama `.vtex_c` textures onto the overlay with GPU caching:
  ```lua
  local img = render.load_image("C:/VITTLOCK/assets/logo.png")
  if img then
      render.image(img, 50, 50, 64, 64, 255, 255, 255, 255)
  end
  render.panorama_image("panorama/images/items/weapon/blood_tribute_psd.vtex_c", 130, 50, 64, 64)
  ```
- **Polygons & Outlines** — `render.filled_polygon(points, r, g, b, a)` and `render.polygon(points, r, g, b, a, [closed], [thick])` for convex polygons, FOV cones, and directional arrows.
- **Backdrop Blur & Frosted Glass** — `render.glass_rect(x, y, w, h, [passes], [rounding], [border])` and `render.blur(x, y, w, h, [passes], [rounding])`.
- **Full `os.date` and `os.time` Standard Library** — supports formatted date strings (`"%Y-%m-%d %H:%M:%S"`), table mode (`"*t"`), and UTC (`"!*t"`).

**Core Engine & Menu Stability**
- **HUD Drag Race Conditions** — resolved race conditions where event bars and notifications were dragged unintentionally while dragging the menu.
- **Script Toggle Persistence** — fixed script toggle switch state syncing and reactive callback dispatching.
- **Top-Left Ghost Rectangle Eliminated** — removed orphaned un-offset glass sidebar and guarded pill rendering.
- **Viewport Boundary Clamping** — clamped menu coordinates within screen boundaries `[0, DisplaySize - WindowSize]`.
- **DeltaTime Easing Fix** — fixed animation step calculations across varying refresh rates.
- **100% Opaque Menu Presets** — enforced solid opacity across all theme presets and Glacier plate.

**Dynamic Multi-Tab Architecture & Explicit Side Routing (`Menu.Create`)**
- **`Menu.Create(category, sub, scriptName, tabName, [sectionHeader])`** — create dedicated, interactive mini-tabs in Lumin with an animated pill bar:
  ```lua
  -- Bind dedicated script tab under "Aimbot" category
  local aim_tab = Menu.Create("Aimbot", "", "PsyAbility", "Aim")

  -- Explicit column routing via Enum.GroupSide (Left = 0, Right = 1)
  local left_card  = aim_tab:Create("Main Settings", Enum.GroupSide.Left)
  local right_card = aim_tab:Create("Target Settings", Enum.GroupSide.Right)

  left_card:Switch("Enabled", true)
  right_card:Slider("Max Distance", 10.0, 150.0, 70.0, "%.0fm")
  ```
- **`Enum.GroupSide` Deterministic 2-Column Placement** — pass `Enum.GroupSide.Left` (`0`) or `Enum.GroupSide.Right` (`1`) to `:Create()`, `:Section()`, or `:Card()`. Guarantees widgets land in the exact column intended.
- **Card Headers for All Groups** — card titles render on every section (including `c == 0`), giving clean visual headers like `"Target Settings"`.
- **Extended Scroll Clearance** — trailing `s_(45.f)` padding added to Lumin card containers so you can scroll all the way down to bottom widgets with zero cutoff.
- **Hot-Reload Clean Slate** — `CLuaEngine::ReloadSingleScript` purges registered widgets, subtabs, and categories via `m_Menu.RemoveScript()` prior to re-execution, preventing widget duplication or ghost state across edits.

**Modal `:Gear()` Sub-Settings Popups**
- **Mechanical Gear Popups (`w:Gear(label)`)** — attach modal sub-settings to any switch or slider:
  ```lua
  local weapon = Menu.Create("Miscellaneous", "", "Items Helper", "Main", "Weapon")
  local ui_aura = weapon:Switch("Auto Heroic Aura", true, "panorama/images/items/weapon/heroic_aura_psd.vtex_c")
  ui_aura:ToolTip("Casts Heroic Aura when allies are grouped up and an enemy is close.")

  -- Returns a scoped builder handle; GUI draws an animated mechanical gear button next to the toggle
  local ui_gear   = ui_aura:Gear("Settings")
  local ui_allies = ui_gear:Slider("Allies Nearby", 1, 5, 2, "%d")
  local ui_radius = ui_gear:Slider("Enemy Radius", 5, 60, 25, "%d m")
  ```
- Clicking the gear button opens an isolated modal popup (`##gear_popup_...`) holding all child widgets, keeping your primary cards clean and compact.

**User Command Silent Aim & Input Control**
- **`cmd:can_psilent_at_pos(pos)`** & **`cmd:set_psilent_at_pos(pos)`** — perform silent aim validation and angle calculation directly on `CUserCmd`:
  ```lua
  callbacks.on_pre_createmove(function(cmd)
      local target_pos = predict_target_position()
      if cmd:can_psilent_at_pos(target_pos) then
          cmd:set_psilent_at_pos(target_pos)
          cmd:AddButtonState(InputBitMask_t.IN_ATTACK)
      end
  end)
  ```
- **Direct Button Word Mutation**:
  - `cmd:add_buttonstate1(mask)`, `cmd:add_buttonstate2(mask)`, `cmd:add_buttonstate3(mask)`
  - `cmd:TapButton(mask)` — quick single-tick button tap (press + release).
  - `cmd:HasButtonState(mask)`, `cmd:HoldButton(mask)`, `cmd:ClearButton(mask)`
- **Post-Prediction Hook Parity**:
  - `callbacks.on_post_createmove(id, fn)` runs after user command finalization and engine prediction.
- **Thread-Safe Event Pipeline**:
  - Modifier events (`on_add_modifier`, `on_remove_modifier`) and entity discovery driven under cache locks.

**Entity & Pawn Inspection**
- **Health & Alive Queries**:
  ```lua
  local hp    = Engine.GetEntityHealth(handle)
  local maxHp = Engine.GetEntityMaxHealth(handle)
  local alive = Engine.IsEntityAlive(handle)    -- m_lifeState == 0 and health > 0

  -- Or via entity_list wrappers:
  local enemy = entity_list:enemies()[1]
  if enemy and enemy:is_alive() then
      print(enemy:get_name(), enemy:get_health(), "/", enemy:get_max_health())
  end
  ```
- **Active Modifiers & State Queries**:
  - `entity:get_modifiers()` / `Engine.GetEntityModifiers(handle)` — returns active modifiers with duration, elapsed, remaining time, attributes, and debuff types.
  - `entity:has_modifier_state(state)` / `Engine.EntityHasModifierState(handle, state)` — fast state check for 305 `EModifierState` schema constants (stunned, silenced, invisible, etc.).
- **Extended Ability & Item Metadata**:
  - `get_stacks()` / `m_nNumStacks` (with automatic class resolution for `CItem_RestorativeLocket`).
  - `get_charges()`, `get_toggle_state()`, `get_cooldown_end()`.
  - `get_slot()`, `get_slot_name()`, `get_button_name()`, `get_button_mask()`.
  - `get_scaled_property("Radius")`, `get_aoe_radius()`.
  - `cast(cmd)` — automatically taps the exact ability/item button bit into the user command.
- **Modifier Attributes & Debuff Data**:
  - Modifiers expose `name`, `creation`, `duration`, `elapsed`, `remaining`, `m_iTeam`, `m_flDuration`, and `get_vdata()` (`m_eDebuffType`, `m_nAttributes`).
- **Game Rules & Network**:
  - `game_rules.game_time()` — reads server game clock (`Engine.GetCurTime()`).
  - `net_channel.latency()` — returns estimated round-trip latency in seconds.

**Engine access & Convars**
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
- **`render.text(x, y, r, g, b, a, text, [size], [font])`** — dynamically sized text, Cyrillic + geometric shapes, FontAwesome icons
- **`render.load_font(name, path, size)` / `render.push_font` / `render.pop_font`** — custom TTF/OTF font loading and scoped font stacks
- **`render.measure_text(text, [size], [font])`** → `w, h` dual-dimension metric tuple
- **`render.load_image(path)` & `render.image(img, x, y, [w], [h], [r,g,b,a])`** — GPU-accelerated texture rendering from disk
- **`render.panorama_image(path, x, y, [w], [h])`** — direct Panorama `.vtex_c` texture rendering with UV auto-crop
- **`render.filled_polygon(points, r, g, b, a)` & `render.polygon(points, ...)`** — 2D convex filled polygons and outlines
- **`render.glass_rect(...)` & `render.blur(...)`** — frosted glass backdrop panels and dual-pass blur
- **`render.line_3d(a, b, r, g, b, a, thick)`** — world-space line between two `Vector3`s
- **`render.text_3d(pos, r, g, b, a, text)`** — text anchored to a world position

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
