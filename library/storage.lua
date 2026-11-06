---@meta
-- Storage: db / db_table (persistent, saved to disk) and global_ctx / global_ctx_t (shared for the session).

-- ── db ──────────────────────────────────────────────────────────────────────

---A node of the persistent database. Read and write it like a table: `db.key = value`, `db.key`, `db.key = nil`.
---Keys are strings or numbers (numeric strings such as `"12"` are the same key as `12`).
---Storable values: boolean, number (single precision; read back as a float), string, Vec2, Color, Vector, and tables
---(copied in as a nested db_table). Assigning any other type is ignored and keeps the old value.
---Reading a nested table returns a db_table that writes straight through to the database.
---`#node` is the number of entries; `tostring(node)` is the node as compact JSON.
---@class db_table
---@field [string] boolean|number|string|Vec2|Color|Vector|db_table|nil
---@field [integer] boolean|number|string|Vec2|Color|Vector|db_table|nil
---@operator len: integer
local db_table = {}

---A deep copy of this node as plain Lua tables (nested nodes become tables). Use it to iterate.
---@return table copy
function db_table:to_table() end

---The persistent database, shared by every script. Saved to `scripts\v2\db.json` every 5 minutes when it changed,
---before each full reload, when the config is saved and when VITTLOCK unloads. It survives reloads and restarts.
---@type db_table
db = {}

-- ── global_ctx ──────────────────────────────────────────────────────────────

---A string-keyed table shared by every script for the session. Values are strings, numbers (single precision) or booleans;
---`nil` removes a key, other types are ignored. Cleared on every full reload, never saved.
---@class global_ctx_t
---@field [string] string|number|boolean|nil

---Session-only values shared by every script. See `global_ctx_t`.
---@type global_ctx_t
global_ctx = {}
