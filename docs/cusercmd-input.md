# `CUserCmd` & input

`CUserCmd` is the per-tick user command. Mutating `cmd` in `on_pre_createmove` changes what the server sees this tick.

All accessors check whether the cmd carries the base sub-message first — if it doesn't, getters return zero and setters silently no-op.

---

## Lifecycle

| When | What happens to `cmd` |
|---|---|
| `on_pre_createmove(cmd)` | Engine just constructed the cmd, mutating it changes the outgoing wire. Apply button holds, set movement here. |
| `on_post_createmove(cmd)` | Wire message sealed. Reading the cmd is fine but mutations won't reach the server this tick. Use it to log info, drive AI behaviour, update render state. |

The Lua-side `cmd` is a C++ object reference, *not* a copy — both callbacks get the same instance, just on different sides of the tick boundary.

---

## Forward / side / up & view angles

| Method | Signature | Description |
|---|---|---|
| `cmd:GetForwardMove()` | → number | Forward axis (`cmd->base().forwardmove()`) |
| `cmd:SetForwardMove(v)` | number → nil | Set forward axis (with `has_base` guard) |
| `cmd:GetSideMove()` | → number | Lateral axis (`base().leftmove()`) |
| `cmd:SetSideMove(v)` | number → nil | Set lateral |
| `cmd:SetUpMove(v)` | number → nil | Vertical impulse |
| `cmd:GetViewAngles()` | → QAngle | `(base().viewangles().x/y/z)` — falls back to zero QAngle when missing |
| `cmd:SetViewAngles(QAngle)` | QAngle → nil | Set view angles per-axis; no-ops without `has_base` |

Examples:

```lua
callbacks.on_pre_createmove(function(cmd)
    -- Auto-forward: walk forward 100 units
    cmd:SetForwardMove(100)
end)

callbacks.on_pre_createmove(function(cmd)
    -- Aim-assist: snap yaw toward nearest enemy
    local target = nearestEnemy()
    local self = Engine.GetLocalPlayerHandle()
    local myPos = Engine.GetEntityOrigin(self)
    local enemyPos = Engine.GetEntityOrigin(target)
    local dx, dy = enemyPos.x - myPos.x, enemyPos.y - myPos.y
    local yaw = math.atan2(dy, dx) * 180 / math.pi
    cmd:SetViewAngles(QAngle.new(0, yaw, 0))
end)
```

⚠️ Deadlock is a MOBA — server may also drive yaw for ability/camera purposes. Setting view angles too aggressively can cause snap-fighting with the camera. Use this with throttle.

---

## Camera

| Method | Description |
|---|---|
| `cmd:GetCameraAngles()` | Prefers `cmd->ang_camera_anglesXX` if available, falls back to active `CCitadelCameraManager` and then to the local pawn's camera angles |
| `cmd:GetCameraPosition()` | Prefers active camera's `m_vecPosition`, falls back to pawn origin |
| `cmd:SetCameraPosition(x, y, z)` | **Only writes if `cmd.cmd.has_vec_camera_position()`** — silently no-ops if the cmd doesn't already carry a camera position field. All non-finite values (`Inf`/`NaN`) silently dropped. |

```lua
callbacks.on_pre_createmove(function(cmd)
    local p = cmd:GetCameraPosition()
    log.info("camera at", p.x, p.y, p.z)
    local a = cmd:GetCameraAngles()
    log.info("camera angle", a.x, a.y, a.z)
end)
```

---

## Buttons

| Method | Description |
|---|---|
| `cmd:GetButtonState()` | Raw `buttonstate1` bitmask (`uint64_t`) |
| `cmd:HasButtonState(bit)` | Test a single bit (see `InputBitMask_t`) |
| `cmd:AddButtonState(bit)` | Hold the button for this tick |
| `cmd:RemoveButtonState(bit)` | Clear the button |
| `cmd:HoldButton(bit)` | Alias of `AddButtonState` |
| `cmd:ClearButton(bit)` | Alias of `RemoveButtonState` |
| `cmd:PressButton(bit)` | Press this single tick (set + auto-clear at frame end) |
| `cmd:TapButton(bit)` | Quick tap (press + release) |
| `cmd:add_buttonstate1(bit)` | Legacy alias of `PressButton` |

`AddButtonState` and `HoldButton` are the same operation — `HoldButton` is the canonical name, `AddButtonState` is the legacy Lua alias. Both end up setting the bit for this tick.

```lua
callbacks.on_pre_createmove(function(cmd)
    -- auto-attack while holding IN_ABILITY_HELD
    if cmd:HasButtonState(InputBitMask_t.IN_ABILITY_HELD) then
        cmd:AddButtonState(InputBitMask_t.IN_ATTACK)
    end
    -- always jump
    cmd:AddButtonState(InputBitMask_t.IN_JUMP)
end)
```

