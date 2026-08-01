# `storage`

A per-script in-memory key-value store. Cheap and accessible from any callback — but **not persisted across DLL restart**. For persistent state use a `switch/slider_*` widget, which auto-saves into the cheat's settings JSON.

---

## API

| Function | Returns | Description |
|---|---|---|
| `storage.set(key, value)` | nil | Store any Lua value under the key for the current script |
| `storage.get(key)` | value or nil | Read back what you stored; `nil` if unset |
| `storage.clear()` | nil | Wipe all keys for the current script |

The "current script" identifier is taken from `__SCRIPT_NAME__`, so each script has its own bucket. Cross-script reads aren't supported by these helpers — use `Menu.Find` or store through explicit globals if you must.

---

## Implementation note

Internally:

```lua
-- inside the engine bootstrap injected by `L.script("__STORAGE__ = __STORAGE__ or {}")`
__STORAGE__[currentScript] = bucket   -- a Lua table
```

`storage.set/get/clear` index into `__STORAGE__[currentScript]` with a string key. The value can be any Lua value (table, function, userdata, thread). Reference cycle collectors run on LuaJIT's normal GC — if you store a reference to something that references the storage back, expect to keep it alive.

---

## Examples

### Cumulative counter

```lua
m:button("Reset hits", function() storage.set("hits", 0) end)

callbacks.on_bullet_create(function(b)
    if b.shooter_handle == Engine.GetLocalPlayerHandle() then
        storage.set("hits", (storage.get("hits") or 0) + 1)
    end
end)

callbacks.on_render(function()
    render.text(30, 30, 1, 1, 1, 1, "hits: " .. (storage.get("hits") or 0))
end)
```

### Per-enemy memory

```lua
local seen = {}  -- store a sub-table per script run
local function enemyKey(h)
    return string.format("ent_%d", h)
end

callbacks.on_entity_create(function(h)
    if Engine.IsPlayer(h) then
        seen[h] = true
        storage.set(enemyKey(h), { first_seen = Engine.GetCurTime(), hits = 0 })
    end
end)

callbacks.on_bullet_create(function(b)
    local s = storage.get(enemyKey(b.shooter_handle))
    if s then
        s.hits = (s.hits or 0) + 1
        storage.set(enemyKey(b.shooter_handle), s)
    end
end)
```

### Read-from-mid-tick

```lua
callbacks.on_pre_createmove(function(cmd)
    local pending = storage.get("parry_pending")
    if pending and ImGui.GetTime() >= pending then
        cmd:AddButtonState(InputBitMask_t.IN_ABILITY_HELD)
        storage.set("parry_pending", nil)
    end
end)
```

### Multivariate

```lua
storage.set("config", {
    mode = "fast",
    threshold = 0.5,
    toggle_keys = { 0x2D, 0x56 },
})

local config = storage.get("config")
if config and config.mode == "fast" then
    -- ...
end
```

---

## Pitfalls

### Lua-table mutation does not auto-persist

```lua
local t = storage.get("foo") or {}
t.x = (t.x or 0) + 1
-- storage.set("foo", t) IS REQUIRED here — without it, the in-engine bucket still holds the old t
```

If you've cached the table reference and only mutated fields, the write doesn't propagate up automatically unless you reassign. Always `storage.set` after mutation.

### Not persisted across DLL restart

The bucket is a Lua table — the whole shared Lua state is dropped on DLL unload. Schema migration between builds won't survive.

### Cross-script reads aren't exposed

`storage.get("hits")` pulls from the **current** script's bucket. There's no `storage.get_from("OtherScript", key)` helper. If scripts need to share data, use:

- A shared Lua global (cross-script, lives in the same shared state). Collision names are a risk.
- A widget's value (`Menu.Find("OtherScript", "Hits")` then `:get_int()`). This is also persistent across restart and visible to the user.
- Document an IPC convention (e.g., a "_registry" script that's the only writer).

### Key types

Keys must be strings — the engine stringifies your key on the way in. Numbers work for cache-slot access — `storage.set(123, ...)` indexes `bucket[123]` — but prefer string keys for clarity.

---

## See also

- [widgets-menu.md](widgets-menu.md) — widgets are persistent cross-restart storage
- [timers.md](timers.md) — combining timers + storage