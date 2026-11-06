# Core

Small global tables every script uses: game time and ticks (`global_vars`), the match (`game_rules`), latency (`net_channel.latency`), console variables (`convar`), a high-resolution clock (`chronos`) and JSON (`utils.json_encode` / `utils.json_decode`). This page also lists the standard Lua libraries available to scripts.

All of these can be called from any callback and from a script's top level.

## global_vars

The engine's frame and tick globals. Every function returns `0` when the globals aren't available yet.

### `global_vars.curtime()`

The current game time in seconds. Use it for anything tied to the match clock (cooldowns, durations).

Returns: `number`.

### `global_vars.tickcount()`

The current tick count.

Returns: `integer`.

### `global_vars.interval_per_tick()`

Seconds per server tick.

Returns: `number`.

### `global_vars.framecount()`

The current frame count.

Returns: `integer`.

### `global_vars.absoluteframetime()`

Real time the last frame took, in seconds.

Returns: `number`.

```lua
callback.on_frame:set(function()
    local ticks_per_second = 1 / math.max(global_vars.interval_per_tick(), 1e-6)
    -- ...
end)
```

## game_rules

### `game_rules.get()`

The match's game rules object (`C_CitadelGameRules`). Read its networked fields by name, like any [raw_struct](entities.md#raw_struct-raw_ptr-cpanoramaimagename).

Returns: `raw_struct`, or `nil` out of a match.

```lua
local rules = game_rules.get()
if rules then
    print("match started at", rules.m_flGameStartTime)
end
```

### `game_rules.game_time()`

The current game time in seconds. Same value as `global_vars.curtime()`.

Returns: `number`.

### `game_rules.match_id()`

The current match id.

Returns: `integer`, `0` when there is no match.

## net_channel

To send network messages, see [`net_channel.send_net_message`](network.md).

### `net_channel.latency()`

An estimate of the one-way latency to the server, in seconds. It is smoothed over recent commands, capped at `0.25`, and only updates while you are in a match.

Returns: `number`, `0` until the first estimate.

```lua
-- Lead a target by your latency.
local function lead(pos, vel)
    return pos + vel * net_channel.latency()
end
```

## convar

`convar` gives you any console variable by name: `convar.sv_gravity`, or `convar["name"]` for names that aren't valid Lua identifiers. Indexing always returns a `convar_table`, even for names that don't exist; reading a convar that doesn't exist returns `nil`. A convar that isn't found yet is looked up again every few seconds, so a convar that appears later starts working on its own.

Only numeric and boolean convars can be read and written. String and vector convars read as `nil`.

### `convar_table:float([value])`

Without an argument, reads the value as a number. With `value`, writes it.

| Name | Type | Description |
|---|---|---|
| `value` | `number?` | New value. Omit to read. |

Returns: the value (`number`) when reading, `nil` when the convar isn't found or isn't numeric. Always `nil` when writing.

### `convar_table:int([value])`

Like `:float`, but reads the value truncated to an integer, and truncates `value` toward zero before writing it.

| Name | Type | Description |
|---|---|---|
| `value` | `number?` | New value. Omit to read. |

Returns: `integer` or `nil`, as above.

### `convar_table:bool([value])`

Reads the value as a boolean (any non-zero value is `true`), or writes `value` as 1 / 0.

| Name | Type | Description |
|---|---|---|
| `value` | `boolean?` | New value. Omit to read. |

Returns: `boolean` or `nil`, as above.

Notes:
- The value is converted to the convar's own type when written, so `:float(1.5)` on an integer convar stores `1`.
- Writes change the local value only. Writing a value the server controls doesn't change it on the server.
- Writes aren't undone when scripts reload. Put the old value back yourself if you need to.
- `tostring(convar.sv_gravity)` is `"convar(sv_gravity)"`.

```lua
local gravity = convar.sv_gravity:float() or 800
print("gravity", gravity)

local fps = convar["fps_max"]
if fps:int() then          -- nil when the convar isn't found
    fps:int(240)
end
```

## chronos

### `chronos.nanotime()`

A high-resolution monotonic clock, in **seconds** (a float with sub-microsecond resolution), despite the name. Only the difference between two calls means anything. Unlike `global_vars.curtime()`, it is real time and keeps running in the main menu.

Returns: `number`.

```lua
local t0 = chronos.nanotime()
-- ... work ...
print(("took %.3f ms"):format((chronos.nanotime() - t0) * 1000))
```

## utils.json_encode / utils.json_decode

The other `utils` functions are documented in [utils](utils.md).

### `utils.json_encode(value)`

Encodes a Lua value as compact JSON text.

Returns: `string`.

How values are converted:

| Lua | JSON |
|---|---|
| `boolean`, `string` | the same |
| `number` | an integer when the value is a whole number (within about ±9e15), else a floating-point number |
| table with keys exactly `1..n` | array |
| any other table, including `{}` | object; keys sorted; integer keys written as strings; other key types (float, boolean, table) skipped |
| `Vector` | `{"x":..,"y":..,"z":..}` |
| `Vec2` | `{"x":..,"y":..}` |
| `Angle` | `{"pitch":..,"yaw":..,"roll":..}` |
| `Color` | `{"r":..,"g":..,"b":..,"a":..}` |
| `nil`, functions, other userdata | `null` |

Notes:
- Tables nested more than 64 levels deep become `null`.
- NaN and infinity are not valid JSON; don't encode them.

### `utils.json_decode(json)`

Decodes JSON text into Lua values.

| JSON | Lua |
|---|---|
| object, array | table (arrays start at index 1) |
| string, `true` / `false` | `string`, `boolean` |
| whole number | integer |
| other number | float |
| `null` | `nil` (the key is missing from its table, or the array has a hole) |

Returns: the decoded value, or `nil` when the text isn't valid JSON.

Objects that came from a `Vector`, `Color`, etc. decode as plain tables; rebuild the value yourself.

```lua
local text = utils.json_encode({ name = "test", pos = Vector(1, 2, 3), list = { 10, 20 } })
-- {"list":[10,20],"name":"test","pos":{"x":1.0,"y":2.0,"z":3.0}}

local t = utils.json_decode(text)
local pos = Vector(t.pos.x, t.pos.y, t.pos.z)
print(t.name, t.list[2], pos)
```

## Standard libraries

Scripts get Lua 5.4's standard library:

- Base functions: `assert`, `collectgarbage`, `error`, `getmetatable`, `ipairs`, `next`, `pairs`, `pcall`, `rawequal`, `rawget`, `rawlen`, `rawset`, `select`, `setmetatable`, `tonumber`, `tostring`, `type`, `xpcall`, `warn`, `_VERSION`.
- Libraries: `string`, `table`, `math`, `utf8`, `coroutine`, `debug`, `package`, `io` and `os` (both complete).
- `print`, `require`, `load`, `loadfile` and `dofile` work on the shared script environment. See [callbacks](callbacks.md#scripts-and-the-shared-environment).

### table and math additions

`table` and `math` have extra helpers (`table.Copy`, `table.Filter`, `math.pow`, `math.atan2`, ...). They are documented in [types](types.md#table-extensions) and [types](types.md#math-extensions).