⚠️ The bit parameter is a 64-bit integer. Lua within 5.1 represents all numbers as doubles — 64-bit values above `2^53` would round-trip lossy. Currently no `InputBitMask_t` constant exceeds 53 bits, so all current constants are safe.

---

## `InputBitMask_t` enum

Bound into the Lua table `InputBitMask_t`. Each entry is an integer of the corresponding button bit. The enum encodes the **per-tick** button state for Deadlock's user command.

| Constant | Value |
|---|---|
| `IN_NONE` | 0 |
| `IN_ATTACK` | `0x1` bit |
| `IN_JUMP` | `0x2` bit |
| `IN_DUCK` | `0x4` bit |
| `IN_FORWARD` | `0x8` bit |
| `IN_BACK` | `0x10` bit |
| `IN_USE` | `0x20` bit |
| `IN_MOVELEFT` | `0x40` bit |
| `IN_MOVERIGHT` | `0x80` bit |
| `IN_ATTACK2` | `0x100` bit |
| `IN_RELOAD` | `0x200` bit (refund/reload slow) |
| `IN_SPEED` | `0x400` bit (sprint) |
| `IN_WEAPON1` | `0x800` bit |
| `IN_ABILITY1` | `0x1000` bit |
| `IN_ABILITY2` | `0x2000` bit |
| `IN_ABILITY3` | `0x4000` bit |
| `IN_ABILITY4` | `0x8000` bit |
| `IN_ABILITY_HELD` | `0x10000` bit (held lane ability — parry/two-action) |
| `IN_INNATE_1` | `0x20000` bit (innate ability slot) |

The integer value is what would be reported by `cmd:GetButtonState()` — combine them with bitwise OR (or `+`, since bits are unique).

```lua
local combined = InputBitMask_t.IN_ATTACK + InputBitMask_t.IN_JUMP  -- both bits
cmd:AddButtonState(combined)
```

⚠️ LuaJIT 5.1 has no native `bit64`, but it has the `bit32` library. The bindings open `bit32` for numeric-only operations — bitwise on these values works because they fit in 32 bits.

---

## Putting it together

### Auto-fire for half a second after hit

```lua
local m = ui.script()
m:category("Combat")
local enabled = m:switch("Auto fire when hit", false)
local fireUntil = 0

callbacks.on_add_modifier(function(mod, ent)
    if not enabled:get_bool() then return end
    if ent:get_handle() ~= Engine.GetLocalPlayerHandle() then return end
    -- hit modifier: any modifier applied to self counts
    fireUntil = ImGui.GetTime() + 0.5
end)

callbacks.on_pre_createmove(function(cmd)
    if not enabled:get_bool() then return end
    if ImGui.GetTime() < fireUntil then
        cmd:AddButtonState(InputBitMask_t.IN_ATTACK)
    end
end)
```

### Walk-only mode

```lua
local m = ui.script()
m:category("Movement")
local enable = m:switch("Always walk", false)

callbacks.on_pre_createmove(function(cmd)
    if not enable:get_bool() then return end
    -- cap forward/side velocity to slow walk
    local fwd = cmd:GetForwardMove()
    if fwd > 50 then cmd:SetForwardMove(50)
    elseif fwd < -50 then cmd:SetForwardMove(-50)
    end
    local lat = cmd:GetSideMove()
    if lat > 50 then cmd:SetSideMove(50)
    elseif lat < -50 then cmd:SetSideMove(-50)
    end
end)
```

### Self-stun log

```lua
callbacks.on_pre_createmove(function(cmd)
    if Engine.HasModifierState(EModifierState.MODIFIER_STATE_STUNNED) then
        log.info(string.format("blocked: curtime %.2f buttons=0x%x", Engine.GetCurTime(), cmd:GetButtonState()))
    end
end)
```

---

## Pitfalls

### Mutation in `on_post_createmove`

Server already has the wire message. Anything you change here is observed only by prediction/local render. Use `on_pre_createmove` for server-visible changes.

### Setting `cmd:SetViewAngles` with NaN angles

`QAngle` is plain — no NaN check on the Lua side. `set_x(yaw_radians * 180 / pi)` is fine for normal angles, but `math.atan2(0,0)` returns `0`, not NaN. Don't manually `math.deg(math.atan(pitch,0))` for your pitch pole cases.

### Calling buttons with bad bits

`cmd:AddButtonState(12345)` — `12345` is not a defined `InputBitMask_t`. The engine stores it raw as if it were a button bit — your buttons will be messy but no crash. No validation is enforced.

### Modifying button state across `on_pre_` then `on_post_`

These are different dispatches over the same `cmd` — your mutations from pre are *still present* in post. If you want to track deltas between the two, diff `GetButtonState()` on entry to each.

---

## See also

- [callbacks-events.md](callbacks-events.md) — when these pre/post callbacks fire
- [modifier-states.md](modifier-states.md) — `EModifierState` constants used with `Engine.HasModifierState`