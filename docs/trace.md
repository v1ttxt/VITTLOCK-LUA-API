# `Engine.TraceLine` — Ray-cast

VITTLOCK exposes a ray-cast tracer through `Engine.TraceLine`. This is the only "geometry-query" binding — there is no trace hull/sphere.

The trace uses mask `0x1C3003` which is the standard "solid to bullets + world" collidable mask. The skip entity is resolved by handle lookup — passing `-1` skips nothing.

---

## Signature

```lua
local result = Engine.TraceLine(start, end, skipHandle)
```

- `start` (Vector3): ray origin
- `end` (Vector3): ray destination
- `skipHandle` (int): entity handle to skip; pass `-1` to skip nothing

Returns a table:

| Field | Type | Description |
|---|---|---|
| `hit` | bool | `true` if blocked before `end` |
| `fraction` | number | `0..1` — distance along ray where hit happened (`1.0` = no hit) |
| `hit_entity` | int | Handle of the entity that was hit, `-1` if none |

Implementation detail: the trace uses mask `0x1C3003` which is the standard "solid to bullets + world" collidable mask. The skip entity is resolved by handle lookup — passing `-1` skips nothing.

---

## Usage

### Line-of-sight check

```lua
local us = Engine.GetLocalPlayerHandle()
local target = nearestEnemy()

local myEye = Engine.GetBonePosition(us, "Head")
local theirHead = Engine.GetBonePosition(target, "Head")

local tr = Engine.TraceLine(myEye, theirHead, us)
if not tr.hit then
    log.info("clear LOS to", Engine.GetEntityName(target))
elseif tr.hit_entity == target then
    log.info("target's head blocks our own head's eye — cover broken at their position")
else
    log.info("blocked by", Engine.GetEntityName(tr.hit_entity))
end
```

### Ground distance

```lua
local pawn = Engine.GetLocalPlayerHandle()
local origin = Engine.GetEntityOrigin(pawn)
local down = Vector3.new(origin.x, origin.y, origin.z - 4096)
local tr = Engine.TraceLine(origin, down, pawn)
log.info("ground in", tr.fraction * 4096, "units")
```

### Visibility throttled per-frame

```lua
callbacks.on_pre_createmove(function(cmd)
    if not enabled:get_bool() then return end
    -- only TrueAim if clear LOS — heavy cost, throttle every 3rd frame
    if (frameCount % 3) ~= 0 then return end
    local target = pickEnemy()
    local eye = Engine.GetBonePosition(myHandle, "Head")
    local pos = Engine.GetBonePosition(target, "Head")
    if not eye or not pos then return end
    local tr = Engine.TraceLine(eye, pos, myHandle)
    if not tr.hit then cmd:SetViewAngles(calcAngle(eye, pos)) end
end)
```

⚠️ `TraceLine` is **synchronous** and not free — tracing ~500 units across a populated scene per tick will grotesiously impact frame times. Throttle.

---

## The legacy `trace` table

The legacy `trace.hull(...)` and `trace.line(...)` functions are **stubs**:

```lua
trace = {
    hull = function() return { entity = nil, hit = false, fraction = 1.0 } end,
    line = function() return { entity = nil, hit = false, fraction = 1.0 } end,
}
```

Both return `fraction=1.0, hit=false`. Use `Engine.TraceLine` for the real deal. Old scripts that use `trace.line()` will simply see "no hit" — silent failure.

---

## See also

- [engine-accessors.md](engine-accessors.md) — `Engine.*`
- [math-vector3-qangle.md](math-vector3-qangle.md) — `Vector3` for `start` / `end`