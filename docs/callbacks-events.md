# Callbacks & events

The `callbacks` module is the entire interactivity surface. The engine maintains a typed list of 20 events; the Lua side registers function callbacks on it.

This doc covers every event, its dispatch timing, its arguments, and accepts/pitfalls.

---

## Registration conventions

Two call forms, both supported.

```lua
-- Modern: script implied via __SCRIPT_NAME__
callbacks.on_FRAME(function(args) ... end)        -- returns a token (int)

-- Legacy: script name first
callbacks.on_FRAME("MyScript", function(args) ... end)
```

| Form | Use when |
|---|---|
| Modern | Any new script. Default. |
| Legacy | You have an old script that already passes the script name; you want to subscribe a different script from another. |

Both return a `CallbackToken` (integer starting at 1, monotonically increasing). Unsubscribe:

```lua
callbacks.unsubscribe(tok)
```

Removing the script (reload / shutdown) calls `UnsubscribeAllFor(owner)`, so your tokens die automatically — no leak.

---

## Bus gating — the enabled flag

Every dispatched callback skips any subscription whose owning script's enabled flag is `false`. The enabled flag is set after script load from the **first** widget's value.

So the **first** widget added via `m:switch(...)` / `UI.AddSwitch(...)` is the master switch. If that switch is off, *no* callbacks fire. Always guard anyway:

```lua
if not enabled:get_bool() then return end
```

`__SCRIPT_NAME__` is re-stamped before each callback fires, so you can use `log.*` / `storage.*` / `ui.script()` inside even if you called it from a cross-script subscription.

---

## Per-frame dispatch flow

The engine fires events from its per-tick hooks: pre-cmd, post-cmd, render. Args are forwarded as native Lua values — table, Vector3, QAngle, CUserCmd, int.

Polling for entity deltas, key edges, and hot-reload only runs from the post-cmd hook — never from pre-cmd. So entity/key deltas are *post-move* events only.

Each poll has a zero-subscriber early-out — events that no script has subscribed to are completely free.

---

## Complete event table

| Event | Lua alias | Dispatched in | Arg(s) |
|---|---|---|---|
| `on_pre_createmove` | `on_createmove` | pre-cmd hook | `cmd:CUserCmd` |
| `on_post_createmove` | `on_postmove` | post-cmd hook | `cmd:CUserCmd` |
| `on_frame` | — | post-cmd hook | `()` |
| `on_render` | `on_draw` | render hook | `()` |
| `on_render_world` | — | render hook (same pass — reserved) | `()` |
| `on_add_modifier` | — | entity poll (post-cmd) | `mod:table, ent:table` |
| `on_remove_modifier` | — | **dispatch not wired** | `mod:table, ent:table` |
| `on_particle_create` | — | entity poll (post-cmd) | `data:table` |
| `on_particle_destroy` | — | entity poll (post-cmd) | `data:table` |
| `on_bullet_create` | — | bullet fire hook | `bullet:table` |
| `on_entity_create` | — | entity poll (post-cmd) | `handle:int` |
| `on_entity_destroy` | — | entity poll (post-cmd) | `handle:int` |
| `on_local_spawn` | — | local pawn handle change (post-cmd) | `()` |
| `on_local_death` | — | local pawn handle change (post-cmd) | `()` |
| `on_menu_open` | — | menu focus gain | `()` |
| `on_menu_close` | — | menu focus loss | `()` |
| `on_key_pressed` | — | key poll (post-cmd, vk 8..255) | `vk:int` |
| `on_key_released` | — | key poll (post-cmd) | `vk:int` |
| `on_script_loaded` | — | script load, once on first load | `()` |
| `on_script_unloaded` | — | **not currently dispatched** | `()` |

### Not dispatched / partial

- `on_remove_modifier` — bound, but the polling logic only fires `on_add_modifier`. Track removal via `Engine.EntityHasModifier` polling.
- `on_script_unloaded` — declared, never dispatched. Any subscription will simply never fire. Future work.
- `on_render_world` — wired to the same handler as `on_render`. No separate world-space pass currently.

---

## Timings

### `on_pre_createmove(cmd)`

