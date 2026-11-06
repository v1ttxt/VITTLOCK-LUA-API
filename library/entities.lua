---@meta
-- Entities: entity_list, entity, player_pawn, ability, modifier, move_data_t, raw_struct, raw_ptr, CPanoramaImageName.

-------------------------------------------------------------------------------
-- entity_list
-------------------------------------------------------------------------------

---Finds entities: the local pawn and controller, by index, by handle, by class.
---@class entity_list
entity_list = {}

---Team filter values for `entity_list.by_class_name`.
---@enum entity_list.team_filter
entity_list.team_filter = {
    enemy = 0,
    friend = 1,
    both = 2,
}

---Every entity in the game (all teams, all classes). Scans every entity slot: call once per frame at most.
---@return (entity|player_pawn|ability)[] entities
function entity_list.get_all() end

---Every entity whose schema class is exactly `class_name`, optionally filtered by team relative to your pawn.
---@param class_name string Exact, case-sensitive schema class name, e.g. "C_CitadelPlayerPawn".
---@param team? entity_list.team_filter|integer `entity_list.team_filter.*`; all teams when omitted.
---@return (entity|player_pawn|ability)[] entities
function entity_list.by_class_name(class_name, team) end

---The entity in slot `index`, or nil when the slot is empty.
---@param index integer Entity index (0..32767).
---@return entity|player_pawn|ability|nil
function entity_list.by_index(index) end

---The entity a handle refers to, or nil when the handle is invalid or the entity is gone.
---@param handle integer An entity handle (from `get_handle()` or a handle field such as `m_hOwnerEntity`).
---@return entity|player_pawn|ability|nil
function entity_list.by_handle(handle) end

---Your hero pawn, or nil when you have none (menu, loading, spectating).
---@return player_pawn|nil
function entity_list.local_pawn() end

---Your player controller, or nil.
---@return entity|nil
function entity_list.local_controller() end

-------------------------------------------------------------------------------
-- entity
-------------------------------------------------------------------------------

---One live particle effect owned by an entity.
---@class entity_particle
---@field name string The particle path, e.g. "particles/abilities/....vpcf".
---@field control_points entity_particle_control_point[] The control points whose position is known.

---@class entity_particle_control_point
---@field cp integer Control point number.
---@field origin Vector World position.

---Any game entity. Holds the entity's handle and looks it up again on every call, so it never points at freed memory.
---Index it with a schema field name (`e.m_iHealth`) to read a networked field; assign to write it (client side only).
---@class entity
---@field [string] any Schema field of the entity's class or any base class (nil when the class has no such field).
local entity = {}

---The entity's index (its slot in the entity list). Works even when the entity is gone.
---@return integer index
function entity:get_index() end

---The entity's handle (index plus serial number). Works even when the entity is gone.
---@return integer handle
function entity:get_handle() end

---True while the handle still refers to this entity.
---@return boolean
function entity:valid() end

---The entity's schema class name, e.g. "C_CitadelPlayerPawn". "" when gone.
---@return string
function entity:get_class_name() end

---Heroes: the internal hero name ("hero_atlas"). Others: the entity's designer name (abilities: their ability name). "" when gone.
---@return string
function entity:get_name() end

---World position of the entity, nil when unavailable.
---@return Vector|nil
function entity:get_origin() end

---Networked velocity, nil when unavailable.
---@return Vector|nil
function entity:get_velocity() end

---World rotation of the entity (for heroes the body rotation, not the camera), nil when unavailable.
---@return Angle|nil
function entity:get_angles() end

---True when the entity exists and its life state is "alive".
---@return boolean
function entity:is_alive() end

---True when the entity is dormant (not being updated by the server) or gone.
---@return boolean
function entity:is_dormant() end

---Max health; 0 when gone.
---@return integer
function entity:get_max_health() end

---Every modifier on the entity (empty table when gone).
---@return modifier[]
function entity:get_modifiers() end

---The first matching modifier, or nil.
---@param name string A modifier class name ("CCitadel_Modifier_Stunned") or an "ability/modifier" key ("citadel_ability_melee_parry/modifier_citadel_parry").
---@return modifier|nil
function entity:get_modifier(name) end

