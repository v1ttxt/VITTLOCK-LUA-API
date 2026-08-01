# Engine accessors

The `Engine` module is the main read-only surface for the live game world. It wraps the entity system, the local pawn, the camera, the global vars, and screen projection helpers. Plus `Engine.TraceLine` — see [trace.md](trace.md) for that one.

---

## Local player accessors

| Function | Returns | Description |
|---|---|---|
| `Engine.GetLocalPlayerHandle()` | integer | Your pawn entity handle, `-1` if no pawn |
| `Engine.GetLocalVelocity()` | Vector3 | Velocity in units/sec — read from offset `0x404` of the local pawn |
| `Engine.GetLocalMoveType()` | integer | `MoveType_t` enum value (unbound to a named enum in Lua — compare against the game's MoveType values: `MOVETYPE_NONE=0`, `MOVETYPE_WALK=2`, `MOVETYPE_FLYGRAVITY=4`, `MOVETYPE_NOCLIP=8`, etc.) |
| `Engine.GetLocalFlags()` | integer | `m_fFlags` bitmask (FL_ONGROUND=1, FL_DUCKING=2, FL_WATERJUMP=8, ...) |
| `Engine.GetCameraAngles()` | QAngle | Local view angles (pitch/yaw/roll) |
| `Engine.HasModifierState(state)` | bool | Local pawn has the given `EModifierState`-*see [modifier-states.md](modifier-states.md)* |
| `Engine.IsOnWall()` | bool | Wall-jumping / wall-sliding state — derived from the `citadel_ability_jump` ability's `m_eWallJumpFacing` and `m_vCurrentWallNormal` |
| `Engine.GetTickInterval()` | number | Per-tick interval in seconds (`GlobalVarsBase->m_flIntervalPerTick`) — typical `0.015625` at 64 Hz |
| `Engine.GetCurTime()` | number | Game clock seconds since server start (`GlobalVarsBase->m_flCurrentTime`) |
| `Engine.GetAirAccelerate()` | number | Hardcoded `10.0` — not bound to a cvar; placeholder for future |

```lua
if Engine.HasModifierState(EModifierState.MODIFIER_STATE_STUNNED) then
    log.info("stunned")
end

if Engine.IsOnWall() then
    cmd:AddButtonState(InputBitMask_t.IN_JUMP)  -- walljump kick predict
end
```

### Caveats

- `GetLocalVelocity` reads raw pawn memory at `pawn + 0x404`. If Deadlock SDK offsets drift across versions, this will return garbage or trigger an access violation.
- `IsOnWall` scans abilities for `citadel_ability_jump` by designer-name substring. If that name changes in a future patch, this returns `false` until the binding is updated.

---

## Per-entity accessors

Every `Engine.GetEntity*` accessor masks the incoming handle via a low-bits mask and looks the entity up in the entity system. So you can pass the high-bit-padded handles (handle | (entry << serial)) safely.

| Function | Returns | Description |
|---|---|---|
| `Engine.GetPlayers()` | `int[]` | Handles of every player pawn (controllers → pawn) |
| `Engine.GetEntityTeam(handle)` | integer | Team number, `-1` if not found |
| `Engine.GetEntityOrigin(handle)` | Vector3 | World position (`m_pGameSceneNode->m_vecAbsOrigin`) — zero vector on fail |
| `Engine.GetEntityName(handle)` | string | Designer-name (e.g. `"citadel_player_hero_vindicta"`), `"Entity"` if name missing |
| `Engine.IsPlayer(handle)` | bool | True if the entity is a `CCitadelPlayerPawn` |
| `Engine.EntityHasModifierState(handle, state)` | bool | Any modifier on the entity has the given `EModifierState` |
| `Engine.EntityHasModifier(handle, name)` | bool | Modifier creation time > 0 for the given name string |
| `Engine.GetEntityAbility(handle, name)` | table or nil | Find ability whose designer-name contains `name` |
| `Engine.GetBonePosition(handle, slotName)` | Vector3 | First bone of the named `HitboxSlot` |

### Bone slots

`slotName` must be one of:

- `"Head"` (default)
- `"Neck"`
- `"Torso"`
- `"Arms"`
- `"Legs"`

Anything else falls through to `Head`.

### Ability table

```lua
local ab = Engine.GetEntityAbility(handle, "citadel_ability_jump")
if ab then
    local cd = ab.get_cooldown()   -- 0.0 (no cooldown) or 10.0 (cd) — see caveat below
end
```

⚠️ The `get_cooldown` closure returns either `0.0` or `10.0` based on `m_bIsCoolingDownInternal()`. There is no per-cooldown-seconds resolution — only the binary state. Read `m_flCooldownStart` directly via reflection if you need a real timer.

### Example: enemy listing

```lua
for _, h in ipairs(Engine.GetPlayers()) do
    if h ~= Engine.GetLocalPlayerHandle() and Engine.GetEntityTeam(h) ~= Engine.GetEntityTeam(Engine.GetLocalPlayerHandle()) then
        local pos = Engine.GetEntityOrigin(h)
        log.info(Engine.GetEntityName(h), "team", Engine.GetEntityTeam(h), "at", pos.x, pos.y, pos.z)
    end
end
```

### Pitfalls

- A padded handle (e.g. `0x12340001`) is acceptable — the mask cares only about the low bits. But a handle `== -1` (sentinel "no pawn") is passed through (`-1 & 0xFFF = 0xFFF`) which the engine will look up and return `nullptr` for, gracefully. So queries on stale `-1` handles return safe defaults, not crashes.
- On team death/respawn, the historical handle becomes invalid — queries return `Vector3{}` / empty strings / `false`. Always check `IsPlayer` first.

---

## Screen & geometry

| Function | Returns | Description |
|---|---|---|
| `Engine.GetScreenSize()` | `{w, h}` table | Viewport size from `ImGui::GetIO().DisplaySize` |
| `Engine.WorldToScreen(pos:Vector3)` | `{x, y, visible}` table | Project via `Math::WorldToScreen` |
| `Engine.AngleVectors(qa:QAngle)` | Vector3 | Forward unit vector from pitch/yaw QAngle |
| `Engine.PlayVol()` | nil | **Legacy no-op**. Preserved for old scripts that might call it |

`AngleVectors` formula:

```text
forward = ( cos(pitch_radians) * cos(yaw_radians),
            cos(pitch_radians) * sin(yaw_radians),
           -sin(pitch_radians)              )
```

`WorldToScreen` returns a table; `visible` is `true` only when the world position projects within the viewport frustum. Outside that, set `x=0,y=0,visible=false` — but rendering the rect anyway is safe because `render.*` draws on the foreground draw list (no offscreen clip).

```lua
local s = Engine.GetScreenSize()
local p = Engine.WorldToScreen(Vector3.new(100, 200, 64))
if p.visible then
    render.filled_rect(p.x - 2, p.y - 2, 4, 4, 1, 0, 0, 1, 0)
end
```

---

## `Engine.TraceLine` — ray-cast

Full doc: [trace.md](trace.md).

```lua
local tr = Engine.TraceLine(start, Vector3.new(end.x, end.y, end.z), skipHandle)
if tr.hit then
    log.info("blocked at fraction", tr.fraction, "by entity", tr.hit_entity)
end
```

---

## See also

- [trace.md](trace.md) — `Engine.TraceLine` mechanism
- [modifier-states.md](modifier-states.md) — `EModifierState` constants
- [entity-wrappers.md](entity-wrappers.md) — `entity_list` convenient loop API
- [math-vector3-qangle.md](math-vector3-qangle.md) — `Vector3` / `QAngle` API