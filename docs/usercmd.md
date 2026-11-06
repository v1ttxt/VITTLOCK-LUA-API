# User command (CUserCmd) and aim

Every tick the game builds a user command: view and camera angles, move axes and the buttons held. Scripts get that command in the three createmove callbacks and can read or change it before it is sent. This page covers the `CUserCmd` object, the button engine (held vs one-tick presses), and `cmd:aim`, the aim helper with its `aim` constants.

See also: [callbacks](callbacks.md), [input](input.md) for the keyboard and mouse, [utils](utils.md) for angle math.

## Which callback to use

All three callbacks receive the same command as their only argument, `cmd`. They run in this order, every command:

| Callback | When | Use it for |
|---|---|---|
| `on_pre_createmove` | First, when the game creates the command, before most of VITTLOCK's own features (movement, hero features, aimbot) apply their changes. | Raw edits that the built-in features should see: view or camera angles, move axes, `add_*` / `clear_*` button words. |
| `on_createmove` | After the built-in features. | The button engine (`press`, `pulse`, `release`, ...), `cmd:aim`, `predict_aim_camera`, the `orig_*` values. This is the normal place for script logic. |
| `on_post_createmove` | Right after every `on_createmove` handler, same command. | Last adjustments after other scripts' `on_createmove`. The button engine and `cmd:aim` also work here. |

```lua
callback.on_createmove:set(function(cmd)
    -- cmd is valid only during this call
end)
```

Notes:
- The `cmd` object is only valid during the call. Don't store it.
- Button engine methods (`press`, `pulse`, `release`, `fresh_press`, `maintain_hold`) and the `get_orig_*` getters track state across commands. Call them from `on_createmove` or `on_post_createmove`. The raw `add_*` / `clear_*` methods work in all three callbacks.
- `cmd:aim`, `cmd:predict_aim_camera` and `cmd:predict_magic_bullets_origin` only work in `on_createmove` / `on_post_createmove`.

## Buttons and InputBitMask_t

Buttons are bits of a 64-bit integer. The global table `InputBitMask_t` holds the bit for each button, read from the running game:

| Name | Button |
|---|---|
| `IN_ATTACK` | Primary fire |
| `IN_ATTACK2` | Secondary fire / zoom |
| `IN_JUMP` | Jump |
| `IN_DUCK` | Crouch |
| `IN_FORWARD`, `IN_BACK`, `IN_MOVELEFT`, `IN_MOVERIGHT` | Movement keys |
| `IN_SPEED` | Dash (the sprint key) |
| `IN_RELOAD` | Reload |
| `IN_USE` | Use |
| `IN_ABILITY1` .. `IN_ABILITY4` | Ability keys 1-4 |
| `IN_ITEM1` .. `IN_ITEM5` | Item keys |
| `IN_NONE`, `IN_ALL` | 0 and all bits |

