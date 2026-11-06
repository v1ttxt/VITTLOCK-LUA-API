---@meta
-- utils: camera, target finders, angle math, VData, bullet prediction, hitbox tests, minimap, misc
-- (utils.json_encode / utils.json_decode are in core.lua)

---@class utils
utils = utils or {}

-- Camera -----------------------------------------------------------------------

---The active camera's angles. (0,0,0) when there is no camera.
---@return Angle angles
function utils.get_camera_angles() end

---The active camera's position. (0,0,0) when there is no camera.
---@return Vector pos
function utils.get_camera_pos() end

---The camera's field of view in degrees, clamped to 10..170. 75 when there is no camera.
---@return number fov
function utils.get_camera_fov() end

---Always returns false, 0.
---@return boolean snapping
---@return integer ticks
function utils.is_camera_snapping() end

---The on-screen radius in pixels of a circle `fov` degrees around the screen centre. 0 when fov <= 0 or there is no camera.
---@param fov number Angle from the screen centre, in degrees
---@return number radius
function utils.fov_to_pixel_radius(fov) end

-- Target finders -----------------------------------------------------------------

---The live enemy hero closest to the crosshair (smallest angle from the camera to its origin) that is visible to your team. nil if none or you are dead.
---@return player_pawn|nil target
function utils.find_nearest_visible_enemy() end

---The live enemy hero closest to the crosshair, visible or not. nil if none or you are dead.
---@return player_pawn|nil target
function utils.find_nearest_fov_enemy() end

---The visible live enemy hero with a body bone within `fov` degrees of the crosshair. nil if none.
---@param fov number Maximum angle in degrees
---@return player_pawn|nil target
function utils.find_target_in_fov(fov) end

-- VData --------------------------------------------------------------------------

---The subclass id of a VData name (case-insensitive), e.g. "upgrade_clip_size". nil for "".
---@param name string
---@return integer|nil id
function utils.subclass_id(name) end

---Looks up VData by subclass id. Returns the VData and its localized display name.
---@param id integer Subclass id (from utils.subclass_id)
---@param kind? integer -1 = any kind (default), 4 = abilities and items
---@return raw_struct|nil vdata
---@return string|nil display_name
function utils.get_vdata_by_subclass(id, kind) end

---An ability VData's property by name (case-insensitive), e.g. "AbilityCooldown". nil if it has none.
---@param vdata raw_struct Ability VData (from utils.get_vdata_by_subclass or ability:get_vdata())
---@param name string Property name
---@return raw_struct|nil property
function utils.get_vdata_property(vdata, name) end

---An ability property's value with the owner's upgrades applied. nil if the owner, ability or property is not found.
---@param owner entity|player_pawn The hero whose upgrades apply
---@param ability_id integer The ability's subclass id
---@param name string Property name
---@return number|nil value
function utils.get_scaled_ability_property(owner, ability_id, name) end

-- Angles --------------------------------------------------------------------------

---The angle that looks from `src` to `dst` (pitch -89..89, yaw -180..180, roll 0). nil for non-Vector or non-finite input.
---@param src Vector
---@param dst Vector
---@return Angle|nil angle
function utils.calc_angle(src, dst) end

---The angle in degrees (0..180) between two view directions (roll ignored). 3.4e38 for bad input.
---@param a Angle
---@param b Angle
---@return number degrees
function utils.get_fov(a, b) end

---The shortest signed difference a - b in degrees (-180..180). 0 for non-finite input.
---@param a number
---@param b number
---@return number degrees
function utils.angle_diff(a, b) end

-- Bullets -------------------------------------------------------------------------

---Where to aim a weapon at a moving target so its bullet meets it (bullet speed, drop and the weapon's aim bias). nil if the weapon has no bullet data.
---@param src Vector Shot origin
---@param dst Vector The target point now
---@param target_velocity Vector The target's velocity
---@param weapon ability The weapon (e.g. pawn:get_primary_weapon())
---@param shooter? entity Whose bullet speed modifiers apply (default: the local pawn)
---@return Vector|nil aim_point
function utils.predict_bullet(src, dst, target_velocity, weapon, shooter) end

-- Slide ---------------------------------------------------------------------------

---The local pawn's slide level: 0 when not sliding, -1 without a local pawn or slide ability.
---@return integer level
function utils.get_slide_level() end

---The slide ability's current slope value. 0 without a local pawn or slide ability.
---@return number value
function utils.get_slide_angle() end

-- Hitbox tests --------------------------------------------------------------------

---True if the segment touches any of the entity's hitboxes. False for a dead or invalid entity.
---@param start Vector
---@param end_ Vector
---@param ent entity
---@return boolean hit
function utils.is_line_intersect_entity(start, end_, ent) end

---The centre of the first hitbox the segment touches (not the entry point). nil when none.
---@param start Vector
---@param end_ Vector
---@param ent entity
---@return Vector|nil center
function utils.get_line_intersection_entity(start, end_, ent) end

---True if a sphere of `hull_radius` swept along the segment touches any of the entity's hitboxes, with the entity moved by `ent_origin_offset`.
---@param start Vector
---@param end_ Vector
---@param hull_radius number
---@param ent entity
---@param ent_origin_offset? Vector Offset added to the entity's hitboxes (default 0,0,0)
---@return boolean hit
function utils.is_hull_intersect_entity(start, end_, hull_radius, ent, ent_origin_offset) end

-- Minimap -------------------------------------------------------------------------

---True while the HUD minimap is shown.
---@return boolean visible
function utils.is_minimap_visible() end

---The screen position (pixels) of a world position on the HUD minimap. (0,0) when the minimap is hidden.
---@param pos Vector
---@return Vec2 screen
function utils.world_to_map(pos) end

---The screen position (pixels) of a minimap position given in 0..255 units per axis. (0,0) when there is no minimap.
---@param p Vec2 Minimap position, 0..255 per axis
---@return Vec2 screen
function utils.minimap_percent_to_minimap(p) end

---The world position of a minimap position given in 0..255 units per axis. (0,0,0) when the map bounds are unknown.
---@param p Vec2 Minimap position, 0..255 per axis
---@return Vector world
function utils.minimap_to_world(p) end

-- Misc ----------------------------------------------------------------------------

---True while you are in a game.
---@return boolean
function utils.is_in_game_ui() end

---Runs a console command, as if typed in the console.
---@param command string
function utils.execute_command(command) end

---Reloads every script on the next frame.
function utils.reload_scripts() end
