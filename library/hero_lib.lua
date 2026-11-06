---@meta
-- HERO_LIB: the built-in hero helper library (loaded before every script).

---An item entry of `HERO_LIB.all_active_items` / `HERO_LIB.passive_items`.
---@class HeroLibItem
---@field name string Item ability name, e.g. "upgrade_target_stun".
---@field category "weapon"|"vitality"|"tech"
---@field image string Icon path for Render.LoadImage.

---A widget made by the HERO_LIB menu builders. Call it to read it:
---switch / slider / colour picker -> the value; combo -> 1-based index, or `w("Name")` -> selected;
---multiselect -> list of enabled names, or `w("Name")` -> enabled.
---@class HeroLibWidget
---@field ref MenuWidget The underlying menu widget.
---@overload fun(name?: string|integer): any

---`a` when `cond` is truthy, else `b`. Defined by HERO_LIB.
---@generic A, B
---@param cond any
---@param a A
---@param b B
---@return A|B
function ter(cond, a, b) end

---Built-in hero helpers. Available in every script without `require`.
---@class HERO_LIB
---@field lp player_pawn|nil Your pawn, refreshed every command.
---@field lp_hero_id integer|nil Your hero id (the same value as `HERO_LIB.get_hero_id(HERO_LIB.lp)`); 0 before you pick a hero.
---@field is_lp_valid boolean|nil `true` while `lp` exists.
---@field is_lp_alive boolean|nil `true` while `lp` is alive.
---@field UNITS_TO_METERS number `0.0254`. Multiply game units by it to get meters; divide meters by it to get units.
---@field ON_HERO_INDICATOR_Z_OFFSET number `65`. Height above the origin used by `get_on_hero_indicator_pos`.
---@field QUICKCAST_MODE table Cast modes returned by `get_ability_cast_mode`: `DEFAULT = 0`, `INSTANT = 1`, `CONFIRM = 2`, `QUICK = 3`.
---@field ENUM_PPS_INFO_FROM table Where prediction reads projectile speed from: `INVALID = 0`, `GUN = 1` (the hero's weapon), `PROJECTILE = 2` (the ability's projectile), `CUSTOM = 3` (the speed you pass).
---@field ENUM_PPS_AIM_TO_POS table Which point of the target prediction aims at: `INVALID = 0`, `LIB_TARGET_POS = 1` (`get_target_pos`, the chest), `PAWN_ORIGIN = 2` (the feet), `CUSTOM = 3` (the position you pass).
---@field ENUM_MV_SIM_TYPE table How movement is predicted: `INVALID = 0`, `SIMULATE_MOVEMENT = 1` (the game's own movement simulation), `SIMPLE_VEL_LOOP = 2` (straight-line velocity, used on ziplines).
---@field TROOPER_TYPE table `RANGED = 1`, `MEDIC = 2`, `MELEE = 3`, `ZIPLINE_CONTAINER = 4`. Compare with `get_trooper_type`.
---@field NEUTRAL_TROOPER_TYPE table `TIER1 = 1`, `TIER2 = 2`, `TIER3 = 3`. Compare with `get_neutral_trooper_type`.
---@field UNIT_TARGET_MASK table Team masks for ability target searches: `FRIENDLY = 255`, `ENEMY = 65280`, `NEUTRAL = 65536`.
---@field NPC_KIND_CLASSES table NPC kind -> list of class names: `trooper`, `neutral`, `guardian`, `walker`, `patron`, `base_guardian`, `shrine`, `midboss`. `get_npc_kind` does the reverse lookup.
---@field DISABLE_MODIFIER_STATES EModifierState[] The modifier states that count as a hard disable (stun and similar), as used by `get_disable_remaining`.
---@field hero_abilities table<string, string[]> Hero class name (`"hero_inferno"`, ...) -> its four signature ability names, in slot order.
---@field fix_hero_names table<string, string> Hero class names whose public name differs (`hero_ghost` -> `"spectre"`, `hero_viper` -> `"kali"`, ...).
---@field all_active_items table<string, HeroLibItem> Every active item by key (`KNOCKDOWN`, `WARP_STONE`, `METAL_SKIN`, `BLOOD_TRIBUTE`, ...): `{ name = "upgrade_...", category = "weapon"|"vitality"|"tech", image = "panorama/..." }`.
---@field passive_items table<string, HeroLibItem> Passive items the library checks for (`ARCANE_SURGE`, `KINETIC_DASH`, `COUNTERSPELL`), same shape as `all_active_items`.
---@field whitelist_bones_only_head_body table<string, boolean> Bone names of the head and torso (`head`, `spine_0` .. `spine_2`, plus the hero-specific variants). Use it to skip limbs.
HERO_LIB = {}

-- ── Health and resources ──────────────────────────────────────────────────────

---Current health (`m_iHealth`), or `nil` without an entity.
---@param ent entity
---@return integer|nil health
function HERO_LIB.get_health(ent) end

---Maximum health.
---@param ent entity
---@return integer|nil max_health
function HERO_LIB.get_max_health(ent) end

---Health as 0-100.
---@param ent entity
---@return number|nil percent
function HERO_LIB.get_health_percent(ent) end

---Barrier (shield) health on top of normal health. For NPCs this includes damage-resistance shields. Never negative.
---@param target entity
---@return number barrier
function HERO_LIB.get_barrier_health(target) end

---Health + barrier + `additional_health`: what has to be dealt to kill the target.
---@param target entity
---@param additional_health? number
---@return number|nil health
function HERO_LIB.get_damageable_health(target, additional_health) end

---Health after `delay` seconds of regeneration (capped at max health), optionally plus barrier and `additional_health`.
---@param target entity
---@param delay? number
---@param additional_health? number
---@param include_barrier? boolean
---@return number|nil health
function HERO_LIB.predict_health(target, delay, additional_health, include_barrier) end

---Current stamina (dash charges); 0 when unknown.
---@param ent player_pawn
---@return number stamina
function HERO_LIB.get_stamina(ent) end

---Maximum stamina; 0 when unknown.
---@param ent player_pawn
---@return number max_stamina
function HERO_LIB.get_max_stamina(ent) end

---Bullets left in the clip and the full clip size with item bonuses (and spirit scaling, using `tech_power` or the hero's current spirit power).
---@param lp player_pawn
---@param tech_power? number
---@return integer current
---@return integer max
function HERO_LIB.get_clip_size(lp, tech_power) end

---The hero id, 0 when unknown.
---@param ent player_pawn
---@return integer hero_id
function HERO_LIB.get_hero_id(ent) end

-- ── Status checks ─────────────────────────────────────────────────────────────

---Stunned.
---@param pawn entity
---@return boolean
function HERO_LIB.is_stunned(pawn) end

---Silenced (including hidden silences).
---@param pawn entity
---@return boolean
function HERO_LIB.is_silenced(pawn) end

---Asleep.
---@param pawn entity
---@return boolean
function HERO_LIB.is_sleeped(pawn) end

---Unstoppable (can't be stunned or moved). Note that heroes are unstoppable in their spawn area.
---@param pawn entity
---@return boolean
function HERO_LIB.is_unstoppable(pawn) end

---Unstoppable or knockdown-immune.
---@param pawn entity
---@return boolean
function HERO_LIB.is_immune_to_stun(pawn) end

---Invulnerable or taking no incoming damage.
---@param pawn entity
---@return boolean
function HERO_LIB.is_invulnerable(pawn) end

---Immune to spirit damage.
---@param pawn entity
---@return boolean
function HERO_LIB.is_tech_invulnerable(pawn) end

---Can't drop below 1 health.
---@param pawn entity
---@return boolean
function HERO_LIB.is_unkillable(pawn) end

---Removed from play (inside an ability, transitioning...).
---@param pawn entity
---@return boolean
function HERO_LIB.is_out_of_game(pawn) end

---Not visible to you, untargetable by enemies, or in Ethereal Shift.
---@param pawn entity
---@return boolean
function HERO_LIB.is_untargetable(pawn) end

---Not worth targeting right now: cubed, in stone form, out of game, invulnerable, or in a tornado.
---@param pawn entity
---@return boolean
function HERO_LIB.is_inactive_target(pawn) end

---Combat abilities disabled.
---@param pawn entity
---@return boolean
function HERO_LIB.is_combat_abilities_disabled(pawn) end

---Commands restricted.
---@param pawn entity
---@return boolean
function HERO_LIB.is_command_restricted(pawn) end

---Deals no damage.
---@param pawn entity
---@return boolean
function HERO_LIB.has_no_outgoing_damage(pawn) end

---Has a spell-avoid effect active (the next spirit ability is blocked).
---@param pawn entity
---@return boolean
function HERO_LIB.avoids_spells(pawn) end

---Ground dash.
---@param pawn entity
---@return boolean
function HERO_LIB.is_ground_dashing(pawn) end

---Air dash.
---@param pawn entity
---@return boolean
function HERO_LIB.is_air_dashing(pawn) end

---Ground or air dash.
---@param pawn entity
---@return boolean
function HERO_LIB.is_any_dashing(pawn) end

---Riding a zipline.
---@param pawn entity
---@return boolean
function HERO_LIB.is_on_zipline(pawn) end

---Climbing a rope.
---@param pawn entity
---@return boolean
function HERO_LIB.is_climbing_rope(pawn) end

---Standing on the ground (the on-ground movement flag).
---@param ent entity
---@return boolean
function HERO_LIB.is_on_ground(ent) end

---Inside a Viscous cube.
---@param pawn entity
---@return boolean
function HERO_LIB.is_in_viscous_cube(pawn) end

---In Ivy's stone form.
---@param pawn entity
---@return boolean
function HERO_LIB.is_in_ivy_stone_form(pawn) end

---Same as `is_in_ivy_stone_form`.
---@param pawn entity
---@return boolean
function HERO_LIB.is_ivy_stone_form(pawn) end

---Inside Mirage's tornado.
---@param pawn entity
---@return boolean
function HERO_LIB.is_in_mirage_tornado(pawn) end

---In Ethereal Shift.
---@param pawn entity
---@return boolean
function HERO_LIB.is_in_ethereal_shift(pawn) end

---Blood Tribute is toggled on.
---@param pawn entity
---@return boolean
function HERO_LIB.is_using_blood_tribute(pawn) end

---Haze's ultimate is active.
---@param pawn entity
---@return boolean
function HERO_LIB.is_casting_haze_ult(pawn) end

---Kelvin's ice beam is active.
---@param pawn entity
---@return boolean
function HERO_LIB.is_casting_kelvin_third(pawn) end

---Mo & Krill's ultimate is active.
---@param pawn entity
---@return boolean
function HERO_LIB.is_casting_krill_ult(pawn) end

---Seven's storm cloud is active.
---@param pawn entity
---@return boolean
function HERO_LIB.is_casting_seven_ult(pawn) end

---This pawn is an attached familiar.
---@param pawn entity
---@return boolean
function HERO_LIB.is_an_attach_familiar_itself(pawn) end

---A familiar can attach to this hero now (alive, active, not locked out).
---@param pawn entity
---@return boolean
function HERO_LIB.can_attach_familiar_to(pawn) end

---A trooper carrying the rift buff.
---@param ent entity
---@return boolean
function HERO_LIB.is_rift_buffed(ent) end

---The hero can be killed now: not out of game, invulnerable, unkillable or invisible. With `allow_victor_ult`, an unkillable hero whose revive ultimate is ready still counts.
---@param pawn player_pawn
---@param allow_victor_ult? boolean
---@return boolean
function HERO_LIB.can_be_lasthitted(pawn, allow_victor_ult) end

-- ── Abilities ─────────────────────────────────────────────────────────────────

---Every ability of the hero (stand-ins for other heroes).
---@param pawn player_pawn
---@return ability[] abilities
function HERO_LIB.get_abilities(pawn) end

---An ability or item by name (`"citadel_ability_..."`, `"upgrade_..."`).
---@param pawn player_pawn
---@param name string
---@return ability|nil ability
function HERO_LIB.get_ability(pawn, name) end

---The ability in a slot.
---@param pawn player_pawn
---@param slot EAbilitySlots_t
---@return ability|nil ability
function HERO_LIB.get_ability_by_slot(pawn, slot) end

---The hero has this ability or item.
---@param pawn player_pawn
---@param ability_name string
---@return boolean
function HERO_LIB.has_ability(pawn, ability_name) end

---The stand-in ability object for `name`, created on first use and cached per hero.
---@param pawn player_pawn
---@param name string
---@param slot? EAbilitySlots_t
---@return ability|nil ability
function HERO_LIB.get_fake_ability(pawn, name, slot) end

---The ability that created a modifier: the real one when you cast it, otherwise a stand-in when the modifier came from the ability called `name`.
---@param modifier modifier
---@param name string
---@return ability|nil ability
function HERO_LIB.get_modifier_ability(modifier, name) end

---`ability:get_level() - 1`.
---@param ab ability
---@return integer|nil level
function HERO_LIB.get_level(ab) end

---The ability can be cast now (the game's own check, plus cooldown and charges). With `allow_casting`, an ability already in its cast delay also counts (and the second value is `true`). `additional_allowed_states` lists extra `can_be_executed` results to accept.
---@param ability ability
---@param allow_casting? boolean
---@param additional_allowed_states? integer[]
---@return boolean ready
---@return boolean|nil casting
function HERO_LIB.is_ability_ready(ability, allow_casting, additional_allowed_states) end

---On cooldown or out of charges. `nil` for stand-ins or abilities without charge data.
---@param ability ability
---@param force_chargeable? boolean
---@return boolean|nil
function HERO_LIB.is_ability_in_cd(ability, force_chargeable) end

---The ability is inside its cast delay (wind-up) right now. Pass your own delay or start time to override the ability's.
---@param ability ability
---@param no_start_offset? boolean
---@param custom_cast_delay? number
---@param custom_cast_delay_start_time? number
---@return boolean|nil
function HERO_LIB.is_ability_in_cast_delay(ability, no_start_offset, custom_cast_delay, custom_cast_delay_start_time) end

---How far through its cast delay the ability is (0..1+). 0 when not casting, `false` when the ability has no cast delay.
---@param ability ability
---@return number|false fraction
function HERO_LIB.get_cast_delay_fraction(ability) end

---The alt-cast (self-cast) hold or double-tap window is still open, using your alt-cast settings.
---@param ability ability
---@return boolean
function HERO_LIB.is_ability_in_self_cast_delay(ability) end

---The alt-cast hold time or double-tap window from your settings.
---@param ability ability
---@return number seconds
function HERO_LIB.get_ability_self_cast_delay(ability) end

---The ability is channeling. Pass an ability, not a pawn.
---@param ability ability
---@return boolean
function HERO_LIB.is_channeling_ability(ability) end

---Any of the hero's abilities is channeling, except the ones used as keys in `exceptions`.
---@param lp player_pawn
---@param exceptions? table<ability, boolean>
---@return boolean
function HERO_LIB.is_channeling_any_ability(lp, exceptions) end

---One of the named abilities is channeling.
---@param lp player_pawn
---@param ability_names string[]
---@return boolean
function HERO_LIB.is_channeling_specific_abilities(lp, ability_names) end

---The ability is selected (being aimed, waiting for confirm).
---@param lp player_pawn
---@param ability ability
---@return boolean
function HERO_LIB.is_ability_selected(lp, ability) end

---Your cast mode setting for the ability's slot, a `QUICKCAST_MODE` value.
---@param ability ability
---@return integer|nil mode
function HERO_LIB.get_ability_cast_mode(ability) end

---The cast mode the ability's activation type implies, a `QUICKCAST_MODE` value.
---@param ability ability
---@return integer|nil mode
function HERO_LIB.get_ability_default_cast_mode(ability) end

---The `InputBitMask_t` button that casts the ability's slot.
---@param ability ability
---@return integer|nil mask
function HERO_LIB.get_ability_input_mask(ability) end

---The ability's icon path, ready for `Render.LoadImage`. Cached by name.
---@param ability? ability
---@param custom_ability_name? string
---@return string|nil path
function HERO_LIB.get_ability_icon(ability, custom_ability_name) end

---A property's value at the ability's current upgrade level.
---@param ability ability
---@param prop_name string
---@return number|nil value
function HERO_LIB.get_actual_prop_value(ability, prop_name) end

---A property's base value as a number. Cached by ability and property name.
---@param ability ability
---@param prop_name string
---@return number|nil value
function HERO_LIB.get_cached_property_num(ability, prop_name) end

---A property's value at each upgrade level (index 1 = base). Cached.
---@param ability ability
---@param prop_name string
---@return number[]|nil values
function HERO_LIB.get_cached_property_values(ability, prop_name) end

---The ability's upgrade tiers as `{ [prop_name] = number }` tables. Cached.
---@param ability ability
---@return table[]|nil upgrades
function HERO_LIB.get_cached_upgrades_num(ability) end

---How far the ability's cooldown has recovered, 0..1.
---@param ability ability
---@return number fraction
function HERO_LIB.get_burst_qsr_chargeup_frac(ability) end

---`"weapon"`, `"vitality"` or `"tech"` for an active item name.
---@param name string
---@return string|nil category
function HERO_LIB.get_item_category_by_name(name) end

-- ── Casting and input ─────────────────────────────────────────────────────────

---Presses the ability's button the way your cast mode needs: one press for quick cast, press then attack for confirm cast (`with_attack`), and the alt-cast button with `with_alt`. Errors when the slot has no button.
---@param cmd CUserCmd
---@param lp player_pawn
---@param ability ability
---@param with_alt? boolean
---@param with_attack? boolean
---@param custom_ability_slot? EAbilitySlots_t
function HERO_LIB.cast_ability(cmd, lp, ability, with_alt, with_attack, custom_ability_slot) end

---A fresh press of `mask` that isn't repeated on the next tick, so the game sees one press. Returns `false` when it pressed the button on the tick just before.
---@param cmd CUserCmd
---@param mask integer
---@return boolean pressed
function HERO_LIB.pulse_button(cmd, mask) end

---Clears the item's button from the command so it doesn't cast.
---@param cmd CUserCmd
---@param item ability
function HERO_LIB.block_item(cmd, item) end

---Toggles Blood Tribute to `value` (on or off), with a short re-cast guard.
---@param cmd CUserCmd
---@param lp player_pawn
---@param blood_tribute ability
---@param value boolean
function HERO_LIB.use_blood_tribute(cmd, lp, blood_tribute, value) end

---Rewrites the command's movement so you move toward an angle, a direction or a position (in that order of preference) whatever way the camera faces. `move_on` / `move_from` force moving toward / away; `block_movement` drops your other movement keys first. Returns `false` when nothing was given.
---@param cmd CUserCmd
---@param lp player_pawn
---@param only_yaw? boolean
---@param need_angle? Angle
---@param need_dir? Vector
---@param need_pos? Vector
---@param block_movement? boolean
---@param move_on? boolean
---@param move_from? boolean
---@return boolean
function HERO_LIB.rotate_movement(cmd, lp, only_yaw, need_angle, need_dir, need_pos, block_movement, move_on, move_from) end

---The cursor is free (a menu or the shop is open).
---@param cmd CUserCmd
---@return boolean
function HERO_LIB.is_using_free_cursor(cmd) end

---`true` unless the cursor is free (or always, with `allow_cursor`).
---@param lp player_pawn
---@param cmd CUserCmd
---@param allow_cursor? boolean
---@return boolean
function HERO_LIB.can_combo(lp, cmd, allow_cursor) end

---`cmd:aim(options)` with smoothing compensation for moving targets, returning the `aim.status`. When the aim is accepted and `options.ability_ent` and `options.target_ent` are set, it also remembers the target as the ability's cast target, which `find_combo_target` / `find_helper_target` then return while the cast goes out.
---@param cmd CUserCmd
---@param options AimOptions
---@return integer status
function HERO_LIB.aim(cmd, options) end

---The aim status means the aim is busy this tick (`PENDING`, `AIMING`, `READY` or `BUSY`), so a combo shouldn't start something else.
---@param status integer
---@return boolean
function HERO_LIB.aim_status_consumes_combo(status) end

-- ── Heroes and NPCs ───────────────────────────────────────────────────────────

---The entity is a hero (`C_CitadelPlayerPawn`).
---@param ent entity
---@return boolean
function HERO_LIB.is_hero_pawn(ent) end

---Both are on the same team. `nil` when one has no team.
---@param pawn1 entity
---@param pawn2 entity
---@return boolean|nil
function HERO_LIB.is_same_team(pawn1, pawn2) end

---Heroes filtered by relation to `lp`.
---@param lp player_pawn
---@param allow_lp? boolean
---@param allow_allies? boolean
---@param allow_enemies? boolean
---@param only_alive? boolean
---@return player_pawn[] heroes
function HERO_LIB.get_all_heroes(lp, allow_lp, allow_allies, allow_enemies, only_alive) end

---Heroes that have the ability, and the matching abilities (same order).
---@param ability_name string
---@param lp player_pawn
---@param allow_lp? boolean
---@param allow_allies? boolean
---@param allow_enemies? boolean
---@param only_alive? boolean
---@return player_pawn[] heroes
---@return ability[]|nil abilities
function HERO_LIB.get_all_heroes_with_ability(ability_name, lp, allow_lp, allow_allies, allow_enemies, only_alive) end

---Heroes that have the modifier (`entity:has_modifier_by_id`).
---@param modifier_id integer
---@param lp player_pawn
---@param allow_lp? boolean
---@param allow_allies? boolean
---@param allow_enemies? boolean
---@param only_alive? boolean
---@return player_pawn[] heroes
function HERO_LIB.get_all_heroes_with_modifier(modifier_id, lp, allow_lp, allow_allies, allow_enemies, only_alive) end

---Living heroes (not `lp`) within `radius` units of `pos`. `check_active` skips inactive targets; `with_time_predict` uses each hero's predicted position `time` seconds ahead.
---@param lp player_pawn
---@param pos Vector
---@param radius number
---@param allow_allies? boolean
---@param allow_enemies? boolean
---@param only_visible? boolean
---@param check_active? boolean
---@param with_time_predict? boolean
---@param time? number
---@return player_pawn[] heroes
function HERO_LIB.get_heroes_in_radius(lp, pos, radius, allow_allies, allow_enemies, only_visible, check_active, with_time_predict, time) end

---The closest living enemy hero to `pos`.
---@param lp player_pawn
---@param pos Vector
---@param only_visible? boolean
---@param with_time_predict? boolean
---@param time? number
---@param check_active? boolean
---@param additional_filter_func? fun(hero: player_pawn): boolean
---@return player_pawn|nil enemy
function HERO_LIB.get_nearest_enemy(lp, pos, only_visible, with_time_predict, time, check_active, additional_filter_func) end

---`"trooper"`, `"neutral"`, `"guardian"`, `"walker"`, `"patron"`, `"base_guardian"`, `"shrine"`, `"midboss"`, or `nil`.
---@param ent entity
---@return string|nil kind
function HERO_LIB.get_npc_kind(ent) end

---A lane trooper's `TROOPER_TYPE`.
---@param ent entity
---@return integer|nil type
function HERO_LIB.get_trooper_type(ent) end

---A neutral's `NEUTRAL_TROOPER_TYPE`.
---@param ent entity
---@return integer|nil type
function HERO_LIB.get_neutral_trooper_type(ent) end

---Damage-resistance shield health on an NPC.
---@param target entity
---@return number shield
function HERO_LIB.get_npc_shield_health(target) end

---An objective's backdoor-protection damage mitigation from players.
---@param target entity
---@return number|nil percent
function HERO_LIB.get_npc_damage_mitigation_percent(target) end

---The entity has one of the particle systems (paths).
---@param ent entity
---@param particles string[]
---@return boolean
function HERO_LIB.has_any_particle(ent, particles) end

-- ── Positions, bones and FOV ──────────────────────────────────────────────────

---The point to aim at for a hero: the upper spine (with the hero-specific bone names handled), or the root while burrowed.
---@param target entity
---@return Vector|nil pos
function HERO_LIB.get_target_pos(target) end

---A point above the hero's origin for drawing indicators.
---@param target entity
---@return Vector|nil pos
function HERO_LIB.get_on_hero_indicator_pos(target) end

---Bone name -> world position for the bones worth aiming at. Handles burrow, hex and the other model swaps.
---@param target entity
---@param ignore_legs? boolean
---@return table<string, Vector> bones
function HERO_LIB.get_bone_positions(target, ignore_legs) end

---The bone closest to your crosshair.
---@param target entity
---@param custom_camera_pos? Vector
---@return Vector|nil pos
function HERO_LIB.get_closest_bone_pos(target, custom_camera_pos) end

---The smallest angle (degrees) from your camera direction to any of the bones.
---@param bones table<string, Vector>
---@param custom_camera_pos? Vector
---@return number|nil fov
function HERO_LIB.get_fov_to_bones(bones, custom_camera_pos) end

---The smallest angle from the camera to the target's bones. Uses the command's original camera angles when `cmd` is given.
---@param camera_pos Vector
---@param target entity
---@param only_yaw? boolean
---@param cmd? CUserCmd
---@return number fov
function HERO_LIB.get_fov_to_entity(camera_pos, target, only_yaw, cmd) end

---The angle from the camera direction to a point.
---@param camera_pos Vector
---@param pos Vector
---@param custom_camera_angles? Angle
---@param only_yaw? boolean
---@param cmd? CUserCmd
---@return number fov
function HERO_LIB.get_fov_to_pos(camera_pos, pos, custom_camera_angles, only_yaw, cmd) end

---`get_fov_to_pos(...) <= fov`.
---@param camera_pos Vector
---@param pos Vector
---@param fov number
---@param custom_camera_angles? Angle
---@param only_yaw? boolean
---@param cmd? CUserCmd
---@return boolean
function HERO_LIB.is_pos_within_fov(camera_pos, pos, fov, custom_camera_angles, only_yaw, cmd) end

---`get_fov_to_entity(...) <= fov`.
---@param camera_pos Vector
---@param target entity
---@param fov number
---@param only_yaw? boolean
---@param cmd? CUserCmd
---@return boolean
function HERO_LIB.is_target_within_fov(camera_pos, target, fov, only_yaw, cmd) end

---The point is inside the ability's targeting cone, measured from the camera (or your origin with `from_lp_origin`), yaw only unless `with_pitch`.
---@param lp player_pawn
---@param cmd CUserCmd
---@param target_position Vector
---@param ability ability
---@param angle_scale? number
---@param from_lp_origin? boolean
---@param with_pitch? boolean
---@param use_half_width_method? boolean
---@return boolean inside
---@return number half_angle
function HERO_LIB.is_target_within_cone(lp, cmd, target_position, ability, angle_scale, from_lp_origin, with_pitch, use_half_width_method) end

---The point is within half of `wave_width` (meters) of the line from the camera along `camera_forward`.
---@param camera_pos Vector
---@param camera_forward Vector
---@param target_pos Vector
---@param wave_width number
---@return boolean
function HERO_LIB.is_within_wave_width(camera_pos, camera_forward, target_pos, wave_width) end

---The point on the segment closest to `point`.
---@param start_point Vector
---@param end_point Vector
---@param point Vector
---@return Vector closest
function HERO_LIB.closest_point_on_line(start_point, end_point, point) end

---The command's camera ray already passes within `threshold` units (default 1) of the point.
---@param predicted_pos Vector
---@param cmd CUserCmd
---@param threshold? number
---@return boolean
function HERO_LIB.is_already_aiming(predicted_pos, cmd, threshold) end

-- ── Visibility and traces ─────────────────────────────────────────────────────

---Traces from `start_pos` to `end_pos`, ignoring your team. Free when the trace gets at least `allowed_fraction` (default 1) of the way, or hits `target`.
---@param start_pos Vector
---@param end_pos Vector
---@param lp player_pawn
---@param target? entity
---@param allowed_fraction? number
---@return boolean free
---@return number|nil fraction
function HERO_LIB.is_line_free(start_pos, end_pos, lp, target, allowed_fraction) end

---`is_line_free` from your camera to a point.
---@param pos Vector
---@param custom_camera_pos? Vector
---@param custom_lp? player_pawn
---@param target? entity
---@param custom_allowed_fraction? number
---@return boolean free
---@return number|nil fraction
function HERO_LIB.no_obs_to_pos(pos, custom_camera_pos, custom_lp, target, custom_allowed_fraction) end

---`is_line_free` from your camera to the target's `get_target_pos`.
---@param target entity
---@param custom_camera_pos? Vector
---@param custom_lp? player_pawn
---@param custom_allowed_fraction? number
---@return boolean free
---@return number|nil fraction
function HERO_LIB.no_obs_to_target(target, custom_camera_pos, custom_lp, custom_allowed_fraction) end

---A hull trace the size of the ability's projectile (or `custom_radius`) reaches the target.
---@param local_pawn player_pawn
---@param camera_pos Vector
---@param target_pos Vector
---@param target entity
---@param ability? ability
---@param ignore_team? boolean
---@param custom_radius? number
---@return boolean
function HERO_LIB.hull_projectile_will_hit(local_pawn, camera_pos, target_pos, target, ability, ignore_team, custom_radius) end

-- ── Prediction ────────────────────────────────────────────────────────────────

---Where the hero will be after `duration` seconds, using the game's movement simulation. `additional_movement_slow` (percent) slows the prediction; `ground_only` gives up on ziplines. The first return value is always `nil` (no debug path); `need_debug` and `movement_path` are accepted and ignored.
---@param target player_pawn
---@param duration number
---@param additional_movement_slow? number
---@param ground_only? boolean
---@param need_debug? boolean
---@param movement_path? Vector[]
---@return nil path
---@return Vector|nil predicted_pos
---@return Vector|nil predicted_velocity
function HERO_LIB.simulate_movement_for_duration(target, duration, additional_movement_slow, ground_only, need_debug, movement_path) end

---Runs a movement simulation (`ENUM_MV_SIM_TYPE`) and calls `callback` with the move data of every simulated tick; return a falsy value from it to stop. Returns `false` when the simulation couldn't run.
---@param pawn player_pawn
---@param sim_type integer
---@param callback fun(mv: move_data_t): boolean
---@return boolean
function HERO_LIB.simulate_pawn_movement(pawn, sim_type, callback) end

---Solves a projectile intercept for a target moving in a straight line, including gravity, up speed and aim bias. `info_from` is an `ENUM_PPS_INFO_FROM` value. `aim_pos` is where to aim, `predicted_pos` where the target will be.
---@param info_from integer
---@param cast_point Vector
---@param target_pos Vector
---@param target_velocity Vector
---@param ability ability
---@param ignore_z? boolean
---@param custom_proj_speed? number
---@return Vector|nil aim_pos
---@return Vector|nil predicted_pos
---@return number|nil travel_time
function HERO_LIB.predict_projectile(info_from, cast_point, target_pos, target_velocity, ability, ignore_z, custom_proj_speed) end

---The full projectile prediction: simulates the target's movement (`sim_type`) tick by tick and finds the tick the projectile meets it, within the ability's range (or `custom_max_range`). `aim_to_pos` picks the target point (`ENUM_PPS_AIM_TO_POS`). Pass your `aim.type` bits and the command to account for magic-bullet aim: `mb_only` / `mb_foot` then tell you the shot only works with magic bullets / aimed at the feet. `aim_pos` is `nil` when there is no solution. Debug output is always off.
---@param need_debug boolean|nil
---@param info_from integer
---@param sim_type integer
---@param aim_to_pos integer
---@param target player_pawn
---@param ability ability
---@param custom_lp? player_pawn
---@param custom_proj_speed? number
---@param custom_max_range? number
---@param use_camera_cast? boolean
---@param aim_type_bits? integer
---@param cmd? CUserCmd
---@param custom_target_pos? Vector
---@param custom_cast_point? Vector
---@param ignore_z? boolean
---@param movement_path? Vector[]
---@return Vector|nil aim_pos
---@return Vector|nil predicted_pos
---@return nil simulated_origins
---@return nil simulated_projectiles
---@return boolean|nil mb_only
---@return boolean|nil mb_foot
function HERO_LIB.predict_projectile_simulated(need_debug, info_from, sim_type, aim_to_pos, target, ability, custom_lp, custom_proj_speed, custom_max_range, use_camera_cast, aim_type_bits, cmd, custom_target_pos, custom_cast_point, ignore_z, movement_path) end

---Like `predict_projectile_simulated` for abilities cast on the ground under the target (with a cast delay of `activation_delay`).
---@param need_debug boolean|nil
---@param info_from integer
---@param target player_pawn
---@param ability ability
---@param custom_lp? player_pawn
---@param aim_type_bits? integer
---@param cmd? CUserCmd
---@param activation_delay? number
---@param ground_offset? number
---@return Vector|nil aim_pos
---@return Vector|nil predicted_pos
---@return nil simulated_origins
---@return nil simulated_projectiles
---@return boolean|nil mb_only
---@return boolean|nil mb_foot
function HERO_LIB.predict_ground_cast_simulated(need_debug, info_from, target, ability, custom_lp, aim_type_bits, cmd, activation_delay, ground_offset) end

---The entity a cone ability would pick when cast now with the command's (or `custom_angles`) view: the one closest to the cone's centre, using the ability's own cone, range and line-of-sight rules.
---@param cmd CUserCmd
---@param lp player_pawn
---@param ability ability
---@param custom_angles? Angle
---@param target_filter? fun(ent: entity): boolean
---@return entity|nil target
function HERO_LIB.get_predicted_cone_target(cmd, lp, ability, custom_angles, target_filter) end

---Drops a position to the ground under the pawn, for ground-targeted abilities.
---@param pawn player_pawn
---@param pos Vector
---@param ability ability
---@return Vector|nil ground
function HERO_LIB.project_ground_autocast_position(pawn, pos, ability) end

---Seconds until the hero comes back from a state you can pre-cast a ground ability onto (revive, Rejuvenator respawn, hotel, void sphere, infinity slash, a stun), for the states enabled in `conditions` (the multiselect from `create_ground_autocast_settings`). `destination` is where the hero reappears when known.
---@param pawn player_pawn
---@param conditions HeroLibWidget
---@return number remaining
---@return boolean active
---@return Vector|nil destination
function HERO_LIB.get_ground_autocast_remaining(pawn, conditions) end

---The longest remaining time of any `DISABLE_MODIFIER_STATES` state on the pawn. 0 when `conditions` doesn't have "Stun" enabled.
---@param pawn entity
---@param conditions? HeroLibWidget
---@return number remaining
function HERO_LIB.get_disable_remaining(pawn, conditions) end

-- ── Damage ────────────────────────────────────────────────────────────────────

---The attacker's damage context: spirit power, outgoing damage bonuses, the ability's scaling and the items that add or amplify spirit damage.
---@param attacker player_pawn
---@param ability ability
---@param reuse? table
---@return table context
function HERO_LIB.prepare_damage_attacker(attacker, ability, reuse) end

---The damage context against one target: its health, barrier, spirit resist, damage reductions and amplifications, and whether damage is blocked (`context.blocked`).
---@param attacker_context table
---@param target entity
---@param reuse? table
---@return table context
function HERO_LIB.prepare_damage_target(attacker_context, target, reuse) end

---The damage `base_damage` of spirit damage deals to the target described by `context` (from `prepare_damage_target`), split into immediate and delayed (damage over time) parts.
---@param context table
---@param base_damage number
---@param item_trigger_damage? boolean
---@param target_health_override? number
---@return number total
---@return number immediate
---@return number delayed
---@return boolean blocked
function HERO_LIB.calculate_spirit_ability_damage(context, base_damage, item_trigger_damage, target_health_override) end

---Whether the damage kills the target, including execute thresholds (`execute_fraction` of max health). `remaining` is the health left after the damage.
---@param context table
---@param total_damage number
---@param immediate_damage number
---@param execute_fraction? number
---@param additional_health? number
---@param health_override? number
---@param damage_blocked? boolean
---@param execute_after_damage? boolean
---@return boolean|nil lethal
---@return number effective_health
---@return integer remaining
---@return boolean execute_lethal
---@return number lethal_capacity
---@return boolean unkillable
---@return number damage_delta
function HERO_LIB.calculate_damage_lethality(context, total_damage, immediate_damage, execute_fraction, additional_health, health_override, damage_blocked, execute_after_damage) end

---Spirit damage from `attacker` won't land on `target` (invulnerable, spirit-immune, out of game, spell-avoid, an NPC's shield or phase).
---@param attacker player_pawn
---@param target entity
---@return boolean
function HERO_LIB.is_spirit_damage_blocked(attacker, target) end

---An NPC or objective currently takes no damage (shield up, invulnerable phase, backdoor rules...).
---@param attacker player_pawn
---@param target entity
---@return boolean
function HERO_LIB.is_npc_damage_blocked(attacker, target) end

---An NPC's spirit resist against `attacker`, including range-based resistance.
---@param attacker player_pawn
---@param target entity
---@return number resist
function HERO_LIB.get_npc_spirit_resist(attacker, target) end

---The damage multiplier abilities get against objectives (it grows with match time), 1 for other targets.
---@param target entity
---@param ability? ability
---@return number scale
function HERO_LIB.get_npc_ability_damage_scale(target, ability) end

-- ── Target selection ──────────────────────────────────────────────────────────

---Max FOV in degrees.
---@param lp? player_pawn
---@return number fov
function HERO_LIB.get_combo_fov(lp) end

---Max distance in meters.
---@param lp? player_pawn
---@return number meters
function HERO_LIB.get_combo_distance(lp) end

---1 Minimal FOV, 2 Minimal Distance, 3 Minimal Health Value, 4 Minimal Health Percent.
---@param lp? player_pawn
---@return integer priority
function HERO_LIB.get_combo_priority(lp) end

---Ignored states, any of `"Asleep"`, `"Invisible"`, `"Invulnerable"`, `"Unstoppable"`.
---@param lp? player_pawn
---@return string[] states
function HERO_LIB.get_combo_ignore(lp) end

---Keep the combo target while it stays valid.
---@param lp? player_pawn
---@return boolean
function HERO_LIB.get_combo_lock_target(lp) end

---Max FOV in degrees.
---@param lp? player_pawn
---@return number fov
function HERO_LIB.get_helper_fov(lp) end

---Max distance in meters.
---@param lp? player_pawn
---@return number meters
function HERO_LIB.get_helper_distance(lp) end

---Same values as `get_combo_priority`.
---@param lp? player_pawn
---@return integer priority
function HERO_LIB.get_helper_priority(lp) end

---Same values as `get_combo_ignore`.
---@param lp? player_pawn
---@return string[] states
function HERO_LIB.get_helper_ignore(lp) end

---`find_combo_target` when `is_combo`, else `find_helper_target`.
---@param cmd CUserCmd
---@param lp player_pawn
---@param is_combo? boolean
---@return player_pawn|nil target
function HERO_LIB.find_target(cmd, lp, is_combo) end

---The best enemy hero under the combo settings. With lock target on, the previous target is kept while it stays valid. While an `aim` cast is going out, returns its target.
---@param cmd CUserCmd
---@param lp player_pawn
---@return player_pawn|nil target
function HERO_LIB.find_combo_target(cmd, lp) end

---The best enemy hero under the helper settings. The result is cached for the command, so calling it several times per tick is cheap.
---@param cmd CUserCmd
---@param lp player_pawn
---@return player_pawn|nil target
function HERO_LIB.find_helper_target(cmd, lp) end

---Forgets the locked combo target.
function HERO_LIB.clear_combo_target() end

-- ── Menu builders ─────────────────────────────────────────────────────────────

---An **Items** switch with an aim-type selector and three multiselects: AOE items, targeted items and non-targeted items. Pass the results to `handle_all_items`.
---@param parent CMenuGroup|HeroLibWidget
---@return HeroLibWidget items_enabled
---@return HeroLibWidget items_aim
---@return HeroLibWidget aoe_widget
---@return HeroLibWidget target_widget
---@return HeroLibWidget non_target_widget
function HERO_LIB.create_item_multiselects(parent) end

---Casts the enabled items on `target`: targeted items first, then AOE items in range, then non-targeted ones. Returns `true` when it cast something.
---@param cmd CUserCmd
---@param me player_pawn
---@param target player_pawn|nil
---@param items_enabled HeroLibWidget
---@param items_aim HeroLibWidget
---@param aoe_widget HeroLibWidget
---@param target_widget HeroLibWidget
---@param non_target_widget HeroLibWidget
---@param movement_path_factory? function
---@return boolean used
function HERO_LIB.handle_all_items(cmd, me, target, items_enabled, items_aim, aoe_widget, target_widget, non_target_widget, movement_path_factory) end

---Casts the first ready targeted item that reaches the target, aiming with `aim_settings` (`items_aim()`).
---@param cmd CUserCmd
---@param lp player_pawn
---@param target player_pawn
---@param items_multiselect HeroLibWidget
---@param aim_settings table
---@param movement_path_factory? function
---@return boolean used
function HERO_LIB.handle_target_items(cmd, lp, target, items_multiselect, aim_settings, movement_path_factory) end

---Casts ready AOE items whose radius covers the target.
---@param cmd CUserCmd
---@param lp player_pawn
---@param target player_pawn
---@param items_multiselect HeroLibWidget
---@return boolean used
function HERO_LIB.handle_aoe_items(cmd, lp, target, items_multiselect) end

---Casts ready non-targeted items.
---@param cmd CUserCmd
---@param lp player_pawn
---@param target player_pawn
---@param items_multiselect HeroLibWidget
---@return boolean used
function HERO_LIB.handle_non_target_items(cmd, lp, target, items_multiselect) end

---An **Auto** switch for a saving ability (heal, shield, cleanse) with its settings: targets (self / allies), max FOV, aim type, and health / health-loss triggers. Pass `settings` to `handle_auto_save`.
---@param parent CMenuGroup|HeroLibWidget
---@param ability_name string
---@param image? string
---@param allies_only? boolean
---@param self_only? boolean
---@return HeroLibWidget enabled
---@return table settings
function HERO_LIB.create_auto_save_ui(parent, ability_name, image, allies_only, self_only) end

---Casts the saving ability on yourself or an ally when a trigger from `settings` fires (health below a value or percent, or health lost within a time window). `state` is an empty table you keep per ability; the function stores its history there.
---@param cmd CUserCmd
---@param lp player_pawn
---@param ability ability
---@param state table
---@param settings table
---@return boolean used
function HERO_LIB.handle_auto_save(cmd, lp, ability, state, settings) end

---A **Cast On** multiselect (stun, revive, Rejuvenator, hotel, void sphere, and infinity slash with `include_yamato`) and a **Post Invulnerability Buffer** slider in ticks. Use them with `get_ground_autocast_remaining`.
---@param parent CMenuGroup|HeroLibWidget
---@param include_yamato? boolean
---@return HeroLibWidget conditions
---@return HeroLibWidget buffer
function HERO_LIB.create_ground_autocast_settings(parent, include_yamato) end

---Sets each item's localized name as the tooltip of its row in a multiselect.
---@param widget HeroLibWidget|MenuWidget
---@param items table[]
function HERO_LIB.apply_item_schema(widget, items) end

---`{ item.name, item.image, value }`, a multiselect row for an item.
---@param item HeroLibItem
---@param value boolean
---@return table row
function HERO_LIB.construct_item_ui_element(item, value) end

---Returns the cached value for `key`, calling `producer` the first time. The cache is shared by every script and cleared on a full reload.
---@param key string
---@param producer fun(): any
---@return any value
function HERO_LIB.cache_get(key, producer) end
