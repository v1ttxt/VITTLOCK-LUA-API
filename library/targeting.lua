---@meta
-- Targeting: TargetSelection, hitscan, backtrack and BacktrackRecord.

-- ── TargetSelection ──────────────────────────────────────────────────────────

---One row of `TargetSelection:get_targets()`.
---@class TargetSelectionEntry
---@field entity entity The selected entity.
---@field score number Its score from the last update (weighted sum of the criteria).

---Scores a set of entities with your own criteria and picks targets from them.
---Create one with `TargetSelection()` and keep it across frames; it stores entities by handle.
---@class TargetSelection
---@overload fun(): TargetSelection
TargetSelection = {}

---Removes every criterion and the filter and clears all selection state (best target, targets, last shootable target, rotation history). The threshold, max targets, always-include-best and score-gap settings are kept.
function TargetSelection:reset() end

---Marks the entity you can currently shoot. While it still passes the filter and the threshold, every update keeps it in the target list. Pass nil (or anything that is not an entity) to clear it.
---@param ent entity|nil The entity, or nil to clear.
function TargetSelection:set_last_shootable_target(ent) end

---The highest-scoring entity from the last update, or nil when nothing scored.
---@return entity|nil best
function TargetSelection:get_best_target() end

---The targets picked by the last update, in pick order. Entities that no longer exist are left out.
---@return TargetSelectionEntry[] targets
function TargetSelection:get_targets() end

---Scores the entities in a table (values only; non-entities are skipped) and picks targets.
---@param entities entity[] The candidates.
function TargetSelection:update(entities) end

---Scores every entity of an exact class name (all teams, dormant and dead ones included) and picks targets.
---@param class_name string Entity class name, e.g. "C_CitadelPlayerPawn".
function TargetSelection:update_by_class(class_name) end

---Sets the minimum lead the best target needs over the second one to be force-included by `set_always_include_best`. 0 (default) means no lead is required.
---@param gap number Score difference.
function TargetSelection:set_best_target_score_gap(gap) end

---When true, the best target is always the first entry of `get_targets()` (subject to the score gap). Default false.
---@param enabled boolean
function TargetSelection:set_always_include_best(enabled) end

---How many targets an update picks besides the best target and the last shootable target. Default 0. Truncated to an integer; negative counts as 0.
---@param count integer
function TargetSelection:set_max_targets(count) end

---Entities scoring below this value are dropped. Default 0, so negative scores are dropped unless you lower it.
---@param threshold number
function TargetSelection:set_score_threshold(threshold) end

---Sets the filter. It is called with each candidate; return a truthy value to keep it. An error is logged and counts as false.
---@param fn fun(ent: entity): any
function TargetSelection:set_filter(fn) end

---Adds a scoring function. Each candidate's score is the sum of `weight * fn(ent)` over all criteria. A non-number result or an error (logged) counts as 0.
---@param fn fun(ent: entity): number
---@param weight number Multiplier for this criterion.
function TargetSelection:add_criterion(fn, weight) end

-- ── BacktrackRecord ──────────────────────────────────────────────────────────

---One recorded position of an enemy hero, from `backtrack.records`. A record is a copy and stays usable after the call. No constructor.
---@class BacktrackRecord
---@field simtime number The hero's simulation time when it was recorded (seconds).
---@field tick integer Tick number of `simtime`: `floor(simtime / tick_interval + 0.5) + 1`.
---@field velocity Vector The hero's velocity when `backtrack.records` was called (the same on every record of that call).
---@field abs_origin Vector The hero's origin at the recorded time.
local BacktrackRecord = {}

---True when the record is still inside the server's lag-compensation window, given your current simulation time and latency.
---@return boolean valid
function BacktrackRecord:is_valid() end

---The recorded position of a hitbox (the position of its bone; `abs_origin` for a hitbox without a bone). (0, 0, 0) for an index the hero has no hitbox for, and for every index on records taken before the first `backtrack.records` call.
---@param index integer Hitbox index in the hero's hitbox set (0-63), as in `HitscanResult.hitbox_index`.
---@return Vector pos
function BacktrackRecord:hitbox_pos(index) end