The table holds every value the game defines, including `IN_ABILITY_HELD`, `IN_ALT_CAST`, `IN_CANCEL_ABILITY`, `IN_MANTLE`, `IN_ZIPLINE`, `IN_TELEPORT`, `IN_DOWN_DASH`, `IN_INNATE_1`..`3`, `IN_MOVE_UP`, `IN_MOVE_DOWN`, `IN_DUCK_TOGGLE` and `IN_SPEC_*`. Ability and item bits are above bit 31, so always keep masks as integers (don't divide them or turn them into floats). Combine bits with `|` and test with `&`:

```lua
local IN = InputBitMask_t
local both = IN.IN_ATTACK | IN.IN_ATTACK2
if cmd:get_buttons_down_mask() & IN.IN_ATTACK ~= 0 then
    -- firing this command
end
```

Every button method takes a mask: one bit or several bits OR'd together. A non-number mask does nothing.

### The three button words

A command carries three button words:

| Word | Meaning |
|---|---|
| down | Buttons held during this command. |
| changed | Buttons whose state changed this command: a press edge (down and changed) or a release edge (up and changed). |
| scroll (wheel) | A press from the scroll wheel. The game treats it as a new press even when the button is already held, for example jump bound to the wheel. |

The game acts on edges. A button that is in the down word with no press edge reads as "still held", not as a new press. That is why `add_buttons_down` alone may not trigger an action that needs a press, and why the button engine exists.

### Held vs pressed for one tick

| You want | Call | Every command? |
|---|---|---|
| Hold a button (crouch, sprint, charge an ability) | `cmd:press(mask)` | Yes. Keep calling it while you want it held. On the first command you stop, the engine sends the release edge for you (unless the player is physically holding the key). |
| Tap a button once (one shot, one cast) | `cmd:pulse(mask)` | Call it on the command you want the tap. It presses for one command and releases on the next. If the button was already down, it releases first and presses on the following command. Calling it on consecutive commands does not re-tap: leave one command without the call to arm it again. |
| A new press while the key is held (jump again while holding space) | `cmd:fresh_press(mask)` | Once, on the command you want it. Only affects this command. |
| Force a button up | `cmd:release(mask)` | Each command you want it up. Sends a release edge if it was down; cancels a pending `pulse`. |
| Continue a hold without a new press | `cmd:maintain_hold(mask)` | Each command. Keeps it down if it was down last command, otherwise keeps it unpressed. |

## CUserCmd fields

All fields are properties: read with `cmd.field`, write with `cmd.field = value`, unless marked read-only.

| Field | Type | Description |
|---|---|---|
| `viewangles` | Angle | The command's view angles. |
| `forwardmove` | number | Forward move axis (positive = forward, negative = back). |
| `leftmove` | number | Side move axis (positive = left). |
| `upmove` | number | Vertical move axis. |
| `command_number` | integer | The command's sequence number. Read-only. |
| `legacy_command_number` | integer | |
| `client_tick` | integer | The client tick the command was built on. |
| `impulse` | integer | |
| `weaponselect` | integer | |
| `random_seed` | integer | The command's random seed. |
| `mousedx`, `mousedy` | integer | Mouse movement this command. |
| `consumed_server_angle_changes` | integer | |
| `cmd_flags` | integer | |
| `pawn_entity_handle` | integer | The pawn the command is for. The low 14 bits are the entity index (`cmd.pawn_entity_handle & 0x3FFF`). |
| `execute_ability_indices` | integer | |
| `camera_roaming_speed` | number | |
| `in_shop` | boolean | The shop is open. |
| `using_free_cursor` | boolean | The game's free cursor is up. |
| `enemy_hero_aimed_at` | integer | |
| `vec_camera_position` | Vector | The command's camera position. |
| `ang_camera_angles` | Angle | The command's camera angles. In Deadlock's third-person view this is where the player is looking; abilities and shots use it. |
| `orig_vec_camera_position` | Vector | The command's camera position before any feature or script changed it. Read-only. |
| `orig_ang_camera_angles` | Angle | The command's camera angles before any feature or script changed it. Read-only. |

Notes:
- When the command carries no camera, `vec_camera_position` and `ang_camera_angles` read the camera this command started with in `on_createmove` / `on_post_createmove`. In `on_pre_createmove` that fallback is not reliable (it can be `(0, 0, 0)` and `viewangles`), so check the values before using them there.
- The `orig_*` values are meant for `on_createmove` / `on_post_createmove`. Use them to undo or compare against changes made earlier in the same command.
- `tostring(cmd)` gives `CUserCmd(<command_number>)`.

```lua
-- Strafe left while R is held (raw move axes, in on_pre_createmove so the
-- built-in movement features see it).
callback.on_pre_createmove:set(function(cmd)
    if input.is_down(Enum.ButtonCode.KEY_R) then
        cmd.leftmove = 1
    end
end)
```

## Button engine methods

### `cmd:press(mask)`
Holds the buttons down on this command. It sends a press edge only if they were up on the last command. Call it every command you want the buttons held. On the first command you stop calling it, the engine releases them with a release edge, unless the player is holding the key.

### `cmd:pulse(mask)`
Taps the buttons: a press on this command and a release on the next. If a button was down on the last command, it releases on this command, presses on the next and releases on the one after. It fires once per run of consecutive commands that call `pulse` with that button. Skip a command to tap again.

### `cmd:fresh_press(mask)`
Sets the buttons' scroll bit on this command. The game reads that as a new press even while the button is held. Cancels a pending `pulse` for those buttons.

### `cmd:release(mask)`
Releases the buttons on this command. Sends a release edge if they are down now or were down on the last command, and cancels a pending `pulse`.

### `cmd:maintain_hold(mask)`
If the buttons were down on the last command, keeps them down with no new edge. If they were not, clears them so they are not pressed on this command. Cancels a pending `pulse`.

### `cmd:was_button_down(mask)`
Returns `true` if any of the buttons was down in the last command that was sent (its final state, after every feature and script).

### Raw word methods
These change one word directly and do no edge tracking. They work in all three callbacks.

| Method | Effect |
|---|---|
| `cmd:add_buttons_down(mask)` | Adds the buttons to the down word. |
| `cmd:add_buttons_changed(mask)` | Adds the buttons to the changed word. |
| `cmd:add_buttons_wheel(mask)` | Adds the buttons to the scroll word. |
| `cmd:clear_button_down_state(mask)` | Removes the buttons from the down word. |
| `cmd:clear_buttons_changed_mask(mask)` | Removes the buttons from the changed word. |
| `cmd:clear_buttons_wheel_mask(mask)` | Removes the buttons from the scroll word. |
| `cmd:clear_button_all_states(mask)` | Removes the buttons from all three words and drops their sub-tick press/release steps, so the press is fully removed from the command. |

To block a button the player is pressing, use `clear_button_all_states`. Clearing only the down word leaves the sub-tick steps, and the game may still see the press.

### Reading the words

| Method | Returns |
|---|---|
| `cmd:get_buttons_down_mask()` | The down word now. `cmd:get_buttons_mask()` is the same. |
| `cmd:get_buttons_changed_mask()` | The changed word now. |
| `cmd:get_buttons_wheel_mask()` | The scroll word now. |
| `cmd:get_orig_buttons_down_mask()` | The down word as the player's input left it, before any feature or script. `cmd:get_orig_buttons_mask()` is the same. |
| `cmd:get_orig_buttons_changed_mask()` | The changed word before any feature or script. |
| `cmd:get_orig_buttons_wheel_mask()` | The scroll word before any feature or script. |

All return integers (InputBitMask_t bits). Read the `orig` words in `on_createmove` / `on_post_createmove`.

```lua
local IN = InputBitMask_t
local BC = Enum.ButtonCode

callback.on_createmove:set(function(cmd)
    -- Hold J: crouch for as long as the key is held.
    if input.is_down(BC.KEY_J) then
        cmd:press(IN.IN_DUCK)
    end

    -- The player pressed fire this command (their own input, not a script's).
    if cmd:get_orig_buttons_changed_mask() & IN.IN_ATTACK ~= 0
        and cmd:get_orig_buttons_down_mask() & IN.IN_ATTACK ~= 0 then
        print("fire pressed on command " .. cmd.command_number)
    end
end)
```

```lua
-- Tap ability 1 once each time K is pressed.
local IN = InputBitMask_t
local want_cast = false

callback.on_frame:set(function()
    if input.is_pressed(Enum.ButtonCode.KEY_K) then
        want_cast = true
    end
end)

callback.on_createmove:set(function(cmd)
    if want_cast then
        want_cast = false
        cmd:pulse(IN.IN_ABILITY1)
    end
end)
```

## Jump state

### `cmd:get_ground_jump_state()`
What a jump would do at the start of this command, from the game's prediction of the local pawn.

Returns four values:

| Value | Type | Description |
|---|---|---|
| `grounded` | boolean or nil | The pawn stands on something. |
| `ready` | boolean or nil | A jump now would be a ground jump. |
| `source_command` | integer or nil | The command number the state was recorded for. |
| `source_tick` | integer or nil | The tick it was recorded at. |

All four are `nil` when the previous command has no record (for example right after spawning, or while prediction is not running).

### `cmd:get_dash_jump_state()`
Returns `dash, source_command, source_tick`. `dash` is `true` when a jump at the start of this command would be a dash jump. All `nil` when there is no record.

```lua
local IN = InputBitMask_t
-- Jump on the first command where a ground jump is possible while space is held.
callback.on_createmove:set(function(cmd)
    if not input.is_down(Enum.ButtonCode.KEY_SPACE) then return end
    local grounded, ready = cmd:get_ground_jump_state()
    if ready then
        cmd:fresh_press(IN.IN_JUMP)
    end
end)
```

## Aim

### `cmd:aim(options)`
Runs an aim request on this command and returns an `aim.status` value. Call it from `on_createmove` or `on_post_createmove`, on every command for as long as you want to aim. Stop calling it to end the request. If you skip a command, the next call starts over as a new request.

| Option | Type | Default | Description |
|---|---|---|---|
| `aim_pos` | Vector | | World point to aim at. |
| `aim_angle` | Angle | | Angle to aim at, instead of `aim_pos`. One of the two is required. |
| `aim_type` | integer | `aim.type.DEFAULT` | `aim.type` bits, see below. |
| `target_ent` | player_pawn | nil | The target hero. Only player pawns are used. |
| `ability_ent` | ability | nil | The ability you are aiming. |
| `smooth` | number | 0 | Smoothing in percent. 0 snaps. DEFAULT and SILENT only. |
| `allowed_min_fov` | number | 1 | The request is READY once the aim is within this many degrees. |
| `trace_radius` | number | 0 | PSILENT: how far (units) the shot may pass from the point and still count. At least 1 is used. |
| `trace_pos` | Vector | nil | MAGIC_BULLETS: the point the bend must have a clear line to. |
| `mb_only` | boolean | false | With MAGIC_BULLETS combined with another type: use only the magic bullet bend. |
| `custom_ang_pitch` | number | nil | Replaces the solved pitch. |
| `custom_ang_yaw` | number | nil | Replaces the solved yaw. |
| `on_process_callback` | function | nil | Called on each command the request is PENDING, AIMING, BUSY or BLOCKED. |
| `on_aimed_callback` | function | nil | Called on the command the request is READY. |

Both callbacks take no arguments. An error inside them is written to the script's log and does not stop the script.

#### aim.type

| Constant | Value | Effect |
|---|---|---|
| `aim.type.NONE` | 0 | Treated as DEFAULT. |
| `aim.type.DEFAULT` | 1 | Turns your real camera toward the point (smoothed). The commands that follow are built from the turned camera. The turn is visible on screen. |
| `aim.type.SILENT` | 2 | Turns only the command's angles (smoothed from the last silent angles). Your camera doesn't move. |
| `aim.type.PSILENT` | 4 | Aims this command's shot at the point without moving your camera. READY or BLOCKED on the same command. |
| `aim.type.MAGIC_BULLETS` | 8 | Bends the command's camera so the shot can reach a point your camera can't see directly. The bend limit is the one set in the menu. |

If several bits are set, one type runs: MAGIC_BULLETS when it is the only bit or `mb_only` is true, else PSILENT, else SILENT, else DEFAULT.

With DEFAULT, `smooth` sets how fast the camera closes in: the time constant is roughly `smooth / 600` seconds (smooth 100 is about 0.17 s, smooth 20 is close to a snap). With smoothing on, a small random jitter is added within the last degree.

#### aim.status

| Constant | Value | Meaning |
|---|---|---|
| `aim.status.INVALID` | 0 | Nothing ran: no live local pawn, no `aim_pos` / `aim_angle`, or called outside `on_createmove` / `on_post_createmove`. |
| `aim.status.PENDING` | 1 | The request started this command (DEFAULT), or MAGIC_BULLETS is still looking for a bend. |
| `aim.status.AIMING` | 2 | Turning toward the point, not within `allowed_min_fov` yet. |
| `aim.status.READY` | 3 | On target this command: fire or cast now. |
| `aim.status.BUSY` | 4 | Another request already owns this command's aim. |
| `aim.status.BLOCKED` | 5 | The aim could not be applied this command (no clear shot for PSILENT, the bend could not be applied, or the command could not be turned). |

Each command has one aim request. The first call owns it. A later call on the same command for a different ability or target gets BUSY. VITTLOCK's own hero features use the same request and run before `on_createmove`, so you may get BUSY while one of them is aiming.

```lua
local IN = InputBitMask_t
local status_name = {}
for k, v in pairs(aim.status) do status_name[v] = k end

local function nearest_enemy(lp)
    local best, best_d = nil, math.huge
    for _, e in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        if e:is_alive() and not e:is_dormant() then
            local d = lp:get_origin():Distance(e:get_origin())
            if d < best_d then best, best_d = e, d end
        end
    end
    return best
end

-- Hold L: aim at the nearest enemy's head and fire when on target.
callback.on_createmove:set(function(cmd)
    if not input.is_down(Enum.ButtonCode.KEY_L) then return end
    local lp = entity_list.local_pawn()
    if not lp or not lp:is_alive() then return end
    local enemy = nearest_enemy(lp)
    local head = enemy and enemy:get_bone_pos("head")
    if not head then return end

    local st = cmd:aim({
        aim_pos = head,
        target_ent = enemy,
        aim_type = aim.type.DEFAULT,
        smooth = 60,
        allowed_min_fov = 1,
        on_aimed_callback = function()
            cmd:pulse(IN.IN_ATTACK)
        end,
    })
    if st == aim.status.BLOCKED then
        print("aim blocked: " .. status_name[st])
    end
end)
```

### `cmd:predict_aim_camera(aim_pos)`
Returns the camera pose whose aim ray passes through `aim_pos` for this command, as a table, or `nil` when there is none. Only works in `on_createmove` / `on_post_createmove` while the local pawn is alive.

| Key | Type | Description |
|---|---|---|
| `angle` | Angle | Camera angles that put the aim ray on the point. |
| `cam_pos` | Vector | Where the camera sits at that angle. |
| `pivot` | Vector | The point the camera orbits around. |
| `launch` | Vector | The point on the aim ray closest to the pivot. |

Deadlock's camera sits behind and beside the hero, so aiming the camera straight at a point is not the same as putting the aim ray through it. `angle` accounts for that.

```lua
callback.on_createmove:set(function(cmd)
    local target = utils.find_nearest_visible_enemy()
    local head = target and target:get_bone_pos("head")
    local pose = head and cmd:predict_aim_camera(head)
    if pose then
        cmd.ang_camera_angles = pose.angle
    end
end)
```

### `cmd:predict_magic_bullets_origin(aim_pos)`
Returns the origin (Vector) that a magic bullet bend from this command's camera would shoot from to reach `aim_pos`, or `nil` when no bend reaches it. It runs its own search and does not affect a running `cmd:aim` request. Only in `on_createmove` / `on_post_createmove`.

### `cmd:mark_aim_movement_frame(...)`
Accepted for compatibility. It does nothing: the aim types that turn the command's angles already correct the movement themselves.
