---@meta
-- Core globals: global_vars, game_rules, net_channel.latency, convar, chronos, utils.json_*, table / math additions.

-- ── global_vars ─────────────────────────────────────────────────────────────

---The engine's frame and tick globals. Every function returns 0 when the globals aren't available.
---@class global_vars
global_vars = {}

---Seconds per server tick.
---@return number seconds
function global_vars.interval_per_tick() end

---The current tick count.
---@return integer ticks
function global_vars.tickcount() end

---The current game time in seconds.
---@return number seconds
function global_vars.curtime() end

---The current frame count.
---@return integer frames
function global_vars.framecount() end

---Real time the last frame took, in seconds.
---@return number seconds
function global_vars.absoluteframetime() end

-- ── game_rules ──────────────────────────────────────────────────────────────

---The match's game rules.
---@class game_rules
game_rules = {}

---The game rules object (`C_CitadelGameRules`), whose networked fields you read by name (`rules.m_flGameStartTime`). nil out of a match.
---@return raw_struct|nil rules
function game_rules.get() end

---The current game time in seconds (same as `global_vars.curtime()`).
---@return number seconds
function game_rules.game_time() end

---The current match id, 0 when there is none.
---@return integer match_id
function game_rules.match_id() end

-- ── net_channel ─────────────────────────────────────────────────────────────

---The connection to the server. `send_net_message` is documented in network.lua.
---@class net_channel
net_channel = {}

---Estimated one-way latency to the server in seconds (smoothed, at most 0.25). 0 until the first estimate.
---@return number seconds
function net_channel.latency() end

-- ── convar ──────────────────────────────────────────────────────────────────

---A console variable by name, from `convar.<name>` or `convar["name"]`.
---Only numeric and boolean convars can be read and written.
---@class convar_table
local convar_table = {}

---Reads the value as a number, or writes it when `value` is given.
---@param value? number New value. Omit to read.
---@return number|nil value The value when reading; nil when the convar isn't found or isn't numeric, and always nil when writing.
function convar_table:float(value) end

---Reads the value as an integer, or writes it (truncated toward zero) when `value` is given.
---@param value? number New value. Omit to read.
---@return integer|nil value The value when reading; nil when the convar isn't found or isn't numeric, and always nil when writing.
function convar_table:int(value) end

---Reads the value as a boolean (non-zero is true), or writes it when `value` is given.
---@param value? boolean New value. Omit to read.
---@return boolean|nil value The value when reading; nil when the convar isn't found or isn't numeric, and always nil when writing.
function convar_table:bool(value) end

---Console variables by name: `convar.sv_gravity:float()`. Indexing never fails; a missing convar reads as nil.
---@class convar
---@field [string] convar_table
convar = {}

-- ── chronos ─────────────────────────────────────────────────────────────────

---High-resolution timer.
---@class chronos
chronos = {}

---A high-resolution monotonic clock in **seconds** (with sub-microsecond fractions). Only differences between two calls are meaningful.
---@return number seconds
function chronos.nanotime() end

-- ── utils (JSON) ────────────────────────────────────────────────────────────

---Utility functions. Only the JSON functions are listed here; the rest are in utils.lua.
---@class utils
utils = {}

---Encodes a Lua value as compact JSON.
---Tables whose keys are exactly 1..n become arrays; other tables (including empty ones) become objects with sorted keys.
---Vector, Vec2, Angle and Color become objects ({x,y,z}, {x,y}, {pitch,yaw,roll}, {r,g,b,a}); functions, other userdata and nil become null.
---@param value any
---@return string json
function utils.json_encode(value) end

---Decodes JSON into Lua values (objects and arrays become tables, null becomes nil). Returns nil when the text isn't valid JSON.
---@param json string
---@return any|nil value
function utils.json_decode(json) end

-- ── table additions ─────────────────────────────────────────────────────────

---True when the table has no entries.
---@param t table
---@return boolean
function table.IsEmpty(t) end

---Removes every entry (the table stays the same object).
---@param t table
function table.Clear(t) end

