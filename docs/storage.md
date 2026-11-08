# Storage

Two global tables hold data outside your script's locals:

- [`db`](#db): a persistent database, saved to disk. It survives script reloads and game restarts. Use it for anything you want to remember next session (counters, positions, your own settings).
- [`global_ctx`](#global_ctx): plain values shared by every script for the current session only. Use it to pass flags or numbers between scripts.

Menu widget values are saved on their own; you don't need either table for them. See [menu](menu.md).

## db

`db` is the root of the database, a [`db_table`](#db_table). There is one database for all scripts, so put your data under a key of its own to avoid clashing with other scripts.

```lua
-- Counts how many times this script has loaded, across sessions.
local store = db.my_script
if not store then
    db.my_script = { runs = 0 }
    store = db.my_script            -- read it back: this is the live node
end
store.runs = (store.runs or 0) + 1
print("loaded " .. math.tointeger(store.runs) .. " times")
```

### When it is saved

The database is loaded from `C:\VITTLOCK\scripts\v2\db.json` once, when VITTLOCK starts. Changes are kept in memory and written to that file:

- every 5 minutes, if anything changed,
- before every full script reload (Reload All, the Reload Bind),
- when the config is saved,
- when VITTLOCK unloads.

If the game crashes, changes since the last save are lost. Script reloads don't touch the database's contents.

If `db.json` can't be read (for example after a bad hand edit), the database starts empty and the file is overwritten at the next save.

## db_table

A node of the database. `db` is one; every nested table you read from it is another. Use it like a Lua table.

### Reading: `node.key` / `node[key]`

Returns the stored value, or `nil` when the key isn't there. A nested table comes back as a `db_table` that is a live view: writing to it writes to the database.

```lua
db.settings = { volume = 5 }
db.settings.volume = 7          -- changes the stored value
print(db.settings.volume)       -- 7.0
```

### Writing: `node.key = value`

Stores `value` under `key`. Assigning `nil` removes the key.

| Value type | Stored as |
|---|---|
| `boolean`, `string` | the same |
| `number` | a single-precision float (about 7 significant digits) |
| `Vector`, `Vec2`, `Color` | the same type |
| `table` | a copy, as a nested node; entries with unsupported keys or values are left out |
| `db_table` | a copy of that node |
| anything else (`Angle`, functions, entities, ...) | not stored; the assignment is ignored and the old value stays |

Notes:
- **Numbers lose precision.** They are stored as single-precision floats and always read back as floats: `db.n = 5` reads back as `5.0`. Whole numbers are exact up to 16,777,216. Store large values, such as `os.time()` timestamps or ids, as strings. Use `math.tointeger(x)` or `x // 1` to get an integer back.
- **Writing a table copies it.** Changing the Lua table afterwards doesn't change the database. Read the key back to get the live node.
- Tables nested more than 32 levels deep are not stored.

### Keys

Keys are strings or numbers. Other key types read as `nil` and are ignored on write.

- A string made only of digits (with an optional leading `-`) is the same key as that integer: `db["12"]` and `db[12]` are the same entry.
- A number with a fractional part becomes a string key: `db[1.5]` is `db["1.5"]`.
- `to_table` is the method below, so it can't be used as a key name.

### `#node`

The number of entries in the node, counting every key (not just `1..n`).

### `tostring(node)`

The node as compact JSON text.

### `node:to_table()`

A deep copy of the node as plain Lua tables; nested nodes become tables. A `db_table` can't be walked with `pairs`; iterate over this copy instead.

Returns: `table`.

```lua
for name, pos in pairs((db.waypoints and db.waypoints:to_table()) or {}) do
    print(name, pos)
end
```

### Other notes

- Each read of a nested key returns a new `db_table` object, so don't compare nodes with `==`. Compare the values inside them.
- `Vector`, `Vec2` and `Color` values keep their type across restarts.

```lua
-- Remember the last position you were at, across sessions.
callback.on_frame:set(function()
    local me = entity_list.local_pawn()
    if me then db.last_pos = me:get_origin() end
end)

local last = db.last_pos            -- a Vector, or nil the first time
if last then print("last position", last) end
```

## global_ctx

`global_ctx` is a string-keyed table shared by every script. It lives in memory only:

- it is cleared on every full reload (Reload All, the Reload Bind, game start),
- it stays when a single script is reloaded,
- it is never saved to disk.

### `global_ctx.key` / `global_ctx.key = value`

| Value type | Behaviour |
|---|---|
| `string`, `boolean` | stored as is |
| `number` | stored as a single-precision float, read back as a float |
| `nil` | removes the key |
| anything else (tables, `Vector`, functions, ...) | ignored; the old value stays |

Notes:
- Keys must be strings. Other keys read as `nil` and are ignored on write.
- `global_ctx` can't be iterated and has no length. Keep a list of your keys yourself if you need one.
- For tables or game objects shared between scripts, use a global (all scripts share one environment, see [callbacks](callbacks.md#load-order)); `global_ctx` is for plain values.

```lua
-- script a.lua
global_ctx.combo_active = true

-- script b.lua
callback.on_frame:set(function()
    if global_ctx.combo_active then
        -- ...
    end
end)
```
