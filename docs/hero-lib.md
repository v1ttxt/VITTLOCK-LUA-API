# HERO_LIB

`HERO_LIB` is a built-in library of hero helpers: status checks, ability state, casting, target selection, FOV and line-of-sight checks, movement and projectile prediction, spirit damage and lethality, and ready-made menu sections. It loads before your scripts, so it is available at the top level of every script with no `require`.

```lua
callback.on_createmove:set(function(cmd)
    local me = HERO_LIB.lp
    if not me or not HERO_LIB.is_lp_alive then return end
    local target = HERO_LIB.find_helper_target(cmd, me)
    if target and not HERO_LIB.is_unstoppable(target) then
        -- ...
    end
end)
```

A few rules:

- Pass a pawn where a function asks for `pawn` / `target`, and an ability where it asks for `ability`. Wrong arguments raise an error in your script; they never crash the game.
- Call the command helpers (`cast_ability`, `aim`, `find_*_target`, ...) from `on_createmove`, where `cmd` is valid.
- Distances are in game units unless the name says meters (`HERO_LIB.UNITS_TO_METERS` converts). Angles and FOVs are in degrees.
- `HERO_LIB` itself is shared by every script: read it, don't assign into it.
- The library also defines the global `ter(cond, a, b)`: `a` when `cond` is truthy, else `b`.

See [the editor stub](../library/hero_lib.lua) for autocomplete, and [examples/13-hero-lib-target-info.lua](../examples/13-hero-lib-target-info.lua) for a complete script.

