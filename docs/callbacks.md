# Callbacks

After a script's top level has run, the only way it runs again is through callbacks. The global `callback` table has one entry per event. Each entry is a `callback_reg`: call `:set(fn)` to add a handler and `:unset(fn)` to remove it. This page lists every event: when it fires, what it passes, and what a return value does. It also covers the shared script environment (`print`, `require`, `load`, `loadfile`, `dofile`) and the load order.

```lua
local function tick()
    -- game logic, once per frame
end

callback.on_frame:set(tick)
-- later, to stop:
callback.on_frame:unset(tick)
```

## Registering handlers

### `callback.<event>:set(fn)`

Adds `fn` as a handler for the event. Several scripts can each set handlers on the same event, and one script can set more than one. Handlers run in the order they were set.

- The handler belongs to the script whose code is running when `set` is called. Its `print` output and errors go to that script's log.
- Setting the same function twice registers it twice, so it runs twice per event.
- You can call `set` from the top level or from inside another handler.

### `callback.<event>:unset(fn)`

Removes every registration of `fn` from this event. Functions are compared by identity, so keep a reference to the function you passed to `set`. An anonymous function can't be unset later.

A handler removed while the event is being dispatched does not run for the rest of that dispatch.

`tostring(callback.on_frame)` returns `"callback_reg(on_frame)"`.

### Errors

An error raised in a handler is caught. It goes to the owning script's log in the menu (Lua tab), prefixed with the event name (`on_frame: ...`). The other handlers still run, and the failing handler is called again the next time the event fires. A handler that fails with the same message every frame is logged once, not every frame.

If a script's top level raises an error, the rest of that file doesn't run. Handlers it set before the error stay registered.

### Disabled scripts

The handlers of a script that is turned off in the menu are skipped.

### Return values

Most events ignore what the handler returns. Three events can block something:

| Event | Return `false` to |
|---|---|
| `on_key_event` | keep the key or mouse message from the menu and the game window |
| `on_send_net_message` | stop the network message from being sent |
| `on_send_gc_message` | stop the Game Coordinator message from being sent |

All handlers of the event still run. If any of them returns `false`, the thing is blocked. Returning `nil`, `true`, or nothing lets it through. A handler that raises an error doesn't count as a block.

### Threading

`on_frame`, the createmove events and the game events (entities, modifiers, particles, network and GC messages) run on the game's main thread. `on_key_event` runs where the game window handles its messages. `on_draw` runs on the render path, which can be a different thread from the main one. Keep game logic out of `on_draw` and drawing out of everything else: `Render.*` only draws inside `on_draw`, and Panorama calls are only allowed in `on_frame` and `on_createmove` (they raise an error elsewhere). A simple pattern that is always safe: compute in `on_frame`, store plain values (numbers, strings, `Vector`s) in locals, and only read those in `on_draw`.

Handlers never run at the same time: every event takes the same script lock, so you don't need locking of your own, even between `on_draw` and the game-thread events.

## Order of events

Each game frame, in this order:

1. Queued events from the game since the last frame: `on_add_modifier`, `on_particle_create` / `on_particle_update_transform` / `on_particle_destroy`, `on_received_net_message`.
2. `on_frame`.

For each user command your client builds:

1. `on_pre_createmove`, early in building the command.
2. Later, for the same tick: queued `on_late_add_entity`, `on_add_modifier` and particle events, then `on_createmove`, then `on_post_createmove`.

Each rendered frame: `on_draw`.

These fire as soon as they happen, outside that order: `on_add_entity`, `on_remove_entity`, `on_send_net_message`, `on_send_gc_message`, `on_receive_gc_message`, `on_key_event`.

Queued modifier and particle events fire at whichever comes first, the next frame or the next command; late adds only fire at the next command. Queued events are only collected while at least one handler is set for that event, so a handler doesn't see things that happened before it was set.

## Event reference

### `on_scripts_loaded()`

Fires once, after every script of a full load has run its top level. Use it for setup that needs globals defined by scripts that load later than yours. It doesn't fire after a single script is reloaded on its own.

```lua
callback.on_scripts_loaded:set(function()
    if not my_shared_lib then
        print("my_shared_lib.lua is missing")
    end
end)
```

### `on_pre_createmove(cmd)`

Fires early in building each user command, before the game's movement processing for it.

| Name | Type | Description |
|---|---|---|
| `cmd` | [`CUserCmd`](usercmd.md) | The command being built. Only valid during the call. |

