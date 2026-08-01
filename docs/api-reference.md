# VITTLOCK Lua API — Full reference

Every module, every function, every argument, every event, with runnable examples.

Scripts live under `C:\VITTLOCK\Scripts\**\*.lua`. Subdirectory name becomes the category tab. Hot-reload can be toggled in the menu. Right-click a script card → **Reload** or **Open in editor**.

Runtime: **LuaJIT 5.1**.

---

## Table of contents

- [Script anatomy](#script-anatomy)
- [The `__SCRIPT_NAME__` convention](#the-__script_name__-convention)
- [Modules](#modules)
  - [`ui` — modern fluent widgets](#ui--modern-fluent-widgets)
  - [`UI` — legacy widget factory](#ui--legacy-widget-factory)
  - [`Menu` — discovery, control & legacy API](#menu--discovery-control--legacy-api)
  - [`callbacks` — event bus](#callbacks--event-bus)
  - [`callback` — legacy alias](#callback--legacy-alias)
  - [`Engine` — game state](#engine--game-state)
  - [`CUserCmd` — per-tick command](#cusercmd--per-tick-command)
  - [`Vector3`](#vector3)
  - [`QAngle`](#qangle)
  - [`entity_list` / `entities`](#entity_list--entities)
  - [`ImGui` — UI primitives](#imgui--ui-primitives)
  - [`render` — draw list](#render--draw-list)
  - [`Render` — legacy alias](#render--legacy-alias)
  - [`log` and `print`](#log-and-print)
  - [`Debugger`](#debugger)
  - [`timers`](#timers)
  - [`storage`](#storage)
  - [`docs`](#docs)
  - [`math.angle_vectors` / `Engine.AngleVectors`](#mathangle_vectors--engineanglevectors)
  - [`InputBitMask_t`](#inputbitmask_t)
  - [`EModifierState`](#emodifierstate)
- [Cookbook](#cookbook)

---

## Script anatomy

A script is a plain `.lua` file. Top-level runs once when the engine loads it. Declare widgets and register callbacks at top-level; do work inside the callbacks.

```lua
-- MyScript.lua
local m = ui.script()
m:category("Combat")

local enabled = m:switch("Enabled", false)
local range   = m:slider_float("Range", 0, 4096, 800)

callbacks.on_frame(function()
    if not enabled:get_bool() then return end
    -- per-frame work
end)

callbacks.on_render(function()
    if not enabled:get_bool() then return end
    -- draw HUD
end)
```

Lifecycle:

1. Engine reads the file, executes top-level under one shared Lua state.
2. Widget declarations populate the menu row for this script.
3. Callback registrations attach to the event bus and inherit the script's enabled flag.
4. On reload, all callbacks/timers for this script are cancelled and the file re-runs.
5. On shutdown, `on_script_unloaded` fires before teardown.

---

## The `__SCRIPT_NAME__` convention

The engine sets the global `__SCRIPT_NAME__` to the script's filename (without extension) before each top-level execution, and re-stamps it before firing any callback, timer, or button click owned by that script. All modules that need "who am I?" (`ui.script()`, `log.info`, `storage.set/get`, `callbacks.on_frame(fn)` without a name) read this global.

You almost never touch it directly. It's exposed for advanced tricks:

```lua
print("running from", __SCRIPT_NAME__)  -- "running from MyScript"
```

---

## Modules

### `ui` — modern fluent widgets

Preferred API for new scripts. No script-name arg. Each factory returns a **widget handle** with typed getters/setters.

#### `ui.script([name])` → menu handle

Grab the menu handle for the current script (`name` defaults to `__SCRIPT_NAME__`).

```lua
local m = ui.script()
```

Handle methods:

| Method | Returns | Description |
|---|---|---|
| `m:category(name)` | nil | Assign category tab (`"Combat"`, `"Movement"`, `"Visuals"`, or anything) |
| `m:switch(label, default)` | handle | Boolean toggle |
| `m:slider_int(label, min, max, default)` | handle | Integer slider |
| `m:slider_float(label, min, max, default)` | handle | Float slider |
| `m:keybind(label, defaultVK)` | handle | Virtual-key capture — use `0x2D` for `VK_INSERT` etc. |
| `m:combo(label, options, default)` | handle | Dropdown; `options` is a Lua array of strings, `default` is 0-indexed |
| `m:color(label, {r, g, b, a})` | handle | RGBA colour picker; values 0..1 |
| `m:button(label, fn)` | handle | Fires `fn()` on click |
| `m:input_text(label, capacity, [default])` | handle | Text input, capped at `capacity` chars |
| `m:group(headerLabel)` | nil | Divider with title inside the popup |
| `m:separator()` | nil | Thin horizontal rule |
| `m:tooltip(label, text)` | nil | Attach a hover tooltip to a previously-created widget with that label |
| `m:find(label)` | handle | Same as `Menu.Find(label)` for current script |
| `m:Find(label)` | handle | alias |

The **first** widget you add is treated as the script's master switch — its value drives the enable state and gates inclusion in every callback dispatch.

#### Widget handle API

Every factory above returns a handle. Handles are cheap to store in locals — reuse them everywhere instead of looking up by name.

| Getter | Returns |
|---|---|
| `h:get()` / `h:Get()` | Kind-dispatched — bool / int / float / string / color-table |
| `h:get_bool()` / `h:GetBool()` | bool |
| `h:get_int()` / `h:GetInt()` | int |
| `h:get_float()` / `h:GetFloat()` | number |
| `h:get_key()` / `h:GetKey()` | int (VK code) |
| `h:get_string()` / `h:GetString()` | string |
| `h:get_color()` / `h:GetColor()` | table `{r, g, b, a}` |

| Setter | Note |
|---|---|
| `h:set(val)` / `h:Set(val)` | Inferring setter — bool/int/float/string/color-table all accepted |
| `h:set_bool(v)` | |
| `h:set_int(v)` | clamps to slider/combo range when known |
| `h:set_float(v)` | clamps to slider range when known |
| `h:set_key(k)` | |
| `h:set_string(s)` | |
| `h:set_color({r,g,b,a})` | Table indexed 1..4 |

| Reactive | Note |
|---|---|
| `h:on_change(fn)` | Called after the value changes (WIP — polled on render, not dispatched every value change) |

#### Full example

```lua
local m = ui.script()
m:category("Combat")

local enabled  = m:switch("Enabled", true)
local range    = m:slider_int("Range", 0, 4096, 1200)
local speed    = m:slider_float("Speed", 0.1, 5.0, 1.0)
local mode     = m:combo("Mode", {"Safe", "Fast", "Insane"}, 1)
local color    = m:color("Tint", {1.0, 0.4, 0.2, 1.0})
local key      = m:keybind("Toggle key", 0x2D)  -- INSERT

m:separator()
m:group("Actions")
m:button("Reset", function() storage.set("hits", 0) end)

callbacks.on_frame(function()
    if not enabled:get_bool() then return end
    local r  = range:get_int()
    local sp = speed:get_float()
    -- do work
end)
```

---

### `UI` — legacy widget factory

Same widgets as `ui.*`, but first arg is always the script name. Kept for scripts that already use it.

| Function | Args | Purpose |
|---|---|---|
| `UI.AddSwitch(script, label, default)` | | Bool toggle |
| `UI.AddSliderInt(script, label, min, max, default)` | | Int slider |
| `UI.AddSliderFloat(script, label, min, max, default)` | | Float slider |
| `UI.AddKeybind(script, label, defaultVK)` | | Keybind capture |
| `UI.AddCombo(script, label, options, default)` | | Dropdown |
| `UI.AddColor(script, label, r, g, b, a)` | | Colour picker |
| `UI.AddButton(script, label, fn)` | | Button |
| `UI.AddText(script, label)` | | Static text row |
| `UI.AddSeparator(script)` | | Separator |
| `UI.SetTooltip(script, label, text)` | | Tooltip |
| `UI.SetCategory(script, category)` | | Category tab |
| `UI.Find(script, label)` or `UI.Find(label)` | → handle | Same as `Menu.Find` |
| `UI.Get(script, label)` | any | Same as `Menu.Get` |
| `UI.Set(script, label, val)` | nil | Same as `Menu.Set` |
| `UI.GetBool(script, label)` | → bool | Read |
| `UI.GetInt(script, label)` | → int | Read |
| `UI.GetFloat(script, label)` | → number | Read |
| `UI.GetKey(script, label)` | → int | Read VK |
| `UI.SetBool` / `SetInt` / `SetFloat` / `SetKey` / `SetString` / `SetColor` | `(script, label, val)` | Typed setters |

Example:

```lua
UI.SetCategory("MyScript", "Movement")
UI.AddSwitch("MyScript", "Enabled", false)
UI.AddKeybind("MyScript", "Toggle Key", 0x56)

callbacks.on_frame(function("MyScript", function()
    if not UI.GetBool("MyScript", "Enabled") then return end
end))
```

---

### `Menu` — discovery, control & legacy API

Find existing menu widgets across any script and dynamically get or set their values at runtime.

| Function / Method | Args | Description |
|---|---|---|
| `Menu.Find(script, label)` or `Menu.Find(label)` | `(string, string)` or `(string)` | Returns a reactive widget handle for the given widget |
| `Menu.Get(script, label)` or `Menu.Get(label)` | `(string, string)` or `(string)` | Read any widget's current value |
| `Menu.Set(script, label, val)` or `Menu.Set(label, val)` | `(string, string, any)` or `(string, any)` | Set any widget's value (bool, int, float, string, color table) |
| `Menu.SetBool` / `SetInt` / `SetFloat` / `SetKey` / `SetString` / `SetColor` | `(script?, label, val)` | Explicit typed setters |
| `Menu.GetBool` / `GetInt` / `GetFloat` / `GetKey` / `GetString` / `GetColor` | `(script?, label)` | Explicit typed getters |

Also: legacy `Menu.Switch / SliderInt / SliderFloat / Slider` factory functions exist in `BindLegacyShims.cpp` — they wrap `UI.AddSwitch/AddSliderInt/AddSliderFloat` and honour `__SCRIPT_NAME__`.

#### Examples

```lua
-- Find a widget in the current script or another script
local targetLock = Menu.Find("Target Lock")
targetLock:set(true) -- Toggle it on

-- Find a widget by explicit script name and label
local aimbotRange = Menu.Find("Aimbot", "Max Range")
aimbotRange:set(1200)

-- Set a color widget dynamically
local espColor = Menu.Find("ESP", "Box Color")
espColor:set({ 1.0, 0.0, 0.0, 1.0 }) -- Red RGBA

-- Direct one-liner setters
Menu.Set("Movement", "Bhop Enabled", true)
Menu.Set("Auto Shoot", true) -- Uses current script for label lookup
```

---

### `callbacks` — event bus

Every event handler is registered here. Two calling conventions — both work:

```lua
-- Modern: current script implied
callbacks.on_frame(function() ... end)

-- Legacy: pass the script name explicitly
callbacks.on_frame("MyScript", function() ... end)
```

Both return a `token` (integer). `callbacks.unsubscribe(token)` removes just that one subscription.

Callbacks only fire while the script's primary widget is **enabled**.

#### Full event list

| Event | Signature | Fires |
|---|---|---|
| `on_pre_createmove` / `on_createmove` | `fun(cmd:CUserCmd)` | Before user command is sent |
| `on_post_createmove` / `on_postmove` | `fun(cmd:CUserCmd)` | After user command is sent |
| `on_frame` | `fun()` | Every game frame (post-cmd) |
| `on_render` / `on_draw` | `fun()` | Every render frame (UI-space) |
| `on_render_world` | `fun()` | Every render frame (world-space — reserved; no dispatcher wired yet) |
| `on_add_modifier` | `fun(mod:table, ent:table)` | New modifier appeared on any entity |
| `on_remove_modifier` | `fun(mod:table, ent:table)` | Modifier removed (declared; **dispatcher currently does not fire** — see Notes) |
| `on_particle_create` | `fun(data:table)` | Particle system spawned |
| `on_particle_destroy` | `fun(data:table)` | Particle destroyed |
| `on_bullet_create` | `fun(bullet:table)` | Bullet fired by any weapon |
| `on_entity_create` | `fun(handle:integer)` | Entity added to world |
| `on_entity_destroy` | `fun(handle:integer)` | Entity removed from world |
| `on_local_spawn` | `fun()` | Your pawn appeared |
| `on_local_death` | `fun()` | Your pawn was destroyed |
| `on_menu_open` | `fun()` | Cheat menu opened |
| `on_menu_close` | `fun()` | Cheat menu closed |
| `on_key_pressed` | `fun(vk:integer)` | Any key went from up → down (256 vk scan) |
| `on_key_released` | `fun(vk:integer)` | Any key went from down → up |
| `on_script_loaded` | `fun()` | This script just loaded |
| `on_script_unloaded` | `fun()` | This script is about to unload |

> ⚠️ **Known gap:** `on_remove_modifier` is bound and the enum entry exists, but the per-frame entity poll only ever fires `on_add_modifier`. Subscribing to `on_remove_modifier` will currently never receive events. Polling `Engine.EntityHasModifier(h, name)` per-frame is the workaround until the dispatcher is wired.

> ⚠️ **Known gap:** `on_render_world` is wired to the enum and regs, but the per-frame dispatch is the same as `on_render` — it's a UI-space dispatch, not a separate world-space pass.

#### Event payloads

**`on_add_modifier(mod, ent)`** — `mod` and `ent` are tables:

```lua
callbacks.on_add_modifier(function(mod, ent)
    local name     = mod.name              -- lowercased RTTI name
    local duration = mod:get_duration()    -- seconds
    local ent_h    = ent:get_handle()      -- integer
    local team     = ent.m_iTeamNum        -- integer
    if name:find("stunned") then
        log.info("stun applied to entity", ent_h)
    end
end)
```

`mod` extras:

| Field | Type | Description |
|---|---|---|
| `mod.name` | string | lowercased RTTI name |
| `mod.duration` | number | seconds (also accessible via `mod:get_duration()`) |
| `mod:get_name()` | fn → string | alias closure |
| `mod:get_duration()` | fn → number | alias closure |

`ent` extras:

| Field | Type | Description |
|---|---|---|
| `ent:get_handle()` | fn → int | Entity handle |
| `ent:valid()` | fn → bool | always returns `true` for this dispatch |
| `ent:get_name()` | fn → string | Designer name |
| `ent.m_iTeamNum` | int | Entity team |

**`on_bullet_create(bullet)`** — rich table:

```lua
callbacks.on_bullet_create(function(b)
    b.shooter          -- wrapped entity table (see below)
    b.shooter_handle   -- integer
    b.team             -- integer
    b.weapon_name      -- string ("citadel_ability_shiv_dagger" etc.)
    b.weapon_handle    -- integer
    b.start            -- {x, y, z} table
    b.target           -- {x, y, z} table (alias .end_pos)
    b.direction        -- {x, y, z} unit vector
    b.pitch            -- number
    b.yaw              -- number
    b.range            -- number
end)
```

The `shooter` table supports `:valid() -> bool`, `:get_handle() -> int`, `:get_name() -> string`, `:get_origin() -> Vector3`, `.m_iTeamNum -> int`.

**`on_particle_create(data)`**:

```lua
callbacks.on_particle_create(function(p)
    p.name    -- effect resource name string
    p.handle  -- integer entity handle
end)
```

`on_particle_destroy(data)` also passes a table with `.handle`.

**`on_entity_create` / `on_entity_destroy`** receive a single integer handle.

**`on_key_pressed` / `on_key_released`** receive a single integer virtual-key code (see [Win32 VK table](https://learn.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes)).

#### Unsubscribe example

```lua
local tok = callbacks.on_frame(function()
    print("hi")
end)

-- later
callbacks.unsubscribe(tok)
```

#### `callbacks.count(name)` → integer

Number of currently-registered handlers for a named event. Useful for debugging.

```lua
print(callbacks.count("on_render"))  -- e.g. 4
```

---

### `callback` — legacy alias

Old-school property-style API. Under the hood it routes to the modern bus.

```lua
callback.on_frame:set(function() ... end)
callback.on_render:set(function() ... end)
callback.on_pre_createmove:set(function(cmd) ... end)
callback.on_add_modifier:set(function(mod, ent) ... end)
callback.on_scripts_loaded:set(function() end)  -- fires immediately
callback.on_draw:set(...) -- alias of on_render
```

---

### `Engine` — game state

Read-only accessors to the live game world.

#### Local player

| Function | Returns | Description |
|---|---|---|
| `Engine.GetLocalPlayerHandle()` | integer | Your pawn handle, or `-1` |
| `Engine.GetLocalVelocity()` | Vector3 | units per second |
| `Engine.GetLocalMoveType()` | integer | `MoveType_t` enum value |
| `Engine.GetLocalFlags()` | integer | `m_fFlags` |
| `Engine.GetCameraAngles()` | QAngle | Local view angles |
| `Engine.HasModifierState(state)` | bool | See `EModifierState` |
| `Engine.IsOnWall()` | bool | Wall-jump / wall-slide state |
| `Engine.GetTickInterval()` | number | Server tick interval seconds |
| `Engine.GetCurTime()` | number | Game clock seconds |
| `Engine.GetAirAccelerate()` | number | Hardcoded `10.0` (no cvar exposure yet) |

```lua
if Engine.HasModifierState(EModifierState.MODIFIER_STATE_STUNNED) then
    log.info("we're stunned")
end
```

#### Any entity

| Function | Returns | Description |
|---|---|---|
| `Engine.GetPlayers()` | `int[]` | Handles of every player pawn |
| `Engine.GetEntityTeam(h)` | integer | `-1` if not found |
| `Engine.GetEntityOrigin(h)` | Vector3 | World position |
| `Engine.GetEntityName(h)` | string | Designer-name |
| `Engine.IsPlayer(h)` | bool | Is a citadel player pawn |
| `Engine.EntityHasModifierState(h, state)` | bool | |
| `Engine.EntityHasModifier(h, name)` | bool | By modifier name |
| `Engine.GetEntityAbility(h, name)` | table or nil | Returns `{get_cooldown = fn}` |
| `Engine.GetBonePosition(h, slotName)` | Vector3 | `"Head"`, `"Neck"`, `"Torso"`, `"Arms"`, `"Legs"` |

```lua
for _, h in ipairs(Engine.GetPlayers()) do
    local team = Engine.GetEntityTeam(h)
    local pos  = Engine.GetEntityOrigin(h)
    print(Engine.GetEntityName(h), team, pos.x, pos.y, pos.z)
end
```

#### Screen / geometry

| Function | Returns | Description |
|---|---|---|
| `Engine.GetScreenSize()` | `{w, h}` | Viewport size |
| `Engine.WorldToScreen(v3)` | `{x, y, visible}` | Project |
| `Engine.AngleVectors(qa)` | Vector3 | Forward vector |
| `Engine.TraceLine(start, end, skipHandle)` | `{hit, fraction, hit_entity}` | Ray-cast (see [trace.md](trace.md)) |
| `Engine.PlayVol()` | nil | Legacy no-op preserved |

```lua
local s = Engine.GetScreenSize()
local p = Engine.WorldToScreen(Vector3.new(100, 200, 64))
if p.visible then
    render.filled_rect(p.x - 2, p.y - 2, 4, 4, 1, 0, 0, 1, 0)
end
```

---

### `CUserCmd` — per-tick command

Passed to `on_pre_createmove(cmd)` and `on_post_createmove(cmd)`. Mutating it in `on_pre_createmove` changes what the server sees.

| Method | Purpose |
|---|---|
| `cmd:GetForwardMove()` / `cmd:SetForwardMove(v)` | Forward move axis |
| `cmd:GetSideMove()` / `cmd:SetSideMove(v)` | Side move axis |
| `cmd:SetUpMove(v)` | Vertical impulse |
| `cmd:GetViewAngles()` / `cmd:SetViewAngles(qa)` | View pitch/yaw/roll |
| `cmd:GetCameraAngles()` | Prefers `cmd`'s own camera angles, falls back to camera manager |
| `cmd:GetCameraPosition()` | Prefers active camera, falls back to pawn origin |
| `cmd:SetCameraPosition(x, y, z)` | Only writes when `cmd` already has a `vec_camera_position` — silently no-ops with non-finite values |
| `cmd:GetButtonState()` | Raw `buttonstate1` bitmask |
| `cmd:HasButtonState(bit)` | Test a button (see `InputBitMask_t`) |
| `cmd:AddButtonState(bit)` | Hold a button this tick |
| `cmd:RemoveButtonState(bit)` | Clear a button |
| `cmd:HoldButton(bit)` | Alias of `AddButtonState` |
| `cmd:ClearButton(bit)` | Alias of `RemoveButtonState` |
| `cmd:PressButton(bit)` | Press this tick only |
| `cmd:TapButton(bit)` | Press + release this tick |
| `cmd:add_buttonstate1(bit)` | Alias of `PressButton` |

```lua
callbacks.on_pre_createmove(function(cmd)
    if UI.GetBool("MyScript", "Auto Jump") then
        cmd:AddButtonState(InputBitMask_t.IN_JUMP)
    end
end)
```

See [cusercmd-input.md](cusercmd-input.md) and [modifier-states.md](modifier-states.md) for the full button/state listings.

---

### `Vector3`

| Constructor | Note |
|---|---|
| `Vector3.new()` | Zero vector |
| `Vector3.new(x, y, z)` | |

Fields: `.x`, `.y`, `.z`

Methods: `:Length()`, `:Length2D()`

Operators: `+`, `-`, `* number`

```lua
local a = Vector3.new(1, 2, 3)
local b = Vector3.new(4, 5, 6)
local d = (b - a):Length()
```

---

### `QAngle`

Same shape as Vector3. Fields `.x` (pitch), `.y` (yaw), `.z` (roll).

```lua
local ang = QAngle.new(0, 90, 0)
local fwd = Engine.AngleVectors(ang)  -- Vector3 pointing +Y
```

---

### `entity_list` / `entities`

Convenience wrappers backed by `Engine.*`. Both names point at the same table.

| Method | Returns | Description |
|---|---|---|
| `entity_list:by_handle(h)` | ent-table | Wrap a handle |
| `entity_list:local_pawn()` | ent-table | Local player wrapped |
| `entity_list:by_class_name(cls)` | ent-table[] | Everyone (currently returns all players regardless of class) |
| `entity_list:enemies()` | ent-table[] | Players on the enemy team |
| `entity_list:allies()` | ent-table[] | Players on your team (excludes you) |

Every ent-table:

```lua
ent:valid()                     -- bool
ent:is_alive()                  -- bool (always true right now)
ent.m_iTeamNum                  -- int
ent:has_modifier_state(state)   -- bool
ent:get_name()                  -- string
ent:get_origin()                -- Vector3
ent:get_handle()                -- int
ent:get_ability(name)           -- table or nil
ent:has_modifier(name)          -- bool
```

```lua
for _, e in ipairs(entity_list:enemies()) do
    if e:has_modifier_state(EModifierState.MODIFIER_STATE_STUNNED) then
        print(e:get_name(), "is stunned")
    end
end
```

Also globally available:

- `dummy_vec` — a fake vector with `:Length()`, `:Length2D()`, `:LengthSqr()`, `:Length2DSqr()` all returning `0` and `+`/`-` returning itself. Used to avoid nil crashes in legacy compat code.
- `global_vars.curtime` — resolves to `Engine.GetCurTime`
- `trace.hull(...)` / `trace.line(...)` — legacy stubs returning `{hit=false, fraction=1.0, entity=nil}`. Use `Engine.TraceLine` for real traces.

---

### `ImGui` — UI primitives

Everything renders inside the game's ImGui context. Use for pop-up windows, checkboxes, buttons, key polling.

#### Windows

```lua
if ImGui.Begin("My Window", ImGui.WindowFlags_AlwaysAutoResize) then
    ImGui.Text("hello")
end
ImGui.End()   -- always call, even if Begin returned false
```

#### Window flags (integer bitmask, sum with `+`)

| Constant | Effect |
|---|---|
| `ImGui.WindowFlags_NoTitleBar` | No title bar |
| `ImGui.WindowFlags_NoResize` | Not resizable |
| `ImGui.WindowFlags_NoScrollbar` | Suppress scrollbars |
| `ImGui.WindowFlags_NoInputs` | Ignore all inputs |
| `ImGui.WindowFlags_NoBackground` | Fully transparent |
| `ImGui.WindowFlags_AlwaysAutoResize` | Size to content each frame |
| `ImGui.WindowFlags_NoNav` | Not focusable via gamepad/keyboard nav |
| `ImGui.WindowFlags_NoDecoration` | Combo of NoTitleBar+NoResize+NoScrollbar+NoCollapse |
| `ImGui.WindowFlags_NoFocusOnAppearing` | Don't steal focus when shown |
| `ImGui.WindowFlags_NoSavedSettings` | Don't persist position/size |

#### Widgets

| Function | Signature |
|---|---|
| `ImGui.Text(s)` | Draw text |
| `ImGui.TextColored(r, g, b, a, s)` | Coloured text |
| `ImGui.Button(label, w, h)` | Returns bool |
| `ImGui.Checkbox(label, value)` | Returns `(changed, newValue)` |
| `ImGui.Separator()` | Horizontal rule |
| `ImGui.Spacing()` | Extra vertical space |
| `ImGui.SameLine()` | Continue on same line |

#### Layout

| Function | Note |
|---|---|
| `ImGui.SetNextWindowPos(x, y)` | Absolute, always |
| `ImGui.SetNextWindowSize(w, h)` | First-use-only |
| `ImGui.SetNextWindowBgAlpha(a)` | 0..1 |
| `ImGui.BeginChild(id, w, h, border)` | Scrolling region — returns bool |
| `ImGui.EndChild()` | |
| `ImGui.SetScrollHereY(ratio)` | Scroll current child to ratio (0=top, 1=bottom) |

#### Input polling

| Function | Note |
|---|---|
| `ImGui.GetTime()` | Seconds since ImGui context creation |
| `ImGui.IsKeyPressed(vk)` | True the frame the key went down |
| `ImGui.IsKeyDown(vk)` | True while held |

```lua
if ImGui.IsKeyPressed(0x2D) then  -- INSERT
    log.info("insert pressed")
end
```

---

### `render` — draw list

Direct access to ImGui's foreground draw list. Coordinates are screen pixels.

| Function | Args | Purpose |
|---|---|---|
| `render.line(x1, y1, x2, y2, r, g, b, a, thick)` | | Line segment |
| `render.rect(x, y, w, h, r, g, b, a, thick, rounding)` | | Rectangle outline |
| `render.filled_rect(x, y, w, h, r, g, b, a, rounding)` | | Filled rectangle |
| `render.circle(x, y, radius, r, g, b, a, segments, thick)` | | Circle outline |
| `render.text(x, y, r, g, b, a, s)` | | Text at screen coords |

Colours are `0..1` floats.

```lua
callbacks.on_render(function()
    render.filled_rect(10, 10, 100, 30, 0, 0, 0, 0.75, 4)
    render.text(16, 16, 1, 1, 1, 1, "hello world")
end)
```

---

### `Render` — legacy alias

Old scripts used `Render.Text/FilledRect/Line/Poly`. All still work — they route to `render.*` internally.

```lua
Render.Text(x, y, r, g, b, a, "hi")
Render.FilledRect(x, y, w, h, r, g, b, a)
Render.Line(x1, y1, x2, y2, r, g, b, a)
Render.Poly(...)  -- no-op
```

---

### `log` and `print`

Per-script structured logger. Every entry gets prefixed with the script name and shown in the in-app **Debugger** console + the on-disk `debug.log`.

| Function | Level |
|---|---|
| `print(...)` | Info |
| `log.info(...)` | Info |
| `log.warn(...)` | Warn |
| `log.error(...)` | Error |

Args are stringified — accepts strings, numbers, booleans.

```lua
log.info("range =", range:get_int())
log.warn("weird state detected")
```

---

### `Debugger`

Access to the Lua console buffer.

| Function | Returns | Description |
|---|---|---|
| `Debugger.GetLogs()` | string | Full log buffer text |
| `Debugger.ClearLogs()` | nil | Clear the console |
| `Debugger.SetClipboardText(text)` | nil | Copy text to system clipboard |

```lua
if ImGui.Button("Copy logs", 100, 25) then
    Debugger.SetClipboardText(Debugger.GetLogs())
end
```

---

### `timers`

Frame-driven scheduler. Timers only tick while the owning script is enabled.

| Function | Returns | Description |
|---|---|---|
| `timers.after(ms, fn)` | int (id) | Fire once after N milliseconds |
| `timers.every(ms, fn)` | int (id) | Fire every N milliseconds forever |
| `timers.cancel(id)` | nil | Kill a scheduled timer |

```lua
timers.after(2000, function()
    log.info("2s elapsed")
end)

local heartbeat = timers.every(5000, function()
    log.info("still alive")
end)

-- later
timers.cancel(heartbeat)
```

---

### `storage`

Per-script in-memory key-value store. Not persisted across DLL restart — for that, use a `switch()` or `slider()` widget which auto-saves.

| Function | Returns | Description |
|---|---|---|
| `storage.set(key, value)` | nil | Any Lua value |
| `storage.get(key)` | value or nil | |
| `storage.clear()` | nil | Wipe this script's bucket |

```lua
storage.set("hits", (storage.get("hits") or 0) + 1)
```

---

### `docs`

Programmatic access to the binding registry + docgen. The engine auto-runs `docs.generate()` on load; scripts can force a regen.

| Function | Returns | Description |
|---|---|---|
| `docs.generate()` | bool | Regenerate `vittlock.d.lua` + `API.md` under `<ScriptsPath>/_docs` |
| `docs.output_dir()` | string | Where the docs will be written |
| `docs.namespaces()` | string[] | All registered API namespaces |
| `docs.list(ns)` | table[] | Entries in a namespace: `{name, signature, description}` |

```lua
for _, row in ipairs(docs.list("Engine")) do
    print(row.name, "::", row.signature)
end
```

---

### `math.angle_vectors` / `Engine.AngleVectors`

Convenience for aiming code.

```lua
local fwd = math.angle_vectors(QAngle.new(0, 90, 0))  -- Vector3
local fwd = Engine.AngleVectors(QAngle.new(0, 90, 0)) -- equivalent
```

---

### `InputBitMask_t`

Button-bit constants for `CUserCmd:AddButtonState` etc.

```
IN_NONE
IN_ATTACK
IN_JUMP
IN_DUCK
IN_FORWARD
IN_BACK
IN_USE
IN_MOVELEFT
IN_MOVERIGHT
IN_ATTACK2
IN_RELOAD
IN_SPEED
IN_WEAPON1
IN_ABILITY1
IN_ABILITY2
IN_ABILITY3
IN_ABILITY4
IN_ABILITY_HELD
IN_INNATE_1
```

```lua
callbacks.on_pre_createmove(function(cmd)
    cmd:AddButtonState(InputBitMask_t.IN_ATTACK)
end)
```

---

### `EModifierState`

305 constants from the Deadlock modifier schema. Use with `Engine.HasModifierState`, `Engine.EntityHasModifierState`, or an entity's `:has_modifier_state()`.

Selected common values:

```
MODIFIER_STATE_STUNNED               = 18
MODIFIER_STATE_INVULNERABLE          = 19
MODIFIER_STATE_TECH_INVULNERABLE     = 20
MODIFIER_STATE_UNSTOPPABLE           = 25
MODIFIER_STATE_INVISIBLE_TO_ENEMY    = 31
MODIFIER_STATE_SPRINTING             = 35
MODIFIER_STATE_AIR_DASHING           = 41
MODIFIER_STATE_BURNING               = 54
MODIFIER_STATE_SLOWED                = 61
MODIFIER_STATE_WALLSLIDE             = 67
MODIFIER_STATE_INFINITE_CLIP         = 69
MODIFIER_STATE_JUMP_DISABLED         = 71
MODIFIER_STATE_SLIDING               = 65
MODIFIER_STATE_FLYING                = 119
MODIFIER_STATE_SCOPED                = 120
MODIFIER_STATE_FROZEN                = 195
MODIFIER_STATE_PARRY_ACTIVE          = 221
MODIFIER_STATE_USING_ZIPLINE         = 84
MODIFIER_STATE_IN_COMBAT             = 163
MODIFIER_STATE_IS_ASLEEP             = 75
MODIFIER_STATE_KNOCKDOWN_IMMUNE      = 70
MODIFIER_STATE_STATUS_IMMUNE         = 24
```

Full 305-entry list: see [docs/modifier-states.md](modifier-states.md). Iterate at runtime with `docs.list("EModifierState")`.

---

## Cookbook

### 1. Toggle-on-keypress with on-screen notification

```lua
local m = ui.script()
m:category("Movement")
local enabled = m:switch("Feature", false)
local key     = m:keybind("Toggle", 0x56)   -- V

local active      = false
local notifyUntil = 0

callbacks.on_pre_createmove(function(cmd)
    if not enabled:get_bool() then return end
    if ImGui.IsKeyPressed(key:get_int()) then
        active = not active
        notifyUntil = ImGui.GetTime() + 2.0
    end
    if active then
        -- your logic
    end
end)

callbacks.on_render(function()
    if ImGui.GetTime() > notifyUntil then return end
    local s = Engine.GetScreenSize()
    ImGui.SetNextWindowPos(s.w * 0.5 - 60, s.h * 0.28)
    ImGui.SetNextWindowBgAlpha(0.85)
    local flags = ImGui.WindowFlags_NoTitleBar + ImGui.WindowFlags_NoResize
                + ImGui.WindowFlags_NoInputs   + ImGui.WindowFlags_NoNav
                + ImGui.WindowFlags_NoFocusOnAppearing + ImGui.WindowFlags_AlwaysAutoResize
    if ImGui.Begin("##Notify", flags) then
        ImGui.TextColored(active and 0.35 or 1.0, active and 1.0 or 0.35, 0.4, 1,
                          active and "FEATURE ON" or "FEATURE OFF")
    end
    ImGui.End()
end)
```

### 2. Enemy ESP box using WorldToScreen + bone position

```lua
local m = ui.script()
m:category("Visuals")
local enabled = m:switch("Enemy ESP", true)
local color   = m:color("Box tint", {1, 0.3, 0.3, 1})

callbacks.on_render(function()
    if not enabled:get_bool() then return end
    local c = color:get_color()
    for _, e in ipairs(entity_list:enemies()) do
        local head  = Engine.GetBonePosition(e:get_handle(), "Head")
        local feet  = e:get_origin()
        local pHead = Engine.WorldToScreen(head)
        local pFeet = Engine.WorldToScreen(feet)
        if pHead.visible and pFeet.visible then
            local h = pFeet.y - pHead.y
            local w = h * 0.5
            render.rect(pHead.x - w * 0.5, pHead.y, w, h, c[1], c[2], c[3], c[4], 1.5, 0)
        end
    end
end)
```

### 3. Auto-parry on incoming melee (event-driven)

```lua
local m = ui.script()
m:category("Combat")
local enabled = m:switch("Auto Parry", false)

callbacks.on_add_modifier(function(mod, ent)
    if not enabled:get_bool() then return end
    if ent:get_handle() ~= Engine.GetLocalPlayerHandle() then return end
    local name = mod.name
    if name:find("melee_target") or name:find("charged_melee") then
        -- press parry next tick
        storage.set("parry_pending", ImGui.GetTime() + 0.05)
    end
end)

callbacks.on_pre_createmove(function(cmd)
    local due = storage.get("parry_pending")
    if due and ImGui.GetTime() >= due then
        cmd:AddButtonState(InputBitMask_t.IN_ATTACK2)
        storage.set("parry_pending", nil)
    end
end)
```

### 4. Periodic heartbeat via timer + storage

```lua
local m = ui.script()
m:category("Utility")
m:switch("Heartbeat", true)
m:button("Reset counter", function() storage.set("n", 0) end)

timers.every(5000, function()
    storage.set("n", (storage.get("n") or 0) + 1)
    log.info(string.format("beat %d", storage.get("n")))
end)
```

### 5. HUD readout of local velocity + curtime

```lua
local m = ui.script()
m:category("Info")
local show = m:switch("Show HUD", true)

callbacks.on_render(function()
    if not show:get_bool() then return end
    local v = Engine.GetLocalVelocity()
    local speed = v:Length2D()
    local flags = ImGui.WindowFlags_NoTitleBar + ImGui.WindowFlags_AlwaysAutoResize
                + ImGui.WindowFlags_NoInputs   + ImGui.WindowFlags_NoNav
    ImGui.SetNextWindowPos(20, 20)
    ImGui.SetNextWindowBgAlpha(0.65)
    if ImGui.Begin("##hud", flags) then
        ImGui.Text(string.format("speed:   %.0f", speed))
        ImGui.Text(string.format("curtime: %.1f", Engine.GetCurTime()))
    end
    ImGui.End()
end)
```

### 6. Combo + colour + persistent scaffolding

```lua
local m = ui.script()
m:category("Combat")

local enabled  = m:switch("Enabled", true)
local mode     = m:combo("Mode", {"Safe", "Fast", "Insane"}, 1)
local tint     = m:color("Tint", {0.2, 1.0, 0.6, 1.0})
local range    = m:slider_int("Range", 0, 4096, 1200)

callbacks.on_render(function()
    if not enabled:get_bool() then return end
    local c = tint:get_color()
    local modes = {"Safe", "Fast", "Insane"}
    render.text(30, 30, c[1], c[2], c[3], c[4],
        string.format("mode=%s range=%d", modes[mode:get_int() + 1] or "?", range:get_int()))
end)
```