- [State](#state)
- [Constants and data tables](#constants-and-data-tables)
- [Health and resources](#health-and-resources)
- [Status checks](#status-checks)
- [Abilities](#abilities)
- [Casting and input](#casting-and-input)
- [Heroes and NPCs](#heroes-and-npcs)
- [Positions, bones and FOV](#positions-bones-and-fov)
- [Visibility and traces](#visibility-and-traces)
- [Prediction](#prediction)
- [Damage](#damage)
- [Target selection](#target-selection)
- [Menu builders](#menu-builders)

## State

The library keeps these fields current from `on_createmove`, so they are set once you are in a match and a command has run. They are `nil` / `false` before that, in the main menu and while a map loads.

| Field | Type | Description |
|---|---|---|
| `HERO_LIB.lp` | `player_pawn\|nil` | Your pawn, refreshed every command. |
| `HERO_LIB.lp_hero_id` | `integer\|nil` | Your hero id (the same value as `HERO_LIB.get_hero_id(HERO_LIB.lp)`); 0 before you pick a hero. |
| `HERO_LIB.is_lp_valid` | `boolean\|nil` | `true` while `lp` exists. |
| `HERO_LIB.is_lp_alive` | `boolean\|nil` | `true` while `lp` is alive. |

## Constants and data tables

Read-only tables. Don't modify them: every script shares the same copy.

| Field | Type | Description |
|---|---|---|
| `HERO_LIB.UNITS_TO_METERS` | `number` | `0.0254`. Multiply game units by it to get meters; divide meters by it to get units. |
| `HERO_LIB.ON_HERO_INDICATOR_Z_OFFSET` | `number` | `65`. Height above the origin used by `get_on_hero_indicator_pos`. |
| `HERO_LIB.QUICKCAST_MODE` | `table` | Cast modes returned by `get_ability_cast_mode`: `DEFAULT = 0`, `INSTANT = 1`, `CONFIRM = 2`, `QUICK = 3`. |
| `HERO_LIB.ENUM_PPS_INFO_FROM` | `table` | Where prediction reads projectile speed from: `INVALID = 0`, `GUN = 1` (the hero's weapon), `PROJECTILE = 2` (the ability's projectile), `CUSTOM = 3` (the speed you pass). |
| `HERO_LIB.ENUM_PPS_AIM_TO_POS` | `table` | Which point of the target prediction aims at: `INVALID = 0`, `LIB_TARGET_POS = 1` (`get_target_pos`, the chest), `PAWN_ORIGIN = 2` (the feet), `CUSTOM = 3` (the position you pass). |
| `HERO_LIB.ENUM_MV_SIM_TYPE` | `table` | How movement is predicted: `INVALID = 0`, `SIMULATE_MOVEMENT = 1` (the game's own movement simulation), `SIMPLE_VEL_LOOP = 2` (straight-line velocity, used on ziplines). |
| `HERO_LIB.TROOPER_TYPE` | `table` | `RANGED = 1`, `MEDIC = 2`, `MELEE = 3`, `ZIPLINE_CONTAINER = 4`. Compare with `get_trooper_type`. |
| `HERO_LIB.NEUTRAL_TROOPER_TYPE` | `table` | `TIER1 = 1`, `TIER2 = 2`, `TIER3 = 3`. Compare with `get_neutral_trooper_type`. |
| `HERO_LIB.UNIT_TARGET_MASK` | `table` | Team masks for ability target searches: `FRIENDLY = 255`, `ENEMY = 65280`, `NEUTRAL = 65536`. |
| `HERO_LIB.NPC_KIND_CLASSES` | `table` | NPC kind -> list of class names: `trooper`, `neutral`, `guardian`, `walker`, `patron`, `base_guardian`, `shrine`, `midboss`. `get_npc_kind` does the reverse lookup. |
| `HERO_LIB.DISABLE_MODIFIER_STATES` | `EModifierState[]` | The modifier states that count as a hard disable (stun and similar), as used by `get_disable_remaining`. |
| `HERO_LIB.hero_abilities` | `table<string, string[]>` | Hero class name (`"hero_inferno"`, ...) -> its four signature ability names, in slot order. |
| `HERO_LIB.fix_hero_names` | `table<string, string>` | Hero class names whose public name differs (`hero_ghost` -> `"spectre"`, `hero_viper` -> `"kali"`, ...). |
| `HERO_LIB.all_active_items` | `table<string, HeroLibItem>` | Every active item by key (`KNOCKDOWN`, `WARP_STONE`, `METAL_SKIN`, `BLOOD_TRIBUTE`, ...): `{ name = "upgrade_...", category = "weapon"\|"vitality"\|"tech", image = "panorama/..." }`. |
| `HERO_LIB.passive_items` | `table<string, HeroLibItem>` | Passive items the library checks for (`ARCANE_SURGE`, `KINETIC_DASH`, `COUNTERSPELL`), same shape as `all_active_items`. |
| `HERO_LIB.whitelist_bones_only_head_body` | `table<string, boolean>` | Bone names of the head and torso (`head`, `spine_0` .. `spine_2`, plus the hero-specific variants). Use it to skip limbs. |

## Health and resources

### `HERO_LIB.get_health(ent)`

Current health (`m_iHealth`), or `nil` without an entity.

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `health` (integer or nil)

### `HERO_LIB.get_max_health(ent)`

Maximum health.

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `max_health` (integer or nil)

### `HERO_LIB.get_health_percent(ent)`

Health as 0-100.

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `percent` (number or nil)

### `HERO_LIB.get_barrier_health(target)`

Barrier (shield) health on top of normal health. For NPCs this includes damage-resistance shields. Never negative.

| Name | Type | |
|---|---|---|
| target | `entity` |  |

**Returns** `barrier` (number)

### `HERO_LIB.get_damageable_health(target, additional_health)`

Health + barrier + `additional_health`: what has to be dealt to kill the target.

| Name | Type | |
|---|---|---|
| target | `entity` |  |
| additional_health | `number` | optional |

**Returns** `health` (number or nil)

### `HERO_LIB.predict_health(target, delay, additional_health, include_barrier)`

Health after `delay` seconds of regeneration (capped at max health), optionally plus barrier and `additional_health`.

| Name | Type | |
|---|---|---|
| target | `entity` |  |
| delay | `number` | optional |
| additional_health | `number` | optional |
| include_barrier | `boolean` | optional |

**Returns** `health` (number or nil)

### `HERO_LIB.get_stamina(ent)`

Current stamina (dash charges); 0 when unknown.

| Name | Type | |
|---|---|---|
| ent | `player_pawn` |  |

**Returns** `stamina` (number)

### `HERO_LIB.get_max_stamina(ent)`

Maximum stamina; 0 when unknown.

| Name | Type | |
|---|---|---|
| ent | `player_pawn` |  |

**Returns** `max_stamina` (number)

### `HERO_LIB.get_clip_size(lp, tech_power)`

Bullets left in the clip and the full clip size with item bonuses (and spirit scaling, using `tech_power` or the hero's current spirit power).

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| tech_power | `number` | optional |

**Returns** `current` (integer), `max` (integer)

### `HERO_LIB.get_hero_id(ent)`

The hero id, 0 when unknown.

| Name | Type | |
|---|---|---|
| ent | `player_pawn` |  |

**Returns** `hero_id` (integer)

## Status checks

Each takes a pawn (hero or NPC) and returns `true` when the state applies.

### `HERO_LIB.is_stunned(pawn)`

Stunned.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_silenced(pawn)`

Silenced (including hidden silences).

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_sleeped(pawn)`

Asleep.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_unstoppable(pawn)`

Unstoppable (can't be stunned or moved). Note that heroes are unstoppable in their spawn area.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_immune_to_stun(pawn)`

Unstoppable or knockdown-immune.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_invulnerable(pawn)`

Invulnerable or taking no incoming damage.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_tech_invulnerable(pawn)`

Immune to spirit damage.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_unkillable(pawn)`

Can't drop below 1 health.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_out_of_game(pawn)`

Removed from play (inside an ability, transitioning...).

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_untargetable(pawn)`

Not visible to you, untargetable by enemies, or in Ethereal Shift.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_inactive_target(pawn)`

Not worth targeting right now: cubed, in stone form, out of game, invulnerable, or in a tornado.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_combat_abilities_disabled(pawn)`

Combat abilities disabled.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_command_restricted(pawn)`

Commands restricted.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.has_no_outgoing_damage(pawn)`

Deals no damage.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.avoids_spells(pawn)`

Has a spell-avoid effect active (the next spirit ability is blocked).

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_ground_dashing(pawn)`

Ground dash.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_air_dashing(pawn)`

Air dash.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_any_dashing(pawn)`

Ground or air dash.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_on_zipline(pawn)`

Riding a zipline.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_climbing_rope(pawn)`

Climbing a rope.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_on_ground(ent)`

Standing on the ground (the on-ground movement flag).

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_in_viscous_cube(pawn)`

Inside a Viscous cube.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_in_ivy_stone_form(pawn)`

In Ivy's stone form.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_ivy_stone_form(pawn)`

Same as `is_in_ivy_stone_form`.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_in_mirage_tornado(pawn)`

Inside Mirage's tornado.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_in_ethereal_shift(pawn)`

In Ethereal Shift.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_using_blood_tribute(pawn)`

Blood Tribute is toggled on.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_casting_haze_ult(pawn)`

Haze's ultimate is active.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_casting_kelvin_third(pawn)`

Kelvin's ice beam is active.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_casting_krill_ult(pawn)`

Mo & Krill's ultimate is active.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_casting_seven_ult(pawn)`

Seven's storm cloud is active.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_an_attach_familiar_itself(pawn)`

This pawn is an attached familiar.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.can_attach_familiar_to(pawn)`

A familiar can attach to this hero now (alive, active, not locked out).

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_rift_buffed(ent)`

A trooper carrying the rift buff.

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.can_be_lasthitted(pawn, allow_victor_ult)`

The hero can be killed now: not out of game, invulnerable, unkillable or invisible. With `allow_victor_ult`, an unkillable hero whose revive ultimate is ready still counts.

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |
| allow_victor_ult | `boolean` | optional |

**Returns** `boolean`

## Abilities

Your own abilities are real `ability` entities. The game doesn't send other heroes' ability entities, so for them `get_ability`, `get_abilities` and `get_ability_by_slot` return stand-in objects (`ability.is_fake == true`) built from the hero's ability list. Stand-ins answer `get_name`, `get_vdata`, `get_property`, `get_scaled_property` (base values), `get_cast_range` and `get_aoe_radius`; their other methods return `nil`.

### `HERO_LIB.get_abilities(pawn)`

Every ability of the hero (stand-ins for other heroes).

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |

**Returns** `abilities` (ability[])

### `HERO_LIB.get_ability(pawn, name)`

An ability or item by name (`"citadel_ability_..."`, `"upgrade_..."`).

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |
| name | `string` |  |

**Returns** `ability` (ability or nil)

### `HERO_LIB.get_ability_by_slot(pawn, slot)`

The ability in a slot.

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |
| slot | `EAbilitySlots_t` |  |

**Returns** `ability` (ability or nil)

### `HERO_LIB.has_ability(pawn, ability_name)`

The hero has this ability or item.

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |
| ability_name | `string` |  |

**Returns** `boolean`

### `HERO_LIB.get_fake_ability(pawn, name, slot)`

The stand-in ability object for `name`, created on first use and cached per hero.

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |
| name | `string` |  |
| slot | `EAbilitySlots_t` | optional |

**Returns** `ability` (ability or nil)

### `HERO_LIB.get_modifier_ability(modifier, name)`

The ability that created a modifier: the real one when you cast it, otherwise a stand-in when the modifier came from the ability called `name`.

| Name | Type | |
|---|---|---|
| modifier | `modifier` |  |
| name | `string` |  |

**Returns** `ability` (ability or nil)

### `HERO_LIB.get_level(ab)`

`ability:get_level() - 1`.

| Name | Type | |
|---|---|---|
| ab | `ability` |  |

**Returns** `level` (integer or nil)

### `HERO_LIB.is_ability_ready(ability, allow_casting, additional_allowed_states)`

The ability can be cast now (the game's own check, plus cooldown and charges). With `allow_casting`, an ability already in its cast delay also counts (and the second value is `true`). `additional_allowed_states` lists extra `can_be_executed` results to accept.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |
| allow_casting | `boolean` | optional |
| additional_allowed_states | `integer[]` | optional |

**Returns** `ready` (boolean), `casting` (boolean or nil)

### `HERO_LIB.is_ability_in_cd(ability, force_chargeable)`

On cooldown or out of charges. `nil` for stand-ins or abilities without charge data.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |
| force_chargeable | `boolean` | optional |

**Returns** `boolean or nil`

### `HERO_LIB.is_ability_in_cast_delay(ability, no_start_offset, custom_cast_delay, custom_cast_delay_start_time)`

The ability is inside its cast delay (wind-up) right now. Pass your own delay or start time to override the ability's.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |
| no_start_offset | `boolean` | optional |
| custom_cast_delay | `number` | optional |
| custom_cast_delay_start_time | `number` | optional |

**Returns** `boolean or nil`

### `HERO_LIB.get_cast_delay_fraction(ability)`

How far through its cast delay the ability is (0..1+). 0 when not casting, `false` when the ability has no cast delay.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `fraction` (number or false)

### `HERO_LIB.is_ability_in_self_cast_delay(ability)`

The alt-cast (self-cast) hold or double-tap window is still open, using your alt-cast settings.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `boolean`

### `HERO_LIB.get_ability_self_cast_delay(ability)`

The alt-cast hold time or double-tap window from your settings.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `seconds` (number)

### `HERO_LIB.is_channeling_ability(ability)`

The ability is channeling. Pass an ability, not a pawn.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `boolean`

### `HERO_LIB.is_channeling_any_ability(lp, exceptions)`

Any of the hero's abilities is channeling, except the ones used as keys in `exceptions`.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| exceptions | `table<ability, boolean>` | optional |

**Returns** `boolean`

### `HERO_LIB.is_channeling_specific_abilities(lp, ability_names)`

One of the named abilities is channeling.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| ability_names | `string[]` |  |

**Returns** `boolean`

### `HERO_LIB.is_ability_selected(lp, ability)`

The ability is selected (being aimed, waiting for confirm).

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| ability | `ability` |  |

**Returns** `boolean`

### `HERO_LIB.get_ability_cast_mode(ability)`

Your cast mode setting for the ability's slot, a `QUICKCAST_MODE` value.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `mode` (integer or nil)

### `HERO_LIB.get_ability_default_cast_mode(ability)`

The cast mode the ability's activation type implies, a `QUICKCAST_MODE` value.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `mode` (integer or nil)

### `HERO_LIB.get_ability_input_mask(ability)`

The `InputBitMask_t` button that casts the ability's slot.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `mask` (integer or nil)

### `HERO_LIB.get_ability_icon(ability, custom_ability_name)`

The ability's icon path, ready for `Render.LoadImage`. Cached by name.

| Name | Type | |
|---|---|---|
| ability | `ability` | optional |
| custom_ability_name | `string` | optional |

**Returns** `path` (string or nil)

### `HERO_LIB.get_actual_prop_value(ability, prop_name)`

A property's value at the ability's current upgrade level.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |
| prop_name | `string` |  |

**Returns** `value` (number or nil)

### `HERO_LIB.get_cached_property_num(ability, prop_name)`

A property's base value as a number. Cached by ability and property name.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |
| prop_name | `string` |  |

**Returns** `value` (number or nil)

### `HERO_LIB.get_cached_property_values(ability, prop_name)`

A property's value at each upgrade level (index 1 = base). Cached.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |
| prop_name | `string` |  |

**Returns** `values` (number[] or nil)

### `HERO_LIB.get_cached_upgrades_num(ability)`

The ability's upgrade tiers as `{ [prop_name] = number }` tables. Cached.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `upgrades` (table[] or nil)

### `HERO_LIB.get_burst_qsr_chargeup_frac(ability)`

How far the ability's cooldown has recovered, 0..1.

| Name | Type | |
|---|---|---|
| ability | `ability` |  |

**Returns** `fraction` (number)

### `HERO_LIB.get_item_category_by_name(name)`

`"weapon"`, `"vitality"` or `"tech"` for an active item name.

| Name | Type | |
|---|---|---|
| name | `string` |  |

**Returns** `category` (string or nil)

## Casting and input

### `HERO_LIB.cast_ability(cmd, lp, ability, with_alt, with_attack, custom_ability_slot)`

Presses the ability's button the way your cast mode needs: one press for quick cast, press then attack for confirm cast (`with_attack`), and the alt-cast button with `with_alt`. Errors when the slot has no button.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| ability | `ability` |  |
| with_alt | `boolean` | optional |
| with_attack | `boolean` | optional |
| custom_ability_slot | `EAbilitySlots_t` | optional |

### `HERO_LIB.pulse_button(cmd, mask)`

A fresh press of `mask` that isn't repeated on the next tick, so the game sees one press. Returns `false` when it pressed the button on the tick just before.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| mask | `integer` |  |

**Returns** `pressed` (boolean)

### `HERO_LIB.block_item(cmd, item)`

Clears the item's button from the command so it doesn't cast.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| item | `ability` |  |

### `HERO_LIB.use_blood_tribute(cmd, lp, blood_tribute, value)`

Toggles Blood Tribute to `value` (on or off), with a short re-cast guard.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| blood_tribute | `ability` |  |
| value | `boolean` |  |

### `HERO_LIB.rotate_movement(cmd, lp, only_yaw, need_angle, need_dir, need_pos, block_movement, move_on, move_from)`

Rewrites the command's movement so you move toward an angle, a direction or a position (in that order of preference) whatever way the camera faces. `move_on` / `move_from` force moving toward / away; `block_movement` drops your other movement keys first. Returns `false` when nothing was given.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| only_yaw | `boolean` | optional |
| need_angle | `Angle` | optional |
| need_dir | `Vector` | optional |
| need_pos | `Vector` | optional |
| block_movement | `boolean` | optional |
| move_on | `boolean` | optional |
| move_from | `boolean` | optional |

**Returns** `boolean`

### `HERO_LIB.is_using_free_cursor(cmd)`

The cursor is free (a menu or the shop is open).

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |

**Returns** `boolean`

### `HERO_LIB.can_combo(lp, cmd, allow_cursor)`

`true` unless the cursor is free (or always, with `allow_cursor`).

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| cmd | `CUserCmd` |  |
| allow_cursor | `boolean` | optional |

**Returns** `boolean`

### `HERO_LIB.aim(cmd, options)`

`cmd:aim(options)` with smoothing compensation for moving targets, returning the `aim.status`. When the aim is accepted and `options.ability_ent` and `options.target_ent` are set, it also remembers the target as the ability's cast target, which `find_combo_target` / `find_helper_target` then return while the cast goes out.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| options | `AimOptions` |  |

**Returns** `status` (integer)

### `HERO_LIB.aim_status_consumes_combo(status)`

The aim status means the aim is busy this tick (`PENDING`, `AIMING`, `READY` or `BUSY`), so a combo shouldn't start something else.

| Name | Type | |
|---|---|---|
| status | `integer` |  |

**Returns** `boolean`

## Heroes and NPCs

### `HERO_LIB.is_hero_pawn(ent)`

The entity is a hero (`C_CitadelPlayerPawn`).

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_same_team(pawn1, pawn2)`

Both are on the same team. `nil` when one has no team.

| Name | Type | |
|---|---|---|
| pawn1 | `entity` |  |
| pawn2 | `entity` |  |

**Returns** `boolean or nil`

### `HERO_LIB.get_all_heroes(lp, allow_lp, allow_allies, allow_enemies, only_alive)`

Heroes filtered by relation to `lp`.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| allow_lp | `boolean` | optional |
| allow_allies | `boolean` | optional |
| allow_enemies | `boolean` | optional |
| only_alive | `boolean` | optional |

**Returns** `heroes` (player_pawn[])

### `HERO_LIB.get_all_heroes_with_ability(ability_name, lp, allow_lp, allow_allies, allow_enemies, only_alive)`

Heroes that have the ability, and the matching abilities (same order).

| Name | Type | |
|---|---|---|
| ability_name | `string` |  |
| lp | `player_pawn` |  |
| allow_lp | `boolean` | optional |
| allow_allies | `boolean` | optional |
| allow_enemies | `boolean` | optional |
| only_alive | `boolean` | optional |

**Returns** `heroes` (player_pawn[]), `abilities` (ability[] or nil)

### `HERO_LIB.get_all_heroes_with_modifier(modifier_id, lp, allow_lp, allow_allies, allow_enemies, only_alive)`

Heroes that have the modifier (`entity:has_modifier_by_id`).

| Name | Type | |
|---|---|---|
| modifier_id | `integer` |  |
| lp | `player_pawn` |  |
| allow_lp | `boolean` | optional |
| allow_allies | `boolean` | optional |
| allow_enemies | `boolean` | optional |
| only_alive | `boolean` | optional |

**Returns** `heroes` (player_pawn[])

### `HERO_LIB.get_heroes_in_radius(lp, pos, radius, allow_allies, allow_enemies, only_visible, check_active, with_time_predict, time)`

Living heroes (not `lp`) within `radius` units of `pos`. `check_active` skips inactive targets; `with_time_predict` uses each hero's predicted position `time` seconds ahead.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| pos | `Vector` |  |
| radius | `number` |  |
| allow_allies | `boolean` | optional |
| allow_enemies | `boolean` | optional |
| only_visible | `boolean` | optional |
| check_active | `boolean` | optional |
| with_time_predict | `boolean` | optional |
| time | `number` | optional |

**Returns** `heroes` (player_pawn[])

### `HERO_LIB.get_nearest_enemy(lp, pos, only_visible, with_time_predict, time, check_active, additional_filter_func)`

The closest living enemy hero to `pos`.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| pos | `Vector` |  |
| only_visible | `boolean` | optional |
| with_time_predict | `boolean` | optional |
| time | `number` | optional |
| check_active | `boolean` | optional |
| additional_filter_func | `fun(hero: player_pawn): boolean` | optional |

**Returns** `enemy` (player_pawn or nil)

### `HERO_LIB.get_npc_kind(ent)`

`"trooper"`, `"neutral"`, `"guardian"`, `"walker"`, `"patron"`, `"base_guardian"`, `"shrine"`, `"midboss"`, or `nil`.

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `kind` (string or nil)

### `HERO_LIB.get_trooper_type(ent)`

A lane trooper's `TROOPER_TYPE`.

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `type` (integer or nil)

### `HERO_LIB.get_neutral_trooper_type(ent)`

A neutral's `NEUTRAL_TROOPER_TYPE`.

| Name | Type | |
|---|---|---|
| ent | `entity` |  |

**Returns** `type` (integer or nil)

### `HERO_LIB.get_npc_shield_health(target)`

Damage-resistance shield health on an NPC.

| Name | Type | |
|---|---|---|
| target | `entity` |  |

**Returns** `shield` (number)

### `HERO_LIB.get_npc_damage_mitigation_percent(target)`

An objective's backdoor-protection damage mitigation from players.

| Name | Type | |
|---|---|---|
| target | `entity` |  |

**Returns** `percent` (number or nil)

### `HERO_LIB.has_any_particle(ent, particles)`

The entity has one of the particle systems (paths).

| Name | Type | |
|---|---|---|
| ent | `entity` |  |
| particles | `string[]` |  |

**Returns** `boolean`

## Positions, bones and FOV

### `HERO_LIB.get_target_pos(target)`

The point to aim at for a hero: the upper spine (with the hero-specific bone names handled), or the root while burrowed.

| Name | Type | |
|---|---|---|
| target | `entity` |  |

**Returns** `pos` (Vector or nil)

### `HERO_LIB.get_on_hero_indicator_pos(target)`

A point above the hero's origin for drawing indicators.

| Name | Type | |
|---|---|---|
| target | `entity` |  |

**Returns** `pos` (Vector or nil)

### `HERO_LIB.get_bone_positions(target, ignore_legs)`

Bone name -> world position for the bones worth aiming at. Handles burrow, hex and the other model swaps.

| Name | Type | |
|---|---|---|
| target | `entity` |  |
| ignore_legs | `boolean` | optional |

**Returns** `bones` (table<string, Vector>)

### `HERO_LIB.get_closest_bone_pos(target, custom_camera_pos)`

The bone closest to your crosshair.

| Name | Type | |
|---|---|---|
| target | `entity` |  |
| custom_camera_pos | `Vector` | optional |

**Returns** `pos` (Vector or nil)

### `HERO_LIB.get_fov_to_bones(bones, custom_camera_pos)`

The smallest angle (degrees) from your camera direction to any of the bones.

| Name | Type | |
|---|---|---|
| bones | `table<string, Vector>` |  |
| custom_camera_pos | `Vector` | optional |

**Returns** `fov` (number or nil)

### `HERO_LIB.get_fov_to_entity(camera_pos, target, only_yaw, cmd)`

The smallest angle from the camera to the target's bones. Uses the command's original camera angles when `cmd` is given.

| Name | Type | |
|---|---|---|
| camera_pos | `Vector` |  |
| target | `entity` |  |
| only_yaw | `boolean` | optional |
| cmd | `CUserCmd` | optional |

**Returns** `fov` (number)

### `HERO_LIB.get_fov_to_pos(camera_pos, pos, custom_camera_angles, only_yaw, cmd)`

The angle from the camera direction to a point.

| Name | Type | |
|---|---|---|
| camera_pos | `Vector` |  |
| pos | `Vector` |  |
| custom_camera_angles | `Angle` | optional |
| only_yaw | `boolean` | optional |
| cmd | `CUserCmd` | optional |

**Returns** `fov` (number)

### `HERO_LIB.is_pos_within_fov(camera_pos, pos, fov, custom_camera_angles, only_yaw, cmd)`

`get_fov_to_pos(...) <= fov`.

| Name | Type | |
|---|---|---|
| camera_pos | `Vector` |  |
| pos | `Vector` |  |
| fov | `number` |  |
| custom_camera_angles | `Angle` | optional |
| only_yaw | `boolean` | optional |
| cmd | `CUserCmd` | optional |

**Returns** `boolean`

### `HERO_LIB.is_target_within_fov(camera_pos, target, fov, only_yaw, cmd)`

`get_fov_to_entity(...) <= fov`.

| Name | Type | |
|---|---|---|
| camera_pos | `Vector` |  |
| target | `entity` |  |
| fov | `number` |  |
| only_yaw | `boolean` | optional |
| cmd | `CUserCmd` | optional |

**Returns** `boolean`

### `HERO_LIB.is_target_within_cone(lp, cmd, target_position, ability, angle_scale, from_lp_origin, with_pitch, use_half_width_method)`

The point is inside the ability's targeting cone, measured from the camera (or your origin with `from_lp_origin`), yaw only unless `with_pitch`.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` |  |
| cmd | `CUserCmd` |  |
| target_position | `Vector` |  |
| ability | `ability` |  |
| angle_scale | `number` | optional |
| from_lp_origin | `boolean` | optional |
| with_pitch | `boolean` | optional |
| use_half_width_method | `boolean` | optional |

**Returns** `inside` (boolean), `half_angle` (number)

### `HERO_LIB.is_within_wave_width(camera_pos, camera_forward, target_pos, wave_width)`

The point is within half of `wave_width` (meters) of the line from the camera along `camera_forward`.

| Name | Type | |
|---|---|---|
| camera_pos | `Vector` |  |
| camera_forward | `Vector` |  |
| target_pos | `Vector` |  |
| wave_width | `number` |  |

**Returns** `boolean`

### `HERO_LIB.closest_point_on_line(start_point, end_point, point)`

The point on the segment closest to `point`.

| Name | Type | |
|---|---|---|
| start_point | `Vector` |  |
| end_point | `Vector` |  |
| point | `Vector` |  |

**Returns** `closest` (Vector)

### `HERO_LIB.is_already_aiming(predicted_pos, cmd, threshold)`

The command's camera ray already passes within `threshold` units (default 1) of the point.

| Name | Type | |
|---|---|---|
| predicted_pos | `Vector` |  |
| cmd | `CUserCmd` |  |
| threshold | `number` | optional |

**Returns** `boolean`

## Visibility and traces

### `HERO_LIB.is_line_free(start_pos, end_pos, lp, target, allowed_fraction)`

Traces from `start_pos` to `end_pos`, ignoring your team. Free when the trace gets at least `allowed_fraction` (default 1) of the way, or hits `target`.

| Name | Type | |
|---|---|---|
| start_pos | `Vector` |  |
| end_pos | `Vector` |  |
| lp | `player_pawn` |  |
| target | `entity` | optional |
| allowed_fraction | `number` | optional |

**Returns** `free` (boolean), `fraction` (number or nil)

### `HERO_LIB.no_obs_to_pos(pos, custom_camera_pos, custom_lp, target, custom_allowed_fraction)`

`is_line_free` from your camera to a point.

| Name | Type | |
|---|---|---|
| pos | `Vector` |  |
| custom_camera_pos | `Vector` | optional |
| custom_lp | `player_pawn` | optional |
| target | `entity` | optional |
| custom_allowed_fraction | `number` | optional |

**Returns** `free` (boolean), `fraction` (number or nil)

### `HERO_LIB.no_obs_to_target(target, custom_camera_pos, custom_lp, custom_allowed_fraction)`

`is_line_free` from your camera to the target's `get_target_pos`.

| Name | Type | |
|---|---|---|
| target | `entity` |  |
| custom_camera_pos | `Vector` | optional |
| custom_lp | `player_pawn` | optional |
| custom_allowed_fraction | `number` | optional |

**Returns** `free` (boolean), `fraction` (number or nil)

### `HERO_LIB.hull_projectile_will_hit(local_pawn, camera_pos, target_pos, target, ability, ignore_team, custom_radius)`

A hull trace the size of the ability's projectile (or `custom_radius`) reaches the target.

| Name | Type | |
|---|---|---|
| local_pawn | `player_pawn` |  |
| camera_pos | `Vector` |  |
| target_pos | `Vector` |  |
| target | `entity` |  |
| ability | `ability` | optional |
| ignore_team | `boolean` | optional |
| custom_radius | `number` | optional |

**Returns** `boolean`

## Prediction

### `HERO_LIB.simulate_movement_for_duration(target, duration, additional_movement_slow, ground_only, need_debug, movement_path)`

Where the hero will be after `duration` seconds, using the game's movement simulation. `additional_movement_slow` (percent) slows the prediction; `ground_only` gives up on ziplines. The first return value is always `nil` (no debug path); `need_debug` and `movement_path` are accepted and ignored.

| Name | Type | |
|---|---|---|
| target | `player_pawn` |  |
| duration | `number` |  |
| additional_movement_slow | `number` | optional |
| ground_only | `boolean` | optional |
| need_debug | `boolean` | optional |
| movement_path | `Vector[]` | optional |

**Returns** `path` (nil), `predicted_pos` (Vector or nil), `predicted_velocity` (Vector or nil)

### `HERO_LIB.simulate_pawn_movement(pawn, sim_type, callback)`

Runs a movement simulation (`ENUM_MV_SIM_TYPE`) and calls `callback` with the move data of every simulated tick; return a falsy value from it to stop. Returns `false` when the simulation couldn't run.

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |
| sim_type | `integer` |  |
| callback | `fun(mv: move_data_t): boolean` |  |

**Returns** `boolean`

### `HERO_LIB.predict_projectile(info_from, cast_point, target_pos, target_velocity, ability, ignore_z, custom_proj_speed)`

Solves a projectile intercept for a target moving in a straight line, including gravity, up speed and aim bias. `info_from` is an `ENUM_PPS_INFO_FROM` value. `aim_pos` is where to aim, `predicted_pos` where the target will be.

| Name | Type | |
|---|---|---|
| info_from | `integer` |  |
| cast_point | `Vector` |  |
| target_pos | `Vector` |  |
| target_velocity | `Vector` |  |
| ability | `ability` |  |
| ignore_z | `boolean` | optional |
| custom_proj_speed | `number` | optional |

**Returns** `aim_pos` (Vector or nil), `predicted_pos` (Vector or nil), `travel_time` (number or nil)

### `HERO_LIB.predict_projectile_simulated(need_debug, info_from, sim_type, aim_to_pos, target, ability, custom_lp, custom_proj_speed, custom_max_range, use_camera_cast, aim_type_bits, cmd, custom_target_pos, custom_cast_point, ignore_z, movement_path)`

The full projectile prediction: simulates the target's movement (`sim_type`) tick by tick and finds the tick the projectile meets it, within the ability's range (or `custom_max_range`). `aim_to_pos` picks the target point (`ENUM_PPS_AIM_TO_POS`). Pass your `aim.type` bits and the command to account for magic-bullet aim: `mb_only` / `mb_foot` then tell you the shot only works with magic bullets / aimed at the feet. `aim_pos` is `nil` when there is no solution. Debug output is always off.

| Name | Type | |
|---|---|---|
| need_debug | `boolean\|nil` |  |
| info_from | `integer` |  |
| sim_type | `integer` |  |
| aim_to_pos | `integer` |  |
| target | `player_pawn` |  |
| ability | `ability` |  |
| custom_lp | `player_pawn` | optional |
| custom_proj_speed | `number` | optional |
| custom_max_range | `number` | optional |
| use_camera_cast | `boolean` | optional |
| aim_type_bits | `integer` | optional |
| cmd | `CUserCmd` | optional |
| custom_target_pos | `Vector` | optional |
| custom_cast_point | `Vector` | optional |
| ignore_z | `boolean` | optional |
| movement_path | `Vector[]` | optional |

**Returns** `aim_pos` (Vector or nil), `predicted_pos` (Vector or nil), `simulated_origins` (nil), `simulated_projectiles` (nil), `mb_only` (boolean or nil), `mb_foot` (boolean or nil)

### `HERO_LIB.predict_ground_cast_simulated(need_debug, info_from, target, ability, custom_lp, aim_type_bits, cmd, activation_delay, ground_offset)`

Like `predict_projectile_simulated` for abilities cast on the ground under the target (with a cast delay of `activation_delay`).

| Name | Type | |
|---|---|---|
| need_debug | `boolean\|nil` |  |
| info_from | `integer` |  |
| target | `player_pawn` |  |
| ability | `ability` |  |
| custom_lp | `player_pawn` | optional |
| aim_type_bits | `integer` | optional |
| cmd | `CUserCmd` | optional |
| activation_delay | `number` | optional |
| ground_offset | `number` | optional |

**Returns** `aim_pos` (Vector or nil), `predicted_pos` (Vector or nil), `simulated_origins` (nil), `simulated_projectiles` (nil), `mb_only` (boolean or nil), `mb_foot` (boolean or nil)

### `HERO_LIB.get_predicted_cone_target(cmd, lp, ability, custom_angles, target_filter)`

The entity a cone ability would pick when cast now with the command's (or `custom_angles`) view: the one closest to the cone's centre, using the ability's own cone, range and line-of-sight rules.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| ability | `ability` |  |
| custom_angles | `Angle` | optional |
| target_filter | `fun(ent: entity): boolean` | optional |

**Returns** `target` (entity or nil)

### `HERO_LIB.project_ground_autocast_position(pawn, pos, ability)`

Drops a position to the ground under the pawn, for ground-targeted abilities.

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |
| pos | `Vector` |  |
| ability | `ability` |  |

**Returns** `ground` (Vector or nil)

### `HERO_LIB.get_ground_autocast_remaining(pawn, conditions)`

Seconds until the hero comes back from a state you can pre-cast a ground ability onto (revive, Rejuvenator respawn, hotel, void sphere, infinity slash, a stun), for the states enabled in `conditions` (the multiselect from `create_ground_autocast_settings`). `destination` is where the hero reappears when known.

| Name | Type | |
|---|---|---|
| pawn | `player_pawn` |  |
| conditions | `HeroLibWidget` |  |

**Returns** `remaining` (number), `active` (boolean), `destination` (Vector or nil)

### `HERO_LIB.get_disable_remaining(pawn, conditions)`

The longest remaining time of any `DISABLE_MODIFIER_STATES` state on the pawn. 0 when `conditions` doesn't have "Stun" enabled.

| Name | Type | |
|---|---|---|
| pawn | `entity` |  |
| conditions | `HeroLibWidget` | optional |

**Returns** `remaining` (number)

## Damage

Spirit damage is calculated in two steps: describe the attacker once, then each target. Pass a table as `reuse` to avoid allocating a new one each call.

### `HERO_LIB.prepare_damage_attacker(attacker, ability, reuse)`

The attacker's damage context: spirit power, outgoing damage bonuses, the ability's scaling and the items that add or amplify spirit damage.

| Name | Type | |
|---|---|---|
| attacker | `player_pawn` |  |
| ability | `ability` |  |
| reuse | `table` | optional |

**Returns** `context` (table)

### `HERO_LIB.prepare_damage_target(attacker_context, target, reuse)`

The damage context against one target: its health, barrier, spirit resist, damage reductions and amplifications, and whether damage is blocked (`context.blocked`).

| Name | Type | |
|---|---|---|
| attacker_context | `table` |  |
| target | `entity` |  |
| reuse | `table` | optional |

**Returns** `context` (table)

### `HERO_LIB.calculate_spirit_ability_damage(context, base_damage, item_trigger_damage, target_health_override)`

The damage `base_damage` of spirit damage deals to the target described by `context` (from `prepare_damage_target`), split into immediate and delayed (damage over time) parts.

| Name | Type | |
|---|---|---|
| context | `table` |  |
| base_damage | `number` |  |
| item_trigger_damage | `boolean` | optional |
| target_health_override | `number` | optional |

**Returns** `total` (number), `immediate` (number), `delayed` (number), `blocked` (boolean)

### `HERO_LIB.calculate_damage_lethality(context, total_damage, immediate_damage, execute_fraction, additional_health, health_override, damage_blocked, execute_after_damage)`

Whether the damage kills the target, including execute thresholds (`execute_fraction` of max health). `remaining` is the health left after the damage.

| Name | Type | |
|---|---|---|
| context | `table` |  |
| total_damage | `number` |  |
| immediate_damage | `number` |  |
| execute_fraction | `number` | optional |
| additional_health | `number` | optional |
| health_override | `number` | optional |
| damage_blocked | `boolean` | optional |
| execute_after_damage | `boolean` | optional |

**Returns** `lethal` (boolean or nil), `effective_health` (number), `remaining` (integer), `execute_lethal` (boolean), `lethal_capacity` (number), `unkillable` (boolean), `damage_delta` (number)

### `HERO_LIB.is_spirit_damage_blocked(attacker, target)`

Spirit damage from `attacker` won't land on `target` (invulnerable, spirit-immune, out of game, spell-avoid, an NPC's shield or phase).

| Name | Type | |
|---|---|---|
| attacker | `player_pawn` |  |
| target | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.is_npc_damage_blocked(attacker, target)`

An NPC or objective currently takes no damage (shield up, invulnerable phase, backdoor rules...).

| Name | Type | |
|---|---|---|
| attacker | `player_pawn` |  |
| target | `entity` |  |

**Returns** `boolean`

### `HERO_LIB.get_npc_spirit_resist(attacker, target)`

An NPC's spirit resist against `attacker`, including range-based resistance.

| Name | Type | |
|---|---|---|
| attacker | `player_pawn` |  |
| target | `entity` |  |

**Returns** `resist` (number)

### `HERO_LIB.get_npc_ability_damage_scale(target, ability)`

The damage multiplier abilities get against objectives (it grows with match time), 1 for other targets.

| Name | Type | |
|---|---|---|
| target | `entity` |  |
| ability | `ability` | optional |

**Returns** `scale` (number)

## Target selection

The settings live on **Heroes > Settings > General** under **Combo Target Selection** and **Helper Target Selection**. The page is created the first time a script calls one of these functions. A hero page can override them per hero. *Combo* is for full combos (with target lock), *helper* for single-ability helpers.

### `HERO_LIB.get_combo_fov(lp)`

Max FOV in degrees.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `fov` (number)

### `HERO_LIB.get_combo_distance(lp)`

Max distance in meters.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `meters` (number)

### `HERO_LIB.get_combo_priority(lp)`

1 Minimal FOV, 2 Minimal Distance, 3 Minimal Health Value, 4 Minimal Health Percent.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `priority` (integer)

### `HERO_LIB.get_combo_ignore(lp)`

Ignored states, any of `"Asleep"`, `"Invisible"`, `"Invulnerable"`, `"Unstoppable"`.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `states` (string[])

### `HERO_LIB.get_combo_lock_target(lp)`

Keep the combo target while it stays valid.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `boolean`

### `HERO_LIB.get_helper_fov(lp)`

Max FOV in degrees.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `fov` (number)

### `HERO_LIB.get_helper_distance(lp)`

Max distance in meters.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `meters` (number)

### `HERO_LIB.get_helper_priority(lp)`

Same values as `get_combo_priority`.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `priority` (integer)

### `HERO_LIB.get_helper_ignore(lp)`

Same values as `get_combo_ignore`.

| Name | Type | |
|---|---|---|
| lp | `player_pawn` | optional |

**Returns** `states` (string[])

### `HERO_LIB.find_target(cmd, lp, is_combo)`

`find_combo_target` when `is_combo`, else `find_helper_target`.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| is_combo | `boolean` | optional |

**Returns** `target` (player_pawn or nil)

### `HERO_LIB.find_combo_target(cmd, lp)`

The best enemy hero under the combo settings. With lock target on, the previous target is kept while it stays valid. While an `aim` cast is going out, returns its target.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |

**Returns** `target` (player_pawn or nil)

### `HERO_LIB.find_helper_target(cmd, lp)`

The best enemy hero under the helper settings. The result is cached for the command, so calling it several times per tick is cheap.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |

**Returns** `target` (player_pawn or nil)

### `HERO_LIB.clear_combo_target()`

Forgets the locked combo target.

## Menu builders

These build ready-made menu sections. `parent` is a menu group (`Menu.Create(...)`) or a widget returned by another builder. The widgets they return are `HeroLibWidget`s: call one to read it (`w()`), and use `w.ref` for the underlying menu widget.

### `HERO_LIB.create_item_multiselects(parent)`

An **Items** switch with an aim-type selector and three multiselects: AOE items, targeted items and non-targeted items. Pass the results to `handle_all_items`.

| Name | Type | |
|---|---|---|
| parent | `CMenuGroup\|HeroLibWidget` |  |

**Returns** `items_enabled` (HeroLibWidget), `items_aim` (HeroLibWidget), `aoe_widget` (HeroLibWidget), `target_widget` (HeroLibWidget), `non_target_widget` (HeroLibWidget)

### `HERO_LIB.handle_all_items(cmd, me, target, items_enabled, items_aim, aoe_widget, target_widget, non_target_widget, movement_path_factory)`

Casts the enabled items on `target`: targeted items first, then AOE items in range, then non-targeted ones. Returns `true` when it cast something.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| me | `player_pawn` |  |
| target | `player_pawn\|nil` |  |
| items_enabled | `HeroLibWidget` |  |
| items_aim | `HeroLibWidget` |  |
| aoe_widget | `HeroLibWidget` |  |
| target_widget | `HeroLibWidget` |  |
| non_target_widget | `HeroLibWidget` |  |
| movement_path_factory | `function` | optional |

**Returns** `used` (boolean)

### `HERO_LIB.handle_target_items(cmd, lp, target, items_multiselect, aim_settings, movement_path_factory)`

Casts the first ready targeted item that reaches the target, aiming with `aim_settings` (`items_aim()`).

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| target | `player_pawn` |  |
| items_multiselect | `HeroLibWidget` |  |
| aim_settings | `table` |  |
| movement_path_factory | `function` | optional |

**Returns** `used` (boolean)

### `HERO_LIB.handle_aoe_items(cmd, lp, target, items_multiselect)`

Casts ready AOE items whose radius covers the target.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| target | `player_pawn` |  |
| items_multiselect | `HeroLibWidget` |  |

**Returns** `used` (boolean)

### `HERO_LIB.handle_non_target_items(cmd, lp, target, items_multiselect)`

Casts ready non-targeted items.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| target | `player_pawn` |  |
| items_multiselect | `HeroLibWidget` |  |

**Returns** `used` (boolean)

### `HERO_LIB.create_auto_save_ui(parent, ability_name, image, allies_only, self_only)`

An **Auto** switch for a saving ability (heal, shield, cleanse) with its settings: targets (self / allies), max FOV, aim type, and health / health-loss triggers. Pass `settings` to `handle_auto_save`.

| Name | Type | |
|---|---|---|
| parent | `CMenuGroup\|HeroLibWidget` |  |
| ability_name | `string` |  |
| image | `string` | optional |
| allies_only | `boolean` | optional |
| self_only | `boolean` | optional |

**Returns** `enabled` (HeroLibWidget), `settings` (table)

### `HERO_LIB.handle_auto_save(cmd, lp, ability, state, settings)`

Casts the saving ability on yourself or an ally when a trigger from `settings` fires (health below a value or percent, or health lost within a time window). `state` is an empty table you keep per ability; the function stores its history there.

| Name | Type | |
|---|---|---|
| cmd | `CUserCmd` |  |
| lp | `player_pawn` |  |
| ability | `ability` |  |
| state | `table` |  |
| settings | `table` |  |

**Returns** `used` (boolean)

### `HERO_LIB.create_ground_autocast_settings(parent, include_yamato)`

A **Cast On** multiselect (stun, revive, Rejuvenator, hotel, void sphere, and infinity slash with `include_yamato`) and a **Post Invulnerability Buffer** slider in ticks. Use them with `get_ground_autocast_remaining`.

| Name | Type | |
|---|---|---|
| parent | `CMenuGroup\|HeroLibWidget` |  |
| include_yamato | `boolean` | optional |

**Returns** `conditions` (HeroLibWidget), `buffer` (HeroLibWidget)

### `HERO_LIB.apply_item_schema(widget, items)`

Sets each item's localized name as the tooltip of its row in a multiselect.

| Name | Type | |
|---|---|---|
| widget | `HeroLibWidget\|MenuWidget` |  |
| items | `table[]` |  |

### `HERO_LIB.construct_item_ui_element(item, value)`

`{ item.name, item.image, value }`, a multiselect row for an item.

| Name | Type | |
|---|---|---|
| item | `HeroLibItem` |  |
| value | `boolean` |  |

**Returns** `row` (table)

### `HERO_LIB.cache_get(key, producer)`

Returns the cached value for `key`, calling `producer` the first time. The cache is shared by every script and cleared on a full reload.

| Name | Type | |
|---|---|---|
| key | `string` |  |
| producer | `fun(): any` |  |

**Returns** `value` (any)
