# Utils

The `utils` table collects helpers that don't belong to one object: the camera, quick enemy finders, angle math, VData lookups, bullet lead, hitbox intersection tests, minimap conversions, and a few misc calls. `utils.json_encode` / `utils.json_decode` are also in this table; they are documented in [core](core.md#utilsjson_encode--utilsjson_decode).

Unless a function says otherwise, call these from `on_frame` or the createmove callbacks (game logic), not `on_draw`.

## Camera

### `utils.get_camera_pos()`
Returns the active camera's position as a `Vector`, or (0, 0, 0) when there is no camera. In Deadlock the camera sits behind and beside the hero; this is where the view is drawn from.

### `utils.get_camera_angles()`
Returns the active camera's angles as an `Angle`, or (0, 0, 0) when there is no camera.

### `utils.get_camera_fov()`
Returns the camera's current field of view in degrees, clamped to 10..170. Returns 75 when there is no camera.

### `utils.is_camera_snapping()`
Always returns `false, 0`.

### `utils.fov_to_pixel_radius(fov)`
Returns the radius in screen pixels of a circle `fov` degrees around the screen centre. Use it to draw an FOV circle that matches an angle limit. Returns 0 when `fov` is 0 or less, or there is no camera.

- `fov` (number): the angle from the screen centre, in degrees (the circle's radius, not its full width).

```lua
local radius = 0
callback.on_frame:set(function()
    radius = utils.fov_to_pixel_radius(8)
end)
-- In on_draw, draw a circle of `radius` pixels at the screen centre (see the render page).
```

## Target finders

These look at enemy heroes only and need a live local pawn (they return `nil` otherwise). "Nearest" means the smallest angle from the camera's view direction, not distance.

### `utils.find_nearest_visible_enemy()`
Returns the live enemy hero ([player_pawn](entities.md#player_pawn)) whose origin is at the smallest angle from the camera, among those visible to your team, or `nil`.

"Visible" here means the hero is networked to you and not invisible to your team. It is not a line-of-sight check: use [trace](trace.md) for that.

### `utils.find_nearest_fov_enemy()`
Same as `find_nearest_visible_enemy`, without the visibility check (alive and enemy only).

### `utils.find_target_in_fov(fov)`
Returns the visible live enemy hero with a body bone (head, spine, pelvis, upper arms, upper legs) within `fov` degrees of the camera's view direction, or `nil`.

- `fov` (number): the maximum angle in degrees.
- Heroes whose origin is more than 90 degrees off the view are skipped.
- The bone with the smallest angle wins, except that a hero whose best bone is less than 3 degrees better only wins if it is also closer to the camera. This favours the nearer hero when two overlap on screen.

```lua
callback.on_frame:set(function()
    local t = utils.find_target_in_fov(10)
    if t then
        print("target in 10 deg: " .. t:get_name())
    end
end)
```

## Angles

### `utils.calc_angle(src, dst)`
Returns the `Angle` that looks from `src` to `dst`: pitch in -89..89 (negative is up), yaw in -180..180, roll 0. Returns `nil` if either argument isn't a `Vector` or has a non-finite component. Returns (0, 0, 0) when the points are equal.

| Name | Type | Description |
|---|---|---|
| `src` | Vector | The eye or camera position. |
| `dst` | Vector | The point to look at. |

### `utils.get_fov(a, b)`
Returns the angle in degrees (0..180) between the view directions `a` and `b`. Roll is ignored and the order doesn't matter. Returns `3.4e38` (the largest float) if either argument isn't an `Angle` or isn't finite.

| Name | Type | Description |
|---|---|---|
| `a` | Angle | First view direction. |
| `b` | Angle | Second view direction. |

### `utils.angle_diff(a, b)`
Returns the shortest signed difference `a - b` in degrees, in -180..180. Returns 0 if either number isn't finite.

| Name | Type | Description |
|---|---|---|
| `a` | number | Angle in degrees. |
| `b` | number | Angle in degrees. |

```lua
-- How far off the crosshair is the enemy's head?
local cam, ang = utils.get_camera_pos(), utils.get_camera_angles()
local enemy = utils.find_nearest_fov_enemy()
local head = enemy and enemy:get_bone_pos("head")
local to_head = head and utils.calc_angle(cam, head)
if to_head then
    print(string.format("%.1f deg off (yaw %.1f)", utils.get_fov(ang, to_head), utils.angle_diff(to_head.yaw, ang.yaw)))
end
```

## Bullet prediction

### `utils.predict_bullet(src, dst, target_velocity, weapon [, shooter])`
Returns the point to aim at so that the weapon's bullet meets a target moving at `target_velocity`, as a `Vector`. It accounts for the weapon's bullet speed (with the shooter's bullet speed modifiers), bullet drop, and the weapon's vertical aim bias. The result is already raised for drop. Returns `nil` if `weapon` is not a valid weapon with bullet data.

| Name | Type | Description |
|---|---|---|
| `src` | Vector | Shot origin. |
| `dst` | Vector | The target point now. |
| `target_velocity` | Vector | The target's velocity (units per second). |
| `weapon` | ability | The weapon, e.g. `pawn:get_primary_weapon()`. |
| `shooter` | entity | Optional. Whose bullet speed modifiers apply. Defaults to the local pawn. |

Notes:
- Arguments that aren't Vectors count as (0, 0, 0).
- For a few weapons whose shots have no travel time, it returns `dst` unchanged.

```lua
callback.on_createmove:set(function(cmd)
    local lp = entity_list.local_pawn()
    local enemy = utils.find_nearest_visible_enemy()
    local weapon = lp and lp:get_primary_weapon()
    local from = lp and lp:get_fireport_position(false)
    local head = enemy and enemy:get_bone_pos("head")
    if not (weapon and from and head) then return end
    local vel = enemy.m_vecVelocity or Vector(0, 0, 0)
    local aim_point = utils.predict_bullet(from, head, vel, weapon)
    if aim_point then
        -- aim_point can go straight into cmd:aim({ aim_pos = aim_point, ... })
    end
end)
```

## VData

VData is the game's static data for abilities, items, heroes and other entity kinds. Lookups return a [raw_struct](entities.md#raw_struct): read its fields by schema name (`vdata.m_iItemTier`).

### `utils.subclass_id(name)`
Returns the subclass id (an integer) for a VData name such as `"upgrade_clip_size"`. The name is case-insensitive. Returns `nil` for an empty string.

### `utils.get_vdata_by_subclass(id [, kind])`
Looks up VData by subclass id. Returns two values: the VData (`raw_struct`) and its display name (the localized name if there is one, else the internal name). Returns `nil, nil` when nothing matches or `id` is 0.

| Name | Type | Description |
|---|---|---|
| `id` | integer | Subclass id, from `utils.subclass_id`. |
| `kind` | integer | Optional. `-1` (default) matches any kind; `4` only abilities and items. |

```lua
local id = utils.subclass_id("upgrade_clip_size")
local vdata, name = utils.get_vdata_by_subclass(id, 4)
if vdata then
    print(name .. ", tier " .. tostring(vdata.m_iItemTier))
end
```

### `utils.get_vdata_property(vdata, name)`
Returns an ability VData's property with the given name (case-insensitive), as a `raw_struct`, or `nil` if the VData has no such property.

| Name | Type | Description |
|---|---|---|
| `vdata` | raw_struct | Ability VData, from `utils.get_vdata_by_subclass` or `ability:get_vdata()`. |
| `name` | string | Property name, e.g. `"AbilityCooldown"`. |

This is the property's base data. For the value a hero actually has, use `get_scaled_ability_property`.

### `utils.get_scaled_ability_property(owner, ability_id, name)`
Returns an ability property's value (a number) with the owner's upgrades applied, or `nil` if the owner, the ability or the property is not found. It works for abilities the owner doesn't have equipped, such as items they haven't bought.

| Name | Type | Description |
|---|---|---|
| `owner` | entity | The hero pawn whose upgrades apply. |
| `ability_id` | integer | The ability's subclass id. |
| `name` | string | Property name, e.g. `"AbilityCooldown"`. One name per call. |

```lua
local lp = entity_list.local_pawn()
local id = utils.subclass_id("upgrade_warp_stone")
local cooldown = lp and utils.get_scaled_ability_property(lp, id, "AbilityCooldown")
```

## Slide

### `utils.get_slide_level()`
Returns the local pawn's slide level as an integer: 0 when not sliding. Returns -1 without a local pawn or slide ability.

### `utils.get_slide_angle()`
Returns the slide ability's current slope value (a number). Returns 0 without a local pawn or slide ability.

## Hitbox tests

These test a segment against an entity's hitboxes directly, with no world trace. They return `false` / `nil` for a dead or invalid entity.

### `utils.is_line_intersect_entity(start, end_, ent)`
Returns `true` if the segment from `start` to `end_` touches any of the entity's hitboxes.

| Name | Type | Description |
|---|---|---|
| `start` | Vector | Segment start. |
| `end_` | Vector | Segment end. |
| `ent` | entity | The entity to test. |

### `utils.get_line_intersection_entity(start, end_, ent)`
Same test. Returns the centre of the first hitbox the segment touches, as a `Vector`, or `nil`. This is not the point where the segment enters the hitbox.

### `utils.is_hull_intersect_entity(start, end_, hull_radius, ent [, ent_origin_offset])`
Returns `true` if a sphere of radius `hull_radius` swept from `start` to `end_` touches any of the entity's hitboxes. Use `ent_origin_offset` to test against where the entity will be (for example its velocity times the travel time).

| Name | Type | Description |
|---|---|---|
| `start` | Vector | Sweep start. |
| `end_` | Vector | Sweep end. |
| `hull_radius` | number | Radius of the swept sphere. |
| `ent` | entity | The entity to test. |
| `ent_origin_offset` | Vector | Optional. Offset added to the entity's hitboxes. Default (0, 0, 0). |

```lua
-- Would a 20-unit projectile from the camera, straight ahead for 1500 units, touch the enemy?
local cam, ang = utils.get_camera_pos(), utils.get_camera_angles()
local enemy = utils.find_nearest_fov_enemy()
if enemy then
    local fwd = ang:GetForward()
    local hit = utils.is_hull_intersect_entity(cam, cam + fwd * 1500, 20, enemy, Vector(0, 0, 0))
end
```

## Minimap

Minimap positions passed to `minimap_percent_to_minimap` and `minimap_to_world` are `Vec2` values in 0..255 per axis across the map. The two screen conversions account for the minimap being rotated for one of the teams.

### `utils.is_minimap_visible()`
Returns `true` while the HUD minimap is shown.

### `utils.world_to_map(pos)`
Returns the screen position (`Vec2`, pixels) of the world position `pos` on the HUD minimap. Returns (0, 0) when the minimap is hidden. Use it in `on_draw` to draw markers on the minimap.

### `utils.minimap_percent_to_minimap(p)`
Returns the screen position (`Vec2`, pixels) on the HUD minimap of the minimap position `p` (0..255 per axis). Returns (0, 0) when there is no minimap panel.

### `utils.minimap_to_world(p)`
Returns the world position (`Vector`) of the minimap position `p` (0..255 per axis). Returns (0, 0, 0) when the map bounds are not known (for example outside a match).

```lua
local marker = nil
callback.on_frame:set(function()
    local enemy = utils.find_nearest_fov_enemy()
    marker = enemy and utils.is_minimap_visible() and utils.world_to_map(enemy:get_origin()) or nil
end)
-- In on_draw, draw a dot at `marker` (see the render page).
```

## Misc

### `utils.is_in_game_ui()`
Returns `true` while you are in a game (not in the main menu or loading).

### `utils.execute_command(command)`
Runs a console command, as if typed in the console. For example `utils.execute_command("say gg")`.

### `utils.reload_scripts()`
Reloads every script at the start of the next frame. It returns immediately; the calling script is reloaded too, so don't put it in a code path that runs on every load.
