---@meta
-- Callbacks: the `callback` registry, its events and their argument types.

-- ── callback_reg ────────────────────────────────────────────────────────────

---One event of the `callback` table. Register a handler with `:set(fn)`, remove it with `:unset(fn)`.
---Any number of scripts can each set any number of handlers on the same event.
---@class callback_reg
local callback_reg = {}

---Adds a handler to this event. The handler belongs to the script whose code is running.
---Setting the same function twice registers it twice.
---@param fn function The handler.
function callback_reg:set(fn) end

---Removes every registration of `fn` (compared by identity) from this event.
---@param fn function The same function value that was passed to `:set`.
function callback_reg:unset(fn) end

-- ── Event argument tables ───────────────────────────────────────────────────

---The table passed to `on_key_event`.
---@class key_event_data
---@field key integer The key or mouse button, an `Enum.ButtonCode` value (mouse buttons are `KEY_MOUSE1`..`KEY_MOUSE5`, the wheel is `KEY_MWHEELUP` / `KEY_MWHEELDOWN`).
---@field event integer What happened, an `Enum.KeyEvent` value: `KEY_DOWN`, `KEY_UP`, `SCROLL_UP` or `SCROLL_DOWN`.

---The table passed to `on_particle_create`.
---@class particle_create_data
---@field entity entity|player_pawn|ability|nil The entity the particle belongs to, nil when unknown.
---@field entity_for_modifiers entity|player_pawn|ability|nil Same value as `entity`.
---@field index integer The particle's index. `on_particle_update_transform` and `on_particle_destroy` use the same index.
---@field name string The particle system's resource name.
---@field hash integer Hash of the name (the same value `utils.subclass_id(name)` returns).

---The table passed to `on_particle_update_transform`.
---@class particle_update_transform_data
---@field index integer The particle's index.
---@field control_point integer The control point that moved.
---@field position Vector The control point's new position.
---@field orientation Angle Always `Angle(0, 0, 0)`.
---@field interpolation_interval number Always 0.

---The table passed to `on_particle_destroy`.
---@class particle_destroy_data
---@field index integer The particle's index.
---@field destroy_immediately boolean Always false.

-- ── Per-event registrations (typed handlers) ───────────────────────────────

---@class callback_reg.on_scripts_loaded: callback_reg
local on_scripts_loaded = {}
---@param fn fun()
function on_scripts_loaded:set(fn) end
---@param fn fun()
function on_scripts_loaded:unset(fn) end

---@class callback_reg.cmd: callback_reg
local cmd_reg = {}
---@param fn fun(cmd: CUserCmd)
function cmd_reg:set(fn) end
---@param fn fun(cmd: CUserCmd)
function cmd_reg:unset(fn) end

---@class callback_reg.on_frame: callback_reg
local on_frame = {}
---@param fn fun()
function on_frame:set(fn) end
---@param fn fun()
function on_frame:unset(fn) end

---@class callback_reg.entity: callback_reg
local entity_reg = {}
---@param fn fun(ent: entity|player_pawn|ability)
function entity_reg:set(fn) end
---@param fn fun(ent: entity|player_pawn|ability)
function entity_reg:unset(fn) end

---@class callback_reg.on_add_modifier: callback_reg
local on_add_modifier = {}
---@param fn fun(mod: modifier, target: entity|player_pawn|ability, owner: entity|player_pawn|ability|nil)
function on_add_modifier:set(fn) end
---@param fn fun(mod: modifier, target: entity|player_pawn|ability, owner: entity|player_pawn|ability|nil)
function on_add_modifier:unset(fn) end

---@class callback_reg.on_received_net_message: callback_reg
local on_received_net_message = {}
---@param fn fun(id: integer, msg: lightuserdata)
function on_received_net_message:set(fn) end
---@param fn fun(id: integer, msg: lightuserdata)
function on_received_net_message:unset(fn) end

---@class callback_reg.on_send_net_message: callback_reg
local on_send_net_message = {}
---@param fn fun(id: integer, msg: lightuserdata): boolean|nil
function on_send_net_message:set(fn) end
---@param fn fun(id: integer, msg: lightuserdata): boolean|nil
function on_send_net_message:unset(fn) end

---@class callback_reg.on_send_gc_message: callback_reg
local on_send_gc_message = {}
---@param fn fun(id: integer, body: lightuserdata, size: integer): boolean|nil
function on_send_gc_message:set(fn) end
---@param fn fun(id: integer, body: lightuserdata, size: integer): boolean|nil
function on_send_gc_message:unset(fn) end

---@class callback_reg.on_receive_gc_message: callback_reg
local on_receive_gc_message = {}
---@param fn fun(id: integer, body: lightuserdata, size: integer)
function on_receive_gc_message:set(fn) end
---@param fn fun(id: integer, body: lightuserdata, size: integer)
function on_receive_gc_message:unset(fn) end

---@class callback_reg.on_particle_create: callback_reg
local on_particle_create = {}
---@param fn fun(data: particle_create_data)
function on_particle_create:set(fn) end
---@param fn fun(data: particle_create_data)
function on_particle_create:unset(fn) end

