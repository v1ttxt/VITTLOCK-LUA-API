# Trace

The `trace` table casts rays and swept boxes through the game world, and checks whether a bullet would reach a target. Use it for line-of-sight checks, ground and wall probes, and shot validation. `trace.line` and `trace.hull` return a [`trace_t`](#trace_t) result; the bullet helpers return a boolean or a hitbox name.

## Where traces work

Traces only run on the game thread: in `on_frame`, `on_pre_createmove`, `on_createmove` and `on_post_createmove`. `on_draw` runs elsewhere, and there a trace does nothing and returns an empty result (`fraction` 1, nothing hit; the filter is not called). Do your traces in `on_frame` and draw the stored results in `on_draw`.

Off the game thread the bullet helpers see that empty result as a clear path: `trace.bullet` returns `true` there. Don't rely on them from `on_draw`.

## Masks and filters

`trace.line` and `trace.hull` take the collision settings as plain integers:

| Argument | Meaning |
|---|---|
| `with` | 64-bit mask of the interaction layers the trace collides with. |
| `exclude` | 64-bit mask of layers to ignore even if they are in `with`. |
| `as` | 64-bit mask of the layers the trace itself counts as. Usually 0. |
| `object_set_mask` | Accepted for compatibility and not used: every object set is traced. |
| `collision_group` | Collision group number (0-255). |

`0x1C1003` is the mask VITTLOCK's own line-of-sight checks use; it is a good default for "can I see this point". The examples on this page use `with = 0x1C1003, exclude = 0, as = 0, object_set_mask = 7, collision_group = 4`.

The `filter` argument is a function that is called with each entity the trace meets ([entity](entities.md#entity), or a more specific type like [player_pawn](entities.md#player_pawn)). Return a truthy value to let that entity block the trace, or `false` / `nil` to let the trace pass through it.

- Always pass a function. With `nil` or a non-function, the call raises `attempt to call a nil value` (or the matching type) as soon as the trace meets an entity.
- If the filter raises an error, the trace call raises that error.
- Keep the filter cheap: it can be called many times per trace.

## trace.line

### `trace.line(start, end_, with, exclude, as, object_set_mask, collision_group, filter [, portal])`
Traces a line from `start` to `end_` and returns a `trace_t`. Your own pawn is always skipped.

| Name | Type | Description |
|---|---|---|
| `start` | Vector | Start point. |
| `end_` | Vector | End point. |
| `with`, `exclude`, `as` | integer | Layer masks, see above. |
| `object_set_mask` | integer | Not used. |
| `collision_group` | integer | Collision group. |
| `filter` | function(ent) | Entity filter, see above. |
| `portal` | boolean | Optional, default `true`. `true` follows the trace through portals. `false` traces a plain line. |

Notes:
- A `start` or `end_` that isn't a Vector is treated as (0, 0, 0). Missing integer arguments count as 0.

```lua
local MASK = 0x1C1003

-- Is the enemy's head visible from the camera?
local function head_visible(enemy, lp)
    local head = enemy:get_bone_pos("head")
    if not head then return false end
    local cam = utils.get_camera_pos()
    local tr = trace.line(cam, head, MASK, 0, 0, 7, 4, function(ent)
        -- Enemy heroes block (so we can see whether we hit this one), teammates don't.
        return ent.m_iTeamNum ~= lp.m_iTeamNum
    end)
    return tr:is_visible_entity(enemy, cam:Distance(head))
end

local visible = {}
callback.on_frame:set(function()
    visible = {}
    local lp = entity_list.local_pawn()
    if not lp then return end
    for _, e in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        if e:is_alive() and not e:is_dormant() and head_visible(e, lp) then
            visible[#visible + 1] = e:get_name()
        end
    end
end)
```

## trace.hull

### `trace.hull(start, end_, mins, maxs, with, exclude, as, object_set_mask, collision_group, filter [, ignore_local [, portal]])`
Sweeps an axis-aligned box from `start` to `end_` and returns a `trace_t`.

| Name | Type | Description |
|---|---|---|
| `start` | Vector | Start point. |
| `end_` | Vector | End point. |
| `mins` | Vector | Box minimum, relative to the path (e.g. `Vector(-16, -16, 0)`). |
| `maxs` | Vector | Box maximum, relative to the path (e.g. `Vector(16, 16, 72)`). |
| `with`, `exclude`, `as` | integer | Layer masks, see above. |
| `object_set_mask` | integer | Not used. |
| `collision_group` | integer | Collision group. |
| `filter` | function(ent) | Entity filter, see above. |
| `ignore_local` | boolean | Optional. Only `true` skips your own pawn. By default the hull can hit your pawn unless the filter lets it pass. |
| `portal` | boolean | Optional, default `true`. `false` sweeps without following portals. |

Notes:
- Unlike `trace.line`, the hull does not skip your pawn unless `ignore_local` is `true`. A hull starting inside your own pawn otherwise stops at once.
- A box with `mins` equal to `maxs` behaves like a line.

```lua
-- Is there floor within 200 units below a point? (a 32x32 box)
local function floor_below(pos)
    local tr = trace.hull(pos, pos - Vector(0, 0, 200), Vector(-16, -16, 0), Vector(16, 16, 8),
        0x1C1003, 0, 0, 7, 4, function() return false end, true)
    if tr.fraction < 1 then
        return tr.end_pos
    end
    return nil
end
```

## Bullet traces

These trace a bullet-sized sphere from `start` toward `end_` with the game's bullet rules and return whether the shot gets there:

- Your own pawn and your teammates never block.
- The target `ent` always counts as a hit.
- Pass-through walls, time-warp zones and ice path shards never block. Fissure walls, grave stone blockers and ice dome blockers always block.
- Other entities block, unless your primary weapon penetrates targets, in which case they never block.
- The trace follows portals.

An `ent` that is not a valid entity makes them return `false` (or `""`). `radius` must be a number; 0 or less traces a line.

### `trace.bullet(start, end_, radius, ent)`
Returns `true` if the shot reaches the end point, or hits `ent` first.

| Name | Type | Description |
|---|---|---|
| `start` | Vector | Shot origin. |
| `end_` | Vector | Aim point on the target. |
| `radius` | number | Bullet radius. |
| `ent` | entity | The target. |

"Reaches the end point" means the trace stopped less than 5 units short of `end_`. So `true` with an `end_` inside the target means nothing blocks the shot before it gets there.

### `trace.bullet_hitbox(start, end_, radius, ent, hitbox_name)`
Returns `true` if the shot passes and the hitbox it hits contains `hitbox_name` (case-sensitive substring). `""` accepts any result that passes.

| Name | Type | Description |
|---|---|---|
| `start` | Vector | Shot origin. |
| `end_` | Vector | Aim point. |
| `radius` | number | Bullet radius. |
| `ent` | entity | The target. |
| `hitbox_name` | string | Part of the hitbox name to look for, e.g. `"head"`. |

The shot passes when it hits `ent`, or when it gets at least 97 % of the way to `end_` (even with no hit).

### `trace.bullet_hitbox_name(start, end_, radius, ent)`
Returns the name of the hitbox the shot hits, or `""` when it doesn't pass (same pass rule as `bullet_hitbox`) or hits no hitbox.

```lua
-- In on_createmove: is the head shot clear for a 5-unit bullet?
callback.on_createmove:set(function(cmd)
    local lp = entity_list.local_pawn()
    local target = utils.find_nearest_visible_enemy()
    local head = target and target:get_bone_pos("head")
    local from = lp and lp:get_fireport_position(false)
    if not head or not from then return end
    if trace.bullet_hitbox(from, head, 5, target, "head") then
        print("clear head shot on " .. target:get_name() .. " (" .. trace.bullet_hitbox_name(from, head, 5, target) .. ")")
    end
end)
```

## trace_t

The result of `trace.line` and `trace.hull`. It is a copy of the result, so you can keep it after the callback.

### Fields

| Field | Type | Description |
|---|---|---|
| `fraction` | number | How far along the path the trace got, 0 to 1. 1 means nothing was hit. Writable. |
| `start_pos` | Vector | Where the trace started. |
| `end_pos` | Vector | Where the trace stopped (`start + (end - start) * fraction` for an unportalled trace). |
| `hit_pos` | Vector | The exact contact point when the game reports one, else `end_pos`. |
| `normal` | Vector | The surface normal at the hit. |
| `portalled` | boolean | The trace went through a portal. |
| `portal_fraction` | number | The fraction of the path at the portal entry. 1 when not portalled. |
| `portal_entry` | Vector | Where the trace entered the portal. (0, 0, 0) when not portalled. |
| `portal_exit` | Vector | Where the trace came out. (0, 0, 0) when not portalled. |

When `portalled` is `true`, `start_pos`, `end_pos`, `normal` and the hit entity describe the part of the trace after the portal exit, and `fraction` covers the whole path.

`tostring(tr)` gives `trace_t(fraction 0.xxx)`.

### `tr:hit_entity()`
Returns the entity that was hit, or `nil` when the trace hit only the world or nothing.

### `tr:hitbox_name()`
Returns the name of the hitbox that was hit, or `""`.

### `tr:is_visible_entity(ent, full_dist)`
Returns `true` if the trace got within 5 units of its full length, or if it hit `ent` (and `fraction` is above 0). Returns `false` if `ent` is not a valid entity.

| Name | Type | Description |
|---|---|---|
| `ent` | entity | The entity you traced toward. |
| `full_dist` | number | The full length of the traced path, e.g. `start:Distance(end_)`. |

### `tr:is_vertical_normal()`
Returns `true` when the normal's x and z are exactly 0 and its y is below -0.99. Note that it tests the y axis: it is not a floor/ceiling test. For a floor, check `tr.normal.z > 0.7` yourself.
