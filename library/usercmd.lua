---@meta
-- user command: CUserCmd (fields, button engine, aim helpers) and the `aim` table

---The command being built this tick. Passed to `on_pre_createmove`, `on_createmove` and `on_post_createmove`.
---Only valid inside the callback that received it: do not keep it.
---@class CUserCmd
---@field viewangles Angle The command's view angles. Read/write.
---@field forwardmove number Forward move axis (positive = forward). Read/write.
---@field leftmove number Side move axis (positive = left). Read/write.
---@field upmove number Vertical move axis. Read/write.
---@field command_number integer The command's sequence number. Read-only.
---@field legacy_command_number integer Read/write.
---@field client_tick integer The client tick the command was built on. Read/write.
---@field impulse integer Read/write.
---@field weaponselect integer Read/write.
---@field random_seed integer The command's random seed. Read/write.
---@field mousedx integer Mouse X movement this command. Read/write.
---@field mousedy integer Mouse Y movement this command. Read/write.
---@field consumed_server_angle_changes integer Read/write.
---@field cmd_flags integer Read/write.
---@field pawn_entity_handle integer The handle of the pawn the command is for (14-bit index, serial above it). Read/write.
---@field execute_ability_indices integer Read/write.
---@field camera_roaming_speed number Read/write.
---@field in_shop boolean The shop is open. Read/write.
---@field using_free_cursor boolean The game's free cursor is up. Read/write.
---@field enemy_hero_aimed_at integer Read/write.
---@field vec_camera_position Vector The command's camera position. Read/write.
---@field ang_camera_angles Angle The command's camera angles. Read/write.
---@field orig_vec_camera_position Vector The command's camera position before any feature or script changed it. Read-only.
---@field orig_ang_camera_angles Angle The command's camera angles before any feature or script changed it. Read-only.
CUserCmd = {}

-- Button engine ----------------------------------------------------------------

---Holds the buttons down this command. Sends a press edge only if they were up last command; stops holding (with a release edge) on the first command you no longer call it.
---@param mask integer InputBitMask_t bits
function CUserCmd:press(mask) end

---Sets the buttons' scroll bit this command: the game reads it as a new press even while the button is already held.
---@param mask integer InputBitMask_t bits
function CUserCmd:fresh_press(mask) end

---Releases the buttons this command, with a release edge if they are down now or were down last command. Cancels a pending pulse.
---@param mask integer InputBitMask_t bits
function CUserCmd:release(mask) end

---Taps the buttons for one command (release first if they were down), then releases them. Fires once per run of consecutive commands that call it.
---@param mask integer InputBitMask_t bits
function CUserCmd:pulse(mask) end

---Keeps the buttons down without a new press edge if they were down last command; otherwise makes sure they are not pressed this command.
---@param mask integer InputBitMask_t bits
function CUserCmd:maintain_hold(mask) end

---True if any of the buttons was down in the last command that was sent.
---@param mask integer InputBitMask_t bits
---@return boolean down
function CUserCmd:was_button_down(mask) end

---Clears the buttons from the down, changed and scroll words, and drops their sub-tick press/release steps.
---@param mask integer InputBitMask_t bits
function CUserCmd:clear_button_all_states(mask) end

---Clears the buttons from the down word only.
---@param mask integer InputBitMask_t bits
function CUserCmd:clear_button_down_state(mask) end

---Clears the buttons from the changed word only.
---@param mask integer InputBitMask_t bits
function CUserCmd:clear_buttons_changed_mask(mask) end

---Clears the buttons from the scroll word only.
---@param mask integer InputBitMask_t bits
function CUserCmd:clear_buttons_wheel_mask(mask) end

---Adds the buttons to the down word (raw; no edge).
---@param mask integer InputBitMask_t bits
function CUserCmd:add_buttons_down(mask) end

---Adds the buttons to the changed word (raw).
---@param mask integer InputBitMask_t bits
function CUserCmd:add_buttons_changed(mask) end

---Adds the buttons to the scroll word (raw).
---@param mask integer InputBitMask_t bits
function CUserCmd:add_buttons_wheel(mask) end

---The down word now. Same as `get_buttons_down_mask`.
---@return integer mask InputBitMask_t bits
function CUserCmd:get_buttons_mask() end

---The down word now (buttons held this command).
---@return integer mask InputBitMask_t bits
function CUserCmd:get_buttons_down_mask() end

---The changed word now (buttons pressed or released this command).
---@return integer mask InputBitMask_t bits
function CUserCmd:get_buttons_changed_mask() end