Fires per-game-tick before the user command is constructed/validated. The `cmd` here is the live `CUserCmd` that will be sent to the server this tick. Mutating buttons, view angles, movement axes here *changes what the server sees*. Validates and clamps happen client-side after this — angles might be normalized before send.

Per-frame arbitration: the cmd's base sub-message is checked on every accessor — if the cmd shape doesn't include a base (rare), the getter/setter silently no-ops or returns zero. `cmd:SetCameraPosition(x,y,z)` only writes if the cmd already carries a camera position, and silently drops on `Inf`/`NaN`.

Avoid heavy work here — this is called per-tick at the game's tick rate (~64 Hz by default). If you need per-frame work that isn't cmd manipulation, use `on_frame` instead.

### `on_post_createmove(cmd)`

Same `cmd` post-package. The cmd is sealed into the wire format by now — **mutating `cmd` here is mostly too late** for the server but is read by prediction/render in the same frame. Use it to *observe* your own send.

This callback is the timing parent for: `on_frame`, timers, entity polls, key polls, hot-reload. They all run on the same engine lock.

### `on_frame()`

Runs unconditionally after `on_post_createmove` on the same dispatch tick. No `cmd` arg — use it for non-cmd per-frame work. Anything that touches the filesystem (logging) or doing polling is fine here.

### `on_render()` / `on_draw()`

Fires from the render hook — once per render frame, on the ImGui draw context. Absolutely the only callback in which it is safe to call `ImGui.*` / `render.*`. Calling `render.*` from `on_frame` writes to the foreground draw list, which is fine technically, but most Lua code paths will mix the two up — keep renders in `on_render`.

### `on_render_world()`

Currently wired to the same handler as `on_render`. There is no separate world-space pass. If you want world-space overlay behaviour, render inside `on_render` and project world positions using `Engine.WorldToScreen`.

### `on_add_modifier(mod, ent)`

Fires from the entity poll after a frame's entity scan. The scan walks every entity index and diffs against the last-seen set so this **only fires per-discrete-create**, not every frame the modifier is active. If a modifier is already-present when the script loads, no event fires for that modifier — track existing ones via `Engine.EntityHasModifier(h, name)` at `on_script_loaded`.

`mod` table:

```lua
{
  name      = "...",            -- lowercased RTTI (e.g. "ctdota_modifier_stunned")
  duration  = 1.5,             -- seconds
  get_name     = function() return name end,
  get_duration = function() return duration end,
}
```

`ent` table:

```lua
{
  get_handle = function() return handle end,
  valid      = function() return true end,
  get_name   = function() return designerName end,
  m_iTeamNum = 3,
}
```

Note: `valid()` always returns `true` here — the scan only carries real entities, not predictions.

### `on_particle_create(data)` / `on_particle_destroy(data)`

Same polling model as modifiers. The engine matches entities whose `SchemaClassBinding` name contains `"Particle"`. `data`:

```lua
{ name = "particles/ability_fx/...", handle = 12345 }
```

The handle is the particle's entity handle, not the original parent.

### `on_bullet_create(bullet)`

The richest payload. Dispatched from the bullet fire hook. The engine walks through the three candidate weapon handles and picks the first entity name containing "ability" or "weapon", else the first non-empty.

```lua
callbacks.on_bullet_create(function(b)
    print(b.shooter_handle, b.weapon_name, b.range)
    print(b.shooter:get_name(), b.shooter:get_origin())
    local from = b.start      -- {x=x, y=y, z=z}
    local to   = b.target     -- alias b.end_pos
    local dir  = b.direction  -- unit vector
end)
```

The shooter is resolved from the pawn pointer when the shooter handle sent on the wire was the sentinel `0xFFFFFFFF`. The lookup fails soft — `shooter.valid()` returns `false` if not found.

### `on_entity_create(handle)` / `on_entity_destroy(handle)`

Polled via diff. Receive just an integer handle. Use `Engine.GetEntityName(h)`, `Engine.GetEntityOrigin(h)`, `Engine.IsPlayer(h)` to enrich.

Spawn death cycle for any entity: `on_entity_create` fires once when first seen; `on_entity_destroy` fires when the next scan would no longer include it. There is **no** per-frame polling of an entity's existence; that's on you.

### `on_local_spawn()` / `on_local_death()`

Triggered by the local pawn handle-change detection at the start of the post-cmd hook. The engine compares the current local pawn handle to the previous one:

