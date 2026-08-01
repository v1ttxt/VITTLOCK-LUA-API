# Entity wrappers

VITTLOCK gives you two ways to read entity state:

- **`Engine.*`** binds directly to the entity system and the local pawn — explicit numeric handles, typed return values like `Vector3`/`int`.
- **`entity_list`** (also aliased as `entities`) is a Lua-side fac¸ade built on top of `Engine.*`. It returns a per-entity "wrapped" Lua table with convenience methods (`:get_handle()`, `:valid()`, `:is_alive()`, `:has_modifier_state(state)`...).

There is no pawn type exposed — you can't reach into the pawn's struct directly from Lua. Use these wrappers.

---

## `Engine.GetPlayers()`

Returns an **array of integer handles** — one for every player pawn in the current match. Reads from the entity cache (locked via `cache->GetLock()`).

```lua
local handles = Engine.GetPlayers()
for _, h in ipairs(handles) do
    print(h, Engine.GetEntityName(h), Engine.GetEntityTeam(h))
end
```

⚠️ It currently returns **controllers'** hero pawn handles only (it enumerates `CITADEL_PLAYER_CONTROLLER` entries, reads `m_hHeroPawn`, and emits that pawn's handle). Passive observers, contaminators, and reanimated NPCs aren't included.

---

## `entity_list` API

| Method | Returns | Description |
|---|---|---|
| `entity_list:by_handle(h)` | ent-table | Wrap any player handle |
| `entity_list:local_pawn()` | ent-table | Local player wrapped |
| `entity_list:by_class_name(cls)` | ent-table[] | **Currently returns every player regardless of cls** |
| `entity_list:enemies()` | ent-table[] | Players on opposing team |
| `entity_list:allies()` | ent-table[] | Players on your team (excluding you) |

### ent-table shape

Every returned ent-table is a fresh Lua table — query closure values are captured into per-method closures (not bound to a stable EntityID, just a handle). The shape mirrors the legacy "Faters cheats" surface and the modern VITTLOCK wrapper sets:

```lua
{
    valid = function(self) return h > 0 end,
    is_alive = function(self) return true end,
    m_iTeamNum = Engine.GetEntityTeam(h),
    has_modifier_state = function(self, s) return Engine.EntityHasModifierState(h, s) end,
    get_name = function(self) return Engine.GetEntityName(h) end,
    get_origin = function(self) return Engine.GetEntityOrigin(h) end,
    get_handle = function(self) return h end,
    get_ability = function(self, name) return Engine.GetEntityAbility(h, name) end,
    has_modifier = function(self, name) return Engine.EntityHasModifier(h, name) end,
}
```

### Methods usage

```lua
local lp = entity_list:local_pawn()
if lp:valid() then
    log.info("my team =", lp.m_iTeamNum)
end

for _, e in ipairs(entity_list:enemies()) do
    log.info(e:get_name(), "pos", e:get_origin().x, e:get_origin().y)
end
```

### `entities` is the alias

Both names point to the same table — use whichever reads more natural.

```lua
entities.enemies(entity_list)      -- works, ugly
entity_list:enemies()              -- preferred
```

### Iteration patterns

```lua
-- All enemies with active stun
local stunned = {}
for _, e in ipairs(entity_list:enemies()) do
    if e:has_modifier_state(EModifierState.MODIFIER_STATE_STUNNED) then
        table.insert(stunned, e)
    end
end
log.info("stunned enemies:", #stunned)
```

```lua
-- Sorted by distance to me
local me = entity_list:local_pawn():get_origin()
local function dist(p) return (p:get_origin() - me):Length() end
local list = entity_list:enemies()
table.sort(list, function(a, b) return dist(a) < dist(b) end)
log.info("closest enemy:", list[1]:get_name(), "at", dist(list[1]))
```

---

## Other globals also available

### `dummy_vec`

A pre-built zero vector with Length methods that always return 0 and arithmetic operations that always return itself. Useful for safe-dealing with legacy scripts that return dummy values when there's no pawn:

```lua
local v = dummy_vec - dummy_vec
print(v.x, v.y, v.z, v:Length(), v:LengthSqr())  -- 0, 0, 0, 0, 0
```