---Number of entries, counting every key (not just 1..n).
---@param t table
---@return integer
function table.Length(t) end

---The table's keys as an array.
---@param t table
---@return any[]
function table.Keys(t) end

---The table's values as an array.
---@param t table
---@return any[]
function table.Values(t) end

---Sum of the table's number values (other values are skipped).
---@param t table
---@return number
function table.Sum(t) end

---A new array with the elements of `t` (1..#t) in reverse order.
---@param t any[]
---@return any[]
function table.Reverse(t) end

---A one-level copy. The metatable is copied too unless `ignore_mt` is true.
---@param t table
---@param ignore_mt? boolean
---@return table
function table.CopyShallow(t, ignore_mt) end

---A deep copy of keys, values and nested tables. Shared and cyclic references are preserved; each copy gets the original's metatable (the metatable itself is not copied).
---@param t table
---@return table
function table.Copy(t) end

---A new table with keys and values swapped. With `v_to_true`, every new value is `true`.
---@param t table
---@param v_to_true? boolean
---@return table
function table.KvSwap(t, v_to_true) end

---Concatenates arrays (1..n of each) into a new array. nil arguments are skipped.
---@param ... any[]|nil
---@return any[]
function table.Merge(...) end

---Merges key/value tables into a new table; later tables win on equal keys. nil arguments are skipped.
---@param ... table|nil
---@return table
function table.MergeHm(...) end

---The entries of `new_t` whose value differs (by `rawequal`) from the same key in `old_t`.
---@param new_t table
---@param old_t table
---@return table
function table.Diff(new_t, old_t) end

---Deep equality of two values (tables compared key by key).
---@param a any
---@param b any
---@return boolean
function table.Equals(a, b) end

---Sorts `t` in place with `table.sort` and returns it.
---@generic T
---@param t T[]
---@param cmp? fun(a: T, b: T): boolean
---@return T[]
function table.Sorted(t, cmp) end

---A new array of `fn(value, key)` for every entry.
---@param t table
---@param fn fun(value: any, key: any): any
---@return any[]
function table.Map(t, fn) end

---A new array of the values for which `fn(value, key)` is truthy.
---@param t table
---@param fn fun(value: any, key: any): any
---@return any[]
function table.Filter(t, fn) end

---True when `fn(value, key)` is truthy for at least one entry.
---@param t table
---@param fn fun(value: any, key: any): any
---@return boolean
function table.Any(t, fn) end

---True when `fn(value, key)` is truthy for every entry (and for an empty table).
---@param t table
---@param fn fun(value: any, key: any): any
---@return boolean
function table.All(t, fn) end

---Finds a value (compared with `rawequal`). Returns the value and its key, or nil.
---@param t table
---@param value any
---@return any|nil value
---@return any|nil key
function table.Find(t, value) end

---Removes the first array element `rawequal` to `e` (or, when `e` is a function, the first for which `e(value, index)` is truthy). True when one was removed.
---@param t any[]
---@param e any|fun(value: any, index: integer): any
---@return boolean removed
function table.RemoveElement(t, e) end

-- ── math additions ──────────────────────────────────────────────────────────

---`x` to the power `y`.
---@param x number
---@param y number
---@return number
function math.pow(x, y) end

---Hyperbolic cosine.
---@param x number
---@return number
function math.cosh(x) end

---Hyperbolic sine.
---@param x number
---@return number
function math.sinh(x) end

---Hyperbolic tangent.
---@param x number
---@return number
function math.tanh(x) end

---Base-10 logarithm.
---@param x number
---@return number
function math.log10(x) end

---Arc tangent of y / x, using the signs of both to find the quadrant (radians).
---@param y number
---@param x number
---@return number
function math.atan2(y, x) end

---`m` * 2^`e`.
---@param m number
---@param e integer
---@return number
function math.ldexp(m, e) end

---Splits `x` into a mantissa in [0.5, 1) and an exponent: x = m * 2^e.
---@param x number
---@return number m
---@return integer e
function math.frexp(x) end