- New handle appeared → `on_local_spawn`
- Old handle disappeared → `on_local_death`

Spawn fires **before** the first `on_frame` runs in that life. Use it to reset per-life state (timers, storage keys, etc.).

### `on_menu_open()` / `on_menu_close()`

The menu render pass tracks its own focus state. Transition into focus → `on_menu_open`. Transition out of focus → `on_menu_close`. Fires every time you tab away without unpausing.

### `on_key_pressed(vk)` / `on_key_released(vk)`

Edge-detected from `GetAsyncKeyState` across VK 8..255. Receives the Win32 virtual-key code (e.g. `0x2D` is `VK_INSERT`, `0x56` is `V`).

Gated: the key poll early-outs when no script subscribes to either key event — if no script registers, polling does not occur.

⚠️ Polling is *current frame only* — it does not queue. If a script subscribes mid-key-press, no event fires for the current press; you'll catch the next one.

### `on_script_loaded()`

Fires once after a successful script load **on first load**. On hot-reload, the first-load flag resets so the event fires again. You can use it to scan existing modifiers, set up local timer schedules, etc.

⚠️ Inside the callback, `__SCRIPT_NAME__` is already your script's name — fine to call `Engine.*` etc. But the bus is mid-dispatch inside the engine lock, so do not call `ReloadScripts` here (would deadlock).

### `on_script_unloaded()`

Binding declared; **dispatcher not wired**. Any subscription handler will never fire. The intention is for it to run prior to script teardown on reload/shutdown — currently the engine just unsubscribes everything for the script without dispatching first. If you need state cleanup, do it in your script's reload path.

---

## `callbacks.count(name)` → integer

Returns the number of currently-registered handlers for a named event. The name must match the bus event name (e.g. `"on_render"`). Unknown names return `0`. Useful for conditional behaviour: skip expensive per-frame work when no script actually subscribes.

```lua
if callbacks.count("on_add_modifier") > 0 then
    -- entity poll will be active this frame
end
```

⚠️ This counts **across all scripts** — not just yours. If you need per-script, you'd need to track it yourself.

---

## Legacy `callback` table

The legacy property-style alias. Each `callback.on_X` is a table with a `.set(fn)` method that calls `callbacks.on_X(fn)` under the hood.

```lua
callback.on_pre_createmove:set(function(cmd) ... end)
callback.on_frame:set(function() ... end)
callback.on_render:set(function() ... end)
```

Bound legacy aliases:

```
on_pre_createmove, on_post_createmove, on_frame, on_render, on_draw,
on_add_modifier, on_particle_create, on_bullet_create, on_scripts_loaded
```

`callback.on_scripts_loaded:set(fn)` immediately calls `fn()` — there's no real bus subscription; this matches the legacy behaviour where scripts_loaded was meant to fire on the universe-manager post-init.

---

## Anti-patterns & pitfalls

### Re-entrant use

- Don't call `ReloadScripts()` from any callback. It acquires the same engine lock; you'll deadlock.
- Safe operations: any `Engine.*`, `entity_list.*`, `render.*`, `ImGui.*`, `storage.*`, `timers.*`, `log.*`.

### Heavy work in `on_pre_createmove`

This is per-tick at the server tick rate. Don't iterate the entity list, don't allocate big tables. Read what you cached in `on_frame`.

### Top-level `callbacks.on_render` with menu-drawing widgets

You'll be double-rendering — once yours, once the C++ menu render pass for the same widget. Use `m:switch/slider_*/button` etc. to register *menu* widgets, and use `ImGui.*` *inside* `on_render` only for overlays/inspectors that aren't per-script menu cards.

### Calling `cmd:SetViewAngles` from `on_post_createmove`

Too late for the wire message. Server may correct it. Set in `on_pre_createmove` only.

### Subscribing to `on_remove_modifier` / `on_script_unloaded`

Currently no-ops for behaviour. Track via polling `Engine.EntityHasModifier(h, name)` until the engine wires the dispatcher. Subscribing does no harm — it just never fires.

---

## See also

- [engine-accessors.md](engine-accessors.md) — `Engine.*` query surface
- [cusercmd-input.md](cusercmd-input.md) — `CUserCmd` mutation details