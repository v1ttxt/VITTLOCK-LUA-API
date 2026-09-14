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
| `Engine.GetEntityHealth(handle)` | integer | Current entity health (`m_iHealth`) |
| `Engine.GetEntityMaxHealth(handle)` | integer | Maximum entity health (`m_iMaxHealth`) |
| `Engine.IsEntityAlive(handle)` | bool | True if `m_lifeState == 0` and `m_iHealth > 0` |
| `Engine.EntityHasModifierState(handle, state)` | bool | Any modifier on the entity has the given `EModifierState` |
| `Engine.EntityHasModifier(handle, name)` | bool | Modifier creation time > 0 for the given name string |
| `Engine.GetEntityModifiers(handle)` | table[] | Array of active modifier objects on the entity |
| `Engine.GetModifierRemainingTime(handle, name)` | number | Remaining seconds for named modifier, `-1` if absent |
| `Engine.GetEntityAbility(handle, name)` | table or nil | Find ability whose designer-name contains `name` |
| `Engine.GetEntityAbilities(handle)` | table[] or nil | Fetch all ability tables for an entity |
| `Engine.IsAbilityReady(handle, name)` | bool | Check if ability or item is equipped and off cooldown |
| `Engine.CastAbility(cmd, name)` | bool | Taps the exact button mask for a named ability or item |
| `Engine.GetProjectiles()` | table[] | Returns array of active projectile entities in the world |
| `Engine.GetBonePosition(handle, slotName)` | Vector3 | First bone of the named `HitboxSlot` |
| `Engine.GetProp(handle, [class,] prop)` | any | Read any schema field off an entity dynamically |

### Bone slots

`slotName` must be one of:

- `"Head"` (default)
- `"Neck"`
- `"Torso"`
- `"Arms"`
- `"Legs"`

Anything else falls through to `"Head"`.

### Ability table

Returned by `Engine.GetEntityAbility(handle, name)` or `ent:get_ability(name)`:

| Field / Method | Returns | Description |
|---|---|---|
| `ab.get_cooldown()` | number | Binary cooldown (`0.0` ready, `10.0` cooling down) |
| `ab.get_cooldown_end()` / `ab.m_flCooldownEnd` | number | Cooldown end timestamp in game clock seconds |
| `ab.get_charges()` | integer | Remaining active charges (`m_iRemainingCharges`) |
| `ab.get_stacks()` / `ab.m_nNumStacks` | integer | Current stack count (auto-resolves for `CItem_RestorativeLocket`) |
| `ab.get_toggle_state()` / `ab.m_bToggleState` | bool | Active toggle state (`m_bToggleState`) |
| `ab.get_slot()` / `ab.m_eAbilitySlot` | integer | Slot index enum |
| `ab.get_slot_name()` | string | Slot name string (e.g. `"ESlot_Signature_1"`) |
| `ab.get_button_name()` | string | Button name (e.g. `"IN_ABILITY1"`, `"IN_ITEM1"`) |
| `ab.get_button_mask()` | integer | Raw button bitmask for `CUserCmd:AddButtonState` |
| `ab.get_scaled_property(prop)` | number | Scaled radius/height property |
| `ab.get_aoe_radius()` | number | AoE effect radius in world units |
| `ab.cast(cmd)` | bool | Automatically applies button bit to user command this tick |

### Modifier table

Returned in the array from `Engine.GetEntityModifiers(handle)`:

| Field / Method | Returns | Description |
|---|---|---|
| `mod.name` | string | RTTI designer name (e.g. `"modifier_citadel_stunned"`) |
| `mod.creation` | number | Game clock timestamp when applied |
| `mod.duration` / `mod.m_flDuration` | number | Total duration in seconds (`<= 0` if passive/permanent) |
| `mod.elapsed` | number | Seconds active so far (`curtime - creation`) |
| `mod.remaining` | number | Seconds remaining (`duration - elapsed`, or `0` if passive) |
| `mod.subclass_id` | integer | Ability subclass ID |
| `mod.m_iTeam` | integer | Team number |
| `mod.get_vdata()` | table | Returns `{ m_eDebuffType = 1, m_nAttributes = attr }` |

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

## Game rules & Network channel

Global helpers for server timing and ping estimation:

| Function | Returns | Description |
|---|---|---|
| `game_rules.game_time()` | number | Server game clock in seconds (`Engine.GetCurTime()`) |
| `net_channel.latency()` | number | Current latency / round-trip time in seconds (e.g. `0.03`) |

```lua
local pingMs = net_channel.latency() * 1000.0
local timeNow = game_rules.game_time()
```

---

## See also

- [trace.md](trace.md) — `Engine.TraceLine` mechanism
- [modifier-states.md](modifier-states.md) — `EModifierState` constants
- [entity-wrappers.md](entity-wrappers.md) — `entity_list` convenient loop API
- [math-vector3-qangle.md](math-vector3-qangle.md) — `Vector3` / `QAngle` API