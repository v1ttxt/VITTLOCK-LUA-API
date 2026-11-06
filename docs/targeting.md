# Targeting

Tools for picking who to shoot and where: `TargetSelection` ranks entities with your own scoring functions, `backtrack` gives you the recent positions of enemy heroes, and `hitscan.evaluate` finds the best reachable point on a target. Run them from `on_createmove` (or `on_frame`), where your pawn, weapon and traces are up to date.

- [TargetSelection](#targetselection)
- [backtrack](#backtrack)
- [BacktrackRecord](#backtrackrecord)
- [hitscan](#hitscan)

## TargetSelection

A reusable selector. You give it a filter and weighted criteria, call `update` each tick with the candidates, and read the best target or a list of targets. It stores entities by handle, so it is safe to create once at the top of your script and keep across frames. Entities that disappear are dropped automatically.

### How an update works

1. Each candidate that still exists is passed to the filter (if one is set). It is kept when the filter returns anything other than `nil` or `false`.
2. Its score is the sum of `weight * criterion(ent)` over all criteria. There is no normalisation: scale your criteria yourself.
3. Candidates whose score is below the threshold (default 0) or not finite (NaN, infinity) are dropped. The rest are sorted by score, highest first.
4. `get_best_target()` becomes the top scorer.
5. The target list is built in this order:
   - the best target, if `set_always_include_best(true)` and it leads the second one by at least the score gap (or there is no gap or only one candidate);
   - the last shootable target, if one is set and it is still among the scored candidates;
   - up to `max_targets` more. Entities picked by earlier updates are skipped while unpicked candidates remain, so repeated updates cycle through the candidates; once every candidate has been picked, the remaining slots are filled in rotating order.

With the defaults (max targets 0, always-include-best off) `get_targets()` is empty unless a last shootable target is set. `get_best_target()` always works.

If nothing scores, the last shootable target and the rotation history are cleared.

Errors inside the filter or a criterion are written to the script's log as `lua(target_selection:filter): ...` or `lua(target_selection:criterion): ...`. A failing filter counts as `false`, a failing criterion (or one that returns a non-number) counts as `0`. The update itself keeps going.

### `TargetSelection()`

Creates a new selector with no filter, no criteria, threshold 0, max targets 0, always-include-best off and score gap 0.

`tostring(sel)` returns `"TargetSelection"`.

### `sel:set_filter(fn)`

Sets the filter, replacing any previous one. `fn(ent)` is called for every candidate during `update`; return a truthy value to keep it.

### `sel:add_criterion(fn, weight)`

Adds a scoring function. Criteria accumulate; there is no way to remove one except `reset()`.

| Name | Type | Description |
|---|---|---|
| fn | `fun(ent: entity): number` | Returns this criterion's value for a candidate. |
| weight | number | Multiplier applied to the value. Use a negative weight to prefer lower values. |

### `sel:set_score_threshold(threshold)`

Candidates scoring below `threshold` are dropped. The default is 0, which drops every negative score: lower it if your criteria can go negative.

### `sel:set_max_targets(count)`

How many targets an update picks in addition to the best target and the last shootable target. Default 0. The value is truncated to an integer and negative values count as 0.

### `sel:set_always_include_best(enabled)`

When `true`, the best target is always the first entry of `get_targets()`, subject to the score gap below. Default `false`.

### `sel:set_best_target_score_gap(gap)`

With always-include-best on, the best target is only force-included when its score is at least `gap` above the second-best score. 0 or less (the default) disables the check.

### `sel:set_last_shootable_target(ent)`

Tells the selector which entity you can currently shoot. As long as it passes the filter and the threshold, every update puts it in the target list right after the best target. Passing `nil` or a non-entity clears it. It is also cleared when it stops scoring.

### `sel:update(entities)`

Scores the values of `entities` (keys are ignored; values that are not entities are skipped) and rebuilds the selection.

### `sel:update_by_class(class_name)`

Same as `update`, with every entity of exactly that class name as candidates. This includes all teams, your own pawn, and dormant and dead entities, so filter them out yourself.

| Name | Type | Description |
|---|---|---|
| class_name | string | Exact class name, e.g. `"C_CitadelPlayerPawn"`. |

### `sel:get_best_target()`

Returns the highest-scoring entity from the last update, or `nil` when nothing scored or that entity no longer exists.

### `sel:get_targets()`

Returns a new array of `{ entity = <entity>, score = <number> }` in pick order (see [How an update works](#how-an-update-works)). Entities that no longer exist are left out.

### `sel:reset()`

Removes all criteria and the filter and clears the best target, the target list, the last shootable target and the rotation history. The threshold, max targets, always-include-best and score-gap settings are kept.

### Example: closest enemy hero, low health preferred

```lua
local sel = TargetSelection()

sel:set_filter(function(e)
    local me = entity_list.local_pawn()
    return me ~= nil and e ~= me and e:is_alive() and not e:is_dormant()
        and e.m_iTeamNum ~= me.m_iTeamNum
end)

-- 1 at point blank, 0 at 3000 units or more.
sel:add_criterion(function(e)
    local me = entity_list.local_pawn()
    local d = me:get_origin():Distance(e:get_origin())
    return math.max(0, 1 - d / 3000)
end, 1.0)

-- 0 at full health, 1 when nearly dead.
sel:add_criterion(function(e)
    local max = e:get_max_health()
    if max <= 0 then return 0 end
    return 1 - e.m_iHealth / max
end, 0.5)

sel:set_always_include_best(true)
sel:set_max_targets(1)   -- best target + one more

local current = nil

callback.on_createmove:set(function(cmd)
    if not entity_list.local_pawn() then return end
    sel:update_by_class("C_CitadelPlayerPawn")
    local best = sel:get_best_target()
    if best ~= current then
        current = best
        print("target: " .. (best and best:get_name() or "none"))
    end
end)
```

## backtrack

### `backtrack.records(ent)`

Returns the recorded positions of an enemy hero as an array of [BacktrackRecord](#backtrackrecord), newest first, up to 32. A new record is taken each time the hero's simulation time changes. Only living enemy heroes are recorded, so teammates, other entities and invalid values give an empty table.

Recording runs all the time, whether or not any backtrack feature is turned on in the menu. Old records are not removed as soon as they become unusable: always check `rec:is_valid()` before using one.

```lua
callback.on_createmove:set(function(cmd)
    local me = entity_list.local_pawn()
    if not me then return end
    for _, enemy in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        local usable = 0
        for _, rec in ipairs(backtrack.records(enemy)) do
            if rec:is_valid() then usable = usable + 1 end
        end
        -- usable = how many recorded positions the server can still rewind to
    end
end)
```

## BacktrackRecord

One recorded position, returned by `backtrack.records` and in `hitscan.evaluate` results. Scripts cannot create records. A record is a copy: it stays usable after the call and can be kept.

`tostring(rec)` returns `"BacktrackRecord(simtime <seconds>)"`.

| Field | Type | Description |
|---|---|---|
| `simtime` | number | The hero's simulation time when the record was taken (seconds). |
| `tick` | integer | Tick number of `simtime`: `floor(simtime / tick_interval + 0.5) + 1`. |
| `abs_origin` | Vector | The hero's origin at that time. |
| `velocity` | Vector | The hero's velocity at the moment `backtrack.records` was called. It is the same on every record of one call, not a per-record value. |

All fields are read-only.

### `rec:is_valid()`

Returns `true` when the record is still inside the server's lag-compensation window (`sv_maxunlag`, or `sv_maxunlag_player` when that is lower), measured from your current simulation time plus your latency. Returns `false` when you have no pawn or the window can't be read.

### `rec:hitbox_pos(index)`

Returns the recorded head position as a Vector. The index argument is required, but every index currently returns the head.

## hitscan

### Constants

Hitgroup bits, for `mask` and the result's `hitgroup`:

| Name | Value | Hitboxes |
|---|---|---|
| `hitscan.HEAD` | 1 | Head |
| `hitscan.CHEST` | 2 | Chest and neck |
| `hitscan.STOMACH` | 4 | Stomach |
| `hitscan.ARMS` | 8 | Arms |
| `hitscan.LEGS` | 0x10 | Legs |
| `hitscan.OTHER` | 0x20 | Everything else |

Multipoint levels, for `multipoint`:

| Name | Value | Points per hitbox |
|---|---|---|
| `hitscan.MULTIPOINT_DISABLED` | 0 | Centre only |
| `hitscan.MINIMUM` | 1 | Centre + 1 sample |
| `hitscan.MEDIUM` | 2 | Centre + 2 samples |
| `hitscan.HIGH` | 3 | Centre + 3 samples |

### `hitscan.evaluate(params)`

Checks points on the target's hitboxes and returns the best one you can hit. Points are traced from your camera position with bullet collision; a point counts when the trace reaches the target (or stops within a few units of the point). The current pose is always tried; each record in `params.records` adds the same hitboxes moved to that record's position.

Returns `result, nil` on success or `nil, err` on failure.

Parameters (fields of `params`):

| Name | Type | Default | Description |
|---|---|---|---|
| `target` | entity | required | The entity to evaluate. |
| `mask` | integer | `0x1F` | Hitgroup bits to consider. The default is everything except `OTHER`. `0` always fails with `no_candidate`. |
| `records` | BacktrackRecord[] | none | Extra poses to try. Values that are not records are skipped. Records are not checked with `is_valid()`: filter them yourself. |
| `multipoint` | integer | `0` | Extra samples per hitbox (0-3, clamped). Samples are spaced evenly along the hitbox between its two ends; each also gets a second point offset by a fraction of the hitbox radius. |
| `point_scale` | number | `100` | Scales that offset. At 100 it is about 82% of the hitbox radius. |
| `min_damage` | number | `1` | Points with a lower estimated damage are rejected. |
| `min_hitchance` | number | `0` | Minimum hit chance in percent (0-100). |
| `trace_count` | integer | `0` | The hit-chance check only runs when this is non-zero and `min_hitchance > 0`. Otherwise every point has hit chance 1. |

Result fields:

| Field | Type | Description |
|---|---|---|
| `record` | BacktrackRecord or nil | The record the point was found on, or `nil` for the current pose. |
| `tick` | integer | `record.tick`, or `0` for the current pose. |
| `aim_point` | Vector | World position to aim at. |
| `hitbox_index` | integer | Index of the hitbox in the target's hitbox set. |
| `hitgroup` | integer | One of the hitgroup bits above. |
| `fov` | number | Angle in degrees between your camera's view direction and `aim_point`. |
| `damage` | number | Estimated damage of one bullet at that point. |
| `hitchance` | number | Estimated hit chance from 0 to 1. |

Error codes, checked in this order:

| Code | Meaning |
|---|---|
| `invalid_target` | `target` is missing or not a valid entity. |
| `no_local_player` | You have no pawn. |
| `no_weapon` | You have no primary weapon. |
| `below_hitchance` | Some points were reachable, but every one failed `min_hitchance`. |
| `below_damage` | Some points were reachable, but every one failed `min_damage`. |
| `no_candidate` | Nothing usable: no reachable point, `mask` was 0, or the target has no hitboxes. |

Notes:

- **Damage is an estimate**: the weapon's base bullet damage with its distance falloff, doubled for head points. It does not include item bonuses or the target's resistances. Use it for comparisons and thresholds, not exact kill checks.
- **Hit chance** compares your weapon's current spread with how large the hitbox looks from the camera. It is 1 when spread is negligible.
- Among the accepted points, the one with the highest `damage * (0.5 + 0.5 * hitchance)` wins.
- Cost grows with hitboxes x points x poses. `HIGH` multipoint with many records means many traces per call: evaluate one target per tick, not every enemy.

### Example: best head or chest point, including backtrack

```lua
local last_err = nil

callback.on_createmove:set(function(cmd)
    local me = entity_list.local_pawn()
    if not me or not me:is_alive() then return end

    local target = nil
    local best_d = math.huge
    for _, e in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        if e:is_alive() and not e:is_dormant() then
            local d = me:get_origin():Distance(e:get_origin())
            if d < best_d then target, best_d = e, d end
        end
    end
    if not target then return end

    local recs = {}
    for _, rec in ipairs(backtrack.records(target)) do
        if rec:is_valid() then recs[#recs + 1] = rec end
    end

    local res, err = hitscan.evaluate({
        target = target,
        mask = hitscan.HEAD | hitscan.CHEST,
        multipoint = hitscan.MEDIUM,
        min_damage = 15,
        records = recs,
    })

    if res then
        last_err = nil
        -- res.aim_point is where to aim; res.tick is the record's tick (0 = current pose)
    elseif err ~= last_err then
        last_err = err
        print("hitscan: " .. err)
    end
end)
```
