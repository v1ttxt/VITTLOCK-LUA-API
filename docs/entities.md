# Entities

Everything in a match is an entity: hero pawns, player controllers, abilities, weapons, items, troopers, bosses, projectiles. This page covers how to find entities (`entity_list`), what you can do with them (`entity`, `player_pawn`, `ability`), the buffs and debuffs on them (`modifier`), movement prediction (`move_data_t`), and how to read any networked field by name (`raw_struct`).

- [How entity objects work](#how-entity-objects-work)
- [Reading fields by name](#reading-fields-by-name)
- [entity_list](#entity_list)
- [entity](#entity)
- [player_pawn](#player_pawn) (has every `entity` method)
- [ability](#ability) (has every `entity` method)
- [modifier](#modifier)
- [move_data_t](#move_data_t)
- [raw_struct, raw_ptr, CPanoramaImageName](#raw_struct)
- [Performance](#performance)

## How entity objects work

Every function that returns an entity gives you one of three types, chosen by the entity's class:

| Type | Used for | Methods |
|---|---|---|
| `player_pawn` | hero pawns (`C_CitadelPlayerPawn`) | all [`entity`](#entity) methods + [`player_pawn`](#player_pawn) methods |
| `ability` | abilities, weapons and items (anything derived from `C_CitadelBaseAbility`) | all [`entity`](#entity) methods + [`ability`](#ability) methods |
| `entity` | everything else (controllers, troopers, projectiles, ...) | [`entity`](#entity) methods |

A `player_pawn` does **not** have `ability` methods and vice versa. Player controllers are plain `entity` objects.

**Handles, not pointers.** An entity object stores the entity's handle (its index plus a serial number) and looks the entity up again on every call. It is therefore safe to keep entity objects across frames, in tables, or in upvalues. When the entity is destroyed (or its slot is reused by a different entity), the object becomes *stale*:

- `e:valid()` returns `false`.
- `get_index()` and `get_handle()` still return the stored values.
- Every other method returns its "nothing" value: `nil`, `""`, `0`, `false` or an empty table. `is_dormant()` returns `true`.
- Field reads return `nil`; field writes are ignored.

Nothing raises an error on a stale object, so check `valid()` (or the return value) before relying on a result.

**Comparing entities.** `a == b` is true when both objects refer to the same handle. Different objects for the same entity are different table keys, so key your own tables by `e:get_handle()`, not by the object.

**No custom data on entities.** Assigning a key that is not a schema field (`e.my_flag = true`) does nothing. Store per-entity data in your own table keyed by handle.

**`tostring(e)`** gives `"<class>(<index>)"`, e.g. `C_CitadelPlayerPawn(3)`.

**Where to call.** Do entity work in `on_frame`, `on_createmove` or the entity/modifier [callbacks](callbacks.md). In `on_draw`, draw values (positions, numbers) you collected there.

```lua
-- Keep enemy heroes across frames; drop the ones that went away.
local tracked = {}   -- handle -> player_pawn

callback.on_frame:set(function()
    for _, pawn in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn")) do
        tracked[pawn:get_handle()] = pawn
    end
    for handle, pawn in pairs(tracked) do
        if not pawn:valid() then tracked[handle] = nil end
    end
end)
```

## Reading fields by name

Index any entity, modifier or `raw_struct` with a field name to read that field from the game:

```lua
local me = entity_list.local_pawn()
if me then
    print(me.m_iHealth, me.m_iTeamNum, me.m_lifeState)
end
```

- **Names follow the game's schema.** A name works when it is a field of the object's class or any of its base classes. A hero pawn (`C_CitadelPlayerPawn`) has its own fields plus those of `C_BaseEntity`, `C_BaseModelEntity` and the rest of its chain. Use `e:get_class_name()` to see an object's class. Names are case-sensitive and almost all start with `m_`.
- **A field the class doesn't have reads `nil`.** That makes `e.m_SomeField or fallback` a safe pattern.
- **Methods come first.** When a name is both a method and a field, you get the method. Field names start with `m_`, so in practice this never clashes.

What comes back depends on the field's type:

| Field type | Lua value |
|---|---|
| `bool` | boolean |
| 8/16/32/64-bit integers, tick counts, entity indices, string tokens | integer (64-bit values are signed) |
| `float32`, `float64`, `GameTime_t` | number (`GameTime_t` is the game time in seconds) |
| `Vector`, `VectorWS` | [`Vector`](types.md) |
| `QAngle` | [`Angle`](types.md) |
| `Vector2D` | [`Vec2`](types.md) |
| `Color` | [`Color`](types.md) |
| `CHandle<...>` | integer handle; pass it to `entity_list.by_handle` |
| strings (`CUtlString`, `CUtlSymbolLarge`, `char*`, `char[N]`) | string |
| enums | integer (compare with the game enum globals, see [enums](enums.md)) |
| an embedded schema struct | [`raw_struct`](#raw_struct) over that part of the object |
| a pointer to a schema class | [`raw_struct`](#raw_struct) of the object it points at (its real class), or `nil` when null |
| `CPanoramaImageName` | [`CPanoramaImageName`](#cpanoramaimagename) |
| anything else (vectors/lists, maps, fixed arrays other than `char[N]`, unknown types) | `nil` |

Handle fields that point at nothing hold `4294967295` (`0xFFFFFFFF`); `entity_list.by_handle` returns `nil` for them.

Structs and pointers chain naturally:

```lua
local me = entity_list.local_pawn()
if me then
    local node = me.m_pGameSceneNode               -- pointer -> raw_struct
    print(node and node.m_vecAbsOrigin)            -- Vector
    local box = me.m_pCollision
    print(box and box.m_vecMins, box and box.m_vecMaxs)
    local comp = me.m_CCitadelAbilityComponent     -- embedded struct -> raw_struct
    local selected = comp and entity_list.by_handle(comp.m_hSelectedAbility)
    print(selected and selected:get_name())
end
```

**Writing fields.** Assigning to a field writes the value into the game's memory on your client only; the server never sees it, and networked fields are overwritten by the next update. Supported: booleans and numbers into bool / integer / float / enum / handle fields (numbers are truncated to the field's type; `true`/`false` become 1/0), and `Vector`, `Angle`, `Vec2`, `Color` into fields of the same type. Anything else (strings, structs, unknown fields, `nil`) is silently ignored.

---

## entity_list

Global table for finding entities. Every function returns fresh objects; see [How entity objects work](#how-entity-objects-work).

### `entity_list.team_filter`

Values for the `team` argument of `by_class_name`:

| Name | Value | Keeps |
|---|---|---|
| `enemy` | 0 | entities whose `m_iTeamNum` differs from yours (this includes neutral entities) |
| `friend` | 1 | entities on your team, your own pawn included |
| `both` | 2 | everything |

When you have no local pawn, the filter is ignored and all teams are returned.

### `entity_list.local_pawn()`

Your hero pawn as a `player_pawn`, or `nil` when you have none (main menu, loading, before you pick a hero).

### `entity_list.local_controller()`

Your player controller as an `entity`, or `nil`.

### `entity_list.by_class_name(class_name [, team])`

Every entity whose schema class is exactly `class_name`.

| Name | Type | Description |
|---|---|---|
| `class_name` | string | Exact, case-sensitive class name, e.g. `"C_CitadelPlayerPawn"`, `"C_NPC_Trooper"`. Subclasses do not match. |
| `team` | integer, optional | An `entity_list.team_filter` value. All teams when omitted. |

Returns an array (possibly empty).

Notes:
- `by_class_name("C_CitadelPlayerPawn")` without `team` is served from a tracked hero list and is cheap. It can contain dead heroes; check `is_alive()`.
- Every other call (other classes, or any `team` argument) scans every entity slot. Call it once per frame and reuse the result.

```lua
callback.on_frame:set(function()
    local me = entity_list.local_pawn()
    if not me then return end
    local my_pos = me:get_origin()
    for _, enemy in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        if enemy:is_alive() and not enemy:is_dormant() then
            local pos = enemy:get_origin()
            if my_pos and pos then
                print(enemy:get_name(), math.floor(my_pos:Distance(pos)))
            end
        end
    end
end)
```

### `entity_list.get_all()`

Every entity in the game, all classes and teams, as an array. Scans every entity slot; avoid calling it more than once per frame.

### `entity_list.by_index(index)`

The entity currently in slot `index` (0 to 32767), or `nil` when the slot is empty or out of range. The slot may hold a different entity later; prefer handles for keeping track of one entity.

### `entity_list.by_handle(handle)`

The entity a handle refers to, or `nil` when the handle is invalid, not a number, or the entity is gone. Use it with `e:get_handle()` and with handle fields such as `m_hOwnerEntity` or a modifier's `m_hCaster`.

---

## entity

Methods every entity object has, including `player_pawn` and `ability` objects. "Gone" below means the object is stale (see [How entity objects work](#how-entity-objects-work)).

### Identity

#### `e:valid()`

`true` while the stored handle still refers to this entity.

#### `e:get_index()`

The entity's index (slot number). Works on stale objects.

#### `e:get_handle()`

The entity's handle as an integer. Works on stale objects. Use it as a table key and with `entity_list.by_handle`.

#### `e:get_class_name()`

The schema class name, e.g. `"C_CitadelPlayerPawn"`, `"C_CitadelPlayerController"`. `""` when gone.

#### `e:get_name()`

- Hero pawns: the internal hero name, e.g. `"hero_atlas"`.
- Everything else: the entity's designer name. For abilities, weapons and items this is the ability name (`"citadel_weapon_..."`, `"upgrade_..."`), which you can pass to [`player_pawn:get_ability`](#pawnget_abilityname).

`""` when gone or unknown.

#### `e:get_address()`

The entity's address as a hex string (`"0x0"` when gone). Only useful for debugging or telling entities apart in logs.

### Position and state

#### `e:get_origin()`

World position (`Vector`), or `nil` when unavailable.

#### `e:get_velocity()`

Networked velocity (`Vector`), or `nil` when unavailable.

#### `e:get_angles()`

World rotation (`Angle`), or `nil`. For heroes this is the body rotation, not where the player is looking.

#### `e:is_alive()`

`true` when the entity exists and its life state is alive. `false` when gone.

#### `e:is_dormant()`

`true` when the server isn't currently sending updates for the entity (out of view or far away), or when it is gone. Positions and fields of a dormant entity are stale.

#### `e:get_max_health()`

Max health as an integer; `0` when gone. There is no `get_health()`: read the field `e.m_iHealth`.

### Modifiers

Modifiers are the buffs, debuffs and effects on an entity. See [modifier](#modifier) for what you can do with one.

#### `e:get_modifiers()`

Every modifier on the entity, as an array of `modifier`. Empty when gone.

#### `e:get_modifier(name)`

The first matching modifier, or `nil`. `name` is either:

- a modifier class name, as `modifier:get_class_name()` returns it, e.g. `"CCitadel_Modifier_Stunned"` (exact match), or
- a modifier key `"<ability name>/<modifier name>"`, e.g. `"citadel_ability_melee_parry/modifier_citadel_parry"` (any name containing `/` is treated as a key; same as `get_modifier_by_id(utils.subclass_id(name))`).

#### `e:has_modifier(name)`

`true` when the entity has a matching modifier. `name` works as in `get_modifier`.

```lua
local enemy_parrying = enemy:has_modifier("citadel_ability_melee_parry/modifier_citadel_parry")
```

#### `e:get_modifier_by_id(id)` / `e:has_modifier_by_id(id)`

Find a modifier by its id. A modifier's id is the subclass id of its key, written as `"<ability name>/<modifier name>"`; compute it with [`utils.subclass_id`](utils.md). Returns the `modifier` (or `nil`) / a boolean.

#### `e:get_modifier_by_id_from(caster, id)`

The modifier with this id that a specific entity applied, or `nil`.

| Name | Type | Description |
|---|---|---|
| `caster` | entity or integer | The entity that applied the modifier, or its handle. |
| `id` | integer | Modifier id. |

#### `e:get_modifier_value(value_id [, default])`

The game's combined value of one modifier value type on the entity (for example gravity scale or a speed bonus), summed over all its modifiers.

| Name | Type | Description |
|---|---|---|
| `value_id` | integer | An `EModifierValue.*` value (see [enums](enums.md)). |
| `default` | number or boolean, optional | Returned when the entity has no modifier providing this value, or is gone. |

Returns a number. When `default` is a boolean, the result is a boolean too (`true` when the value is non-zero). Without `default`, the "none" case returns `nil`.

```lua
local me = entity_list.local_pawn()
if me then
    print("gravity scale", me:get_modifier_value(EModifierValue.MODIFIER_VALUE_GRAVITY_SCALE, 1))
end
```

#### `e:get_sum_modifier_value(value_id [, default])`

Same as `get_modifier_value`.

#### `e:has_modifier_state(state)`

`true` when any active modifier puts the entity in `state` (an `EModifierState.*` value), e.g. stunned, silenced, invulnerable.

#### `e:has_any_modifier_state(...)`

`true` when the entity is in at least one of the given states. Pass the states as separate arguments, not as a table; non-number arguments are ignored.

```lua
local function is_disabled(pawn)
    return pawn:has_any_modifier_state(
        EModifierState.MODIFIER_STATE_STUNNED,
        EModifierState.MODIFIER_STATE_SILENCED,
        EModifierState.MODIFIER_STATE_IMMOBILIZED)
end
```

#### `e:get_modifier_state_remaining_duration(state)`

Seconds left on the longest-lasting timed modifier that applies `state`. `0` when none (modifiers without a duration don't count).

#### `e:find_best_modifier_for_state(state)`

The modifier applying `state` with the most time left, or `nil`. A modifier without a duration counts as lasting forever and wins.

#### `e:find_best_modifiers_for_states(...)`

For each state given (separate arguments), the best modifier as in `find_best_modifier_for_state`. States that no modifier applies are **skipped**, so the result's positions don't line up with the arguments, and the same modifier can appear more than once.

### VData and model

#### `e:get_vdata()`

The entity's VData (its static class data, the values from the game files) as a [`raw_struct`](#raw_struct), or `nil` when it has none.
- Hero pawns: the hero's data (`CitadelHeroData_t`).
- Abilities, weapons, items: their ability VData (`CitadelAbilityVData` or a subclass), with fields such as `m_strAbilityImage`.

#### `e:get_vdata_class_name()`

The class name of `get_vdata()`; `""` when none.

#### `e:get_skeleton_instance()`

The entity's scene node (usually a `CSkeletonInstance`) as a `raw_struct`, or `nil`.

#### `e:get_model_state()`

The model state (`CModelState`) as a `raw_struct`, or `nil`.

#### `e:get_model_name()`

The model's path; `""` when none.

### Bones and attachments

#### `e:get_bone_pos(bone_name)`

World position of one bone (`Vector`), or `nil` when the model or the bone is missing. Bone names come from the model, e.g. `"head"`.

#### `e:get_bones()`

Every bone as a table `bone name -> Vector`. Empty when the entity has no model. Use it when you need several bones; for one, `get_bone_pos` is enough.

#### `e:get_min_fov_to_bones(camera_pos [, only_yaw])`

The smallest angle, in degrees, between your current view direction and the direction from `camera_pos` to any of the entity's bones. `180` when the entity has no bones.

| Name | Type | Description |
|---|---|---|
| `camera_pos` | Vector | Where to measure from, usually your camera position. |
| `only_yaw` | boolean, optional | Compare the horizontal angle only. Default `false`. |

#### `e:get_attachment(name)`

World position of a named model attachment (`Vector`), e.g. `"ability_cast"`, or `nil` when missing.

#### `e:get_fireport_position()`

The muzzle point of your weapon (`Vector`). Only works on your own pawn; returns `nil` for every other entity. Extra arguments are ignored.

#### `e:get_anims()`

Currently always returns an empty table.

### Particles

The entity's live particle effects, as sent by the server. Effects the client creates on its own are not listed.

#### `e:get_particles()`

An array of `{ name = string, control_points = { { cp = integer, origin = Vector }, ... } }`, ordered by creation. `control_points` holds the control points whose position is known.

#### `e:has_particle(path)`

`true` when the entity owns a live particle with this path. The match is exact but case-insensitive, and `".vpcf_c"` is treated the same as `".vpcf"`.

#### `e:get_particle_position(path)`

Position of the entity's particle with this path: control point 0 when known, else the lowest known one. `nil` when there is no such particle or no known position.

```lua
callback.on_frame:set(function()
    local me = entity_list.local_pawn()
    if not me then return end
    for _, p in ipairs(me:get_particles()) do
        local cp = p.control_points[1]
        print(p.name, cp and cp.origin)
    end
end)
```

See [callbacks](callbacks.md) for the `on_particle_*` events.

---

## player_pawn

A hero pawn. It has **every [entity](#entity) method** plus the methods below. Get one from `entity_list.local_pawn()`, `entity_list.by_class_name("C_CitadelPlayerPawn")`, or any function that returns a hero.

Ability entities are only sent to you for some heroes: your own abilities always, other players' often not (enemies in particular). For a pawn whose abilities didn't reach you, the ability methods return `nil` or an empty table.

### `pawn:get_abilities()`

Every ability, weapon and item entity of the pawn that reached your client, as an array of `ability`.

### `pawn:get_ability(name)`

The pawn's ability, weapon or item with this name, or `nil`. The name is the one `ability:get_name()` returns, e.g. `"upgrade_..."` for items.

```lua
local me = entity_list.local_pawn()
if me then
    for _, ab in ipairs(me:get_abilities()) do
        print(ab:get_name(), ab:get_level())
    end
    local weapon = me:get_primary_weapon()
    print(weapon and me:get_ability(weapon:get_name()) == weapon)   -- true
end
```

### `pawn:get_ability_by_id(id)`

The pawn's ability with this subclass id (`ability.m_nSubclassID`, or [`utils.subclass_id(name)`](utils.md)), or `nil`.

### `pawn:has_item_by_id(id)`

`true` / `false` whether the pawn has an ability or item with this subclass id. Returns `nil` (not `false`) when the pawn is gone.

### `pawn:get_primary_weapon()`

The primary weapon (`ability`), or `nil`.

### `pawn:get_ability_by_slot(slot)`

The ability in a slot (an `EAbilitySlots_t.*` value, e.g. `ESlot_Signature_1` to `ESlot_Signature_4`, `ESlot_ActiveItem_1`, `ESlot_Weapon_Melee`), or `nil`.

### `pawn:get_starting_stat(stat)`

The hero's base value for a stat (an `EStatsType.*` value, e.g. `EMaxHealth`, `EClipSize`) from its hero data. `0` when unknown.

### `pawn:get_scaling_stat(stat)`

The hero's scale factor for a stat from its hero data. `0` when the hero has none for that stat.

### `pawn:get_tech_resist()`

The pawn's spirit (tech) damage reduction stat as the game computes it. `0` when unavailable.

### `pawn:is_visible()`

`true` when the pawn is being updated for you (not dormant) and isn't invisible to your team.

### `pawn:simulate_movement(callback)`

Predicts where the pawn will be over the next ticks (up to 200) from its current movement: velocity, gravity, walls and ground. `callback` is called once per tick with a [`move_data_t`](#move_data_t), in order. Return `true` to get the next tick; any other return value (including nothing) stops. An error inside the callback also stops the simulation, without being reported.

```lua
-- Where will this enemy be in 16 ticks?
local function predict(pawn, ticks)
    local pos
    pawn:simulate_movement(function(mv)
        pos = mv:get_origin()
        return mv.tickcount < ticks
    end)
    return pos   -- nil when the pawn is gone
end
```

### `pawn:get_player_controller()`

The player controller (`entity`) of this pawn, or `nil`.

### `pawn:get_currency(currency)`

The pawn's amount of a currency (an `ECurrencyType.*` value, e.g. `EGold`, `EAbilityPoints`). `0` when out of range (valid: 0 to 5) or gone.

### `pawn:get_account_id()`

The player's Steam account id (the low 32 bits of their Steam id). `0` for bots or when unavailable.

### `pawn:get_map_district_id()`

The id of the map district the pawn is in. `0` when unavailable.

---

## ability

An ability, weapon or item entity. It has **every [entity](#entity) method** plus the methods below. Its schema fields include `m_eAbilitySlot`, `m_flCooldownEnd` and `m_nSubclassID`; its VData (`ab:get_vdata()`) holds the static values like `m_strAbilityImage`.

### `ab:get_cast_range()`

The cast range with upgrades and per-ability overrides applied. `0` when not learned or gone.

### `ab:get_aoe_radius()`

The ability's area radius (its `Radius` property). `0` when it has none.

### `ab:get_level()`

`0` not learned, `1` learned, then `+1` for each upgrade bought (up to `4`).

### `ab:get_cooldown()`

Seconds until the cooldown ends; `0` when ready. Charges are not taken into account.

### `ab:can_be_executed()`

The game's own answer to "can this be cast right now?" as an integer: `0` means ready; any other value is the reason it can't be cast (for example `2` cooldown, `10` busy with another action). See `Enum.AbilityExecuteState` in [enums](enums.md). Returns `-1` when the answer isn't available or the ability is gone.

```lua
local me = entity_list.local_pawn()
local ab = me and me:get_ability_by_slot(EAbilitySlots_t.ESlot_Signature_1)
if ab and ab:can_be_executed() == Enum.AbilityExecuteState.READY then
    print(ab:get_name() .. " is ready")
end
```

### `ab:get_weapon_info()`

For weapons, the weapon info (`CCitadelWeaponInfo`) as a `raw_struct` (bullet speed, spread, radius and so on). `nil` for abilities that aren't weapons.

### `ab:get_property(name)`

The raw property entry for `name` from the ability's VData (`CitadelAbilityProperty_t`, with fields such as `m_strValue`), or `nil`.

### `ab:get_scaled_property(name)`

The property's current value: base value plus bought upgrades plus the owner's stat scaling (spirit power and similar), as the game computes it. `nil` when the ability has no property named `name`.

```lua
local me = entity_list.local_pawn()
local ab = me and me:get_ability_by_slot(EAbilitySlots_t.ESlot_Signature_2)
if ab then
    print("cooldown", ab:get_scaled_property("AbilityCooldown"))
end
```

### `ab:get_upgrade(level)`

What one upgrade level changes, as a table `property name -> bonus` (the bonus is a string, as written in the game data). `level` is 1-based; `nil` past the last level.

### `ab:get_upgrades()`

Every upgrade level as an array of the tables `get_upgrade` returns. `nil` when the ability has no upgrade list.

### `ab:get_imbued_abilities()`

For items that are imbued on an ability: the subclass ids (integers) of the abilities they are imbued on. Empty otherwise.

### `ab:has_imbue_for(id)`

`true` when this item is imbued on the ability with subclass id `id`.

### `ab:get_target()`

For your own cone-targeted abilities: the unit the game would pick if you cast now along your current aim (a hero or an NPC), or `nil`. Always `nil` for abilities that aren't yours.

### `ab:find_entities_in_cone(team, start, direction, range, half_width [, half_angle [, owner [, los_check [, include_extra2d_cone]]]])`

Every living hero and NPC unit (troopers, neutral camps, guardians, walkers, patrons, the midboss) of one team inside a cone. The result doesn't depend on the ability you call it on.

| Name | Type | Description |
|---|---|---|
| `team` | integer | Team number to look for (`2` or `3`, see `Enum.TeamNum`). Not a `team_filter` value. |
| `start` | Vector | The cone's apex. |
| `direction` | Vector | The cone's axis; any length. A zero vector returns an empty table. |
| `range` | number | Maximum distance from `start`; `0` for no limit. |
| `half_width` | number | Also accept units within this distance of the axis (in front of `start`); `0` for none. |
| `half_angle` | number or Angle, optional | The cone's half angle in degrees (an `Angle` uses its yaw). `0` or omitted: only the `half_width` tube counts. |
| `owner` | entity, optional | An entity to leave out, usually yourself. |
| `los_check` | any, optional | Truthy (not `nil`, `false` or `0`): only units in line of sight from `start`. |
| `include_extra2d_cone` | any, optional | Truthy: also accept units inside the same angle measured flat on the ground. |

Heroes are tested at their body aim point, NPCs at the middle of their bounding box. Units within 1 unit of `start` are skipped. Returns an array of `player_pawn` / `entity`.

```lua
-- Enemies in a 30 degree cone in front of you, up to 2000 units.
local me = entity_list.local_pawn()
if me then
    local enemy_team = me.m_iTeamNum == 2 and 3 or 2
    local eye = me:get_origin() + Vector(0, 0, 64)
    local fwd = me:get_angles():GetForward()
    local any = me:get_primary_weapon()
    if any then
        for _, e in ipairs(any:find_entities_in_cone(enemy_team, eye, fwd, 2000, 0, 15, me, true)) do
            print(e:get_class_name(), e:get_name())
        end
    end
end
```

---

## modifier

A buff, debuff or effect on an entity, from `e:get_modifiers()`, `e:get_modifier(...)`, the `find_best_*` methods or the `on_add_modifier` [callback](callbacks.md).

A modifier object is re-checked on every use: it is valid while it is still on its target. Once it has been removed, every method returns its "nothing" value (`""`, `nil`, `0`) and field reads return `nil`. There is no `valid()` method; `m:get_class_name() ~= ""` tells you whether it is still there. `tostring(m)` gives `"modifier(<class>)"`, or `"modifier(stale)"`. Two modifier objects are `==` when they are the same modifier.

**Fields.** Index a modifier with field names, like an entity. The modifier's own class is searched first, then the common modifier fields, for example:

| Field | Value |
|---|---|
| `m_hCaster` | handle of the entity that applied it |
| `m_hAbility` | handle of the ability that applied it |
| `m_flCreationTime` | game time it was applied |
| `m_flDuration` | duration in seconds (`0` or less: no duration) |
| `m_bDisabled` | it is currently switched off |

### `m:get_class_name()`

The modifier's class name, e.g. `"CCitadel_Modifier_Stunned"`. This is the name `e:get_modifier` and `e:has_modifier` match against. `""` when removed.

### `m:get_name()`

Currently returns the same as `get_class_name()`.

### `m:get_vdata()`

The modifier's VData as a `raw_struct`, or `nil` when removed.

### `m:get_vdata_class_name()`

The class name of the modifier's VData; `""` when unknown or removed.

### `m:get_remaining_duration()`

Seconds left. `-1` for a modifier without a duration, `0` when it has expired or been removed.

### `m:get_ability()`

The ability that applied the modifier (`ability`, or another entity type), or `nil`.

```lua
callback.on_frame:set(function()
    local me = entity_list.local_pawn()
    if not me then return end
    for _, m in ipairs(me:get_modifiers()) do
        local caster = entity_list.by_handle(m.m_hCaster)
        print(m:get_class_name(), m:get_remaining_duration(), caster and caster:get_name())
    end
end)
```

---

## move_data_t

One predicted tick, passed to the callback of [`pawn:simulate_movement`](#pawnsimulate_movementcallback). Only valid during that callback call; copy the values you need.

| Member | Type | Description |
|---|---|---|
| `mv:get_origin()` | Vector | Predicted position at this tick. |
| `mv:get_velocity()` | Vector | Predicted velocity at this tick. |
| `mv.tickcount` | integer | Ticks from now: `1` for the next tick, then `2`, `3`, ... Read-only. |

---

<a id="raw_struct"></a>
## raw_struct, raw_ptr, CPanoramaImageName

### raw_struct

A view of a game object or struct whose schema class is known. You get one from a field read (embedded structs and pointers), from `get_vdata()`, `get_skeleton_instance()`, `get_model_state()`, `get_weapon_info()`, `get_property()`, and from other pages (for example `game_rules.get()` in [core](core.md)). Scripts can't create one.

Index it with field names exactly like an entity ([Reading fields by name](#reading-fields-by-name)); the field rules, return types and write rules are the same. `tostring(r)` gives the class name and address.

Unlike entity objects, a `raw_struct` holds a plain address and is **not** re-checked. Reading one after the object it views has been freed won't crash, but returns `nil` or garbage. Get it again from its owner each time instead of keeping it across frames.

```lua
local me = entity_list.local_pawn()
local weapon = me and me:get_primary_weapon()
local info = weapon and weapon:get_weapon_info()
if info then
    print("bullet radius vs world", info.m_flBulletRadiusVsWorld)
end
```

### raw_ptr

A raw address. The only thing it supports is `tostring`, which gives the address in hex.

### CPanoramaImageName

An image reference, returned when you read a field of that type (ability icons, for example `ab:get_vdata().m_strAbilityImage`).

| Method | Returns |
|---|---|
| `img:get_name()` | The path as the game stores it, e.g. `"file://{images}/hud/abilities/x.psd"`; `""` when empty. |
| `img:get_file_path()` | The compiled texture path, e.g. `"panorama/images/hud/abilities/x_psd.vtex_c"`, which [`Render.LoadImage`](render.md) accepts. |
| `img:is_empty()` | `true` when no image is set. |

`tostring(img)` is the same as `img:get_name()`.

```lua
-- Load the icon of your first ability once.
local icon
callback.on_frame:set(function()
    if icon then return end
    local me = entity_list.local_pawn()
    local ab = me and me:get_ability_by_slot(EAbilitySlots_t.ESlot_Signature_1)
    local vd = ab and ab:get_vdata()
    local img = vd and vd.m_strAbilityImage
    if img and not img:is_empty() then
        icon = Render.LoadImage(img:get_file_path())
    end
end)
```

---

## Performance

- **Entity objects are cheap to keep.** Store them in tables across frames and check `valid()`; there is no need to look heroes up again every frame.
- **Scans cost.** `entity_list.get_all()` and `entity_list.by_class_name(...)` (except heroes without a team filter) walk every entity slot. Call them once per frame (or less often) and reuse the table; never call them inside a loop over entities.
- **Every method call looks the entity up again.** In hot code, read a value once into a local instead of calling the same getter repeatedly.
- **Collect in `on_frame`, draw in `on_draw`.** Gather positions and values in `on_frame` and draw the stored values:

```lua
local marks = {}   -- world positions of enemy heads, refreshed every frame

callback.on_frame:set(function()
    marks = {}
    for _, e in ipairs(entity_list.by_class_name("C_CitadelPlayerPawn", entity_list.team_filter.enemy)) do
        if e:is_alive() and not e:is_dormant() then
            marks[#marks + 1] = { name = e:get_name(), pos = e:get_bone_pos("head") or e:get_origin() }
        end
    end
end)

callback.on_draw:set(function()
    for _, m in ipairs(marks) do
        if m.pos then
            local screen, on_screen = m.pos:ToScreen()
            if on_screen then
                Render.Text(0, 14, m.name, screen, Color(255, 80, 80, 255))
            end
        end
    end
end)
```