---@class callback_reg.on_particle_update_transform: callback_reg
local on_particle_update_transform = {}
---@param fn fun(data: particle_update_transform_data)
function on_particle_update_transform:set(fn) end
---@param fn fun(data: particle_update_transform_data)
function on_particle_update_transform:unset(fn) end

---@class callback_reg.on_particle_destroy: callback_reg
local on_particle_destroy = {}
---@param fn fun(data: particle_destroy_data)
function on_particle_destroy:set(fn) end
---@param fn fun(data: particle_destroy_data)
function on_particle_destroy:unset(fn) end

---@class callback_reg.on_key_event: callback_reg
local on_key_event = {}
---@param fn fun(data: key_event_data): boolean|nil
function on_key_event:set(fn) end
---@param fn fun(data: key_event_data): boolean|nil
function on_key_event:unset(fn) end

-- ── callback ────────────────────────────────────────────────────────────────

---The callback registry: one `callback_reg` per event.
---Errors raised by a handler are caught and shown in the owning script's log; the handler keeps being called.
---@class callback
---@field on_scripts_loaded callback_reg.on_scripts_loaded Once, after every script of a full load ran its top level.
---@field on_pre_createmove callback_reg.cmd Early in building each user command.
---@field on_createmove callback_reg.cmd Once per user command, after movement processing; the place for buttons and aim.
---@field on_post_createmove callback_reg.cmd Right after every `on_createmove` handler, with the same command.
---@field on_frame callback_reg.on_frame Once per game frame, in the main menu too. Game logic and Panorama calls go here.
---@field on_draw callback_reg.on_frame Once per rendered frame. The only place `Render.*` draws.
---@field on_add_entity callback_reg.entity An entity was created.
---@field on_late_add_entity callback_reg.entity An entity created since the previous user command (fires at the next command).
---@field on_remove_entity callback_reg.entity An entity is about to be removed.
---@field on_add_modifier callback_reg.on_add_modifier A modifier was applied to an entity.
---@field on_received_net_message callback_reg.on_received_net_message A network message arrived from the server.
---@field on_send_net_message callback_reg.on_send_net_message A network message is about to be sent. Return false to block it.
---@field on_send_gc_message callback_reg.on_send_gc_message A Game Coordinator message is about to be sent. Return false to block it.
---@field on_receive_gc_message callback_reg.on_receive_gc_message A Game Coordinator message arrived.
---@field on_particle_create callback_reg.on_particle_create The server created a particle effect.
---@field on_particle_update_transform callback_reg.on_particle_update_transform The server moved a particle's control point.
---@field on_particle_destroy callback_reg.on_particle_destroy The server destroyed a particle effect.
---@field on_key_event callback_reg.on_key_event A key, mouse button or wheel event. Return false to keep it from the menu and the game window.
---@field on_target_acquired callback_reg Registered, but does not fire in this version.
---@field on_animation_start callback_reg Registered, but does not fire in this version.
---@field on_animation_end callback_reg Registered, but does not fire in this version.
---@field on_pre_framestage callback_reg Registered, but does not fire in this version.
---@field on_post_framestage callback_reg Registered, but does not fire in this version.
---@field on_particle_update callback_reg Registered, but does not fire in this version.
---@field on_remove_modifier callback_reg Registered, but does not fire in this version.
---@field on_bullet_create callback_reg Registered, but does not fire in this version.
---@field on_start_sound callback_reg Registered, but does not fire in this version.
callback = {}

-- ── Shared environment ──────────────────────────────────────────────────────

---Writes its arguments, converted with `tostring` and separated by tabs, to the log of the script whose code is running (shown in the menu's Lua tab).
---@param ... any
function print(...) end

---Loads a module from `scripts\v2\`: `name.lua`, else `name\init.lua` (dots in `name` become folders). The module runs once in the shared environment, receives `name` as `...`, and its return value (or `true` when it returns nothing) is cached until the next full reload. Names not found there fall back to the standard `require`.
---@param name string Module name, e.g. `"lib.mathx"`.
---@return any module The module's return value, or `true`.
function require(name) end

---Standard `load`, except that the chunk runs in the shared script environment when `env` is not given.
---@param chunk string|function
---@param chunkname? string
---@param mode? "b"|"t"|"bt"
---@param env? table Environment for the chunk; defaults to the shared script environment.
---@return function|nil fn
---@return string|nil err
function load(chunk, chunkname, mode, env) end

---Standard `loadfile`, except that the chunk runs in the shared script environment when `env` is not given.
---@param filename string
---@param mode? "b"|"t"|"bt"
---@param env? table Environment for the chunk; defaults to the shared script environment.
---@return function|nil fn
---@return string|nil err
function loadfile(filename, mode, env) end

---Loads and runs a file in the shared script environment and returns what it returns. Raises an error when the file can't be loaded.
---@param filename string
---@return any ...
function dofile(filename) end