### `global_vars.curtime`

A metatable-accessor returning `Engine.GetCurTime`. Use:

```lua
local t = global_vars.curtime()
```

Don't assign to it (`global_vars.curtime = 5`) — that just overwrites the table inside the global table; nothing else uses it.

### `trace.hull` / `trace.line`

⚠️ **Stub return values** — `{hit=false, fraction=1.0, entity=nil}`. Real traces go through `Engine.TraceLine` (see [trace.md](trace.md)).

---

## Lifecycle & reload guarantees

The wrapped handle is a **numeric snapshot** — it can become stale after some game frames if the entity is destroyed. Always call `:valid()` before doing anything with a wrapped entity ifcached across frames:

```lua
callbacks.on_frame(function()
    if not target or not target:valid() then return end
    -- target may have been destroyed during a frame iteration
end)
```

⚠️ `:valid()` returns `h > 0` — it does **not** check that the entity is still alive or still has the same identity. A `2` followed by entity-replacement would silently pass. For best-practice, also call `Engine.IsPlayer(h)` and compare `Engine.GetEntityName(h)` to a cached name.

⚠️ `:is_alive()` always returns `true` — the binding doesn't read health or state, it's a placeholder. Use `Engine.HasModifierState(EModifierState.MODIFIER_STATE_OUT_OF_GAME)` or check abilities.

---

## Examples

### Auto-target the closest alive enemy (polling each frame)

```lua
local m = ui.script()
m:category("Combat")
local enabled = m:switch("Auto-target", false)

callbacks.on_frame(function()
    if not enabled:get_bool() then return end
    local lp = entity_list:local_pawn()
    if not lp:valid() then return end
    local my = lp:get_origin()
    local closest, dist = nil, math.huge
    for _, e in ipairs(entity_list:enemies()) do
        local d = (e:get_origin() - my):Length()
        if d < dist then closest, dist = e, d end
    end
    if closest then
        storage.set("target_handle", closest:get_handle())
        storage.set("target_dist", dist)
    end
end)
```

### Cross-script widget access

```lua
local function get_external_setting()
    return Menu.Find("OtherScript", "Mode"):get_int()
end
```

---

## Pitfalls

### `by_class_name` returns all players

The current implementation ignores `cls` — it back-route through `Engine.GetPlayers()` regardless. If you need class-filtered enumeration, do it through `on_entity_create`:

```lua
local function class_matches(h, cls)
    return Engine.GetEntityName(h):find(cls) ~= nil
end

callbacks.on_entity_create(function(h)
    if class_matches(h, "ParticleKillBoss") then
        storage.set("boss_alive", h)
    end
end)
```

### `entity_list:local_pawn()` with no pawn

When you're dead and respawning, `Engine.GetLocalPlayerHandle()` returns `-1`. The wrapper still constructs a valid table:

```lua
{
    valid = function() return -1 > 0 end,  -- returns false
    m_iTeamNum = -1,
}
```

So `lp:valid()` returns `false` — but `lp.m_iTeamNum` reads as `-1`. Don't iterate without first checking `lp:valid()`.

### Per-frame allocations

Each `entity_list:enemies()` call **allocates a fresh array + a fresh wrapper per entity**. Tight-looped caching of wrappers within a single frame is fine — wrapper methods close over the stable handle, not the table identity. But avoid storing wrappers in `storage` — they're Lua tables that survive until GC, and they close over `Engine.*` calls, all of which work post-reload.

### `get_abilities()` on the wrapper

The VITTLOCK wrapper surface does not expose `get_abilities` — there's no list of abilities per pawn accessible from `entity_list`. To fetch a single ability by designer name, use `Engine.GetEntityAbility`:

```lua
local ab = Engine.GetEntityAbility(handle, "citadel_ability_...")
if ab then log.info("found ability") end
```

---

## See also

- [engine-accessors.md](engine-accessors.md) — `Engine.*` raw bindings
- [callbacks-events.md](callbacks-events.md) — `on_entity_create/destroy`, `on_bullet_create`, `on_add_modifier` payloads all carry handles