The three createmove events only fire in a match, while your client is building commands.

### `on_createmove(cmd)`

Fires once per user command, after movement processing and after VITTLOCK's own hero features have run on it. This is the place to press buttons, change movement and aim (`cmd:aim`). Panorama calls are allowed here.

| Name | Type | Description |
|---|---|---|
| `cmd` | [`CUserCmd`](usercmd.md) | The command being built. Only valid during the call. |

```lua
callback.on_createmove:set(function(cmd)
    local me = entity_list.local_pawn()
    if not me or not me:is_alive() then return end
    -- read or change cmd here (see usercmd.md)
end)
```

### `on_post_createmove(cmd)`

Fires right after every `on_createmove` handler has run, with the same command. Use it to see or adjust the command after all `on_createmove` handlers have made their changes.

| Name | Type | Description |
|---|---|---|
| `cmd` | [`CUserCmd`](usercmd.md) | The same command `on_createmove` got. Only valid during the call. |

### `on_frame()`

Fires once per game frame, in the main menu as well as in a match. Put game logic, timers and Panorama calls here. Before it fires, the queued events of that frame are delivered (see [Order of events](#order-of-events)).

```lua
local last = 0
callback.on_frame:set(function()
    local now = chronos.nanotime()
    if now - last < 1 then return end   -- once a second
    last = now
    print("tick", global_vars.tickcount())
end)
```

### `on_draw()`

Fires once per rendered frame, on the render path, in the main menu too. `Render.*` functions draw only inside this callback. Don't run game logic here; compute in `on_frame` and draw the stored results.

```lua
local text = ""
callback.on_frame:set(function()
    text = ("curtime %.1f"):format(global_vars.curtime())
end)
callback.on_draw:set(function()
    Render.Text(0, 16, text, Vec2(20, 20), Color(255, 255, 255))
end)
```

### `on_add_entity(ent)`

Fires when the game creates an entity, at that moment.

| Name | Type | Description |
|---|---|---|
| `ent` | [`entity`](entities.md#entity) \| [`player_pawn`](entities.md#player_pawn) \| [`ability`](entities.md#ability) | The new entity: a `player_pawn` for hero pawns, an `ability` for abilities and items, an `entity` otherwise. |

The entity has just been created, so many of its fields may not be filled in yet. If you need them, use `on_late_add_entity`.

### `on_late_add_entity(ent)`

Fires for each entity created since the previous user command, just before `on_createmove`. By then the entity's fields have been filled in. Same argument as `on_add_entity`.

Entities removed again before that command are not reported. Entities are only collected while a handler for this event is set.

### `on_remove_entity(ent)`

Fires when the game is about to remove an entity, while it can still be read. Same argument as `on_add_entity`.

```lua
local tracked = {}
callback.on_add_entity:set(function(ent)
    if ent:get_class_name() == "C_CitadelPlayerPawn" then
        tracked[ent:get_handle()] = true
    end
end)
callback.on_remove_entity:set(function(ent)
    tracked[ent:get_handle()] = nil
end)
```

### `on_add_modifier(mod, target, owner)`

Fires when a modifier has been applied to an entity. The event is delivered at the next frame or command, and only if the modifier is still on its target by then.

| Name | Type | Description |
|---|---|---|
| `mod` | [`modifier`](entities.md#modifier) | The modifier. |
| `target` | [`entity`](entities.md#entity) \| [`player_pawn`](entities.md#player_pawn) \| [`ability`](entities.md#ability) | The entity it was applied to. |
| `owner` | [`entity`](entities.md#entity) \| [`player_pawn`](entities.md#player_pawn) \| [`ability`](entities.md#ability) \| `nil` | The modifier's caster, `nil` when there is none or it can't be resolved. |

```lua
callback.on_add_modifier:set(function(mod, target, owner)
    local me = entity_list.local_pawn()
    if me and target == me then
        print(("%s on me from %s, %.1f s left"):format(
            mod:get_class_name(), owner and owner:get_name() or "?", mod:get_remaining_duration()))
    end
end)
```

### `on_received_net_message(id, msg)`

Fires for network messages received from the server. Messages are queued as they arrive and delivered at the start of the next frame.

| Name | Type | Description |
|---|---|---|
| `id` | `integer` | The message type id. |
| `msg` | `lightuserdata` | The decoded message. Read it with `protobuf.decodeToJSONfromObject(msg)` (see [network](network.md)). Only valid during the call. |

The high-volume engine messages (tick, client move and packet entities) are not reported. If more than 4096 messages are waiting, the oldest are dropped. The return value is ignored; received messages can't be blocked.

```lua
local WATCH_ID = 208   -- the message type id you are interested in

callback.on_received_net_message:set(function(id, msg)
    if id ~= WATCH_ID then return end
    local data = utils.json_decode(protobuf.decodeToJSONfromObject(msg))
    if data then print(utils.json_encode(data)) end
end)
```

### `on_send_net_message(id, msg)`

Fires when your client is about to send a network message. Return `false` to block it.

| Name | Type | Description |
|---|---|---|
| `id` | `integer` | The message type id. |
| `msg` | `lightuserdata` | The message. Read it with `protobuf.decodeToJSONfromObject(msg)` (see [network](network.md)). Only valid during the call. |

Returns: `false` to stop the message; anything else lets it through.

Only messages sent from the game's main thread are reported; messages sent from other threads pass through unseen and can't be blocked. The handler runs while the message is being sent, so keep it short. To send your own message, see [`net_channel.send_net_message`](network.md).

### `on_send_gc_message(id, body, size)`

Fires when your client is about to send a Game Coordinator message. Return `false` to block it.

| Name | Type | Description |
|---|---|---|
| `id` | `integer` | The GC message type id. |
| `body` | `lightuserdata` | The message body (the encoded protobuf, without the GC header). Only valid during the call. |
| `size` | `integer` | Body size in bytes. Can be `0`; check it before decoding. |

Returns: `false` to stop the message; anything else lets it through.

Decode the body with `gc.decode(id, body, size)` or `gc.decode_message(name, body, size)` (see [network](network.md)). Only messages sent from the game's main thread are reported.

### `on_receive_gc_message(id, body, size)`

Fires when a Game Coordinator message arrives. Same arguments as `on_send_gc_message`; the return value is ignored. Only messages handled on the game's main thread are reported.

```lua
callback.on_receive_gc_message:set(function(id, body, size)
    print("GC in:", id, gc.get_message_name(id), size .. " bytes")
end)
```

### `on_particle_create(data)`

Fires when the server creates a particle effect. Effects the client creates on its own (without the server) are not reported. Delivered at the next frame or command.

| Field | Type | Description |
|---|---|---|
| `entity` | [`entity`](entities.md#entity) \| `nil` | The entity the particle belongs to, `nil` when unknown. |
| `entity_for_modifiers` | [`entity`](entities.md#entity) \| `nil` | Same value as `entity`. |
| `index` | `integer` | The particle's index; the transform and destroy events use the same index. |
| `name` | `string` | The particle system's resource name. |
| `hash` | `integer` | Hash of the name, the same value `utils.subclass_id(name)` returns. |

```lua
local live = {}
callback.on_particle_create:set(function(p)
    if p.name:find("ultimate") then live[p.index] = p.name end
end)
callback.on_particle_destroy:set(function(p)
    live[p.index] = nil
end)
```

### `on_particle_update_transform(data)`

Fires when the server moves one of a particle's control points. Delivered at the next frame or command.

| Field | Type | Description |
|---|---|---|
| `index` | `integer` | The particle's index. |
| `control_point` | `integer` | The control point that moved. |
| `position` | [`Vector`](types.md#vector) | Its new position. |
| `orientation` | [`Angle`](types.md#angle) | Always `Angle(0, 0, 0)`. |
| `interpolation_interval` | `number` | Always `0`. |

### `on_particle_destroy(data)`

Fires when the server destroys a particle effect. Delivered at the next frame or command.

| Field | Type | Description |
|---|---|---|
| `index` | `integer` | The particle's index. |
| `destroy_immediately` | `boolean` | Always `false`. |

### `on_key_event(data)`

Fires when the game window receives a key, mouse button or mouse wheel message. Return `false` to keep the message from the menu and the game window.

| Field | Type | Description |
|---|---|---|
| `data.key` | `integer` | An `Enum.ButtonCode` value (`KEY_A`, `KEY_SPACE`, `KEY_MOUSE1`..`KEY_MOUSE5`, `KEY_MWHEELUP`, `KEY_MWHEELDOWN`, ...). |
| `data.event` | `integer` | An `Enum.KeyEvent` value: `KEY_DOWN`, `KEY_UP`, `SCROLL_UP` or `SCROLL_DOWN`. |

Returns: `false` to block the message; anything else lets it through.

Notes:
- Key auto-repeat is not reported: holding a key gives one `KEY_DOWN` and one `KEY_UP`.
- A double click is reported as a second `KEY_DOWN`.
- Keys without a button code are not reported. Mouse movement is not reported.
- The menu toggle key is handled before this event and can't be blocked.
- Blocking keeps the message from the menu and the game window, but the game may still read the key through its own input. Don't rely on it to hide a key from the game.

```lua
callback.on_key_event:set(function(data)
    if data.key == Enum.ButtonCode.KEY_F6 and data.event == Enum.KeyEvent.KEY_DOWN then
        print("F6 pressed")
        return false   -- swallow it
    end
end)
```

### Events that don't fire yet

These entries exist in `callback`, so `:set` and `:unset` work on them without an error, but nothing fires them in this version. Their handlers are never called:

`on_target_acquired`, `on_animation_start`, `on_animation_end`, `on_pre_framestage`, `on_post_framestage`, `on_particle_update`, `on_remove_modifier`, `on_bullet_create`, `on_start_sound`.

## Scripts and the shared environment

### Load order

Every `.lua` file under `C:\VITTLOCK\scripts\v2\` (subfolders included) is loaded as a script. Files are sorted by file name, ignoring the folder they are in. Names that start with a character other than a letter or digit (`_init.lua`, `!lib.lua`) come first, then the rest, case-insensitively. When two files have the same name, the full path decides.

All scripts share one global environment. A global set by one script is visible to every script that runs after it, and `_G` is that shared environment. Declare everything `local` unless you mean to share it. When one script needs another's globals at startup, do that setup in [`on_scripts_loaded`](#on_scripts_loaded).

### Reloads

A **full reload** happens when the game starts, after a map change, and when you reload all scripts from the menu. It:
- saves the [`db`](storage.md#db) and keeps it,
- removes every handler of every script,
- creates a fresh shared environment (every global is gone) and clears the `require` cache,
- clears [`global_ctx`](storage.md#global_ctx),
- loads every script again in order, then fires `on_scripts_loaded`.

A **single-script reload**, for example when hot reload sees that you saved the file, removes only that script's handlers and runs the file again. The shared environment, other scripts' globals, the `require` cache and `global_ctx` all stay, so globals the script set during its previous run still exist. `on_scripts_loaded` doesn't fire.

### `print(...)`

Converts each argument with `tostring`, joins them with tabs, and writes the line to the log of the script whose code is running: the script whose top level is executing, or the script that set the handler currently running. The log is shown in the menu's Lua tab.

### `require(name)`

Loads a module from the scripts folder and returns its value.

| Name | Type | Description |
|---|---|---|
| `name` | `string` | Module name. Dots become folders: `"lib.mathx"` is `scripts\v2\lib\mathx.lua`, else `scripts\v2\lib\mathx\init.lua`. |

Returns: what the module returned, or `true` when it returned nothing.

- The module runs in the shared environment and receives `name` as `...`.
- The result is cached: later `require` calls with the same name return the cached value without running the file again. The cache is cleared by a full reload.
- Errors while loading or running the module are raised from `require`.
- Names that aren't found in the scripts folder go to Lua's standard `require` (`package.path` / `package.cpath`). Modules loaded that way don't run in the shared environment and don't see the API.

Every `.lua` file under `scripts\v2\` is loaded as a script, except files inside `scripts\v2\lib\`: those only run when something requires them. Put modules there. A module placed elsewhere runs once as a script (with an empty `...`) and once more on its first `require`; if you must keep one outside `lib\`, return early when `...` is empty:

```lua
-- scripts\v2\lib\mathx.lua
if select("#", ...) == 0 then return end   -- loaded as a script, not required

local M = {}
function M.clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
return M
```

```lua
-- scripts\v2\my_script.lua
local mathx = require("lib.mathx")
print(mathx.clamp(5, 0, 3))   -- 3
```

### `load(chunk [, chunkname [, mode [, env]]])` / `loadfile(filename [, mode [, env]])`

Lua's standard `load` and `loadfile`, except that when `env` is not given the chunk runs in the shared script environment, so it sees the API and your globals. Passing an `env` table works as usual.

`loadfile` paths that aren't absolute are relative to the game's working directory, not the scripts folder. Use full paths.

### `dofile(filename)`

Loads `filename` with `loadfile` (in the shared environment), runs it, and returns its results. Raises an error if the file can't be loaded.

### Standard libraries

The standard libraries available to scripts are listed in [core](core.md#standard-libraries); the additions to `table` and `math` are in [types](types.md#table-extensions).