-- ── backtrack ────────────────────────────────────────────────────────────────

---Recorded positions of enemy heroes.
---@class backtrack
backtrack = {}

---The recorded positions of an enemy hero, newest first (up to 32). Only living enemy heroes are recorded, so teammates, other entities and invalid values give an empty table.
---@param ent entity The enemy hero pawn.
---@return BacktrackRecord[] records
function backtrack.records(ent) end

-- ── hitscan ──────────────────────────────────────────────────────────────────

---Error codes returned by `hitscan.evaluate`.
---@alias HitscanError
---| "invalid_target"  # target missing or not a valid entity
---| "no_local_player" # you have no pawn
---| "no_weapon"       # no primary weapon
---| "below_hitchance" # a point was found but min_hitchance was above 100 (with trace_count set)
---| "below_damage"    # points were reachable but all failed min_damage
---| "no_candidate"    # nothing reachable (or mask = 0, or no hitboxes)

---Input table of `hitscan.evaluate`.
---@class HitscanParams
---@field target entity Required. The entity to evaluate.
---@field mask? integer Hitgroup bits to consider (`hitscan.HEAD` ...). Default 0x1F (all except OTHER).
---@field records? BacktrackRecord[] Extra poses, used only when the current pose has no point (heroes only). Default none.
---@field multipoint? integer `hitscan.MULTIPOINT_DISABLED` .. `hitscan.HIGH`: 0 / 2 / 4 / 6 ring points around each hitbox centre; any other value gives the centre only. Default 0.
---@field point_scale? number Size of the multipoint ring (100 = 82% of the hitbox radius). Default 100.
---@field min_damage? number Minimum damage of a point (equal passes). Default 1.
---@field min_hitchance? number Minimum hit chance in percent. Hit chance is always 100, so only values above 100 reject. Default 0.
---@field trace_count? integer Any non-zero value (with min_hitchance > 0) enables the min_hitchance check. Default 0.

---Result table of `hitscan.evaluate`.
---@class HitscanResult
---@field record BacktrackRecord|nil The record the point belongs to, or nil for the current pose.
---@field tick integer `record.tick`, or 0 for the current pose.
---@field aim_point Vector The world position to aim at.
---@field hitbox_index integer Index of the hitbox in the target's hitbox set (as `BacktrackRecord:hitbox_pos` takes).
---@field hitgroup integer One of the `hitscan` hitgroup bits.
---@field fov number Angle in degrees between your camera direction and `aim_point`.
---@field damage number Damage of one bullet on this pose with your bonuses and falloff (no headshot multiplier, no target resistances).
---@field hitchance number Always 100.

---Finds the best point to shoot on a target.
---@class hitscan
hitscan = {
    ---Hitgroup bit: head and neck.
    HEAD = 1,
    ---Hitgroup bit: chest and upper spine.
    CHEST = 2,
    ---Hitgroup bit: stomach, pelvis and lower spine.
    STOMACH = 4,
    ---Hitgroup bit: arms and hands.
    ARMS = 8,
    ---Hitgroup bit: legs and feet.
    LEGS = 0x10,
    ---Hitgroup bit: everything else.
    OTHER = 0x20,
    ---Multipoint: only the hitbox centre.
    MULTIPOINT_DISABLED = 0,
    ---Multipoint: centre + 2 ring points per hitbox.
    MINIMUM = 1,
    ---Multipoint: centre + 4 ring points per hitbox.
    MEDIUM = 2,
    ---Multipoint: centre + 6 ring points per hitbox.
    HIGH = 3,
}

---Traces from the camera to points on the target's hitboxes and returns the reachable one closest to your crosshair (the current pose first, records only when it has none), or nil and an error code.
---@param params HitscanParams
---@return HitscanResult|nil result
---@return HitscanError|nil err
function hitscan.evaluate(params) end
