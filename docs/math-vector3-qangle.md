# `Vector3` & `QAngle`

VITTLOCK exposes two geometry types:

- **`Vector3`** — 3D vector with `.x/.y/.z` fields, magnitude helpers, and operator overloads. Used for positions, velocities, directions.
- **`QAngle`** — pitch/yaw/roll triplet (`x`/`y`/`z` are pitch/yaw/roll respectively). Mainly used for view angles.

Both are also exposed through `math.angle_vectors` and `Engine.AngleVectors` for forward-vector extraction.

---

## `Vector3`

### Constructors

| Form | Note |
|---|---|
| `Vector3.new()` | Zero vector `{0,0,0}` |
| `Vector3.new(x, y, z)` | Explicit |

You can also call the constructor directly without `new`:

```lua
local v1 = Vector3.new(1, 2, 3)
local v2 = Vector3(1, 2, 3)   -- equivalent
local v3 = Vector3()          -- zero vector
```

### Fields & methods

| Field/method | Type | Notes |
|---|---|---|
| `.x` / `.y` / `.z` | number float | Direct assignment works — `v.x = 5` writes through to the field |
| `:Length()` | number | Euclidean length |
| `:Length2D()` | number | Length ignoring `z` (i.e. `sqrt(x²+y²)`) |

### Operators

| Op | Result |
|---|---|
| `v1 + v2` | New Vector3 with sum per component |
| `v1 - v2` | New Vector3 with diff per component |
| `v * scalar` | New Vector3 with scalar multiply |

No dot product, no cross product, no equality — implement those in Lua:

```lua
local function dot(a, b) return a.x * b.x + a.y * b.y + a.z * b.z end
local function cross(a, b)
    return Vector3.new(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x)
end
local function vec_eq(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end
```

### Example

```lua
local a = Vector3.new(1, 2, 3)
local b = Vector3.new(4, 5, 6)
local d = (b - a):Length()       -- sqrt(27) ≈ 5.20
local u = b * 2                  -- {8, 10, 12}
print("dist =", d, "scaled =", u.x, u.y, u.z)
```

---

## `QAngle`

Pitch (`.x`), yaw (`.y`), roll (`.z`) — same shape as Vector3.

| Constructor | Note |
|---|---|
| `QAngle.new()` | Zero `{0,0,0}` |
| `QAngle.new(pitch, yaw, roll)` | Explicit |

```lua
local ang = QAngle.new(-10, 90, 0)
local fwd = Engine.AngleVectors(ang)  -- Vector3
```

⚠️ No operators overloaded on `QAngle`. Treat it as a plain struct.

---

## `math.angle_vectors` / `Engine.AngleVectors`

Two names for the same conversion — converts a QAngle into a forward unit Vector3 using the Source-engine convention.

```text
forward = ( cos(pitch)*cos(yaw), cos(pitch)*sin(yaw), -sin(pitch) )
```

```lua
local ang = QAngle.new(0, 90, 0)        -- looking east +Y
local fwd = math.angle_vectors(ang)
print(fwd.x, fwd.y, fwd.z)              -- 0.0, 1.0, 0.0

-- Equivalent alias
local fwd2 = Engine.AngleVectors(ang)
```

Roll is ignored — the forward is always the yaw-rotated pitch-depressed direction; the up direction would need additional derivation. If you need right/up vectors, build via:

```lua
local function angle_vectors_full(ang)
    local fwd = Engine.AngleVectors(ang)
    -- Right = forward rotated by -90° around Z (yaw - 90)
    local right = Engine.AngleVectors(QAngle.new(ang.x, ang.y - 90, 0))
    local up = Vector3.new(
        fwd.y * right.z - fwd.z * right.y,
        fwd.z * right.x - fwd.x * right.z,
        fwd.x * right.y - fwd.y * right.x)
    return fwd, right, up
end
```

---

## Common recipes

### Aim at a target position

```lua
local function aim_at(shooterEye, targetPos)
    local dx = targetPos.x - shooterEye.x
    local dy = targetPos.y - shooterEye.y
    local dz = targetPos.z - shooterEye.z
    local horiz = math.sqrt(dx*dx + dy*dy)
    local yaw   = math.atan2(dy, dx) * 180 / math.pi
    local pitch = -math.atan2(dz, horiz) * 180 / math.pi
    return QAngle.new(pitch, yaw, 0)
end

local myEye = Engine.GetBonePosition(Engine.GetLocalPlayerHandle(), "Head")
local enemyHead = Engine.GetBonePosition(target, "Head")
local aim = aim_at(myEye, enemyHead)
```

### Distance to enemy

```lua
local function entity_distance(my_handle, theirs)
    local mine = Engine.GetEntityOrigin(my_handle)
    local their = Engine.GetEntityOrigin(theirs)
    return (their - mine):Length()
end
```

### Velocity magnitude (2D)

```lua
local v = Engine.GetLocalVelocity()
local speed2D = v:Length2D()
```

---

## Pitfalls

### Field assignment

`.x`, `.y`, `.z` are direct field references — assignment works in-place (`v.x = 5` writes through to the field). Vectors you receive from `Engine.*` accessors are copies pushed across the binding — mutating them does **not** change the engine's world state. Don't mutate engine-returned vectors expecting live state to change; build a new one and pass it back through a setter.

### Vector3 vs QAngle from cmd:GetViewAngles

`cmd:GetViewAngles()` returns a QAngle. `cmd:SetViewAngles(QAngle)` expects a QAngle. Passing a Vector3 will sol-type-detect-fail silently — no-op. Always construct the right kind.

### Angle wrapping

`math.atan2(dy, dx)` returns radians in `(-π, π]`. Multiplying by `180/π` gives `(-180, 180]`. Source-engine convention is `[-180, 180]` for yaw, **don't need to wrap further** if you read directly. Writing angles outside this range can be normalized by the server (e.g. `170 + 30 = -160` after server's modular yaw); choose the shortest-arc representation.

### Vector multiplication by `0`

`v * 0` is `{0, 0, 0}` — fine. Lua float `0` doesn't produce NaN. But note `Vector3 * int` and `Vector3 * float` are the same operator — LuaJIT seamlessly converts.

---

## See also

- [engine-accessors.md](engine-accessors.md) — places that emit/receive Vector3
- [cusercmd-input.md](cusercmd-input.md) — `cmd:GetViewAngles` returns QAngle
- [trace.md](trace.md) — `Engine.TraceLine(Vector3, Vector3, int)`