---The scroll word now.
---@return integer mask InputBitMask_t bits
function CUserCmd:get_buttons_wheel_mask() end

---The down word as the player's input left it, before any feature or script. Same as `get_orig_buttons_down_mask`.
---@return integer mask InputBitMask_t bits
function CUserCmd:get_orig_buttons_mask() end

---The down word as the player's input left it, before any feature or script.
---@return integer mask InputBitMask_t bits
function CUserCmd:get_orig_buttons_down_mask() end

---The changed word as the player's input left it, before any feature or script.
---@return integer mask InputBitMask_t bits
function CUserCmd:get_orig_buttons_changed_mask() end

---The scroll word as the player's input left it, before any feature or script.
---@return integer mask InputBitMask_t bits
function CUserCmd:get_orig_buttons_wheel_mask() end

---What a jump would do at the start of this command. All values are nil when there is no record for the previous command.
---@return boolean|nil grounded The local pawn stands on something
---@return boolean|nil ready A jump now would be a ground jump
---@return integer|nil source_command The command number the state was recorded for
---@return integer|nil source_tick The tick the state was recorded at
function CUserCmd:get_ground_jump_state() end

---Whether a jump at the start of this command would be a dash jump. All values are nil when there is no record for the previous command.
---@return boolean|nil dash A jump now would be a dash jump
---@return integer|nil source_command The command number the state was recorded for
---@return integer|nil source_tick The tick the state was recorded at
function CUserCmd:get_dash_jump_state() end

-- Aim ----------------------------------------------------------------------------

---Options for `CUserCmd:aim`. `aim_pos` or `aim_angle` is required.
---@class AimOptions
---@field aim_pos? Vector World point to aim at
---@field aim_angle? Angle Angle to aim at (used instead of aim_pos)
---@field aim_type? integer aim.type bits (default aim.type.DEFAULT)
---@field target_ent? player_pawn The target hero (only player pawns count)
---@field ability_ent? ability The ability being aimed
---@field smooth? number Smoothing in percent, 0 = snap (default 0). DEFAULT and SILENT only
---@field allowed_min_fov? number READY once within this many degrees (default 1)
---@field trace_radius? number Allowed miss in units for PSILENT (default 0, at least 1 is used)
---@field trace_pos? Vector MAGIC_BULLETS: the point the bend must see
---@field mb_only? boolean With MAGIC_BULLETS plus another type: use only the magic bullet bend
---@field custom_ang_pitch? number Overrides the solved pitch
---@field custom_ang_yaw? number Overrides the solved yaw
---@field on_process_callback? fun() Called on each command the request is PENDING, AIMING, BUSY or BLOCKED
---@field on_aimed_callback? fun() Called on the command the request is READY

---The camera pose returned by `CUserCmd:predict_aim_camera`.
---@class AimCameraPose
---@field angle Angle Camera angles that put the aim ray on the point
---@field cam_pos Vector Where the camera sits at that angle
---@field pivot Vector The point the camera orbits around
---@field launch Vector The point on the aim ray closest to the pivot

---Runs an aim request on this command. Call it every command while you want to aim. Use it from on_createmove or on_post_createmove.
---@param options AimOptions
---@return integer status aim.status value
function CUserCmd:aim(options) end

---The camera pose whose aim ray passes through `aim_pos`, for this command. nil when there is none (or outside on_createmove / on_post_createmove).
---@param aim_pos Vector
---@return AimCameraPose|nil pose
function CUserCmd:predict_aim_camera(aim_pos) end

---The origin a magic bullet bend from this command's camera would shoot from to reach `aim_pos`. nil when no bend reaches it.
---@param aim_pos Vector
---@return Vector|nil origin
function CUserCmd:predict_magic_bullets_origin(aim_pos) end

---Accepted for compatibility; does nothing.
---@param ... any
function CUserCmd:mark_aim_movement_frame(...) end

---aim.type values: bits for `AimOptions.aim_type`.
---@enum AimType
local AimType = {
    NONE = 0,
    DEFAULT = 1,
    SILENT = 2,
    PSILENT = 4,
    MAGIC_BULLETS = 8,
}

---aim.status values returned by `CUserCmd:aim`.
---@enum AimStatus
local AimStatus = {
    INVALID = 0,
    PENDING = 1,
    AIMING = 2,
    READY = 3,
    BUSY = 4,
    BLOCKED = 5,
}

---Constants for `CUserCmd:aim`.
---@class aim
aim = {}

---Aim type bits (combine with `|`).
aim.type = AimType

---Aim request results.
aim.status = AimStatus
