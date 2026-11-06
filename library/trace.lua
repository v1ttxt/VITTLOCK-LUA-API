---@meta
-- trace: ray, hull and bullet traces through the game world, and the trace_t result

---The result of `trace.line` / `trace.hull`. A copy: safe to keep.
---@class trace_t
---@field fraction number How far along the path the trace got, 0..1 (1 = nothing hit). Read/write.
---@field start_pos Vector Where the trace started. Read-only.
---@field end_pos Vector Where the trace stopped. Read-only.
---@field hit_pos Vector The exact hit point when the game reports one, else end_pos. Read-only.
---@field normal Vector Surface normal at the hit. Read-only.
---@field portalled boolean The trace passed through a portal. Read-only.
---@field portal_fraction number Fraction of the path at the portal entry (1 when not portalled). Read-only.
---@field portal_entry Vector Where the trace entered the portal ((0,0,0) when not portalled). Read-only.
---@field portal_exit Vector Where the trace left the portal ((0,0,0) when not portalled). Read-only.
local trace_t = {}

---The entity that was hit, or nil.
---@return entity|nil ent
function trace_t:hit_entity() end

---The name of the hitbox that was hit, or "" when no hitbox was hit.
---@return string name
function trace_t:hitbox_name() end

---True if the trace reached within 5 units of the full distance, or hit `ent` (with a fraction above 0).
---@param ent entity The entity you traced toward
---@param full_dist number The full length of the traced path
---@return boolean visible
function trace_t:is_visible_entity(ent, full_dist) end

---True when the normal's x and z are exactly 0 and its y is below -0.99.
---@return boolean
function trace_t:is_vertical_normal() end

---Traces through the game world. Only works on the game thread (on_frame, the createmove callbacks); elsewhere returns an empty result (fraction 1).
---@class trace
trace = {}

---Traces a line from `start` to `end_`. The local pawn is always skipped.
---@param start Vector Start point
---@param end_ Vector End point
---@param with integer Interaction layers the trace collides with (64-bit mask)
---@param exclude integer Interaction layers to ignore (64-bit mask)
---@param as integer Interaction layers the trace itself counts as (64-bit mask)
---@param object_set_mask integer Accepted but not used (every object set is traced)
---@param collision_group integer Collision group (0-255)
---@param filter fun(ent: entity): boolean Called for each entity the trace meets: return true to let it block, false/nil to pass through
---@param portal? boolean Follow portals (default true)
---@return trace_t result
function trace.line(start, end_, with, exclude, as, object_set_mask, collision_group, filter, portal) end

---Sweeps a box from `start` to `end_`.
---@param start Vector Start point
---@param end_ Vector End point
---@param mins Vector Box minimum, relative to the path
---@param maxs Vector Box maximum, relative to the path
---@param with integer Interaction layers the trace collides with (64-bit mask)
---@param exclude integer Interaction layers to ignore (64-bit mask)
---@param as integer Interaction layers the trace itself counts as (64-bit mask)
---@param object_set_mask integer Accepted but not used
---@param collision_group integer Collision group (0-255)
---@param filter fun(ent: entity): boolean Called for each entity the trace meets: return true to let it block
---@param ignore_local? boolean true skips the local pawn (default false: your own pawn can be hit)
---@param portal? boolean Follow portals (default true)
---@return trace_t result
function trace.hull(start, end_, mins, maxs, with, exclude, as, object_set_mask, collision_group, filter, ignore_local, portal) end

---True if a bullet from `start` toward `end_` would reach `ent`, using the game's bullet collision rules.
---@param start Vector Shot origin
---@param end_ Vector Aim point
---@param radius number Bullet radius (0 or less = a line)
---@param ent entity The target
---@return boolean reaches
function trace.bullet(start, end_, radius, ent) end

---True if a bullet would reach `ent` and the hit hitbox's name contains `hitbox_name` ("" accepts any).
---@param start Vector Shot origin
---@param end_ Vector Aim point
---@param radius number Bullet radius
---@param ent entity The target
---@param hitbox_name string Substring to look for in the hitbox name (case-sensitive)
---@return boolean hit
function trace.bullet_hitbox(start, end_, radius, ent, hitbox_name) end

---The name of the hitbox a bullet would hit on `ent`, or "" when it doesn't reach.
---@param start Vector Shot origin
---@param end_ Vector Aim point
---@param radius number Bullet radius
---@param ent entity The target
---@return string name
function trace.bullet_hitbox_name(start, end_, radius, ent) end