---True when the entity has a matching modifier.
---@param name string A modifier class name or an "ability/modifier" key (see get_modifier).
---@return boolean
function entity:has_modifier(name) end

---The modifier with this id, or nil.
---@param id integer Modifier id (see `utils.subclass_id`).
---@return modifier|nil
function entity:get_modifier_by_id(id) end

---True when the entity has a modifier with this id.
---@param id integer Modifier id.
---@return boolean
function entity:has_modifier_by_id(id) end

---The modifier with this id that `caster` applied, or nil.
---@param caster entity|player_pawn|ability|integer The caster entity or its handle.
---@param id integer Modifier id.
---@return modifier|nil
function entity:get_modifier_by_id_from(caster, id) end

---The game's combined modifier value on the entity, or `default` when it has none.
---@param value_id integer `EModifierValue.*`
---@param default? number|boolean Returned when the entity has no such value. When boolean, the result is a boolean too.
---@return number|boolean|nil
function entity:get_modifier_value(value_id, default) end

---Same as `get_modifier_value`.
---@param value_id integer `EModifierValue.*`
---@param default? number|boolean
---@return number|boolean|nil
function entity:get_sum_modifier_value(value_id, default) end

---True when any active modifier puts the entity in this state.
---@param state integer `EModifierState.*`
---@return boolean
function entity:has_modifier_state(state) end

---True when the entity is in any of the given states.
---@param ... integer `EModifierState.*` values, as separate arguments.
---@return boolean
function entity:has_any_modifier_state(...) end

---Seconds left on the longest timed modifier that applies this state; 0 when none.
---@param state integer `EModifierState.*`
---@return number seconds
function entity:get_modifier_state_remaining_duration(state) end

---The modifier applying this state with the most time left (untimed modifiers win), or nil.
---@param state integer `EModifierState.*`
---@return modifier|nil
function entity:find_best_modifier_for_state(state) end

---For each state given, the modifier applying it with the most time left. States no modifier applies are skipped.
---@param ... integer `EModifierState.*` values, as separate arguments.
---@return modifier[]
function entity:find_best_modifiers_for_states(...) end

---The entity's VData (static class data). Heroes: their hero data. Abilities: their ability VData. nil when none.
---@return raw_struct|nil
function entity:get_vdata() end

---The class name of `get_vdata()`; "" when none.
---@return string
function entity:get_vdata_class_name() end

---The entity's scene node (usually a CSkeletonInstance), nil when none.
---@return raw_struct|nil
function entity:get_skeleton_instance() end

---The entity's model state (CModelState), nil when none.
---@return raw_struct|nil
function entity:get_model_state() end

---The model path; "" when none.
---@return string
function entity:get_model_name() end

---The entity's address as a hex string ("0x0" when gone). For debugging and identity checks.
---@return string
function entity:get_address() end

---World position of the named bone, nil when the bone or model is missing.
---@param bone_name string e.g. "head"
---@return Vector|nil
function entity:get_bone_pos(bone_name) end

---Every bone: bone name -> world position.
---@return table<string, Vector>
function entity:get_bones() end

---The smallest angle (degrees) between your current view direction and the direction from `camera_pos` to any bone. 180 when the model has no bones.
---@param camera_pos Vector Where to measure from (usually your camera position).
---@param only_yaw? boolean Compare yaw only. Default false.
---@return number degrees
function entity:get_min_fov_to_bones(camera_pos, only_yaw) end

---World position of the named model attachment, nil when missing.
---@param name string Attachment name, e.g. "ability_cast".
---@return Vector|nil
function entity:get_attachment(name) end

---The muzzle point of your weapon. Only works on your own pawn; nil for every other entity.
---@return Vector|nil
function entity:get_fireport_position() end

---Currently always an empty table.
---@return table
function entity:get_anims() end

---The live server particles owned by this entity.
---@return entity_particle[]
function entity:get_particles() end

---True when the entity owns a live particle with this path (case-insensitive; ".vpcf_c" and ".vpcf" both match).
---@param path string
---@return boolean
function entity:has_particle(path) end

---Position of the entity's particle with this path: control point 0, else the lowest known one. nil when unknown.
---@param path string
---@return Vector|nil
function entity:get_particle_position(path) end

-------------------------------------------------------------------------------
-- player_pawn
-------------------------------------------------------------------------------

---A hero pawn. Has every `entity` method plus the ones below.
---@class player_pawn : entity
local player_pawn = {}

---Every ability entity the pawn has that reached your client (abilities, weapons, items).
---@return ability[]
function player_pawn:get_abilities() end

---The pawn's ability with this name, e.g. "upgrade_..." or "citadel_weapon_...", or nil.
---@param name string Ability name (as `ability:get_name()` returns).
---@return ability|nil
function player_pawn:get_ability(name) end

---The pawn's ability with this subclass id (`ability.m_nSubclassID`), or nil.
---@param id integer
---@return ability|nil
function player_pawn:get_ability_by_id(id) end

---True when the pawn has an ability or item with this subclass id; nil when the pawn is gone.
---@param id integer
---@return boolean|nil
function player_pawn:has_item_by_id(id) end

---The primary weapon, or nil.
---@return ability|nil
function player_pawn:get_primary_weapon() end

---The ability in a slot, or nil.
---@param slot integer `EAbilitySlots_t.*`
---@return ability|nil
function player_pawn:get_ability_by_slot(slot) end

---The hero's starting value for a stat (from its hero data); 0 when unknown.
---@param stat integer `EStatsType.*`
---@return number
function player_pawn:get_starting_stat(stat) end

---The hero's per-level scale for a stat (from its hero data); 0 when unknown.
---@param stat integer `EStatsType.*`
---@return number
function player_pawn:get_scaling_stat(stat) end

---The pawn's spirit (tech) damage reduction stat; 0 when unavailable.
---@return number
function player_pawn:get_tech_resist() end

---True when the pawn is networked to you (not dormant) and not invisible to your team.
---@return boolean
function player_pawn:is_visible() end

---Predicts the pawn's movement tick by tick (up to 200 ticks). `callback` gets each tick; return true to continue.
---@param callback fun(mv: move_data_t): boolean
function player_pawn:simulate_movement(callback) end

---The pawn's player controller, or nil.
---@return entity|nil
function player_pawn:get_player_controller() end

---The pawn's amount of a currency; 0 when out of range or gone.
---@param currency integer `ECurrencyType.*` (0..5)
---@return integer
function player_pawn:get_currency(currency) end

---The player's Steam account id (low 32 bits of the Steam id); 0 for bots or when unavailable.
---@return integer
function player_pawn:get_account_id() end

---The id of the map district the pawn is in; 0 when unavailable.
---@return integer
function player_pawn:get_map_district_id() end

-------------------------------------------------------------------------------
-- ability
-------------------------------------------------------------------------------

---An ability, weapon or item entity. Has every `entity` method plus the ones below.
---@class ability : entity
local ability = {}

---The cast range (upgrades and overrides included); 0 when not learned or gone.
---@return number
function ability:get_cast_range() end

---The weapon info (CCitadelWeaponInfo) of a weapon ability, nil otherwise.
---@return raw_struct|nil
function ability:get_weapon_info() end

---0 not learned, 1 learned, +1 for each upgrade bought (max 4).
---@return integer
function ability:get_level() end

---Seconds until the cooldown ends; 0 when ready.
---@return number seconds
function ability:get_cooldown() end

---The ability's area radius ("Radius" property); 0 when none.
---@return number
function ability:get_aoe_radius() end

---Whether the game would let the ability be cast now: 0 ready, other values a reason (see `Enum.AbilityExecuteState`). -1 when unavailable.
---@return integer
function ability:can_be_executed() end

---Subclass ids (integers) of the abilities this item is imbued on.
---@return integer[]
function ability:get_imbued_abilities() end

---True when this item is imbued on the ability with this subclass id.
---@param id integer Ability subclass id.
---@return boolean
function ability:has_imbue_for(id) end

---The raw property entry (CitadelAbilityProperty_t) from the ability's VData, or nil.
---@param name string Property name, e.g. "AbilityCooldown".
---@return raw_struct|nil
function ability:get_property(name) end

---The property's value with upgrades and the owner's scaling applied; nil when the ability has no such property.
---@param name string Property name.
---@return number|nil
function ability:get_scaled_property(name) end

---The changes one upgrade level makes: property name -> bonus (as text). nil past the last level.
---@param level integer 1-based upgrade level.
---@return table<string, string>|nil
function ability:get_upgrade(level) end

---Every upgrade level (see `get_upgrade`); nil when the ability has no upgrades.
---@return table<string, string>[]|nil
function ability:get_upgrades() end

---The unit the game would pick for this cone-targeted cast. Your own abilities only; nil otherwise.
---@return entity|player_pawn|nil
function ability:get_target() end

---Heroes and NPC units of `team` inside a cone (or its half-width tube). Does not depend on the ability it is called on.
---@param team integer Team number to look for (2 or 3, see `Enum.TeamNum`).
---@param start Vector Cone apex.
---@param direction Vector Cone axis (any length).
---@param range number Max distance; 0 for no limit.
---@param half_width number Half width of the tube along the axis; 0 for none.
---@param half_angle? number|Angle Cone half angle in degrees (an Angle uses its yaw). 0 or nil: tube only.
---@param owner? entity|player_pawn|ability Entity to leave out (usually yourself).
---@param los_check? any Truthy (non-nil, non-false, non-zero): only units in line of sight from `start`.
---@param include_extra2d_cone? any Truthy: also accept units inside the same angle measured flat on the ground plane.
---@return (entity|player_pawn)[]
function ability:find_entities_in_cone(team, start, direction, range, half_width, half_angle, owner, los_check, include_extra2d_cone) end

-------------------------------------------------------------------------------
-- modifier
-------------------------------------------------------------------------------

---A modifier (buff / debuff) on an entity. Re-checked on every use: once removed, every method returns its default.
---Index it with a schema field name (`m.m_hCaster`, `m.m_flDuration`) to read a field.
---@class modifier
---@field [string] any Schema field of the modifier's class or CBaseModifier.
local modifier = {}

---The modifier's class name, e.g. "CCitadel_Modifier_Stunned"; "" when removed.
---@return string
function modifier:get_class_name() end

---Currently the same as `get_class_name()`.
---@return string
function modifier:get_name() end

---The class name of the modifier's VData; "" when unknown or removed.
---@return string
function modifier:get_vdata_class_name() end

---The modifier's VData, nil when removed.
---@return raw_struct|nil
function modifier:get_vdata() end

---Seconds left; -1 for a modifier without a duration; 0 when removed.
---@return number
function modifier:get_remaining_duration() end

---The ability that applied the modifier, or nil.
---@return ability|entity|nil
function modifier:get_ability() end

-------------------------------------------------------------------------------
-- move_data_t
-------------------------------------------------------------------------------

---One predicted tick from `player_pawn:simulate_movement`.
---@class move_data_t
---@field tickcount integer Ticks from now (1 = the next tick). Read-only.
local move_data_t = {}

---Predicted position at this tick.
---@return Vector
function move_data_t:get_origin() end

---Predicted velocity at this tick.
---@return Vector
function move_data_t:get_velocity() end

-------------------------------------------------------------------------------
-- raw_struct / raw_ptr / CPanoramaImageName
-------------------------------------------------------------------------------

---A view of a game object of a known schema class. Index it with field names to read; assign to write.
---Holds a plain address with no validity check: do not keep it across frames.
---@class raw_struct
---@field [string] any Schema field of the struct's class or a base class (nil when missing or unsupported).

---A raw address. Only `tostring` (hex) is supported.
---@class raw_ptr

---A game image reference (ability icons and similar), read from a schema field.
---@class CPanoramaImageName
local CPanoramaImageName = {}

---The image path as the game stores it, e.g. "file://{images}/hud/abilities/x.psd"; "" when empty.
---@return string
function CPanoramaImageName:get_name() end

---The compiled texture path, e.g. "panorama/images/hud/abilities/x_psd.vtex_c" (for `Render.LoadImage`).
---@return string
function CPanoramaImageName:get_file_path() end

---True when no image is set.
---@return boolean
function CPanoramaImageName:is_empty() end
